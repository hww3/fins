//! return a friendly string description of a @[Calendar] object.
//!
public string describe_date(object c)
{
  if(c->nice_print) return c->nice_print();
  else return "UNKOWN";
}

//! describe the calendar as a distance from
//! the present, such as "10 days ago".
public string friendly_date(object c)
{
   string howlongago;
   int future;

   if (c < Calendar.now()) {
     c = c->distance(Calendar.now());
   }
   else {
     c = Calendar.now()->distance(c);
     future++;
   }

   if(c->number_of_minutes() < 3)
   {
      howlongago = "Just a moment ago";
   }
   else if(c->number_of_minutes() < 60)
   {
      howlongago = c->number_of_minutes() + " minutes ago";
   }
   else if(c->number_of_hours() < 24)
   {
      howlongago = c->number_of_hours() + " hours ago";
   }
   else if(c->number_of_days() < 365)
   {
      howlongago = c->number_of_days() + " days ago";
   }
   else
   {
      howlongago = c->number_of_years() + ((c->number_of_years()>1)?" years ago":" year ago");
   }

   if (future)
     return replace(howlongago, "ago", "in the future");
   else
     return howlongago;
}

//! remove html tags from a string
string textify(string html)
{
  object p = Parser.HTML();
  p->_set_tag_callback(lambda(object parser, mixed val){return " ";});

  return p->finish(html)->read();
}

//! generate an excerpt of a string by breaking on a natural word 
//! less than 500 characters long and appending an elipsis.
string make_excerpt(string c)
{
        if(sizeof(c)<500)
          return c;
   int loc = search(c, " ", 499);

        // we don't have a space?
   if(loc == -1)
        {
                c = c[0..499] + "...";
        }
        else
        {
                c = c[..loc] + "...";
        }

        return c;
}

//! generate a password string resembling a word, containing prounouncable syllables
string generate_password(int length)
{
	object P = .PhoneticPasswords();
	return P->generate(1, length)[0];
}

multiset valid_chars = (<'1', '2', '3', '4', '5', '6', '7', '8', '9', '0', '.', 'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j',
  'k', 'l', 'm', 'n', 'o',  'p', 'q', 'r', 's', 't', 'u', 'v', 'w', 'x', 'y', 'z'>);

//! Parse a string containing a file size descriptor
//!
//! @param input
//!   a string describing a file size, such as: 2mb or 3.2gb, etc. This method understands bytes, 
//!   kilobytes, megabytes and gigabytes. If no unit is provided, it assumes kilobytes. Common abbreviations 
//!   are understood, as well.
//!
//! @returns
//!   an integer representing the number of bytes described by the input string.
int parse_filesize(string input)
{
  float mag;
  int mult = 1;
  string units;  

  // remove spaces and non-alphanumerics.  
  input = filter(lower_case(input), lambda(int a){ return valid_chars[a]; });
  sscanf(input, "%f%s", mag, units);
  
  if(mag <=0.0)
  {
    throw(Error.Generic("Invalid size specification '" + mag + " " + units + "'."));
  }
  
  if(!units || !sizeof(units)) units = "kb";
  
  switch(units)
  {
    case "b":
    case "bytes":
    case "byte":
      break;

    case "k":    
    case "kb":
    case "kilobytes":
    case "kilobyte":
      mult = 1024;
      break;

    case "m":    
    case "mb":
    case "megabytes":
    case "megabyte":
      mult = 1024*1024;
      break;

    case "g":    
    case "gb":
    case "gigabytes":
    case "gigabyte":
      mult = 1024*1024*1024;
      break;

    case "t":    
    case "tb":
    case "terabytes":
    case "terabyte":
      mult = 1024*1024*1024*1024;
      break;
      
    default:
      throw(Error.Generic("Unknown unit of size '" + units + "'."));
      break;
  }
  
  return (int)(mag * mult);
}

inherit .NamedSprintf;
