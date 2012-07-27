object logger = Tools.Logging.get_logger("finserve");
//! @param app_dir
//!   the full path to the application directory.


static void create()
{  
//  werror("loader loaded.\n"); 
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

  object _master = master();
  
  if(_master->multi_tenant_aware)
  {
    key = app_dir + "#" + config_name;
    handler = master()->new_handler(key);
   // werror("have handler.\n");
    //werror("adding %O\n", combine_path(app_dir, "modules"));

  // add_module_path calls root_module->add_path(), which consults fc.
  // therefore, unless we want to share a module directory with the default 
  // environment, we need to temporarily tell the master to use a non-default handler
  // on this thread. we could also alter add_module_path() to take and use the handler key instead.
  // also note that we shouldn't need to lock here.
  //
  // do we do the re-add of the module path in order to force the new
  // handler to re-init itself? seems like a kluge but may have been
  // simpler to accept this ugliness rather than rewriting more of the master.
    master()->handlers_for_thread[Thread.this_thread()] = key;
    foreach(reverse(handler->pike_module_path);;string p)
      handler->add_module_path(p);
    handler->add_module_path(combine_path(app_dir, "modules")); 
    m_delete(master()->handlers_for_thread, Thread.this_thread());

    handler->add_program_path(combine_path(app_dir, "classes")); 
    object thread = Thread.Thread(key, low_load_app, app_dir, config_name);  

    return thread->wait();
  }
  else // not running multi-tenant mode.
  {
    add_module_path(combine_path(app_dir, "modules")); 
    add_program_path(combine_path(app_dir, "classes")); 
    return low_load_app(app_dir, config_name);
  }
}

object low_load_app(string app_dir, string config_name)
{
  string cn;
  object a;
  string b = "";
  string logcfg = combine_path(app_dir, "config", "log_" + config_name+".cfg");
//  if(master()->multi_tenant_aware)
  {
//    write("handler_name: %O = %s\n", Thread.this_thread(), handler_name); 
 //   master()->handlers_for_thread[Thread.this_thread()] = handler_name;
  }

/*
  why, gentle reader, do we do the following?  
*/

 string stub = 
#"void f(string app_dir, string config_name, string logcfg, string app_name) {
Tools.Logging.set_config_variables(([\"appdir\": app_dir, \"app\": app_name, \"config\": config_name, \"home\": Tools.System.get_home() ]));
  if(file_stat(logcfg))
  {
    Tools.Logging.set_config_file(logcfg);
  }
 }
";


 logger->info("Loading app configuration from " + app_dir + ".");
  Fins.Configuration config = load_configuration(app_dir, config_name);
 logger->info("Loading log configuration from " + logcfg + ", if present.");
 compile_string(stub)()->f(app_dir, config_name, logcfg, config->app_name);

  logger->info("Preparing to load application " + config->app_name + ".");

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
    logger->exception("error occurred while loading the application.", Error.mkerror(err));
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

  logger->debug("config file: " + config_file);

  Stdio.Stat stat = file_stat(config_file);
  if(!stat || stat->isdir)
  {
    mixed err = Error.Generic("Unable to load configuration file " + config_file + "\n");

    logger->exception("Problem loading configuration.", err);
    throw(err);
  }
  return master()->resolv("Fins.Configuration")(app_dir, config_file);
}
