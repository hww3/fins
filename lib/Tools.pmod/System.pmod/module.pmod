//! Get the username for the user running this process.
string getUser()
{
#if constant(System.GetUserName)
  return System.GetUserName();
#elseif constant(System.getuid)
  return getpwuid(System.getuid())[0];
#else
  return "UNKNOWN";
#endif /* System.GetUserName */
}

