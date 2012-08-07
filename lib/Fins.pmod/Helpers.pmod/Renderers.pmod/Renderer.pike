//! Renderer defines the interface used by @[Fins.ScaffoldController] for rendering of fields in a 
//! @[Fins.Model.DataObject]. All Model datatypes get a default renderer appropriate for that type
//! of data, however this may be changed on a case-by-case basis (for details, see 
//! @[Fins.Model.DataObject.set_renderer].)

//!
optional mixed from_form(mapping value, Fins.Model.Field field, void|object/*Fins.Model.DataObjectInstance*/ i);

//!
string get_editor_string(mixed|void value, Fins.Model.Field field, void|object/*Fins.Model.DataObjectInstance*/ i)
{
  return (string)value;
}

//!
string get_display_string(void|mixed value, Fins.Model.Field field, void|object/*Fins.Model.DataObjectInstance*/ i)
{
  return (string)value;
}


//! 
string get_form_field_name(Fins.Model.Field field, string|void part)
{
  if(part)
    return "_" + field->name + "_" + part;
  else return field->name;
}
