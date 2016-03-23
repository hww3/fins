

protected array acriteria = ({});

string _sprintf(mixed ...args)
{
   return "CompoundCriteria(" + get() + ")";
}

protected void create(array(.Criteria) _criteria)
{
   acriteria = _criteria;
}

string get(string|void name, void|.DataObjectInstance datai)
{
   return ((acriteria->get(name, datai))*" ");
}

string get_criteria_type()
{
  return "COMPOUND";
}
