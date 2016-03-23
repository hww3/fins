inherit .Appender;

object output = Stdio.stdout;

protected void create(mapping|void config)
{
  if(!config) config = ([]);
  ::create(config);
}
