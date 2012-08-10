inherit .DataModelContext;

constant context_type = "SqlDataModelContext";

object log = Tools.Logging.get_logger("fins.model.sqldatamodelcontext");

mapping builder = ([ "possible_links" : ({}), "belongs_to" : ({}), "has_many": ({}), "has_many_many": ({}), "has_many_index": ({}) ]);


//! 
object personality;

//!
mapping xa_storage = ([]);

//!
Sql.Sql sql;

int in_xa = 0;

int lower_case_link_names = 0;

string host_info()
{
  return sql->host_info();  
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
  catch(t = model_config["personality"]);
  if(t) 
    return t;
  else 
    return lower_case(Standards.URI(model_config["datasource"])->scheme);
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

  ::initialize();
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

int create_index(string table, string name, array fields, int unique)
{
  return personality->create_index(table, name, fields, unique);  
}

int drop_index(string table, string index)
{
  return personality->drop_index(table, index);
}

//! @returns
//!  1 if table existed and was dropped, 0 otherwise.
int drop_table(string table)
{
  array t = sql->list_tables(table);
  if(search(t, table) != -1)
  {
    sql->query(sprintf("drop table %s", table));
  }
  else return 0;
}

//! drops one or more columns from a table
//!
//! @note
//!  this functionality is simulated for some databases (such as sqlite)
//!  and therefore may not behave properly in all situations. always
//!  backup data and test before relying on the results of this operation.
int drop_column(string table, string|array columns)
{
  return personality->drop_column(table, columns);
}

//!
int rename_table(string table, string newname)
{
  return personality->rename_table(table, newname);
}

int rename_column(string table, string name, string newname)
{
  
}

void rebuild_fields()
{
   foreach(repository->object_definitions;; object d)
   {
	   d->gen_fields(this);
	   d->_set_renderers();
   }
}

//!
void register_types()
{
  ::register_types();

  initialize_links();
  rebuild_fields();
}

protected void remove_field_from_possibles(string field_name, string instance_name)
{
  foreach(builder->possible_links; int i; mapping pl)
  {
    if(pl && pl->obj && pl->obj->instance_name == instance_name && pl->field->name == field_name)
      builder->possible_links[i] = 0;
  }
}

// there be monsters here...
void initialize_links()
{
  if(!repository->object_definitions || 
     !sizeof(repository->object_definitions)) return 0;

  foreach(builder->belongs_to;; mapping a)
  {
    log->debug("processing belongs_to: %O", a);
    if(!repository->get_object(a->other_type))
    {
		log->error("error processing %O->belongs_to because the type %O does not exist.", a->obj, a->other_type);
	}
    if(!a->my_name) a->my_name = a->other_type;
    if(!a->my_field) a->my_field = lower_case(a->other_type + "_" + 			
		repository->get_object(a->other_type)->primary_key->field_name);    
	
	string my_name = a->my_name;
	string my_field = a->my_field;
	
	if(lower_case_link_names)
	{
	  my_name = lower_case(my_name);
	}
	
    a->obj->add_field(this_object(), master()->resolv("Fins.Model.KeyReference")(my_name, my_field, a->other_type, 0, a->nullable ));
//    a->obj->remove_field(my_field);
    remove_field_from_possibles(my_field, a->obj->instance_name);
  }

  foreach(builder->has_many;; mapping a)
  {
    if(!a->my_name) a->my_name = Tools.Language.Inflect.pluralize(a->other_type);
    if(!a->other_field) a->other_field = repository->get_object(a->other_type)->primary_key->name	;    

	string my_name = a->my_name;
	string other_field = a->other_field;

	if(lower_case_link_names)
	{
	  my_name = lower_case(my_name);
	}

    a->obj->add_field(this, master()->resolv("Fins.Model.InverseForeignKeyReference")(my_name, 
                        /*Tools.Language.Inflect.singularize*/(a->other_type),  other_field, a->criteria));

    remove_field_from_possibles(other_field, a->other_type);
  }

  foreach(builder->has_many_index;; mapping a)
  {
    if(!a->my_name) a->my_name = Tools.Language.Inflect.pluralize(a->other_type);

//    werror("we'll call the field " + a->my_name + "\n");
    if(!a->other_field) a->other_field = repository->get_object(a->other_type)->primary_key->name	;    

	string my_name = a->my_name;
	string other_field = a->other_field;
    string index_field = a->index_field;

	if(lower_case_link_names)
	{
	  my_name = lower_case(my_name);
	}

    a->obj->add_field(this, master()->resolv("Fins.Model.MappedForeignKeyReference")(my_name, /*Tools.Language.Inflect.singularize*/(a->other_type), other_field, index_field));

    remove_field_from_possibles(other_field, a->other_type);
  }

  foreach(builder->has_many_many;; mapping a)
  {
     object this_type;
     object that_type;

     this_type = repository->object_definitions[a->this_type->instance_name];
     that_type = repository->object_definitions[a->that_type];

     log->debug("*** have a Many-to-Many relationship in %s between %O and %O", a->join_table, this_type, that_type);

	string this_name = a->this_name;
	string that_name = a->that_name;

	if(lower_case_link_names)
	{
	  this_name = lower_case(this_name);
	  that_name = lower_case(that_name);
	}

     this_type->add_field(this, master()->resolv("Fins.Model.MultiKeyReference")(this_type, 
            Tools.Language.Inflect.pluralize(that_name),
            a->join_table,
            lower_case(this_type->instance_name + "_" + this_type->primary_key->field_name),
            lower_case(that_type->instance_name + "_" + that_type->primary_key->field_name),
             that_type->instance_name, that_type->primary_key->name, 0, 1));

     that_type->add_field(this, master()->resolv("Fins.Model.MultiKeyReference")(that_type, Tools.Language.Inflect.pluralize(this_name),
            a->join_table,
            lower_case(that_type->instance_name + "_" + that_type->primary_key->field_name),
            lower_case(this_type->instance_name + "_" + this_type->primary_key->field_name),
             this_type->instance_name, this_type->primary_key->name));
  }

  foreach(builder->possible_links;; mapping pl)
  {
	if(!pl) continue;
    log->debug("investigating possible link field %s in %s.", pl->field->name, pl->obj->instance_name);
    string pln = lower_case(pl->field->name);

    foreach(repository->object_definitions; string on; object od)
    {
      string mln = Tools.Language.Inflect.singularize(od->table_name) + "_" + od->primary_key->field_name;
      log->debug("  - considering %s as a possible field linkage.", mln);
      if(pln == lower_case(mln))
      {
		log->debug("adding reference for %s in %s id=%O", od->instance_name, pl->obj->instance_name, pl->obj->primary_key->name);

		string this_name = od->instance_name;
		string that_name = pl->obj->instance_name;

		if(lower_case_link_names)
		{
		  this_name = lower_case(this_name);
		  that_name = lower_case(that_name);
		}

        pl->obj->add_field(this, master()->resolv("Fins.Model.KeyReference")(this_name, pl->field->name, od->instance_name, 0, !(pl->field->not_null)));
        od->add_field(this, master()->resolv("Fins.Model.InverseForeignKeyReference")(Tools.Language.Inflect.pluralize(that_name), pl->obj->instance_name, this_name));
        builder->possible_links -= ({pl});
      }
    }
  }

  array table_components = ({});

  foreach(repository->object_definitions; string on; object od)
  {
    table_components += ({ (["tn": lower_case(Tools.Language.Inflect.pluralize(on)), "od": od ]) });  
  }
    
  // Now, we check for link-tables, that is, tables which represent a many-to-many relationship
  // between two datatypes using a table that contains tuples of the two id fields.
  //
  // We do this automatically by searching for any combination of tablea_tableb in the database which 
  // conforms to the practice of having the fields representing the two linked tables called typeA_id 
  // and typeB_id where typeA and typeB are singular forms of the table name.
  // 
  //  for example a table used to link user and group would be called users_groups and have fields called
  //  user_id and group_id.
  multiset available_tables = (multiset)sql->list_tables();
    
  foreach(table_components;; mapping o)
  {
    log->debug("looking for multi link reference for %s.", o->tn);

    foreach(table_components;; mapping q)
    {
      if(q->tn == o->tn) continue;  // skip self-self relationships :)
    log->debug(" - checking %s->%s.", q->tn, o->tn + "_" + q->tn);

      if(available_tables[o->tn + "_" + q->tn])
      {
        log->debug("  - have a mlr on %s", o->tn + "_" + q->tn);

		string this_name = q->od->instance_name;
		string that_name = o->od->instance_name;

		if(lower_case_link_names)
		{
		  this_name = lower_case(this_name);
		  that_name = lower_case(that_name);
		}

          o->od->add_field(this, master()->resolv("Fins.Model.MultiKeyReference")(o->od, Tools.Language.Inflect.pluralize(this_name),
            o->tn + "_" + q->tn, 
            lower_case(o->od->instance_name + "_" + o->od->primary_key->field_name), 
            lower_case(q->od->instance_name + "_" + q->od->primary_key->field_name),
             q->od->instance_name, q->od->primary_key->name, 0, 1));

          q->od->add_field(this, master()->resolv("Fins.Model.MultiKeyReference")(q->od, Tools.Language.Inflect.pluralize(that_name),
            o->tn + "_" + q->tn, 
            lower_case(q->od->instance_name + "_" + q->od->primary_key->field_name), 
            lower_case(o->od->instance_name + "_" + o->od->primary_key->field_name),
             o->od->instance_name, o->od->primary_key->name));
      }
    }
  }

  log->debug("possible links left over: %O", builder->possible_links);
  foreach(builder->possible_links;; mapping pl)
  {
    if(pl)
      pl->obj->do_add_field(this, pl->field);
  }
  
  builder->belongs_to = ({});
  builder->has_many = ({});
  builder->has_many_many = ({});
}
