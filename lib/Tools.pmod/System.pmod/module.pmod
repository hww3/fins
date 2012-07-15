//! Get the username for the user running this process.
string get_user()
{
#if constant(System.GetUserName)
  return System.GetUserName();
#elseif constant(System.getuid)
  return getpwuid(System.getuid())[0];
#else
  return "UNKNOWN";
#endif /* System.GetUserName */
}

string get_home()
{
  string home = getenv("HOME");
  if(home) return home;

#if __NT__
  string homedrive = getenv("HOMEDRIVE");
  home = getenv("HOMEPATH");
  if(homedrive)
    home = homedrive + home;
  if(home) return home;
#endif
      
  throw("Unable to determin HOME directory.\n");
}

