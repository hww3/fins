inherit .Base;

object localeLogger = Tools.Logging.get_logger("fins.macros.LOCALE");

//!
string simple_macro_sessionid(Fins.Template.TemplateData data, mapping|void args)
{
  return data->get_request()->misc->session_id;
}

//! args id, string
string simple_macro_LOCALE(Fins.Template.TemplateData data, mapping|void args)
{
  object r = data->get_request();

  string t;

  if(!r)
  {
    t = args["string"];
  }
  else
  {
    if(!objectp(r)) // a real request will be an object, otherwise we won't be able to make Locale work. 
    {
      localeLogger->debug("returning string without Locale translation. request=%O, args=%O", r, args);
      return args["string"];
    }

    mixed e;
    if(e = catch(t = Locale.translate(r->get_project(), r->get_lang(), 
      (int)args["id"], args["string"])))
      localeLogger->exception(sprintf("LOCALE macro failed: %O, args: %O\n", r, args), e);
  }
    return t;
}

//! args: var
string simple_macro_humanize(Fins.Template.TemplateData data, mapping|void args)
{
//	werror("humanize: %O\n", args->var);
  return Tools.Language.Inflect.humanize(args->var || "");
}

//! args: 
string simple_macro_dump_data(Fins.Template.TemplateData data, mapping|void args)
{
  return sprintf("%O\n", mkmapping(indices(data->get_data()), values(data->get_data())));
}

//! args: 
string simple_macro_dump_id(Fins.Template.TemplateData data, mapping|void args)
{
  return sprintf("%O\n", mkmapping(indices(data->get_request()), values(data->get_request())));
}

//! populate a data field with a mapping containing available language codes (keys) and native names (values)
//!
//! args: name
string simple_macro_available_languages(Fins.Template.TemplateData data, mapping|void args)
{
    // we do this to force a language update, if it hasn't happened already.
    string lang = data->get_request()->get_lang();
    data->get_data()[args->name] = app->available_languages();	
	return "";
}

//! produce a drop down language selector
//!
//! args: text
string simple_macro_language_selector(Fins.Template.TemplateData data, mapping|void args)
{
	String.Buffer buf = String.Buffer();

    // we do this to force a language update, if it hasn't happened already.
    string lang = data->get_request()->get_lang();
 	mapping l = app->available_languages();	

	buf += "<form id=\"language_form\">\n";
        buf += (args->text || "Language: ");
        buf += "<input type=\"hidden\" name=\"qd\" value=\"" + time() + "\">";
	buf += "<select name=\"_lang\" ";
	buf += "onChange=\"document.getElementById('language_form').submit();\"";
	buf += ">\n";

	foreach(l; string k; string v)
	{
           if(k == lang)
		buf += "<option selected=\"1\" value=\"" + k + "\">" + v + "</option>\n";
           else
		buf += "<option value=\"" + k + "\">" + v + "</option>\n";
	}

	buf += "</select>\n</form>\n";

	return buf->get();
}



//! args: controller, action, args, _id=dom element id
//!
//! any arguments other than those above will be considered variables to 
//! be added to the url above.
string simple_macro_action_link(Fins.Template.TemplateData data, mapping|void args)
{
  object controller;
  object request = data->get_request();
  string event = "index";
  if(args->action)
    event = args->action;
//  if(!event) throw(Error.Generic("action_link: event name must be provided.\n"));

  catch(controller = request->controller);
  if(args->controller)
    controller = app->get_controller_for_path(args->controller, controller);
  if(!controller) throw(Error.Generic("action_link: controller " + args->controller + " can not be resolved.\n"));

  mixed action = controller[event];
  if(!action) throw(Error.Generic("action_link: action " + args->action + " can not be resolved.\n"));

  array uargs;

  if(args->args)
    uargs = ((string)args->args)/"/";

  string target = (args["#"]?("#" + args["#"]):"");
  
  string id;

  if(args->_id) 
    id = args->_id;

  m_delete(args, "_id");
  m_delete(args, "controller");
  m_delete(args, "action");
  m_delete(args, "args");
  m_delete(args, "#");

  string url = app->url_for_action(action, uargs, args);

  return "<a href=\"" + url + target + "\"" + (id?(" id=\"" + id + "\">"):">");
}

