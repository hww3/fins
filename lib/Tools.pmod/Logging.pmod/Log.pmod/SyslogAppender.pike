//!  an appender that uses the syslog() function to deliver messages.
//!  log levels are mapped to syslog levels, with the exception that TRACE
//!  has no syslog equivalent, and thus is mapped to LOG_DEBUG.
//!

inherit .Appender;

void create(mapping|void config)
{
  ::create(config);
}


mixed write(mapping args)
{
  if(enable)
    return do_write(do_format(args), args->level);
}

protected int do_write(string s, int level)
{
  level = 
([
  1:7, // TRACE is mapped to SYSLOG DEBUG
  2:7,
  4:6,
  8:4,
  16:3,
  32:2
])[level];
  
  System.syslog(level, s);
  return 1;
}

