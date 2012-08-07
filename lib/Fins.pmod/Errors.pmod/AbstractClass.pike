inherit Error.Generic;


//!
constant error_type = "abstract_class";

//!
constant _is_abstract_class_error = 1;

protected void create(mixed|void bt)
{
  if(!bt) bt = predef::backtrace();
  
  //write("sizeof bt: %O, %O\n", bt, backtrace());
  string msg = sprintf("Method %s in class %O must be overridden.\n", function_name(bt[-3][2]), function_program(bt[-3][2]) );
  ::create(msg, bt);
}