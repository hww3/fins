//! collapse duplicated and adjacent elements.
//!
//! @param template
//!   a template string to use for collapsed elements, uses 
//!   @[Tools.String.named_sprintf] with the parameter names "message"
//!   and "count".  If a template is not specified, a default will 
//!   be provided.
//! 
public array consolidate(array(string) items, string|void template)
{
  array out = ({});
  string last;
  int count;
  
  if(!template) template = "%{message} (%{count} times)";

  foreach(items;; string i)
  {
    if(last && last == i)
      count++;
    else if(last && last != i)
    {
      out += ({Tools.String.named_sprintf(template, (["message": last, "count": count]))});
      last = i;
      count = 1;
    }
    else
    {
      last = i;
    }
  }
  if(last)
  {
    string msg = last;
    if(count>1)
      msg = Tools.String.named_sprintf(template, (["message": msg, "count": count]));
    out+=({msg});
  }
  return out;
}
