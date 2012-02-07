constant __author = "Bill Welliver <hww3@riverweb.com>";
constant __version = "0.4";

//! anyone remember what this is used for? Perhaps for something related to module installation?
constant __components = ({
  "./Fins.pmod/",
  "./Fins.pmod/Application.pike",
  "./Fins.pmod/Configuration.pike",
  "./Fins.pmod/FinsController.pike",
  "./Fins.pmod/FinsModel.pike",
  "./Fins.pmod/Loader.pmod",
  "./Fins.pmod/Request.pike",
  "./Fins.pmod/Response.pike",
  "./Fins.pmod/Model.pmod/",
  "./Fins.pmod/Model.pmod/Criteria.pike",
  "./Fins.pmod/Model.pmod/DataModelContext.pike",
  "./Fins.pmod/Model.pmod/DataObject.pike",
  "./Fins.pmod/Model.pmod/DataObjectInstance.pike",
  "./Fins.pmod/Model.pmod/DateField.pike",
  "./Fins.pmod/Model.pmod/DateTimeField.pike",
  "./Fins.pmod/Model.pmod/Field.pike",
  "./Fins.pmod/Model.pmod/FloatField.pike",
  "./Fins.pmod/Model.pmod/Repository.pike",
  "./Fins.pmod/Model.pmod/ForeignKeyReference.pike",
  "./Fins.pmod/Model.pmod/IntField.pike",
  "./Fins.pmod/Model.pmod/InverseForeignKeyReference.pike",
  "./Fins.pmod/Model.pmod/KeyReference.pike",
  "./Fins.pmod/Model.pmod/LikeCriteria.pike",
  "./Fins.pmod/Model.pmod/ObjectArray.pike",
  "./Fins.pmod/Model.pmod/PrimaryKeyField.pike",
  "./Fins.pmod/Model.pmod/Relationship.pike",
  "./Fins.pmod/Model.pmod/StringField.pike",
  "./Fins.pmod/Model.pmod/TimeField.pike",
  "./Fins.pmod/Model.pmod/TransformField.pike",
  "./Fins.pmod/Model.pmod/Undefined_Value.pmod",
  "./Fins.pmod/Model.pmod/module.pmod",
  "./Fins.pmod/Model.pmod/MultiKeyReference.pike",
  "./Fins.pmod/Model.pmod/MultiObjectArray.pike",
  "./Fins.pmod/Model.pmod/CacheField.pike",
  "./Fins.pmod/Model.pmod/Personality.pmod/",
  "./Fins.pmod/Model.pmod/Personality.pmod/Personality.pike",
  "./Fins.pmod/Model.pmod/Personality.pmod/SQLite.pike",
  "./Fins.pmod/Model.pmod/Personality.pmod/mysql.pike",
  "./Fins.pmod/Model.pmod/Personality.pmod/postgres.pike",
  "./Fins.pmod/Model.pmod/",
  "./Fins.pmod/Model.pmod/StringField.pike.save",
  "./Fins.pmod/Model.pmod/DirectAccessInstance.pike",
  "./Fins.pmod/Model.pmod/BinaryStringField.pike",
  "./Fins.pmod/Model.pmod/LimitCriteria.pike",
  "./Fins.pmod/Model.pmod/CompoundCriteria.pike",
  "./Fins.pmod/Model.pmod/AndCriteria.pike",
  "./Fins.pmod/Model.pmod/NotCriteria.pike",
  "./Fins.pmod/Template.pmod/",
  "./Fins.pmod/Template.pmod/Simple.pike",
  "./Fins.pmod/Template.pmod/Template.pike",
  "./Fins.pmod/Template.pmod/TemplateContext.pike",
  "./Fins.pmod/Template.pmod/TemplateData.pike",
  "./Fins.pmod/Template.pmod/XSLT.pike",
  "./Fins.pmod/Template.pmod/module.pmod",
  "./Fins.pmod/Template.pmod/Basic.pike",
  "./Fins.pmod/Template.pmod/View.pike",
  "./Fins.pmod/",
  "./Fins.pmod/FinsView.pike",
  "./Fins.pmod/FinsBase.pike",
  "./Fins.pmod/FinsCache.pike",
  "./Fins.pmod/FCGIRequest.pike",
  "./Fins.pmod/HTTPRequest.pike",
  "./Fins.pmod/XMLRPCController.pike",
  "./Fins.pmod/Helpers.pmod/",
  "./Fins.pmod/Helpers.pmod/Runner.pike",
  "./Fins.pmod/Helpers.pmod/Macros.pmod/",
  "./Fins.pmod/Helpers.pmod/Macros.pmod/JavaScript.pike",
  "./Fins.pmod/Helpers.pmod/Macros.pmod/Basic.pike",
  "./Fins.pmod/Helpers.pmod/Macros.pmod/Base.pike",
  "./Fins.pmod/",
  "./Fins.pmod/FinServe.pike",
  "./Fins.pmod/FinsPackage.pmod",
  "./Fins.pmod/SCGIRequest.pike",
  "./Fins.pmod/DocController.pike",
  "./Fins.pmod/module.pmod",
  "./Fins.pmod/PackageInstaller.pmod",
  "./Fins.pmod/JSONRPCController.pike",
  "./Session.pmod/",
  "./Session.pmod/FileSessionStorage.pike",
  "./Session.pmod/Session.pike",
  "./Session.pmod/SessionManager.pike",
  "./Session.pmod/SessionStorage.pike",
  "./Session.pmod/SQLiteSessionStorage.pike",
  "./Session.pmod/RAMSessionStorage.pike",
  "./Tools.pmod/Logging.pmod/Log.pmod/",
  "./Tools.pmod/Logging.pmod/Log.pmod/module.pmod",
  "./Tools.pmod/Logging.pmod/Log.pmod/Logger.pike",
  "./Tools.pmod/JSON.pmod/",
  "./Tools.pmod/JSON.pmod/JSONArray.pike",
  "./Tools.pmod/JSON.pmod/JSONObject.pike",
  "./Tools.pmod/JSON.pmod/JSONTokener.pike",
  "./Tools.pmod/JSON.pmod/JSONUtils.pmod",
  "./Tools.pmod/JSON.pmod/NULLObject.pmod",
  "./Tools.pmod/JSON.pmod/module.pmod",
  "./Tools.pmod/JSON.pmod/RPC.pmod",
  "./Tools.pmod/",
  "./Tools.pmod/Tar.pmod"
 });

