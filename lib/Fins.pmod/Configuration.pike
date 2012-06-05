//! the full path to the application directory
string app_dir;

//! name of the application; usually the last element of the full path to the application.
string app_name;

//! the path to the configuration file in use, such as /path/to/config/dev.cfg
string config_file;

//! the name of the configuration in use, such as dev
string config_name;

//! the name of the multi-tenant handler, if present
string handler_name;

protected mapping values;

protected string get_app_name()
{
 return ((app_dir/"/")-({""}))[-1];
}

//!
protected void create(string appdir, string|mapping _config_file)
{
  app_dir = appdir;

  if(appdir)
    app_name = get_app_name();
  

  // TODO: should we have the following bit of code here?
  // I'm somewhat dubious.
  object m = master();
  if(m->handlers_for_thread)
    handler_name = m->handlers_for_thread[Thread.this_thread()];


  if(stringp(_config_file))
  {
    config_file = _config_file;
	array _cn = (basename(config_file)/".");
	config_name = _cn[0..sizeof(_cn)-2]*".";

    string fc = Stdio.read_file(config_file);

    // the "spec" says that the file is utf-8 encoded.
    fc=utf8_to_string(fc);

    values = Public.Tools.ConfigFiles.Config.read(fc);
  }
  else if(mappingp(_config_file))
  {
    values = _config_file;
  }
}

array get_sections()
{
  return indices(values);
}

//! sets a value in the configuration
void set_value(string section, string item, mixed value)
{
  if(!values[section])
    values[section] = ([]);

  if(arrayp(value))
    values[section][item] = value;
  else
    values[section][item] = (string)value;

  Public.Tools.ConfigFiles.Config.write_section(config_file, section, values[section]);
}

//! returns a string containing the first occurrance of a configuration 
//! variable item in configuration section "section".
string get_value(string section, string item)
{
  if(!values[section])
  {
    throw(Error.Generic("Unable to find configuration section " + section + ".\n"));
  }

  else if(!values[section][item] && zero_type(values[section][item]))
  {
    throw(Error.Generic("Item " + item + " in configuration section " + section + " does not exist.\n"));
  }

  else if(arrayp(values[section][item]))
  {
    return values[section][item][0];
  }

  else return values[section][item];
}


//! returns an array containing all occurrances of a configuration 
//! variable item in configuration section "section".
array get_value_array(string section, string item)
{
  if(!values[section])
  {
    throw(Error.Generic("Unable to find configuration section " + section + ".\n"));
  }

  else if(!values[section][item] && zero_type(values[section][item]))
  {
    throw(Error.Generic("Item " + item + " in configuration section " + section + " does not exist.\n"));
  }

  else if(arrayp(values[section][item]))
  {
    values[section][item];
  }

  else return ({ values[section][item] }); 
}

//! easy accessor for an entire configuration section
mixed `[](string arg)
{
  //      werror("GOT %O\n", arg);
  return values[arg];

}

int(0..1) _is_type(string t)
{
  int v=0;

  switch(t)
  {
    case "mapping":
      v = 1;
    break;
  }

  return v;
}

