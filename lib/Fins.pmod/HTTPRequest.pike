inherit Fins.Request;
inherit Protocols.HTTP.Server.Request;

string referrer = "";
constant low_protocol = "HTTP";
void parse_request()
{
  ::parse_request();

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
