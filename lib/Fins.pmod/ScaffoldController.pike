//
//! A controller that impliments CRUD functionality
//! for a given Model component.
//!

import Fins;
inherit Fins.DocController;
import Tools.Logging;

//! this should be the name of your object type and is used to link this
//! controller to the model. For auto-configured models, this is normally
//! a capitalized singular version of your table. For example, if your
//! table is called "users", this would be "User".
string model_component = 0;

//! if your application contains multiple model definitions, this should be the 
//! model "id" for the definition containing the component. the default value
//! selects the default model definition.
string model_id = Fins.Model.DEFAULT_MODEL;

object model_object;
object model_context;

//! Contains default contents of the template used for displaying a list of items
//! in this scaffolding. You may override the use of this string by creating 
//! a template file. Store the template file in your templates directory under
//! controller/path/list.phtml. For example, if your scaffold controller
//! is mounted at /widgets/, you would store the overriding template file in
//! templates/widgets/list.phtml.
string list_template_string = 
#"<html><head><title>Listing <%$type%></title></head>
  <body>
  <h1><%$type%></h1>
  <div class=\"flash-message\"><% flash var=\"$msg\" %></div>
  <%foreach var=\"$items\" val=\"item\"%> [ 
  <%action_link action=\"display\" id=\"$item._id\"%>view</a> | 
  <%action_link action=\"update\" id=\"$item._id\"%>edit</a> | 
  <%action_link action=\"delete\" id=\"$item._id\"%>delete</a> ] 
  <%describe_object var=\"$item\"%><br/>
  <%end%>
  <p>
  [ <%action_link action=\"new\"%>new</a> ] 
  </body></html>";

//! Contains default contents of the template used for displaying items
//! in this scaffolding. You may override the use of this string by creating 
//! a template file. Store the template file in your templates directory under
//! controller/path/display.phtml. For example, if your scaffold controller
//! is mounted at /widgets/, you would store the overriding template file in
//! templates/widgets/display.phtml.
string display_template_string =
#"<html><head><title>Displaying <%$type%></title></head>
  <body>
  <h1>Viewing <%$type%></h1>
  <div class=\"flash-message\"><% flash var=\"$msg\" %></div>
  <%action_link action=\"update\" id=\"$item._id\"%>Edit</a><p>
  <table>
  <%foreach var=\"$field_order\" ind=\"key\" val=\"value\"%>
  <tr><td><b><%humanize var=\"$value\"%></b></td><td><%field_describe field=\"$value\" item=\"$item\"%></td></tr>
  <%end %>
  </table>
  <p/>
  <%action_link action=\"list\"%>Return to List</a><p>
  </body></html>";

//! Contains default contents of the template used for editing items
//! in this scaffolding. You may override the use of this string by creating 
//! a template file. Store the template file in your templates directory under
//! controller/path/update.phtml. For example, if your scaffold controller
//! is mounted at /widgets/, you would store the overriding template file in
//! templates/widgets/update.phtml.
string update_template_string =
#  "<html><head><title>Editing <%$type%></title>
   <script type=text/javascript>function fire_select(n){
    window.document.forms[0].action = n;
    window.document.forms[0].submit();
    }</script>
  </head>
  <body>
  <h1>Editing <%$type%></h1>
  <div class=\"flash-message\"><% flash var=\"$msg\" %></div>
  <form action=\"<% action_url action=\"doupdate\" %>\" method=\"post\">
  <table>
  <%foreach var=\"$field_order\" ind=\"key\" val=\"value\"%>
  <tr><td><b><%humanize var=\"$value\"%></b></td><td><%field_editor item=\"$item\" field=\"$value\" orig=\"$orig\"%></td></tr>
  <%end %>
  </table>
  <input name=\"___cancel\" value=\"Cancel\" type=\"submit\"> 
  <input name=\"___orig_data\" value=\"<%$orig_data%>\" type=\"hidden\">
  <input name=\"___save\" value=\"Save\" type=\"submit\"> 
  <input name=\"___fields\" value=\"<%$fields%>\" type=\"hidden\">
  </form>
  <p/>
  <%action_link action=\"list\"%>Return to List</a><p>
  </body></html>";

//! Contains default contents of the template used for creating items
//! in this scaffolding. You may override the use of this string by creating 
//! a template file. Store the template file in your templates directory under
//! controller/path/new.phtml. For example, if your scaffold controller
//! is mounted at /widgets/, you would store the overriding template file in
//! templates/widgets/new.phtml.
string new_template_string =
#  "<html><head><title>Creating <%$type%></title>
   <script type=text/javascript>function fire_select(n){
    window.document.forms[0].action = n;
    window.document.forms[0].submit();
    }</script>
  </head>
  <body>
  <h1>Creating <%$type%></h1>
  <div class=\"flash-message\"><% flash var=\"$msg\" %></div>
  <form action=\"<% action_url action=\"donew\" %>\" method=\"post\">
  <table>
  <%foreach var=\"$field_order\" ind=\"key\" val=\"value\"%>
  <tr><td><b><%humanize var=\"$value\"%></b></td><td><%field_editor item=\"$item\" field=\"$value\" orig=\"$orig\"%></td></tr>
  <%end %>
  </table>
  <input name=\"___cancel\" value=\"Cancel\" type=\"submit\"> 
  <input name=\"___save\" value=\"Save\" type=\"submit\"> 
  <input name=\"___fields\" value=\"<%$fields%>\" type=\"hidden\">
  </form>
  <p/>
  <%action_link action=\"list\"%>Return to List</a><p>
  </body></html>";

  //! Contains default contents of the template used to confirm deletion
  //! in this scaffolding. You may override the use of this string by creating 
  //! a template file. Store the template file in your templates directory under
  //! controller/path/delete.phtml. For example, if your scaffold controller
  //! is mounted at /widgets/, you would store the overriding template file in
  //! templates/widgets/delete.phtml.
  string delete_template_string =
  #  "<html><head><title>Confirm: Really delete <%$type%>?</title>
    </head>
    <body>
    <h1>Confirm Deletion of <%$type%></h1>
    <div class=\"flash-message\"><% flash var=\"$msg\" %></div>
    <form action=\"<% action_url action=\"delete\" %>\" method=\"post\">
    <input name=\"___cancel\" value=\"Cancel\" type=\"submit\"> 
    <input name=\"___delete\" value=\"Delete\" type=\"submit\"> 
    <input name=\"id\" value=\"<%$item._id%>\" type=\"hidden\">
    </form>
    <p/>
    </body></html>";

  string pick_one_template_string =
  # "<html><head><title>Choose Value: <%$type%> for <%$nicefor%></title>
    </head>
    <body>
    <h1>Choose <%$type%> for <%$nicefor%></h1>
    <div class=\"flash-message\"><% flash var=\"$msg\" %></div>
    <form action=\"<% action_url action=\"do_pick\"%>\" method=\"post\">
    <p/><input type=\"submit\" name=\"__return\" value=\"Cancel\">
    <input type=\"submit\" name=\"__select\" value=\"Select\">
    <p/>
    <%foreach var=\"$values\" ind=\"key\" val=\"value\"%>
      <%if data->value->get_id() == data->previous_selection %>
      <input type=\"radio\" name=\"selected_id\" value=\"<%$value._id%>\" checked=\"1\"> <%describe_object var=\"$value\"%><br/>
      <%else%>
      <input type=\"radio\" name=\"selected_id\" value=\"<%$value._id%>\"> <%describe_object var=\"$value\"%><br/>
      <%endif%>
    <%end%>
   <input type=\"hidden\" name=\"old_data\" value=\"<%$old_data%>\">
   <input type=\"hidden\" name=\"selected_field\" value=\"<%$selected_field%>\">
   <input type=\"hidden\" name=\"for\" value=\"<%$for%>\">
   <input type=\"hidden\" name=\"for_id\" value=\"<%$for_id%>\">
   <p/><input type=\"submit\" name=\"__return\" value=\"Cancel\">
   <input type=\"submit\" name=\"__select\" value=\"Select\"></form>
   </form>
   <p/>
   </body></html>";

   string pick_many_template_string =
   # "<html><head><title>Choose Values: <%$type%> for <%$nicefor%></title>
     </head>
     <body>
     <h1>Choose <%$type%> for <%$nicefor%></h1>
     <div class=\"flash-message\"><% flash var=\"$msg\" %></div>
     <form action=\"<% action_url action=\"do_pick\"%>\" method=\"post\">
     <p/><input type=\"submit\" name=\"__return\" value=\"Cancel\">
     <input type=\"submit\" name=\"__select\" value=\"Select\">
     <p/>
     <%foreach var=\"$values\" ind=\"key\" val=\"value\"%>
       <%input type=\"checkbox\" name=\"selected_id\" value=\"$value._id\" data_supplied=\"$for\"%><%describe_object var=\"$value\"%><br/>
     <%end%>
    <input type=\"hidden\" name=\"old_data\" value=\"<%$old_data%>\">
    <input type=\"hidden\" name=\"selected_field\" value=\"<%$selected_field%>\">
    <input type=\"hidden\" name=\"for\" value=\"<%$for%>\">
    <input type=\"hidden\" name=\"for_id\" value=\"<%$for_id%>\">
    <p/><input type=\"submit\" name=\"__return\" value=\"Cancel\">
    <input type=\"submit\" name=\"__select\" value=\"Select\"></form>
    </form>
    <p/>
    </body></html>";


object __get_view(mixed path)
{  
  object v;
  mixed e = catch(v = ::__get_view(path));

  if(e || !v)
  {
    Log.debug("load of view from template failed, using default template string.\n");
    if(!__quiet)
      Log.exception("Error follows", e);

    string pc = ((path/"/")[-1]) + "_template_string";
    string x = `->(this, pc);
//werror("getting simple view for %O: %O, %O\n", pc, x, indices(this));    
    v = view->get_string_view(x);
  }

  return v;
}

void start()
{
  if(model_component)
  {
	model_context = Fins.Model.get_context(model_id);
    model_object = model_context->repository->get_object(model_component);
    model_context->repository->set_scaffold_controller("html", model_object, this);
  }
}

public void index(Fins.Request request, Fins.Response response, mixed ... args)
{
  response->redirect(action_url(list));
}

public void list(Fins.Request request, Fins.Response response, Fins.Template.View v, mixed ... args)
{
//  object v = get_view(list, list_template_string);

  v->add("type", lower_case(model_object->instance_name_plural));

  object items = model_context->_find(model_object, ([]));

  if(!sizeof(items))
  {
    response->flash("msg", "No " + 
      lower_case(model_object->instance_name_plural)
      + " found.<p>\n");
  }
  else
  {
    v->add("items", items);
  }

  response->set_view(v);
}

public void display(Fins.Request request, Fins.Response response, Fins.Template.View v, mixed ... args)
{
//  object v = get_view(display, display_template_string);

  object item = model_context->find_by_id(model_object, (int)request->variables->id);
  v->add("type", make_nice(model_object->instance_name));

  if(!item)
  {
    response->flash("msg", make_nice(model_object->instance_name) + " not found.");
  }
  else
  {
//    mapping val = item->get_atomic();
    v->add("field_order", model_object->field_order);
    v->add("item", item);
  }

  response->set_view(v);
}

public void do_pick(Request id, Response response, Fins.Template.View v, mixed ... args)
{
  if(!(id->variables->for && id->variables->for_id))
  {
    response->set_data("error: invalid data.");
    return;
  }
  
  object sc = model_context->repository->get_scaffold_controller("html", model_context->repository->get_object(id->variables["for"]));
  function action;

  if(!(int)id->variables->for_id)
    action = sc->new;
  else
    action = sc->update;
  
  if(id->variables->__return)
  {
    response->redirect_temp(action, ({}), (["old_data": id->variables->old_data, "id": id->variables["for_id"]]));
    return;
  }
  
  werror("var: %O\n", id->variables);
    
  // why do we assume that a value must be selected? why can't it be empty?
  /*
  if(id->variables->__select && !(arrayp(id->variables->selected_id) || (int)id->variables->selected_id))
  {
    response->flash("msg", "No " + make_nice(model_object->instance_name) + " selected.");
    response->redirect_temp(action_url(pick_one, ({}), (["old_data": id->variables->old_data, "selected_field": id->variables->selected_field, 
                "for": id->variables["for"], "for_id": id->variables["for_id"]])));
    return;
  }
  */
  
  id->variables->id = id->variables->for_id;
  m_delete(id->variables, "for_id");
  m_delete(id->variables, "for");

  response->redirect_temp(action_url(action, ({}), id->variables));
}

public void pick_many(Request id, Response response, Fins.Template.View v, mixed ... args)
{
  if(!(id->variables->for && id->variables->for_id && id->variables->selected_field))
  {
    response->set_data("error: invalid data.");
    return;	
  }

  id->variables->old_data = Protocols.HTTP.percent_encode(MIME.encode_base64(encode_value(id->variables), 1));

  v->add("type", make_nice(lower_case(model_object->instance_name_plural)));
  v->add("nicefor", make_nice(id->variables["for"]));

  array x = model_context->find_all(model_component);
  v->add("values", x);

  v->add("old_data", id->variables->old_data);
  v->add("selected_field", id->variables->selected_field);
  v->add("for", id->variables["for"]);
  v->add("for_id", id->variables["for_id"]);  
}

public void pick_one(Request id, Response response, Fins.Template.View v, mixed ... args)
{
  if(!(id->variables->for && id->variables->for_id && id->variables->selected_field))
  {
    response->set_data("error: invalid data.");
    return;	
  }

  id->variables->old_data = Protocols.HTTP.percent_encode(MIME.encode_base64(encode_value(id->variables), 1));

  v->add("type", make_nice(model_object->instance_name));
  v->add("nicefor", make_nice(id->variables["for"]));

  array x = model_context->find_all(model_component);

  if((int)id->variables["for_id"])
  {
    object obj = model_context->find_by_id(id->variables["for"], (int)id->variables["for_id"]);
    v->add("previous_selection", (obj?obj[id->variables->selected_field]->get_id():0));
  }
  
  v->add("values", x);
  v->add("old_data", id->variables->old_data);
  v->add("selected_field", id->variables->selected_field);
  v->add("for", id->variables["for"]);
  v->add("for_id", id->variables["for_id"]);  
}

public void delete(Request id, Response response, Fins.Template.View v, mixed ... args)
{
  if(!id->variables->id)
  {
    response->set_data("error: invalid data.");
    return;	
  }

  v->add("type", make_nice(model_object->instance_name));

  object item = model_context->find_by_id(model_object, (int)id->variables->id);

  if(!item)
  {
    response->set_data(make_nice(model_object->instance_name) + " not found.");
    return;
  }
  
  v->add("item", item);

  if(id->variables->___delete)
    response->redirect_temp(action_url(dodelete, 0, (["id": id->variables->id])));
  else if(id->variables->___cancel)
  {
    response->flash("msg", "Delete cancelled.");
    response->redirect_temp(action_url(list));
  }
}

public void dodelete(Request id, Response response, Fins.Template.View v, mixed ... args)
{
  if(!id->variables->id)
  {
    response->set_data("error: invalid data.");
    return;	
  }
  
  object item = model_context->find_by_id(model_object, (int)id->variables->id);

  if(!item)
  {
    response->set_data(make_nice(model_object->instance_name) + " not found.");
    return;
  }
  
  item->delete();

  response->flash("msg", make_nice(model_object->instance_name) + " deleted successfully.");
  response->redirect_temp(action_url(list));

}


string describe(object o, string key, mixed value)
{
  string rv = "";
werror("describe(%O, %O, %O)\n", o, key, value);
    if(stringp(value) || intp(value))
      rv += value; 
    else if(arrayp(value))
      rv += describe_array(o, key, value);
    else if(objectp(value))
      rv += describe_object(o, key, value);

  return rv;
}

public void decode_old_values(mapping variables, mapping orig)
{
  if(variables->old_data)
  {
    string in = MIME.decode_base64(variables->old_data);
    mixed inv = decode_value(in);
    decode_from_form(inv, orig);
    if(variables->selected_field)
    {
      if(arrayp(variables->selected_id))
      {
        array x = allocate(sizeof(variables->selected_id));
        foreach(variables->selected_id;int i; mixed v)
         x[i] = model_context->find_by_id(model_object->fields[variables->selected_field]->otherobject, (int)v);
        orig[variables->selected_field] = x;
      }
      else
      {
        orig[variables->selected_field] = model_context->find_by_id(model_object->fields[variables->selected_field]->otherobject, (int)variables->selected_id);
      }
    }
  }

}

public void update(Fins.Request request, Fins.Response response, Fins.Template.View v, mixed ... args)
{
//  object v = get_view(update, update_template_string);

  v->add("type", lower_case(model_object->instance_name_plural));
  
  mapping orig = ([]);

  object item = model_context->find_by_id(model_object, (int)request->variables->id);

  if(!item)
  {
    response->set_data(make_nice(model_object->instance_name) + " not found.");
    return;
  }

  decode_old_values(request->variables, orig);

  // FIXME: this could go very wrong...
  string orig_data = encode_orig_data(item->get_atomic());

  array fields = ({});

  foreach(model_object->field_order; int key; mixed value)
  {	
    if(model_object->primary_key->name != value)
    {
      fields += ({value});
    }
  }

  v->add("item", item);
  v->add("orig", orig);
  v->add("field_order", model_object->field_order);
  v->add("orig_data", orig_data);
  v->add("fields", fields*",");

  response->set_view(v);
}

static mixed make_encodable_val(mixed val)
{
  mixed rval;

  if(objectp(val))
  {
    if(rval = val["_id"])
      return rval;
    else if(val->_cast) return (string)val;
    else if(val->format_utc) return val->format_utc();
  }

  else return val;
}

static string encode_orig_data(mapping orig)
{
  mapping val = ([]);

  foreach(val; string k; mixed v)
  {
    val[k] = make_encodable_val(v);
  }

  MIME.encode_base64(encode_value(val), 1); 

}

public void doupdate(Fins.Request request, Fins.Response response, Fins.Template.View vt, mixed ... args)
{
mixed e;

e=catch{
  if(!request->variables->id || !(request->variables->___save || request->variables->___cancel))
  {
	response->set_data("error: invalid data");
	return;
  }

  if(request->variables->___cancel)
  {
	response->flash("msg", "editing canceled");
    response->redirect_temp(action_url(list));
    return;	
  }

  object item = model_context->find_by_id(model_object, (int)request->variables->id);

  if(!item)
  {
    response->set_data(make_nice(model_object->instance_name) + " not found.");
    return;
  }

  response->redirect_temp(action_url(display, 0, (["id": request->variables->id])));
    
  mapping v = ([]);

  array inds = indices(request->variables);

  int should_update;
  foreach(request->variables->___fields/","; int ind; string field)
  {
     // we don't worry about the primary key.
     if(item->master_object->get_primary_key()->name == field) continue; 

	array elements = glob( "_" + field + "__*", inds);
	
	if(sizeof(elements))
	{
		foreach(elements;; string e)
		{
			if(request->variables["__old_value_" + e] != request->variables[e])
			{
				werror("field: %O\n", item->master_object->fields[field]);
				Log.debug("Scaffold: " + field + " in " + model_object->instance_name + " changed.");
		    if(item->master_object->fields[field]->is_shadow && !model_object->fields[field]->get_renderer()->from_form) continue;
				should_update = 1;
				mapping x = ([]);
				foreach(elements;; string e)
				  x[e[(sizeof(field)+3)..]] = request->variables[e];
  			mixed field_vals = model_object->fields[field]->get_renderer()->from_form(x, model_object->fields[field], item);
				  v[field] = field_vals;
				break;
			}
		}
	}
        else	
 	  if(request->variables["__old_value_" + field] != request->variables[field])
	  {
		werror("field: %O\n", item->master_object->fields[field]);
		Log.debug("Scaffold: " + field + " in " + model_object->instance_name + " changed.");
        if(item->master_object->fields[field]->is_shadow) continue;
		should_update = 1;
		v[field] = request->variables[field];
	  }
  }

  mixed err;

  if(should_update)
  {
    err = catch(item->set_atomic(v));
    if(err)
      response->flash("msg", "Error: " + err[0]);
    else
      response->flash("msg", "Update successful.");
  }
  else
    response->flash("msg", "Nothing to update.");

};
if(e)
  Log.exception("error", e);
}

static void decode_from_form(mapping variables, mapping v)
{
  array inds = indices(variables);

  foreach((variables->___fields || "")/","; int ind; string field)
  {
     // we don't worry about the primary key.
     if(model_object->get_primary_key()->name == field) continue;

        array elements = glob( "_" + field + "__*", inds);

        if(sizeof(elements))
        {
                foreach(elements;; string e)
                {
                  object field_object;
                  mapping x = ([]);
                  foreach(elements;; string e)
                    x[e[(sizeof(field)+3)..]] = variables[e];
                  field_object = model_object->fields[field];
                  werror("decoding %O from %O with value %O = %O\n", field, model_object, x, field_object);
          				v[field] = field_object->get_renderer()->from_form(x, field_object);
//                  v[field] = model_object->fields[field]->from_form(x);
                  break;
                }
        }
        else
          {
                v[field] = variables[field];
          }
  }
}

public void donew(Fins.Request request, Fins.Response response, Fins.Template.View vt, mixed ... args)
{
mixed e;
mapping v = ([]);
e=catch{
  if(!(request->variables->___save || request->variables->___cancel))
  {
	response->set_data("error: invalid data");
	return;
  }

  if(request->variables->___cancel)
  {
	response->flash("msg", "create canceled.");
    response->redirect_temp(action_url(list));
    return;	
  }

  object item = model_context->new(model_object);

  if(!item)
  {
    response->set_data(make_nice(model_object->instance_name) + " not found.");
    return;
  }

 // werror("%O\n", request->variables);
  m_delete(request->variables, "___save");

  array inds = indices(request->variables);

  int should_update;
//werror("inds: %O\n", inds);

  foreach(request->variables->___fields/","; int ind; string field)
  {
     // we don't worry about the primary key.
     if(item->master_object->get_primary_key()->name == field) continue; 

	array elements = glob( "_" + field + "__*", inds);
	werror ("elements: %O\n", elements);
	if(sizeof(elements) > 0)
	{
		foreach(elements;; string e)
		{
				Log.debug("Scaffold: " + field + " in " + model_object->instance_name + " changed.");
				werror("%O\n", item->master_object->fields[field]);
		    if(item->master_object->fields[field]->is_shadow && !model_object->fields[field]->get_renderer()->from_form) continue;
				should_update = 1;
				mapping x = ([]);
				foreach(elements;; string e)
				  x[e[(sizeof(field)+3)..]] = request->variables[e];
				mixed field_val = model_object->fields[field]->get_renderer()->from_form(x, model_object->fields[field], item);
				
				v[field] = field_val;
				break;
		}
	}
        else	
	  {
			werror("%O\n", item->master_object->fields[field]);
	        if(item->master_object->fields[field]->is_shadow) continue;
		Log.debug("Scaffold: " + field + " in " + model_object->instance_name + " changed.");
		should_update = 1;
		v[field] = request->variables[field];
	  }
  }
werror("setting: %O\n", v);
  mixed e;
//item->set_atomic(v);
  e = catch(item->set_atomic(v));
  if(e)
  { 
    Log.exception("Record creation failed.", e); 
    response->flash("msg", "Record creation failed: " + (Error.mkerror(e)->message()));
    response->redirect_temp(action_url(new, 0, v));
  }

  else
  {
    response->redirect_temp(action_url(list));
    response->flash("msg", "create successful.");
  }
};
if(e)
  Log.exception("error", e);
}


public void new(Fins.Request request, Fins.Response response, Fins.Template.View v, mixed ... args)
{
  array fields = ({});
  mapping orig = ([]);

//  object v = get_view(new, new_template_string);

  v->add("type", lower_case(model_object->instance_name_plural));

  object no = model_context->new(model_object->instance_name);

  decode_old_values(request->variables, orig);

  foreach(model_object->field_order; int key; mixed value)
 {	
	if(model_object->fields[value]->is_primary_key) continue;
	fields += ({value});
  }

  v->add("field_order", model_object->field_order);
  v->add("orig", orig);
  v->add("item", no);
  v->add("fields", fields*",");

  response->set_view(v);
}

static string make_nice(string v)
{
  return Tools.Language.Inflect.humanize(v);
}

string make_value_describer(string key, void|mixed value, void|object o)
{
	werror("make_value_describer(%O=%O)\n", key, value);
	  if(model_object->fields[key]->is_shadow && !model_object->fields[key]->get_renderer()->get_display_string)
	  {
	werror("no editor for shadow field " + key + "\n");
		if(o)
		  return describe(o, key, value);   
	    else return "";
	  }
	  else if(model_object->primary_key->name == key)
	  {
	    if(o) return (string)value;	
	    else return 0;
	  }
	  else if(model_object->fields[key]->get_renderer()->get_display_string)
	  {
	    if(o)
	      return model_object->fields[key]->get_renderer()->get_display_string(value, model_object->fields[key], o);
 		  else return model_object->fields[key]->get_renderer()->get_display_string(0, model_object->fields[key]);
	//  else if(stringp(value) || intp(value))
	//    return "<input type=\"text\" name=\"" + key + "\" value=\"" + value + "\">";
	  }
	  else 
	    return sprintf("%O", value);
	
}

string make_value_editor(string key, void|mixed value, void|object o)
{
werror("make_value_editor(%O=%O)\n", key, model_object->fields[key]);
  if(model_object->fields[key]->is_shadow && !model_object->fields[key]->get_renderer()->get_editor_string)
  {
werror("no editor for shadow field " + key + "\n");
	if(o)
	  return describe(o, key, value);   
    else return "";
  }
  else if(model_object->primary_key->name == key)
  {
    if(o) return "<input type=\"hidden\" name=\"id\" value=\"" + value + "\">" + value;	
    else return 0;
  }
  else if(model_object->fields[key]->get_renderer()->get_editor_string)
  {
    if(o)
      return model_object->fields[key]->get_renderer()->get_editor_string(value, model_object->fields[key], o);
	else return model_object->fields[key]->get_renderer()->get_editor_string(0, model_object->fields[key]);
//  else if(stringp(value) || intp(value))
//    return "<input type=\"text\" name=\"" + key + "\" value=\"" + value + "\">";
  }
  else 
    return sprintf("%O", value);
}

string describe_array(object o, string key, object a)
{
  array x = ({});
  foreach(a;; object v)
  {
    if(objectp(v))
      x += ({ describe_object(0, key, v) });
    else x+= ({ (string)v });
  }

  return x * ", ";
}

string describe_object(object m, string key, object o)
{
  string rv;
  if(o->master_object && o->master_object->alternate_key)
  {
    string link;
    link = get_view_url(o);
    if(link) link = " <a href=\"" + link + "\">view</a>";
    else link = "";
    return (string)o->describe()
     + link;
  }
  else if(o->_cast)
    return  (string)o;
  else if(m && (rv = m->describe_value(key, o)))
    return rv;
  else return sprintf("%O", o);
}

string get_view_url(object o)
{
  object controller = model_context->repository->get_scaffold_controller("html", o->master_object);  
  if(!controller)
    return 0;

  string url;

  url = action_url(controller->display, 0, (["id": o[o->master_object->primary_key->name]]));  

  return url;
}
