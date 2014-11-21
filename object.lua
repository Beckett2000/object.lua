-- object.lua - (Beckett Dunning 2014) - Object oriented lua programming 
---------- ---------- ---------- ---------- ----------

local Lib_Version = 2.75 -- object unified environment (stable)

-- This script adds an Object Oriented aproach to Lua Programming Calls. Traditionally in lua, there is little notion of inheritance or classes. This script allows for Javascript like progamming calls in chained sequence as opposed to the traditional structure of raw Lua

object,libs = {},{} local _object,object = object, {} -- aliases object class / stores libraries
local meta = {__index = self,__type = "object class", __version = Lib_Version,
__tostring = function(self) -- gives objects a tostring native behavior
   local vals = {} for k,_ in pairs(self) do table.insert(vals,tostring(k)) end
   table.sort(vals) return "(object baseClass):["..table.concat(vals,", ").."]" end,
__call = function(self,...) -- creates object class from initializer
 return self.init and self:init(...) or self:new(...) end } 
setmetatable(meta,{__type = "object meta", __index = object }) setmetatable(object,meta)

-- Local variable declaration for speed improvement
local type,pairs,table,unpack,setmetatable,getmetatable,object = 
 type,pairs,table,unpack,setmetatable,getmetatable,object
local abs,pi,cos,min,max,pow,acos,floor,sqrt = math.abs,math.pi,math.cos,
 math.min,math.max, math.pow,math.acos,math.floor,math.sqrt

-- accepted metatable keys to be parsed from object
local meta_tables,meta_ext = { __index = true, __tostring = true,  __newindex = true, __call = true, __add = true, __sub = true, __mul = true, __div = true, __unm = true, __concat = true, __len = true, __eq = true, __lt = true, __le = true}, { __type = true, __version = true, __namespace = true}

------------ ------------ ------------ ------------ ------------ ------------ ------------ 
-- Object Extension Module :init() - (object:ext()) ----------- ----------- ---------

local function initExtensionLayer(self) -- (private) initializes object extension layer
 local meta = getmetatable(self) if not meta.__exIndex then 
  meta.__exIndex = {} setmetatable(meta.__exIndex,{__type = "extLayer"})
 elseif meta.__exIndex == true then local metaSb = {} -- makes new layer referencing superclass 
  for k,v in pairs(getmetatable(meta.__proto)) do metaSb[k] = v end 
  meta.__exIndex = {} setmetatable(meta.__exIndex,metaSb) end
 local layer,super = meta.__exIndex,{} setmetatable(super,{__index = meta.__index});  
 getmetatable(layer).__index = function(layer,key) -- (lazy unpack) instantiates extensions
  if super.ext and super.ext[key] then layer[key] = super.ext[key](self) return layer[key] end
  return super[key] end meta.__index = layer return meta.__exIndex end -- returns: extension layer

------------------------------------------------------------------
-- Primative Object Constructor -> object:new() | object()

-- The new metamethods for an object subclass are passed at the time of initialization. If metatable elements are detected, they are removed from the objects methods and added to its metatable. The imput object as well as the output object retured can be used to add new methods and values to a class, but new metamethods will not be detected after initial initialization.

-- object.init = function(self) end -- Called upon object initiation

object.new = function(super,self) -- (object) - base constructor 
 local meta,metaS = {},getmetatable(super) meta.__index = super == object and metaS.__proto or super
 meta.__proto,meta.__exIndex = meta.__index,metaS.__exIndex and true for k,v in pairs(metaS) do 
  if not meta[k] then meta[k] = type(v) ~= "table" and v or object.copy(v) end end
 meta.__type = super == _object and "object" or meta.__type 
 self = type(self) == "table" and self or {} for key,value in pairs(self) do -- (meta key parsing)
  if meta_tables[key] or meta_ext[key] then meta[key],self[key] = value, nil end end 
 setmetatable(self,meta) initExtensionLayer(self) -- creates and initializes object meta
 return self end -- returns: new object instance

