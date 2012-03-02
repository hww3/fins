inherit .Renderer;

constant YES_NO = 1;
constant Y_N = 2;
constant ON_OFF = 3;
constant TRUE_FALSE = 4;

int display_type = 1;

array display_types = ({
  ({"0", "1"}),
  ({"No", "Yes"}),
  ({"N", "Y"}),
  ({"Off", "On"}),
  ({"True", "False"})
});

string get_display_string(void|mixed value, Fins.Model.Field field, void|Fins.Model.DataObjectInstance i)
{
  return display_types[display_type][(int)value];
}

string get_editor_string(void|mixed value, Fins.Model.Field field, void|Fins.Model.DataObjectInstance i)
{
  string rv = "";
  rv += ("<input type=\"hidden\" name=\"__old_value_" + field->name + "\" value=\"" + value + "\">" "<select name=\"" + field->name + "\">");
  foreach(display_types[display_type]; int x; string dv)
    rv += "<option value=\"" + x + "\"" + (((int)value == x)?" SELECTED":"") + ">" + dv + "\n";
  rv += "</select>\n";
  return rv;
  
}
