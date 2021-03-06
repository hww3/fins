//! This class serves to encapsulate the ports, worker thread pool and associated machinery for running a Fins application.

string status = "STOPPED";
object status_last_change = Calendar.now();

protected object app;

Thread.Queue queue = Thread.Queue();

program server = Fins.Util.AppPort;
program ssl_server = Fins.Util.SSLAppPort;

protected array ports = ({});
multiset urls = (<>);
protected array workers = ({});

protected object logger;
string project;
string config;
string ident;

//! this is the key used to identify the compilation handler environment used by all threads that have this key
string handler_key;

protected function do_handle_request;
protected function do_new_session;

protected object session_manager;
protected object container;

protected int keep_running = 1;
protected int worker_number;

protected object reload_scanner;

//!
protected void create(string _project, string _config)
{
  logger=master()->resolv("Tools.Logging.get_logger")("finserve");
  project = _project;
  config = _config;
  ident = sprintf("%s/%s", project, config);
  handler_key = combine_path(getcwd(), project) + "#" + config;
}

#if constant(Filesystem.Monitor.basic)
class ReloadScanner
{
  inherit Filesystem.Monitor.basic : mon;
  
  protected object runner;
  protected void create(object _runner)
  {
    runner = _runner;
    
    object config = runner->get_application()->config;
    mon::create(0,0,0);
      
    monitor(combine_path(config->app_dir, "classes"), MF_RECURSE);
    monitor(combine_path(config->app_dir, "templates"), MF_RECURSE);
    monitor(combine_path(config->app_dir, "modules"), MF_RECURSE);    
  
    set_nonblocking(10);
#if constant(Pike.DefaultBackend.HAVE_CORE_FOUNDATION)
    Pike.DefaultBackend.enable_core_foundation(1);
#endif
    call_out(check, 5.0);
  }
    
  void stable_data_change(string path, object st){
    reload_app();
  }

  void data_changed(string path, object st){
    reload_app();
  }

  void file_created(string path){
    reload_app();
  }

  void file_deleted(string path){
    reload_app();
  }

  void reload_app()
  {
    werror("Restarting application\n");
    catch(runner->get_appication()->shutdown());
    runner->load_application();
    runner->start_application();
  }  
}
#else
class ReloadScanner
{
  protected void create(object _runner)
  {
    logger->warning("No support for Filesystem.Monitor found. NOT enabling automatic application reload.");
  }
}
#endif /* constant(Filesystem.Monitor.basic) */

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

protected void set_status(string _status)
{
  status = _status;
  status_last_change = Calendar.now();
}

protected object load_app(string project, string config_name)
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
void start_application()
{
  get_application()->do_start();
}

//!
void load_application()
{
  keep_running = 1;
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
//write("key: %O\n", get_application()->app_runner->handler_key);
  logger->info("Application %s loaded.", ident);
  
  if(!reload_scanner && get_application()->config->get_boolean("devel", "auto_reload"))
  {
    reload_scanner = ReloadScanner(this);
  }
  
}

void unregister_ports()
{
  foreach(ports;; object port)
  {
    ports -= ({port});
    destruct(port->get_bonjour());
    logger->info("Shutting down port " + port->port->query_address());
    destruct(port->port);
    destruct(port);
  }
  
  urls = (<>);
}

object register_port(int p, string|void bind, mapping|void args)
{
  object port;
  int use_ssl = 0;
werror("args: %O\n", args);
  if(args && args->ssl)
  {
    use_ssl = 1;
  }
      
  if(!bind) bind = "*";
  logger->info("Starting %s port %s:%d for %O", (use_ssl?"https":"http"), bind, p, app);

  mixed err;

  if(use_ssl)
  {
    // TODO: we should support SNI somehow. Need to decide how to specify the keys for 
    // a given servername, then parse and set them in the SSL context.
    err = catch(port = ssl_server(handle_request, p, (bind=="*"?0:bind), args));
  }
  else
  { 
    err = catch(port = server(handle_request, p, (bind=="*"?0:bind)));
  }
  
