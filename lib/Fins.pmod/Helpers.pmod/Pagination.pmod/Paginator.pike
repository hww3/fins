//! a class that handles breaking an array into page sized chunks.


array|object rdata;
array|object data;

int page_size;
int current_pos;
string key;
int _np;
string filter_value;
string filter_field;

//!
void create(array|object pdata, string|void pkey)
{
  data = rdata = pdata;
  key = pkey||"paginator";
}

void filter_data()
{
  if(filter_field && sizeof(filter_field) && filter_value && sizeof(filter_value))
  {
    data = filter(rdata, lambda(mixed v){return has_prefix(lower_case(v[filter_field]||""), filter_value); });
  }
  else data = rdata;
}

void set_page_size(int len)
{
  int ops = page_size;

  if(len < 1) throw(Error.Generic("Page size cannot be less than 1.\n"));

  _np=0;
  page_size = len;
 
  // if we are already on a different page, we should figure out what the 
  // new page would be for the first record on the old one.
  if(current_page > 0 && ops != page_size)
  {
    // find current record number 
    int start = current_pos;
    int nps = (int)floor((float)start/page_size);
    set_current_pos(nps);
  }
}

//!
void set_current_pos(int pos)
{
  if(pos < 0) 
    current_pos = 0;
  else if(pos > (sizeof(data)/page_size)*page_size) 
  {
    current_pos = (sizeof(data)/page_size)*page_size;
  }
  else
    current_pos = pos;
}

//!
mixed `->page()
{
  return data[current_pos..(current_pos+page_size)-1];
}

//!
int `->page_no()
{
  return (current_pos/page_size)+1;  
}

//!
int `->num_pages()
{
  if(_np) return _np;
  else
  return _np = (int)ceil((float)(sizeof(data))/page_size);
}

//!
int `->current_page()
{
  return (current_pos/page_size);  
}

//!
int `->has_next_page()
{
  return current_page<(num_pages-1);  
}

//!
int `->has_prev_page()
{
  return current_page>0;  
}

//!
void set_from_request(object id)
{
  string s;
  int i;

  if(s = id->variables["_" + key + "_filter_field"])
  {
    filter_field = s;
  }

  if(s = id->variables["_" + key + "_filter"])
  {
    filter_value = lower_case(s);
  }

  // filter the data, if necessary, before performing page count calculation.
  filter_data();
  
  if(s = id->variables["_" + key + "_size"])
  {
    if(i = (int)s)
    {
      werror("setting page size " + i + "\n");
      set_page_size(i);
    }
  }

  if(s = id->variables["_" + key + "_shift"])
  {
     if(s == "+")
     {
       set_current_pos(current_pos + page_size);
     }
     else if(s == "-")
     {
       set_current_pos(current_pos - page_size);
     }
     else
     {
       set_current_pos((int)s);
     }
  }
}


mapping get_page_args(int pn)
{
  return ( (["_" + key + "_shift": page_size*pn, "_" + key + "_size": page_size]) +  
    ( (filter_value && filter_field) ? ( (["_" + key + "_filter": filter_value, "_" + key + "_filter_field": filter_field ]) ) : ( ([]) ) ) );
}

mapping get_next_args()
{
  return ( (["_" + key + "_shift": page_size*(current_page + 1), "_" + key + "_size": page_size]) + 
    ( (filter_value && filter_field) ? ( (["_" + key + "_filter": filter_value, "_" + key + "_filter_field": filter_field ]) ) : ( ([]) ) ) );
  
}

mapping get_prev_args()
{
  return ( (["_" + key + "_shift": page_size*(current_page -1), "_" + key + "_size": page_size]) + 
    ( (filter_value && filter_field) ? ( (["_" + key + "_filter": filter_value, "_" + key + "_filter_field": filter_field ]) ) : ( ([]) ) ) );
}

mapping get_size_args(int len)
{
  return ( (["_" + key + "_shift": page_size*(current_page), "_" + key + "_size": len]) + 
    ( (filter_value && filter_field) ? ( (["_" + key + "_filter": filter_value, "_" + key + "_filter_field": filter_field ]) ) : ( ([]) ) ) );
}

