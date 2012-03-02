inherit .Renderer;

string get_display_string(void|mixed value, Fins.Model.Field field, void|Fins.Model.DataObjectInstance i)
{
	if(value && objectp(value))
    	return value->format_tod();
	else return (string)value;
}

/*
string get_editor_string(void|mixed value, void|Fins.Model.DataObjectInstance i)
{
	werror("TimeField.get_editor_string(%O, %O)\n", value, i);
  string rv = "";
  if(i) rv +=("<input type=\"hidden\" name=\"__old_value_" + name + "\" value=\"" + 
				(value?value->format_tod():"") + "\">" );
  rv += "<input type=\"text\" name=\"" + name + "\" value=\"";
  if(i) rv+=(value?value->format_tod():"");
  rv += "\">";

  return rv;
}
*/


string get_editor_string(void|mixed value, Fins.Model.Field field, void|Fins.Model.DataObjectInstance i)
{
        string rrv = "";
        int def = 0;
        array vals = ({});

        if(!value)
        { 
          def = 1; 
          value = Calendar.now();
        }


        {
          vals = ({});
          foreach(({"hour_no", "minute_no", "second_no"});; string part)
          {
	        string rv = "";
		string current_val = 0;
		int from, to;

                if(value)
                {
		  current_val = value[part]();
		}

		switch(part)
		{
		  case "hour_no":
		    from = 0; to = 23;
		    break;
		  case "minute_no":
		    from = 0; to = 59;
		    break;
		  case "second_no":
		    from = 0; to = 59;
		    break;
		}
		rv += "<select name=\"_" + field->name + "__" + part + "\">\n";
		for(int i = from; i <= to; i++) 
                  rv += "<option " + ((int)current_val == i?"selected":"") + ">" + i + "\n";
		rv += "</select>\n";

		if(!def)
                  rv += "<input type=\"hidden\" name=\"\"__old_value_" + field->name + "__" + part + "\" value=\"" + current_val + "\">";
	
		vals += ({rv});
        }

		rrv += (vals * " : ");
      }
      return rrv;
}


mixed from_form(mapping value, Fins.Model.Field field, void|Fins.Model.DataObjectInstance i)
{
  object c = Calendar.dwim_time(sprintf("%02d:%02d:%02d", (int)value->hour_no, (int)value->minute_no, (int)value->second_no));
        return c;
}