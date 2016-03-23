constant __is_sql_literal = 1;

string literal;

protected void create(string l)
{
  literal = l;
}

string get_literal()
{
  return literal;
}

protected string _sprintf(int x, void|mapping y)
{
  return "SqlLiteral(" + literal + ")";
}
