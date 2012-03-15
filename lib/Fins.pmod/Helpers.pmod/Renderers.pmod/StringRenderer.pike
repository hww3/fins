inherit .Renderer;

string get_editor_string(void|string value, Fins.Model.Field field, void|Fins.Model.DataObjectInstance i)
{
  if(!value && zero_type(value)) value = "";

  if(i)
  {
    if(field->len < 60) return ("<input type=\"hidden\" name=\"__old_value_" + field->name +
                         "\" value=\"" + value + "\">" "<input type=\"text\" size=\"" + field->len +
                         "\" name=\"" + field->name + "\" value = \"" + value + "\">");
    else return ("<textarea name=\"" + field->name  + "\" rows=\"5\" cols=\"80\">" + value + "</textarea>"
                    "<input type=\"hidden\" name=\"__old_value_" + field->name + "\" value=\"" + value + "\">" );
  }
  else
  {
    if(field->len < 60) return ("<input type=\"text\" size=\"" + field->len + "\" name=\"" + field->name + "\" value = \"\">");
    else return ("<textarea name=\"" + field->name  + "\" rows=\"5\" cols=\"80\"></textarea>");

  }
}


