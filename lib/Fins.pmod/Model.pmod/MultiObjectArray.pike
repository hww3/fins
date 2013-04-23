inherit .ObjectArray;

int clearfirst;

private array deferred_adds = ({});

void get_contents()
{
  contents = context->old_find(otherobject, ([ field : parentobject]));

  changed = 0;
}

void save(object instance)
{
  werror("%O->save()\n", this);
  foreach(deferred_adds;; mixed id)
  {
    werror("committing %O\n", id);
    commit_add(instance, id);
  }
}

void set_atomic(array x)
{
  clearfirst = 1;

  if(!arrayp(x))
    x = ({x});
  
  foreach(x;; mixed v) add(v);
}

mixed `+(mixed arg)
{
  return add(arg);
}

mixed add(mixed arg)
{
werror("`+(%O)\n", arg);

// werror("otherobject: %O\n", otherobject);

  // do we have the right kind of object?
  if(!objectp(arg) || !arg->master_object || arg->master_object != otherobject)
  {
    throw(Error.Generic("Wrong kind of object: got " + sprintf("%O", arg) + ", expected " + otherobject->instance_name + ".\n"));
  }

  // ok, we have the right kind of object, now we need to get the id.
  int id = parentobject->get_id();  

  if(!id)
  {
    deferred_adds += ({arg->get_id()});
  }
  else
  {
    commit_add(arg, arg->get_id());
  }
  /*
  werror("INSERT INTO " + field->mappingtable + 
	 "(" + field->my_mappingfield + "," + field->other_mappingfield + ") VALUES(" + 
	 parentobject->master_object->primary_key->encode(parentobject->get_id()) + "," + 
	 arg->master_object->primary_key->encode(arg->get_id()) + ")");
  */
  changed = 1;
  return this;
}

mixed `-(mixed arg)
{
//werror("`-(%O)\n", arg);
  // do we have the right kind of object?
  if(!objectp(arg) || !arg->master_object || arg->master_object != otherobject)
  {
    throw(Error.Generic("Wrong kind of object: got " + sprintf("%O", arg) + ", expected DataObjectInstance.\n"));
  }

  // ok, we have the right kind of object, now we need to get the id.
  int id = parentobject->get_id();  

  arg->context->execute("DELETE FROM " + field->mappingtable + 
	 " WHERE " + field->my_mappingfield + "=" + 
	 parentobject->master_object->primary_key->encode(parentobject->get_id()) + " AND " + 
    field->other_mappingfield + "=" + 
	 arg->master_object->primary_key->encode(arg->get_id()));

  /*
  werror("DELETE FROM " + field->mappingtable + 
	 " WHERE " + field->my_mappingfield + "=" + 
	 parentobject->master_object->primary_key->encode(parentobject->get_id()) + " AND " + 
    field->other_mappingfield + "=" + 
	 arg->master_object->primary_key->encode(arg->get_id()));
*/
  changed = 1;
  return this;
}

void commit_add(object arg, mixed id)
{
  if(clearfirst)
  {
    arg->context->execute("DELETE FROM " + field->mappingtable + " WHERE " + field->my_mappingfield + "="
      + parentobject->master_object->primary_key->encode(parentobject->get_id()));
    clearfirst = 0;
  }
  arg->context->execute("INSERT INTO " + field->mappingtable + 
    "(" + field->my_mappingfield + "," + field->other_mappingfield + ") VALUES(" + 
    parentobject->master_object->primary_key->encode(parentobject->get_id()) + "," + 
    arg->master_object->primary_key->encode(id) + ")");
}
