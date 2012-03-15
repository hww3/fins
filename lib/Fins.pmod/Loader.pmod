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

  // we shouldn't need to lock here.
  master()->handlers_for_thread[Thread.this_thread()] = key;
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
   
  write("handler_name: %O = %s\n", Thread.this_thread(), handler_name); 
  master()->handlers_for_thread[Thread.this_thread()] = handler_name;
  string logcfg = combine_path(app_dir, "config", "log_" + config_name+".cfg");
  Tools.Logging.set_config_variables((["appdir": app_dir, "config": config_name, "home": getenv("HOME") ]));

  Log.info("Loading log configuration from " + logcfg + ", if present.");

  if(file_stat(logcfg))
    Tools.Logging.set_config_file(logcfg);

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

  object al = Tools.Logging.get_logger("access");
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

  return Fins.Configuration(app_dir, config_file);
}
