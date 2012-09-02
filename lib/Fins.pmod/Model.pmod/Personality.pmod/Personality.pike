constant type = "";
constant splitter = ";\n";

object log = Tools.Logging.get_logger("fins.model.personality");
object context;

int use_datadir;
string datadir;

mapping dbtype_to_finstype = 
([
   "var string": "string",
   "char": "string",
   "varchar": "string",
   "text": "string"
]);

mapping dbtype_ranges =
([
]);

protected mapping rdbtypes;


mapping get_field_info(string table, string field, mapping|void info);

static void create(object c)
{
  context = c;
}

object initialize()
{
  object s = get_connection();
  initialize_connection(s);
  return s;
}

void initialize_connection(object s)
{  
}

object get_connection()
{
  return master()->resolv("Sql.Sql")(context->url);
}

string get_serial_insert_value()
{
	return "NULL";
}


//! @param options
//!   a set of optional parameters: name, unique, order (mapping of fieldname to direction)
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
    options->name = sprintf("fins_%s_index_%s", table, fields * "_");
  context->execute(sprintf("CREATE %s INDEX %s ON %s (%s)", (options->unique?"UNIQUE":""), options->name, table, fields *","));

  // TODO: return a better value.
  return 1;
}

//!
int drop_index(string table, string index)
{
  context->execute(sprintf("DROP INDEX %s ON %s", index, table));

  // TODO: return a better value.
  return 1;
}

//!
int drop_index_for_column(string table, array columns)
{
  string name = get_index_for_column(table, columns);
  drop_index(table, name);
  // TODO: return a better value.
  return 1;
}

//!
string get_index_for_column(string table, array columns)
{
  Tools.throw(Fins.Errors.AbstractClass);
}

//!
int rename_table(string table, string newname)
{
  context->execute(sprintf("ALTER TABLE %s RENAME TO %s", table, newname));
  
  return 1;
}

//! returns sql datatype definition (but not the field name) for a given field.
string get_field_definition(string table, string field, int|void include_index)
{
  mapping fd = context->sql->list_fields(table, field)[0];
  
  if(fd->name != field)
    Tools.throw(Error.Generic, "unable to find field %s in table %s.", field, table);
  
  return low_get_field_definition(fd, include_index);
}

string format_literal(mixed l)
{
  if(intp(l) || floatp(l))
    return (string)l;
  else if(objectp(l) && Program.implements(object_program(l), Fins.Model.SqlLiteral))
    return l->get_literal();
  else
    return sprintf("'%s'", context->sql->quote(l));
}

protected string low_get_field_definition(mapping fd, int|void include_index)
{
  string type = fd->type;
  if(dbtype_ranges[fd->type] && dbtype_ranges[fd->type]->include_size)
    type = sprintf("%s(%s%s}", type, fd->length, (fd->decimals?(", " + fd->decimals):""));
   string def = sprintf("%s %s %s %s", upper_case(type), (fd->flags->not_null?"NOT NULL":""), 
                  (has_index(fd,"default")?("DEFAULT " + format_literal(fd->default)) :""), 
                  ((include_index&&fd->flags->primary_key)?"PRIMARY KEY":""));

   return String.trim_whites(def);
}

//!
int rename_column(string table, string name, string newname)
{
  string def;

  def = get_field_definition(table, name);  
  string q = sprintf("ALTER TABLE %s CHANGE %s %s %s", table, name, newname, def);
  
  log->info("executing "+ q);
  
  context->execute(q);
}

//! change the column type but not the name
int change_column(string table, string name, mapping fd)
{
  string def;
  def = get_field_definition(table, name);  
  string q = sprintf("ALTER TABLE %s CHANGE %s %s %s", table, name, name, def);

  log->info("executing "+ q);
  context->execute(q);  
}

//!
int add_column(string table, string name, mapping fd)
{
  string def;
  def = low_get_field_definition(unmap_field(fd, table));
  string q = sprintf("ALTER TABLE %s ADD COLUMN %s %s", table, name, def);

  log->info("executing "+ q);
  context->execute(q);  
}

//! delete columns from a table.
//!
//! @param table
//!   name of the table containing columns to drop
//!
//! @param columns
//!   name or array of names of colums to drop
//!
//! @note
//!   transaction will be rolled back if this operation fails.
int drop_column(string table, string|array columns)
{
   if(stringp(columns))
   {
     columns = ({columns});
   }
   
   array spec = allocate(sizeof(columns));
   
   foreach(columns; int i; string c)
   {
     spec[i] = sprintf("DROP COLUMN %s", c);
   }

   string query = sprintf("ALTER TABLE %s %s", table, spec*", ");
   
   mixed e;
   
   context->begin_transaction();
   if((e = catch(context->execute(query))))
   {
     context->rollback_transaction();
     throw(e);
   }
   else
     context->begin_transaction();
   
   return 1; 
}

//!
array(mapping) list_fields(string table, string|void wild)
{
   array x = context->sql->list_fields(table, wild);
   return map(x, map_field, table);
}

// there's little agreement here, so we'll have to override this everwhere.
// start is the starting point from which to begin the limit, where the first record is record 1.
string get_limit_clause(int limit, int|void start)
{
  return "";
}

string make_fn(string s)
{
  return  (string)hash(s + time());
}

