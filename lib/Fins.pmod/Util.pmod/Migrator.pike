
string make_descriptor(string text)
{ 
  return (string)map(filter((array)Unicode.normalize(lower_case(text), "DK"), `<, 256), lambda(mixed x){if(x<'0') return '_'; else return x;}); 
}

string make_id(object id)
{
  return replace(id->format_time(), ({" ", "-", ":", "."}), ({"", "", "", ""})); 
}

string make_class(string text, object id)
{
  return
  #"inherit Fins.Util.MigrationTask;
  
  constant id = \"" + make_id(id) + 
  
  #"\";
  constant name=\"" + make_descriptor(text) + 
  #"\";
  ";
  
  
}

string new_migration(string text, object|void id)
{
  if(!id) id = Calendar.now();
  string c = make_class(text, id);
  string fn = make_id(id) + "_" + make_descriptor(text) + ".pike";
  
  Stdio.write_file(fn, c);
  
  return fn;
}