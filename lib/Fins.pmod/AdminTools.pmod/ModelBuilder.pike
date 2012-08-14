import Tools.Logging;

object app;
//Fins.Application app;
string project;
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

  if(!sizeof(args))
  {
    Log.error("ModelBuilder requires the name of the application to work with.");
    exit(1);
  }

  foreach(Getopt.find_all_options(args,aggregate(
    ({"help",Getopt.NO_ARG,({"--help"}) }),
    ({"config",Getopt.HAS_ARG,({"--config", "-c"}) }),
    ({"model",Getopt.HAS_ARG,({"--model", "-m"}) }),
    ({"force",Getopt.NO_ARG,({"--force", "-f"}) }),
    )),array opt)
    {
      switch(opt[0])
      {
        case "help":
  		  print_help();
		  return 0;
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

	args-=({0});
	argc = sizeof(args);

  if(argc) project = args[0];

  if(argc>1)
    commands = args[1..];
}

int run()
{
  Log.info("ModelBuilder module running.");

  project = combine_path(getcwd(), project);

  Fins.Loader.set_multi_tenant(0);

  app = Fins.Loader.load_app(project, config_name);  

  Log.debug("Application loaded.");

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
	werror("Usage: pike -x fins model [-f|--force] [-c config] [-m modelid] AppDir (scan | [add table [table1... tableN]])\n");
	return;
}

