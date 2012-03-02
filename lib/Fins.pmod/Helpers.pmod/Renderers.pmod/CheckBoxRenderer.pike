inherit .BooleanRenderer;

string get_editor_string(void|mixed value, Fins.Model.Field field, void|Fins.Model.DataObjectInstance i)
{
  string rv = "";
  rv += ("<input type=\"hidden\" name=\"__old_value_" + field->name + "\" value=\"" + value + "\">");
    rv += "<input type=\"checkbox\" name=\"" + field->name + "\" value=\"1\"" + (((int)value)?" CHECKED":"") + ">\n";
  return rv;

}