  if(err)
  {
    set_status("FAILED");
    logger->exception("Unable to open port " + bind + ":" + p + ".", err);
    throw(err);

  }  
  port->set_application(app);
  program prog = Fins.HTTPRequest;
  if(app->request_program)
  {
    logger->info("using HTTP request program: %O", app->request_program );
    prog = app->request_program;
  }
  
  port->request_program = prog;

  #if constant(_Protocols_DNS_SD) && constant(Protocols.DNS_SD.Service);
  if(bind == "*")
  {
    logger->info("Advertising this application via Bonjour.");
    mixed err = catch {
      port->set_bonjour(p, "Fins Application (" + ident + ")",
                     (args->ssl?"_https._tcp":"_http._tcp"));
    };
    if(err)
      logger->warn("Unable to advertise application via Bonjour. Message: %s", err[0]);
  }
#endif
    
 return port;
}

//!
void register_ports()
{
  int p;
  string addr;
  object port;
  
  if(status != "LOADED") throw("Cannot register ports until application is loaded.\n");
    
  catch(p = (int)app->config["web"]["port"]); 
  catch(addr = app->config["web"]["bind"]); 
  
  // prefer command line specification to config file to default.
  if(p)
  {
    port = register_port(p, addr, app->config["web"]);
    ports += ({port});
  }
  
  // we can register a bunch of ports, too. just have multiple port_xxx sections in the config file.
  foreach(glob("port_*", app->config->get_sections());; string pd)
  {
    string protocol;
    
    catch(p = (int)app->config[pd]["port"]); 
    catch(addr = app->config[pd]["bind"]); 
    catch(protocol = app->config[pd]["protocol"]); 
    
    if(protocol && !(<"http", "ssl", "https">)[protocol])
    {
      throw(Error.Generic("Unknown protocol '" + protocol + "' in port definition '" + pd + "'."));
    }
    
    mapping args = ([]);
        
    if((<"ssl", "https">)[protocol])
    {
      args->ssl = 1;  
      args->key = app->config[pd]["key"];
      args->certificate = app->config[pd]["certificate"];
    }
    
    if(p)
    {
      port = register_port(p, addr, args);
      ports += ({port});
    }    
  }
  
  object a;
  mixed err = catch(a = app->get_my_url());
  
  if(!err) 
  {
    logger->info("Registering %O", lower_case(a->host));
    urls += (< lower_case(a->host) >);
  }
  else
  {
    logger->warn("Unable to determine application URL. Still starting app but you probably won't be able to access it. Root exception follows.", err);
  }  
}

protected void run_worker(object app)
{
  keep_running = 1;
  mixed err;
  err = catch 
  {
    do
    {
      object r = queue->read();
    
      if(r)
        do_handle_request(r);

//werror("run\n");
    } while(keep_running);
  };
  if(err)
  logger->exception("Worker Thread " + sprintf("%O", Thread.this_thread()) + " exiting.", err);
  logger->info("Worker Thread %O exiting.", Thread.this_thread());
}

protected Thread.Thread start_worker_thread(object app, string key)
{
  Thread.Thread t;
  
  t = Thread.Thread(key, run_worker, app);
  t->set_thread_name("Worker " + worker_number++ + " " + key);
  
  return t;
}

//!
void start_worker_threads()
{
  workers+= ({ start_worker_thread(app, handler_key) });
  
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
  
  if(!queue)
    queue = Thread.Queue();
  start_worker_threads();  
}

void stop()
{
  if(status == "STOPPED")
  {
    throw(Error.Generic("Application is already stopped.\n")); 
  }
  
  keep_running = 0;
  set_status("STOPPING");

  foreach(workers;; object worker)
  {
//    werror("worker: %O\n", worker);
    queue->write(0);
  }
  app->shutdown();
  queue = Thread.Queue();
  if(master()->multi_tenant_aware && handler_key)
  {
    object handler = master()->handlers[handler_key];
//    werror("handler: %O\n", handler);
    destruct(handler);
  }
  
  unregister_ports();
  worker_number = 0;
  catch(gc());
  set_status("STOPPED");
}
