inherit .Personality;

constant type = "mysql";
constant splitter = ";\n";

mapping dbtype_to_finstype = 
([
   "tinyblob": "binary_string",
   "blob": "binary_string",
   "mediumblob": "binary_string",
   "longblob": "binary_string",

   "tinytext": "string",
   "text": "string",
   "mediumtext": "string",
   "longtext": "string",

   "char": "string",
   "varchar": "string",

   "tinyint": "integer",
   "smallint": "integer",
   "integer": "integer",
   "bigint": "integer",

   "float": "float",
   "double": "float",
 ]);

mapping dbtype_ranges =
([
  "tinyblob": (["min": 0, "max": 255]),
  "blob": (["min": 0, "max": 65535]),
  "mediumblob": (["min": 0, "max": 16777215]),
  "longblob": (["min": 0, "max": 4294967295]),

  "tinytext": (["min": 0, "max": 255]),
  "text": (["min": 0, "max": 65535]),
  "mediumtext": (["min": 0, "max": 16777215]),
  "longtext": (["min": 0, "max": 4294967295]),

  "tinyint": (["min": -128, "max": 127, "num": 1]),
  "smallint": (["min": -32768, "max": 32767, "num": 1]),
  "mediumint": (["min": -8388608, "max": 8388607, "num": 1]),
  "int": (["min": -2147483648, "max": 2147483647, "num": 1]),
  "bigint": (["min": -9223372036854775808, "max": 9223372036854775807, "num": 1]),

  "char": (["min": 0, "max": 255, "include_size": 1]),
  "varchar": (["min": 0, "max": 255, "include_size": 1]),
]);


string quote_binary(string s)
{
  return context->sql->quote(s);
}

string unquote_binary(string s)
{
  return s;
}

string get_limit_clause(int limit, int|void start)
{
  return "LIMIT " + (start?(((start-1)||"0") + ", "):"") + limit;
}

object get_connection()
{
  return master()->resolv("Sql.Sql")(context->sql_url, 0, 0, 0, (["reconnect": 1]));
}

void initialize_connection(object s)
{
  s->query("SET NAMES utf8");
  return;
}

mapping get_field_info(string table, string field)
{  
  mapping m = ([]);

  array r = context->execute("SHOW FIELDS FROM " + table + " LIKE '" + field + "'"); 
  if(!sizeof(r)) 
    Tools.throw(Error.Generic, "Field %s does not exist in %s.", field, table);

  if(has_prefix(r[0]->Type, "timestamp")) m->type = "timestamp";
  else m->type = r[0]->Type;
  if(r[0]->Key && r[0]->Key == "UNI") m->unique = 1;

  return m;
}

string get_field_definition(string table, string field, int|void include_index)
{
  array r = context->execute("SHOW FIELDS FROM " + table + " LIKE '" + field + "'"); 
  if(!sizeof(r)) 
    Tools.throw(Error.Generic, "Field %s does not exist in %s.", field, table);
  
  mapping fd = r[0];

  if(fd->Field != field)
    Tools.throw(Error.Generic, "Field %s does not exist in %s.", field, table);
  
  return low_get_field_definition(fd, include_index);
}

protected string low_get_field_definition(mapping fd, int|void include_index)
{
  string def;
  
  def = fd->Type + " " + ((fd->Null == "NO")?"NOT NULL ":"")  + 
  
  if(fd->Default)
    def += (" " + fd->default);
  def += (" " + fd->extra);
  
  if(include_index)
  {
    if(fd->Key == "UNI")
      def += " UNIQUE";
    else if(fd->Key == "PRI")
      def += " PRIMARY KEY";
  }
  return def;
}

int(0..1) transaction_supported()
{
//
// TODO: not strictly true, we need to do more here.
//
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
