
//!
void throw(program errtype, string|void message, mixed ... args)
{
  mixed e = errtype(sprintf(message+"\n", @args), backtrace()[..<1]);
  predef::throw(e);
}