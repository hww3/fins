object context;
string table;

protected array fields = ({});
protected array indexes = ({});

protected void create(string _table, object _context)
{
  context = _context;
  table = _table;
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
  context->create_table(table, fields, indexes);
}