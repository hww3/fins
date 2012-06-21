//! a convenience class that makes it straightforward to write applications that 
//! detatch from the console and enter the background (such as for daemons).
//!
//! @note 
//! this class requires @[fork()] to function properly. If @[fork()] is not available,
//! this class will behave as though it had entered the background, allowing the application
//! to continue running normally without detaching.

private int in_child = 0;
private object child_pid;

//! 
//! @param should_we
//!   an integer that determines whether the process should be backgrounded or not
//!
//! @param logfile
//!   a string pointing to a log file that stdout and stderr will be written to
//!
//! @returns
//!    1 if the parent has successfully backgrounded a child, 0 if already in the background 
//!    or don't need to enter the background.
//!
//! @note
//!   when this function returns true (1), this means we're in the foreground process and should 
//!   @[exit()] the program as expeditiously as possible.
int enter_background(int(0..1) should_we, string logfile, void|int(0..1) quiet)
{
  // no need to attempt to enter the background if we're already there.
  if(in_child) return 0;
  
#if constant(fork)
  if(!should_we)
    return 0;

  if(!quiet)
  {
    write("Entering Daemon mode...\n");
    write("Directing output to %s.\n", logfile);
  }
  
  // first, we attempt to open the log file; if we can't, bail out.
  object lf;
  mixed e = catch(lf = Stdio.File(logfile, "crwa"));
  if(e) 
  {
    werror("Unable to open log file: " + Error.mkerror(e)->message());
    werror("Exiting.\n");
    exit(1);
  }
  
  child_pid = fork();
  
  if(!child_pid)
  {
    // this is the code we run in the child.
    in_child = 1;
    Stdio.stdin.close();
    Stdio.stdin.open("/dev/null", "crwa");
    Stdio.stdout.close();
    Stdio.stdout.open(logfile, "crwa");
    Stdio.stderr.close();
    Stdio.stderr.open(logfile, "crwa");    
    return 0;
  }
  else
  {
    if(!quiet)
      werror("Daemon pid: %O\n", child_pid->pid());
    return 1;
  }
  
#endif /* constant(fork) */
  return 0;
}

//! returns true if we're actually the child process.
int in_background()
{
  return in_child;
}

//! get the process object for the child process, if any.
//! 
//! @returns
//!   a @[Process.create_process] object representing the backgrounded child.
object get_child_pid()
{
  return child_pid;
}