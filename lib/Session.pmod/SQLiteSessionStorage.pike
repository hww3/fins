inherit .SessionStorage;

int writing_session = 0;

protected string storage_dir;
protected object sql;

object log = Tools.Logging.get_logger("session.sqlitesessionstorage");

void create()
{
}

void clean_sessions(int default_timeout)
{
  sql->query("DELETE FROM SESSIONS WHERE timeout + " + default_timeout + " < CURRENT_TIMESTAMP");
}

//! this is the pathname of the database file, not the full SQL url.
void set_storagedir(string dbpath)
{
  mixed e;
  e = catch 
  {
    sql = Sql.Sql("sqlite://" + dbpath);
  };
  if(e) throw(Error.Generic("Unable to create session storage database " + dbpath + ".\n"));
  storage_dir = dbpath;

  mixed rs = sql->query("PRAGMA table_info(SESSIONS)");
  if(!rs || !sizeof(rs))
  {
    werror("creating sessions table...\n");
    sql->query("CREATE TABLE SESSIONS(sessionid varchar(15) PRIMARY KEY, data text, timeout timestamp)");
  }
}

mixed get(string sessionid)
{
  .Session data;
  string p;
  mixed d;

  array res = sql->query("SELECT * FROM SESSIONS WHERE sessionid='" + sessionid + "'");

  if(sizeof(res))
  {
    p = res[0]->data;
    d = decode_value(MIME.decode_base64(p));
  }
  else
  {
    return 0;
  }

  data = .Session(sessionid);
  data->data = d;

  return data;
}

int expunge(string sessionid)
{
  sql->query("DELETE FROM SESSIONS WHERE sessionid='" + sessionid + "'");
  return 1;
}

void set(string sessionid, .Session data, int timeout)
{
  log->info("storing session, sessionid=<%s>, data=<%O>", sessionid, data);
   string d = MIME.encode_base64(encode_value(data->data)); 

  sql->query("INSERT OR REPLACE INTO SESSIONS (sessionid, data, timeout) VALUES('" + 
    sessionid + "','" + d + "', CURRENT_TIMESTAMP)");
  log->info("stored session, sessionid=<%s>", sessionid);

   return;
}
