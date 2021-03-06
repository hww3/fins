inherit .Renderer;


string get_editor_string(mixed|void value, object/*Fins.Model.Field*/ field, void|object/*Fins.Model.DataObjectInstance*/ i)
{
  string desc = "";
  object obj;
  int linked = 0;
  array ids = ({});
  
werror("obther object: %O\n", field->otherobject);
 obj =  field->context->repository->get_object(field->otherobject);
  object sc = field->context->repository->get_scaffold_controller("html", obj);
werror("value for keyreference is %O, scaffold controller is %O\n", value, sc);

  if(!value || !sizeof(value)) 
  {
    werror("not set\n");
    desc = "not set";
  }

  else if(arrayp(value) || (objectp(value) && Program.implements(object_program(value), Fins.Model.ObjectArray)))
  {
    werror("making link list\n");
    if(sc && sc->display)
    {
      array links = ({});
      foreach(value; int key; mixed value)
      {
        werror("VALUE: %O\n", value);
        
        if(!value) desc = "not set";
        else if(objectp(value) && value->describe)
          desc = value->describe();
        else desc = sprintf("%O", value);
        
        string id = (string)value->get_id();
        ids += ({id});
        links += ({sprintf("<input type=\"hidden\" name=\"_%s__id\" value=\"%s\"><a href=\"%s\">%s</a>", field->name, id, field->context->app->url_for_action(sc->display, ({}), (["id": value?value->get_id():0 ])),  desc)});
      }
       
      desc = links * ", ";
      linked = 1;
    }
  }
  else if(objectp(value))
  {
    werror("making link list\n");
    if(sc && sc->display)
    {
      array links = ({});
      {
        werror("VALUE: %O\n", value);
        
        if(!value) desc = "not set";
        else if(objectp(value) && value->describe)
          desc = value->describe();
        else desc = sprintf("%O", value);
        
        ids += ({(string)value->get_id()});
        links += ({sprintf("<a href=\"%s\">%s</a>", field->context->app->url_for_action(sc->display, ({}), (["id": value?value->get_id():0 ])),  desc)});
      }
       
      desc = sprintf("<input type=\"hidden\" name=\"_%s__id\" value=\"%s\">%s", 
       field->name, ids*",", links * ", ");
      
      linked = 1;
    }
  }
  else desc = "AIEEE!";

/*
  if(!linked)
  {
    if(sc && sc->display)
     desc = sprintf("<input type=\"hidden\" name=\"_%s__id\" value=\"%d\"><a href=\"%s\">%s</a>", 
      name, (objectp(value)&&value->get_id)?value->get_id():0, context->app->url_for_action(sc->display, ({}), (["id": (objectp(value)&&value->get_id)?value->get_id():0 ])),  
      desc);
  }
*/

  if(sc && sc->pick_many)
  {
    desc += sprintf(" <a href='javascript:fire_select(%O)'>select</a>",
      field->context->app->url_for_action(sc->pick_many, ({}), (["selected_id": ids, "selected_field": field->name, "for": i->master_object->instance_name,"for_id": i->get_id()]))
     );
  }
//werror("returning %O\n", desc);
  return desc;
}
  
optional mixed from_form(mapping value, object/*Fins.Model.Field*/ field, void|object /*Fins.Model.DataObjectInstance*/ i)
{ 
  werror("value: %O\n", value);
  if(arrayp(value->id))
  {
    array x = allocate(sizeof(value->id));
    foreach(value->id;int i; mixed v)
    x[i] = field->context->find_by_id(field->otherobject, (int)v);

   return x;
  }
  
  return field->context->find_by_id(field->otherobject, (int)value->id);
}
  
