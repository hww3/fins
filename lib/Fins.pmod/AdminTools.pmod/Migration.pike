import Tools.Logging;

string appname;
string config_name = "dev";
array args;
object app;

void create(array(string) argv)
{
  Log.info("Migration module loading");
  args = argv;
}

void print_help()
{
  Log.error("Usage: pike -x fins migration -a appname -c configname [create \"migration description\"]|[run [-up | -down][migration1 [migrationN]]]\n");
  exit(1);
}
int run()
{
  Log.info("Migration tool running.");
  Log.info("Fins version " + Fins.__version);

  if(sizeof(args) < 2)
  {
    print_help();
  }
 
  array a2 = ({""}) + args;

  foreach(Getopt.find_all_options(a2,aggregate(
     ({"config",Getopt.HAS_ARG,({"-c", "--config"}) }),
     ({"app",Getopt.HAS_ARG,({"-a", "--application"}) }),
     ({"help",Getopt.NO_ARG,({"--help"}) }), 
     ), 0),array opt)
     {    
       switch(opt[0])
       {
   		   case "config":
 		       config_name = opt[1];
 		       break;
     		 case "app":
   		     appname = opt[1];
   		     break;
       }
     }

  string command;

  args = a2[1..] - ({0});
  object st;
  if(!(st = file_stat(appname)) || !st->isdir)
  {
    Log.error("Application %s doesn't exist.", appname);
    exit(5);
  }

  if(!sizeof(args))
  {
    Log.error("No command specified.");
    exit(4);
  }
  
  [command, args] = Array.shift(args);

  switch(command)
  {
    case "create":
      return do_create(@args);
      break;
      case "run":
        return do_run(@args);
        break;
    default:
      Log.error("Unknown command %O.", command);
      exit(1);
  }
  
  return 0;
}

void load_app()
{
  // FinsMode.get_context() will check for this constant and defer type registration if it exists.
  // Naturally, we want that, as there may be datatype mapping elements present that aren't reflected
  // in the schema (yet).
  add_constant("__defer_register_types", 1);
  
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

int do_run(string... args)
{
  int dir = Fins.Util.MigrationTask.UP;

  load_app();

  array a2 = ({" "}) + args;

  foreach(Getopt.find_all_options(a2,aggregate(
     ({"up",Getopt.NO_ARG,({"-u", "--up"}) }),
     ({"down",Getopt.NO_ARG,({"-d", "--down"}) }),
     )),array opt)
     {    
       switch(opt[0])
       {
   		   case "up":
  		     dir = Fins.Util.MigrationTask.UP;
 		       break;
     		 case "down":
   		     dir = Fins.Util.MigrationTask.DOWN;
   		     break;
       }
     }

  args = a2[1..] - ({0});
  
  object migrator = Fins.Util.Migrator(app);
  
  array migrations = migrator->get_migrations();
  
  if(dir == Fins.Util.MigrationTask.UP)
    migrator->announce("Applying migrations: ");
  else
  migrator->announce("Reverting migrations: ");
  migrator->write_func("%{" + (" "*3) + "- %s\n%}", migrations->name); 
  
  
  foreach(migrations;; object m)
  {
    m->run(dir);
  }
}

int do_create(string migration)
{
  if(!migration || !sizeof(migration))
  {
    Log.error("Migration name must be specified.");
    return 1;
  }

  load_app();

  string dir = Stdio.append_path(appname, Fins.Util.Migrator.MIGRATION_DIR);

  Stdio.mkdirhier(dir);
  string fn = Fins.Util.Migrator(app)->low_new_migration(migration, 0, dir);
  
  Log.info("Created new migration %s", fn);
  return 0;
}
