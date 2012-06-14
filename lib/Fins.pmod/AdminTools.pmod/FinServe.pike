#!/usr/local/bin/pike -Mlib -DLOCALE_DEBUG

//import Fins;
//import Tools.Logging;
//inherit Fins.Bootstrap;

#define DEFAULT_CONFIG_NAME "dev"

object logger;

function(object:void) ready_callback;

constant default_port = 8080;
constant my_version = "0.2";

mapping status = ([]);

// we really want the default to be RAM.
string session_storagetype = "ram";
//string session_storagetype = "file";
//string session_storagetype = "sqlite";
//string session_storagedir = "/tmp/scriptrunner_storage";
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

mapping/*(object:Session.SessionManager)*/ managers = ([]);
mapping(object|string:Thread.Thread) workers = ([]);
mapping(string:object|int) urls = ([]);
multiset(Protocols.HTTP.Server.Port) ports = (<>);
Thread.Queue admin_queue = Thread.Queue();

#if constant(_Protocols_DNS_SD) &&  constant(Protocols.DNS_SD.Service);

#endif
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
 // ::create();
}

int run()
{
  return main(sizeof(tool_args) + 1, ({""}) + tool_args);
}

void print_status()
{
  werror("status: %O\n", status);
}

int main(int argc, array(string) argv)
{
  int my_port = default_port;
  array(string) config_name = ({});
//  Pike.DefaultBackend->call_out(print_status, 1);
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
    status[pn + "/" + config_name[i]] = "STOPPED";
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

#if constant(fork)
  if(!hilfe_mode && go_background && fork())
  {
    // first, we attempt to open the log file; if we can't, bail out.
    object lf;
    mixed e = catch(lf = Stdio.File(logfile, "crwa"));
    if(e) 
    {
      werror("Unable to open log file: " + Error.mkerror(e)->message());
      werror("Exiting.\n");
      exit(1);
    }
    write("Entering Daemon mode...\n");
    write("Directing output to %s.\n", logfile);
    return 0;
  }
  if(!hilfe_mode && go_background)
  {
    // we should be in the forked copy.
    write("FinServe daemon pid: %d\n", getpid());
    Stdio.stdin.close();
    Stdio.stdin.open("/dev/null", "crwa");
    Stdio.stdout.close();
    Stdio.stdout.open(logfile, "crwa");
    Stdio.stderr.close();
    Stdio.stderr.open(logfile, "crwa");
  }
#endif /* fork() */

  logger=master()->resolv("Tools.Logging.get_logger")("finserve");

  if(hilfe_mode && sizeof(projects) > 1)
  {
    werror("hilfe mode is only available when starting 1 application.\n");
    exit(1);
  }

  if(hilfe_mode)
  {
    foreach(projects;int i;string project)
    {
      int res = start_app(project, config_name[i]);
      if(res == 0) return 0;
    }
  }
  else
  {
    if(start_admin(((int)my_port))) return 0;
    call_out(schedule_start_app, 5, projects, config_name);
  }

  return -1;

}

void run_hilfe(object app)
{
  write("\nStarting interactive interpreter...\n");
  add_constant("application", app);
  object in = Stdio.FILE("stdin");
  object out = Stdio.File("stdout");
  object o = Fins.Helpers.Hilfe.FinsHilfe();
  exit(1);
  return;
}

int start_current_position = 0;

