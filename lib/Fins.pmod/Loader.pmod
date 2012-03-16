import Tools.Logging;

//! @param app_dir
//!   the full path to the application directory.


static void create()
{  
  werror("loader loaded.\n"); 
}

protected function genlogger(object al)
{
  return lambda(mapping m){al->do_msg(10,"%O", m);};
}

object load_app(string app_dir, string config_name)
{
  object handler;
  string key;
  
  if(!file_stat(app_dir)) 
    throw(Error.Generic("Application directory " + app_dir + " does not exist.\n"));
  
  key = app_dir + "#" + config_name;
  handler = master()->new_handler(key);
  werror("have handler.\n");
  //werror("adding %O\n", combine_path(app_dir, "modules"));

  // add_module_path calls root_module->add_path(), which consults fc.
  // therefore, unless we want to share a module directory with the default 
  // environment, we need to temporarily tell the master to use a non-default handler
  // on this thread. we could also alter add_module_path() to take and use the handler key instead.
  // also note that we shouldn't need to lock here.
  master()->handlers_for_thread[Thread.this_thread()] = key;
  foreach(handler->pike_module_path;;string p)
    handler->add_module_path(p);
  handler->add_module_path(combine_path(app_dir, "modules")); 
  m_delete(master()->handlers_for_thread, Thread.this_thread());

  handler->add_program_path(combine_path(app_dir, "classes")); 
  object thread = Thread.Thread(low_load_app, key, app_dir, config_name);  

  return thread->wait();
}

object low_load_app(string handler_name, string app_dir, string config_name)
{
  string cn;
  object a;
string b = "";

  write("handler_name: %O = %s\n", Thread.this_thread(), handler_name); 
  
  master()->handlers_for_thread[Thread.this_thread()] = handler_name;
  string logcfg = combine_path(app_dir, "config", "log_" + config_name+".cfg");
    
/*
  why, gentle reader, do we do the following?
  
*/

 string stub = 
#"void f(string app_dir, string config_name, string logcfg) {
Tools.Logging.set_config_variables(([\"appdir\": app_dir, \"config\": config_name, \"home\": getenv(\"HOME\") ]));
  if(file_stat(logcfg))
  {
    Tools.Logging.set_config_file(logcfg);
  }
 }
";

 Log.info("Loading log configuration from " + logcfg + ", if present.");
 compile_string(stub)()->f(app_dir, config_name, logcfg);

  Fins.Configuration config = load_configuration(app_dir, config_name);
  Log.info("Preparing to load application " + config->app_name + ".");

  program p;

  catch(cn = config["application"]["class"]);
  if(!cn) cn = "application";
mixed err = catch 
{
  p = master()->cast_to_program(cn);
  a = p(config);
};

  if(err)
  {
    Log.exception("error occurred while loading the application.", Error.mkerror(err));
    return a;
  }

  object access_logger;

 stub = 
#"object f() {
   return Tools.Logging.get_logger(\"access\");
 }
";

 object al = (compile_string(stub)()->f());

  if(al->log)
    access_logger = al->log;
  else
    access_logger = genlogger(al);

  a->access_logger = access_logger;

  //werror("FC: %O", master()->get_fc());

  return a;
}

Fins.Configuration load_configuration(string app_dir, string config_name)
{
  string config_file = combine_path(app_dir, "config", config_name+".cfg");

  Log.debug("config file: " + config_file);

  Stdio.Stat stat = file_stat(config_file);
  if(!stat || stat->isdir)
    throw(Error.Generic("Unable to load configuration file " + config_file + "\n"));

  return master()->resolv("Fins.Configuration")(app_dir, config_file);
}
