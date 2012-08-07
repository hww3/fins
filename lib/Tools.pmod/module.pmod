
//!
void throw(program errtype, string|void message, mixed ... args)
{
  mixed e;
  
  if(message)
    e = errtype(sprintf(message+"\n", @args), backtrace()[..<1]);
  else 
    e = errtype();
  
  predef::throw(e);
}