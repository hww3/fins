inherit .Personality;

constant type = "postgres";
constant splitter = "\\g\n";

string get_serial_insert_value()
{
	return "DEFAULT";
}

string get_last_insert_id(object field, object i)
{
	string t, f;
	
	t = i->master_object->table_name;
	f = field->field_name;
	

	array a = context->execute("select currval('" + t + "_" + f + "_seq')");

   return a[0]["currval"];
}


string get_limit_clause(int limit, int|void start)
{
  return "LIMIT " + limit + (start?(" OFFSET " + start):"");
}


int(0..1) transaction_supported()
{
  return 1;
}

void begin_transaction()
{
  context->execute("START TRANSACTION");
}

void rollback_transaction()
{
  context->execute("ROLLBACK");
}

void commit_transaction()
{
  context->execute("COMMIT");
}

//!
int create_index(string table, string name, array fields, int unique, string|void tablespace)
{
  context->execute(sprintf("CREATE %s INDEX %s ON %s (%s)%s", (unique?"UNIQUE":""), name, table, fields *",", (tablespace?(" TABLESPACE " + tablespace):"")));

  // TODO: return a better value.
  return 1;
}


string get_index_for_column(string table, array columns)
{
  string expr;
 
  array cx = ({});
  columns = columns + ({}); // make a copy.
       
  foreach(columns; int i; string s)
    columns[i] = lower_case(s);
  
  array cx = ({});
  
  foreach(columns;; string c)
    cx += ({"'" + c + "'"});
  array res = context->execute(sprintf(
    #"
    select
        t.relname as table_name,
        i.relname as index_name,
        a.attname as column_name
    from
        pg_class t,
        pg_class i,
        pg_index ix,
        pg_attribute a
    where
        t.oid = ix.indrelid
        and i.oid = ix.indexrelid
        and a.attrelid = t.oid
        and a.attnum = ANY(ix.indkey)
        and t.relkind = 'r'
        and t.relname like '%s'
        and a.attname IN(%s)
    order by
        t.relname,
        i.relname;
    ", table, cx *", "));
  
  if(sizeof(res) <= sizeof(columns)) // short circuit.
  {
    return 0;
  }

  array keys = uniq(res->index_name);
  mapping indexes = ([]);
  foreach(res;; mapping rs)
  {
    if(!indexes[rs->index_name])
     indexes[rs->index_name] = ({});
    indexes[rs->index_name] += ({rs->column_name});
  } 
   
  foreach(keys;; string keyname)
  {
    array k = indexes[keyname];
    if(sizeof(k) != sizeof(columns)) 
      continue;
    else if(sizeof(k - columns) == 0)
      return keyname;
  }
  
  return 0;
}

int create_index(string table, array fields, mapping|void options)
{
  if(!options) options = ([]);

  fields = fields + ({}); // make a copy.

  if(options->order)
  {
    foreach(options->order; string f; string direction)
    {
      int i = search(fields, f);
      if(i == -1)
       Tools.throw(Error.Generic, "index order specified for non-specified field %s.", f);
      else
        fields[i] = fields[i] + " " + direction;
    }
  }

  if(!options->name)
    options->name = sprintf("fins_%s_index_%s", table, fields * "_")
  context->execute(sprintf("CREATE %s INDEX %s ON %s (%s)%s", 
    (options->unique?"UNIQUE":""), 
    options->name, table, fields *",", 
    (options->tablespace?(" TABLESPACE " + options->tablespace):"")));

  // TODO: return a better value.
  return 1;
}

int change_column(string table, string name, mapping fd)
{
  Tools.throw(Fins.Errors.AbstractClass);
}
