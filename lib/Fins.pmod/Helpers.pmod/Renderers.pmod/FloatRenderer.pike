inherit .Renderer;

string get_editor_string(void|string value, Fins.Model.Field field, void|Fins.Model.DataObjectInstance i)
{
  if(!value && zero_type(value)) value = "0.0";

  if(i)
  {
    return ("<input type=\"hidden\" name=\"__old_value_" + field->name + "\" value=\"" + value + "\">" "<input type=\"text\" size=\"" + field->len + "\" name=\"" + field->name + "\" value = \"" + value + "\">");
  }
  else
  {
    return ("<input type=\"text\" size=\"" + field->len + "\" name=\"" + field->name + "\" value = \"\">"); 
  }
}

mixed from_form(mapping value, Fins.Model.Field field, void|Fins.Model.DataObjectInstance i)
{
  werror("value: %O\n", value->value);
  return (float)value->value;
}
