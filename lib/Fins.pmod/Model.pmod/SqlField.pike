inherit .Field;

program ic; // InCriteria

string make_qualifier(mixed v)
{
  if(!ic)
    ic = master()->resolv("Fins.Model.InCriteria");
  if(arrayp(v))
    return ic(v)->get(field_name);
  else
    return field_name + "=" + encode(v);
}
