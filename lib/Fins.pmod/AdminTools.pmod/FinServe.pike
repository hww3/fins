#!/usr/local/bin/pike -Mlib -DLOCALE_DEBUG

//import Fins;
//import Tools.Logging;
//inherit Fins.Bootstrap;
inherit Tools.Application.Backgrounder;

#define DEFAULT_CONFIG_NAME "dev"

object logger;
constant is_fins_serve = 1;

function(object:void) ready_callback;

constant default_port = 8080;
constant my_version = "0.2";

// we really want the default to be RAM.
string session_storagetype = "ram";
string session_storagedir = 0;
string logfile = "finserve.log";

string session_cookie_name = "PSESSIONID";
int session_timeout = 7200;

//Session.SessionManager session_manager;
//object /*Fins.Application*/ 
mapping(string:object) apps = ([]);

program server = Fins.Util.AppPort;
int _ports_defaulted;
int admin_port;

// url to runner mapping
mapping(string:object|int) urls = ([]);

multiset(Protocols.HTTP.Server.Port) ports = (<>);
Thread.Queue admin_queue = Thread.Queue();
array workers = ({});

int hilfe_mode = 0;
int go_background = 0;
private int has_started = 0;

void print_help()
{
	werror("Help: fin_serve [-p portnum|--port=portnum|--hilfe] [-s ram|file|sqlite|--session-manager=ram|file|sqlite [-l "
		"storage_path|--session-storage-location=storage_path]] [-c|--config configname] [-d] [--logfile|-f logfilename] appname [appname [appname]]\n");
}

array tool_args;

int(0..1) started()
{
  if(sizeof(ports) && has_started) return 1;
  else return 0;
}

void create(array args)
{
  tool_args = args;
}

int run()
{
  return main(sizeof(tool_args) + 1, ({""}) + tool_args);
}

int main(int argc, array(string) argv)
{
  int my_port = default_port;
  array(string) config_name = ({});

  foreach(Getopt.find_all_options(argv,aggregate(
    ({"port",Getopt.HAS_ARG,({"-p", "--port"}) }),
    ({"config",Getopt.HAS_ARG,({"-c", "--config"}) }),
    ({"sessionmgr",Getopt.HAS_ARG,({"-s", "--session-manager"}) }),
    ({"sessionloc",Getopt.HAS_ARG,({"-l", "--session-storage-location"}) }),
#if constant(fork)
    ({"daemon",Getopt.NO_ARG,({"-d"}) }),
    ({"logfile",Getopt.HAS_ARG,({"-f", "--logfile"}) }),
#endif /* fork() */
    ({"hilfe",Getopt.NO_ARG,({"--hilfe"}) }),
    ({"help",Getopt.NO_ARG,({"--help"}) }),
    )),array opt)
    {
      switch(opt[0])
      {
		case "port":
		  my_port = (int)opt[1];
		  break;
		
		case "config":
		  config_name += ({opt[1]});
		  break;

		case "sessionloc":
		  session_storagedir = opt[1];
                  break;

		case "sessionmgr":
		  if(!(<"sqlite", "ram", "file">)[opt[1]])
		  {
  		    werror("Error: invalid session manager type '%s'. Valid options are sqlite, ram, file.", opt[1]);
		    exit(1);
		  }
		  session_storagetype = opt[1];
		  break;
		
		case "hilfe":
		  hilfe_mode = 1;
		  break;
		
		case "daemon":
		  go_background = 1;
		  break;
		
		case "logfile":
		  logfile = opt[1];
		  break;
		
    case "help":
      print_help();
		  return 0;
		  break;
	  }
	}
	
	argv-=({0});
	argc = sizeof(argv);
        if(!sizeof(config_name)) config_name = ({"dev"});

  admin_port = my_port;
  array projects = ({"default"});
  if(argc>=2) projects = argv[1..];

  config_name += allocate(sizeof(projects) - sizeof(config_name));

  foreach(projects;int i;string pn)
  {
    if(!config_name[i]) config_name[i] = DEFAULT_CONFIG_NAME;
  }

  int x = do_startup(projects, config_name, my_port);

  return x;
}

