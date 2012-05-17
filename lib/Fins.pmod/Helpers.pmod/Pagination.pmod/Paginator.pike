//! a class that handles breaking an array into page sized chunks.


array|object data;

int page_size;
int current_page;
string key;
int _np;

//!
void create(array|object pdata, string|void pkey)
{
  data = pdata;
  key = pkey||"paginator";
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
    int start = (current_page) * ops;
    int nps = (int)floor((float)start/page_size);
    set_current_page(nps);
  }
}

//!
void set_current_page(int pn)
{
  if(pn < 0) 
    current_page = 0;
  else if(pn > num_pages) 
  {
    current_page = num_pages;
  }
  else
    current_page = pn;
}

//!
mixed `->page()
{
  int start = (current_page) * page_size;
  return data[start..(start+page_size)-1];
}

//!
int `->page_no()
{
  return current_page;  
}

//!
int `->num_pages()
{
  if(_np) return _np;
  else
  return _np = (int)ceil((float)(sizeof(data))/page_size);
}

//!
void set_from_request(object id)
{
  string s;
  int i;

  if(s = id->variables["_" + key + "_shift"])
  {
     if(s == "+")
     {
       set_current_page(current_page + 1);
     }
     else if(s == "-")
     {
       set_current_page(current_page - 1);
     }
     else
     {
       set_current_page((int)s);
     }
  }
  if(s = id->variables["_" + key + "_size"])
  {
    if(i = (int)s)
    set_page_size(i);
  }
}


mapping get_up_args()
{
  return (["_" + key + "_shift": (current_page + 1), "_" + key + "_size": page_size]);
}

mapping get_down_args()
{
  return (["_" + key + "_shift": (current_page -1), "_" + key + "_size": page_size]);
}

mapping get_size_args(int len)
{
  return (["_" + key + "_shift": (current_page), "_" + key + "_size": len]);
}

