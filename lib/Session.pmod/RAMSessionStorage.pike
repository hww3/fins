inherit .SessionStorage;

mapping sessions = ([]);
object log = Tools.Logging.get_logger("session.ramsessionstorage");


void create()
{
}

void clean_sessions(int default_timeout)
{
  int t = time();

  foreach(sessions; string sid; array stor)
    if((stor[0] + default_timeout) < t)
      m_delete(sessions, sid);
}

mixed get(string sessionid)
{
  .Session data;
  mixed d;

  array sess = sessions[sessionid];

  if(sess)
  {
    d = sess[1];
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
  return m_delete(sessions, sessionid);
}

void set(string sessionid, .Session data, int timeout)
{
  log->info("storing session, sessionid=<%s>, data=<%O>", sessionid, data);

  sessions[sessionid] = ({ time(), data->data });

  log->info("stored session, sessionid=<%s>", sessionid);

  return;
}
