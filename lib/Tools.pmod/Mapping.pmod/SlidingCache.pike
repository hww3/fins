inherit .MappingCache;


//! an implementation of a mapping that "forgets" entries after a certain time has elapsed since the last access/update of a given key.


//!
	protected mixed `[](mixed k)
	{
	  mixed q;
	
	  if(!has_index(vals, k)) return ([])[0];
	  
	  q = vals[k];
	
	  if(q[0] < time()) // have we overstayed our welcome?
	  {
	     m_delete(vals, k);
	     return ([])[0];
	  } 
	  else
	  {
	    q[0] = time() + timeout;
	    return q[1];
    }
	}
