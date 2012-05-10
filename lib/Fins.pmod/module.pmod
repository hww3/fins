constant __author = "Bill Welliver <hww3@riverweb.com>";
constant __version = "0.9.5";

#if __VERSION__ >= 7.9.5
#define FINS_MULTI_TENANT 1
#endif

//!
string version()
{
  return "Fins " + __version;
}

int ts;

static void create()
{
  ts = time();
  //werror("bootstrap!\n");

#ifdef FINS_MULTI_TENANT

  // we don't want to do this if it's already been done.
  if(!master()->fins_master)
  {
        object m = my_master();
    //werror("got master!\n");
    m->do_replace_master();
    //werror("replaced master.\n");
      } 
  else
    ; //werror("no master replacement needed!");
#endif
}


#ifdef FINS_MULTI_TENANT

class my_master
{
  inherit "/master": old_master;

  constant multi_tenant_aware = 1;

#define DEFAULT_KEY "_fins_default"
 
  mapping(string:object) handlers = set_weak_flag(([]), Pike.WEAK_VALUES);
  mapping(object:string) handlers_for_thread = set_weak_flag(([]), Pike.WEAK_INDICES);
  constant fins_master = 1;
  int created = 0;
  
  mixed get_fc()
  {
    return fc;
  }
protected mixed `->root_module()
{
  object t = Thread.this_thread();
  object h;
  
  h = get_handler_for_thread(t);
//  werror("root module: %O\n", sizeof(indices(h->root_module)));
  return h->root_module;
} 

protected void `->root_module=(mixed val)
{
  object t = Thread.this_thread();
  object h;
if(!created) return; // evil, but necessary.
  h = get_handler_for_thread(t);
//  if(h && val)
// werror("root module=: %O, %O\n", indices(h->root_module), indices(val));
// werror("%O", backtrace());
// exit(1);
//master()->describe_backtrace(backtrace());
// else
// werror("root module=: %O, %O\n", indices(h), val);
 
  h->root_module = val;      
}

protected mixed `->pike_program_path()
{
  object t = Thread.this_thread();
  object h;
  
  h = get_handler_for_thread(t);
  
  return h->pike_program_path;
}  

protected void `->pike_program_path=(mixed val)
{
  object t = Thread.this_thread();
  object h;
  
  h = get_handler_for_thread(t);

  h->pike_program_path = val;      
}

protected mixed `->pike_module_path()
{
  object t = Thread.this_thread();
  object h;
  
  h = get_handler_for_thread(t);
  
  //werror("module path: %O %O\n", h, h->pike_module_path);
  return h->pike_module_path;
}  

protected void `->pike_module_path=(mixed val)
{
  object t = Thread.this_thread();
  object h;
//werror("module path=: %O\n", val);  
  h = get_handler_for_thread(t);

  h->pike_module_path = val;      
}

protected mixed `->pike_include_path()
{
  object t = Thread.this_thread();
  object h;
  
  h = get_handler_for_thread(t);
  
  return h->pike_include_path;
}  

protected void `->pike_include_path=(mixed val)
{
  object t = Thread.this_thread();
  object h;
  
  h = get_handler_for_thread(t);

  h->pike_include_path = val;      
}

protected mixed `->resolv_cache()
{
  object t = Thread.this_thread();
  object h;
  
  h = get_handler_for_thread(t);
  
  return h->resolv_cache;
}  

protected void `->resolv_cache=(mixed val)
{
  object t = Thread.this_thread();
  object h;
  
  h = get_handler_for_thread(t);

  h->resolv_cache = val;      
}

protected mixed `->dir_cache()
{
  object t = Thread.this_thread();
  object h;
  
  h = get_handler_for_thread(t);
  
  return h->dir_cache;
}  

protected void `->dir_cache=(mixed val)
{
  object t = Thread.this_thread();
  object h;
  
  h = get_handler_for_thread(t);

  h->dir_cache = val;      
}
  
