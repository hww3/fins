//! field definition for id field.
constant ID = ({"id", "integer", (["primary_key": 1, "auto_increment": 1])});

object context;
string table;
object migration;

protected array fields = ({});
protected array indexes = ({});

int dry_run;

//!
protected void create(string _table, object _context, object|void _migration, int|void _dry_run)
{
  context = _context;
  table = _table;
  migration = _migration;
  dry_run = _dry_run;
}

//!
void add_field(string field, string type,  mapping opts)
{
  fields += ({ ({field, opts + (["type": type]) }) });
}

//!
void add_index(array fields, mapping opts)
{
  indexes += ({ ({fields, opts }) });  
}

//! creates the table.
void go(int|void _dry_run)
{
  if(!_dry_run)
    _dry_run = dry_run;
    
  if(migration)
  {
    migration->announce("creating table %s.", table);
  }
  
  context->create_table(table, fields, indexes, _dry_run);
}