int do_startup(array(string) projects, array(string) config_name, int my_port)
{
  if(sizeof(projects) > 1 && !master()->multi_tenant_aware)
  {
    werror("multi-tenant mode is only available when running Pike 7.9 or higher.\n");
    exit(1);
  }

  if(!hilfe_mode && enter_background(go_background, logfile))
  {
    return 0;
  }
  
  logger=master()->resolv("Tools.Logging.get_logger")("finserve");

  if(hilfe_mode && sizeof(projects) > 1)
  {
    werror("hilfe mode is only available when starting 1 application.\n");
    exit(1);
  }

  int i;
  string project;
  
  foreach(projects;i;project)
    logger->info("Will start application %s with config %s.", project, config_name[i]);

  if(hilfe_mode)
  {
    foreach(projects; i; project)
    {
      int res = start_app(project, config_name[i]);
      if(res == 0) return 0;
    }
  }
  else
  {
    if(start_admin(((int)my_port))) return 0;
    master()->old_call_out(schedule_start_app, 1, projects, config_name);
  }

  return -1;
}

void run_hilfe(object app)
{
  write("\nStarting interactive interpreter...\n");
  add_constant("application", app);
  add_constant("app", app);
  object in = Stdio.FILE("stdin");
  object out = Stdio.File("stdout");
  object o = Fins.Helpers.Hilfe.FinsHilfe();
  exit(1);
  return 0;
}

int start_current_position = 0;

void schedule_start_app(array projects, array config_name)
{
  if(start_current_position < sizeof(projects))
  {
    int res = start_app(projects[start_current_position], config_name[start_current_position]);
    master()->old_call_out(schedule_start_app, 0.5, projects, config_name);
    start_current_position++;
  }
  else
  {
    if(ready_callback)
  	  master()->old_call_out(ready_callback, 0, this);
    has_started = 1;
  }
}

int start_admin(int my_port)
{
  object port;

  logger->info("FinServe starting admin server on port " + my_port + ".");
  port = server(admin_handle_request, my_port);  
  port->request_program = Fins.HTTPRequest;

  ports += (<port>);

#if constant(_Protocols_DNS_SD) && constant(Protocols.DNS_SD.Service);
    port->set_bonjour(Protocols.DNS_SD.Service("FinServe Admin",
                     "_http._tcp", "", my_port));

    logger->info("Advertising main port via Bonjour.");
#endif

    workers+=({start_admin_worker_thread()});
}

void restart_app(object runner)
{
  runner->load_application();
  call_out(reregister_app, 0.1, runner);  
}

void reregister_app(object runner)
{
  if(!runner->get_application())
  {
    if(runner->status == "FAILED")
    {
      return;
    }
    else
    {
      call_out(reregister_app, 0.2, runner);  
    }
  }
  runner->register_ports();
  call_out(restart_workers, 0.1, runner);
}

void restart_workers(object runner)
{
  
  runner->start();
  foreach(runner->urls;string url;)
  {
    urls[url] = runner;
  }
  
  // let's always make the app available via a xip.io url.
  // TODO: should this be configurable?
  urls[lower_case(Fins.Util.get_xip_io_url(runner->get_application())->host)] = runner;
  
}

int start_app(string project, string config_name, int|void solo)
{
  object _master = master();
  object runner = master()->resolv("Fins.Util.AppRunner")(project, config_name);
  apps[runner->ident] = runner;
  
  runner->set_container(this);
  runner->set_request_handler(thread_handle_request);
  runner->set_new_session_handler(new_session);

  runner->load_application();

  if(hilfe_mode)
  {
    // apps typically have deferred startup for things like controllers
    // and such. Running the back end once or twice will allow deferred actions
    // to run so that we hopefully have things like controllers started up.
    Pike.DefaultBackend(0.0);
    Pike.DefaultBackend(0.0);

    if(_master->low_create_thread)
    {
         _master->low_create_thread(run_hilfe, runner->get_application()->config->handler_name, runner->get_application());
    }
    else
    {
      Thread.Thread(run_hilfe, runner->get_application());
    }

    return -1;
  }
  else
  {
    // start a new thread and run the session manager startup process within it, that's the easiest way to get a application 
    // enviornment synchronously (we could also use call_out, but then we couldn't easily wait for it).
    object session_thread;
    
    if(_master->low_create_thread)
    {
      session_thread = _master->low_create_thread(session_startup, runner->get_application()->config->handler_name, runner);
      session_thread->set_thread_name("Session Startup");
    }
    else
    {
      session_thread = Thread.Thread(session_startup, runner->get_application()->config->handler_name, runner);
      session_thread->set_thread_name("Session Startup");
    }
    
    session_thread->wait();
    
    runner->register_ports();
    
    // TODO probably should have a better way to do this.
    foreach(runner->urls;string url;)
    {
      urls[url] = runner;
    }
    
    // let's always make the app available via a xip.io url.
    // TODO: should this be configurable?
    urls[lower_case(Fins.Util.get_xip_io_url(runner->get_application())->host)] = runner;
    
    runner->start();
    
    if(runner->has_ports())
      logger->info("Application %s is ready for business on %s.", runner->ident, (runner->get_ports()->port->query_address()) * ", ");
    else
      logger->info("Application %s is ready for business on admin hosting port %d.", runner->ident, admin_port);

    return -1;
  }
}

