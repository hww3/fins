//! A mixin for controllers at the root of the application tree
//! 
//! Currently, this class merely registers the /static/ directory as a 
//! @[Fins.StaticController].

protected void create(object a)
{
  string static_dir = Stdio.append_path(a->config->app_dir, "static/");
  
  this->add_action("static", Fins.StaticController(a, static_dir, 1));
//  ::`[]("add_action", 2)("static", Fins.StaticController(a, static_dir, 1));
}
