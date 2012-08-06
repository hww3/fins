inherit .Field;

int len;
int null;
mixed default_value;
string name;

object renderer = master()->resolv("Fins.Helpers.Renderers.IntRenderer")(); // ScaffoldRenderer

constant type = "Integer";

void create(string _name, int _len, int(0..1) _null, int|void _default)
{
   int na = query_num_arg();
//if(_name=="digested") werror("digested: %O, %O\n", na, _default);
   name = _name;
   len = _len;
   null = _null;
   if(na == 4) 
     default_value = _default;
   else default_value = .Undefined;

   ::create();
}

int decode(string value, void|.DataObjectInstance i)
{
   return (int)value;
}

string encode(mixed value, void|.DataObjectInstance i)
{
  value = validate(value, i);

  if(value == .Undefined)
  {
    return "NULL";
  }

  return (string)value;
}

mixed validate(mixed value, void|.DataObjectInstance i)
{
   if(value == .Undefined && !null && default_value == .Undefined)
   {
     throw(Error.Generic("Field " + name + " cannot be null; no default value specified.\n"));
   }

   else if (value == .Undefined && !null && default_value!= .Undefined)
   {
     return default_value;
   }

   else if (value == .Undefined || value == "")
   {
     return .Undefined;
   }

  else if(stringp(value))
  {
    int v;
    if(!sscanf(value, "%d", v))
      throw(Error.Generic("Cannot set " + name + " using " + basetype(value) + ".\n"));
    else return v;
  }

  else if(!intp(value))
   {
      throw(Error.Generic("Cannot set " + name + " using " + basetype(value) + ".\n"));
   }
   
   return value;
}