int admin_worker_num;

Thread.Thread start_admin_worker_thread()
{
  Thread.Thread t;
  t = Thread.Thread(run_admin_worker);
  t->set_thread_name("Admin Worker " + admin_worker_num++);
  return t;
}

void run_admin_worker()
{
  // TODO we should probably have a little more sophistication built in here; probably
  // need to consider what happen if we want to shut down, etc.
  int keep_running = 1;
  
  do
  {
    object r = admin_queue->read();
    
    if(r)
      thread_admin_handle_request(r);

  } while(keep_running);
}

void session_startup(object runner)
{
  object s;
  object session_manager;
  object app = runner->get_application();

  logger->info("Starting Session Manager for %s/%s.", app->get_app_name(), app->get_config_name());

  session_manager = master()->resolv("Session.SessionManager")();

  if(app->config["web"])
  {
    if(app->config["web"]->session_storage_type)
      session_storagetype = app->config["web"]->session_storage_type;
    if(app->config["web"]->session_storage_location)
      session_storagedir = app->config["web"]->session_storage_location;
    if(app->config["web"]->session_timeout)
      session_timeout = (int)app->config["web"]->session_timeout;
  }

  switch(session_storagetype)
  {
    case "file":
      if(!session_storagedir)
      {
        logger->error("You must specify a filesystem location in order to use file-based session storage.");
        exit(1);
      }
      logger->info("SessionManager will use files in " + session_storagedir + " to store session data.");
      s = master()->resolv("Session.FileSessionStorage")();
      s->set_storagedir(session_storagedir);
      break;

    case "sqlite":
      if(!session_storagedir)
      {
        logger->error("You must specify a database location in order to use SQLite session storage.");
        exit(1);
      }
      logger->info("SessionManager will use SQLite database " + session_storagedir + " to store session data.");
      s = master()->resolv("Session.SQLiteSessionStorage")();
      s->set_storagedir(session_storagedir);
      break;

    case "ram":
      logger->info("SessionManager will use RAM to store session data.");
      s = master()->resolv("Session.RAMSessionStorage")();
      break;
	
    default:
      logger->warn("Unknown session storage type '" + session_storagetype + "'."); 
      logger->info("SessionManager will use RAM to store session data.");
      s = master()->resolv("Session.RAMSessionStorage")();
      break;
  }

  session_manager->set_default_timeout(session_timeout);
  session_manager->set_cleaner_interval(session_timeout + random(session_timeout)/2	);
  session_manager->session_storage = ({s});

  add_constant("Session", master()->resolv("Session.Session"));
  add_constant("session_manager", session_manager);

  runner->set_session_manager(session_manager);
}

void admin_handle_request(Protocols.HTTP.Server.Request request)
{
  admin_queue->write(request);  
}

