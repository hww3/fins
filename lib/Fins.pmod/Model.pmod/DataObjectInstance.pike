.DataObject master_object;
.DataModelContext context;

//! this is an actual instance containing model-domain data for a given data type. 
//! typically, this means that an object of this type represents a row of data
//! in your database.
//! 
//! fields are accessed or set using the `[] and `[]= operators; thus if your data-mapping
//! contained a field called "full_name," you would access it in this way:
//!
//! myobject["full_name"]
//!
//! data for an object may be cached so that subsequent requests to find an object by
//! id (primary key) or alternate key do not generate database requests. to alter this
//! behavior, see @[Fins.Model.DataObject.set_cachable].

string object_type;
multiset fields_set = (<>);

// storage location of changed values local to this instance
mapping object_data = ([]);

// the local storage location of the global cache for data values of this id.
// this is shared by all objects of this id, regardless of connection, except those within
// a transaction session.
mapping object_data_cache = ([]); 

// if non-zero, the id of the current transaction. not currently used.
int transaction_id;

static mixed key_value = UNDEFINED;
int new_object = 0;
int saved = 0;
int initialized;

Iterator _get_iterator()
{
  return .DataObjectIterator(this);
}

string _sprintf(mixed ... args)
{
  return object_type + "(" + get_descriptor() + "/" + key_value + ")";
}

mixed cast(string t)
{
  switch(t)
  {
    case "mapping":
      return get_atomic();
    case "string":
       return describe();
     // return get_alt() || (get_descriptor()+ "/" + get_id);
    default:
     throw(Error.Generic("Unable to cast DataObjectInstance to " + t + ".\n"));
  }
}

string render_json(multiset|object filter_fields)
{
  mapping m = render_mapping(filter_fields);
  return Tools.JSON.serialize(m, objectp(filter_fields)?filter_fields:0);
}

mapping render_mapping(multiset|object filter_fields)
{
  int shells = 0;
  mapping m; // the gathered object
  mixed e; // error object
  mixed fx; // the filter multiset or function.

  if(!objectp(filter_fields) || !filter_fields->parse_depth_okay())
  {
    shells = 1;
  }
  catch
  {
    if(shells)
      m = get_atomic(1);
    else
      m = get_atomic();
    if(multisetp(filter_fields))
      m-=filter_fields;
    else if(objectp(filter_fields))
    {
      fx = filter_fields->get_filter_for_program(object_program(this));
      if(multisetp(fx))
        m-=fx;
      if(!functionp(fx)) fx = 0;
    }

    foreach(m; string index; mixed val)
    {
      // if the filter function exists, use it to determine fields to be skipped.
      if(fx && fx(index, val)) m_delete(m, index);
      if(objectp(val) && functionp(val->format_http))
        m[index] = val->format_http();  
    }
    if(shells)
    {     
      string url;
      object ctrl = context->repository->get_scaffold_controller("json", master_object);
      if(ctrl) 
      {
        url = context->app->url_for_action(ctrl);
        m["$ref"] = url + "/:" + get_id();
      }
    }
  };

  if(e) throw(e);  
  return m;
}


string describe_value(string key, mixed value)
{
  return master_object->describe_value(key, value, this);
}

string describe()
{
  return get_descriptor();
}

string get_descriptor()
{
  if(master_object && master_object->describe)
    return master_object->describe(this);
  else return ("huh? " + get_id());
}

int _is_type(string type)
{
   if(type=="mapping")
     return 1;
   return 0;
}

//!
void set_initialized(int i)
{
  initialized = i;
}

//!
int is_initialized()
{
  return initialized;
}

//!
string get_type()
{
  return object_type;
}

//! set the default operator to use when querying on multiple fields.   
//!  valid values are @[Fins.Model.OPER_AND] and @[Fins.Model.OPER_OR].
void set_operator(int o)
{
  master_object->set_operator(o);
}

