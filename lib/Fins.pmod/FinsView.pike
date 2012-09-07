import Tools.Logging;
import Fins;
inherit FinsBase : base;
inherit Fins.Helpers.Macros.JavaScript;
inherit Fins.Helpers.Macros.Basic;
inherit Fins.Helpers.Macros.Scaffolding;

Tools.Logging.Log.Logger log = get_logger("fins.view");

//! the default class to be used for templates in this application
program default_template = Fins.Template.Simple;
program default_string_template = Fins.Template.StringSimple;

//! the default template data object class for use in this application
program default_data = Fins.Template.TemplateData;

//! the default template context class to be used in this application
program default_context = Fins.Template.TemplateContext;

static mapping templates = ([]);
static mapping(string:function|string) macros = ([]);

//! the base View class

//!
static void create(object app)
{
	::create(app);
  
	load_macros();
}

static void load_macros()
{
  foreach(glob("simple_macro_*", indices(this)); ; string mf)
  {
    log->debug("loading macro %O", mf[13..]);
    add_macro(mf[13..], this[mf]);
  }
  
  foreach(glob("*" +  default_template.TEMPLATE_EXTENSION, get_dir("macros")); ; string mf)
  {
    string mn = mf[0..<sizeof(default_template.TEMPLATE_EXTENSION)];
    log->debug("loading string macro %O", mn);
    add_macro(mn, Stdio.read_file(combine_path("macros", mf)));
  }
  
}

//! macros can be either "simple" macros, which are pike functions, or they can be text strings,
//! which are treated as templates of the default type, and which receive any arguments passed
//! in the macro invocation as data in a mapping called "args".
//! 
//! upon startup, string macros are loaded from files contained in the macros directory.
//! "simple" macros are loaded by scanning the view class for functions with names in the form of
//! "simple_macro_abc", where abc is the name under which the macro will be registered.
public void add_macro(string name, function|string macrocode)
{
  if(functionp(macrocode))
    macros[name] = macrocode;
  else
    macros[name] = StringMacroRunner(name, macrocode, this);
}

class StringMacroRunner(string name, string macrocode, object view)
{
  static function `()(Fins.Template.TemplateData data, mapping|void args)
  {
    return view->render_string_partial(macrocode, data->get_data() + (["args": args]), 0, 0, data->get_request());
  }
}

//!
public function|string get_macro(string name)
{
  return macros[name];
}

public string render_partial(string view,  mapping data, 
                                 string|void collection_name, mixed|void collection, void|Fins.Request request)
{
//werror("render_partial(%O)\n", request);
	string result = "";
	object v = get_view(view);
  return low_render_partial(v, data, collection_name, collection, request);
}

public string render_string_partial(string view,  mapping data, 
                                 string|void collection_name, mixed|void collection, void|Fins.Request request)
{
//werror("render_partial(%O)\n", request);
	string result = "";
	object v = get_string_view(view);
  return low_render_partial(v, data, collection_name, collection, request);
}

//!
public string low_render_partial(object v, mapping data, 
                                 string|void collection_name, mixed|void collection, void|Fins.Request request)
{
//werror("render_partial(%O)\n", request);
	string result = "";
	
	if(collection_name)
	{
		if(request)
      v->data->set_request(request);
		foreach(collection;mixed i; mixed c)
		{
			mapping d = data + ([]);
			d[collection_name] = c;
      d->id = i;
			v->data->set_data(d);
			result += v->render();
		}
	}
  else
	{
		if(request)
      v->data->set_request(request);
		v->data->set_data(data);
		result += v->render();
	}	

	return result;
}

//! create a view using the template program specified. 
//! @param templateType
//!      a program implementing Fins.Template.Template
//!
//!  @param tn
//!     a string passed to the constructor of the template program.
//!     the meaning of this value will vary depending on the template
//!     implementation. often, this is the name of the template to load,
//!     or it may be the actual content of the template, for example in 
//!     @[Fins.Template.StringSimple].
public Template.View low_get_view(program templateType, string tn)
{
  object t;

  t = low_get_template(templateType, tn);

  object d = default_data();

  d->set_data((["config": config])); 

  return Template.View(t, d);
}

//! get a view using the default string template type. 
//!
//! @param ts
//!   a string to be used as the template data
//!
//! app config is added as a value to the template data object as the value "config".
public Template.View get_string_view(string ts)
{
  return low_get_view(default_string_template, ts);
}

//! get a view using the default string template type, with fallback to a string containing
//! the content of a template. 
public Template.View get_fallback_string_view(string|function path, string fallback_template_string)
{
  object v;
  mixed e;
  if(!stringp(path))
    path = app->get_path_for_action(path);
  e = catch(v = view->get_view(path));
  if(e)
  {
    Log.debug("load of view from template failed, using default template string.\n");
    v = get_string_view(fallback_template_string);
  }
  return v;
}

//! get a view using the default template type. 
//!
//! @param tn
//!   a string containing the name of the template to load. how this is loaded is dependent on
//!   the behavior of the specified default template type
//!
//! app config is added as a value to the template data object as value "config".
public Template.View get_view(string tn)
{
  return low_get_view(default_template, tn);
}

//!
public Template.Template low_get_template(program templateType, string templateName, void|object context, int|void is_layout)
{
  object t;

// werror("low_get_template(%O, %O, %O, %O)\n", templateType, templateName, context, is_layout);

  if(!context) 
  {
    context = default_context();
    context->application = app;
    context->view = this;
  }

  if(!templateName || !stringp(templateName))
    throw(Error.Generic("get_template(): template name not specified.\n"));

  if(!templates[templateType])
  {
    templates[templateType] = ([]);
  }

  if(!(t = templates[templateType][templateName]))
  {
 //   werror("trying for template.\n");
    mixed err = catch(
    t = templateType(templateName, context, is_layout));
    if(err)
      log->exception("error while compiling.", err);
//    werror("got it.\n");
    if(!t)
    {
      throw(Error.Generic("get_template(): unable to load template " + templateName + "\n"));
    }

    templates[templateType][templateName] = t;
  }

//  if(t) werror("success.\n");
  return t;

}

//!
public int flush_template(string templateName)
{
   foreach(templates;; mapping templateT)
   if(templateT[templateName])
   {
      m_delete(templateT, templateName);
      return 1;
   }
   return 0;
}

//!
public int flush_templates()
{
  templates = ([]);
}

