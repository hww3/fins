import Tools.Logging;

string appname;
string config_name = "dev";
array args;
object app;
int dryrun;

void create(array(string) argv)
{
  Log.info("Migration module loading");
  args = argv;
}

void print_help()
{
  Log.error("Usage: pike -x fins migration -a appname -c configname [-n|--dry-run] [create \"migration description\"]|[list]|[run [--up | --down] [throughMigration]]\n");
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
   		   case "help":
   		     print_help();
   		     return 0;
       }
     }

  string command;
werror("%O\n", a2);
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
    print_help();
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
      case "list":
        return do_list(@args);
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
  add_constant("__defer_full_startup", 1);
  
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

int do_list(string ... args)
{
  load_app();
  
  object migrator = Fins.Util.Migrator(app);

  array migrations;
  migrations = migrator->list_migrations();

  migrator->announce("All migrations in " + app->config->app_name);
  migrator->write_func(" Applied?    Name\n");

  foreach(migrations;; object m)
  {
    migrator->write_func("       %s     %s\n", (m->is_applied?"*":" "), m->name); 
  }
}

int do_run(string... args)
{
  string through;
  int dir = Fins.Util.MigrationTask.UP;

  load_app();
  
  array run_migrations = ({});

  array a2 = ({" "}) + args;
  foreach(Getopt.find_all_options(a2,aggregate(
     ({"migration",Getopt.HAS_ARG,({"-m", "--migration"}) }),
     ({"up",Getopt.NO_ARG,({"-u", "--up"}) }),
     ({"dryrun", Getopt.NO_ARG, ({"-n", "--dry-run"})}),
     ({"down",Getopt.NO_ARG,({"-d", "--down"}) }),
     )),array opt)
     {    
       switch(opt[0])
       {
         case "migration":
           run_migrations += ({ opt[1] });
           break;
         case "up":
           dir = Fins.Util.MigrationTask.UP;
           break;
         case "down":
           dir = Fins.Util.MigrationTask.DOWN;
           break;
     		 case "dryrun":
     	     dryrun = 1;
     	     break;
       }
     }

  args = a2[1..] - ({0});
  
  object migrator = Fins.Util.Migrator(app);

  array migrations;
  if(args && sizeof(args))
  {
    through = args[0];
    migrations = migrator->get_migrations(dir, through);
  }
  else
    migrations = migrator->get_migrations(dir);

  if(sizeof(run_migrations))
  {
    foreach(run_migrations;; string m)
    {
       foreach(migrations; int x; object mc)
        if(mc->name != m)
          migrations[x] = 0;
    }
  }
  
  migrations -= ({0});
  string msg;
  if(dir == Fins.Util.MigrationTask.UP)
    msg = "Applying unapplied migrations";
  else
    msg = "Reverting applied migrations";
  if(through) msg += (" through <" + through + ">");
  if(dryrun)
    msg += (" (dry run)");
  migrator->announce(msg);
  migrator->write_func("%{" + (" "*3) + "- %s\n%}", migrations->name); 
  
  
  foreach(migrations;; object m)
  {
    if(dryrun)
      m->dry_run = 1;
    m->run(dir);
  }

  msg = "Migration Complete";
  if(dryrun)
    msg += (" (dry run)");
  msg += ".";
  migrator->announce(msg);
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