//! args: controller, action, args, method, enctype
//!
//! any arguments other than those above will be considered variables to 
//! be added to the url above.
string simple_macro_action_form(Fins.Template.TemplateData data, mapping|void args)
{
  object controller;
  object request = data->get_request();
  string event = "index";
  if(args->action)
    event = args->action;
//  if(!event) throw(Error.Generic("action_form: event name must be provided.\n"));

  controller = request->controller;
  if(args->controller)
    controller = app->get_controller_for_path(args->controller, controller);
  if(!controller) throw(Error.Generic("action_form: controller " + args->controller + " can not be resolved.\n"));

  mixed action = controller[event];
  if(!action) throw(Error.Generic("action_form: action " + args->action + " can not be resolved.\n"));

  array uargs;

  if(args->args)
    uargs = args->args/"/";

  string other = "";

  if(args->method) other += " method=\"" + args->method + "\"";
  if(args->enctype) other += " method=\"" + args->enctype + "\"";

  m_delete(args, "controller");
  m_delete(args, "action");
  m_delete(args, "args");
  m_delete(args, "method");
  m_delete(args, "enctype");

  string url = app->url_for_action(action, uargs, args);

  return "<form action=\"" + url + "\"" + other + ">";
}

//! args: controller, action, args 
//!
//! any arguments other than those above will be considered variables to 
//! be added to the url above.
string simple_macro_action_url(Fins.Template.TemplateData data, mapping|void args)
{
  object controller;
//werror("******* action_url\n");
  object request = data->get_request();
  string event = args->action;
//  if(!event) throw(Error.Generic("action_link: event name must be provided.\n"));

  controller = request->controller;
  if(args->controller)
    controller = app->get_controller_for_path(args->controller, controller);
  if(!controller) throw(Error.Generic("action_link: controller " + args->controller + " can not be resolved.\n"));

  mixed action = controller[event||"index"];
  if(!action) throw(Error.Generic("action_link: action " + args->action + " can not be resolved.\n"));
//werror("********* action: %O\n", action);
  array uargs;

  if(args->args)
    uargs = args->args/"/";

 string target = (args["#"]?("#" + args["#"]):"");

  m_delete(args, "controller");
  m_delete(args, "action");
  m_delete(args, "args");
  m_delete(args, "#");

  string url = app->url_for_action(action, uargs, args) + target;

  return url;
}

//! args: none required, arg "mandatory" may be specified, and args "name",
//! "value" and "checked" enable special functionality, below.
//!
//! generates an input tag with any args passed along.
//! if value in the request's variables mapping with the same name is present,
//! it will be used to fill the default value, overriding the default passed
//! as the "value" argument.
//! 
//! if field of type "checkbox" or "radio", and the argument "checked" is present
//! with a value of "1", the input will be "activated". "data_supplied" is a value that,
//! if present disables the checked argument for checkboxes (since unchecked boxes don't
//!  provide a value when submitted, it appears to this control as if no value were provided)
string simple_macro_input(Fins.Template.TemplateData data, mapping|void args)
{
//werror("******* input\n");
  object request = data->get_request();
  string event = args->action;
//  if(!event) throw(Error.Generic("action_link: event name must be provided.\n"));
  mixed v;
  int checked; 
  
  if(!args) args = ([]);

  string type = lower_case(args->type||"");
  
  if(!(<"radio", "checkbox">)[type] && args->name && ((v = request->variables[args->name]) && !arrayp(v)))
    args->value = (string)v;

  String.Buffer buf = String.Buffer();
  buf->add("<input");

  foreach(args;string s;string v)
  { 
    if((<"radio", "checkbox">)[type])
    {
      if(lower_case(s) == "checked")
      {
        checked = 1;
        continue;      
      }
      if(lower_case(s) == "data_supplied")
        continue;
    }
    buf->add(" " + s + "=\"" + v + "\""); 
  }
  
  werror("is %O(%O) == %O?", args->name, args->value, request->variables[args->name]);
  if((<"radio", "checkbox">)[type] && 
    ((request->variables[args->name] == (string)args->value) ||
        (arrayp(request->variables[args->name]) && search(request->variables[args->name], (string)args->value)!=-1)) 
    || (checked &&  !args->data_supplied))
  {
      buf->add(" checked=\"1\"");
  }
  
  buf->add("/>");

  if(args->mandatory && lower_case(args->mandatory) != "false")
  {
	if(!args->value || !sizeof(args->value))
	{
		buf->add("<font class=\"mandatory\" *</font>");
	}
  }

  return buf->get();
}