//!
static void create(mixed|void id, object _object_type, .DataModelContext context)
{
//  werror("create(%O, %O, %O)\n", id, _object_type, context);

  if(!_object_type)
    throw(Fins.Errors.ModelError("No Data Object Definition passed to create()\n"));

  if(!context)
  {
	throw(Fins.Errors.ModelError("Attempting to create object without context.\n"));
  }

  if(objectp(_object_type)) 
  {
    master_object = _object_type;
     object_type = _object_type->instance_name;
  }

  this->context = context;

  if(!id)
  {
    set_new_object(1);
  }

  else if(objectp(id)) // assume it's a XML Node object
  {
    set_new_object(1);
    decode_xml_node(id);
  }
  else
  {
    master_object->load(context, id, this);
//    master_object->add_ref(this);
  }


}

//! performs validation on object and returns an error object if any errors occur.
//! 
//! @seealso
//! @[Fins.Model.DataObject.valid]
Fins.Errors.Validation valid()
{
  return master_object->valid(this);
}

//! if data is suspected to be stale (such as for long-lived objects where the underlying
//! database records might have been changed), this call will force the data to be refreshed
//! from the database.
void refresh()
{
   master_object->load(context, key_value, this, 1);
}

//! create a new object of this type. 
//!
//! @note
//!   no record is created in the underlying database for this object until @[save] is called.
object(this_program) new(void|.DataModelContext c)
{
   program p = this_program;
   object new_object = p(UNDEFINED, c||context);  

   new_object->set_new_object(1);
   return   new_object;
}

//!
object(this_program) find_by_alternate(mixed id, void|.DataModelContext c)
{
    program p = object_program(this);
    object new_object = p(UNDEFINED, c||context);  
    master_object->load_alternate(c, id, new_object);
    return new_object;
}

//! an id must be a non-zero integer.
object(this_program) find_by_id(int id, void|.DataModelContext c)
{
   program p = object_program(this);
   object new_object = p(UNDEFINED, c||context);  

    master_object->load(c||context, id, new_object);
//    master_object->add_ref(new_object);
     return new_object;
}

//!
array(object(this_program)) find_all(void|.DataModelContext c)
{
  return find(([]), c||context);
}

//!
array(object(this_program)) find(mapping qualifiers, .Criteria|void criteria, void|.DataModelContext c)
{
  return master_object->find(c||context, qualifiers, criteria, this);
}

//! delete this object from the database.
//!
//! @param force
//!  if true, any objects linked by relationships will
//!  be deleted as well. this can result in a large number of records being deleted,
//!  so care should be exercised when using this option.
int delete(void|int force, void|.DataModelContext c)
{
   return master_object->delete(c||context, force, this);
}

//!
int save(int|void no_validation, void|.DataModelContext c)
{
	//werror("%O", c||context);
   return master_object->save(c||context, no_validation, this);
}

//!
int set_atomic(mapping values, int|void no_validation, void|.DataModelContext c)
{
   return master_object->set_atomic(c||context, values, no_validation, this);
}

//!
int set(string name, mixed value, int|void no_validation, void|.DataModelContext c)
{
   return master_object->set(c||context, name, value, no_validation, this);
}

//!
mixed get_atomic(int(0..1)|void norecurse, void|.DataModelContext c)
{
  if(norecurse)
  { 
    mapping mp = (["_objecttype": master_object->instance_name, "id": get_id()]);
    if(master_object->alternate_key)
    {
      string akn = master_object->alternate_key->name;
      if(master_object->alternate_key) mp[akn] = get(akn);
    }
    return mp;
  }
  else
    return master_object->get_atomic(norecurse, c||context, this);
}

//!
mixed get(string name, void|.DataModelContext c)
{
   return master_object->get(c||context, name, this);
}

//!
void set_id(mixed id)
{ 
  key_value = id;   
}

//!
mixed get_id()
{
   return key_value;
}

