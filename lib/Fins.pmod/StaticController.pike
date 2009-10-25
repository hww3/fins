import Fins;

//!
//! a controller that serves a directory of static content.
//!
//! @note
//!   it's not necessary (and not very useful) to load a static controller 
//!   with @[load_controller]().
//!   
//!  additionally, directory listings are not generated by this controller.
//!
//! @example
//!   // in this example, mystaticdir will be served from the "foo" mountpoint.
//!   Fins.StaticController foo;
//!   void start() 
//!   {
//!      foo = Fins.StaticController(app, "mystaticdir");
//!	  }
//!

inherit Fins.FinsController;

static string static_dir;
static function low_static_request;


//! 
//! @param app
//!   the Fins application object, always available in your controller as "app"
//!
//! @param dir
//!   the directory to serve from this controller. if dir is a relative path,
//!   the directory is assumed to be relative to the application directory.
//!   absolute paths are allowed.
static void create(Fins.Application app, string|void dir)
{
	::create(app);
	if(dir)
	{
	  if(dir[0] != '/')
  	    dir = combine_path(app->config->app_dir, dir);
	  static_dir = dir;
	}
	
	low_static_request = app->low_static_request;
}


void index(Request req, Response resp, mixed ... args)
{
//	werror("Serving " + Stdio.append_path(static_dir, args*"/") + " from " + getcwd());
   	low_static_request(req, resp, Stdio.append_path(static_dir, args*"/"));
}
