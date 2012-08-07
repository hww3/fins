//! The base class for all other inter-datatype relationships. Doesn't really provide any functionality on its own.

inherit .SqlField;

constant type = "";
string otherobject = "";

string to()
{
  return otherobject;
} 
