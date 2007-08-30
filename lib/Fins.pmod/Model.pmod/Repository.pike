import Tools.Logging;

mapping(string:.DataObject) object_definitions = ([]);
mapping(program:.DataObject) program_definitions = ([]);
mapping(string:program) instance_definitions = ([]);
static mapping(object:object) scaffold_controllers = ([]);
static object model_module;
static object object_module;

object Objects = objects(this);

class objects(object repository)
{
  mixed `[](mixed a)
  {
    if(instance_definitions[a]) return instance_definitions[a];
    else throw(Error.Generic("unknown object type " + a + ".\n"));
  }
}

//!
array old_find(string|program|object ot, mapping qualifiers, void|.Criteria criteria)
{
   object o;
   if(!objectp(ot))
     o = get_object(ot);
   else
     o = ot;
   if(!o) throw(Error.Generic("Object type " + ot + " does not exist.\n"));
   return get_instance(o->instance_name)(UNDEFINED)->find(qualifiers, criteria);
}

//!
object get_model_module()
{ 
  return model_module;
}

//!
object get_object_module()
{
  return object_module;
}

//! called in Fins.Loader.
void set_model_module(object o)
{
  model_module = o;
}

//! called in Fins.Loader.
void set_object_module(object o)
{
  object_module = o;
}

//!
.DataObject get_object(string|program name)
{
  if(programp(name))
   return program_definitions[name];
  else
   return object_definitions[name];
}

//!
program get_instance(string name)
{
   return instance_definitions[name];
}

//!
void add_object_type(.DataObject t, program i)
{
   Log.debug("adding type def: %O", t->instance_name);
   object_definitions[t->instance_name] = t;
   program_definitions[object_program(t)] = t;
   instance_definitions[t->instance_name] = i;
}

//!
object get_scaffold_controller(object model_component)
{
  return scaffold_controllers[model_component];
}

//!
void set_scaffold_controller(object model_component, object controller)
{
   scaffold_controllers[model_component] = controller;
}

//!
void find_all(string|object ot)
{
  old_find(ot, ([]));
}

// find() is in module.pmod.

//!
.DataObjectInstance find_by_id(string|program|object ot, int id)
{
   object o;
   if(!objectp(ot))
     o = get_object(ot);
   else
     o = ot;
   if(!o) throw(Error.Generic("Object type " + ot + " does not exist.\n"));
   return  get_instance(o->instance_name)(id);
}

//!
.DataObjectInstance find_by_alternate(string|program|object ot, mixed id)
{
   object o;
   if(!objectp(ot))
     o = get_object(ot);
   else
     o = ot;
   if(!o) throw(Error.Generic("Object type " + ot + " does not exist.\n"));
   if(!o->alternate_key)
     throw(Error.Generic("Object type " + ot + " does not have an alternate key.\n"));

   return old_find(o, ([o->alternate_key->name: id]))[0];
}

//!
.DataObjectInstance new(string|program|object ot)
{
   object o;
   if(!objectp(ot))
     o = get_object(ot);
   else
     o = ot;
  if(!o) throw(Error.Generic("Object type " + ot + " does not exist.\n"));
  return  get_instance(o->instance_name)(UNDEFINED);
}
