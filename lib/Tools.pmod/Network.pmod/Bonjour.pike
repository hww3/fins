object dns_sd;
function(string:void) success;
function(string:void) failure;

//! A wrapper around multiple Bonjour/Zeroconf/MDNS providers.
//!
//! @todo
//!  for command line based implementations, we should monitor 
//!  the status of the command in order to detect deregistration
//!  or other problems.

void destroy()
{
  if(dns_sd)
  {
    werror("De-registering Bonjour advertisement");
    destruct(dns_sd);
  }
}

//!
void create(int port, string|void name, string|void service)
{
  if(!port) return;
  else if(!name && !service)
   throw(Error.Generic("Bonjour: must specify service and name.\n"));
  else
    dns_sd = low_register_bonjour(port, name, service);
}

// TODO: make this work on windows?
int have_command(string command)
{
  int p;
  p = Process.system("which " + command);
  return !(p);    
}

object low_register_bonjour(int port, string name, string service, function|void _success, function|void _failure)
{
  object bonjour;
  success = _success, failure = _failure;
    if(0);
  #if constant(_Protocols_DNS_SD)
  #if constant(Protocols.DNS_SD.Service);
    else if(1)
    {
      mixed err = catch{
        bonjour = Protocols.DNS_SD.Service(name, "_" + service + "._tcp", "", (int)port);
      };
      if(err)
      {
        if(failure) failure("Unable to register service via Bonjour: " + err[0]); 
        else
          throw(Error.Generic("Unable to register service via Bonjour: " + err[0] + ".\n"));
        return 0;
      }
      if(success) success("Advertising tunesd/" + upper_case(service) + " via Bonjour.");
    }
  #endif
  #endif
    else if(have_command("avahi-publish"))
    {
      array command = ({"avahi-publish", "-s"});
      command += ({name});
      command += ({"_" + service + "._tcp"});
      command += ({(string)port});
      bonjour = Process.create_process(command, (["callback": proc_state_changed]));
      sleep(0.5);
      if(bonjour->status() != 0)
      {
        if(failure) failure("Unable to register service using avahi-publish."); 
        else
          throw(Error.Generic("Unable to register service using avahi-publish.\n"));
        return 0;
      }
      if(success)
        success("Advertising tunesd/" + upper_case(service) + " via Bonjour (using avahi-publish).");

    }
    else if(have_command("avahi-publish-service"))
    {
      array command = ({"avahi-publish-service"});
      command += ({name});
      command += ({"_" + service + "._tcp"});
      command += ({(string)port});
      bonjour = Process.create_process(command, (["callback": proc_state_changed]));
      sleep(0.5);
      if(bonjour->status() != 0)
      {
        if(failure) failure("Unable to register service using avahi-publish-service."); 
        else
          throw(Error.Generic("Unable to register service using avahi-publish-service.\n"));
        return 0;
      }
      if(success)
        success("Advertising tunesd/" + upper_case(service) + " via Bonjour (using avahi-publish=service).");
    }
    else if(have_command("dns-sd"))
    {
      array command = ({"dns-sd"});
      command += ({"-R"});
      command += ({name});
      command += ({"_" + service + "._tcp"});
      command += ({"."});
      command += ({(string)port});
      bonjour = Process.create_process(command, (["callback": proc_state_changed]));
      sleep(0.5);
      if(bonjour->status() != 0)
      {
        if(failure) failure("Unable to register service using dns-sd."); 
        else
          throw(Error.Generic("Unable to register service using dns-sd.\n"));
        return 0;
      }
      if(success)
        success("Advertising tunesd/" + upper_case(service) + " via Bonjour (using avahi-publish=service).");
    }
    else
    {
      if(failure) failure("No Bonjour/Avahi installation found.");
      else throw(Error.Generic("No Bonjour/Avahi installation found.\n"));
      return 0;
    }
  return bonjour;
}

void proc_state_changed(object proc)
{
  int errcode;
  if(proc->status() == 2) // exited
  {
    errcode = proc->wait();
    if(errcode && failure)
      failure("Bonjour registration has failed.\n");
  }
}
