string status = STOPPED;

static object app;

Thread.Queue queue = Thread.Queue();

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

//!
static void create(string _project, string _config)
{
  object app;
  object port;
  
  logger=master()->resolv("Tools.Logging.get_logger")("finserve");
  project = _project;
  config = _config;
  ident = sprintf("%s/%s", project, config_name);
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
  container = container;  
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
  ident = sprintf("%s/%s", project, config_name);
  
  logger->info("FinServe loading application from " + project + " using configuration " + config_name);
  
  status = "LOADING";
  
  
  application = load_application(project, config_name);

  if(!application)
  {
    ident = "FAILED";
    logger->critical("Application in %s failed to load.", ident);
    throw(Error.Generic("Application failed to load.\n"));
  }
  
  status = "LOADED";
  set_application(application);
  logger->info("Application %s loaded.", ident);
}

//!
void register_ports()
{
  int p;
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

  // TODO we should probably have a little more sophistication built in here; probably
  // need to consider what happen if we want to shut down, etc.
  int keep_running = 1;
  
  do
  {
//    werror("loop\n");
    object r = app->queue->read();
    
    if(r)
      do_handle_request(r);
//    werror("handled request.\n");
  } while(keep_running);
}

static Thread.Thread start_worker_thread(object app, string key)
{
  Thread.Thread t;
  object _master = master();

  if(_master->multi_tenant_aware)
  {
    // NOTE should not need to lock here because startup is single-threaded.
    if(key)
    {
      _master->handlers_for_thread[Thread.this_thread()] = key;
    }

    t = _master->fins_aware_create_thread(run_worker, app);

    if(key)
    {
      m_delete(_master->handlers_for_thread, Thread.this_thread());
    }
  }
  else 
  {
    t = Thread.Thread(run_worker, app);
  }
  return t;
}

//!
void start_worker_threads()
{
  workers+= ({ start_worker_thread(app, combine_path(getcwd(), project) + "#" + config_name) });
  
  status = "STARTED";
  
}

static void handle_request(Protocols.HTTP.Server.Request request)
{
  if(!request->fins_app) 
    request->fins_app = app;
    
  queue->write(request);  
}