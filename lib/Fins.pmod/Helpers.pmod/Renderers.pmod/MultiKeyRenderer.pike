inherit .Renderer;


string get_editor_string(mixed|void value, Fins.Model.Field field, void|Fins.Model.DataObjectInstance i)
{
  string desc = "";
  object obj;
  int linked = 0;
werror("obther object: %O\n", field->otherobject);
 obj =  field->context->repository->get_object(field->otherobject);
  object sc = field->context->repository->get_scaffold_controller("html", obj);
werror("value for keyreference is %O, scaffold controller is %O\n", value, sc);

  if(!value || !sizeof(value)) 
  {
    werror("not set\n");
    desc = "not set";
  }
  else if(objectp(value))
  {
    werror("making link list\n");
    if(sc && sc->display)
    {
      array ids = ({});
      array links = ({});
      foreach((array)value; int key; mixed value)
      {
        ids += ({value->get_id()});
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
      field->context->app->url_for_action(sc->pick_many, ({}), (["selected_field": field->name, "for": i->master_object->instance_name,"for_id": i->get_id()]))
     );
  }
//werror("returning %O\n", desc);
  return desc;
}
  
optional mixed from_form(mapping value, Fins.Model.Field field, void|Fins.Model.DataObjectInstance i)
{ 
  return field->context->find(field->otherobject, value->id);
}
  
