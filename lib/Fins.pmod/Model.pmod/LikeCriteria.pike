inherit .Criteria;


//!
string get(string|void name, object datao)
{
   object field = datao->fields[name];
  if(!field) werror("field <%s> not found in %O\n", name, datao);
   return sprintf("%s LIKE %s", name, field->encode(criteria));
}
