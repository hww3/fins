inherit Error.Generic;

//!
constant error_type = "abstract_class";

//!
constant _is_abstract_class_error = 1;

//!
protected void create(mixed|void bt)
{
  mixed f = bt[-3][2];
  
  if(!bt) bt = predef::backtrace();
    string msg = sprintf("Method %s in class %O must be overridden.\n", function_name(f), function_program(f));

  ::create(msg, bt);
}