//!
mixed get_alt()
{
  if(master_object->alternate_key)
    return get(master_object->alternate_key->name);

  else return 0;

}

//!
void add(string field, mixed value)
{
  master_object->add(field, value, this);	
}

//!
void set_new_object(int(0..1) i)
{
   new_object = i;
}

//!
void set_saved(int(0..1) i)
{
   saved = i;
}

//!
int is_saved()
{
   return saved;
}

//!
int is_new_object()
{ 
   return new_object;
}

string render_xml(multiset filter_fields)
{
  object root = Parser.XML.Tree.SimpleRootNode();

  root->add_child(Parser.XML.Tree.SimpleNode(Parser.XML.Tree.XML_HEADER, "xml", (["version": "1.0"]), ""));
  root->add_child(render_xml_node(filter_fields));

  return root->render_xml();
}

void decode_xml_node(Parser.XML.Tree.Node node)
{
  if(node->get_full_name() != master_object->instance_name)
  {
    throw(Error.Generic("Cannot decode XML Node: element name is incorrect."));
  }
  array x = node->get_children();
  array refs = ({});
  foreach(x;; object n)
  {
    if(n->get_node_type() != Parser.XML.Tree.XML_ELEMENT) continue;
    string field = n->get_full_name();
    mapping attr = n->get_attributes();

   if(attr["key"] && lower_case(attr["key"]) == "true")
   {
     // TODO make this not be "primary key as int" specific.
     if(master_object->primary_key->name != field)
       throw(Error.Generic("Cannot decode XML Node: declared key field is not our key field.\n"));

      string text = (n->get_children()->get_text())*"";
//      werror("dealing with " + field + "=<" + text + ">\n");
      set(field, (int)text);
   }
   else if(master_object->fields[field]) 
    {
      mixed text = (n->get_children()->get_text())*"";
      if(attr["datatype"])
      {
        switch(attr["datatype"])
        {
          case "int":
            text = (int)text;
            break;
          case "float":
            text = (float)text;
            break;
        }
      }

      if(attr["reference_type"] && attr["referred_type"])
      {
        refs += ({ n });
      }
      else
      {  
//      werror("dealing with " + field + "=<" + text + ">\n");
        set(field, text);
      }
    }
  }

  // finally, let's deal with the refs.
  foreach(refs;; object n)
    decode_ref(n);

}

void decode_ref(object n)
{
  object obj;
  string field = n->get_full_name();
  mapping attr = n->get_attributes();

  mixed text = (n->get_children()->get_text())*"";
  if(attr["datatype"])
  {
    switch(attr["datatype"])
    {
      case "int":
        text = (int)text;
        break;
      case "float":
        text = (float)text;
        break;
    }
  }

  // short circuit self refs
  if(attr["referred_type"] == master_object->instance_name && this[attr["reference_type"]] == text )
  {
    set(field, get_id());
    return;
  }
  array r = context->_find(attr["referred_type"], ([attr["reference_type"]: text]));
  if(sizeof(r) > 1)
  {
    throw(Error.Generic("decode_ref(): too many results for single key value\n"));
  }
  else if(!sizeof(r))
  {
    throw(Error.Generic("decode_ref(): no results for single key value, " + attr["referred_type"] + "." + attr["reference_type"] + "=" + text + ", mine is \n")); 
  }
  set(field, r[0]);
}

