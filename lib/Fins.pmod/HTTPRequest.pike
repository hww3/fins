inherit Fins.Request;
inherit Protocols.HTTP.Server.Request;

string referrer = "";
constant low_protocol = "HTTP";

void parse_post()
{
  ::parse_post();

  foreach(variables; string k; string v)
    catch(variables[k] = utf8_to_string(v));

  if(variables["_lang"])
  {
    set_lang(variables["_lang"]);
    m_delete(variables, "_lang");
  }

}

void parse_request()
{
  ::parse_request();

  foreach(variables; string k; string v)
    catch(variables[k] = utf8_to_string(v));

  remoteaddr = ((my_fd->query_address()||"")/":")[0];
  string n_not_query = Protocols.HTTP.Server.http_decode_string(not_query);
  if(n_not_query != not_query)
  catch{
    n_not_query = utf8_to_string(n_not_query);
  };
  
  not_query = n_not_query;

  not_query = replace(not_query, "+", " ");
  referrer = request_headers["referer"];
}

//!
string remoteaddr = "";

void flatten_headers()
{  
  ::flatten_headers();

  if(request_headers->pragma)
    pragma |= (multiset)(request_headers->pragma/",");
}

//! an X-Forwarded-For aware method of getting the original client address. 
//! note that X-F-F headers are notoriously easy to forge, so don't rely
//! on this value to be accurate if you know there to be proxies present.
string get_client_addr()
{
  string f = request_headers["x-forwarded-for"];
  if(!f) return (remoteaddr/" ")[0];
  else return String.trim_whites((f/",")[0]);
}


//! when running within a Fins-specific container like FinServe, the port object contains a reference to the application,
//! so we link the application to the request here before continuing.
void attach_fd(Stdio.File _fd, Port server,
	       function(this_program:void) _request_callback,
	       void|string already_data)
{
  fins_app = server->get_application();
  
  ::attach_fd(_fd, server, _request_callback, already_data);
}