
static mapping loggers = ([]);

string config_file_path;
mapping config_values = ([]);
mapping appenders = ([]);
mapping config_variables = ([]);
static array _rk;
static array _rv;

int is_configed = 0;

mapping _default_config_variables = (["host": gethostname(), 
				"pid": (string)getpid(), 
				"user": Tools.System.get_user() ]);

mapping _default_logger_config = (["appender": "default", "level": "INFO"]);

object default_logger = Tools.Logging.Log.Logger();

//! 
//!  configuration file is standard ini-style.
//!
//!  [logger.logger_name] <-- configures a logger named "logger_name", loggers are hierarchal, with "." separating
//!  the various components in the logger hierarchy. For example, "myapp.subsystem.component". The root logger
//!  from which all configurations inherit, is called "default".
//!
//!  level=TRACE|DEBUG|INFO|WARN|ERROR <-- optional log level for this logger
//!
//!  appender=appender_name <-- use the appender "appender_name", may be specified multiple times
//!
//!  class=Some.Pike.Class <-- use the specified pike class as logger,
//!    defaults to Tools.Logging.Log.Logger
//!
//!  additivity=false <-- do not use the parent configuration as a basis for this logger's configuration to override.
//!    Defaults to "true", in which case any value not specified in the child will be sourced from the parent. If set to 
//!    true, any logger targets from the parent will also be added to the child.
//!
//!  enable=true/false/yes/no <-- whether the logger should generate entries
//!
//!  [appender.appender_name] <-- configures an appender named "appender_name"
//!
//!  class=Some.Pike.Class <-- use the specified pike class for appending
//!
//!  format=someformatstring
//!  you may include replacements in the format to place different data according to your preferences. the format 
//!  for specifying a replacement is %{field}, available fields differ between loggers, but generally include 
//!  the following: name, level, msg, pid, host plus any of the values from @[localtime]().
//!
//!  see also the note below about configuration variables, which may be inserted into your format string (values
//!  are inserted at configuration time, and are static thereafter).
//!
//!  enable=true/false/yes/no <-- whether the appender should generate entries
//!  
//!  example: Tools.Logging.Log.FileAppender uses argument "file" to specify logging file
//!
//!  @note 
//!  if the configuring application specifies any, you may use substitution variables
//!  in the form ${varname} in your configuration values. By default, "host", "user" and "pid"
//!  are available.
//!
//! @note
//!  regardless of configuration, a default logger will always be available.
//!  a configuration file may specify an alternate default logger configuration
//!  by using a config section called [default.logger].


static void create()
{

//werror("***\n*** %O -> %O\n***\n", Thread.this_thread(), master()->get_handler_for_thread(Thread.this_thread()));
  create_default_appender();
  config_values["logger.default"] = _default_logger_config;
  set_config_variables(([]));
}

static void create_default_appender()
{
  appenders->default = Tools.Logging.Log.ConsoleAppender();
}

//! returns the default logger, which will always be available,
//! and which outputs to the console (unless this configuration is specifically
//! altered in the configuration file.)
object get_default_logger()
{
  	  return default_logger;
}

//! sets available configuration substitution variables, in addition to the standard
//! values of "host", "pid" and "user".
void set_config_variables(mapping vars)
{
  mapping v = _default_config_variables + vars;
   config_variables =  mkmapping(("${" + indices(v)[*])[*] + "}", values(v)); 
}

//! specifies a configuration file to be used, which will be loaded and parsed.
void set_config_file(string configfile)
{
  is_configed = 1;

//werror("***\n*** set cf %O -> %O\n***\n", Thread.this_thread(), master()->get_handler_for_thread(Thread.this_thread()));
  default_logger->info("setting log configuration using " + configfile);

  if(master()->multi_tenant_aware)    
    default_logger->warn("logger thread: %O, handler: %O", Thread.this_thread(), master()->get_handler_for_thread(Thread.this_thread()));
  if(!file_stat(configfile))
  {
    throw(Error.Generic("Configuration file " + configfile + " does not exist.\n"));
  }
  else
  {
    config_file_path = configfile;
  }

  load_config_file();

   config_values["logger.default"] = _default_logger_config + (config_values["logger.default"]||([])); 

  if(config_values["logger.default"])
  {
    default_logger->configure(config_values["logger.default"]);
    Tools.Logging.Log.configure(config_values["logger.default"]);
  }  
}

void load_config_file()
{
  string fc = Stdio.read_file(config_file_path);

  // the "spec" says that the file is utf-8 encoded.
  fc=utf8_to_string(fc);

  config_values = Public.Tools.ConfigFiles.Config.read(fc);  
}

//! get a logger for loggername
//!
//! by default, this call will always return a logger object. if the requested 
//! logger is not found, the nearest parent logger will be returned, up to and
//! including the default root logger.
//!
//! @param loggername
//!   may be a string, in which the logger is directly specified,
//!   or a program, in which case the logger name will be the 
//!   lower-cased full name of the program (as determined by the %O parameter to @[sprintf()], 
//!   with any "/" converted to ".".
//!
//! @param no_default_logger
//!   if specified, this flag will cause this call to return '0' if no logger
//!   with the requested name could be found.
//!
//! @example
//!   get_logger(Protocols.HTTP.client) 
//!
//! would request the logger named "protocols.http.client".
//! 
//! @note 
//!  loggers returned by this method are shared copies.
Tools.Logging.Log.Logger get_logger(string|program loggername, int|void no_default_logger)
{

//  if(master()->multi_tenant_aware)
//    default_logger->warn("logger thread: %O, handler: %O", Thread.this_thread(), master()->get_handler_for_thread(Thread.this_thread()));


  if(programp(loggername))
    loggername = replace(lower_case(sprintf("%O", loggername)), "/", ".");
  if(!loggers[loggername]) 
    loggers[loggername] = create_logger(loggername);

  return loggers[loggername] || get_default_logger();
}

