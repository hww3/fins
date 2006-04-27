string simple_macro_javascript_includes(Fins.Template.TemplateData data, mapping|void args)
{
  return 
#" 
<script src=\"/static/javascripts/dojo.js\" type=\"text/javascript\"></script> 
";
}

//!
//! args:
//!
//! method
//! url
//! parameters
//! update
//! updatesuccess
//! updatefailure
//! before
//! after
//! condition
//!
string simple_macro_remote_form(Fins.Template.TemplateData data, mapping|void arguments)
{


  return "<form " + (arguments->id?"id=\"" + arguments->id + "\" ":"") + "onsubmit=\"" + 
     remote_function(arguments) + "\"" 
     ">";
}


string remote_function(mapping options)
{
  string f = "";
  array u = ({});

  string loadFunc = "";
  string errorFunc = "";

  if(!options->load)
  {

    if(options->success)
    {
      loadFunc += options->success;
    }

    if(options->update)
    {
      loadFunc += "var d = document.getElementById(" + stringify(options->update) + ");"
                "if(d) d.innerHTML = data.toString();";
    }
  
    if(options->complete)
    {
      loadFunc += options->complete;
    }
  }
  else
  {  
    loadFunc = options->load;
  }

  if(options->error)
  {
    errorFunc += options->error;
  }

  u += ({ "load: function(type, data, event){ " + loadFunc + "}" });
  u += ({ "error: function(type, data, event){ " + errorFunc + "}" });

  foreach(({"method", "mimetype", "url", "transport"});; string o)
  {
    if(options[o]) u += ({ o + ": " + stringify(options[o]) });
  }
 
  f = "var bindArgs = { " + (u * ",") + "};";

  

  if(options->id)
  {
    f += "var form = document.getElementById(" + stringify(options->id) + ");"
         "if(form) bindArgs.formNode = form;";
  }

  if(options->begin)
  {
    f += options->begin;
  }

  f += "var requestObj = dojo.io.bind(bindArgs);";

  f += "return false;";

  return "return function ()  { " + f + "}();";
}

string stringify(string s)
{
  return "'" + replace(s, "\"", "\\\"") + "'";
}
