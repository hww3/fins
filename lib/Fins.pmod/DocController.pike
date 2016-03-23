inherit .FinsController;
import Tools.Logging;
Fins.Template.Template __layout;
int __checked_layouts; 

//! set this to a particular template type if you don't want to use the default type defined in your application's view class
protected program __default_template;


//! set this flag to true to turn off notices for events which have no 
//! corresponding template file.
int __quiet;

protected int __has_errors;

//!
//!  Implements a controller which automatically provides a view based on
//!  the position of the request within the tree
//!
//!  it is the same as the standard controller, except that event functions
//!  receive an additional argument:
//!
//!  void event(Fins.Request request, Fins.Response response,
//!                  Fins.Template.View view, mixed ... args);
//!
//!  the view parameter provided will be loaded from a file according to the 
//!  event's name and position in the controller tree. for example, event "foo"
//!  within controller "bar" would cause the template "foo/bar" to be loaded.
//!
//!  @note
//!   If you have an event without a template, an error will not be thrown, but a view will not be set or provided.
//!
//!  DocController now sets a layout from the following locations, if present:
//!
//!  templates/layouts/path/to/controller.phtml
//!  templates/layouts/application.phtml
//!
//!  if a layout is set and detected, you must reload to change the layout file name (ie, switching from application.phtml to controller.phtml). 
//!  templates detected and changed will be reloaded if the file content changes.
//!
//!  use the <%yield%> macro in your layout file to insert the template specified.
//!
//!  additionally you may simply use Template.View->set_layout() instead, in your own non DocController apps.

mapping __vc = ([]);

//! perform some standard boilerplate functionality for each request
void populate_template(Fins.Request request, Fins.Response response, Fins.Template.View lview, mixed args)
{
}

protected mixed `[](mixed a)
{
  mixed v; 

  if(v = __vc[a])
    return v;

  if(v = ::`[](a, 2))
  {
    if(objectp(v)) return v;
    else if(functionp(v))
      return (__vc[a] = DocRunner(v));
    else return v;
  }
  else 
  {
    return UNDEFINED;
  }
}

object __get_view(mixed path)
{
   return view->low_get_view(__default_template||view->default_template, path);
}

object __get_layout(object request)
{
  if(__layout) return __layout;
//werror("  dont have layout yet\n");

  if(__checked_layouts && !request->pragma["no-cache"]) return 0;
//werror("  wooh\n");

  mixed e;
  object l;
  __checked_layouts = 1;
  array paths = ({
  });
//werror("  calculating paths\n");

  foreach(request->controller_path/"/";; string p)
  {
    if(!sizeof(p)) continue;
      
    if(sizeof(paths))
      paths += ({ paths[-1] + "/" + p });
    else paths += ({"/layouts/" + p });
  }

  paths = reverse(paths);

  paths +=({ "/layouts/application" });

  foreach(paths;; string p)
  {
    e = catch(l = view->low_get_template(__default_template || view->default_template, p, 0, 1));
    if(!e)
      break;
    else
    {
      if(e && objectp(e) && e->is_templatecompile_error)
        view->log->exception("Unable to load layout from \"" + p + "\", error was %s.", e);
    }
  }
  return __layout = l;
}

private class DocRunner(function req)
{
  inherit .Helpers.Runner;

  protected mixed `()(Fins.Request request, Fins.Response response, mixed ... args) 
  {
    run(request, response, @args);
    return 0;
  }

  Fins.FinsController get_controller()
  {
    return function_object(req);
  }

  string get_name()
  {
    return function_name(req);
  }

  protected int(0..1) _is_type(string bt)
  {
    if(bt=="function")
      return 1;
    else
      return 0;
  }

  void run(Fins.Request request, Fins.Response response, mixed ... args)
  {
    object layout = __get_layout(request);
    Fins.Template.View lview;

    if(layout)
      view->log->debug("Have a layout: %O\n", layout);

    mixed e;
    e = catch(lview = __get_view(request->not_args));

    if(e && objectp(e) && e->is_templatecompile_error)
    {
      view->log->exception("An error occurred while compiling the template " + request->not_args + "\n", e);	
//      throw(e);
    }
    else if( (e || !lview)  && !__quiet) 
    {
      view->log->exception("An error occurred while loading the template " + request->not_args + "\n"
        "To turn these notices off, set the __quiet flag in your DocController instances.", e);
    }
    else if((e || !lview) && __quiet)
    {
      if(!__has_errors)
      {
        view->log->debug("An error occurred while loading a template in controller %O; this error has been surpressed.\n"
			"To enable these errors, unset the __quiet flag in your DocController instance.", get_controller());
        __has_errors++;
      }
    }

werror("layout: %O lview: %O\n", layout, lview);
    if(layout && lview)
    {
werror("setting layout.\n");
      lview->set_layout(layout);
    }
    if(lview)
      response->set_view(lview);

    populate_template(request, response, lview, args);

    view->log->info("Running %O(%O, %O, %O, %O)", req, request, response, lview, args);
    
    req(request, response, lview, @args);

    return;
  }
}
