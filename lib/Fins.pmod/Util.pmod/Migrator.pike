object application;

protected void create(void|object app)
{
  application = app;  
}

string make_descriptor(string text)
{ 
  return (string)map(filter((array)Unicode.normalize(lower_case(text), "DK"), `<, 256), lambda(mixed x){if(x<'0') return '_'; else return x;}); 
}

string make_id(object id)
{
  return replace(id->format_time(), ({" ", "-", ":", "."}), ({"", "", "", ""})); 
}

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

function write_func = Stdio.stdout.write;

array(Fins.Util.MigrationTask) get_migrations()
{
  if(!application)
    throw(Error.Generic("new_migration: no application loaded"));

  string migration_dir = Stdio.append_path(application->config->app_dir, "migration");

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
      migrations += ({mp(application)});
  }
  
  return migrations;
}

string new_migration(string text, object|void id)
{
  if(!application)
    throw(Error.Generic("new_migration: no application loaded"));
    
  return low_new_migration(text, id, application->config->app_dir);
}

string low_new_migration(string text, object|void id, string dir)
{
  if(!id) id = Calendar.now();
  string c = make_class(text, id);
  string fn = make_id(id) + "_" + make_descriptor(text) + ".pike";
  
  Stdio.write_file(Stdio.append_path(dir || getcwd(), fn), c);
  
  return fn;
}