void schedule_start_app(array projects, array config_name)
{
  if(start_current_position < sizeof(projects))
  {
    int res = start_app(projects[start_current_position], config_name[start_current_position]);
    call_out(schedule_start_app, 0.5, projects, config_name);
    start_current_position++;
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

    workers["admin"] = start_admin_worker_thread();
}

int start_app(string project, string config_name, int|void solo)
{
  object app = Fins.Util.AppRunner(project, config_name);
  
  app->load_app();

  app->__fin_serve = this;

  apps[ident] = app;

  if(hilfe_mode)
  {
    // apps typically have deferred startup for things like controllers
    // and such. Running the back end once or twice will allow deferred actions
    // to run so that we hopefully have things like controllers started up.
    Pike.DefaultBackend(0.0);
    Pike.DefaultBackend(0.0);

    object _master = master();

    if(_master->multi_tenant_aware)
    {
      _master->low_create_thread(run_hilfe, app->config->handler_name, app);
    }
    else
    {
      Thread.Thread(run_hilfe, app);
    }
    return -1;
  }
  else
  {
    app->register_ports();

    workers[app] = start_worker_thread(app, combine_path(getcwd(), project) + "#" + config_name);

    // TODO: do we need to call this for each application?
    call_out(session_startup, 0, app);

    status[ident] = "STARTED";

    if(p)
      logger->info("Application %s is ready for business on port %d.", ident, p);
    else
      logger->info("Application %s is ready for business on admin hosting port %d.", ident, admin_port);

    // TODO: do we need to call this for each application?
    if(ready_callback)
	call_out(ready_callback, 0, this);

    has_started = 1;

    return -1;
  }
}

Thread.Thread start_worker_thread(object app, string key)
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

Thread.Thread start_admin_worker_thread()
{
  Thread.Thread t;
  t = Thread.Thread(run_admin_worker);
  return t;
}

void run_worker(object app)
{

  // TODO we should probably have a little more sophistication built in here; probably
  // need to consider what happen if we want to shut down, etc.
  int keep_running = 1;
  
  do
  {
//    werror("loop\n");
    object r = app->queue->read();
    
    if(r)
      thread_handle_request(r);
//    werror("handled request.\n");
  } while(keep_running);
}

void run_admin_worker()
{

  // TODO we should probably have a little more sophistication built in here; probably
  // need to consider what happen if we want to shut down, etc.
  int keep_running = 1;
  
  do
  {
//    werror("loop\n");
    object r = admin_queue->read();
    
    if(r)
      thread_handle_request(r);
//    werror("handled request.\n");
  } while(keep_running);
}

void session_startup(object app)
{
  object s;
  object session_manager;

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

  managers[app] = session_manager;

}

void handle_request(Protocols.HTTP.Server.Request request)
{
  Thread.Queue queue;

  queue = request->fins_app->queue;
  queue->write(request);  
}

void admin_handle_request(Protocols.HTTP.Server.Request request)
{
  if(request->protocol == "HTTP/1.1" && request->request_headers["host"])
  {
    string host = lower_case(request->request_headers["host"]);
    host = (host/":")[0];
//    werror("parsing host = %O\n", host);

    object|int app;
    if(!(app = urls[host]))
    {
       foreach(urls; string u; object a)
       {
         if(has_suffix(host, "." + u))
         {
           app = urls[host] = a;
           break; 
         }
       }      
    }

    if(!app || app == -1)
    {
       urls[host] = -1;
    }
    else
    {
      request->fins_app = app;
      handle_request(request);
      return;
    }
  }


  // now that we have the pesky ip-less virtual hosting out of the way, let's get down to the business!
  admin_queue->write(request);
  
  return;
}

mapping do_admin_request(object request)
{
  object r = Fins.Response(request);
  string response = "Welcome to FinServe " + my_version + ".<p>\n";
  if(sizeof(apps))
  {
    response += "Apps currently configured:<p>\n";
    response += "<table><tr><th>Application/Config</th><th>State</th><th>URL</th></tr>\n";

    foreach(status;string ident; string stat)
    {
      string url;
      if(apps[ident])
      {
        catch(url = (string)apps[ident]->get_my_url());
      }
      response += ("<tr><td>" + ident + "</td><td>" + stat + "</td><td>" + (url?("<a href=\"" + url + "\">" + url + "</a>"):"") + "</td></tr>\n");
    }
  }
  else
  {
    response += "No applications configured.\n";
  }
  r->set_data(response);
  return r->get_response();
}

void thread_handle_request(Protocols.HTTP.Server.Request request)
{
  mixed r;
  object app = request->fins_app;
  object session_manager = managers[app];
  mixed e;

  if(!app) // show the admin page.
  {
    mapping r = do_admin_request(request);
    // TODO
    // we should do access logging, and also deal with errors if they occur.
    request->response_and_finish(r);  
    return;
  }
  else
  {
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
      e = catch {
        r = app->handle_request(request);
      };
  }

  if(e)
  {
    logger->exception("Error occurred while handling request!", e);
    mapping response = ([]);
    response->error=500;
    response->type="text/html";
    response->data = "<h1>An error occurred while processing your request:</h1>\n"
                     "<pre>" + describe_backtrace(e) + "</pre>";
    response->request = request;
    app->access_logger(response);

    request->response_and_finish(response);
    return 0;
  }

  e = catch {
    if(mappingp(r))
    {
      app->access_logger(r);
      if(!r->_is_pipe_response)
      {
//        werror("respnse_and_finish 2\n");
        request->response_and_finish(r);
      }
    }
    else if(stringp(r))
    {
      mapping response = ([]);
      response->server="FinServe " + my_version;
      response->type = "text/html";
      response->error = 200;
      response->data = r;
      response->request = request;
      app->access_logger(response);
//      werror("respnse_and_finish 3\n");
      request->response_and_finish(response);
    }
    else
    {
      logger->debug("Got nothing from the application for the request %O, referrer: %O. Probably means the request passed through an index action unhandled.", request, request->referrer);
      if(e) logger->exception("An error occurred while processing the request\n", e);
      mapping response = ([]);
      response->server="FinServe " + my_version;
      response->type = "text/html";
      response->error = 404;
      response->data = "<h1>Page not found</h1>"
                       "Fins was unable to find a handler for " + request->not_query + ".";
      response->request = request;
      app->access_logger(response);
//      werror("respnse_and_finish 4\n");
      request->response_and_finish(response);
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
    logger->exception("Internal Server Error!", e);
    mapping response = ([]);
    response->error=500;
    response->type="text/html";
    response->data = "<h1>Internal Server Error</h1>\n"
                     "<pre>" + describe_backtrace(e) + "</pre>";
    response->request = request;
    app->access_logger(response);
//    werror("respnse_and_finish 5\n");
    request->response_and_finish(response);
    return 0;
  }

  return 0;
}

object load_application(string project, string config_name)
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
  
void new_session(object request, object response, mixed ... args)
{
  object session_manager = managers[request->fins_app];

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
  if(logger && sizeof(ports)) logger->info("Shutting down Fins applications.");
  if(sizeof(ports)) 
  {
    object port;
    foreach(ports;object port;)
    {
      destruct(port->get_app());
      destruct(port);
    }
  }

  exit(0);
}
