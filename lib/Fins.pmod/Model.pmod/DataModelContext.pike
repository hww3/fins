//!
int debug = 0;

object log = Tools.Logging.get_logger("fins.model.datamodelcontext");

mapping model_config;

//! contains the finder object. see also @[Fins.Model.find_provider]
object find;

//!
object config;

//!
object repository;

//!
object app;

//!
object cache;

//!
object model;

string context_id;

int id = random(time());

int is_default;

string url;

constant context_type = "DataModelContext";

protected void create(mapping|object config_section, string|void id)
{
  if(objectp(config_section))
  {
    did_clone(config_section);
  }
//  werror("config: %O\n", config_section);
  
  model_config = config_section;
  context_id = id || config_section["id"] || Fins.Model.DEFAULT_MODEL;

  if(!context_id)
    Tools.throw(Error.Generic, "model config section does not contain an id field.");

  string url = config_section["datasource"];
  if(!url) throw(Error.Generic("Unable to load model: no datasource defined.\n"));

  set_url(url);

  is_default = (context_id == Fins.Model.DEFAULT_MODEL);

  debug = (int)config_section["debug"];        
}

string _sprintf(mixed ... args)
{
  return context_type + "(" + host_info() + ")";
}

string host_info()
{
  Tools.throw(Fins.Errors.AbstractClass);
}

object get_repository()
{
  object repo = master()->resolv("Fins.Model.Repository")();
  string definition_module;
  object o;

  // get the object that contains the list of default names to use for finding model objects.
  object defaults = Fins.Helpers.Defaults;
  catch(defaults = (object)"defaults");

  // The default definition container module is either defined in the model config section,
  // or it's the name of the app, as calculated by the Configuration object.
  if(is_default) 
  {
    definition_module = (model_config->definition_module || (config?config->module_root:0));
  }
  else 
  {
    definition_module = model_config->definition_module;
  }

  if(!definition_module)
  {
    Tools.throw(Error.Generic, "No model definition module specified. Cannot configure model (default=%O, config=%O).", is_default, config);
  }

  string mn = definition_module + "." + defaults->data_mapping_module_name;
  if(o = master()->resolv(mn))
  {
    repo->set_model_module(o);
    log->debug("Model %s using %s for data mapping objects.", context_id, mn); 
  }
  else
    log->warn("Unable to find model data mapping definition module %s.", mn); 

  mn = definition_module + "." + defaults->data_instance_module_name;
  if(o = master()->resolv(mn))
  {
    repo->set_object_module(o);
    log->debug("Model %s using %s for data object instances.", context_id, mn); 
  }
  else
    log->warn("Unable to find model data object instance module %s.", mn); 

  repo->set_default_context(this);

  return repo;
}

int initialize()
{
  find = .find_provider(this);
  if(app && app->cache)
    cache = app->cache;
  else
    cache = Fins.FinsCache();
}

array execute(mixed ... args)
{
  Tools.throw(Fins.Errors.AbstractClass);
}

//! copy this DataModelContext object and opens a new sql connection.
object clone()
{
	object d = object_program(this)(this);
	return d;
}

void did_clone(object c)
{
	repository = c->repository;
	config = c->config;
	app = c->app;
	cache = c->cache;
	model = c->model;
	debug = c->debug;
	model_config = c->model_config;
	context_id = c->context_id;
	is_default = c->is_default;

  initialize();
}

void set_url(string u)
{
	url = u;
}

//! not recommended for current use
//! @deprecated
function(string|program|object,mapping,void|object/*.Criteria*/:array) _find = old_find;

//! not recommended for current use
//! @deprecated
array old_find(string|program|object ot, mapping qualifiers, void|object/*.Criteria*/ criteria)
{
   object o;
   if(!objectp(ot))
     o = repository->get_object(ot);
   else
     o = ot;
   if(!o) throw(Error.Generic("Object type " + ot + " does not exist.\n"));

   return repository->get_instance(o->instance_name)(UNDEFINED)->find(qualifiers, criteria, this);
}

//! not recommended for current use
//! @deprecated
array find_all(string|object ot)
{

  return old_find(ot, ([]));
}

// find() is in module.pmod.

//! not recommended for current use
//! @deprecated
.DataObjectInstance find_by_id(string|program|object ot, int id)
{
   object o;
   if(!objectp(ot))
     o = repository->get_object(ot);
   else
     o = ot;
   if(!o) throw(Error.Generic("Object type " + ot + " does not exist.\n"));
   return  repository->get_instance(o->instance_name)(id, this);
}

//! not recommended for current use
//! @deprecated
array find_by_query(string|program|object ot, string query)
{
   object o;
   if(!objectp(ot))
     o = repository->get_object(ot);
   else
     o = ot;
   if(!o) throw(Error.Generic("Object type " + ot + " does not exist.\n"));

   return old_find(o, (["0": Fins.Model.Criteria(query)]));
}

//! not recommended for current use
//! @deprecated
object /*.DataObjectInstance*/ find_by_alternate(string|program|object ot, mixed id)
{
   object o;
   if(!objectp(ot))
     o = repository->get_object(ot);
   else
     o = ot;
   if(!o) throw(Error.Generic("Object type " + ot + " does not exist.\n"));
   if(!o->alternate_key)
     throw(Error.Generic("Object type " + ot + " does not have an alternate key.\n"));

   return repository->get_instance(o->instance_name)(UNDEFINED)->find_by_alternate(id, this);
}

//! not recommended for current use
//! @deprecated
object /*.DataObjectInstance*/ new(string|program|object ot)
{
   object o;
   if(!objectp(ot))
     o = repository->get_object(ot);
   else
     o = ot;
  if(!o) throw(Error.Generic("Object type " + ot + " does not exist.\n"));
  return  repository->get_instance(o->instance_name)(UNDEFINED, this);
}

void register_types()
{
  repository = get_repository();

  if(!repository->get_object_module())
  {
    log->warn("Using automatic model registration, but no datatype_definition_module set. Skipping.");
    return 0;
  }
  object mm = repository->get_model_module();

  log->debug("Data mapping module: %O", mm);
  foreach(mkmapping(indices(mm), values(mm));string name; program definition)
  { 
    register_type(name, definition);
  }
}

void register_type(string name, program definition)
{
  object repository = get_repository();
  object im = repository->get_object_module();
  object d = definition(this);
  program di;
  if(im && im[name])
  {
    di = im[name];
    if(di && !di->type_name) {/*werror("%O\n", di);di->type_name = n;*/}
  }
  else
  {
    throw(Fins.Errors.ModelError("No Data Instance class defined for data type " + name + " in model id " + context_id + "."));
  }
  log->info("Registering data type %s", d->instance_name);
  repository->add_object_type(d, di);
}
