// TODO: make this work on windows?
// probably use Process.locate_binary() instead.
int have_command(string command)
{
  string p;
  p = Process.popen("which " + command);
  return sizeof(p);    
}

// TODO also try using dns-sd on windows/osx boxes without the DNS_SD module.
void register_bonjour()
{
  db = model;

  // TODO: we should add a process-end callback to restart the registration
  // if avahi-publish* die for some reason.
  if(have_command("avahi-publish"))
  {
    array command = ({"avahi-publish", "-s"});
    command += ({db->get_name()});
    command += ({"_daap._tcp"});
    command += ({(string)__fin_serve->my_port});
    bonjour = Process.create_process(command);
    sleep(0.5);
    if(bonjour->status() != 0)
    {
      throw(Error.Generic("Unable to register service using avahi-publish.\n"));
    }
    log->info("Advertising tunesd/DAAP via Bonjour (using avahi-publish).");
  }
  else if(have_command("avahi-publish-service"))
  {
    array command = ({"avahi-publish-service"});
    command += ({db->get_name()});
    command += ({"_daap._tcp"});
    command += ({(string)__fin_serve->my_port});
    bonjour = Process.create_process(command);
    sleep(0.5);
    if(bonjour->status() != 0)
    {
      throw(Error.Generic("Unable to register service using avahi-publish-service.\n"));
    }
    log->info("Advertising tunesd/DAAP via Bonjour (using avahi-publish-service).");
  }
#if constant(_Protocols_DNS_SD)
#if constant(Protocols.DNS_SD.Service);
  else if(1)
  {
    log->info("Advertising tunesd/DAAP via Bonjour.");
    bonjour = Protocols.DNS_SD.Service(db->get_name(),
                   "_daap._tcp", "", (int)__fin_serve->my_port);
  }
#endif
#endif
  else
  {
    throw(Error.Generic("You must have a Bonjour/Avahi installation in order to run this application.\n"));
  }

}