//! args: none required, args "mandatory", "default_value", "options"  may be specified
//!
//! options may point to an array of strings or an array of 2 element arrays, where the first element
//! is the value name and the second element is the value to display to the user in the drop-down.
//!
//! generates a select tag with any args passed along
//!  and a value in the request's variables mapping used to fill the default value
string simple_macro_select(Fins.Template.TemplateData data, mapping|void args)
{
  object request = data->get_request();
  string event = args->action;
  mixed v;
  String.Buffer buf = String.Buffer();

  if(!args) args = ([]);

  if(args->name && (v = request->variables[args->name]))
    args->value = v;

  array valid_options = args->options;
  string value = args->value || args->default_value;

  m_delete(args, "value");
  m_delete(args, "default_value");
  m_delete(args, "options");

  buf->add("<select");

  foreach(args; string s;string v)
  { 
    buf->add(" " + s + "=\"" + v + "\""); 
  }

  buf->add("/>\n");

  foreach(valid_options;; string|array vo)
  {
    string dn = ""; // display name
    string vn = ""; // value name

    if(arrayp(vo)) { dn = vo[1]; vn = vo[0]; }
    else 
    {
      vn = vo;
      dn = vo;
    }  
      
      buf->add("<option value=\"" + vn + "\"");

      if(vn == value)
        buf->add(" selected=\"1\"");

      buf->add(">");
      buf->add(dn);
      buf->add("</option>\n");
     
  }
  

  buf->add("</select>\n");

  if(args->mandatory && lower_case(args->mandatory) != "false")
  {
	if(!args->value || !sizeof(args->value))
	{
		buf->add("<font class=\"mandatory\" *</font>");
	}
  }
  return buf->get();
}


//! args: none required, arg "mandatory" may be specified
//!
//! generates a textarea with any args passed along
//!  and a value in the request's variables mapping used to fill the default value
string simple_macro_textarea(Fins.Template.TemplateData data, mapping|void args)
{
  object request = data->get_request();
  string event = args->action;
  mixed v;

  if(!args) args = ([]);

  if(args->name && (v = request->variables[args->name]))
    args->value = v;

  string value = args->value || "";
  m_delete(args, "value");

  String.Buffer buf = String.Buffer();
  buf->add("<textarea");
  foreach(args;string s;string v)
  { 
    buf->add(" " + s + "=\"" + v + "\""); 
  }
  buf->add("/>");
  buf->add(value);  
  buf->add("</textarea>");

  if(args->mandatory && lower_case(args->mandatory) != "false")
  {
	if(!args->value || !sizeof(args->value))
	{
		buf->add("<font class=\"mandatory\" *</font>");
	}
  }

  return buf->get();
}

//! args: var
string simple_macro_autoformat(Fins.Template.TemplateData data, mapping|void args)
{
    return replace(args->var||"", ({"\n\n", "\n"}), ({"<p/>", "<br/>"}));
}

//! args: var
string simple_macro_capitalize(Fins.Template.TemplateData data, mapping|void args)
{
    return String.capitalize(args->var||"");
}

//! args: var
//! if var is not provided, it is assumed to be "msg".
string simple_macro_flash(Fins.Template.TemplateData data, mapping|void args)
{
    if(!args->var) args->var = "msg";
    return (data->get_flash()[args->var]||"");
}

//! args: var
string simple_macro_sizeof(Fins.Template.TemplateData data, mapping|void args)
{
    return (string)(sizeof(args->var ||({})));
}

//! args: var, splice, final
string simple_macro_implode(Fins.Template.TemplateData data, mapping|void args)
{
  mixed v = args->var;

  if(!arrayp(v))
    return "invalid type for " + args->var;

  string retval = "";

  if(args->nice)
  {
    retval = String.implode_nicely(v, args->nice);
  }
  else
  {
    retval = v*args->final;
  }
  
  return retval;
}
	
//! args: var
string simple_macro_boolean(Fins.Template.TemplateData data, mapping|void args)
{
        mixed v = args->var;
                if (intp(v))
                {
                        return (v != 0)?"Yes":"No";
                }
                else if(stringp(v))
                {
                        return ((int)v != 0)?"Yes":"No";
                }
                else
                {
                        return "invalid type for boolean ";
                }
}

//! args: var
string simple_macro_describe_object(Fins.Template.TemplateData data, mapping|void args)
{
  mixed v = args->var;

  if(objectp(v) && v->describe) return v->describe();
  else return sprintf("%O\n", v);
}

//! args: var
string simple_macro_describe(Fins.Template.TemplateData data, mapping|void args)
{
  string key = args->key;
  mixed value = args->var;
  string rv = "";

    if(stringp(value) || intp(value))
      rv += value; 
    else if(arrayp(value))
      rv += describe_array(0, key, value);
    else if(objectp(value))
      rv += describe_object(0, key, value);

  return rv;
}

//! display a calendar object as a distance in the past in a friendly manner 
//!
//! args: var
string simple_macro_friendly_date(Fins.Template.TemplateData data, mapping|void args)
{
  mixed p = args->var;

  if(intp(p))
    p = Calendar.Second(p);

  return Tools.String.friendly_date(p);
}


