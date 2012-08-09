inherit .Personality;

constant type = "sqlite";
constant splitter = "\\g\n";

int use_datadir;
string datadir;

mapping indexes = ([]);

int initialize_connection(object s)
{

#if constant(Sql.Provider.SQLite)
error("SQL.Provider.SQLite is not supported.\n");
#endif

  s->query("PRAGMA full_column_names=1");

  if((int)(context->model->config["model"]["datadir"]))
  {
    use_datadir = 1;
    datadir = context->model->config["model"]["datadir"];
  }

  return 1;
}


string get_limit_clause(int limit, int|void start)
{
  return "LIMIT " + limit + (start?(" OFFSET " + ((start-1)||"0")):"");
}

mapping get_field_info(string table, string field, mapping info)
{  
  if(!indexes[table])
    load_indexes(table);

  mapping i = indexes[table];
  mapping m = ([]);

  foreach(i;; mapping ind)
  {
    if(ind->name == field) 
    {
      if(ind->unique == "1") m->unique = 1;
    }
  }

  if(info && (<"datetime", "timestamp", "date", "time">)[info->type])
  {
	switch(upper_case(info->default))
	{
		case "CURRENT_TIME":
		case "CURRENT_DATE":
		case "CURRENT_TIMESTAMP":
//		werror("******\n******\n******\n");
			m->default = Fins.Model.Undefined;
			m->type_class = Fins.Model.SqliteDateTimeField;
	}
  }

  return m;
}

void load_indexes(string table)
{
  array x = context->execute("PRAGMA index_list(" + table + ")");

  if(!indexes[table]) indexes[table] = ([]);

  if(x) foreach(x;; mapping m)
  {
    array ii = context->execute("PRAGMA index_info(" + m->name + ")");
    foreach(ii;; mapping ir)
    {
      indexes[table][m->name] = ir + (["unique": m->unique]);
    }
  }
}

int(0..1) transaction_supported()
{
  return 1;
}

void begin_transaction()
{
  context->execute("BEGIN TRANSACTION");
}

void rollback_transaction()
{
  context->execute("ROLLBACK");
}

void commit_transaction()
{
  context->execute("COMMIT");
}

//! the alter table command in sqlite doesn't support dropping columns.
//! in order to simulate this functionality, we create a new table without 
//! the columns to be dropped, and then pull the data from the original table
//! before dropping the old table and renaming the new one. it's a technique
//! fraught with problems, because, for example, not all index definitions 
//! can be reconstructed. please be careful with this function, and 
//! always, always, ALWAYS have a good database backup before use.
int drop_column(string table, string|array columns)
{
   if(stringp(columns))
   {
     columns = ({columns});
   }
  
   // TODO: verify that the column already exists in the table.
   
   array columns_left = get_columns(table, columns);
   
   mapping ddl = regenerate_ddl(table, columns, 1);
   string query = 
   
   context->begin_transaction();
   mixed e;

   string copy_query = sprintf("INSERT INTO new_%s (%s) SELECT %s FROM %s", table, (columns_left->name)*", ", (columns_left->name) *", ", table);
   string drop_query = sprintf("DROP TABLE %s", table);
   string rename_query = sprintf("ALTER TABLE new_%s RENAME TO %s", table, table);
   
   e = catch
   {
     context->execute(ddl->table);
     context->execute(copy_query);
     context->execute(drop_query);
     context->execute(rename_query);

     string q;
     
     foreach(ddl->indexes;; q)
       context->execute(q);

       foreach(ddl->triggers;; q)
         context->execute(q);
   };
   if(e)  
   {
     context->rollback_transaction();
     throw(e);
   }
   else
     context->commit_transaction();
   
   return 1; 
}

array get_columns(string table, array columns_to_exclude)
{
  array x = context->execute(sprintf("PRAGMA table_info (%s)", table));

  if(!x) return 0;
  
  array columns = ({});
  
  foreach(x;; mapping column)
  {
    if(search(columns_to_exclude, column->name) == -1)
    columns += ({column});
  }
  
  return columns;
}

//! generate a set of sql to generate a table and associated objects
//!
//! can generate the sql ddl for the table, indexes (not including collation order)
//! and can also fetch trigger information. note that triggers may need to be
//! assessed manually, as they may involve columns excluded from the table definition.
//!
//! @note
//!  doesn't handle foreign keys yet.
mapping regenerate_ddl(string table, array columns_to_exclude, int newtable)
{
  string primary_key;
  array indexes = ({});
  array x;
  
  x = get_columns(table, columns_to_exclude);    
//  werror("%O\n", columns);

  array spec = ({});
    
  foreach(x;;mapping c)
  {
    if((int)c->pk) primary_key = c->name;
    
    string def = sprintf("%s %s %s %s %s", 
      c->name, 
      c->type, 
      (c->dflt_value != ""?(sprintf("DEFAULT VALUE '%s'", c->dflt_value)):""), 
      ((int)c->notnull?"NOT NULL":""), 
      ((int)c->pk?"PRIMARY KEY":""));
    spec += ({def});
  }

  string query = sprintf("CREATE TABLE %s (\n%s\n)", (newtable?"new_" + table:table), spec*",\n");

  mapping ind = ([]);

  x = context->execute(sprintf("PRAGMA index_list (%s)", table));
//  werror("%O\n", x);

  foreach(x;; mapping i)
  {
    mapping def = (["name": i->name, "columns": ({})]);
    if((int)i->unique) def->unique = 1;
    array z = context->execute(sprintf("pragma index_info (%s)", i->name));
    if(def->unique && sizeof(z) == 1 && z[0]->name == primary_key) // if this index is the primary key, we've already handled it.
      continue;

    foreach(z;; mapping index_info)
    {
      if(search(columns_to_exclude, index_info->name) == -1)
        def->columns = def->columns + ({index_info->name});
    }
    if(sizeof(def->columns))
      ind[i->name] = def;
  }

  array index_queries = ({});
    
 foreach(ind; string index_name;mapping index)
  {
    // if the index name is a sqlite generated name, we can't use it.
    if(has_prefix(index_name, "sqlite_autoindex_"))
      index_name = "index_" + (index->unique?"unique_":"") + (index->columns*"_");
    string iq = sprintf("CREATE %s INDEX %s ON %s (%s)", (index->unique?"UNIQUE":""), index_name, table, index->columns * ", ");
    index_queries += ({iq});
  } 
  
  x = context->execute(sprintf("SELECT * FROM sqlite_master where tbl_name='%s' and type='trigger'", table));
   
//  write(query + "\n");
  return (["table": query, "indexes": index_queries, "triggers": x->sql]);
}
