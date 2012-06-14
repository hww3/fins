string status;

object app;

array ports = ({});
multiset urls = (<>);

static object logger;
string project;
string config;
string ident;

static void create(string _project, string _config)
{
  object app;
  object port;
  
  logger=master()->resolv("Tools.Logging.get_logger")("finserve");
  project = _project;
  config = _config;
  ident = sprintf("%s/%s", project, config_name);
}
  
void load_app()
{
  ident = sprintf("%s/%s", project, config_name);
  
  logger->info("FinServe loading application from " + project + " using configuration " + config_name);
  
  status = "LOADING";
  
  
  app = load_application(project, config_name);

  if(!app)
  {
    ident = "FAILED";
    logger->critical("Application in %s failed to load.", ident);
    throw(Error.Generic("Application failed to load.\n"));
  }
  
  status = "LOADED";
  logger->info("Application %s loaded.", ident);
}

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