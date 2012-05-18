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
  return app->add_variables_to_path(app->get_context_root() + r->not_args, args);
}