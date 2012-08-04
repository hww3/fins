import Fins;
inherit FinsBase;

object log = Tools.Logging.get_logger("model");

static void create(Fins.Application a)
{
  ::create(a);
  load_model();
}

//! configures any models defined in the application's configuration file. this method is automatically called
//! by the constructor.
//!
//! an application normally contains a default model, which is specified in the "model" section of the application's
//! configuration file. additional model definitions can be specified in the configuration file by adding sections
//! whose name is in the form of "model_x" where x is some unique identifier.
//!
//! valid configuration values for a model definition include "id", "datasource", "definition_module" and "debug". 
//! The "datasource" attribute is mandatory for all model definitions; "definition_module" and "id" are mandatory for 
//! all definitions other than the default, and all other attributes are optional for all model definitions.
//!
//! when each model is loaded, a database connection will be made and all registered data types will be configured,
//! either manually or automatically using database reflection. Additionally the default context for each model 
//! definition will be registered in @[Fins.DataSources] using the value of its "id" attribute as the key.
//!
//! in addition to being available from Fins.Model, the default model is also available from @[Fins.Datasources] by its
//! "id" attribute, or if no "id" is specified, using the key "_default".
//!
//! @example
//!    // get a context for the default model
//!    Fins.Model.DataModelContext ctx = Fins.DataSources._default;
//!    // get a context for the model whose configuration specifies an "id" of "my_additional_model"
//!    Fins.Model.DataModelContext ctx2 = Fins.DataSources.my_additional_model;
//!
void load_model()
{
  object context = configure_context(config["model"], 1);

  Fins.Model.set_context("_default", context);

  if(config["model"]["id"])
    Fins.Model.set_context(config["model"]["id"], context);     

  foreach(glob("model_*", config->get_sections());; string md)
  {
	 log->info("configuring model id <" + config[md]["id"] + "> specified in config secion " + md);
     object ctx = configure_context(config[md], 0);
     Fins.Model.set_context(config[md]["id"], ctx);
   }
}

object get_context(mapping config_section)
{
	return master()->resolv("Fins.Model.DataModelContext")();
}

object configure_context(mapping config_section, int is_default)
{
  Fins.Model.Repository repository;
  string definition_module;
  object o;

  object defaults = Fins.Helpers.Defaults;
  catch(defaults = (object)"defaults");

  string url = config_section["datasource"];
  if(!url) throw(Error.Generic("Unable to load model: no datasource defined.\n"));

  if(is_default) definition_module = (config_section->definition_module || config->module_root);
  else definition_module = config_section->definition_module;

  if(!definition_module)
  {
    throw(Error.Generic("No model definition module specified. Cannot configure model."));
  }

  object d = get_context(config_section);
  d->context_id = config_section["id"] || "_default";

  repository = d->get_repository();
  string mn = definition_module + "." + defaults->data_mapping_module_name;
  if(o = master()->resolv(mn))
  {
    repository->set_model_module(o);
    log->debug("Model %s using %s for data mapping objects.", d->context_id, mn); 
  }
  else
    log->warn("Unable to find model data mapping definition module %s.", mn); 

  mn = definition_module + "." + defaults->data_instance_module_name;
  if(o = master()->resolv(mn))
  {
    repository->set_object_module(o);
    log->debug("Model %s using %s for data object instances.", d->context_id, mn); 
  }
  else
    log->warn("Unable to find model data object instance module %s.", mn); 

 d->set_url(url);
 d->debug = (int)config_section["debug"];
 d->repository = repository;
 d->cache = cache;
 d->app = app;
 d->model = this;
 d->initialize();

 repository->set_default_context(d);

 d->register_types();
  return d;
}
