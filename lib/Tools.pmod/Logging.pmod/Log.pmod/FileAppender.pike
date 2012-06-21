//!

inherit .Appender;

//! a config setting.
string file;

string dirname;

void create(mapping|void config)
{
  if(!config || !config->file)
  {
    throw(Error.Generic("Configuration File must be specified.\n"));
  }
  else
  {
    file = config->file;
    dirname = make_log_directory(file);
    output = Stdio.File(file, "cwa");
  }

  ::create(config);
}

