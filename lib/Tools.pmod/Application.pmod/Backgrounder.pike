//! a convenience class that makes it straightforward to write applications that 
//! detatch from the console and enter the background (such as for daemons).
//!
//! @note 
//! This class will use @[fork()] on systems where it is available, however fork-like 
//! semantics should not be assumed, as other methods are employed when fork() is not
//! available in order to achieve the goal of detaching from the controlling console.
//!
//! In particular, developers should not assume that a child process will be created 
//! at all, 

private int in_child = 0;
private int child_pid;

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
//!   when this function returns true (1), this means we're in the foreground process and 
//!   should @[exit()] the program as expeditiously as possible. Otherwise, the process is 
//!   in the background and should continue on with normal operations.
int enter_background(int(0..1) should_we, string logfile, void|int(0..1) quiet)
{
  // no need to attempt to enter the background if we're already there.
  if(in_child) return 0;

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
    
#if constant(fork)
  object c = fork();
  if(!c)
  {
    in_child = 1;
    child_pid = getpid();
  }
  else
  {
    child_pid = c->pid();
  }
#elseif constant(System.FreeConsole)

  child_pid = getpid();

  if(!quiet)
    werror("Daemon pid: %O\n", child_pid);

  int res;
  if((res = System.FreeConsole()))
  {
    // an error occurred while trying to free the console. why? who knows?
    throw(Error.Generic(sprintf("An error occurred while trying to release the console, code=%d\n", res)));
  }
  else
  {
    // we're not really a "child", per se, but we are in the background.
    in_child = 1;
  }
#else
  return 0;
#endif /* constant(fork) */
  
  if(in_child)
  {
    // this is the code we run in the child.
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
}

//! returns true if we're actually the child process.
int in_background()
{
  return in_child;
}

//! get the process object for the child process, if any.
//! 
//! @returns
//!   the process id of the child process.
//!
//! @note
//!   when running in environments that don't have @[fork], such as Windows, 
//!   the child process id will be the current process. Therefore, this method 
//!   should only be used to get the process id for informational purposes.
object get_child_pid()
{
  return child_pid;
}
