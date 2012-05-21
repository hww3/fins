inherit .Base;

//! args: var = dataset to paginate, store = basename of variable name to store stuff in.
string simple_macro_paginator(Fins.Template.TemplateData data, mapping|void args)
{
  object r = data->get_request();

  if(!args) return "";

  mixed pdata = args->var;

  if(!arrayp(pdata) && !objectp(pdata))
    return "";

  object paginator = Fins.Helpers.Pagination.Paginator(pdata);
  if(args->size) paginator->set_page_size((int)args->size);
  paginator->set_from_request(r);

  if(args->store)
  {
    mixed d = data->get_data();
    d[args->store] = paginator;
    
    if(paginator->has_next_page)
      d[args->store + "_nexturl"] = make_url(r, paginator->get_next_args());
    if(paginator->has_prev_page)
      d[args->store + "_prevurl"] = make_url(r, paginator->get_prev_args());
  }
  
  return "";    
}

//! args: var = dataset to paginate, store = basename of variable name to store stuff in.
string simple_macro_page_size_url(Fins.Template.TemplateData data, mapping|void args)
{
  object r = data->get_request();

  if(!args) return "";
  
  object paginator = args->paginator;
  
  if(!paginator) return "page_size_url macro: no paginator.";
  
  int size = (int)args->size;
  if(!size) return "page_size_url: invalid size " + args->size;
  return make_url(r, paginator->get_size_args(size));
}

string make_url(object r, mapping args)
{
  return app->add_variables_to_path(app->get_context_root() + r->not_args, r->variables + args);
}

//! args: var = dataset to paginate, size = comma separated list of size options (default is 5, 10, 25).
string simple_macro_page_size_selector(Fins.Template.TemplateData data, mapping|void args)
{
  object r = data->get_request();

  if(!args) return "";
  
  object paginator = args->paginator;
  
  if(!paginator) return "page_size_url macro: no paginator.";
  
  array(int) sizes = ({5, 10, 25});
  
  if(args->size)
  {
    sizes = ({});
      
    foreach(args->size/",";; string so)
    {
      int s = (int)(so - " ");
      if(s)
        sizes += ({ s });
    }
  }
  
  if(!sizeof(sizes)) return "page_size_url: invalid size " + args->size;
  
  String.Buffer buf = String.Buffer();
  
  foreach(sizes;; int s)
  {  
     if(paginator->page_size == s)
     {
       buf += " ";
       buf += (string)s;
     }
     else
     {
       buf += " <a href=\"";
       buf += make_url(r, paginator->get_size_args(s));  
       buf += ("\">" + s + "</a>");
     }
  }
  return buf->get();
}

//! args: var = dataset to paginate, window = number of page options to show (default = 5)
string simple_macro_page_selector(Fins.Template.TemplateData data, mapping|void args)
{
  object r = data->get_request();

  if(!args) return "";
  
  object paginator = args->paginator;
  
  if(!paginator) return "page_selector macro: no paginator.";
  
  int window = 5;
  
  if(args->window)
  {
    window = (int)args->window;      
  }
  
  if(!window) return "page_selector: invalid window size " + args->window;
  
  String.Buffer buf = String.Buffer();
  
  array sizes = ({});
    
  sizes += ({paginator->current_page});
  
  int q = (window/2) || 1;
  int up = paginator->current_page + 1;
  int lp = paginator->current_page - 1;
  while(q>0)
  {
    if(lp > -1) sizes += ({lp--});
    else if (up < paginator->num_pages)
      sizes+=({up++});
    q--;
  }
  q = (window/2)||1;
  while(q>0)
  {
    if (up < paginator->num_pages)
      sizes+=({up++});
    else if(lp > -1) sizes += ({lp--});
    q--;
  }
  
  sort(sizes);
  werror("pages: %O\n", sizes);
  array opt = ({});
  string pre = "", post="";
  
  if(sizeof(sizes))
  {
    if(sizes[0] > 0)
      pre = " ...";
  }
  foreach(sizes;; int s)
  {  
     if((paginator->current_page) == s)
     {
       buf += " ";
       buf += (string)(s+1);
       buf += " ";
     }
     else
     {
       buf += " ";
       buf += "<a href=\"";
       buf += make_url(r, paginator->get_page_args(s));  
       buf += ("\"> " + (s+1) + " </a>");
       buf += " ";
       
     }
     
     if(sizeof(sizes))
     {
       if(sizes[-1] < (paginator->num_pages -1))
         post = "... ";
     }
     
     
     opt += ({ buf->get() });
  }
  return pre + (opt * " &nbsp; ") + post;
}

//! args: var = dataset to paginate, window = number of page options to show (default = 5)
string simple_macro_page_filter(Fins.Template.TemplateData data, mapping|void args)
{
  object r = data->get_request();

  if(!args) return "";
  
  object paginator = args->paginator;
  
  if(!paginator) return "page_selector macro: no paginator.";
  
  String.Buffer buf = String.Buffer();
  
  buf += "<form action=\"";
  buf += r->not_query;
  buf += "\">";
  
  buf += "Starts wtih: ";
  
  foreach(r->variables; string k; string v)
  {
    if(k == ("_" + paginator->key + "_filter")) continue;
    if(k == ("_" + paginator->key + "_filter_field")) continue;

    buf += "<input name=\"";
    buf += k;
    buf += "\" type=\"hidden\" value=\"";
    buf += v;
    buf += "\">\n";
  }
  
  buf += "<input type=\"string\" name=\"_";
  buf += paginator->key;
  buf += "_filter\" value=\"";

  if(r->variables["_" + paginator->key + "_filter"])
    buf += r->variables["_" + paginator->key + "_filter"];
  buf += "\">";
  
  buf += "<input type=\"hidden\" name=\"_";
  buf += paginator->key;
  buf += "_filter_field\" value=\"";
  buf += args->field;
  buf += "\">"; 
  
  buf += "</form>";
  
  return buf->get();
}