    protected mixed `->fc()
    {
      object t = Thread.this_thread();
      object h;

      h = get_handler_for_thread(t);
//werror("`->fc(%O)\n",indices(h->fc));
      return h->fc;
    }  

    protected void `->fc=(mixed val)
    {
      object t = Thread.this_thread();
      object h;

      h = get_handler_for_thread(t);

      h->fc = val;      
    }

  protected mixed `->programs()
  {
    object t = Thread.this_thread();
    object h;
    
    h = get_handler_for_thread(t);
    
    return h->programs;
  }  
  
  protected void `->programs=(mixed val)
  {
    object t = Thread.this_thread();
    object h;
    
    h = get_handler_for_thread(t);

  //  h->programs = val;      
  }

  protected mixed `->objects()
  {
    object t = Thread.this_thread();
    object h;
    
    h = get_handler_for_thread(t);
    
    return h->objects;
  }  
  
  protected void `->objects=(mixed val)
  {
    object t = Thread.this_thread();
    object h;
    
    h = get_handler_for_thread(t);

  //  h->objects = val;      
  }

  protected mixed `->rev_programs()
  {
    object t = Thread.this_thread();
    object h;
    
    h = get_handler_for_thread(t);
    
    return h->rev_programs;
  }  
  
  protected void `->rev_programs=(mixed val)
  {
    object t = Thread.this_thread();
    object h;
    
    h = get_handler_for_thread(t);

   // h->rev_programs = val;      
  }

  protected mixed `->rev_fc()
  {
    object t = Thread.this_thread();
    object h;
    
    h = get_handler_for_thread(t);
    
    return h->rev_fc;
  }  
  
  protected void `->rev_fc=(mixed val)
  {
    object t = Thread.this_thread();
    object h;
    
    h = get_handler_for_thread(t);

    //h->rev_fc = val;      
  }

  protected mixed `->rev_objects()
  {
    object t = Thread.this_thread();
    object h;
    
    h = get_handler_for_thread(t);
    
    return h->rev_objects;
  }  
  
  protected void `->rev_objects=(mixed val)
  {
    object t = Thread.this_thread();
    object h;
    
    h = get_handler_for_thread(t);

    //h->rev_objects = val;      
  }

  protected mixed `->documentation()
  {
    object t = Thread.this_thread();
    object h;
    
    h = get_handler_for_thread(t);
    
    return h->documentation;
  }  
  
  protected void `->documentation=(mixed val)
  {
    object t = Thread.this_thread();
    object h;
    
    h = get_handler_for_thread(t);

 //   h->documentation = val;      
  }

  protected mixed `->source_cache()
  {
    object t = Thread.this_thread();
    object h;
    
    h = get_handler_for_thread(t);
    
    return h->source_cache;
  }  
  
  protected void `->source_cache=(mixed val)
  {
    object t = Thread.this_thread();
    object h;
    
    h = get_handler_for_thread(t);

//    h->source_cache = val;      
  }

  void do_replace_master()
  {
    replace_master(this);
        if (master_efuns) {
          foreach(master_efuns, string e) {
            if (has_index(this, e)) {
    //          werror("addin %O\n", e);          
              add_constant(e, this[e]);
            } else {
              throw(({ sprintf("Function %O is missing from fins_master.pike.\n",
                               e), backtrace() }));
            }
          }
  }
}

  //!
  protected void create()
  {
    object mm = master();
        
//    add_constant("fins_add_handler", fins_aware_add_handler);  
//handlers_for_thread = ([]);
    set_weak_flag(handlers_for_thread, Pike.WEAK_INDICES);
//    object defaults = MultiTenantCompileContainer(DEFAULT_KEY);
//werror("handlers: %O\n", handlers);
//handlers = ([]);
//werror("handlers: %O\n", handlers);
//    handlers[DEFAULT_KEY] = defaults;

    object o = this_object();

    /* Copy variables from the original master */
    foreach(indices(mm) 
- 
({


"fc",
"rev_programs",
"rev_objects",
"rev_fc",
"programs",
"objects",
"dir_cache",
"source_cache",
"documentation",
"resolv_cache",
"root_module"
})
/* - ({ 
     
      "handler_root_modules",
      "show_if_constant_errors",
      "_master_file_name",
      "inhibit_compile_errors",
      "compilation_mutex",
//      "compat_handler_cache",
      "initial_predefines",
      "system_module_path",
      "fallback_resolver",
      "handler",
      "cflags",
      "ldflags",
      "doc_prefix",
      "mkobj",
      "fname",
      "ver",
      "include_prefix",
      "encoded",
      "newest",
      "load_time",
      "autoreload_on",
      "currentversion",
      "predefines",
      "no_resolv",
      "_pike_file_name",
      "is_pike_master",
      "compat_minor",
      "compat_major",
      "want_warnings",    }) */
     
      , string varname) {
        if(!catch(o[varname] = mm[varname]))
       ;// werror("%O,\n", varname);
      /* Ignore errors when copying functions */
    }

    programs["/master"] = this_program;
    objects[this_program] = o;    
    
    /* make ourselves known */
    add_constant("_master",o);
    /* Move the old efuns to the new object. */
    if (o->master_efuns) {
      foreach(o->master_efuns, string e) {
        if (has_index(o, e)) {
//          werror("addin %O\n", e);          
         // add_constant(e, o[e]);
        } else {
          throw(({ sprintf("Function %O is missing from fins_master.pike.\n",
                           e), backtrace() }));
        }
      }
    } else {
      ::create();
    }

    //werror("created!\n");
    created = 1;
    
    // it appears that some during-master-object-creation initialization logic is wiping out the pre-set variables.
    pike_module_path = mm->pike_module_path;
    pike_program_path = mm->pike_program_path;
    pike_include_path = mm->pike_include_path;
  }
  
  array get_program_path(object|void handler)
  {
//werror("handler: %O=>%O\n", get_handler_for_thread(Thread.this_thread()), get_handler_for_thread(Thread.this_thread())->pike_program_path);
    return pike_program_path;
  }
  
    void add_module_path(string tmp)
    {
      //werror("add_module_path(%O)\n", tmp);
      ::add_module_path(tmp);
    }

  object fins_aware_create_thread(function(mixed ... :void) f, mixed ... args)
  {
    string hn;
    hn = handlers_for_thread[Thread.this_thread()];
    
    return low_create_thread(f, hn, @args);
  }

  object low_create_thread(function(mixed ... :void) f, string handler, mixed ... args)
  {
//werror("low_Create_thread: %O\n", handler);
    object t = Thread.Thread(splice(setup_thread, f), handler, @args);
    return t;
  }

  void setup_thread(string hn, mixed ... args)
  {   
//werror("adding handler %O for %O\n", hn, Thread.this_thread());
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
        if(sizeof(args))
          [a, args] = Array.shift(args);
      }
    }
  }

  object get_handler_for_thread(object thread)
  {
    string hn;
    if(!handlers) // we might get here via __INIT, which means none of the object-global variables are initialized.
    { 
      //werror("settin' up shop\n");
      handlers = set_weak_flag(([]), Pike.WEAK_VALUES);
      if(!handlers_for_thread) handlers_for_thread = set_weak_flag(([]), Pike.WEAK_INDICES);
      handlers[DEFAULT_KEY] = new_handler(DEFAULT_KEY);
    }
//write("handlers: %O %O\n", handlers_for_thread, Thread.this_thread());
    hn = handlers_for_thread[thread];
//write("handler sought: %O from %O\n", hn, (handlers));
    if(hn) return handlers[hn];
    else
    {
//      werror("using default handler.\n");
     return handlers[DEFAULT_KEY];
   }
  }

  void fins_add_handler(string key, object handler)
  {
    handlers[key] = handler;
  }

  object new_handler(string key)
  {
    //werror("handlers: %O\n", handlers);
      object h = MultiTenantCompileContainer(key);
      object d = handlers[DEFAULT_KEY];
      if(!d) // we must be in an old master.
      {
//        if(created) throw("Wowza!\n");
        //werror("we're an old master!\n");
        d = master();
        h->root_module = d->get_root_module();
      }
      else
      {
        //werror("we're not an old master\n");
//        throw("wowza2!\n");
        h->root_module = low_get_root_module();
      }

//werror("path: %O %O\n",d,  d->pike_module_path);
      h->pike_include_path = d->pike_include_path;
      h->pike_program_path = d->pike_program_path;
      
      h->programs["/master"] = this_program;
      h->objects[this_program] = this_object();    

      foreach(reverse(d->pike_module_path);; string p)
      {
        //werror("adding %O\n", p);
        h->add_module_path(p);
      }
//werror("module_path: %O %O\n", h, h->pike_module_path);      
      handlers[key] = h;
      return h;
  }
  
  joinnode low_get_root_module()
   {
     joinnode node;
     // Check for _static_modules.
     mixed static_modules = _static_modules;
     //werror("getting root module()\n");
#ifdef FINS_MULTI_TENANT
return joinnode(({static_modules,  @filter(root_module->joined_modules,
                                lambda(mixed x) {
                                  return objectp(x) && x->is_resolv_dirnode;
                                })  })
, 0);
#else
return joinnode(({static_modules}), 0, 0, "predef::");
#endif
#if 0
     node = joinnode(({ instantiate_static_modules(static_modules),
                        // Copy relevant stuff from the root module.
                    /*    @filter(root_module->joined_modules,
                                lambda(mixed x) {
                                  return objectp(x) && x->is_resolv_dirnode;
                                }) */ }),
                     0,
/*                     root_module->fallback_module*/ 0,
                     "predef::");
#endif
     // FIXME: Is this needed?
     // Kluge to get _static_modules to work at top level.
   //  node->cache->_static_modules = static_modules;

     return node;
   }
  
  class MultiTenantCompileContainer
  {

    string my_key;
  static void create(string _my_key)
  {
    //werror("MultiTenantCompileContainer()\n");
    my_key = _my_key;
  }
  
    array pike_program_path = ({});
    array pike_include_path = ({});
    array pike_module_path = ({});
      
    mapping(string:object|NoValue) fc=([]);    
    mapping(program:string) rev_programs = ([]);
    mapping(object:program) rev_objects = ([]);
    mapping(mixed:string) rev_fc = ([]);
    mapping(string:program|NoValue) programs=([]);
    mapping(program:object) documentation = ([]);
    mapping(program:string) source_cache = ([]);
    mapping (program:object|NoValue) objects=([]);
    mapping(string:multiset(string))dir_cache=([]);
    mapping resolv_cache=([]);
    object root_module;
    
    void add_module_path(string tmp)
    {
//      werror("adding %O\n", tmp);
      
      tmp=normalize_path(combine_path_with_cwd(tmp));
      root_module->add_path(tmp);
      pike_module_path = ({ tmp }) + (pike_module_path - ({ tmp }));
    }
    
    void add_include_path(string tmp)
    {
      tmp=normalize_path(combine_path_with_cwd(tmp));
      pike_include_path-=({tmp});
      pike_include_path=({tmp})+pike_include_path;
    }
    
    void add_program_path(string tmp)
    {
      tmp=normalize_path(combine_path_with_cwd(tmp));
      pike_program_path-=({tmp});
      pike_program_path=({tmp})+pike_program_path;
//werror("program_path: %O->%O\n", this, pike_program_path);
    }
    
    string _sprintf(int t)
    {
      return t=='O' && sprintf("MultiTenantCompileContainer(%O)",my_key);
    }
  } 
}

#endif /* MULTI_TENANT */