------------ ------------ ------------ ------------ ------------ ------------ ------------ 
-- object extension module -> object:extension():method() | object.extension:method()

-- The extensions module creates extensions which can perform various functions which normally exceed the standard bounds of lua. This is not one single method, but more a collection of meethods which together extend the object class. Extensions are not private to objects, and any lua table can adopt an extension. Exposed extensions are below ...

-- [ :ext():prefix() / :ext():dictionary() ] These methods both create data structures which pass their selfness to an internal method call as their root object. Dictionary extensions store data internally in their meta.__dataStore and are pulled into an object when edited, while prefix extensions reference the keys in the root object which begn with their key name. Declaration and usage is below...
------------ ------------ ------------ ------------ ------------ ------------ ------------

local function getExtStore(self) -- (private) points to / creates object.ext store
local target,ext if self ~= object then -- stores extensions in __exIndex of metatable
 local meta,layer = getmetatable(self) if not meta then meta = {} setmetatable(self,meta) end
 if meta.__exIndex then layer = meta.__exIndex else layer = initExtensionLayer(self) end       
 target,ext = layer, meta.__proto and meta.__proto.ext or nil
else target,ext = self,self.ext end -- stores extensions in self 
if not rawget(target,"ext") then -- creates .ext index if not present
 meta = {} target.ext = {} local cache = ext or object.ext 
 for k,v in pairs(getmetatable(cache)) do meta[k] = v end meta.__index,meta.__proto = ext,ext; 
setmetatable(target.ext,meta) end return target.ext end

local function _extSetter(ext,wrapper) -- (private) creates setters ext().setter(val).key
 return function(self,name,method) -- (static) creates wrapper for calls
  local store = self if self ~= ext then store = getExtStore(self) store = store(self) end
  if not name and not method then -- determines _:ext:prefix() method output
    local caller = {} setmetatable(caller,{ -- creates _:ext:wrapper() calling object
    __newindex = function(alias,key,value) store[key] = wrapper(key,value) end,
    __call = function(...) return wrapper(name,method)(store)(...) end }) return caller
  else store[tostring(name)] = wrapper(name,method or function() end) end end end