void thread_admin_handle_request(Protocols.HTTP.Server.Request request)
{
  if(request->protocol == "HTTP/1.1" && request->request_headers["host"])
  {
    string host = lower_case(request->request_headers["host"]);
    host = (host/":")[0];

    object|int runner;
//    werror("url we want: %O\n", host);
//    werror("urls we know: %O\n", urls);
    if(!(runner = urls[host]))
    {
       foreach(urls; string u; object r)
       {
         if(has_suffix(host, "." + u))
         {
           runner = urls[host] = r;
           break; 
         }
       }      
    }

    if(!runner || runner == -1)
    {
       urls[host] = -1;
    }
    else
    {
      runner->handle_request(request);
      return 0;
    }
  }

  // now that we have the pesky ip-less virtual hosting out of the way, let's get down to the business!
  thread_handle_request(request);
  
  return 0;
}

mapping do_admin_request(object request)
{
  object r = Fins.Response(request);
  string response = "<h1>Welcome to FinServe " + my_version + ".</h1>\n";

  response += "<h2>Applications</h2>\n";

  if(sizeof(apps))
  {
    response += "Apps currently configured:<p>\n";
    response += "<table cellpadding=5><tr><th>Application/Config</th><th>State</th><th>Last State Change</th><th>URL</th><th>Ports</th></tr>\n";

    foreach(apps;string ident; object app)
    {
      string url;
      if(app)
      {
        catch(url = (string)app->get_application()->get_my_url());
        if(request->variables->stop && request->variables->stop == ident)
        {
          foreach(app->urls; string url;)
          {
            m_delete(urls, url);
          }
          
          m_delete(urls, lower_case(Fins.Util.get_xip_io_url(app->get_application())->host));
          
          app->stop();
          object resp = Fins.Response(request);
          resp->redirect("/");
          return resp->get_response();
        }
        
        else if(request->variables->start && request->variables->start == ident)
        {
          call_out(restart_app, 0.0, app);
          object resp = Fins.Response(request);
          resp->redirect("/");
          return resp->get_response();
        }
        
        else if(request->variables->restart && request->variables->restart == ident)
        {
          foreach(app->urls; string url;)
          {
            m_delete(urls, url);
          }
          
          m_delete(urls, lower_case(Fins.Util.get_xip_io_url(app->get_application())->host));
          
          app->stop();

          call_out(restart_app, 0.0, app);
          object resp = Fins.Response(request);
          resp->redirect("/");
          return resp->get_response();
        }
        
      }
      
      string func;
      
      switch(app->status)
      {
        case "STARTED":
          func = "stop";
          break;
        case "STOPPED":
          func = "start";
          break;
        case "FAILED":
          func = "restart";
          break;
      } 
      
      response += ("<tr><td>" 
        + ident + "</td><td>" 
        + app->status  + "</td><td>" 
        + app->status_last_change->format_time() + "</td><td>" 
        + (url?("<a href=\"" + url + "\">" + url + "</a>"):"") + "</td><td>" );
        
      string ports = ""; 
      if(app && sizeof(app->get_ports()))
        ports = (app->get_ports()->port->query_address() * "<br>");
      response += (ports + "</td><td>");
        
        if(func) response += ("[ <a href=\"?" + func + "=" + ident + "\">" + String.capitalize(func) + "</a> ]\n");
        
        response += "</td></tr>\n";
    }

    response += "</table>\n";

  }
  else
  {
    response += "No applications configured.\n";
  }
  
  response += "<p>";
  response += "<h2>Threads</h2>\n";
  response += "<table cellpadding=5><tr><th>Thread ID</th><th>Status</th><th>Handler</th><th>Name</th><th>Execution Point</th></tr>\n";

  foreach(Thread.all_threads();; object thread)
  {
    response += ("<tr><td>" + thread->id_number() +  "</td><td>" 
      + ([Thread.THREAD_NOT_STARTED: "NOT_STARTED", Thread.THREAD_RUNNING: "RUNNING", Thread.THREAD_EXITED: "EXITED"])[thread->status()] + "</td><td>" 
      + (thread->handler||"-") + "</td><td>" 
      + (thread->thread_name || "-") + "</td><td><pre>" 
      + describe_backtrace(({thread->backtrace()[-1]})) + "</pre></td></tr>\n");
  }
  
  response += "</table>\n";

  r->set_data(response);
  return r->get_response();
}

mapping http_string_response(object request, string r, object|void access_logger)
{
  return http_code_response(request, 200, r, access_logger);  
}

