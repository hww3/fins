inherit .Relationship;

import Tools.Logging;

mixed default_value = .Undefined;
int null = 0;
.Criteria criteria;

object renderer = Fins.Helpers.Renderers.KeyRenderer(); // ScaffoldRenderer

static void create(string _name, string _myfield, string _otherobject, void|.Criteria _criteria, void|int _null)
{
  name = _name;
  field_name = _myfield;
  otherobject = _otherobject;
  criteria = _criteria;
  null = _null;
}

// value should be the value of the link field, which is the primary key of the 
// other object we're about to get.
mixed decode(string value, void|.DataObjectInstance i)
{
//	werror("INSTANCE: %O\n", i);
	object ot = context->repository->get_object(otherobject);
	mixed val = ot->primary_key->decode(value);
	if(val)
      return i->context->find_by_id(ot, val);
    else return 0;
}

// value should be a dataobject instance of the type we're looking to set.
string encode(int|.DataObjectInstance value, void|.DataObjectInstance i)
{
//Log.debug("%O(%O, %O)", Tools.Function.this_function(), value, i);
  value = validate(value);
//Log.debug("%O(): validate() returns %O", Tools.Function.this_function(), value);

  if(intp(value)) return (string)value;

  if(value->is_new_object())
  {
    value->save();
  }
    
  return (string)value->get_id();
}


mixed validate(mixed value, void|.DataObjectInstance i)
{
//Log.debug("%O(%O, %O)", Tools.Function.this_function(), value, i);

   mixed o;

   if(intp(value)) return value;

   if(value == .Undefined && !null && default_value == .Undefined)
   {
     throw(Error.Generic("Field " + name + " cannot be null; no default value specified.\n"));
   }

   else if (value == .Undefined && !null && default_value!= .Undefined)
   {
     return default_value;
   }

   else if (value == .Undefined)
   {
     return .Undefined;
   }
   else if(objectp(value) && value->get_type() != otherobject)
     throw(Error.Generic(sprintf("Got %O object, expected %s.\n", value->get_value(), otherobject)));
   else if(stringp(value) && ((int)value || value == "0"))
   {
     return (int)value;
   }
   else if(stringp(value) && (o = context->repository->get_object(otherobject)) && o->alternate_key)
   {
      return context->find_by_alternate(otherobject, value);
   }
   else if(!objectp(value))
     throw(Error.Generic(sprintf("Got a non-object value instead of expected %s.\n", otherobject)));

   return value;
}



  
