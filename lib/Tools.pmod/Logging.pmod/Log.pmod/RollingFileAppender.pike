//! A File Appender that rolls a logfile before it gets too big, and keeps a certain number of past logs.

inherit .FileAppender;

//! config setting
int max_file_size;

//! config setting
int max_backup;

protected int current_size;
protected int current_backup;

void create(mapping|void config)
{
  ::create(config);
  
  // defaults of 100kb max file size and 1 backup file.
  if(!config->max_file_size)
    config->max_file_size = "100kb";
  if(!(int)config->max_backup)
    config->max_backup = "1";
    
  max_file_size = Tools.String.parse_filesize(config->max_file_size);
  max_backup = (int)config->max_backup;
  
  current_size = output->stat()->size;
  
}

protected object lock = Thread.Mutex();

protected int do_write(string s)
{

  // we want the sensitive portion of this method (the part that determines whether a roll
  // is needed and then does it) is only happening in one thread at a time.
  object key = lock->lock();
  int size = sizeof(s);
  if(size >= max_file_size)
  {
    werror("*** WARNING: RollingFileAppender: Log message is greater than maximum log file size; truncating it to fit.\n");
    s = s[0..max_file_size-1];
    size = sizeof(s);
  }
  
  if(current_size + size > max_file_size)
    roll();
  
  current_size += size;

  key = 0;

  return ::do_write(s);
}

void roll()
{ 
  if(!current_backup)
  {
    calc_current_backup();
  }
  
  if(current_backup == max_backup)
  {
    rm(file + "." + current_backup);
  }
  else
  {
    current_backup++;
  }
  
  int i = current_backup;
  while(i > 0)
  {
    string ofn = file;
    if(i>1) ofn += ("." + (i-1));
    
    if(file_stat(ofn))
    {
    //  werror("moving " + ofn +" to " + file + "." + (i) + "\n");
      mv(ofn, file + "." +  i);
    }
    i--;
  }
  
  reopen_file();
}

protected void reopen_file()
{
  output = Stdio.File(file, "cwa");
  current_size = output->stat()->size;
}
protected void calc_current_backup()
{
  for(int i = max_backup; i > 0; i--)
  {
    if(file_stat(file + "." + i))
    {
      current_backup = i;
      return 0;
    }
  }
  
  current_backup = 0;
  return 0;
}