------------ ------------ ------------ ------------ ------------ ------------ ------------
object.ext = {} setmetatable(object.ext, { -- .ext() is a dynamic module

__tostring = function(self) -- reports details when converted to string
 local names,layer,name = {},self while layer do for k,v in pairs(layer) do 
   table.insert(names,tostring(k)..":("..getmetatable(v(object)).__type..")") end 
  layer = getmetatable(layer).__proto end table.sort(names)
 return "(ext cache):{"..table.concat(names,", ").."}" end,

__index = function(ext,key) return end, -- object.ext:method()
__call = function(ext,obj)  -- invoked when calling object:ext()
 if not obj then error("invalid arg. no.1 (lua table) to object.ext().",2) return end 
 local extender,meta = {},{ -- extender -> returned by object:ext() 
    
 __newindex = function(self,key,value) -- [newindex] object.ext[key] set / object[key] unwrapped
  local store = getExtStore(obj) store[key],obj[key] = value, value(obj) end,
 __index = function(extension,key) local ext = {} -- handles indexes to _:ext()   
        
   ---------- ---------- ---------- ---------- ---------- ---------- ---------- ----------
   -- [ext().prefix()] - Declare: :ext():|prefix|().name = method / :ext():|prefix|(name,method)
   -- Declare Key: :|prefix|().|key| = method / .|prefix||key| = method
   -- Call Key: object:prefix():key() / object.prefix:key() / object:|prefix||key|()     
   ---------- ---------- ---------- ---------- ---------- ---------- ---------- ----------
   ext.prefix = _extSetter(extension, function(name,method) -- (passUp) object indexer / sorter
    return function(self)  local extension,meta = {},{ __type = "ext.prefix", 

    __tostring = function(pointer) -- (ext) returns prefix descriptor string
     local level,list,entry,key,val = self,{} while level do key,val = next(level)
     while val do if string.find(key,"^"..name) then entry = string.gsub(key,"^"..name,"") 
       if entry ~= "" then for i = 1,#list do if list[i] == entry then entry = "" break end end end
       list[#list + 1] = entry ~= "" and entry or nil end key,val = next(level,key) end       
     level = getmetatable(level) level = level and level.__proto end table.sort(list)
     return "(ext.prefix _:"..name.."|...|):{"..table.concat(list,", ").."}" end,      

    __newindex = function(pointer,key,value) -- declaration: obj.|prefix|.|name| = method                                        
     local entry,internal = name..tostring(key) if not value and not rawget(self,entry) then
      internal = false error("Extension cannot modify superclass.",2) else internal = true end
     self[entry] = (not value and internal) and nil or value end,

    __index = function(pointer,key) -- indexing statement: _.|prefix|:|name|()
     local path = self[name..tostring(key)] if path then return function(v,...)        
      if v == pointer then return path(self,...) else return path(v,...) end end end end,       

    __call = function(pointer,obj,...) -- calling statement: _:|prefix|() / _:|prefix|():|name|()               
     if not obj then return end local extra = select("#",...)
     if obj == pointer and extra == 0 then return pointer
     elseif extra == 0 and type(obj) == "table" then 
      return obj[name] and obj[name] or object.ext[name](obj)                      
     else return method(obj,...) end end 

    } setmetatable(extension,meta) return extension end end )

   ---------- ---------- ---------- ---------- ---------- ---------- ---------- ----------     
   -- [ext().dictionary()] - Declare: :ext():|dict|().name = method / :ext():|dict|(name,method)
   -- Declare Key: :|dict|().|key| = method -- Call Key: object:dict():key() / object.dict:key()
   ---------- ---------- ---------- ---------- ---------- ---------- ---------- ----------
   ext.dictionary = _extSetter(extension, function(name,method) -- (passUp) dictionary object
    local localID = function() end return function(self) local extension,store = {},{}
                
     local meta = getmetatable(self) local proto = meta and meta.__proto        
     if proto and proto[name] then local metaS = getmetatable(proto[name]) 
      if metaS.__id == localID then setmetatable(store,{__index = metaS.__dataStore}) end end                
     local meta = { __type = "ext.dict", __dataStore = store, __id = localID,

     __tostring = function(pointer) -- (ext) returns dict descriptor string           
      local level,list,entry,key,val = store,{} while level do key,val = next(level)
       while val do entry = true for i = 1,#list do if list[i] == key then 
        entry = false break end end if entry then table.insert(list,key) end 
       key,val = next(level,key) end level = getmetatable(level) 
       level = level and level.__index end table.sort(list)
      return "(ext.dict _."..name..":|...|):{"..table.concat(list,", ").."}" end,              

    __newindex = function(pointer,key,value) -- declaration: obj.|dict|.|name| = method
     if not rawget(self,name) then self[name] = pointer local metaS = getmetatable(self) 
      if metaS and metaS.__exIndex then metaS.__exIndex[name] = nil end end -- moves dict to self
     local entry,internal = tostring(key) if not value and not rawget(store,entry) then
      internal = false error("Extension cannot modify superclass.",2) else internal = true end
     store[entry] = (not value and internal) and nil or value end,

    __index = function(pointer,key) -- indexing statement: _.|dict|:|name|()
     local path = store[key] if path then return function(v,...)        
     if v == pointer then return path(self,...) else return path(v,...) end end end end,       

    __call = function(pointer,obj,...) -- calling statement: _:|prefix|() / _:|prefix|():|name|()               
     if not obj then return end local extra = select("#",...)
     if obj == pointer and extra == 0 then return pointer
     elseif extra == 0 and type(obj) == "table" then 
      return obj[name] and obj[name] or object.ext[name](obj)                      
     else return method(obj,...) end end 

    } setmetatable(extension,meta) return extension end end )
   
   ---------- ---------- ---------- ----------           
   ext.dict = ext.dictionary 
        
  return ext[key] end } -- returns: pointer to method in entry
 setmetatable(extender,meta) return extender end })

-------------------- -------------------- --------------------     
-- (_.insert, _.remove) - Prefix Block Extensions
------------------- - -------------------- --------------------     
-- These hardcoded prefix extensions search for the insert or remove prefix when referenced to lcreate custom method call blocks. Using the declaration syntax, subclasses can append custom local methods to these extensions. The usage structure is below:
-- Declaration: object.|insert/remove|Extension IE: object.insertValue
-- Calling Examples: object:insertValue() object.insert:Value() object:insert():Value() 
-------------------- -------------------- --------------------     

object:ext():prefix().remove = table.remove; object:ext():prefix().insert = table.insert

-- object.insert|...| -- These functions are used to add data to the array portion of an object. All the methods can be referenced from calling their direct method name or by using the object:insert() block call connections -> object:insert():First(values):Last(values).

object.insert.First = function(self,value,...) -- adds values to beginning of table
 local capacity = 0 if value then -- adds first value to table
  capacity = capacity + 1 table.insert(self,capacity,value) end 
 local extra = select("#",...) if extra > 0 then local args,arg = {...}
  for i = 1, extra do arg = args[i] -- adds extra arguments with table
   if arg then capacity = capacity + 1 table.insert(self,capacity,arg) end end end
 return self end -- returns: subject table of call

object.insert.Last = function(self,value,...) -- adds values to end of table
 local capacity = #self if value then -- adds first value to table
  capacity = capacity + 1 self[capacity] = value end 
 local extra = select("#",...) if extra > 0 then local args,arg = {...}
  for i = 1, extra do arg = args[i] -- adds extra arguments with table
   if arg then capacity = capacity + 1 self[capacity] = arg end end end
 return self end -- returns: subject table of call

object.insert.AtIndex = function(self,index,val,...) -- adds values at index in table
 if index < 1 then index = 1 else local max = #self if index > max then index = max + 1 end end
 if val then table.insert(self,index,val) index = index + 1 end -- adds first value to table
 local extra = select("#",...) if extra > 0 then local args,arg = {...}
  for i = 1, extra do arg = args[i] -- adds extra arguments with table
   if arg then table.insert(self,index,arg) index = index + 1 end end end
 return self end -- returns: subject table of call
        
-- object.remove|...| -- These functions are used to remove data from the array portion of an object. All the methods can be referenced from calling their direct method name or by using the object:remove() 

object.remove.Index = function(self,index) -- bridged for table.remove method
 return table.remove(self,index) end -- returns: table.remove output

object.remove.Indexies = function(self,...) -- removes vararg of indexies from table
 local out,length = {},select("#",...) if length == 0 then return end
 local args = {...} table.sort(args, function(a,b) return a > b and true or false end)
 local pos,last,index = 0 for i = 1,length do index = args[i]
  if index ~= last and self[index] then pos = pos + 1 out[pos] = table.remove(self,index)
  last = index end end return unpack(out) end -- returns: vararg of removed values

object.remove.First = function(self,number) -- removes number of entries from beginning of table
 if not number or number == 1 or number == -1 then return table.remove(self,1) 
 elseif number == 0 then return false end local out = {} number = abs(number) 
 for i = 1,number do out[i] = table.remove(self,1) end
 return unpack(out) end -- returns: vararg of removed values

object.remove.Last = function(self,number) -- removes number of entries from end of table
 if not number or number == 1 or number == -1 then return table.remove(self,#self) 
 elseif number == 0 then return false end local reps,out = #self + 1,{} number = abs(number) 
 for i = 1,number do out[i] = table.remove(self,reps - i) end
 return unpack(out) end -- returns: vararg of removed values

object.remove.AtIndex = function(self,index,number) -- removes number of entries at index 
 local max = #self; index = index < 1 and 1 or index > max and max or index
 if not number or number == 1 or number == -1 then return table.remove(self,index)
 else local out,arg = {},number/abs(number) -- removes entries to left or right
  if arg == 1 then for i = index,index + number - 1 do if not self[index] then break
   else table.insert(out,table.remove(self,index)) end end
  else arg = 0 for i = index,index + number + 1,-1 do if not self[index - arg] then break
   else table.insert(out,table.remove(self,index - arg)) arg = arg + 1 end end end
  return unpack(out) end end -- returns: vararg of removed values

object.remove.BeforeIndex = function(self,index,number) -- removes entries starting before index
 if index <= 1 then return false else max = #self; index = index > max and max or index end
 number = number and abs(number) or math.huge local out = {} for i = 1,number do 
  index = index - 1 if self[index] then out[i] = table.remove(self,index) else break end end
 return unpack(out) end -- returns: vararg of removed values   

object.remove.AfterIndex = function(self,index,number) -- removes entries starting after index
 local max = #self; index = index <= 1 and 2 or index > max and max + 1 or index + 1 
  number = number and abs(number) or math.huge local out = {} for i = 1,number do 
  if self[index] then out[i] = table.remove(self,index) else break end end
 return unpack(out) end -- returns: vararg of removed values
    
object.remove.FirstIndexOf = function(self,val,...) -- removes values from their first table indexies
 local max,extra,removed = #self,select("#",...),0 if val then for i = 1,max do
  if self[i] == val then val = table.remove(self,i) max = max - 1 removed = 1 break 
  elseif i == max then val = false end end end
 if extra == 0 then return val else local out,args = removed == 1 and {val} or {}, {...}
  local arg for i = 1,extra do arg = args[i]
   for i = 1,max do if self[i] == arg then removed = removed + 1
    out[removed] = table.remove(self,i) max = max - 1 break end end end
  return unpack(out) end end

object.remove.IndexiesOf = function(self,val,...)
 local max,extra,removed = #self,select("#",...),0 if val then for i = 1,max do
  if self[i] == val then val = table.remove(self,i) max = max - 1 removed = 1 
  elseif removed == 0 and i == max then val = false end end end
 if extra == 0 then return val else local out,args = removed == 1 and {val} or {}, {...}
  local arg for i = 1,extra do arg = args[i]
   for i = 1,max do if self[i] == arg then removed = removed + 1
    out[removed] = table.remove(self,i) max = max - 1 end end end
  return unpack(out) end end

object.remove.LastIndexOf = function(self,val,...) -- removes values from their last indexies in table
 local max,extra,removed = #self,select("#",...),0 if val then for i = max,1,-1 do
  if self[i] == val then val = table.remove(self,i) max = max - 1 removed = 1 break 
  elseif i == 1 then val = false end end end
 if extra == 0 then return val else local out,args = removed == 1 and {val} or {}, {...}
  local arg for i = 1,extra do arg = args[i]
   for i = max,1,-1 do if self[i] == arg then removed = removed + 1
    out[removed] = table.remove(self,i) max = max - 1 break end end end
  return unpack(out) end end

object.remove.Range = function(self,first,last) -- removes entries within range of indexies
 local max = #self; first = first < 1 and 1 or first > max and max or first
  last = last < 1 and 1 or last > max and max or last   
 if first == last then return self[first] and table.remove(self,first) or false -- removes single entry
 elseif first < last then local out = {} -- starts at first index and loops until last
  for i = 1, last - first + 1 do out[i] = table.remove(self,first) end return unpack(out)
 elseif last < first then local out = {} -- starts at last index and loops until first
  for i = 1,first - last + 1 do out[i] = table.remove(self,last) end return unpack(out) end end
    
-- (alias names) - object.insert|...| / object.remove|...| declaration point ...
object.unshift, object.shift, object.push, object.pop, object.slice =
 object.insertFirst, object.removeFirst, object.insertLast, object.removeLast, object.removeAtIndex

------------------------------------------------------------------
-- Object Native Data Management Methods

-- An object is created with pointers to methods which can evaluate and modify data which is contained within an object. While these functions do exist in deeper object classes, they can be overriden by methods inherited from those classes.

object.length = function(self) -- gets length of table/array
 local i,index = 0,next(self) while index do i = i + 1 index = next(self,index) end return i end
object.countElements = object.length -- aliases object.length

object.type = function(self) -- Gets objects' __type values or type() results
 if not self then return error("Invalid argument no.1 to object.type().",2) end
 local meta = getmetatable(self) if meta and meta.__type then return meta.__type 
 else return type(self) end end -- returns: type string of object

object.keys = function(self) -- Returs array object of keys in an object
 local keys = object:new() for Key,_ in pairs(self) do keys[#keys + 1] = Key end
 return keys end -- Return: "array object"

-- object:contains(...) -> boolean - Determines if value(s) exist inside object
---------- ---------- ---------- ---------- ---------- ---------- ---------- ----------
object.contains = function(self,val,ex,...) -- check for entries in table (speed -> 1)
 if val and not ex then  -- used if only one argument is passed
  local pairs = pairs for _,v in pairs(self) do if v == val then return true end end return false     
 else local vals = {val,ex,...} -- used if more than one argument is passed
  local next,remove,total = next,table.remove,#vals local index,value = next(self)   
  while index do for i = 1, total do -- cycles once through self and compares entities with vals
    if vals[i] == value then remove(vals,i) total = total - 1 
    if total == 0 then return true end end end -- returns: true if all matches were found
   index,value = next(self,index) end -- gets next entry in table
  return false end end -- returns: false if not all matches were found

---------- ---------- ---------- ---------- ---------- ---------- 
object.indexOf = function(self,...) -- Parses table for indexes
 local search,entries = {...}, #self local num = #search
 for i = 1,num do local found for index = 1,entries do 
   if self[index] == search[i] then search[i] = index found = true break end end
  if not found then search[i] = nil end end 
 return unpack(search,1,num) end -- Returns list of first occurances  

object.keyOf = function(self,...) -- Parses table for key values
 local search,entries = {...}, #self local num = #search
 for i = 1,num do local found for key,value in pairs(self) do 
   if value == search[i] then search[i] = key found = true break end end
  if not found then search[i] = nil end end 
 return unpack(search,1,num) end -- Returns list of first occurances  

object.inverse = function(self) -- Inverses numerical indexies of array
 local pos = 0 for i = #self,1,-1 do i = i + pos
  self:insert(pos + 1, self:remove(i)) pos = pos + 1 end 
 return self end

------------------------------------------------------------------
-- Object Status / Configuration Methods

object.meta = function(self) -- Creates object reference to metatable
 local meta = getmetatable return meta(self) end -- returns: object metatable

object.super = function(self) -- Returns super class / prototype of object
 return getmetatable(self).__proto end 
object.prototype = object.super -- alias for object.super

object.copy = function(self) -- Creates a deep copy of object table and metatable
 local meta,metaFm,copy = {}, getmetatable(self) or {},{} for k,v in pairs(metaFm) do meta[k] = v end
 for key,value in pairs(self) do if type(value) ~= "table" then copy[key] = value
  else copy[key] = object.copy(value) end end setmetatable(copy,meta) 
 return copy end -- Returns: object - copy of object

------------------------------------------------------------------
-- Extra Utility Methods

object.concat = function(self,sep)  -- Returns concantenated string of array entries
 return table.concat(self,sep) end -- Return: "string"

object.asIterator = function(self) -- Creates iterator from index part of table
 local pos = 0 return function() pos = pos + 1 if self[pos] then return self[pos] end end end

------------------------------------------------------------------
-- Envitonment Manipulation to scope of objects

-- The environment is set to a scope object which reference the caller object as well as passes all index and key declarations back to the caller object. Scopes also posess a 'self' which indexes the caller object. The current scope can be modified with the object:setScope(), object:pushScope(), and object:popScope() methods. Scopes can also exist in 'for' closures through the object:inScopeOf() iterator. Upon the loop ending in these closures, the enviornment prior to the loop is returned reguardless of the environment within the closure. 

---------------------------------------------------------------
-- Helper Functions ---------- ---------- ---------- ----------

 local function getLevel() -- Gets stack level of caller function
  local scope,err = 1,"no function environment for tail call at level "
  local env,error while true do env,error = pcall(getfenv,scope + 1) 
   if not env and error ~= err..tostring(scope + 1) then break end scope = scope + 1 end 
  return scope - 1 end -- Returns: number (stack level)      

----------------------------------------------------------------
-- Iterators (for (values) in (iterator) do) ---------- --------

object.inScopeOf = function(self) -- Sets environment within 'for' closure
 local cycle,env = 0, getfenv(getLevel() - 1) return function() cycle = cycle + 1 
  local scope = cycle == 1 and object.getScope(self) or cycle == 2 and env
  if scope then setfenv(getLevel() - 1, scope) -- Sets first to scope then _G
   return cycle == 1 and scope or nil end end end -- returns: scope object then nil

-------------------------------------------------------------------------------
-- Scope Stack Manipulation Methods ---------- ---------- ---------- ---------- 

object.getScope = function(self) -- Gets object's global scope   
 if not self then return getfenv(getLevel() - 1) end -- Returns caller environment
 local scope,meta = {self = self},{__type = "scope", __prev = getfenv(getLevel() - 1),
  __index = function(val,key) -- Indexes in environment point to object
   local value = self[key] or _G[key] return value end,
  __newindex = function(t,k,v) self[k] = v end} -- New indexes point to original object
 setmetatable(scope,meta) return scope end -- Returns new scope of object

object.setScope = function(self) -- Sets global scope of caller function to object 
 if not self then return setfenv(getLevel() - 1, _G) end
 local scope,level = object.type(self) == "scope" and self or object.getScope(self), getLevel()
 local meta = getmetatable(getfenv(level - 1)) if meta then
  getmetatable(scope).__prev = getfenv(level - 1) end   
 return setfenv(getLevel() - 1, scope) end

object.pushScope = function(self) -- Pushes a copy of the current scope onto the stack
 local level = getLevel() local current = getfenv(level - 1)
 if object.type(current) == "scope" then local scope = current:copy() 
  getmetatable(scope).__prev = current -- Sets previous meta index to current environment
 return setfenv(level - 1, scope) end end -- Sets caller environment to scope copy

object.popScope = function(self) -- Removes current scope from top of stack
 local level = getLevel() local meta = getmetatable(getfenv(level - 1)) 
 if meta and meta.__prev then return setfenv(level - 1, meta.__prev) 
 else return error("No object is currently in scope.") end end

----- ----------- ----------- ----------- ----------- ----------- -----------
----------- ----------- -----------  ----------- ----------- ----------- -----------
-- (object env) - The 'object' global variable space is used to represent the object environment and its methods. The object base class is referenced by the environment's meta.__index.

local meta = getmetatable(object) -- Allows object class to have independent extension instances
 setmetatable(_object,{__index = object, __call = meta.__call, 
  __version = meta.version, __type = "object env", __proto = object,

  __tostring = function(self) -- converts table to descriptor string
   local entries,value,formatK,formatV,meta = {} for k,v in pairs(self) do 
    formatK,formatV = type(k),type(v) meta = formatV == "table" and getmetatable(v)
    if formatV == "function" then value = "(lua function)" -- lua function handling
    elseif formatV == "table" and meta and meta.__type then -- object handling
     if meta.__tostring then value = tostring(v)
     elseif meta.__type then value = "("..tostring(meta.__type)..")" end
    elseif formatV == "table" and meta and meta.__tostring then value = tostring(v) 
    elseif formatV == "table" then value = "(lua table)" -- lua table handling
    elseif formatV == "string" then value = '"'..v..'"' else value = tostring(v) end 
    table.insert(entries,(formatK == "string" and '["'..k..'"]' or tostring(k))..":"..value.."") end
   table.sort(entries) return -- sorts entries / returns: descriptor string
    "("..tostring(getmetatable(self).__type).."):{"..table.concat(entries,", ").."}" end})

 object = _object; initExtensionLayer(object) -- updates object alias pointer

-- Private Class Methods entered after this point ...
----------- ----------- ----------- ----------- ----------- ----------- -----------
----- ----------- ----------- ----------- ----------- ----------- -----------
