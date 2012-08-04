
//!
void throw(program errtype, string message, mixed ... args)
{
  mixed e = errtype(sprintf(message+"\n", @args), backtrace()[..<1]);
  predef::throw(e);
}