inherit .Relationship;

constant type="Foreign Key";

string otherobject; 
string otherkey; 
mixed default_value = .Undefined;
int null = 0;
int is_shadow=1;

static void create(string _name, string _otherobject, string _otherkey)
{
  name = _name;
  otherobject = _otherobject;
  otherkey = _otherkey;
}

// value will be null in a foreign key, as we're not in an object where that's a real field.
mixed decode(string value, void|.DataObjectInstance i)
{
  return .DataObjectInstance(UNDEFINED, otherobject)->find(([ otherkey :
                                  (int) i->get_id()]));
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

