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
      d[args->store + "_nexturl"] = app->add_variables_to_path(app->get_context_root() + r->not_args, paginator->get_next_args());
    if(paginator->has_prev_page)
      d[args->store + "_prevurl"] = app->add_variables_to_path(app->get_context_root() + r->not_args, paginator->get_prev_args());
  }
  
  return "";    
}