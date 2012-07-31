inherit Fins.FinsBase;

constant UP = 0; // default
constant DOWN = 1;

constant name = "";
constant id = "";

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
  
  if(direction == UP)
  {
    m = up;
    announce("migrating");
  }
  else
  {
    m = down;
    announce("reverting");
  }
  
  int ntime = gethrtime();
  mixed g = gauge(m());
  ntime = gethrtime() - ntime;
  
  float t = ntime / 1000000.0;  
  announce("migrated in %0.2f seconds, %0.2f cpu", t, g);
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
  l = max(0, 75 - sizeof(m));
  Stdio.write(m + " " + ("="*l));
}