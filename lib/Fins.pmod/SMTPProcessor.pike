import Fins;
import Tools.Logging;
inherit Processor;

//! A processor for handling incoming messages via SMTP.
//!
//! configuration data:
//!
//! [processors]
//! processor=my_smtp_processor
//! 
//! [smtp]
//! listen_port=portnum
//! listen_host=bindhost
//! domain=relaydomain1
//! domain=relaydomainn

object smtp;

program server = SMTPServer;

class SMTPServer
{
  inherit Protocols.SMTP.Server;

  protected void create(array domains, int port, string host, function _cb_mailfrom,
    function _cb_rcptto, function _cb_data, object app)
  {
    fins_app = app;
    ::create(domains, port, host, _cb_mailfrom, _cb_rcptto, _cb_data);
    fdport->set_backend(fins_app->get_backend());
  }

  object fins_app;
}

array supported_protocols()
{
  return ({"SMTP"});
}

void start()
{
  if(!config["smtp"])
    throw(Error.Generic("No SMTP configuration section.\n"));

  else
  {
    int port = (int)(config["smtp"]["listen_port"] || 25);
    string host = config["smtp"]["listen_host"] || "*";
    array|string domains = config["smtp"]["domain"];
    if(stringp(domains)) domains = ({ domains });
    Log.info("Opening SMTP Listener on %s:%d for domains %s.", host, port, domains*", ");
    smtp = server(domains, port, (host=="*"?0:host), 
	_cb_mailfrom, _cb_rcptto, _cb_data, app);
  }
}

int|array _cb_mailfrom(string email)
{
  return 250;
}

int|array _cb_rcptto(string email)
{
  return 250;
}

int|array _cb_data(object mime, string sender, array(string) recipient, 
                     void|string raw)
{
  return 250;
}


