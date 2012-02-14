//! This relationship object is used to model a many-to-many relationship between two
//! data types using a third "join" table containing the primary keys of the two types 
//! to be mapped.

inherit .Relationship;

constant type="Multi Key";

object parent;
string otherkey; 
int null = 0;
int is_shadow=1;
int unique;
.Criteria criteria;
string mappingtable;
string my_mappingfield;
string other_mappingfield;

static void create(object p, string _name, string _mappingtable, string _my_mappingfield, 
	string _other_mappingfield, string _otherobject, string _otherkey, .Criteria|void _criteria)
{
  name = _name;
  mappingtable = _mappingtable;
  my_mappingfield = _my_mappingfield;
  other_mappingfield = _other_mappingfield;
  otherobject = _otherobject;
  otherkey = _otherkey;
  criteria = _criteria;
  parent = p;
}

// value will be null in a foreign key, as we're not in an object where that's a real field. 
mixed decode(string value, void|.DataObjectInstance i) 
{ 
    return .MultiObjectArray(this, i, i->context);
}

// value should be a dataobject instance of the type we're looking to set.
string encode(.DataObjectInstance value, void|.DataObjectInstance i)
{
  return "";
}


mixed validate(mixed value, void|.DataObjectInstance i)
{
  return 0;
}

string make_qualifier(mixed value)
{
  string v = "";

  if(arrayp(value))
  {
    error("We don't do arrays yet!\n");	
  }
  else
  {
     v = mappingtable + "." + other_mappingfield + "=" + value->get_id() + " AND " + 
	      parent->table_name + "." + parent->primary_key->field_name + "=" + mappingtable + "." + my_mappingfield ;	
  }

  return v;
}

string get(mixed name, mixed value, .DataObjectInstance i)
{
	string v = "";

   if(value)
   {
     v = mappingtable + "." + my_mappingfield + "=" + name->get_id() + " AND " + 
	    context->repository->get_object(otherobject)->table_name + "." + 
	    otherkey + "=" + mappingtable + "." + other_mappingfield ;
   }
   return v;
}

string get_table(string name, string value, .DataObjectInstance i)
{
	return mappingtable;
}


string get_editor_string(mixed|void value, void|.DataObjectInstance i)
{
  string desc = "";
  object obj;
werror("obther object: %O\n", otherobject);
 obj =  context->repository->get_object(otherobject);
  object sc = context->repository->get_scaffold_controller("html", obj);
werror("value for keyreference is %O, scaffold controller is %O\n", value, sc);

  if(!value) desc = "not set";
  else if(objectp(value) && value->describe)
    desc = value->describe();
  else desc = sprintf("%O", value);

  if(sc && sc->display)
   desc = sprintf("<input type=\"hidden\" name=\"_%s__id\" value=\"%d\"><a href=\"%s\">%s</a>", 
    name, value?value->get_id():0, context->app->url_for_action(sc->display, ({}), (["id": value?value->get_id():0 ])),  
    desc);

//werror("other object is %O\n", otherobject);
  if(sc && sc->pick_one)
  {
    desc += sprintf(" <a href='javascript:fire_select(%O)'>select</a>",
      context->app->url_for_action(sc->pick_one, ({}), (["selected_field": name, "for": i->master_object->instance_name,"for_id": i->get_id()]))
     );
  }
//werror("returning %O\n", desc);
  return desc;
}
  
optional mixed from_form(mapping value, void|.DataObjectInstance i)
{ 
  return context->find(otherobject, value->id);
}
  

