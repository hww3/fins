constant description = "Administrative Tool for Fins.";

mapping populate_commands()
{
  mapping commands = ([]);

  foreach(values(Fins.AdminTools);; program p)
  {
    if(p->fins_command)
      commands[p->fins_command] = p;
  }
  return commands;
}

int main(int argc, array argv)
{
   mapping commands;

   commands = populate_commands();

   if(!argv || sizeof(argv) < 2)
   {
     werror("invalid arguments. usage: pike -x fins [command]\n");
     return 1;
   }

   program meth;

   string command = argv[1];

   if(commands[command])
     meth = commands[command];
   else
   {
     werror("unknown command \"%s\".\n", command);
     werror("valid commands include: %s\n", sort(indices(commands)) * ", ");
     return 1;
   }

   array newargs = ({});
   if(sizeof(argv) > 2) newargs = argv[2..];

   object cmd = meth(newargs);

   int x = cmd->run();

   return x;
}
