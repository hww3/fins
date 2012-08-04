inherit .DataObjectInstance;

//! provides direct data object instance access

//! This is the name of the class that contains the data mapping definition for this type. For example, User or Comment.
string type_name = "unknown";

//! This is the id of the model this type is associated with; the default model id is "_default".
string context_name = "_default";

//!
static void create(int|Parser.XML.Tree.Node|void identifier, void|.DataModelContext c)
{
  if(!c)
	  c = Fins.Model.get_context(context_name);
  object o = c->repository->get_object(type_name);
  if(!o)
  {
    throw(Error.Generic("Model configuration error: object type " + type_name + " does not have a data mapping.\n"));
  }
  ::create(identifier, o, c);
}