//! renders the attributes of the current object as an XML node object. This method does not perform a 
//! recursive or deep traversion of any attached objects linked from this object
//!
//! @param filter_fields
//!   a list of fields that should be excluded from the resulting output.
//!  
//! @param absolute_mode
//!   if true, object ids and references will be stored in the output as they are; otherwise
//!   auto-numbering and references by alternate id and object type will be used
//!
//! @note 
//!   absolute_mode will render an exact replica on import, however cannot be reliably used
//!   in a model with pre-existing objects.
Parser.XML.Tree.SimpleNode render_xml_node(multiset filter_fields, int(0..1)absolute_mode)
{
  object obj = Parser.XML.Tree.SimpleNode(Parser.XML.Tree.XML_ELEMENT, master_object->instance_name, ([]), "");
  if(!filter_fields) filter_fields = (<>);

  if(!filter_fields) filter_fields = (<>);

  foreach(_indices();; string i)
  {
werror("considering %O\n", i);
	string indval = "";
	mapping attrs = ([]);
	if(filter_fields[i]) continue;

	if(master_object->fields[i]->is_shadow) continue;	
	if(master_object->primary_key == master_object->fields[i])
		attrs["key"] = "true";
	mixed m = get(i);
	if(objectp(m))
	{
		// we don't need to include foreign keys, as they're not stored here.
		if(Program.inherits(object_program(master_object->fields[i]), Fins.Model.InverseForeignKeyReference))
		  continue;

		else if(Program.implements(object_program(m), Fins.Model.DataObjectInstance))
		{
			// TODO
			// perhaps we should check to see if there's an alternate id field and use that instead.
			attrs["referred_type"] = m->master_object->instance_name;
			attrs["reference_type"] = (m->master_object->alternate_key ?
										m->master_object->alternate_key->name :
										m->master_object->primary_key->name);
			
			indval = m->master_object->alternate_key?(string)m->get_alt():(string)m->get_id();
		}

		else if(Program.implements(object_program(m), master()->resolv("Fins.Model.MultiObjectArray")))
		{
werror("have a many-to-many reference: %O.\n", i);
			attrs["reference_type"] = "many-to-many";
			object val = Parser.XML.Tree.SimpleNode(Parser.XML.Tree.XML_ELEMENT, i, attrs, "");

			foreach(m;;object f)
			{
				object ref = Parser.XML.Tree.SimpleNode(Parser.XML.Tree.XML_ELEMENT, "reference", ([ "reference_type": (f->master_object->alternate_key?f->master_object->alternate_key->name:f->master_object->primary_key->name), "referred_type": f->master_object->instance_name]), "");
				ref->add_child(Parser.XML.Tree.SimpleNode(Parser.XML.Tree.XML_TEXT, "", ([]), (string)f->get_id()));
				val->add_child(ref);
			}
			obj->add_child(val);
			continue;
		}
                else if(master_object->fields[i]->encode_xml)
                {
                  indval = master_object->fields[i]->encode_xml(m, this);
                }
	}
	else if(arrayp(m))
	{
	}
	else if(mappingp(m))
	{
		
	}
	else if(multisetp(m))
	{
		
	}
	else
	{
	  	indval = (string)m;
	}
	
//	attrs->type = master_object->fields[i]->type;
	object val = Parser.XML.Tree.SimpleNode(Parser.XML.Tree.XML_ELEMENT, i, attrs, "");
	val->add_child( Parser.XML.Tree.SimpleNode(Parser.XML.Tree.XML_TEXT, "", ([]), indval));
	obj->add_child(val);
  }

  return obj;
}

//!
mixed `[]=(mixed i, mixed v)
{
  if(!v && zero_type(v) == 1)
  {
    return get(i);
  }

  else return set(i, v);
}

//!
mixed `[](mixed arg)
{
  return get(arg);
}

//!
array _indices()
{
  array a = ({});

  foreach(master_object->fields; string name; .Field f)
  {
    a+=({name});
  }

  return a;
}

//!
array _values()
{
  array a = ({});

  foreach(master_object->fields; string name; .Field f)
  {
    a+=({get(name)});
  }

  return a;
}

//!
int `==(mixed a)
{
  if(objectp(a) && (object_program(this) == object_program(a)) && (a->get_id() == this->get_id()) && (a->get_type() == this->get_type()))
    return 1;
  else return 0;
}

/*
static void destroy()
{
  if(master_object) 
    master_object->sub_ref(this);
  else
  {
    werror("ERROR! No Master object on instance destroy!\n");
  }
}
*/
