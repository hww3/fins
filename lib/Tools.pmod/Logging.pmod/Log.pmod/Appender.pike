//!
constant default_format =  "%{hour:02d}:%{min:02d}:%{sec:02d} %{level} - %{name}: %{msg}";

//!
constant common_log_format = "%{remote_host} - %{user} [%{mday:02d}/%{month}/%{year}:%{hour:02d}:%{min:02d}:%{sec:02d} %{timezone:+05d}] \"%{method} %{request} %{protocol}\" %{code} %{size}";

object output;

//! config setting
string format = default_format;

function format_function;

//! config setting
int enable = 1;

protected void create(mapping config)
{
  if(config->format)
    format = config->format;
  if(config->enable)
    enable = Tools.Boolean.fromString(config->enable);

  format_function = Tools.String.named_sprintf_func(format + "\n");
}

//! creates the parent folder for file if it doesn't exist.
//!  
//! @returns
//!  the name of the directory.
protected string make_log_directory(string file)
{
  string dirname = dirname(file);
  Stdio.Stat fss = file_stat(dirname);
  if(!fss)
  {
    .module.info("creating directory " + dirname);
    Stdio.mkdirhier(dirname);
  }
  
  return dirname;
}

mixed write(mapping args)
{
  if(enable)
    return do_write(do_format(args));
}

protected int do_write(string s)
{
  return output->write(s);
}

protected string do_format(mapping args)
{
  return encode_string(format_function(args) );
}

string _sprintf(mixed ... args)
{
  return sprintf("appender(%O)", output);
}

// we shouldn't assume the output should be utf8, but it will allow us to avoid
// errors when trying to write log messages with wide strings.
protected string encode_string(string input)
{
  return string_to_utf8(input);
}
