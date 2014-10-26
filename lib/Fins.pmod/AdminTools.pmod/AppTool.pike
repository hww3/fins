#!/usr/local/bin/pike -Mlib -DLOCALE_DEBUG

constant fins_command = "apptool";
import Tools.Logging;

function(object:void) ready_callback;
function(object:void) failure_callback;

constant my_version = "0.1";

string tool_name;

string project = "default";
string config_name = "dev";
private int has_started = 0;

object app;

void print_help()
{
	werror("Help: apptool [-c|--config configname] appname toolname [toolargs...]\n");
}

array tool_args;

int(0..1) started()
{
  if(has_started) return 1;
  else return 0;
}

void create(array args)
{
  tool_args = args;
}

int run()
{
  return main(sizeof(tool_args) + 1, ({""}) + tool_args);
}

int main(int argc, array(string) argv)
{
  foreach(Getopt.find_all_options(argv,aggregate(
    ({"config",Getopt.HAS_ARG,({"-c", "--config"}) }),
    ({"help",Getopt.NO_ARG,({"--help"}) }),
    )),array opt)
    {
      switch(opt[0])
      {
		case "config":
		config_name = opt[1];
		break;

        case "help":
		print_help();
		return 0;
		break;
	  }
	}
	
	argv-=({0});
	argv-=({""});
	argc = sizeof(argv);

  if(argc>=1) project = argv[0];
  if(argc>=2) tool_name = argv[1];
  if(argc>=3) tool_args = argv[2..];
  else tool_args = ({});

  if(!tool_name)
  {
    werror("no tool name specified.\n");
    exit(1);
  }

  int x;
  mixed e;
  if(e = catch(x = do_startup()))
  {
    if(failure_callback)
      call_out(failure_callback, 0, this);
    Log.exception("Failure during startup.", e);
  }

  return x;
}

//!
object get_application()
{
  return app;
}

//!
object get_container()
{
  return this;
}

//!
int has_ports()
{
  return 0;
}

void do_ready()
{
//  werror("app started. running tool %s with args=%O.", tool_name, tool_args);
  object tool = ((program)tool_name)(app);
  tool->start();
  int rv = tool->run(@tool_args);
 
  app->shutdown();

  exit(rv);  
}

void do_failure()
{
  werror("app failed to load. please see the debug log for details.\n");
  exit(1);
}


int do_startup()
{
ready_callback = do_ready;
failure_callback = do_failure;


  Log.info("FinServe loading application " + project + " using configuration " + config_name);
  Log.info("Fins version " + Fins.__version);
  load_application();

  app->app_runner = this;

  Log.info("Application " + project + " loaded.");

  app->do_start();

    Log.info("Application ready for business.");
    if(ready_callback)
	call_out(ready_callback, 0, this);

    has_started = 1;

    return -1;
}

void load_application()
{
  object application;
  mixed err = catch(
  application = Fins.Loader.load_app(combine_path(getcwd(), project), config_name));
  if(err || !application)
  {
    if(err) Log.exception("An error occurred while loading the application.", err);
    else Log.critical("An error occurred while loading the application.");
    exit(1);
  }

  app = application;
}
