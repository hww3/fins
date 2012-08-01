import Tools.Logging;

string appname;
array args;

void create(array argv)
{
  Log.info("Migration module loading");

  if(!sizeof(argv))
  {
    Log.error("Migration requires the name of the application to work with.");
    exit(1);
  }

  [appname, args] = Array.shift(argv);
}

int run()
{
  Log.info("Migration tool running.");
  Log.info("Fins version " + Fins.__version);

  Log.info("Migration tool running for application %s.", appname);

  if(sizeof(args) < 2)
  {
    Log.error("Usage: pike -x fins migration create \"migration description\"\n");
  }

  string command;
  
  [command, args] = Array.shift(args);
  
  switch(command)
  {
    case "create":
      return do_create(@args);
      break;
    default:
      Log.error("Unknown command %O.", command);
      exit(1);
  }
  
  return 0;
}


int do_create(string migration)
{
  if(!migration || !sizeof(migration))
  {
    Log.error("Migration name must be specified.");
    return 1;
  }

  object st = file_stat(appname);
  
  if(!st || !st->isdir)
  {
    Log.error("Application directory %O does not exist.", appname);
    return 1;    
  }
  
  string dir = Stdio.append_path(appname, "migration");

  Stdio.mkdirhier(dir);
  string fn = Fins.Util.Migrator()->new_migration(migration, 0, dir);
  
  Log.info("Created new migration %s", fn);
  return 0;
}