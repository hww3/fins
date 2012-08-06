inherit .StringField;

constant type = "BinaryString";
int len = 1024;

string encode(mixed value, void|object/*.DataObjectInstance*/ i)
{
  value = validate(value);
  if(value == .Undefined)
    return "NULL";
  else
    return "'" + context->quote_binary(value) + "'";
}

mixed decode(string value, void|object/*.DataObjectInstance*/ i)
{
  return context->unquote_binary(value);
}

