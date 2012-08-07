inherit Fins.FinsBase;

constant UP = 0; // default
constant DOWN = 1;

constant name = "";
constant id = "";
constant model = "";

int verbose;

static void create(object app)
{
  ::create(app);
  
  setup();
}

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

void up()
{
  
}

void down()
{
  
}

void announce(string message, mixed ... args)
{
  int l;
  string m = "== " + id + " " + name + ": " + message;
  m = sprintf(m, @args);
  l = max(0, 79 - sizeof(m));
  Stdio.stdout.write(m + " " + ("="*l) + "\n");
}