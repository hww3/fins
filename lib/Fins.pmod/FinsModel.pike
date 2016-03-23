import Fins;
inherit FinsBase;

object log = Tools.Logging.get_logger("model");

//! normally, fields that represent references between objects will be created using the referenced
//! type's proper object name using mixed case (such as "User"). If this field is set to true, the
//! reference will be created using lower case (such as "user").
int lower_case_link_names = 0;

protected void create(Fins.Application a)
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
//! "id" attribute, or if no "id" is specified, using the key  @[Fins.Model.DEFAULT_MODEL], or "_default".
//!
//! @example
//!    // get a context for the default model
//!    Fins.Model.DataModelContext ctx = Fins.DataSources._default;
//!    // get a context for the model whose configuration specifies an "id" of "my_additional_model"
//!    Fins.Model.DataModelContext ctx2 = Fins.DataSources.my_additional_model;
//!    // alternately, you can use get_context():
//!    Fins.Model.DataModelContext ctx2 = Fins.Model.get_context("my_additional_model");


void load_model()
{
  object context = get_context(config["model"], Fins.Model.DEFAULT_MODEL);

  Fins.Model.set_context(Fins.Model.DEFAULT_MODEL, context);
  log->warn("added context!\n");
  if(config["model"]["id"])
    Fins.Model.set_context(config["model"]["id"], context);     

  foreach(glob("model_*", config->get_sections());; string md)
  {
	  log->info("configuring model id <" + config[md]["id"] + "> specified in config secion " + md);
    object ctx = get_context(config[md], config[md]["id"]);
    Fins.Model.set_context(config[md]["id"], ctx);
  }
}

object get_context(mapping config_section, string id)
{
  object c = master()->resolv("Fins.Model.SqlDataModelContext")(config_section, id);

  c->config = config;
  c->app = app;
  c->model = this;
  
  // TODO: fix this properly. 
  c->lower_case_link_names = lower_case_link_names;
  c->initialize();

  // this exists primarily for the migration tools, which should run before model objects are
  // configured. that way, any database objects will be up-to-date before the model tries to
  // configure itself via reflection.
  //
  // a migration that needs to access model-mapped objects can call initialize_types() itself
  // before doing so.
  if(!all_constants()["__defer_full_startup"])
    c->register_types();

  return c;
}
