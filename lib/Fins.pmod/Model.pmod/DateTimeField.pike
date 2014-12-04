inherit .DateField;

//! a field representing a day and time in a database.
//! values that may be passed include a calendar object,
//! an integer (which will be interpreted as a unix timestamp)
//! or a string, which will be parsed for a workable date format
//! @note 
//!  that this is not a recommended way, as it's slow and 
//!  the parsing accuracy is not guaranteed.

constant type = "DateTime";
int includetime = 1;
program unit_program = Calendar.Second;
function unit_parse = Calendar.ISO.dwim_time;
string output_unit_format = "%Y-%M-%D %h:%m:%s";

Fins.Helpers.Renderers.Renderer renderer = master()->resolv("Fins.Helpers.Renderers.DateTimeRenderer")(); // ScaffoldRenderer

function encode_get = _encode_get;

string _encode_get(mixed value, void|object/*.DataObjectInstance*/ i)
{
  value = validate_get(value);

  if(value == .Undefined)
  {
    return "NULL";
  }

  if(stringp(value)) return sprintf("'%s'", value);
  return "'" + value->format_time() + "'";
}

string encode(mixed value, void|object/*.DataObjectInstance*/ i)
{
  value = validate(value, i);

  if(value == .Undefined)
  {
    return "NULL";
  }

  if(stringp(value)) return sprintf("'%s'", value);
  return "'" + value->set_timezone(timezone_offset)->format_time() + "'";
}

string describe(mixed v, void|object/*.DataObjectInstance*/ i)
{
  return v->format_time();
}

