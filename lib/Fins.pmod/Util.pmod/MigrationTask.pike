inherit Fins.FinsBase;

object log = Tools.Logging.get_logger("fins.util.migrationtask");

constant UP = 0; // default
constant DOWN = 1;

constant name = "";
constant id = "";
constant model_id = Fins.Model.DEFAULT_MODEL;

int verbose;

//!
Fins.Model.DataModelContext context;

//!
Fins.Util.Migrator migration_engine;

static void create(object app, object migrator)
{
  ::create(app);
  if(sizeof(model_id))
  {
    context = Fins.Model.get_context(model_id);
  }
  migration_engine = migrator;
  setup();
}

//! actions performed before the migration is initiated.
void setup()
{
  
}

void write(mixed ... args)
{
  if(verbose)
    Stdio.stdout.write(@args);
}

void run(int|void direction)
{
  function m;
  string dir;
  
  if(direction == UP)
  {
    m = up;
    dir = "migrated";
    announce("migrating");
  }
  else
  {
    m = down;
    dir = "reverted";
    announce("reverting");
  }
  
  int ntime = gethrtime();
  mixed g = gauge(m());
  ntime = gethrtime() - ntime;
  
  float t = ntime / 1000000.0;  
  announce(dir + " in %0.2f sec, %0.2f cpu", t, g);
}

//! perform a migration
void up()
{
  
}

//! revert a migration
void down()
{
  
}

//! display a message
//!
//! @param message
//!   the message to display
//! 
//! @param args
//!   arguments to insert into message, @[sprintf]-style.
void announce(string message, mixed ... args)
{
  int l;
  string m = "== " + id + " " + name + ": " + message;
  m = sprintf(m, @args);
  l = max(0, 79 - sizeof(m));
  Stdio.stdout.write(m + " " + ("="*l) + "\n");
}

//! run a set of engine specific sql statements.
//!
//! files are stored in db/migration/scripts. each file should contain statements
//! separated by semicolons and at least 1 new line.
//!
//! @param segment_name
//!   the base name of a file containing sql statements. the extension for the 
//!   appropriate database engine (mysql, sqlite, postgres) in use will be added. 
//!   
//! @param enginespecific
//!  if set, bypasses check for scripts for all supported databases.
void apply_sql(string segment_name, string|void engine_specific)
{
  string engine = context->type();
  string segment_path = Stdio.append_path(migration_engine->migration_dir, "scripts", segment_name + "." + engine);
  object st = file_stat(segment_path);
  string splitter = ";\n";
  mixed e; // error

  if(engine_specific && engine != engine_specific)
  {
    log->info("skipping %s-only sql %s.", engine_specific, segment_name);
  } 
   
  if(!st || !st->isreg)
  {
    Tools.throw(Error.Generic, "sql segment %s does not exist.", segment_path);
  }

  if(!engine_specific)
  {
    log->debug("checking to make sure we have all varieties of the sql script.");
    foreach(values(Fins.Model.Personality);; mixed p)
    {
      if(programp(p) && Program.implements(p, Fins.Model.Personality.Personality) && p != Fins.Model.Personality.Personality)
      {
        string check_segment_path = Stdio.append_path(migration_engine->migration_dir, "scripts", segment_name + "." + p->type);
        object st = file_stat(check_segment_path);
        if(!st || !st->isreg)
        {
          log->warn("sql segment %s for database type <%s> does not exist.", segment_name, p->type);
        }
      }
    }
  }

   // now, we can populate the schema.
   string s = Stdio.read_file(segment_path);
   mapping tables = ([]);
   array commands = ({});

   log->info("loaded ddl %s for %s.", segment_name, engine);

   // Remove the #'s, if they're there.
   string _s = "";
   foreach(s / "\n"; int lnum; string line) 
   {
     log->debug("looking at line %d.", lnum);
     if (!sizeof(line) || line[0] == '#')
       continue;
     else
       _s += line + "\n";
   }
   s = _s;

   string command;

   log->info("parsing schema.");

   // Split it into statements;
   foreach((s / splitter) - ({ "\n" }), command) 
   {
     string table_name;
     if (sscanf(lower_case(command), "create table %s %*s", table_name))
     {
       log->info("found definition for %s.", table_name);
       tables[table_name] = String.trim_all_whites(command);
     }
     else if(sizeof(command))
     {
       log->info("adding sql query to queue.");
       commands += ({command});
     }
   }

   // Create tables
   log->debug("getting tables in database.");

   multiset extant_tables = (multiset)context->sql->list_tables();

   log->debug("have tables.\n");

   foreach(indices(tables), string name) 
   {
     if (extant_tables[name])
     {
       log->info("skipping definition for %s.", name);
       continue;
     } 
     log->info("command: %s", tables[name]);
       
     e = catch(context->execute(tables[name]));
     if (e) 
     {
       log->exception("An error occurred while running a command: " + tables[name] + ".", e);
       throw(e);
     }
   }

   foreach(commands;; string c)
   {
     log->info("executing: %O", c);
     e = catch(context->execute(c));
     if (e) 
     {
       log->exception("An error occurred while running a command: " + c + ".", e);
       throw(e);
     }
   }
}

//! drop a sql table 
//!
//! @param table
//!   the sql table name to drop.
void drop_table(string table)
{
  context->drop_table(table);
}
