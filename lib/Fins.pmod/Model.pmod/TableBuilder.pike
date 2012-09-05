object context;
string table;
object migration;

protected array fields = ({});
protected array indexes = ({});

protected void create(string _table, object _context, object|void _migration)
{
  context = _context;
  table = _table;
  migration = _migration;
}

void add_field(string field, string type,  mapping opts)
{
  fields += ({ ({field, opts + (["type": type]) }) });
}

void add_index(array fields, mapping opts)
{
  indexes += ({ ({fields, opts }) });  
}

void go()
{
  if(migration)
  {
    migration->announce("creating table %s.", table);
  }
  
  context->create_table(table, fields, indexes);
}