//!
string quote_binary(string s)
{
  if(!use_datadir)
    return replace(s, ({"%", "'", "\000"}), ({"%25", "%27", "%00"}));
  else
  {
    string fn = make_fn(s);
    string mfn = Stdio.append_path(datadir, fn);
    Stdio.write_file(mfn, s);
    return fn;
  }
}

//!
string unquote_binary(string s)
{
  if(!use_datadir)
    return replace(s, ({"%25", "%27", "%00"}), ({"%", "'", "\000"}));

  else
  {
    return Stdio.read_file(Stdio.append_path(datadir, s));
  }
}

mapping unmap_field(mapping t, string table)
{
  log->debug("unmapping field %O.", t);

  t = t + ([]); // make a copy

  mapping field = ([]);

  field->name = t->name;

  if(!field->flags)
    field->flags = ([]);


  if(t->default)
    field->default = t->default;
  if(t->type_class)
    field->type_class = t->type_class;

  switch(lower_case(t->type))
  {
    case "time":
      field->type = "time";
      break;

    case "date":
      field->type = "date";

    case "datetime":
      field->type = "datetime";
      break;

    case "timestamp":
      field->type = "timestamp";
      break;

    case "float":
      field->type = "float";
      break;

    case "integer":
    case "string":
      field->length = t->length;
      field->type = get_type_for_size(t->type, (int)t->length);
      if(!field->type)
      {
        Tools.throw(Error.Generic, "Unable to determine native db type for % with len %d.", t->type, (int)t->length);
      }
      break;

    case "binary_string":
      field->length = t->length;
      string tx = get_type_for_size(t->type, (int)t->length);
      if(!field->type)
      {
        Tools.throw(Error.Generic, "Unable to determine native db type for %s with len %d.", t->type, t->length);
      }
      tx = field->type;
      break;

    default:
      throw(Error.Generic("unknown field type " + t->type + ".\n"));

  }

  field->flags->unique = t->unique;
  field->flags->not_null = t->not_null;
  field->flags->primary_key = t->primary_key;

  werror("unmapped to %O\n", field);

  return field;
}

string get_type_for_size(string type, int len)
{
  string t;

  if(!rdbtypes)
  {
    rdbtypes = ([]);

    foreach(dbtype_to_finstype; string dbt; string ft)
    {
      if(!rdbtypes[ft]) rdbtypes[ft] = ({});
      rdbtypes[ft] += ({dbt});
    }
  }

  foreach(rdbtypes[type];;string dbt)
  {
    mapping dbtr;
    if(!(dbtr = dbtype_ranges[dbt]))
      continue;
    int nn = len;
    if(dbtr->num) nn = (int)(pow(10, len)-1);
    if(dbtr->max >= nn)
    {
       t = dbt;
       if(dbtr->include_size) t+= ("(" + len + ")");
       break;
    }
  }

  return t;
}

mapping map_field(mapping t, string table)
{
  log->debug("mapping field %O.", t);
  mapping field = ([]);

  field->name = t->name;

  if(!t->flags)
    t->flags = ([]);

  field->primary_key = t->flags->primary_key;

  if(this->get_field_info)
  { 
    mapping x = this->get_field_info(t->table, t->name, t);
    if(t->type != "unknown")
      m_delete(x, "type");

        t = t + x;
  }

  if(t->default)
    field->default = t->default;
  if(t->type_class)
    field->type_class = t->type_class;

  log->debug("Field %s.%s is a %s.", t->table, t->name, t->type); 

  string ftype = lower_case(t->type);

  field->type = dbtype_to_finstype[ftype] || ftype;
  field->otype = ftype;

  switch(lower_case(field->type))
  {
    case "string":
      if(t->default && sizeof(t->default)) field->default = t->default;
      field->length = t->length;
      if(!field->length)
      {
       if(dbtype_ranges[field->otype])
          field->length = dbtype_ranges[field->otype]->max;
        else
          log->warn("No maximum field length specification available for type %s.", field->otype);
      }
      break;
    case "timestamp":
    case "time":
    case "date":
    case "datetime":
    case "integer":  
      // TODO: handle mix/max limit setting.
      break;
    case "float":
      // TODO: handle mix/max limit setting.
      break;
    case "binary_string":
      field->length = (int)t->length;
      if(!field->length)
      {
        if(dbtype_ranges[field->otype])
          field->length = dbtype_ranges[field->otype]->max;
        else
          log->warn("No maximum field length specification available for type %s.", field->otype);
      }
      break;
    default:
      Tools.throw(Error.Generic, "unsupported field type %s specified in field %s, table %s.", upper_case(field->type), t->name, table);
  }

  field->unique = t->unique;
  field->not_null = t->flags->not_null;

  return field;
}


//!
int(0..1) transaction_supported()
{
  return 0;
}

//! abstract method
void begin_transaction()
{
  Tools.throw(Fins.Errors.ModelError, "Transactions are not supported by this database engine.");
}

//! abstract method
void rollback_transaction()
{
  Tools.throw(Fins.Errors.ModelError, "Transactions are not supported by this database engine.");
}

//! abstract method
void commit_transaction()
{
  Tools.throw(Fins.Errors.ModelError, "Transactions are not supported by this database engine.");
}
