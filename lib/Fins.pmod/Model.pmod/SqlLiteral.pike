constant __is_sql_literal = 1;

string literal;

static void create(string l)
{
  literal = l;
}

string get_literal()
{
  return literal;
}

static string _sprintf(int x, void|mapping y)
{
  return "SqlLiteral(" + literal + ")";
}
