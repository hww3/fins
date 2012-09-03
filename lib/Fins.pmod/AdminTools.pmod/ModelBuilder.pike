import Tools.Logging;

object app;
//Fins.Application app;
string appname;
string config_name = "dev";
array commands;
string model_id = Fins.Model.DEFAULT_MODEL;
int overwrite;

void create(array args)
{
	int argc;
	
//  Log.set_level(0);
  Log.info("ModelBuilder module loading");
  Log.info("Fins version " + Fins.__version);

  array a2 = ({""}) + args;

  foreach(Getopt.find_all_options(a2,aggregate(
    ({"help",Getopt.NO_ARG,({"--help"}) }),
    ({"config",Getopt.HAS_ARG,({"--config", "-c"}) }),
    ({"model",Getopt.HAS_ARG,({"--model", "-m"}) }),
    ({"app",Getopt.HAS_ARG,({"-a", "--application"}) }),
    ({"force",Getopt.NO_ARG,({"--force", "-f"}) }),
    )),array opt)
    {
      switch(opt[0])
      {
        case "help":
  		    print_help();
		      return 0;
		      break;
        case "app":
        werror("got appname.\n");
          appname = opt[1];
		      break;
        case "config":
          config_name = opt[1];
		      break;
        case "model":
          model_id = opt[1];
		      break;
       case "force":
          overwrite ++;
		      break;
	  }
	}

  args = a2[1..] - ({0});
	argc = sizeof(args);

  if(argc)
    commands = args;
}

void load_app()
{
  if(!appname)
  {
    Log.error("No application specified.");
    exit(3);
  }
  if(!config_name)
  {
    Log.error("No configuration specified.");  
    exit(6);
  }
  Log.error("Loading application %s with configuration %s.", appname, config_name);
  
  if(appname[0]!='/')
  {
    appname = Stdio.append_path(getcwd(), appname);
  }

  // we only load 1 app in this tool, so there's no need to do multi-tenancy
  // which makes it's easier to interact with the application from the main thread.
  Fins.Loader.set_multi_tenant(0);
  app = Fins.Loader.load_app(appname, config_name);
  
  if(!app)
  {
    Log.error("Unable to load application.");
    exit(2);
  }

}


int run()
{
  Log.info("ModelBuilder module running.");

  load_app();

  object modelbuilder = Fins.Util.ModelBuilder(app, model_id);
  
  if(modelbuilder->verify())
  {
    Log.error("ModelBuilder detected configuration errors. Please fix them and try again.");
    return 1;
  }

  modelbuilder->set_overwrite(overwrite);

  if(!commands) 
  {
    Log.error("Error: no command given.");
    print_help();
    return 1;
  }

  if(!(<"add", "scan">)[commands[0]])
  {
    Log.error("Error: bad command " + commands[0] + " given.");
    print_help();
    return 1;
  }

  if(commands[0] != "scan" && sizeof(commands) < 2)
  {
    Log.error("Error: no tables given.");
    print_help();
    return 1;
  }
  
  array tables_to_add = commands[1..];

  if(commands[0] == "scan")
  {
    tables_to_add = modelbuilder->scan();
    Log.info("Scan found %d tables to add: %s", sizeof(tables_to_add), tables_to_add * ", ");
  }

  if(!sizeof(tables_to_add))
  {
    Log.error("Error: no tables to add.");
    return 1;
  }

  return modelbuilder->add(tables_to_add);
}

void print_help()
{
	werror("Usage: pike -x fins model -a appdir [-f|--force] [-c config] [-m modelid] AppDir (scan | [add table [table1... tableN]])\n");
	return;
}