//!
string version()
{
  return "Fins " + __version;
}

static void create()
{
  werror("bootstrap!\n");
  werror("replacing master!\n");
  object m = my_master();
 replace_master(m);
}

class my_master
{
  object mm = (object)"/master";

  inherit "/master": old_master;

  mapping(string:object) handlers = ([]);
  mapping(object:string) handlers_for_thread = ([]);

  function orig_compile = predef::compile;
  function orig_compile_string = predef::compile_string;
  function orig_compile_file = predef::compile_file;

  //!
  void create()
  {
    add_constant("compile", fins_aware_compile);
    add_constant("compile_string", fins_aware_compile_string);
    add_constant("compile_file", fins_aware_compile_file);
    add_constant("create_thread", fins_aware_create_thread);
//    add_constant("fins_add_handler", fins_aware_add_handler);  
    set_weak_flag(handlers_for_thread, Pike.WEAK_INDICES);

    object o = this_object();
    /* Copy variables from the original master */
    foreach(indices(mm), string varname) {
      catch(o[varname] = mm[varname]);
      /* Ignore errors when copying functions */
    }
    werror("programs: %O\n", programs);
    programs = ([]);
    programs["/master"] = object_program(o);
//    program_names[object_program(o)] = "/master";
 //   objects[object_program(o)] = o;
    /* make ourselves known */
    add_constant("_master",o);
    /* Move the old efuns to the new object. */
    if (o->master_efuns) {
      foreach(o->master_efuns, string e) {
        if (has_index(o, e)) {
          add_constant(e, o[e]);
        } else {
          throw(({ sprintf("Function %O is missing from caudium_master.pike.\n",
                           e), backtrace() }));
        }
      }
    } else {
      ::create();
    }
  }
  
  array get_program_path(object|void handler)
  {
    
    if(!handler)
      handler = get_handler_for_thread(Thread.this_thread());
    return handler->pike_program_path;
  }
  
  program low_cast_to_program(string pname,
                              string current_file,
                              object|void handler,
                              void|int mkobj)
  {
      if(!handler)
        handler = get_handler_for_thread(Thread.this_thread());
        
      werror("> low_cast_to_program(%s, %s, %O)\n", (string)pname, (string)current_file, handler);
      if(handler) werror(" program path: %s", handler->pike_program_path *", ");
      return ::low_cast_to_program(pname, current_file, handler, mkobj);
  }
  
  program fins_aware_compile_file(string filename, object|void handler, void|program p, void|object o)
  {
    werror("___ COMPILE_FILE(%O)\n", filename);
    if(!handler) handler = get_handler_for_thread(Thread.this_thread());  
    return orig_compile_file(filename, handler, p, o);    
  }

program fins_aware_compile_string(string source, void|string filename, object|void handler, void|program p, void|object o, void|int _show_if_constant_errors)
{
  werror("___ COMPILE_STRING(%O)\n", source);
  if(!handler) handler = get_handler_for_thread(Thread.this_thread());  
  return orig_compile_string(source, filename, handler, p, o, _show_if_constant_errors);  
}

  program fins_aware_compile(string source, object|void handler, mixed ... args)
  {
    werror("___ COMPILE(%O)\n", source);
    if(!handler) handler = get_handler_for_thread(Thread.this_thread());  
    return orig_compile(source, handler, @args);
  }

  object fins_aware_create_thread(function(mixed ... :void) f, mixed ... args)
  {
    string hn;
    hn = handlers_for_thread[Thread.this_thread()];

    object t = Thread.Thread(splice(setup_thread, f), hn, @args);
    handlers_for_thread[t] = hn;
  }

  void setup_thread(string hn, mixed ... args)
  {
      handlers_for_thread[Thread.this_thread()] = hn;
  }

  class splice(function ... funcs)
  {
    static void `()(mixed ... args)
    {
      foreach(funcs;; function f)
      {
        mixed a;
        f(@args);
        [a, args] = Array.shift(args);
      }
    }
  }

  object get_handler_for_thread(object thread)
  {
    string hn;
write("handlers: %O %O\n", handlers_for_thread, Thread.this_thread());
    hn = handlers_for_thread[thread];
write("handler sought: %O from %O\n", hn, handlers[hn]);
    if(hn) return handlers[hn];
    else return 0;
  }

  void fins_add_handler(string key, object handler)
  {
    handlers[key] = handler;
  }


  class MultiTenantResolver
  {
    inherit CompatResolver;
    string my_key;

    protected void create(mixed key, CompatResolver|void fallback_resolver)
    {
       my_key = key;
       ::create(0, fallback_resolver);
    }

      mixed resolv(string identifier, string|void current_file,
               object|void current_handler)
  {
    werror("%s.", (string)my_key);
    return ::resolv(identifier, current_file, current_handler);

  }

    string _sprintf(int t)
    {
      return t=='O' && sprintf("MultiTenantResolver(%O)",my_key);
    }

  }
}

