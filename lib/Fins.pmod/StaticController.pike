import Fins;

//!
//! a controller that serves a directory of static content.
//!
//! @note
//!   it's not necessary (and not very useful) to load a static controller 
//!   with @[load_controller]().
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

//!
protected int allow_directory_listings = 0;

//! in hours
protected int static_expiry_period = 12;

//!
protected string static_dir;

protected object filesystem;

//! 
//! @param app
//!   the Fins application object, always available in your controller as "app"
//!
//! @param dir
//!   the directory to serve from this controller. if dir is a relative path,
//!   the directory is assumed to be relative to the application directory.
//!   absolute paths are allowed.
//!
//!  @param _allow_directory_listings
//!    if set to 1, requests to directory entries will generate a directory listing.
//!    the default is to deny directory listings.
protected void create(Fins.Application app, string|void dir, int|void _allow_directory_listings)
{
	::create(app);
	if(dir)
	{
	  if(dir[0] != '/')
  	    dir = combine_path(app->config->app_dir, dir);
	  static_dir = dir;
	}
	
	allow_directory_listings = _allow_directory_listings;
	filesystem = create_filesystem();
}

//! override this method to provide alternate filesystem access methods. should return a 
//! Filesystem.Base object rooted at the static directory.
protected Filesystem.Base create_filesystem()
{
  return Filesystem.System(static_dir)->chroot(static_dir);
}


void index(Request req, Response resp, mixed ... args)
{
//	werror("Serving " + Stdio.append_path(static_dir, args*"/") + " from " + getcwd());
   	low_static_request(req, resp, "/" + (args*"/"));
}

protected string default_directory_listing = 
#"<html>
<head>
<title>Directory Listing: <%$directory%></title>
</head>
<body>
<h1>Directory listing of <%$directory%></h1>
<hr/>
<%if data->parent%>
<a href=\"<%$parent%>\">Previous Directory</a>
<%endif%>
<table>
<tr>
<th>Filename</th>
<th>Size</th>
<th>Created</th>
<th>Type</th>
</tr>
<%foreach var=\"$entries\" val=\"entry\"%>
<tr>
<td><a href=\"<%$entry.link%>\"><%$entry.name%></a></td>
<td><%friendly_size size=\"$entry.size\"%></td>
<td><%format_date var=\"$entry.ctime\" format=\"mtime\"%></td>
<td><%$entry.type%></td>
</tr>
<%end%>
</table>
<hr/>
</body>
</html>
";

protected void generate_directory_listing(string filename, .Request request, .Response response, Filesystem.Base fs)
{
  array x;
  string listing = "";

  object view = view->get_fallback_string_view("application/directory", default_directory_listing);

  response->set_view(view);

  view->add("directory", request->not_query);

  if(filename != "/")
  { 
    view->add("parent", "../");
  }

  x = fs->get_stats(filename);
  array entries = allocate(sizeof(x));

  foreach(x;int i;object st)
  {
    mapping entry = ([]);

    if(st->isdir()) 
    {
       entry->name = st->name;
       entry->link = (st->name + "/");
       entry->type = "directory";
    }
    else
    {
       entry->name = st->name;
       entry->link =  st->name;
       entry->type = Protocols.HTTP.Server.filename_to_type(basename(filename));
    }

    entry->link = combine_path(request->not_query, entry->link);
    entry += mkmapping(indices(st), values(st));
    entries[i] = entry;    
  }
  
  view->add("entries", entries);
}

//! @param filename
//!  the object to fetch, an absolute path rooted at the static directory,
//!  for instance to fetch /etc/hosts from a static directory of /etc, 
//! filename would be /hosts.
protected .Response low_static_request(.Request request, .Response response, 
    string filename, void|Filesystem.Base fs)
{
  if(!fs) fs = filesystem;

  Filesystem.Stat stat = fs->stat(filename);
  if(stat && stat->isdir())
  {
    if(allow_directory_listings)
    {
      // FIXME: should we be basing this decision on filename instead? (think mapped requests)
      if(request->not_query[-1] != '/')
      {
        response->redirect(request->not_query + "/");
        return response;
      }
      else
        generate_directory_listing(filename, request, response, fs);
    }
    else // FIXME: should probably be a "not allowed" error.
      response->access_denied(request->not_query);
    return response;
  }
  else if(!stat)
  {
    response->not_found(request->not_query);
    return response;
  }

  if(request->request_headers["if-modified-since"] && 
      Protocols.HTTP.Server.http_decode_date(request->request_headers["if-modified-since"]) 
      >= stat->mtime) 
  {
    response->not_modified();
    return response;
  }

  response->set_header("Cache-Control", "max-age=" + (3600*static_expiry_period));
  response->set_header("Expires", (Calendar.Second() + (7200*static_expiry_period))->format_http());
  response->set_file(fs->open(filename, "r"));

  string type = Protocols.HTTP.Server.filename_to_type(basename(filename));
  response->set_type(type);
  int _handled;

  if (has_suffix(type, "css"))
  {
    app->_templatefilter->filter(request, response);
  }

  // content compression
  if (type && app->_gzfilter) {
    if (has_prefix(type, "text") || has_suffix(type, "xml")) {
      _handled = 1;
      app->_gzfilter->filter(request, response);
    }
    int pos = search(type, "/");
    if (!_handled && pos != -1) {
      switch(type[0..pos-1]) {
	case "text":
	case "application":
   	  app->_gzfilter->filter(request, response);
        break;
      }
    }
  }

  return response;
}