//! display a calendar object in a friendly manner using a format appropriate to the
//! time interval the calendar object represents (week, month, second, etc)
//!
//! args: var
string simple_macro_describe_date(Fins.Template.TemplateData data, mapping|void args)
{  
  mixed p = args->var;

  if(intp(p))
    p = Calendar.Second(p);
      
  return Tools.String.describe_date(p);
}

//! display a calendar object as a date and time in a friendly manner
//!
//! args: var
string simple_macro_describe_datetime(Fins.Template.TemplateData data, mapping|void args)
{  
  mixed p = args->var;

  if(intp(p))
    p = Calendar.Second(p);
      
  if(p && p->format_ext_time_short)
    return p->format_ext_time_short();
  else return "N/A";
}

//! provides the context root of this application, if any
//!
string simple_macro_context_root(Fins.Template.TemplateData data, mapping|void args)
{
  return app->context_root;
}

//! args: var, format
//! where var is a calendar object or a unix timestamp. format is a Calendar object format type; default is ext_ymd.
//!
//! short_date: 13 Jun 2012
//! year: 2012
//! short_month_name: Jun
//! month_name: June
//! month_day: 13
//  time12: 3:55 PM
//  time24/time: 15:55
//! 
//!
//! iso_short: 20120513T15:55:47
//! time_xshort: 120513 15:55:47
//! time_short: 20120513 15:55:47
//! ext_time_short: Sun, 13 May 2012 15:55:47 EDT
//! ymd_short: 20120513
//! week_short: 2012w19
//! month_short: 201205
//! tod_short: 155547
//! ymd_xshort: 120513
//! iso_week_short: 201219
//! commonlog: 13/May/2012:15:55:47 -0400
//! iso_ymd: 2012-05-13 (May) -W19-7 (Sun)
//! ext_ymd: Sunday, 13 May 2012
//! ymd: 2012-05-13
//! smtp: Sun, 13 May 2012 15:55:47 -0400
//! nicez: 13 May 15:55:47 EDT
//! nice: 13 May 15:55:47
//! month: 2012-05
//! week: 2012-w19
//! iso_week: 2012-W19
//! todz: 15:55:47 EDT
//! tod: 15:55:47
//! http: Sun, 13 May 2012 19:55:47 GMT
//! ctime: Sun May 13 15:55:47 2012
//!
//! xtime: 2012-05-13 15:55:47.000000
//! mtime: 2012-05-13 15:55
//! time: 2012-05-13 15:55:47
//! ext_time: Sunday, 13 May 2012 15:55:47
//! iso_time: 2012-05-13 (May) -W19-7 (Sun) 15:55:47 UTC-4
//! todz_iso: 15:55:47 UTC-4
//! mod: 15:55
//! xtod: 15:55:47.000000
string simple_macro_format_date(Fins.Template.TemplateData data, mapping|void arguments)
{
  string res;
  if(arguments->var)
  {
    mixed p = arguments->var;

    if(intp(p))
      p = Calendar.Second(p);
      
    if(!p) return "";

    if(! arguments->format) arguments->format="ext_ymd";

    switch(arguments->format)
    {
      case "time24":
      case "time":
         res = sprintf("%02d:%02d", p->hour_no(), p->minute_no());
         break;
      case "time12":
         int v;
         res = sprintf("%2d:%02d %s", (v=(p->hour_no()%12))?v:12, p->minute_no(), ((p->hour_no()/12)?"PM":"AM"));
         break;
      case "short_month_name":
         res = p->month_shortname();
         break;
      case "month_name":
         res = p->month_name();
         break;
      case "month_day":
         res = (string)p->month_day();
         break;
      case "year":
         res = (string)p->year_no();
         break;
      case "short_date":
         res = format_short_date(p);
         break;
      default:
        res = p["format_" + arguments->format]();
    }

    if(arguments->store)
    {
      mixed d = data->get_data();
      d[arguments->store] = res;
      return "";
    }
    else return res;
  }
}


protected string format_short_date(object d)
{
write("d: %O\n", d);
  return d->month_day() + " " + 
    d->month_shortname() + " " +
    d->year_no();
}


//! args: size
string simple_macro_friendly_size(Fins.Template.TemplateData data, mapping|void args)
{
  if(args->size)
  {
    int size = (int)args->size;
    if(size < 1024) return size + " bytes";
    if(size < 1024*1024) return sprintf("%.1f KB", size/1024.0);
    if(size < 1024*1024*1024) return sprintf("%.2f MB", size/(1024.0*1024.0));
    if(size < 1024*1024*1024*1024) return sprintf("%.12f GB", size/(1024.0*1024.0*1024.0));
  }
  else return "--";
}

