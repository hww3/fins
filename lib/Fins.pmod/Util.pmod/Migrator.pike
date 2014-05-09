//!  Entry point for migration subsystem
//!
//!

constant MIGRATION_DIR = "db/migration";
constant MIGRATION_STATUS_TABLE = "_fins_migrations";

//!
object application;

object log = Tools.Logging.get_logger("fins.db.migration");

//!
string migration_dir;

function write_func = Stdio.stdout.write;

protected void create(void|object app)
{
  application = app;  
  
  if(!application)
    throw(Error.Generic("new_migration: no application loaded"));

  migration_dir = Stdio.append_path(application->config->app_dir, MIGRATION_DIR);
  initialize();
}

void initialize()
{
  object st = file_stat(migration_dir);

  if(!st || !st->isdir)
    throw(Error.Generic("Migrator.initialize(): migration dir " + migration_dir + " does not exist.\n"));
  array ids = Fins.Model.get_context_ids();
  
  foreach(ids; int i; string model_id)
  {
      initialize_migration_context(model_id);
  }
}

void initialize_migration_context(string model_id)
{
  object context = Fins.Model.get_context(model_id);
  if(!context) 
    log->error("Unable to get registered model context with id=%s", model_id);
  
  if(context->table_exists(MIGRATION_STATUS_TABLE))
    log->info("Migration status table exists.");
  else
  {
    log->info("Migration status table does not exist in model with id=%s", model_id);
    object tb = context->get_table_builder(MIGRATION_STATUS_TABLE, this);
    tb->add_field("name", "string", (["primary_key": 1]));
    tb->add_field("status", "integer");
    tb->add_field("applied", "timestamp");
    tb->go();
  }
}

string make_descriptor(string text)
{ 
  return (string)map(filter((array)Unicode.normalize(lower_case(text), "DK"), `<, 256), lambda(mixed x){if(x<'0') return '_'; else return x;}); 
}

string make_id(object id)
{
  return replace(id->format_time(), ({" ", "-", ":", "."}), ({"", "", "", ""})); 
}

//!
string make_class(string text, object id)
{
  return
  #"inherit Fins.Util.MigrationTask;
  
constant id = \"" + make_id(id) + 
  
  #"\";
constant name=\"" + make_descriptor(text) + 
  #"\";

void up()
{
  
}

void down()
{
  
}
";  
}

void announce(string message, mixed ... args)
{
  int l;
  string m = "== " + message;
  m = sprintf(m, @args);
  l = max(0, 79 - sizeof(m));
  write_func(m + " " + ("="*l) + "\n");
}


//! default direction is @[Fins.Util.MigrationTask.UP].
array(Fins.Util.MigrationTask) get_migrations(int|void dir, string|void through)
{
  array f = glob("*.pike", get_dir(migration_dir));

  array migrations = ({});
  
  foreach(f;;string p)
  {
    string taskpath = Stdio.append_path(migration_dir, p);
    object st;
    
    if(!(st = file_stat(taskpath)) || st->isdir)
    {
      werror("skipping %s\n", taskpath);
      continue;
    } 

    program mp = (program)taskpath;
    if(!Program.implements(mp, Fins.Util.MigrationTask))
    {
      werror("program %s doesn't implement MigrationTask.\n", p);
    }
    else
    {
      object migration = mp(application, this);
      object context = Fins.Model.get_context(mp->model_id);

      if(!context) 
      {
        log->error("Unable to get registered model context with id=%s", mp->model_id);
        continue;
      }
      
      // TODO: possibility of non-SQL datastores needs to be considered.
      int needs_migration;
      
      if(context->sql)
      {
        array x = context->sql->query(sprintf("SELECT * FROM %s WHERE name='%s'", MIGRATION_STATUS_TABLE, migration->id + "_" + migration->name));

        if(!sizeof(x))
        {
          if(dir == Fins.Util.MigrationTask.UP)
            needs_migration = 1;
        }
        else
        {
          if((int)x[0]->status == 1 && dir == Fins.Util.MigrationTask.UP)
            needs_migration = 0;
          else if((int)x[0]->status == 1 && dir == Fins.Util.MigrationTask.DOWN)
            needs_migration = 1;
          else if((int)x[0]->status == 0 && dir == Fins.Util.MigrationTask.UP)
            needs_migration = 1;
          else if((int)x[0]->status == 0 && dir == Fins.Util.MigrationTask.DOWN)
            needs_migration = 0;
          // what if status not in {0, 1}? 
            
        }
        if(needs_migration)
          migrations += ({migration});
      }

    }
  }
  
  migrations = sort(migrations);

  if(dir == Fins.Util.MigrationTask.DOWN)
    migrations = reverse(migrations);

  if(through)
  {
    int stopat;
    stopat = search(migrations->name, through);
    if(stopat == -1)
      stopat = search(migrations->id, through);

    if(stopat != -1)
    {
      migrations = migrations[0..stopat];
    }
    else
    {
      throw(Error.Generic("get_migrations: unable to find stopping point <" + through + ">.\n"));
    }
  }
  return migrations;
}

//!
string new_migration(string text, object|void id)
{
  if(!application)
    throw(Error.Generic("new_migration: no application loaded"));
    
  return low_new_migration(text, id, Stdio.append_path(application->config->app_dir, migration_dir));
}

string low_new_migration(string text, object|void id, string dir)
{
  if(!id) id = Calendar.now();
  string c = make_class(text, id);
  string fn = make_id(id) + "_" + make_descriptor(text) + ".pike";
  string afn = Stdio.append_path(dir || getcwd(), fn);
  
  log->debug("Creating new migration in %s.", afn);
  Stdio.write_file(afn, c);
  
  return fn;
}
