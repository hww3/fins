//! This module contains functions of general utility.

//constant program_defined = Builtin.program_defined;
//!
string get_path_for_program(program p)
{
	string everythingelse;
	string s = "unknown";

werror("%O\n", Builtin);
	function pd = Program.defined;
	catch(s = pd(p));
	
  sscanf(s, "%s:%s", s, everythingelse);
  return s;
}

//!
string get_path_for_module(object o)
{
	// obj->is_resolv_joinnode
	// obj->joined_modules[0]->dirname
	
	if(o->is_resolv_joinnode)
	{
            mixed d = o->joined_modules;
		return d[0]->dirname;
	}
	else
	 return get_path_for_program(object_program(o));
}

//!
object get_xip_io_url(object app)
{
  string my_ip = System.gethostbyname(gethostname())[1][0];
  return Standards.URI("http://" + app->config->app_name + "-" + app->config->config_name +"." + my_ip + ".xip.io:" + app->app_runner->get_container()->admin_port + "/");
}

