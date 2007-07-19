//!
int debug = 0;

mapping builder = ([ "possible_links" : ({}), "belongs_to" : ({}), "has_many": ({}) ]);

//!
object repository;

//!
object cache;

//! 
object personality;

//!
object app;

//!
Sql.Sql sql;
string sql_url;

string _sprintf(mixed ... args)
{
  return "DataModelContext(" + sql->host_info() + ")";
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
  catch(t = app->config["model"]["personality"]);
  if(t) return t;
  else return (sprintf("%O", object_program(sql->master_sql))/".")[-1];
}

program get_personality()
{
  if(!sql) throw(Error.Generic("No SQL connection defined.\n"));

  return .Personality[type()];
}

int initialize()
{
  program p = get_personality();
  if(!p) throw(Error.Generic("Unknown database type. No personality.\n"));

  personality = p(sql, this);

  personality->initialize();
}
