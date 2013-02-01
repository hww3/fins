inherit .Renderer;

string get_display_string(void|mixed value, Fins.Model.Field field, void|Fins.Model.DataObjectInstance i)
{
	if(value && objectp(value))
    	return value->format_ymd();
	else return (string)value;
}

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
        foreach(({"month_no", "month_day", "year_no"});; string part)
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
		  case "month_no":
		    from = 1; to = 12;
		    break;
		  case "year_no":
		    object cy;
		    if(current_val) cy = Calendar.ISO.Year(current_val); else cy = Calendar.ISO.Year();
		    from = (cy - 80)->year_no(); to = (cy + 20)->year_no();
		    break;
		  case "month_day":
		    from = 1; to = 31;
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

	rrv += (vals * " / ");

      return rrv;
}


mixed from_form(mapping value, Fins.Model.Field field, void|Fins.Model.DataObjectInstance i)
{
  object c = Calendar.dwim_day(sprintf("%04d-%02d-%02d", (int)value->year_no, (int)value->month_no, (int)value->month_day));
        return c;
}

