#!/usr/local/bin/pike -Mlib -DLOCALE_DEBUG

//import Fins;
import Tools.Logging;
//inherit Fins.Bootstrap;

function access_logger;
object logger;

function(object:void) ready_callback;

constant default_port = 8080;
constant my_version = "0.1";
int my_port;

// we really want the default to be RAM.
string session_storagetype = "ram";
//string session_storagetype = "file";
//string session_storagetype = "sqlite";
//string session_storagedir = "/tmp/scriptrunner_storage";
string session_storagedir = 0;

string logfile_path = "/tmp/scriptrunner.log";
string session_cookie_name = "PSESSIONID";
int session_timeout = 7200;

Session.SessionManager session_manager;

object /*Fins.Application*/ app;
Protocols.HTTP.Server.Port port;
program server = fins_app_port;

#if constant(_Protocols_DNS_SD)

#if constant(Protocols.DNS_SD.Service);

Protocols.DNS_SD.Service bonjour;

#endif
#endif
int hilfe_mode = 0;
string project = "default";
string config_name = "dev";
int go_background = 0;
private int has_started = 0;
void print_help()
{
	werror("Help: fin_serve [-p portnum|--port=portnum|--hilfe] [-s ram|file|sqlite|--session-manager=ram|file|sqlite [-l "
		"storage_path|--session-storage-location=storage_path]] [-c|--config configname] [-d]  appname\n");
}

array tool_args;

int(0..1) started()
{
  if(port && has_started) return 1;
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

int main(int argc, array(string) argv)
{
  my_port = default_port;

  foreach(Getopt.find_all_options(argv,aggregate(
    ({"port",Getopt.HAS_ARG,({"-p", "--port"}) }),
    ({"config",Getopt.HAS_ARG,({"-c", "--config"}) }),
    ({"sessionmgr",Getopt.HAS_ARG,({"-s", "--session-manager"}) }),
    ({"sessionloc",Getopt.HAS_ARG,({"-l", "--session-storage-location"}) }),
#if constant(fork)
    ({"daemon",Getopt.NO_ARG,({"-d"}) }),
#endif /* fork() */
    ({"hilfe",Getopt.NO_ARG,({"--hilfe"}) }),
    ({"help",Getopt.NO_ARG,({"--help"}) }),
    )),array opt)
    {
      switch(opt[0])
      {
		case "port":
		my_port = opt[1];
		break;
		
		case "config":
		config_name = opt[1];
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
		
        case "help":
		print_help();
		return 0;
		break;
	  }
	}
	
	argv-=({0});
	argc = sizeof(argv);


  if(argc>=2) project = argv[1];

  int x = do_startup();

  return x;
}

int do_startup()
{

#if constant(fork)
  if(!hilfe_mode && go_background && fork())
	{
		werror("Entered Daemon mode...\n");
		return 0;
	}

#endif /* fork() */

  Log.info("FinServe starting on port " + my_port);

  Log.info("FinServe loading application " + project + " using configuration " + config_name);
  load_application();
  logger=Tools.Logging.get_default_logger();

  app->__fin_serve = this;

  logger->info("Application " + project + " loaded.");

  if(hilfe_mode)
  {
    // apps typically have deferred startup for things like controllers
    // and such. Running the back end once or twice will allow deferred actions
    // to run so that we hopefully have things like controllers started up.
    Pike.DefaultBackend(0.0);
    Pike.DefaultBackend(0.0);

    write("\nStarting interactive interpreter...\n");
    add_constant("application", app);
    object in = Stdio.FILE("stdin");
    object out = Stdio.File("stdout");
    object o = Fins.Helpers.Hilfe.FinsHilfe();
    return 0;
  }
  else
  {
    object al = Tools.Logging.get_logger("access");
    if(al->log) access_logger = al->log;
    else access_logger = genlogger(al);
    port = server(handle_request, (int)my_port);  
    port->set_app(app);
    port->request_program = Fins.HTTPRequest;

#if constant(_Protocols_DNS_SD)
#if constant(Protocols.DNS_SD.Service);
    bonjour = Protocols.DNS_SD.Service("Fins Application (" + project + "/" + config_name + ")",
                     "_http._tcp", "", (int)my_port);

    logger->info("Advertising this application via Bonjour.");
#endif
#endif

    call_out(session_startup, 0);
    logger->info("FinServe listening on port " + my_port);
    logger->info("Application ready for business.");
    if(ready_callback)
	call_out(ready_callback, 0, this);

    has_started = 1;

    return -1;
  }
}

function genlogger(object al)
{
  return lambda(mapping m){al->do_msg(10,"%O", m);};
}

void session_startup()
{
  Session.SessionStorage s;

  Log.info("Starting Session Manager.");

  session_manager = Session.SessionManager();

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
        Log.error("You must specify a filesystem location in order to use file-based session storage.");
        exit(1);
      }
      Log.info("SessionManager will use files in " + session_storagedir + " to store session data.");
      s = Session.FileSessionStorage();
      s->set_storagedir(session_storagedir);
      break;

    case "sqlite":
      if(!session_storagedir)
      {
        Log.error("You must specify a database location in order to use SQLite session storage.");
        exit(1);
      }
      Log.info("SessionManager will use SQLite database " + session_storagedir + " to store session data.");
      s = Session.SQLiteSessionStorage();
      s->set_storagedir(session_storagedir);
      break;

    case "ram":
      Log.info("SessionManager will use RAM to store session data.");
      s = Session.RAMSessionStorage();
      break;
	
    default:
      Log.warn("Unknown session storage type '" + session_storagetype + "'."); 
      Log.info("SessionManager will use RAM to store session data.");
      s = Session.RAMSessionStorage();
      break;
  }

  session_manager->set_default_timeout(session_timeout);
  session_manager->set_cleaner_interval(session_timeout + random(session_timeout)/2	);
  session_manager->session_storage = ({s});

  add_constant("Session", Session.Session);
  add_constant("session_manager", session_manager);

}

