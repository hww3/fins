inherit .Relationship;

import Tools.Logging;

mixed default_value = .Undefined;
int null = 0;
.Criteria criteria;

//!  A field type that represents some other object identified that object's unique id
//!  stored in this field. 
//! 
//!  @example
//!  An object representing a "book" may have a single owner. 
//!  That relationship could be modeled using a KeyReference that links that book to its 
//!  owner (perhaps a "user" object) via a field on the book that contains the owner's id.
//!
//!  @seealso
//!   @[Fins.Model.DataObject.belongs_to()]


Fins.Helpers.Renderers.Renderer renderer = Fins.Helpers.Renderers.KeyRenderer(); // ScaffoldRenderer

//! @param _name
//!   the name this field will be accessible via (such as "User")
//! @param _myfield
//!   the name of the database field that represents this reference (such as "user_id")
//! @param _otherobject
//!   the name of the object type this link represents (such as "User")
//! @param _criteria
//!   not used in this class
//! @param _null
//!   if set, an object can be saved without providing a value for this field
protected void create(string _name, string _myfield, string _otherobject, void|.Criteria _criteria, void|int _null)
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



  
