string name;
string field_name;
object context; // DataModelContext
constant type = "";
int is_shadow = 0;

Fins.Helpers.Renderers.Renderer renderer;// = Fins.Helpers.Renderers.Renderer(); // ScaffoldRenderer

object get_renderer()
{
  return renderer;
}

void set_renderer(object _renderer)
{
  renderer = _renderer;
}
mixed validate(mixed value, void|object i)
{
  return value;
}

mixed decode(string value, void|object i)
{
   return value;
}

string encode(mixed value, void|object i);

string translate_fieldname()
{
   return lower_case(name);
}

void set_context(object c)
{
   context = c;
}

protected void create()
{
   field_name = translate_fieldname();
}

string make_qualifier(mixed v)
{
  Tools.throw(Fins.Errors.AbstractClass);
}

string describe(mixed v, void|object i)
{
  return encode(v, i);
}