mapping http_code_response(object request, int code, string r, object|void access_logger)
{
  mapping response = ([]);
  response->error = code;
  response->server="FinServe " + my_version;
  response->type = "text/html";
  response->data = r;
  response->request = request;
  if(access_logger) access_logger(response);
  return response;  
}

mapping http_exception_response(object request, mixed err, object|void access_logger)
{
  err = Error.mkerror(err);
  logger->exception("Error occurred while handling request!", err);

  string r = "<h1>An error occurred while processing your request:</h1>\n"
                   "<pre>" + describe_backtrace(err) + "</pre>";  
  return http_code_response(request, 500, r, access_logger);
}

void thread_handle_request(Protocols.HTTP.Server.Request request)
{
  mixed r;
  object app = request->fins_app;
  mixed e;

  if(!app) // show the admin page.
  {
    mapping r;
    mixed err;
    mixed addrs;
    
    if(1)//request->remoteaddr && (addrs = gethostbyaddr(request->remoteaddr)) && search(addrs, "localhost") != -1)
      err = catch(r = do_admin_request(request));
    else
    {
      r = http_code_response(request, 403, "<h1>Access Denied by IP</h1>\n");
    }
    // TODO
    // we should do access logging, and also deal with errors if they occur.

    if(err)
    {
      r = http_exception_response(request, err);
    }
    
    request->response_and_finish(r);  
    return 0;
  }
  
//  werror("app: %O, app_runner: %O, session_manager: %O\n", app, app->app_runner, app->app_runner->get_session_manager());
  object session_manager = app->app_runner->get_session_manager();
  // Do we have either the session cookie or the PSESSIONID var?
  if(request->cookies && request->cookies[session_cookie_name]
       || request->variables[session_cookie_name] )
  {
    e = catch 
    {  
      string ssid=request->cookies[session_cookie_name]||request->variables[session_cookie_name];
      object /*Session.Session*/ sess = session_manager->get_session(ssid);
      request->get_session_by_id = session_manager->get_session;
      request->misc->_session = sess;
      request->misc->session_id = sess->id;
      request->misc->session_variables = sess->data;
    };
  }

  // it all comes down to this... tell the app to handle this request!
  if(!e)
  {
    e = catch {
      r = app->handle_request(request);
    };  
  }
      
  if(e)
  {
    request->response_and_finish(http_exception_response(request, e, app->access_logger));
    return 0;
  }

  e = catch {
    if(mappingp(r))
    {
      app->access_logger(r);
      if(!r->_is_pipe_response)
      {
        request->response_and_finish(r);
      }
    }
    else if(stringp(r))
    {
      request->response_and_finish(http_string_response(request, r));
    }
    else
    {
      logger->debug("Got nothing from the application for the request %O, referrer: %O. Probably means the request passed through an index action unhandled.", request, request->referrer);
      if(e) logger->exception("An error occurred while processing the request\n", e);

      r = "<h1>Page not found</h1>"
                       "Fins was unable to find a handler for " + request->not_query + ".";

      request->response_and_finish(http_code_response(request, 404, r, app->access_logger));
    }
  };

  if(request->misc->_session)
  {
     // we need to set this explicitly, in case the link was broken.
     request->misc->_session->data = request->misc->session_variables;
     session_manager->set_session(request->misc->_session->id, request->misc->_session,
                                  session_timeout);
  }

  if(e)
  {
    request->response_and_finish(http_exception_response(request, e, app->access_logger));
  }

  return 0;
}
  
void new_session(object request, object response, mixed ... args)
{
  object session_manager = request->fins_app->app_runner->get_session_manager();

  string ssid=session_manager->new_sessionid();
  response->set_cookie(session_cookie_name,
                           ssid, time() + session_timeout);

  string req=request->not_query;
  req += "?PSESSIONID="+ssid;
  if( sizeof(request->query) )
  {
    req += "&"+request->query;
  }
  response->redirect(req);

  logger->debug( "Created new session app='%s/%s' sid='%s' host='%s'",
    request->fins_app->config->app_name, 
    request->fins_app->config->config_name,
    ssid,
    request->get_client_addr());
}

void destroy()
{
  if(logger && sizeof(apps)) logger->info("Shutting down Fins applications.");
  if(sizeof(apps)) 
  {
    foreach(apps;;object runner)
      runner->stop();
  }

  exit(0);
}