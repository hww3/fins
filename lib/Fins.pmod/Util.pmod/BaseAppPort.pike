optional protected object port;
protected object app;

string protocol = "http";

mapping conns = set_weak_flag(([]), Pike.WEAK_INDICES);

// why we need both ifs i don't know
#if constant(_Protocols_DNS_SD) && constant(Protocols.DNS_SD.Service);
protected Tools.Network.Bonjour bonjour;

public void set_bonjour(int port, string name, string protocol)
{
  bonjour = Tools.Network.Bonjour(port, name, protocol);
}

public object get_bonjour()
{
  return bonjour;
}
#endif
  
public object get_application()
{
  return app;  
}
  
public void set_application(object application)
{
  app = application;
}

void destroy()
{
  foreach(conns; object c;)
  {
    if(c) c->finish(0);
    destruct(c);
  }
}
