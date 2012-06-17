string status = "STOPPED";
object status_last_change = Calendar.now();

static object app;

Thread.Queue queue = Thread.Queue();

program server = Fins.Util.AppPort;
static array ports = ({});
multiset urls = (<>);
static array workers = ({});

static object logger;
string project;
string config;
string ident;

static function do_handle_request;
static function do_new_session;

static object session_manager;
static object container;

static int keep_running = 1;
static int worker_number;
//!
static void create(string _project, string _config)
{
  logger=master()->resolv("Tools.Logging.get_logger")("finserve");
  project = _project;
  config = _config;
  ident = sprintf("%s/%s", project, config);
}

//!
int has_ports()
{
  return sizeof(ports);
}

//!
array get_ports()
{
  return ports + ({});
}

//!
object get_session_manager()
{
  return session_manager;
}

//!
void set_session_manager(object manager)
{
  session_manager = manager;
}

//!
object get_application()
{
  return app;  
}

//!
void set_application(object application)
{
  application->app_runner = this;
  app = application;
}

//!
void set_new_session_handler(function handler)
{
  do_new_session = handler;
}

//!
void set_request_handler(function handler)
{
  do_handle_request = handler;  
}

//! associate the application server container (ie FinServe or the like) with the runner.
void set_container(object app_container)
{
  container = app_container;  
}

object get_container()
{
  return container;
}

mixed new_session(mixed ... args)
{
  return do_new_session(@args);
}

static void set_status(string _status)
{
  status = _status;
  status_last_change = Calendar.now();
}

static object load_app(string project, string config_name)
{
  object application;
  mixed err = catch(

  application = master()->resolv("Fins.Loader")->load_app(combine_path(getcwd(), project), config_name));
  if(err || !application)
  {
    if(err) logger->exception("An error occurred while loading the application.", err);
    else logger->critical("An error occurred while loading the application.");
    return 0;
//    exit(1);
  }

  return application;

}

//!
void load_application()
{
  object application;
  
  logger->info("FinServe loading application from " + project + " using configuration " + config);
  
  set_status("LOADING");
  
  application = load_app(project, config);

  if(!application)
  {
    set_status("FAILED");
    logger->critical("Application in %s failed to load.", ident);
    throw(Error.Generic("Application failed to load.\n"));
  }
  
  set_status("LOADED");
  set_application(application);
  logger->info("Application %s loaded.", ident);
}

//!
void register_ports()
{
  int p;
  object port;
  
  if(status != "LOADED") throw("Cannot register ports until application is loaded.\n");
  
  catch(p = (int)app->config["web"]["port"]);
  // prefer command line specification to config file to default.
  if(p)
  {
    port = server(handle_request, p);  
    port->set_app(app);
    port->request_program = Fins.HTTPRequest;

  #if constant(_Protocols_DNS_SD) && constant(Protocols.DNS_SD.Service);
    port->set_bonjour(Protocols.DNS_SD.Service("Fins Application (" + ident + ")",
                       "_http._tcp", "", p));

    logger->info("Advertising this application via Bonjour.");
  #endif

    ports += ({port});
  }
  
  object a;
  mixed err = catch(a = app->get_my_url());
  
  if(a) 
  {
    logger->info("registering %O", lower_case(a->host));
    urls += (< lower_case(a->host) >);
  }
  else
  {
    logger->exception("Unable to determine application URL. Still starting app but you probably won't be able to access it. Root exception follows.", err);
  }  
}

static void run_worker(object app)
{
  keep_running = 1;
  
  do
  {
    object r = queue->read();
    
    if(r)
      do_handle_request(r);

  } while(keep_running);
}

static Thread.Thread start_worker_thread(object app, string key)
{
  Thread.Thread t;
  object _master = master();
  if(_master->multi_tenant_aware && key)
      _master->handlers_for_thread[Thread.this_thread()] = key;

    t = thread_create(run_worker, app);
    t->set_thread_name("Worker " + worker_number++);
  if(_master->multi_tenant_aware && key)
    m_delete(_master->handlers_for_thread, Thread.this_thread());
}

//!
void start_worker_threads()
{
  workers+= ({ start_worker_thread(app, combine_path(getcwd(), project) + "#" + config) });
  
  set_status("STARTED");
}

void handle_request(Protocols.HTTP.Server.Request request)
{
  if(!request->fins_app) 
    request->fins_app = app;
        
  queue->write(request);  
}

void start()
{
  if(status != "LOADED")
  {
    throw(Error.Generic("Cannot start application until it has been loaded.\n"));
    
  }
  
  start_worker_threads();  
}

void stop()
{
  keep_running = 0;
  set_status("STOPPING");

  foreach(workers;; object worker)
  {
    worker->kill();
  }

  app->shutdown();
  set_status("STOPPED");
}