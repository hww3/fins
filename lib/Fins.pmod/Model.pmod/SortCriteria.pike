
array fields = ({});
array direction = ({});

static string criteria = "";

string _sprintf(mixed ...args)
{
   return "LimitCriteria(" + start + ", " + limit + ")";
}

//! @param order
//!   one if @[Fins.Model.SORT_ASCENDING] or @[Fins.Model.SORT_DESCENDING]
//!   if not provided, defaults to SORT_ASCENDING.
static void create(string|array field, string|array order)
{
  if(!arrayp(field))
    field = ({ field });

  if(!arrayp(order))
    order = ({ order });

  int count_difference = sizeof(field) - sizeof(order);
  if(count_difference)
  {
     order = order + allocate(count_difference);
  }

   fields = field;
   direction = order;
}

string get(string|void name, object|void datao)
{
   return "ORDER BY " + get_clause();
}

string get_clause()
{
  string clause = "";
  array c = ({});

  foreach(fields;int i;;string fn)
  {
     c += ({fn, direction[i]?" DESC":" ASC"});
  }

  clause = c * ", ";

  return clause;
}

string get_criteria_type()
{
  return "ORDER BY";
}
