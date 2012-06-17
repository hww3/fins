inherit Protocols.HTTP.Server.Port;

protected object app;

mapping conns = set_weak_flag(([]), Pike.WEAK_INDICES);

// why we need both ifs i don't know
#if constant(_Protocols_DNS_SD) && constant(Protocols.DNS_SD.Service);
protected Protocols.DNS_SD.Service bonjour;

public void set_bonjour(object _bonjour)
{
  bonjour = _bonjour;
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
  app->my_port = (int)(port->query_address()/" ")[1];
}

void destroy()
{
  foreach(conns; object c;)
  {
    if(c) c->finish(0);
    destruct(c);
  }
}