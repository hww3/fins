import Tools.Logging;

string newappname;

string locale_contents = 
#string "templates/locale.txt";

string config_contents = 
#string "templates/config.txt";

string log_config_contents = 
#string "templates/log_config.txt";

string model_contents =
#"
inherit Fins.FinsModel;

";

string view_contents = 
#"
inherit Fins.FinsView;
";

string application_contents =
#"
inherit Fins.Application;
";

string controller_contents =
#string "templates/controller.txt";

string script_base =
#string "templates/script_base.txt";

string hilfe_contents = script_base +
#"
  exec pike $PIKE_ARGS -x fins start --hilfe \"$@\"
";

string start_contents = script_base + 
#"
  exec pike $PIKE_ARGS -x fins start \"$@\"
";

string fins_contents = script_base + 
#"
  if [ x$ARG0 = \"x\" ]; then
    echo \"$0: no command given.\"
    exit 1
  fi
  shift 1

  exec pike $PIKE_ARGS -x fins $ARG0 \"$@\"
";

void create(array args)
{
  Log.info("CreateApplication module loading");

  if(!sizeof(args))
  {
    Log.error("CreateApplication requires the name of the application to create.");
    exit(1);
  }

  else newappname = args[0];
}

int run()
{
  Log.info("CreateApplication module running.");
  Log.info("Fins version " + Fins.__version);

  Log.info("Creating application %s in %s.", newappname, getcwd());

  // first, create the directory for the app.
  mkdir(newappname);
  cd(newappname);
  
  // now, let's create the subfolders.
  foreach(({"classes", "config", "modules", "templates", "macros", "static", "logs", "bin", "db/schema", "db/migration", "translations", "translations/eng"});; string dir)
    Stdio.mkdirhier(dir);
 
  // now, we create the configfiles, one each for dev, test, prod.
  cd("config");

  foreach(({"dev", "test", "prod"});; string tier)
  {
    Stdio.write_file(tier + ".cfg", customize("#\n# this is the configuration for " + upper_case(tier) + ".\n#\n" + config_contents));
    Stdio.write_file("log_" + tier + ".cfg", customize("#\n# this is the logging configuration for " + upper_case(tier) + ".\n#\n" + log_config_contents));
  }

  Stdio.write_file("locale.xml", customize(locale_contents));

  cd("../classes");
  Stdio.write_file("application.pike", customize(application_contents));
  Stdio.write_file("model.pike", customize(model_contents));
  Log.info("Be sure to edit config/*.cfg to specify the application's datasource");
  Stdio.write_file("view.pike", customize(view_contents));
  Stdio.write_file("controller.pike", customize(controller_contents));

  // next, we prepare the modules, mostly used by the model.
  cd("../modules");
  mkdir(newappname + ".pmod");
  cd(newappname + ".pmod");
  mkdir(Fins.Helpers.Defaults.data_instance_module_name + ".pmod");
  mkdir(Fins.Helpers.Defaults.data_mapping_module_name + ".pmod");  
//  Stdio.write_file("Repo.pmod", customize(repo_contents));

  cd("../..");

  cd ("bin");
  Stdio.write_file("start", customize(start_contents));
  Stdio.write_file("fins", customize(fins_contents));
  Stdio.write_file("hilfe", customize(hilfe_contents));
  Process.system("chmod a+rx hilfe");
  Process.system("chmod a+rx start");
  Process.system("chmod a+rx fins");
  
  return 0;
}

string customize(string c)
{
  return replace(c, ({"__APPNAME__"}), ({newappname}));
}
