inherit .CompoundCriteria;

//!
string get(string|void name, void|int datao)
{
   return "(" + ((acriteria->get(name, datao))*" OR ") + ")";
}

//!
string get_criteria_type()
{
  return "OR";
}
