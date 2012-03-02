inherit .Renderer;


string get_editor_string(mixed|void value, Fins.Model.Field field, void|Fins.Model.DataObjectInstance i)
{
  string desc = "";
  object obj;
werror("obther object: %O\n", field->otherobject);
 obj =  field->context->repository->get_object(field->otherobject);
  object sc = field->context->repository->get_scaffold_controller("html", obj);
werror("value for keyreference is %O, scaffold controller is %O\n", value, sc);

  if(!value) desc = "not set";
  else if(objectp(value) && value->describe)
    desc = value->describe();
  else desc = sprintf("%O", value);

  if(sc && sc->display)
   desc = sprintf("<input type=\"hidden\" name=\"_%s__id\" value=\"%d\"><a href=\"%s\">%s</a>", 
    field->name, value?value->get_id():0, field->context->app->url_for_action(sc->display, ({}), (["id": value?value->get_id():0 ])),  
    desc);

  if(sc && sc->pick_one)
  {
    desc += sprintf(" <a href='javascript:fire_select(%O)'>select</a>",
      field->context->app->url_for_action(sc->pick_one, ({}), (["selected_field": field->name, "for": i->master_object->instance_name,"for_id": i->get_id()]))
     );
  }
//werror("returning %O\n", desc);
  return desc;
}
  
optional mixed from_form(mapping value, Fins.Model.Field field, void|Fins.Model.DataObjectInstance i)
{ 
  return field->context->find_by_id(field->otherobject, (int)value->id);
}
