
.Controller controller = ((program)"controller")();
string static_dir = Stdio.append_path(getcwd(), "static");

static void create()
{
}

public mixed handle_request(.Request request)
{

  function event;

  if(has_prefix(request->not_query, "/static/"))
  {
    return static_request(request)->get_response();
  }

  array x = get_event(request);

  if(sizeof(x)>1)
    event = x[0];

  array args = x[1..];

  .Response response = .Response();
  
  if(functionp(event))
    event(request, response, @args);

  else response->set_data("Unknown event: %O\n");

  return response->get_response();
}

array get_event(.Request request)
{
  .Controller cc = controller;
  function event;
  array args = ({});

  array r = request->not_query/"/";

  // first, let's find the right function to call.
  foreach(r; int i; string comp)
  {
    if(!strlen(comp))
    {
      // ok, the last component was a slash.
      // that means we should call the index method in 
      // the current controller.
      if((i+1) == sizeof(r))
      {
         if(event)
         {
           werror("undefined situation! we have to fix this.\n");
         }
         else if(cc && cc["index"])
         {
           event = cc["index"];
         }
         else
         {
            werror("cc: %O\n", cc);
            werror("fall through!!!!\n");
         }
         break;
      }
      else
      {
        // what should we do?
        if(event)
        {
          args+=({comp});
        }
      }
    }

    // ok, the component was not empty.
    else
    {
      if(event)
      {
        args+=({comp});
      }
      else if(cc && cc[comp] && functionp(cc[comp]))
      {
        event = cc[comp];
      }
      else if(cc && cc[comp] && objectp(cc[comp]))
      {
        if(!Program.implements(object_program(cc[comp]), Fins.Controller))
        {
          throw(Error.Generic("Component " + comp + " is not a Controller.\n"));
        }    
        else
        {
          cc = cc[comp];
        }
      }
      else
      {
        throw(Error.Generic("Component " + comp + " does not exist.\n"));
      }
    }
  }

  werror("got to end of path; current controller: %O, event: %O, args: %O\n", cc, event, args);

  // we got all this way without an event.
  if(!event && r[-1] != "")
  {
    event = lambda(.Request request, .Response response, mixed ... args)
    {
      response->redirect(request->not_query + "/");
    };
  }

  if(args)
    return ({event, args});
 
  else return ({event});

}

.Response static_request(.Request request)
{
  .Response response = .Response();
  string fn = Stdio.append_path(static_dir, request->not_query[7..]);
  Stdio.Stat stat = file_stat(fn);
  if(!stat || stat->isdir)
  {
    response->not_found(request->not_query);
    return response;
  }
  
  response->set_type(Protocols.HTTP.Server.filename_to_type(basename(fn)));
  response->set_file(Stdio.File(fn));

  return response;
}
