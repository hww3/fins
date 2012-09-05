inherit .Personality;

constant type = "sqlite";
constant splitter = "\\g\n";

int use_datadir;
string datadir;

mapping indexes = ([]);

mapping dbtype_to_finstype = ::dbtype_to_finstype +
([
    "blob": "binary_string",
    "string": "string",
    "integer": "integer",
    "int": "integer",
    "float": "float"
]);

mapping dbtype_ranges =
([
  "blob": (["min": 0, "max": 4294967295]),
  "string": (["min": 0, "max": 4294967295]),
  "integer": (["min": -9223372036854775808, "max": 9223372036854775807]),
  "float": (["min": -9223372036854775808, "max": 9223372036854775807]),
]);


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

//!
string get_index_for_column(string table, array columns)
{
  columns = columns + ({});
     
  array res = context->execute(sprintf("PRAGMA index_list(%s)", table));
  
  if(!sizeof(res))
  {
    return 0;
  }
  
  foreach(columns; int i; string s)
    columns[i] = lower_case(s);
  
  foreach(res;;mapping index)
  {
    res = context->execute(sprintf("PRAGMA index_info(%s)", index->name));
    res = res->name;
    if(sizeof(res) != sizeof(columns))
      continue;
      
    foreach(res; int i; string s)
      res[i] = lower_case(s);
    if(sizeof(res - columns) == 0)
      return index->name;
  }
  
  return 0;
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
int drop_column(string table, string|array columns, int dry_run)
{
   if(stringp(columns))
   {
     columns = ({columns});
   }
  
   // TODO: verify that the column already exists in the table.
   
   array columns_left = get_columns(table, columns);
   
   mapping ddl = regenerate_ddl(table, columns, 1);
   

   string copy_query = sprintf("INSERT INTO new_%s (%s) SELECT %s FROM %s", table, (columns_left->name)*", ", (columns_left->name) *", ", table);
   string drop_query = sprintf("DROP TABLE %s", table);
   string rename_query = sprintf("ALTER TABLE new_%s RENAME TO %s", table, table);

   if(!dry_run)
   {
//     context->begin_transaction();
     mixed e;

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
//       context->rollback_transaction();
       throw(e);
     }
//     else
//       context->commit_transaction();
   }
   
   return 1; 
}

//!
int change_column(string table, string name, mapping fd, int dry_run)
{
  array columns_left = get_columns(table, ({}));

  int i = search(columns_left->names, name);
  if(i == -1)
    Tools.throw(Error.Generic, "field %s does not exist in table %s", name, table);

  array oldnames = columns_left->name;
  columns_left[i] = fd;

  array newnames = columns_left->name;

  mapping ddl = low_regenerate_ddl(table, columns_left, newnames, 1);

  string copy_query = sprintf("INSERT INTO new_%s (%s) SELECT %s FROM %s", table, (newnames * ", "), (oldnames * ", "), table);
  string drop_query = sprintf("DROP TABLE %s", table);
  string rename_query = sprintf("ALTER TABLE new_%s RENAME TO %s", table, table);

  if(!dry_run)
  {
//    context->begin_transaction();
    mixed e;

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
//      context->rollback_transaction();
      throw(e);
    }
//    else
//      context->commit_transaction();
  }
  
  return 1; 
}

int rename_column(string table, string name, string newname, int dry_run)
{
   array columns_left = get_columns(table, ({}));
   array newnames = columns_left->name;
   
   int i = search(newnames, name);
   if(i == -1)
     Tools.throw(Error.Generic, "field %s does not exist in table %s", name, table);
   
   newnames[i] = newname;
   
   mapping ddl = low_regenerate_ddl(table, columns_left, newnames, 1);
   
//   context->begin_transaction();
   mixed e;

   string copy_query = sprintf("INSERT INTO new_%s (%s) SELECT %s FROM %s", table, newnames*", ", (columns_left->name) *", ", table);
   string drop_query = sprintf("DROP TABLE %s", table);
   string rename_query = sprintf("ALTER TABLE new_%s RENAME TO %s", table, table);

   if(!dry_run)
   {
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
//       context->rollback_transaction();
       throw(e);
     }
//     else
//       context->commit_transaction();
   }
   
   return 1; 
}

array get_columns(string table, array columns_to_exclude)
{
  array x = context->sql->list_fields(table);

  if(!x) return 0;
  
  array columns = ({});
  
  foreach(x;; mapping column)
  {
    if(search(columns_to_exclude, column->name) == -1)
    columns += ({column});
  }
  
  return columns;
}

string get_field_definition(string table, string field, int|void include_index)
{
  mapping c;
  array x = context->sql->list_fields(table, field);
  
  if(!sizeof(x) || x[0]->name != field)
    Tools.throw(Error.Generic, "field %s not found in table %s.", field, table);
  
  c = x[0];

  return low_get_field_definition(c, include_index);
}

protected string low_get_field_definition(mapping fd, int|void include_index)  
{
  log->debug("low_get_field_definition(%O)\n", fd);
  string type = fd->type;
  if(dbtype_ranges[fd->type] && dbtype_ranges[fd->type]->include_size)
    type = sprintf("%s(%s%s}", type, fd->length, (fd->decimals?(", " + fd->decimals):""));

  string def = sprintf("%s %s %s %s", 
    upper_case(type),
    (has_index(fd, "default")?(sprintf("DEFAULT %s", format_literal(fd->default))):""), 
    ((int)fd->flags->not_null?"NOT NULL":""), 
    ((include_index && (int)fd->flags->primary_key)?"PRIMARY KEY":0) || ((include_index && (int)fd->flags->unique)?"UNIQUE":""));

  return String.trim_whites(def);
}

//! generate a set of sql to generate a table and associated objects
//!
//! can generate the sql ddl for the table, indexes (not including collation order)
//! and can also fetch trigger information. note that triggers may need to be
//! assessed manually, as they may involve columns excluded from the table definition.
//!
//! @note
//!  doesn't handle foreign keys yet.
mapping low_regenerate_ddl(string table, array columns, array newnames, int newtable)
{
  string primary_key;
  array indexes = ({});
  array spec = ({});  

  foreach(columns; int i;mapping c)
  {
    c->newname = newnames[i];
      
    if((int)c->flags->primary_key) primary_key = c->name;

    string def = sprintf("%s %s",  
      c->newname, 
      low_get_field_definition(c, 1));
    spec += ({def});
  }
  
  string query = sprintf("CREATE TABLE %s (\n%s\n)", (newtable?"new_" + table:table), spec*",\n");

  mapping ind = ([]);

  array x = context->execute(sprintf("PRAGMA index_list (%s)", table));
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
      if(search(columns->name, index_info->name) != -1)
      {
        string n = index_info->name;
        
        // map the old name to the new name.
        n = newnames[search(columns->name, n)];
        def->columns = def->columns + ({n});
      }
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

mapping regenerate_ddl(string table, array columns_to_exclude, int newtable)
{
  array x;
  
  x = get_columns(table, columns_to_exclude);    
//  werror("%O\n", columns);

  return low_regenerate_ddl(table, x, x->name, newtable);
}
