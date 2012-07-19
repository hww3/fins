//! A mixin for controllers at the root of the application tree
//! 
//! Currently, this class merely registers the /static/ directory as a 
//! @[Fins.StaticController].

protected void create(object a)
{
  string static_dir = Stdio.append_path(a->config->app_dir, "static/");
  
  ::`[]("add_action", 3)("static", Fins.StaticController(a, static_dir, 1));
}