Tools.Logging.Log.Logger create_logger(string loggername)
{
  object l = create_logger_from_config(loggername);

#if 0
  // go with a default.
  if(!l) {	
    default_logger->debug("no defined logger " + loggername + ", using default.");
   l = Tools.Logging.Log.Logger((["name":loggername]));
  }
#endif /* 0 */
  return l;
}

mapping build_logger_config(string loggername)
{
  if(!is_configed) 
  {
    default_logger->warn("logging system has not been configured yet, using default settings for <%s>.", loggername);
  }

  return low_build_logger_config(loggername);
}

mapping low_build_logger_config(string loggername)
{

  mapping cx = ([]);
  string cn;
  int need_to_add;

  //werror("build_logger_config(%O)\n", loggername);

  if(loggername == "") throw(Error.Generic("Foo!\n"));

  // first, find the nearest logger in the hierarchy.

  // "default" should always be present.
  cx = config_values["logger." + loggername];

  if(!cx)
  {
    if(loggername != "default")  // if we don't have an exact match
    {
      need_to_add = 1;
      // get the closest match.
      // generate a list of parts.
      array lp = ((loggername/".")-({""}));
      string ncn = lp[..<1] * ".";
      if(ncn == "")
        ncn = "default";
      cx = low_build_logger_config(ncn);
    }
    else
      cx = low_build_logger_config("default");
  }
  
  cn = loggername;

  if(!cx->additivity) cx->additivity = "true";

  cx["name"] = cn;
  cx["_name"] = cn;

  // do we want to blend in the previous higher level logger configuration in?

  default_logger->debug("configuring <%s>", (string)cn);
  if(cn != "default" && lower_case(cx->additivity) == "true")
  {
      // generate the parent logger name.
      array lp = ((cn/".")-({""}));
      string ncn = lp[..<1] * ".";
      if(ncn == "")
        ncn = "default";

      if(ncn!=loggername)
      {
      	default_logger->debug("<%s> - additivity is true, blending settings from parent logger %O", cn, ncn);
        mapping lc = low_build_logger_config(ncn);
//werror("first: <%s>: %O\n", cn, cx);
        cx = additize(cx, lc);
      }
  }

  if(need_to_add)
    config_values["logger." + loggername] = cx;

  //werror("after: <%s>: %O\n", loggername, cx);

  return cx;
}

protected mapping additize(mapping a, mapping b)
{
  mapping c = ([]);

  foreach(b; string k; mixed v)
  {
    if(k != "appender")
    {
      if(!has_index(a, k))
        c[k] = v;
      else
        c[k] = a[k];

      continue;
    }
    else
    {
      if(!has_index(a, k))
      {
        c[k] = v;
        continue;
      }

      if(!arrayp(a[k]))
        c[k] = ({a[k]});
      else c[k] = a[k];

      if(!arrayp(v))
        c[k] += ({v});
      else c[k] += v; 

      c[k] = Array.uniq(c[k]);
    }
  }

  return c;

}

//!
string get_default_level()
{
  return (config_values["logger.default"]->level) || "INFO";
}

Tools.Logging.Log.Logger create_logger_from_config(string loggername)
{
  // get the nearest logger configuration.
  mapping cx;

  cx = build_logger_config(loggername);

  if(!cx) return 0;

  // werror("config: %O\n", cx);

  cx->name = loggername;

  cx = insert_config_variables(cx);

  //werror("config: <%s>: %O\n", loggername, cx); 

  if(!cx->level) 
  {
    string default_level = get_default_level();
    default_logger->warn("no log level set for logger " + cx->name +". using default level " + default_level + ".");
    cx->level = default_level;
  }

  program loggerclass;
  if(cx->class)
  {
    program lc = master()->resolv(cx["class"]);
    if(lc) loggerclass = lc;
    else
      throw(Error.Generic("Logger type " + cx["class"] + " does not exist.\n"));
      
  }
  if(!loggerclass)
    loggerclass = Tools.Logging.Log.Logger;
  
  object l = loggerclass(cx);
  
  return l;
}

array get_appenders(array config)
{
  if(!config) return ({ appenders["default"] });  

  array a = ({});

  //werror("get_appenders(%O)\n", config);

  foreach(config;; string appender_config)
  {
    object ap = get_appender(appender_config);
    if(ap)
      a += ({ ap });
  }

  return a;
}

object get_appender(string config)
{
  if(!appenders[config])
  {
    mapping c = config_values["appender." + config];
  
    if(!c) return 0;

    c = insert_config_variables(c);

    object ap;
    program apc = master()->resolv(c["class"]);
    if(!apc) 
    {
      throw(Error.Generic("Appender type " + c["class"] + " does not exist.\n"));
    }

    ap = apc(c);

    appenders[config] = ap;
  }

  return appenders[config];
}

mapping insert_config_variables(mapping c)
{
  foreach(c; string k; string v)
  {
    if(v)
      c[k] = replace(v, indices(config_variables), values(config_variables));
  }

  return c;
}
