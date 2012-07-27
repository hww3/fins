.Field field;
object otherobject;
object parentobject;
array contents;
int changed;
.DataModelContext context;

static void create(.Field f, object parent, void|.DataModelContext c)
{
//  Tools.Logging.Log.debug("%O(%O, %O, %O)", Tools.Function.this_function(), f, parent, c);
  field = f; 
  parentobject = parent;
  context = c || parent->context;
//werror("Creating objectArray: %O\n", field->otherobject);
  otherobject = context->repository["get_object"](field->otherobject);
  if(!otherobject)
    throw(Error.Generic("unable to find object type '" + field->otherobject + "' in model.\n"));
  changed = 1;
}

static mixed cast(string rt)
{
  switch(rt)
  {
    case "array":
      if(changed)
        get_contents();
        return contents;
      break;
    case "string":
      if(changed)
        get_contents();
        return contents->get_descriptor()*", ";
      break;
    default:
      throw(Error.Generic("Cannot cast ObjectArray to " + rt + ".\n"));
      break;
  }

}

Iterator _get_iterator()
{
  if(changed)
    get_contents();

  return Array.Iterator(contents);
}

static array _values()
{
  if(changed)
    get_contents();

    return contents;
}

static array _indices()
{
  if(changed)
    get_contents();

    return indices(contents);
}

static int _sizeof()
{
  if(changed)
    get_contents();
  
  return sizeof(contents);
}

int(0..1) _is_type(string t)
{
  int v=0;

  switch(t)
  {
    case "array":
      v = 1;
      break;
  }

  return v;
}

void get_contents()
{

//  werror("%O\n", mkmapping(indices(field), values(field)));
  contents = context->old_find(otherobject, ([ field->otherkey :
                                  (int) parentobject->get_id()]), field->criteria);

  changed = 0;
}

mixed `+(mixed arg)
{

  // do we have the right kind of object?
  if(!objectp(arg) || !arg->master_object || arg->master_object != otherobject)
  {
    throw(Error.Generic("Wrong kind of object: got " + sprintf("%O", arg) 
+ ", expected DataObjectInstance.\n"));
  }

  // ok, we have the right kind of object, now we need to get the id.
  int id = parentobject->get_id();  

  arg[field->otherkey] = id;
  changed = 1;
  return this;
}

// args is used for function signature compatibility with DataObjectInstance.
mixed get_atomic(int(0..1)|void norecurse, mixed ... args)
{
  int sv = _sizeof();
  array v = allocate(sv);

  for(int i = 0; i < sv; i++)
  {
    v[i] = this[i]->get_atomic(norecurse);
  }

  return v;
}

.DataObjectInstance get_element(int e)
{
  if(changed)
    get_contents();

  if(contents[e])
    return contents[e];
  else
    throw(Error.Generic("Error indexing the array with element " + e + ".\n"));
     
}

mixed `[]=(int i, mixed v)
{
  if(v == UNDEFINED)
  {
return 0;
//    return get(i);
  }
return 0;

 // else return set(i, v);
}

mixed `[](int arg)
{
  return get_element(arg);

}

