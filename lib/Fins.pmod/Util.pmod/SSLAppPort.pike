inherit Protocols.HTTP.Server.SSLPort : sslport;
inherit .BaseAppPort : bap;

string protocol = "https";

protected object logger = Tools.Logging.get_logger("fins.sslport");

private string key;
protected array certificates;

protected void create(function cb, int _port, string|void bind, mapping args)
{
  load_key_and_certs(args);
    
  sslport::create(cb, _port, bind, key, certificates);

//  sslport::port->sni_certificates["fooba-dev.10.211.55.2.xip.io"] = ({"foo"});
//  sslport::port->sni_keys["fooba-dev.10.211.55.2.xip.io"] = this->port->rsa;
}

protected void load_key_and_certs(mapping args)
{
  if(!args->certificate)
  {
    logger->warn("No SSL Certificate provided. Using default self-signed certificate.");
  }
  else
  {
    certificates = ({});
      
    foreach(args->certificate;; string cert)
    {
      string c = Stdio.read_file(cert);
      if(!c) 
        throw(Error.Generic("SSLAppPort: unable to read certificate from file '" + cert + "'."));
      object pem = Tools.PEM.Msg(c);
      if(!pem || !pem->parts["CERTIFICATE"])
        throw(Error.Generic("SSLAppPort: unable to find certificate in file '" + cert + "'."));
      
      cert = pem->parts["CERTIFICATE"]->decoded_body();
      logger->info("SSLPort will use cert key from file %O", cert);
      certificates += ({cert});
      
      if(pem->parts["RSA PRIVATE KEY"])
      {
        logger->info("SSLPort will use private key from file %O", cert);
        key = pem->parts["RSA PRIVATE KEY"]->decoded_body();
      }
    }
    
    if(args->key)
    {
      string k = Stdio.read_file(args->key);
      
      if(key) throw(Error.Generic("SSLAppPort: private key file specified, but already found one within a certificate file."));
      
      if(!k) 
        throw(Error.Generic("SSLAppPort: unable to read private key from file '" + args->key + "'."));
      object pem = Tools.PEM.Msg(k);
      if(!pem || !pem->parts["RSA PRIVATE KEY"])
        throw(Error.Generic("SSLAppPort: unable to find private key in file '" + args->key + "'."));

      logger->info("SSLPort will use private key from file %O", args->key);      
      key = pem->parts["RSA PRIVATE KEY"]->decoded_body();
    }
  }
}
