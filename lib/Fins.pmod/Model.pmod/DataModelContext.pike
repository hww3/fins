//!
int debug = 0;

object log = Tools.Logging.get_logger("fins.model.datamodelcontext");

mapping builder = ([ "possible_links" : ({}), "belongs_to" : ({}), "has_many": ({}), "has_many_many": ({}), "has_many_index": ({}) ]);

//! contains the finder object. see also @[Fins.Model.find_provider]
object find;

//!
object repository;

//!
object cache;

//! 
object personality;

//!
object app;

//!
object model;

//!
mapping xa_storage = ([]);

//!
Sql.Sql sql;
string sql_url;

string context_id;

int in_xa = 0;

int id = random(time());

string _sprintf(mixed ... args)
{
  return "DataModelContext(" + sql->host_info() + ")";
}

array query(mixed ... args)
{
	return sql->query(@args);
}

string quote(string s)
{
   return sql->quote(s);
}

string quote_binary(string s)
{
  return personality->quote_binary(s);
}

string unquote_binary(string s)
{
  return personality->unquote_binary(s);
}

string type()
{
  string t;
  catch(t = model->config["model"]["personality"]);
  if(t) 
    return t;
  else 
    return lower_case(Standards.URI(model->config["model"]["datasource"])->scheme);
}

program get_personality()
{
  return .Personality[lower_case(type())];
}

int initialize()
{
  program p = get_personality();
  if(!p) throw(Error.Generic("Unknown database type. No personality.\n"));

  personality = p(this);
  sql = personality->initialize();
  find = .find_provider(this);
}

array execute(mixed ... args)
{
  mixed x;
  mixed err;
  err = catch(x = sql->query(@args));
  
  if(err)
  {
    int r = sql->ping();
    if(r != 1)
      throw(err);
    else
    {      
      log->info("Re-initializing context due to reconnect.");
      sql = personality->initialize();
      if(in_xa)
      {
        throw(Error.Generic("Transaction aborted due to database reconnect.\n"));
      }
      x = sql->query(@args);
    }
  }
  
	return x;
}

//! copy this DataModelContext object and opens a new sql connection.
object clone()
{
	object d = object_program(this)();
	d->repository = repository;
	d->cache = cache;
	d->app = app;
	d->model = model;
	
	// don't need to call the setter here, right?
	d->sql_url = sql_url;
	d->initialize();
	d->debug = debug;
	return d;
}

void set_url(string url)
{
	sql_url = url;
}

//!
int begin_transaction()
{
  if(!personality->transaction_supported())
	throw(Error.Generic("Transactions are not supported by this database engine.\n"));

  if(in_xa)
	throw(Error.Generic("Already in a transaction.\n"));

  personality->begin_transaction();
  in_xa = 1;
}

//!  TODO: look for uncommitted data in objects and save before committing
int commit_transaction()
{
  if(!personality->transaction_supported())
	throw(Error.Generic("Transactions are not supported by this database engine.\n"));

  if(!in_xa)
	throw(Error.Generic("Not currently in a transaction.\n"));

  personality->commit_transaction();
  xa_storage = ([]);
  in_xa = 0;
}

//!  TODO: look for uncommitted data in objects and throw away
int rollback_transaction()
{
  if(!personality->transaction_supported())
	throw(Error.Generic("Transactions are not supported by this database engine.\n"));

  if(!in_xa)
	throw(Error.Generic("Not currently in a transaction.\n"));

  personality->rollback_transaction();
  in_xa = 0;
}

//!
int in_transaction()
{
  return in_xa;
}

//! not recommended for current use
//! @deprecated
function(string|program|object,mapping,void|.Criteria:array) _find = old_find;

//! not recommended for current use
//! @deprecated
array old_find(string|program|object ot, mapping qualifiers, void|.Criteria criteria)
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
.DataObjectInstance find_by_alternate(string|program|object ot, mixed id)
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
.DataObjectInstance new(string|program|object ot)
{
   object o;
   if(!objectp(ot))
     o = repository->get_object(ot);
   else
     o = ot;
  if(!o) throw(Error.Generic("Object type " + ot + " does not exist.\n"));
  return  repository->get_instance(o->instance_name)(UNDEFINED, this);
}