void handle_request(Protocols.HTTP.Server.Request request)
{
  Thread.Queue queue;

  write("id: %O\n", request->my_fd->query_id());
  queue = request->app->queue;
  thread_handle_request(request);
  queue->write(request);  
}

void thread_handle_request(Protocols.HTTP.Server.Request request)
{
  mixed r;
//access_logger(request);
  // Do we have either the session cookie or the PSESSIONID var?
  if(request->cookies && request->cookies[session_cookie_name]
         || request->variables[session_cookie_name] )
  {
    string ssid=request->cookies[session_cookie_name]||request->variables[session_cookie_name];
    Session.Session sess = session_manager->get_session(ssid);
    request->get_session_by_id = session_manager->get_session;
    request->misc->_session = sess;
    request->misc->session_id = sess->id;
    request->misc->session_variables = sess->data;
  }

  mixed e = catch {
    r = request->app->handle_request(request);
  };

  if(e)
  {
//describe_backtrace(e);
    Log.exception("Error occurred while handling request!", e);
    mapping response = ([]);
    response->error=500;
    response->type="text/html";
    response->data = "<h1>An error occurred while processing your request:</h1>\n"
                     "<pre>" + describe_backtrace(e) + "</pre>";
    response->request = request;
    access_logger(response);
    request->response_and_finish(response);
    return;
  }

  e = catch {
    if(mappingp(r))
    {
      access_logger(r);
      if(!r->_is_pipe_response)
        request->response_and_finish(r);
    }
    else if(stringp(r))
    {
      mapping response = ([]);
      response->server="FinServe " + my_version;
      response->type = "text/html";
      response->error = 200;
      response->data = r;
      response->request = request;
      access_logger(response);
      request->response_and_finish(response);
    }
    else
    {
      Log.debug("Got nothing from the application for the request %O, referrer: %O. Probably means the request passed through an index action unhandled.\n", request, request->referrer);
      if(e) Log.exception("An error occurred while processing the request\n", e);
      mapping response = ([]);
      response->server="FinServe " + my_version;
      response->type = "text/html";
      response->error = 404;
      response->data = "<h1>Page not found</h1>"
                       "Fins was unable to find a handler for " + request->not_query + ".";
      response->request = request;
      access_logger(response);
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
    access_logger(response);
    request->response_and_finish(response);
    return;
  }

  return;
}

void load_application()
{
  object application;
  mixed err = catch(
  application = master()->resolv("Fins.Loader")->load_app(combine_path(getcwd(), project), config_name));
  if(err || !application)
  {
    if(err) Log.exception("An error occurred while loading the application.", err);
    else Log.critical("An error occurred while loading the application.");
    exit(1);
  }

  app = application;

}
  void new_session(object request, object response, mixed ... args)
  {
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

    logger->debug( "Created new session sid='%s' host='%s'",ssid,request->get_client_addr());
  }

void destroy()
{
  if(logger) logger->info("Shutting down Fins application.");
  if(port) destruct(port);
}


class fins_app_port
{
  inherit Protocols.HTTP.Server.Port;

  protected object app;

  public void set_app(object application)
  {
    app = application;
  }

  protected void new_connection()
  {
    while( Stdio.File fd=port->accept() )
    {
        .Request r=request_program();
        r->fins_app = app;
        r->attach_fd(fd,this,callback);
    }
  }
}
