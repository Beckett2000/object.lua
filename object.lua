-------------------------------------------
-- object.lua - 3.12 - Object Library for Lua programming - (Beckett Dunning 2014 - 2025) - WIP (8-04-25)
-------------------------------------------

-- local value = object() / object.new()
-- print("Hello object!")

-- This class adds a base (object) sub class which can be used to expose certain data manipulation methods to a table value 

-- local tree = object{}
-- tree.insert:first("foo"):push("bar")
-- print(tree) -- -> {"foo","bar"}

-------------------------------------------
-- if true then return end -- --- ---- -- 
-------------------------------------------

-- Local variable declaration for speed improvements

local type,pairs,table,unpack,concat,setmetatable,getmetatable,gsub,getfenv,setfenv = 
type,pairs,table,table.unpack,table.concat,setmetatable,getmetatable,string.gsub,getfenv,setfenv

local abs,pi,cos,min,max,pow,acos,floor,sqrt = math.abs,math.pi,math.cos,
math.min,math.max, math.pow,math.acos,math.floor,math.sqrt

----- ----- ----- ----- ----- -----

local object = object
if not object then   
  object = {libs = {}, stack = {}}    
end

----- ----- ----- ----- ----- -----

local _object,object,libs,initial,stack = 
 object,{},object.libs,object._initial,
 object._stack

-- accepted metatable keys to be parsed from object

local meta_tables,meta_ext = { __index = true, __tostring = true,  __newindex = true, __call = true, __add = true, __sub = true, __mul = true, __div = true, __unm = true, __concat = true, __len = true, __eq = true, __lt = true, __le = true}, { __type = true, __version = true, __namespace = true}

----- ----- ----- ----- ----- -----
-- Configuration methods for object instance behavior in code / within scopes

local _objectConfig = {
    
    ------ -------- ------ --------
    
    -- Allows for object.prefix expansion in a scope using dot syntax i.e - tree.insert.first("apple") inserts "apple" at the first index of object tree.
    
    -- Note: tree.insert:first("apple") would have the same effect.
    
    dotObjectRef = false,
    
    ------ -------- ------ --------
    
    -- Implicit 'self' - When in the scope of an object (i.e. tree:inScopeOf) pass self as first argument to base methods.
    
    -- Note: Without this flag enabled, you can use the [ :focus() / :blur() ] methods on an object to pass an implied self to methods
    
    -- Note: Not tested on Lua 5.1
    
    implicitSelf = false,
    
    --[[ ---- ---- ---- ---- ----
    local tree = object()
    for scope in tree:inScopeOf() do
        insertFirst("leaves")
        pop("leaves") -- removes from tree
    
    end
    ]] ---- ---- ---- ---- ----
    
    ------ -------- ------ --------

    -- WIP - Allows calls to be chained with callbacks through an object
    
    -- (Note: 04/05) Extension precidence / order of operations needs to be worked on with the call chaining
    
    --[[ ---- ---- ---- ---- ----
    local tree = object()
    tree:insert():first("a"):last("b")
    print(tree) --> tree{"a","b"}
    ]] ---- ---- ---- ---- ----
    
    callChain = false
    
    ------ -------- ------ --------
}

------------ ------------ ------------

-- Holds implicit self pointer ref. (see _objectConfig.implicitSelf)

local _implicitSelfObj = nil 

------------ ------------ ------------ 
-- Private method declarations
------------ ------------ ------------ 
local _handleToString, _objSerialDescriptor 
local _errorHandler, _canFunctionRun
------------ ------------ ------------ 
local _isObject, _firstOrLast, _indexOf
------------ ------------ ------------

------------ ------------ ------------ 
-- Debug Logs for object class
------------ ------------ ------------ 

local objectDebug = {
  extensions = false
}

------------ ------------ ------------ 
-- objectDebug = false
------------ ------------ ------------ 

local meta = {__index = self, __type = "object class", __version = true,

    __tostring = function(self) -- gives objects a tostring native behavior
        local vals = {} for k,_ in pairs(self) do table.insert(vals,tostring(k)) end
    table.sort(vals) return "(object baseClass):["..table.concat(vals,", ").."]" end,
    
    __call = function(self,...) -- creates object class from initializer
        return -- self.init and self:init(...) or 
    self:new(...) end } 

setmetatable(meta,{__type = "object meta", __index = object }) setmetatable(object,meta)

------------ ------------ ------------ 

-- TBD / Temporary - Trying to fix scope for module import vs inline class

local __ENV = _ENV

object.setenv = function(env)
    env.object = object
    __ENV = env
end

object.getenv = function()
    return __ENV
end

------------ ------------ ------------ 
-- stores object config data 

local function getDataStore(obj,create)
  local meta = getmetatable(obj)
  if not meta.__data then 
   if create == false then return end
   meta.__data = {} end
  return meta.__data
end

------------ ------------ ------------ 
-- serial - pretty print data value(s)
------------ ------------ ------------ 

----- ----- ----- ----- ----- -----
-- default settings for string gen.

local _tostringSettings = {
    
  ----- ----- ----- ----- ----- -----
  -- serial printing styles [__toString]
  -- "inline" | "block" | "vertical"
    
  style =  "inline", -- "vertical",
  spacer = " ", -- indent space i.e. "\t"
 
  -- maybe add these options later?   
  -- layout:
  -- padding:
    
  ----- ----- ----- ----- ----- -----
  -- table / function info options
    
  offsets = true, -- show offsets 0x0000
  lengths = true, -- show lengths table[2]   
  depth = 1, -- nested table depth
    
  ----- ----- -----    
  data = {} -- used internally by the toStringHandler to keep track of states when called recursively
  ----- ----- -----
    
}


------------ ------------ ------------ 
-- (top level) helpers for building object
------------ ------------ ------------ 

-------- ------ >>

local isCallableTable = function(value)
    local metatable = getmetatable(value)
    if metatable and metatable.__call then return true
    else return false end
end

-------- ------ >>

local isFunctionOrCallableTable = function(value)
    local valueType = type(value)
    if valueType == "function" then return true
    elseif valueType ~= "table" then return false end
    return isCallableTable(value)
end

-------- ------ >>

local _stringifyTable = function(tab)
  local stringTable = {}
  for i = 1,#tab do
  table.insert(stringTable,
   tostring(tab[i])) end
  return table.concat(stringTable)
end

-------- ------ >>
-- converts a string to upper or lower case

local _upperOrLower = function(str,upper)
 if type(str) ~= "string" then
  return str end
 local form = function(a,b) 
 local upperOrLower = upper and string.upper or string.lower
  return upperOrLower(a)..b end
 local out = gsub(str,"(%a)(%a+)",form)
 return out end

------------ ------------ ------------
------------ ------------ ------------ 
-- Object Extension Module :init() - (object:ext()) ----------- ----------- ---------

local function getInheritedValue(self,proto,key) 
    
 --print("getInheritedValue was called:",self,prototype:toString())
  
 local meta = getmetatable(proto)
 local protoIndex = meta.__index
 local callable = isFunctionOrCallableTable
    
 -- wrapper creation from ext in proto of object (self) -> returned wrapper is stored in self:meta():__exIndex
    
 if callable(proto[key]) then
    
  local objectType = object.type(proto[key])
        
  --print("This is self:",self)
        
  if objectType == "ext.extend" then return end -- you should never get an extend obj here ...
        
  if objectType == "ext.prefix" then
        
   local wrapper = 
    proto._ext[key](self)
      
   -- print("The wrapper:",wrapper,self,getmetatable(wrapper).__self)
            
   if objectDebug.extensions then
    print(object.concat{"getInheritedValue(): '",objectType,"' wrapper created from extension: [",proto[key],"] with key: '", key,"' for object: [",self,"]."}) end

   local wrapperMeta = getmetatable(wrapper)
            
    wrapperMeta.__call = function(self,...) return proto[key](...) end
            
    wrapperMeta.__modifiedExt = true
    return wrapper end
        
   end
    
   -- fallthrough in case wrapper fails
   return proto[key]     
    
end

------------ ------------ ------------ 

-- builder: builds object._ext
local function initExtensionLayer(self) -- (private) initializes object extension layer
    
  local meta = getmetatable(self)
    
  if meta == nil then meta = {} setmetatable(self,meta) end
    
  if not meta.__exIndex then 
   meta.__exIndex = {}
   setmetatable(meta.__exIndex,
    {__type = "extLayer"})
        
  elseif meta.__exIndex == true then
        
   local exMeta = {} -- makes new layer referencing superclass 
   local protoMeta = getmetatable(meta.__proto)
        
   for k,v in pairs(protoMeta) do 
    exMeta[k] = v end 
   meta.__exIndex = {}
   setmetatable(meta.__exIndex,exMeta)
    
  end
    
  local exIndex,super = meta.__exIndex,{} setmetatable(super,{__index = meta.__index});  
    
   getmetatable(exIndex).__index = function(exIndex,key) -- (lazy unpack) instantiates extensions
        
     local backRef = (meta.__type ~= "ext.prefix") and meta.__proto or meta.__self
             
     backRef = meta.__proto   
        
    if false then
    if objectDebug.extensions == true then  print(table.concat{"initExtensionLayer(): for object type: [",meta.__type,"]."}) end end
        
      -- meta.__type == "ext.prefix",meta.__type)
        
     --[[
     print("This is the metadata here..")
     for k,v in pairs(self) do
       print(table.concat{"Meta k:",k," Value:",v})
     end
     ]]
        
     local protoIndex = getmetatable(backRef).__index
        
     local keyIsModified = protoIndex and protoIndex[key] and isCallableTable(protoIndex[key]) and getmetatable(protoIndex[key]).__modifiedExt == true
    
     -- print("This is where the proto index is being used ...")
        
     if (protoIndex and protoIndex[key] ~= super[key]) or keyIsModified then 

       exIndex[key] = getInheritedValue(self,backRef,key) 
     
       if objectDebug.extensions then
        print(object.concat{"{{ lazy load }} Loaded extension .. \nfrom proto: [[ ", meta.__proto,' ]]\n with key: "',key, '"\n for object: [[ ',self," ]].\n new meta.__exIndex: [",object.tostring(meta.__exIndex),"]."}) end
            
      return exIndex[key]
            
      elseif super._ext and super._ext[key] then exIndex[key] = super._ext[key](self) return exIndex[key] end
        return super[key] end 
    
    -- sets a constructor instance for objects
    exIndex.constructor = super.new
    meta.__index = exIndex 
    
return meta.__exIndex end -- returns: extension layer

------------ ------------ ------------ 

local function hasExtensionLayer(self) -- (private) determines if table has ext layer
 local meta = getmetatable(self)
 if meta and meta.__exIndex then
  return true, meta.__exIndex 
 else return false end
 end -- returns: true and extension layer if found or false otherwise

local function getExtensionIndex(self)
  local hasIndex,exIndex = hasExtensionLayer(self)
  if not hasIndex then exIndex = initExtensionLayer(self) end
  return exIndex 
end

------------ ------------ ------------ 

-- object extension module -> object:extension():method() | object.extension:method()

-- _ext():dict() -> was prefix i.e. insert.first but would not combine into insertFirst when called ...

-- now _prefix: is object.insertFirst | object.insertfirst | object.insert.First | object.insert.first

------------ ------------ ------------

local function getExtStore(self) -- (private) points to / creates object.ext store
    -- print("This is self:",self)
 local target,ext 
 if self ~= object then -- stores extensions in __exIndex of metatable
        
  local layer = getExtensionIndex(self)
  local meta = getmetatable(self)  
        
  target,ext = layer, meta.__proto and meta.__proto._ext or nil
        
 else -- stores extensions in self 
  target,ext = self,self._ext 
 end 
    
 if not rawget(target,"_ext") then -- creates .ext index if not present
        
  meta = {} target._ext = {} 
  local cache = ext or object._ext 
  for k,v in pairs(getmetatable(cache)) do meta[k] = v end 
        
  meta.__index,meta.__proto = ext,ext;   
  setmetatable(target._ext,meta) end 
    
return target._ext end

------------ ------------ ------------

local function _extSetter(ext,wrapper) -- (private) creates setters ext().setter(val).key
    
 return function(self,name,method) -- (static) creates wrapper for calls
        
  local store = self ~= ext and getExtStore(self)(self) or self 
        
  if not name and not method then -- determines _:ext:prefix() method output
            
   local caller = {}
   setmetatable(caller,{ -- creates _:ext:wrapper() calling object
                
   __newindex = function(alias,key,value)
    store[key] = wrapper(key,value) end,
   __call = function(...) return 
    wrapper(name,method)(store)(...) end 
                
  }) return caller
            
  else store[tostring(name)] = wrapper(name,method or function() end) 
  end     
     
end end 

------------ ------------ ------------

-- (private) get alias function store
local function getBackReference(self) 
    
 local target,meta = self 
 while target do -- iterate through aliases
  meta = getmetatable(target) 
  if meta and meta.__self then
   target = meta.__self 
  else return target end end
        
end  -- returns: alias root target


------------ ------------ ------------
-- (private) ::proxy:: - creates a proxy object for extensions and tables/objects

local _proxy = function(ext,obj)
  
  local meta = { 
            
    __newindex = function(self,keys,value) -- [newindex] object.ext[key] set / object[key] unwrapped
        
     local names,lastKey = {},""
     local _c = _upperOrLower
     local insert = table.insert
        
     if type(keys) == "string" then
      insert(names,keys)
     elseif type(keys) == "table" then
      local key = keys[#keys]
      insert(names,_c(key,true))
      insert(names,_c(key,false))
      lastKey = keys[#keys - 1]
     end
                
     local store,ext = getExtStore(obj),ext
     if #names >= 1 then ext = value(obj) end
      
     for i = 1,#names do
      local key = lastKey..names[i]
      store[key],obj[key] = value, ext
     end 
            
    end,
            
    __index = function(extension,key) 
                
     local ext = {} -- handles indexes to _:ext()        
                
      ---------- ---------- ---------- ---------- ---------- ---------- ---------- ----------
      -- [ext().prefix()] - Declare: :ext():|prefix|().name = method / :ext():|prefix|(name,method)
      -- Declare Key: :|prefix|().|key| = method / .|prefix||key| = method
      -- Call Key: object:prefix():key() / object.prefix:key() / object:|prefix||key|()     
      ---------- ---------- ---------- ---------- ---------- ---------- ---------- ----------
                
      ext._prefix = _extSetter(extension, function(name,method) -- (passUp) object indexer / sorter
        return function(self)  
            
         ---- ---- ---- ---- ---- ----
                        
         local extension,meta = {},{
           _isPrefix = true
         } -- --- ---- ----- ------           
        
         ---- ---- ---- ---- ---- ----
         local _meta = meta               
         ---- ---- ---- ---- ---- ----
                        
         meta = { -- extension metadata
                            
          __type = "ext.prefix", 
          __self = self, -- obj
                            
          __data = {             
            -- stores ext name path data                              
            path = type(name) == "string" and {name} or type(name) == "table" and name                    
          },
                            
          -------- ------ ---- >               
          -- (ext) returns prefix descriptor string        
                            
          __tostring = function(pointer) 
                                
           local list,meta,key,val = {}, getmetatable(pointer)
                                
           local path = meta.__data.path
           local methodName = path[#path]
           local prefix = concat(path)                                                 
           local level = pointer.self
                                
           while(level) do 
                                    
            key,val = next(level,key)    
            if not key then break end  

            local name = string.match(key,concat{"^",prefix,"([%w_]+)$"})
            
            if name then 
             table.insert(list,name)
            end end
                                
           table.sort(list) 
                                
           ------ ---- ------ ---- --
           -- object.ext.tostring()
           ------ ---- ------ ---- --   
                                             
           -- the __self an extension could also be serialized here ... [descriptors.osd ] -- TBD
                                
           local osd = _objSerialDescriptor                  
           local descriptors = {
            "self", osd = concat(
             {"(",osd(pointer.self),")"})
           } --- ---- --- ---- ----
           ------ ---- -- ---- --           
           local extTag = concat{"[::",descriptors[1],".",concat(path,"."),"::]"}  
           ------ ---- -- ---- --
           return concat{"(ext.prefix[",
           #list,"]: ",extTag,"):{",concat(list,", "),"}"}
           ------ ---- -- ---- --
                                
         end,       
                            
         ---- ---- ---- ---- ---- ----
         -------- ------ ---- >  
                                                                             
         -- declaration: obj.|prefix|.|name| = method                        
         __newindex = function(pointer,key,value) 
                                
           -- print("##### newindex invoked")
                             
           -- _caseStr: converts first char of string to lowercase or uppercase                  
           local _c = _upperOrLower
                                
           local entry,internal = tostring(key) 
                                
          local nameIsTable = type(name) == "table"            
          local suffix,prefix = name, ""
          if nameIsTable then
            suffix,prefix = name[#name], name[#name - 1] end
        
          if objectDebug.extensions then       
           print(concat{"__newindex called for extension: [[ ",suffix,' ]] \nwith key: "',key,'".'})
          end
                                                 
         local extNames = {
          _c(entry,true), _c(entry,false)}
                                 
         for i = 1,2 do
                                    
          if nameIsTable then 
          table.insert(extNames,_c(suffix,true)..extNames[i])
           extNames[i] = _c(suffix,false)..extNames[i]
           
          else extNames[i] = suffix..extNames[i] end
                                    
         end
                                
         ---- ---- ---- ----
                                
         for i = 1,#extNames do
                                    
           local entry = prefix..extNames[i]
                                    
           if not value and not rawget(self,entry) then
            internal = false error("Extension cannot modify superclass.",2) 
           else internal = true end
                                    
           self[entry] = (not value and internal) and nil or value
                                    
          end                                       
         end,
              
         ---- ---- ---- ---- ---- ----  
         -------- ------ ---- > 
                         
         __index = function(pointer,key) -- indexing statement: _.|prefix|:|name|()    

          -- TBD note: these could be moved so that they are not on every extension (get/set?)
                                
          -- returns: prefix self ref.
          if key == "self" then         
           return meta.__self
                
          elseif key == "tostring" or key == "toString" then return 
           function(options) return _handleToString(pointer, options) 
           end
                
          -- calling prefix.extend                 
          elseif key == "extend" or key == "ext" then
                                    
           local extensionObj = {}
           setmetatable(extensionObj,{   
                                              
            __type = "ext.extend",
            __self = obj,
                                                        
            __call = function(self,_ext,str)                             
              obj.extend(_ext,str)                              
             end
                                                                                                
           }) 
                                                            
           return extensionObj
                                                                
          end 
                                
          ----- ---- ----- ----
                                     
          local data = meta.__data
          local dataPath = data.path
          local _key = concat(dataPath)..key
          
          -- (lazy load) on methodName index      
          local path = self[_key]                
          local format = type(path)
                                
          -- local directPath = self[key]         
                                 
          if objectDebug.extensions then       
           print(object.concat{"__index called for extension: [[ ",pointer,' ]] \nwith key: "',key,'", and name path:',object.tostring(dataPath,{style="vertical",
             depth = 10})})
          end                   
                                
          -- local callable = isFunctionOrCallableTable
        
          ---------- ---------- ----------         
          -- temp. - if an ext.prefix is ever passed to a call, it should return it self key
                                
          local _isExtension = function(value)
           local meta = getmetatable(value)
           if meta and meta.__type == "ext.prefix" then return true 
           else return false end
          end
                                
          ---------- ---------- ----------  
          
          if format == "function" then 

           return function(v,...) -- redirector function for calls

            --- --- -----
    
            if v == pointer then return path(self,...)

            elseif self == object then 
             if object[key] then 
              return object[key](v,...)
             else return path(v,...) end
            end
                                        
            --- --- -----
                                        
            -- overload: objectInst.[ext].[val] points to objectInst i.e. tree.insert.first("apple") -> tree{"apple"}
                                        
            if _objectConfig.dotObjectRef == true then
             return path(self,v,...)       
            end
                  
            ---- ------ ---- ------ 
            -- fallthrough: return pointer to function with unchanged args
                  
            return path(v,...)
                  
            ---- ------ ---- ------   
                                           
         end        
        
        ---------- ---------- ----------
                  
        -- hanles sub extensions                                                
        elseif _isExtension(pointer) and data.prev then -- print("* sub ext")

         local path = concat(dataPath)..key
                  
         -- note: could be used to replace lazy load - so then you dont necessarily need an _exIndex - TBD
                                    
          return function(pointer,...)
            if not _isExtension(pointer) then 
             return self[path](pointer,...) 
            else
             local self = pointer.self
             return self[path](self,...)                  
           end end                       
                                                                                      
        end                                        
        
        ---------- ---------- ----------
                
        -- local meta = getmetatable(path)
        -- print(path,meta.__self)       
                
        return path end, -- returns: redirector or key actual 
  
        ---- ---- ---- ---- ---- ----  
        -------- ------ ---- >    
                              
       __call = function(pointer,obj,...) -- calling statement: _:|prefix|() / _:|prefix|():|name|()          
         
         ------ ------ ------ -------
         local target = getBackReference(obj)
         ------ ------ ------ -------
                                                   
         if not obj then return end local extra = select("#",...)
         local meta = obj and getmetatable(pointer)
         local objType = type(obj)
         
         ------ ------ ------
                
         --- WIP - use this to allow _ext():_prefix() methods to not return the prefix itself when called with no arguments 
                          
         if _objectConfig.callChain == true then
                                
          if obj == pointer and extra == 0 then return pointer                
          elseif extra == 0 and objType == "table" then 
                                 
            -- print("Handling _ext store for calling ...")
                    
           return obj[name] and obj[name] or getBackReference(pointer)[name]  
                                        
         end end
                      
        ------ ------ ------
                               
        return method(target,...) end 
                            
        ---- ---- ---- ---- ---- ----
                            
         } setmetatable(extension,meta) return extension end end ) 
                
       return ext[key] end
            
     } -- returns: pointer to method in entry
  
   local proxy = {} setmetatable(proxy,meta) 
   return proxy -- returns: proxy table 

end

------------> ------------> ------------> 
object._ext = {} ---> ------> -------->
------------> ------------> ------------> 

local extMeta = { -- .ext() is a dynamic module
    
 __type = "object._ext",
    
 __tostring = function(self) -- reports details when converted to string
  local names,layer,name = {},self 
  while layer do for k,v in pairs(layer) do 
   table.insert(names,tostring(k)..":("..getmetatable(v(object)).__type..")") end 
   layer = getmetatable(layer).__proto end table.sort(names)
  return "(ext cache):{"..table.concat(names,", ").."}" end,
    
 __index = function(ext,key) return ext(getBackReference(ext))[key] end, -- object.ext:method()
    
 __call = function(ext,obj)  -- invoked when calling object:ext()
    
  if not obj then error("invalid arg. no.1 (lua table) to object.ext().",2) 
  return end 
    
  return _proxy(ext,obj) 
 end -- returns: proxy table 
  
} 

-- Sets up metatable for object.ext
setmetatable(object._ext,extMeta)

---------- ---------- ---------- -----
-- ::object:new():: | ::object():: -> primitive object constructors

-- The new metamethods for an object subclass are passed at the time of initialization. If metatable elements are detected, they are removed from the objects methods and added to its metatable. The imput object as well as the output object retured can be used to add new methods and values to a class, but new metamethods will not be detected after initial initialization.

object.new = function(super,self) -- (object) - base constructor 
    
 local meta,superMeta = {__type = "object", __data = false}, getmetatable(super) meta.__index = super == object and superMeta.__proto or super

  -- Note (3-9-25): meta.__proto used to be set to meta.__index. This was changed to meta.__index = super. This may have unexpected effects in classes which use object (see below)
    
  meta.__proto = meta.__index
  meta.__exIndex = 
   superMeta.__exIndex and true 
        
  for k,v in pairs(superMeta) do 
   if meta[k] == nil then 
    meta[k] = type(v) ~= "table" and 
     v or object.copy(v,{
      depth = math.huge, meta = true
    }) end  
  end
     
  meta.__type = super == _object and "object" or meta.__type 
  
  self = type(self) == "table" and 
   self or {}
    
  -- object.constructor = super.new
    
  -- Iterates over passed in table and moves metamethods to metatable
 for key,value in pairs(self) do
   if meta_tables[key] or meta_ext[key] then
    meta[key], self[key] = value, nil
 end end
    
 setmetatable(self,meta)
 initExtensionLayer(self) -- creates and initializes object meta
    
return self end -- returns: new object instance

---------- ---------- ----------
-- ::object.init:: - an optional '.init()' function can be declared which will be called each time an object is instantiation

-- object.init = function(self) end -- Called upon object instantiation

---------- ---------- ----------
-- ::object.extend:: / :ext() - creates a extension on a key so that it can function such as object.insertFirst | object.insert.first | object.insert:First etc. where the 'ext' is object.insert

object.extend = function(self,key)

 if not self or type(self) ~= "table" then 
  return end

 local meta = getmetatable(self)
 local type = meta and meta.__type and meta.__type or type
 
 local _self,path = self,key
 local callable = isFunctionOrCallableTable   
 local isExtension = type == "ext.extend" or type == "ext.prefix"  
   
 if objectDebug.extensions == true then
        
  if not isExtension then
   print(concat{'{{ object.extend }} Creating an extension for object type: "',type,'", \nwith key: "',key,'"'})
            
  else
   print(object.concat{'{{ object.extend }} Creating a (sub)extension for ext object: [[ "',self,'" ]] \nin object: [[ ',meta.__self,' ]] \nwith key: "',key,'".'})
        
 end end
    
 if isExtension then
  local dataPath = meta.__data.path
  path = {unpack(dataPath),key}
  key,self = concat(path), meta.__self
 end
    
 local target = self[key] 
 if target and callable(target) then
  self:_ext():_prefix()[path] = target 
  
  -- sets the data.prev for nested exts
  if isExtension then -- this may be moved 
   local ext = self[concat(path)]
   local extMeta = getmetatable(ext)
   extMeta.__data.prev = _self
            
 end end       
        
end

----- ----> ----- ---- -----> ----
object.ext = object.extend ----->
----- ----> ----- ---- -----> ----

---------- ---------- ----------

-- ::object.proxy:: - (TBA) creates a proxy to a table or object which takes on the 'self' of a referenced object and allows for access control. Access 'r' (read) 'w' (write) or 'rw' (read and write) - defaults to 'rw'

object.proxy = function(self,access)
  
end

---------- ---------- ----------

-------------------- -------------------- --------------------     
-- (_.insert, _.remove) - Prefix Block Extensions
------------------- - -------------------- --------------------     

-- These prefix extensions search for the insert or remove prefix when referenced to create custom method call blocks. Using the declaration syntax, subclasses can append custom local methods to these extensions. The usage structure is below:

-- Declaration: object.|insert/remove|Extension IE: object.insertValue
-- Calling Examples: object:insertValue() object.insert:Value() object:insert():Value() 

-- object:_extPreix().remove = table.remove; object:_extPrefix().insert = table.insert

-------------------- --------------------
-------------------- --------------------

-- object.insert|...| -- These functions are used to add data to the array portion of an object. All the methods can be referenced from calling their direct method name or by using the object:insert() block call connections -> object:insert():First(values):Last(values).

object.insert = table.insert
object:extend("insert")

------ ---- ------ ---- ------

-- inserts at the start of a table/string
object.insert.first = function(self,...)
    
  if not _canFunctionRun{ 
   method = "object.insert.first",
   types = {"table","string"},
   self = self } then return self end
    
  local count,args = select("#",...)    
  if count == 0 then return self end
  local format = type(self) 
    
  -- string handling
    
  if format == "string" then
   if count == 1 then
    return select(1,...)..self end
   return _stringifyTable{...,self}
  end -- returns: (new string)
    
  -- table handling

  if count == 1 then
   table.insert(self,1,select(1,...))
   return self
  else args = {...} end 
    
  for i = count,1,-1 do 
   table.insert(self,1,args[i])
  end return self
    
end -- returns: table (self)

-- object.unshift = object.insert.first

---- ---- ------

-- inserts at the end of a table/string
object.insert.last = function(self,...)
    
  if not _canFunctionRun{ 
   method = "object.insert.last",
   types = {"table","string"},
   self = self } then return self end  
    
  local count,args = select("#",...)
  if count == 0 then return self end
  local format = type(self)   
    
  -- string handling

  if format == "string" then
   if count == 1 then
    return self..select(1,...) end
   return _stringifyTable{self,...}
  end -- returns: (new string)
    
  -- table handling
  
  if count == 0 then return self
  elseif count == 1 then
   table.insert(self,select(1,...))
   return self
  else args = {...} end
    
  for i = 1,count do 
   table.insert(self,args[i])
  end return self 
    
end -- returns: table (self)

-- object.push = object.insert.last

---- ---- ------

-- inserts at an index of a table/string
object.insert.atIndex = function(self,index,...)
    
  if not _canFunctionRun{ 
   method = "object.insert.atIndex",
   types = {"table","string"},
   self = self } then return self end
        
  if count == 0 then return self end
  local format = type(self)   
    
  local max,abs = #self + 1, abs
  index = index < 1 and 1 or index > max and max or abs(index)
    
  -- string handling
    
  if format == "string" then
   local first,second = string.sub(self,1,index),
    string.sub(self,index + 1,#self)    
   
   local strData = {first,...}
   table.insert(strData,second)
   return _stringifyTable(strData)
  end -- returns: (new string)
    
  -- table handling
    
  local argCount = select("#",...)
  if argCount == 1 then
   table.insert(self,index,select(1,...))    
  else local args,arg = {...} 
   for i = 1,argCount do arg = args[i]
    if arg then 
     table.insert(self,index,arg)
     index = index + 1 end end
        
 return self end end -- returns: table (self)

------ ---- ------ ---- ------

-- TBD - object.insert:fromTable(table) - potential proxy?

-- Values can be inserted from an existing table rather than having to be ennumerated manually in the insert declaration. Other simpler method namespaces ( will also be ) utilized.

object.insert.firstIndexiesFromTable = function(self,source) -- inserts indexies first into self
    if not source then return self else for i = 1,#source do -- coppies indexies from source into self
            table.insert(self,i,source[i]) end return self end end

object.insert.lastIndexiesFromTable = function(self,source) -- inserts indexies last into self
    if not source then return self else local total = #self -- coppies indexies from source into self
        for i = 1,#source do table.insert(self,i + total,source[i]) end return self end end

object.insert.atIndexIndexiesFromTable = function(self,index,source) 
    if not index or not source then return end local total = #self + 1
    local index = index <= 1 and 1 or index >= total and total or index
    for i = 1,#source do table.insert(self,index + i - 1, source[i]) end return self end 

object.insert.indexiesFromTable = function(self,source,overwrite) -- inserts indexies from table
    if not source then return self end if overwrite ~= false and overwrite ~= 0 then 
        for i = 1,#source do self[i] = source[i] end -- coppies indexies from source into self
    else for i = 1,#source do -- coppies entries if not present in self
            if not rawget(self,i) then self[i] = source[i] end end return self end end

object.insert.keysFromTable = function(self,source,overwrite) -- inserts keys from existing table
    if not source then return self end local index,value = next(source)
    if overwrite ~= false and overwrite ~= 0 then while index do -- overwrite: defaults to true
            self[index] = value index,value = next(source,index) end -- overwrites duplicate keys in self       
    else while index do if not rawget(self,index) then self[index] = value end -- only adds new keys
        index,value = next(source,index) end end return self end

---- ------ -------- ---------- --------

-- object.remove|...| -- These functions are used to remove data from the array portion of an object. All the methods can be referenced from calling their direct method name or by using the object:remove()

object.remove = table.remove
object:extend("remove")

------ ---- ------ ---- ------

-- removes one or more indexies from table
object.remove.indexies = function(self,...) 
    
  if not _canFunctionRun{ 
   method = "object.remove.indexies",
   types = {"table"},
   self = self } then return end
    
  local len = select("#",...)
  if len == 1 then 
   return table.remove(self,select(1,...)) 
  end  -- returns: (removed val)
    
  local out = {}
    
  -- removes all numerical indexies when called without arguments 
    
  if len == 0 then for i = 1,#self do
    table.insert(out,table.remove(self,1)) 
   end return unpack(out) end -- returns: vararg (removed values)
  
  -- removes multiple inexies when more than one index value is passed in
    
  local args,indexies = {...},{}
  local index,ref,count = args[1],1,1
    
  while count <= len do
        
    if type(index) == "number" and not indexies[index] then 
      indexies[index] = true  
      ref = ref + 1
    else table.remove(args,ref) end  
         
    index,count = args[ref], count + 1
    
  end
    
  indexies = {}
  table.sort(args, function(a,b) return a > b and true or false end)
    
  for i = 1,#args do hash = args[i]
   indexies[hash] = table.remove(self,hash) 
  end 
    
  for i = 1,len do
   hash = select(i,...)
   if hash ~= nil then
    out[i] = indexies[hash] 
  end end
    
 return unpack(out,1,len) end -- returns vararg (removed values)

---- ---- ------

-- removes one or more keys from table
object.remove.keys = function(self,...)
    
  if not _canFunctionRun{ 
   method = "object.remove.keys",
   types = {"table"},
   self = self } then return end
    
  local len,hash,out = select("#",...)
  if len == 1 then hash = select(1,...)
   if hash ~= nil then out = self[hash]
   self[hash] = nil return out end end -- returns: output (removed values)
  
  local out = {}
    
  -- removes all non numerical keys when called without arguments - maybe this could return a keyed table?
        
  if len == 0 then
   for k,_ in pairs(self) do
    if type(k) ~= "number" then 
     table.insert(out,self[k]) 
     self[k] = nil end 
   end return unpack(out)
        
  -- removes multiple key values when more than one key is passed in
        
  else local args = {...}
   for i = 1,#args do hash = args[i]
    if hash ~= nil then
     out[i],self[hash] = self[hash], nil         
  end end end 
    
 return unpack(out,1,len) end -- output (removed values)

---- ---- ------

-- remove index value(s) from table start
object.remove.first = function(self,number) 
    
  if not _canFunctionRun{ 
   method = "object.remove.first",
   types = {"table"},
   self = self } then return end
    
  if not number or number == 1 or number == -1 then return table.remove(self,1)  
  elseif number == 0 then return end 
    
  local out = {} number = abs(number) 
  for i = 1,number do out[i] = table.remove(self,1) end
    
 return unpack(out) end -- returns: vararg of removed values

---- ---- ------

-- remove index value(s) from table end
object.remove.last = function(self,number) 
    
  if not _canFunctionRun{ 
   method = "object.remove.last",
   types = {"table"},
   self = self } then return end
    
  if not number or number == 1 or number == -1 then return table.remove(self,#self) 
  elseif number == 0 then return end
    
  local reps,out = #self + 1,{} number = abs(number) 
  for i = 1,number do out[1 + number - i] = table.remove(self,reps - i) end
    
 return unpack(out) end -- returns: vararg of removed values

---- ---- ------

-- remove value(s) from a table which are stored before a certain indice
object.remove.beforeIndex = function(self,index,number) 
    
  if not _canFunctionRun{ 
   method = "object.remove.beforeIndex",
   types = {"table"},
   self = self } then return end
    
  if index <= 1 then return false else max = #self; index = index > max and max or index end
    
  number = number and abs(number) or math.huge local out = {} 
    
  for i = 1,number do index = index - 1 
   if self[index] then 
    out[i] = table.remove(self,index) 
   else break end end
    
return unpack(out) end -- returns: vararg of removed values   

---- ---- ------

-- remove value(s) from a table which are stored after a certain indice
object.remove.afterIndex = function(self,index,number) 
    
  if not _canFunctionRun{ 
   method = "object.remove.afterIndex",
   types = {"table"},
   self = self } then return end
    
  local max = #self; 
  index = index <= 1 and 2 or index > max and max + 1 or index + 1 
    
  number = number and abs(number) or math.huge local out = {} 
    
  for i = 1,number do 
   if self[index] then
    out[i] = table.remove(self,index) 
   else break end end
    
return unpack(out) end -- returns: vararg of removed values

---- ---- ------

object.remove.atIndex = function(self,index,number) -- removes number of entries at index 
    local max = #self; index = index < 1 and 1 or index > max and max or index
    if not number or number == 1 or number == -1 then return table.remove(self,index)
    else local out,arg = {},number/abs(number) -- removes entries to left or right
        if arg == 1 then for i = index,index + number - 1 do if not self[index] then break
                else table.insert(out,table.remove(self,index)) end end
        else arg = 0 for i = index,index + number + 1,-1 do if not self[index - arg] then break
                else table.insert(out,table.remove(self,index - arg)) arg = arg + 1 end end end
    return unpack(out) end end -- returns: vararg of removed values

---- ---- ------

object.remove.firstIndexOf = function(self,val,...) -- removes values from their first table indexies
    local max,extra,removed = #self,select("#",...),0 if val then for i = 1,max do
            if self[i] == val then val = table.remove(self,i) max = max - 1 removed = 1 break 
            elseif i == max then val = false end end end
    if extra == 0 then return val else local out,args = removed == 1 and {val} or {}, {...}
        local arg for i = 1,extra do arg = args[i]
            for i = 1,max do if self[i] == arg then removed = removed + 1
                    out[removed] = table.remove(self,i) max = max - 1 break end end end
    return unpack(out) end end

object.remove.indexiesOf = function(self,...)
    
    local args = {...}
    for i = 1,#args do 
     local entry,selfLength = args[i], #self
     for j = 1,selfLength do
       local tableEntry = self[j]
       while tableEntry == entry do 
        table.remove(self,j)
        tableEntry,selfLength = self[j], selfLength - 1         
       end end end
    return unpack(args)
    
end

object.remove.lastIndexOf = function(self,val,...) -- removes values from their last indexies in table
    local max,extra,removed = #self,select("#",...),0 if val then for i = max,1,-1 do
            if self[i] == val then val = table.remove(self,i) max = max - 1 removed = 1 break 
            elseif i == 1 then val = false end end end
    if extra == 0 then return val else local out,args = removed == 1 and {val} or {}, {...}
        local arg for i = 1,extra do arg = args[i]
            for i = max,1,-1 do if self[i] == arg then removed = removed + 1
                    out[removed] = table.remove(self,i) max = max - 1 break end end end
    return unpack(out) end end

object.remove.range = function(self,first,last) -- removes entries within range of indexies
    local max = #self; first = first < 1 and 1 or first > max and max or first
    last = last < 1 and 1 or last > max and max or last   
    if first == last then return self[first] and table.remove(self,first) or false -- removes single entry
    elseif first < last then local out = {} -- starts at first index and loops until last
        for i = 1, last - first + 1 do out[i] = table.remove(self,first) end return unpack(out)
    elseif last < first then local out = {} -- starts at last index and loops until first
        for i = 1, first - last + 1 do out[i] = table.remove(self,last) end return unpack(out) end end

object.remove.entry = function(self,entry) -- finds entry in table and removes all instances
    if not self then error("Invalid argument no.1 'self' to object.removeEntry().") end
    --print(self)
    object.removeIndexiesOf(self,entry)
    local keys = object.keysOf(self,entry) 
    for i = 1,#keys do self[keys[i]] = nil end
return entry end

object.remove.entries = function(self,...) -- finds values in table and removes them
    if not self then error("Invalid argument no.1 'self' to object.removeEntries().") end
    local args,pos = {...} for i = 1,#args do 
        object.removeEntry(self,args[i]) end 
return unpack(args) end

---- ------ ---- ------ -- >>

-- (alias names) - object.insert|...| / object.remove|...| declaration point ...

object.unshift = object.insertFirst
object.shift = object.removeFirst
object.push = object.insertLast
object.pop = object.removeLast
object.slice = object.removeAtIndex

------- ------- ------- ------- ------- ----
-- Querying / Search Methods
------- ------- ------- ------- ------- ----

-- An object is created with pointers to methods which can evaluate and modify data which is contained within an object. While these functions do exist in deeper object classes, they can be overriden by methods inherited from those classes.

------- ------- ------- -------

object.countElements = function(self) -- gets number of elements in object
  local i,index = 0,next(self) while index do i = i + 1 index = next(self,index) end return i end

-- TODO - change .length and .size to getters
object.length = object.countElements
object.size = object.countElements

-------- -------- -------- -------- 

-- object:contains(...) - determines if one or more entries exists in a source table

object.contains = function(self,...) -- determines if table contains entry
  
 local count = select("#",...)
 if count == 1 then; local val = select(1,...)
  for _,v in pairs(self) do if v == val then return true end end return false end

 local args,vals,arg = {...},{} -- used if more than one argument is passed
  for i = 1,#args do arg = args[i]
   if arg == nil then return false
   elseif not vals[arg] then vals[arg] = true
   else count = count - 1 end
 end
    
 local index,value = next(self)             
 while value do 
  if vals[value] then
   vals[value] = nil count = count - 1
   if count == 0 then return true end
  end  
 
  index,value = next(self,index) end 
  
 return false end -- returns: true or false

-------- -------- -------- --------

-- (private) helper: finds entry in table - used for :indexiesOf(...), :keysOf(...), and :find(...)

local function _findEntries(self,form,...)

  local out,index,val = {}, next(self)
  local args,vals,arg = {...},{}
  for i = 1,#args do arg = args[i]
   if args ~= nil then vals[arg] = true end
  end
  
  while(index) do
   if vals[val] then 
      local _type = type(index)
      if form == "keys" and _type ~= "number" or form == "indexies" and _type == "number" or not form then
      table.insert(out,index) end
    end index,val = next(self,index)
  end return unpack(out)
  
end

---- ---- ------

-- object.indexies(self) - gets a list of the indexies declared in a source table

object.indexies = function(self)
  return unpack(self,1,#self)
end

---- ---- ------

-- object:indexiesOf(...) - finds the indexies of one or more values in a source table

object.indexiesOf = function(self,...)
  return _findEntries(self,"indexies",...)
end

---- ---- ------

-- object.keys(self) - gets a list of the keys declared in a source table

object.keys = function(self) 
  
 local insert = table.insert
 local keys,index = {},next(self)
 while index do 
   if type(index) ~= "number" then
    table.insert(keys,index) end
   index = next(self,index) end
  
 return unpack(keys) end 

---- ---- ------

-- object:keysOf(...) - finds the keys of one or more values in a source table

object.keysOf = function(self,...)
 return _findEntries(self,"keys",...)
end

---- ---- ------

-- object:hasKeys(...) - determines if a source table has one or more keys

object.hasKeys = function(self,...)
 if not self or type(self) ~= "table" then return false end
 for i = 1, select("#",...) do
  if not self[select(i,...)] then return false end
  end return true end

---- ---- ------

-- object:find(...) - finds indecies or keys of one or more values in a source table

object.find = function(self,...)
  return _findEntries(self,nil,...)
end

-------- -------- -------- -------- 

-------- -------- -------- -------- --------
-- object.first|...| / object.last|...|
-------- -------- -------- -------- --------

object.first = function(self,count) 
  return _firstOrLast(self,1,count) 
end -- returns: first entrie(s)

object.last = function(self,count) 
  return _firstOrLast(self,-1,count) 
end -- returns: last entrie(s)

-------- -------- -------- -------- 
object:extend("first")
object:extend("last")
-------- -------- -------- -------- 
  
object.first.indexOf = function(self,...)
  return _indexOf(self,false,...)
 end -- returns: vararg - indices or nils

---- ---- ------

object.last.indexOf = function(self,...)  
  return _indexOf(self,true,...)    
end -- returns: vararg - indices or nils

-------- -------- -------- -------- 

-- get index value range / substring of table / string values respectively
object.range = function(self,start,fin)
    
  if not _canFunctionRun{ 
   method = "object.range",
   types = {"table","string"},
   self = self } then return end
    
  local out,step = {}, 1
    
  if not start or not fin or type(start) ~= "number" or type(fin) ~= "number" then
   error("Invalid anchor points to object.range.") return
  end

  if type(self) == "string" then 
    return string.sub(self,start,fin)
  end

  start,fin = abs(start),abs(fin)
  if start == fin then return self[start]
  elseif start > fin then step = -1 end
    
  for i = start,fin,step do 
   table.insert(out,self[i])
  end
    
  return unpack(out)
    
end

-------- -------- -------- -------- 
-- object.copy|...| -- Prefix
-------- -------- -------- --------
-- object.copy: replaces an object based on the memory access pointer locations at a given level for a lua data type
-------- -------- -------- --------

local _copy -- helper: copies objects
_copy = function(self,depth)

  if not self or depth == 0 then
   return self end

  local copy = {} 
  for k,v in pairs(self) do 
    
    local value,type = self[k],type(v)
    if type == "string" or type == "number" 
     or type == "boolean" then copy[k] = v 
      
    elseif type == "table" or 
    type == "function" then  
     if depth == 1 then copy[k] = v
     else copy[k] = _copy(v, depth - 1)
    end end end
  
  return copy
  
end -- returns: object - copy of object

-------- -------- -------- --------
-- copy - opt: {depth: number, meta: boolean}
---- ---- ---- ---- ---- ---- ---- ----

object.copy = function(self,opt,ext)

  if not _canFunctionRun{ 
   method = "object.copy",
   types = {"table"}, self = self } 
  then return end
  
  local depth,meta = 1, true
  
  if opt then
    
   if type(opt) == "number" then
    depth = opt end
    
   meta = (opt.meta and type(opt.meta) == "boolean") or true
   depth = (opt.depth and type(opt.depth) == "number") or 1
    
  end

  local copy = _copy(self,depth)
  local meta = getmetatable(self)
  
  if meta then 
   setmetatable(copy, _copy(meta,depth)) 
  end
  
  return copy -- returns: copy of table
  
end

-------- -------- -------- -------- 
object:extend("copy")
-------- -------- -------- -------- 

object.copy.deep = function(self) -- Creates a deep copy of object table and metatable
  
  if type(self) ~= "table" then
    -- error("object.copy: self was not table. ",self)
    return self
  end
  
  local meta,metaFm,copy = {}, getmetatable(self) or {},{} 
  
  for k,v in pairs(metaFm) do 
    meta[k] = v end
  
  for key,value in pairs(self) do 
    if type(value) ~= "table" then copy[key] = value
    else copy[key] = object.copy(value)
    end end setmetatable(copy,meta) 
  
  return copy 
  
end -- returns: object - copy of object

-------- -------- -------- -------- 
-- Object Status / Configuration Methods
-------- -------- -------- -------- 

object.inverse = function(self) -- Inverses numerical indexies of array
  local pos = 0 for i = #self,1,-1 do i = i + pos self:insert(pos + 1, self:remove(i)) 
  pos = pos + 1 end  return self
end

---------- -------- ----------
object.inverseIndexies = object.inverse
---------- -------- ----------

object.concat = function(self,sep) -- Concantinates table indexies
    
  if not _canFunctionRun { 
   method = "object.concat",
   types = {"table"},
   self = self } then return end
    
  local toString,insert = 
    object.toString,object.insert
  local sep = sep and toString(sep) or ""
    
  local strings = {}
  for i = 1,#self do
   insert(strings,toString(self[i]))
   if i ~= #self then insert(strings,sep)
  end end
    
  local concat = table.concat
  return concat(strings)
        
 end -- returns: (string) - table indexes converted into a string

---------- -------- ----------
object.cat = object.concat
---------- -------- ----------

-- Gets objects' __type values or data type

object.type = function(self) 
  if not self then return error("Invalid argument no.1 to object.type().",2) end
  local meta = getmetatable(self) if meta and meta.__type then return meta.__type 
    else return type(self) end 
end -- returns: type string of object


-------- -------- -------- -------- 
-- object.is|...| -- Prefix
-------- -------- -------- --------
-- object.is: determins equality and types of a data value compared against others
-------- -------- -------- --------

object.is = function(self,...)
  if not self then return false end
  local count = select("#",...)
  if count == 0 then return false end
  for i = 1,count do
   if self ~= select(i,...) then 
    return false end end
  return true
end

-------- -------- -------- -------- 
object:extend("is")
-------- -------- -------- -------- 

-- TODO - this should either be lazy load or dynamic cache as objects are built rather than created each time  ...

local function _getProtoChain(self) -- helper: builds prototype reference table for objects
  
  local unshift = object.unshift
  
  local protos,list = {},{}
  local proto = self:proto()
  
  while(proto) do  
    unshift(list,proto); protos[proto] = true
    if proto == object then break end
    proto = proto:proto()     
  end
  
  -- ordered list of proto objects
  protos.list = list
  
return protos end  --> returns: (table) 
-- {[obj]:true, [obj]:true, 'list':{...}}

-------- -------- -------- -------- 

-- Tests if a data value is an instance of another object instance

object.is.instanceOf = function(self,...)
  
  local count = select("#",...)
  if not self or count == 0 then
  return false end
  
  local _type = type(self)
  if _type ~= "string" and _type ~= "table" then return false end
  local protoChain = false
  
  local isObject = _isObject(self) == true 
  
  for i = 1, select("#",...) do
    
    local arg = select(i,...)
    if _type == "string" and arg ~= string then 
    return false end 
    
    if self == arg or isObject and arg == object then -- implicit continue
    elseif isObject then
      if not _isObject(arg) then
      return false end
      
      -- cheates proto chain reference
      if not protoChain then
      protoChain = _getProtoChain(self) end
      if not protoChain[arg] then 
      return false end end
    
  end
  
return true end

-- Tests if an object is subclass / instance of another object or if a given data value is a certain lua / object type

object.is.typeOf = function(self,...) 

 local count = select("#",...)
 if not self then return false end
    
 local _type = type(self)
 local objType = baseType == "table" and self.type and self:type()
 local isObject = _isObject(self) == true 
  
 local arg,step = select(1,...), 1
 local isOfType = true
  
 while true do
     
  local argType = type(arg)       
  if arg == self then isOfType = true 
  elseif arg == nil then 
   isOfType = false break 
    
  -- (string) - object:type() or type() 
  elseif argType == "string" then
   if _type ~= arg and objType ~= arg then isOfType = false break end     
   elseif isObject and not self:isInstanceOf(arg) then
    isOfType = false break end
    
  step = step + 1 
  if step > count then break end
  arg = select(step,...) end
    
  return isOfType 
    
end

-- Tests if a data value is contained inside one or more data structures (shallow)

object.is.containedIn = function(self,...)
 local contains = object.contains 
 local count,arg = select("#",...)
 for i = 1,count do arg = select(i,...)
  if not contains(arg,self) then 
   return false end end 
 return true end -- returns: true by default

----- ------ ------- -------- ---------
-- [:toString] - pretty print data
----- ------ ------- -------- ---------

-- The object.toString function can take an optional second argument which is passed to the toStringHandler to provide more printing options / formats.

local function getToStringSettings()
    
  ---------- ---------- ---------- ------
  --> __tostring settings: [name]:type
    
  local settings = { ------ ------ ----
        
    -- show offsets --> table: 0x311d85a00
    offsets = "boolean", -- true|false
    ------ ----- -------- ---- -----    
    -- show lengths --> table[3]: {a,b,c}  
    lengths = "boolean", -- true|false
    ------ ----- -------- ---- -----   
     -- show sub tables --> {a,b,c,{d,e}}
    depth = "number", -- (0 -> math.huge)
    -- <----- <----- <----- <----- <---
    -----> -----> -----> -----> ----->
    -- [pretty print] --> style name    
    style = "string", -- 'vertical'|'block' 
    ------ ----- -------- ---- -----   
    -- [pretty print] --> spacer string        
    spacer = "string" -- "\t"," ",etc.
        
  } ------ ------ ------
  ---------- ---------- ---------- ------
    
  return settings ---> returns: {table}
    
end

----- ------ ------ ------ ------ ------

object.toString = function(self,opt) 

  if not _canFunctionRun { 
   method = "object.toString",
   types = {"table","string","number",
    "function","boolean","nil"},
   self = self } then return end
  
  -- string printing options to toString
  local optType = opt and type(opt)
  if optType == "string" then
    if opt == "vertical" or opt == "v" then 
      opt = object.copy(_tostringSettings)
      opt.style = "vertical"
    end
  end

  -- certain types are passed through to tostring unchanged
    
  local type = type(self)
  if type == "string" then return self
  elseif type == "boolean" or type == "number" or type == "nil" then
   return tostring(self)     
  end
  
  -- tables and functions are passed to the toStringHandler
    
  local meta = getmetatable(self)
  if meta and meta.__tostring and not opt then return tostring(self) end
  return _handleToString(self,opt)
    
end

-------- -------- -------- -------- 
object:extend("toString")
-------- -------- -------- -------- 

---- ---- ---- ----
-- (__tostring) - sets default behavior for  converting an object instance to a string

-- TBD - Change tostring.config to proxy?

object.toString.config = function(self,opt)

  if not _canFunctionRun { 
   method = "object.toString.config",
   types = {"table"}, isObject = true,
   self = self } then return end

  if type(opt) ~= "table" then
   return end
    
  local data = getDataStore(self)
  if not data.tostring then
   data.tostring =
    object.copy(_tostringSettings)
  end
  
  local tostringSettings = data.tostring
    
  ---------- ---------- ---------- ------
  local settings = getToStringSettings()
  ---------- ---------- ---------- ------
    
  for k,v in pairs(opt) do
    local setting = settings[k]
    if setting and type(v) == setting then
     tostringSettings[k] = v        
    end
  end
    
end

---------- -------- ----------
-- Note: This does not currently work inside an object scope -- WIP
---------- -------- ----------
object.tostring = object.toString
---------- -------- ----------

----- ------ ------- -------- --------
-- Access instance metatables and super classes / prorotypes
----- ------ ------- -------- --------

object.meta = function(self) -- Creates object reference to metatable
  local meta = getmetatable return meta(self)
 end -- returns: object metatable

object.super = function(self) -- Returns super class / prototype of object
  return getmetatable(self).__proto end 

-- alias for object.super
object.prototype = object.super 
object.proto = object.super

----- ------ ------- -------- --------
-- Binding Methods
----- ------ ------- -------- --------

-- TBD - Binding to a super which is already part of an object should do nothing. Binding a table to an object should do what? binding an object to an object with the same super should make a multiple inherited object and change the bindee object to this object. The bindees super doesnt directly become the object which it is bound to

object.bind = function(self,...)
  
  if _isObject(self) then return self
  else return object(self) end
  
return end

-- object:bindTo(...)

---------- -------- ----------

-- object.release is going to need to take object.bind

-- object:release with no args - Throw all binding away back to lua table
-- vararg - Release object bindings from multiple inheritence / supers

object.release = function(self,...)
  
  if not self then
  return error("Invalid argument no.1 to object.release().",2) end
  local format = type(self)
  if format ~= "table" or _isObject(self) == false
  then return self end
  
  setmetatable(self,nil)
  return self
  
end

---------- -------- ----------
object.unbind = object.release
---------- -------- ----------

-- object:releaseFrom(...)

----- ------ ------- -------- --------


---- ------ ----- --- ------ -----
-- ::WIP - begin:: - (unstable) --- --- --->
----- ------ --- ----- ------ ----

--[[

-- TBD - Think about if this is useful or redundant

object.closest = function(self,object)
    
  local isObject = _isObject(self)
  if type(self) ~= "table" or not _isObject(self) then return nil end
  
  if isObject then 
   local meta = object:meta()
   while(meta) do
    if meta == object then return true end
    meta = object:meta()
    end
   end
end

]]

------------------------------------------------------------------
-- Extra Utility Methods

object.asIterator = function(self) -- Creates iterator from index part of table
  local pos = 0 return function() pos = pos + 1 if self[pos] then return self[pos] end end 
end

------------------------------------------------------------------
-- Envitonment Manipulation to scope of objects

-- The environment is set to a scope object which reference the caller object as well as passes all index and key declarations back to the caller object. Scopes also posess a 'self' which indexes the caller object. The current scope can be modified with the object:setScope(), object:pushScope(), and object:popScope() methods. Scopes can also exist in 'for' closures through the object:inScopeOf() iterator. Upon the loop ending in these closures, the enviornment prior to the loop is returned reguardless of the environment within the closure. 

-------------------------------------------------------------------------------

-- private: formats vars in scope based on settings in _objectConfig

local function _formatScopeVar(self,key,var)
    
    -- if true then return var end
    
    local format = type(var)
    if format == "number" or format == "string" or (format == "table" and var._isPrefix == true) then return var     
    end
    
    if (_objectConfig.implicitSelf == true or _implicitSelfObj ~= nil) and format == "function" and (type(self) == "table" and self[key] ~= nil and _isObject(self)) then
        
        ------- ------- ------- -------
        -- Adds a wrapped callback for _ext nethods passing implicit self
        
        local wrapper,wrapperMeta = {},{
          __call = function(wrap,...)
            return self[key](self,...)
          end
        }
        
        setmetatable(wrapper,wrapperMeta)
        return wrapper
        
        ------- ------- ------- -------
        
    end
    
    --local (...)
            
    ------ ---- ------
    -- if true then return var end
    ------ ---- ------
    
    --[=[
    
    if isFunctionOrCallableTable(var) and 
    (_objectConfig.implicitSelf == true or _implicitSelfObj ~= nil) then
      return function(...) return var(...) end    
    end
    
    --[[
    if isFunctionOrCallableTable(var) and  _objectConfig.implicitSelf == true and (format == "table" and var._isObjectExt == false or format == "function") then 
        return function(...) return var(scope,...) end 
    end
    ]=]
    
    return var
    
end

-------------------------------------------

-- object [:focus() / :blur()]

-- Note: _objectConfig.implicitSelf set to true overrides these methods.

-- The :focus() and :blur() methods are used to enable/disabe the object which it is called on as the self (first argument) to methods within an objects class. i.e. If an object is in scope -> obj:inScopeOf() - push() would implicitly be called as push(self) / push(obj) 

-------------------------------------------

object.focus = function(self)
    _implicitSelfObj = self
end

object.blur = function()
    _implicitSelfObj = nil
end

-------------------------------------------

------ ------ ------ ------
-- Object Scope - API Notes
------ ------ ------ ------

-- Object Methods - Stack Calls

-- object:inScopeOf() -- Iterator overload - Iterate once and set scope to object implicitly -> local scope becomes object 

-- for scope in object:inScopeOf do
-- end

-- setScope(scope,bind/reset) - Update Dynamic Pointer
-- pushScope() -- Add to array and set dynamic pointer
-- popScope() -- Remove from array and set dynamic pointer

-- (for all) -> returns: scope

------ ------ 

-- TODO - Later - Think of this like an object, splice, slice, pop(index), etc. to change scope position (obfus idea from note 3-10-25 - 02:00)

------ ------ ------ ------

-- Scope Object Methods

-- scope:next() / scope:previous() - scope stack movement

-- scope:release() - clear stack / return to main scope
-- scope:bind(scope) - (alias) - clear scope stack and set to new scope - scope:bind(nil) - same as scope:release()

---- ----

-- TODO - Scope Traceback (Stack)

-- Improvement Idea: 1) Try to look at _G first - Is it the scope pointer?
-- 2) If you call debug to iterate up, store it in an array so you can look back without calling debug.getupvalue each time
-- 3) If 1 and 2 fail, use debug.getupvalue to iterate back and populate the array (2) to be used as an alternate for step 2
-- (Dynamic Pointer) Store a pointer to be used in 1 as the last if the last is not _G - See step 1

------ ------ ------ ------

local _getGlobalScope = function()
    
    if _VERSION ~= "Lua 5.1" then
      local scope -- = initial.global
      -- print("This is the scope:",scope)
      if not scope then scope = _ENV end
      return scope
    else return _G end
    
end

------ ------ ------ ------

if _VERSION == "Lua 5.1" then -- manipulates scope in versions prior to lua 5.2

  -- (private) Helper Functions ---------- ---------- ---------- ----------

 local function getLevel() -- Gets stack level of caller function
  local scope,err = 1,"no function environment for tail call at level "
  local env,error while true do env,error = pcall(getfenv,scope + 1) 
   if not env and error ~= err..tostring(scope + 1) then break end scope = scope + 1 end 
  return scope - 1 end -- Returns: number (stack level)      

  -- Iterators (for (values) in (iterator) do) ---------- --------

  object.inScopeOf = function(self) -- Sets environment within 'for' closure
   local cycle,env = 0, getfenv(getLevel() - 1) return function() cycle = cycle + 1 
    local scope = cycle == 1 and object.getScope(self) or cycle == 2 and env
    print("This is the level:",getLevel() - 1,scope)
    if scope then setfenv(getLevel() - 1, scope) -- Sets first to scope then _G
     return cycle == 1 and scope or nil end end end -- returns: scope object then nil

   -- Scope Stack Manipulation Methods ---------- ---------- ---------- ---------- 

   object.getScope = function(self) -- Gets object's global scope   
    if not self then return getfenv(getLevel() - 1) end -- Returns caller environment
    local scope,meta = {self = self},{__type = "scope", __prev = getfenv(getLevel() - 1),
    __index = function(val,key) -- Indexes in environment point to object
    local value = self[key] or _G[key] 
     --return _formatScopeVar(value) end,
     return value end,
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

-------------------------------------------------------------------------------    
    
elseif _VERSION == "Lua 5.2" or _VERSION == "Lua 5.3" or _VERSION == "Lua 5.4" then -- manipulates scope in lua 5.2 / 5.3 / 5.4
    
   -- Iterators (for (values) in (iterator) do) ---------- -------- 

   -- TODO - upvalue stack from scope?
    
   object.inScopeOf = function(self)
        
    local env,step = _getGlobalScope(), 0
    local scopeWrapper;
        
    scopeWrapper = function() 

     step = step + 1

     local i = 1
     local foundEnv = false
     local foundIndex;
    
     while true do
                
      local name,val = debug.getupvalue(scopeWrapper, i);
                
      if name == "_ENV" then
       foundEnv = val; foundIndex = i; break
      elseif not name then break
      end

      i = i + 1   

     end
          
     local environment = step == 1 and self:getScope() or env;
     local meta = getmetatable(self)
            
     if foundEnv then 
                
       -----------     
       -- This is the point where you change the upvalue - disable for debugging broken loops     
      debug.setupvalue(scopeWrapper,foundIndex,environment);
                
       -- _ENV = environment        
       ------------

      meta.__inScope = true end

     -- else _ENV = a end
            
--[[
     for key,value in pairs(environment) do print("key:",key,"value:",value) end
      print("This is the environment:",environment)
]]
            
     return step == 1 and environment or nil end

    return scopeWrapper end
    
   -- Scope Stack Manipulation Methods ---------- ---------- ----------  
    
   --- object.getScope: function
   object.getScope = function(self) -- Gets object's global scope   
    local currentScope = _getGlobalScope()
    if not self then 
        return currentScope end 
    local scope,meta = {self = self},{__type = "scope", __prev = currentScope,
            
    __index = function(val,key) -- Indexes in environment point to object
     local value = self[key] and self[key] 
      or currentScope[key]
      value = _formatScopeVar(self,key,value)
    return value end,
            
    __newindex = function(t,k,v) self[k] = v end} -- New indexes point to original object
     setmetatable(scope,meta) return scope end -- Returns new scope of object

   object.setScope = function(self) -- Sets global scope of caller function to object 
    if not self then local env,meta = _ENV, getmetatable(_ENV)
      while meta do if meta and meta.__prev then env = meta.__prev 
       meta = getmetatable(env) end end _ENV = env return end
    local scope = object.type(self) == "scope" and self or object.getScope(self)
    local meta = getmetatable(_ENV) if meta then getmetatable(scope).__prev = _ENV end   
        
     _ENV = scope return end
    
   --- object.pushScope: function
   -- Pushes a pointer to the current scope onto the stack - TBD: Do you ever want a copy -> env:copy()
    
   object.pushScope = function(self) 
        
    local env,scope = _getGlobalScope()
    local scope = object.type(env) == "scope" and env == self and env 
    scope = scope and scope or (env ~= self and object.type(self) == "scope") and self or self:getScope()
        
     if not scope and type(self) == "table" then scope = object(self):getScope()
     end
    
     if scope then
      getmetatable(scope).__prev = env   
     end
        
     _ENV = scope 
        
    return scope end
    
   --- object.popScope: function
   -- Removes last scope from scope stack
    
   object.popScope = function(self) 
         
    local scope = _getGlobalScope()     
    local meta = getmetatable(scope) if meta and meta.__prev then _ENV = meta.__prev return 
    else return error("No object is currently in scope.") end end    
    
   -- object.env = function() return _ENV end -- TODO - add this back with better pointer - getter?
    
end

---- ------ ----- --- ------ -----
-- ::WIP end:: - (unstable) --- --- --- (*)
----- ------ --- ----- ------ ----





------------ ------------ ------------ 
-- [debug] error handler / method checks
------------ ------------ ------------ 

-- used to configure error messages
_errorHandler = function(options)
    
    local concat = table.concat
    
    local self = options.self
    local method = options.method
    local errorType = options.error
    local types = options.types
    
    local message = options.message
    
    if errorType == "pcall" then
     return error(_stringifyTable{"pcall returned an error in ",method,': "',message,'".'})
        
    elseif errorType == "missingSelf" then
     return error(_stringifyTable{"argument 1 (self) to ",method," was nil."})
        
    elseif errorType == "notObject" then
     return error(_stringifyTable{"argument 1 (self) to ",method," was not an instance of object."})
        
    elseif errorType == "wrongType" then
     return error(_stringifyTable{"invalid argument 1 (self : ",self,") to ", method,". Expected type", 
      #types > 1 and "s" or "",":(",concat(types,"|"),") got:(",type(self),")."})
    end

end

-- checks if a method can run
_canFunctionRun = function(options)
    
  local method = options.method
  local types = options.types
  local self = options.self
    
  if not self then
   return _errorHandler{error = "missingSelf", self = self, method = method} end
    
  local format,typeMatch = type(self)  
  for i = 1,#types do
    if types[i] == format then
      typeMatch = true break end
  end
    
  if not typeMatch then return _errorHandler{error = "wrongType", self = self, method = method, types = types}end

  if options.isObject == true and not _isObject(self) then return _errorHandler{error = "notObject", self = self, method = method} end
    
  return true
    
end --> boolean - can method run

------------ ------------ ------------ 
-- __tostring handler - converts data values (namely tables) to readable strings
------------ ------------
-- note: also invoked with printing options by calling object.toString on any data type (see object.toString)
------------ ------------ ------------ 

_handleToString = function(value,opt)

    local concat,unpack = 
     table.concat,table.unpack
  
    local isObject = _isObject(value)
    local handleStr,objStr = _handleToString, _objSerialDescriptor
    
    local settings = object.copy(_tostringSettings)
  
   ---- --- ---- --- ---- --- ----
  
   local self, meta = value
   local entries,value = {} 
   local formatK,formatV,isObjectV

   -- when an object with __tostring config settings is handled, the config is in the object's data store  
    
   if isObject then
    local data = getDataStore(self,false)
    if data and data.tostring then
      settings = data.tostring    
    end end
  
   ---- --- ---- --- ---- --- ----
   -- options to the tostringHandler
    
   settings.data.indents = 1
   settings.data.nested = false
    
   ---- --- ---- --- ---- --- ----
   -- [opt] - passed in options 
   
   if opt and type(opt) == "table" then
    
    if opt.offsets ~= nil and type(opt.offsets) == "boolean" then
     settings.offsets = opt.offsets end
    if opt.lengths ~= nil and type(opt.lengths) == "boolean" then
     settings.lengths = opt.lengths end
        
    settings.depth = opt.depth and type(opt.depth) == "number" and floor(abs(opt.depth)) or settings.depth
        
    settings.style = opt.style and (opt.style == "block" or opt.style == "vertical") and opt.style or settings.style
        
    settings.spacer = opt.spacer and type(opt.spacer) == "string" and opt.spacer or settings.spacer
    
    ---- --- ---- --- ---- --- ----
    -- [opt.data] - recursive call data
        
    if opt.data then
       
      local indents = opt.data.indents
      if indents then
      settings.data.indents =     
        floor(abs(opt.data.indents))
      end
            
      settings.data.nested = opt.data.nested      
        
    end
         
   end   
    
   ---- --- ---- --- ---- --- ----
   -- settings to use for string gen.
    
   local style = settings.style
   local spacer = settings.spacer 
    
   local useOffsets = settings.offsets
   local depth = settings.depth
   local override = settings.override
    
   local indents = settings.data.indents
   local nested = settings.data.nested
    
   ---- --- ---- --- ---- --- ----

   local descriptor = type(self)
   if descriptor == "table" then descriptor = objStr(self,settings) end
    
   ---- --- ---- --- ---- --- ----
   -- (depth) data value stringification
   -- adds string data for leveles of nested tables. Defalts to level 1
    
   if depth == 0 then
    return concat{"(",descriptor,")"}
   end
    
   ---- --- ---- --- ---- --- ----
   -- (sort) - sort the list of indexies / keys for the tosteing display
  
   local list = {string = {}, number = {}, table = {}, ["function"] = {}}
   
   local valueType
   for key,val in pairs(self) do
    if val then 
     table.insert(list[type(key)],key)
   end end
    
   table.sort(list.string)
   table.sort(list.number)

   local sortList
   sortList = function(key)
    for i = 1, #list[key] do
     table.insert(list,list[key][i])     
    end list[key] = nil
    return sortList
   end
   
   sortList("number")("string")("table")("function") --> list: index/key order
    
   ---- --- ---- --- ---- --- ----
    
   for i = 1,#list do 
        
    local key,val = list[i],self[list[i]]
    formatK,formatV = type(key),type(val)  
    key,notation = formatK == "number" and key < 10 and "0"..key or key
        
    if formatV == "table" then
      meta,isObjectV = getmetatable(val), _isObject(val)
    else meta,isObjectV = nil,false end
        
    ---- --- ---- --- ---- --- ----
    -- (sub level) table entry notation
    
    -- shows function() pointers  
    if formatV == "function" then
     notation = useOffsets and tostring(val) or type(val)
     value = concat{"(",notation,")"}
    
    -- shows {table} / {object} pointers
    elseif formatV == "table" then
            
     if depth <= 1 then
      value = concat{"(", objStr(val,settings),")"}
                
     else -- shows {sub tables} (level > 1)
      local options = object.copy(settings) 
      options.depth = depth + 1
      options.data.indents = indents + 1   
      options.data.nested = true 
      value = handleStr(val,options)     
     end
            
    -- annotate "strings"
    elseif formatV == "string" then value = concat{'"',val,'"'} else value = tostring(val) end 
   
    local padding = object{}
    if style == "vertical" then 
     padding:push("\n",spacer)
     for i = 1,indents do
      padding:push(spacer)
     end
    end

   -- formats key / index display    
   local keyForm = object{padding:concat()}
        
   if formatK == "number" then 
    keyForm:push(tostring(key))
   elseif formatK == "function" then
    local str = useOffsets and tostring(key) or type(key)
    keyForm:push('[(',str,')]')
   elseif formatK == "table" then 
    local str = objStr(key,settings)
    keyForm:push('[(',str,')]')    
             
   elseif formatK == "string" then
    local varName = "^[%a_][%w_]*$"
    if key:match(varName) then
     keyForm:push(key)  
    else keyForm:push('["',key,'"]') end
         
   else keyForm:push(tostring(key)) end
   keyForm:push(":",value,"")  
   
   -- shows [key:value] pairs  
   local notation = keyForm:concat()
   table.insert(entries,notation)    
        
   end

   ---- --- ---- --- ---- --- ----
   -- output to toString
    
   local padding = object{}
   if style == "vertical" then 
    padding:push("\n")
    if nested then
     for i = 1,indents do
      padding:push(spacer)
    end end
   end
    
   return concat{"(",descriptor,"):{", concat(entries,", "), padding:concat(), "}"}
    
   ---- --- ---- --- ---- --- ----
    
end --> returns: serial descriptor string

------------ ------------ ------------ 

-- helper: gets a short string notation for object instances for the toStringHandler

_objSerialDescriptor = function(obj,opt)
    
  if not _canFunctionRun { 
   method = "_objSerialDescriptor",
   types = {"table"}, 
   self = obj } then
    return tostring(obj) end
    
  ------- ------- ------- ------- ---
    
  local concat,getmetatable,setmetatable = table.concat,getmetatable,setmetatable
    
  local self = obj
  local meta,descriptor
  local isObject = _isObject(self)

  local opt = opt and opt or _tostringSettings
    
  ------- ------- ------- ------- ---
  local offsetNotation = opt.offsets
  local showLengths = opt.lengths
  ------- ------- ------- ------- ---
    
  local meta,descriptor = getmetatable(self), not isObject and tostring(self) or ""
  local type,metaType = not isObject and type(self) or object.type(self), type(meta)
    
  ------- ------- ------- ------- ---
  local natStr = meta and meta.__tostring
  local sep = offsetNotation and ": " or ""
    
  -- adds length str -> i.e table[2]  
  local length = showLengths and concat{"[",#self,"]"} or ""
    
  -- adds offset notation -> 0x000000
  local offset = ""
    
  ------- ------- ------- ------- ---
    
  if offsetNotation then
   
   local str = descriptor
   if not isObject and (metaType ~= "table" or metaType == "table" and meta.__tostring == nil) then
     offset = string.match(str,"0x%x+")  
        
   else  
            
    ------- ------- -------
    if natStr then 
     setmetatable(self,nil) end
    ------- ------- -------

    str = tostring(self)
    offset = string.match(str,"0x%x+")
        
    ------- ------- -------
    if natStr then 
     setmetatable(self,meta) end
    ------- ------- -------
        
  end end
        
  ------- ------- -------
  -- shows the native __tostring output for tables passed into object.toString
    
  if natStr and meta.__tostring ~= _handleToString then
        
   local status,str = pcall(tostring,self)  
          
   if status == false then _errorHandler{error = "pcall", method = "handleToString", message = str} end
    local sep = sep == ":" and " " or ": "
    natStr = status == true and concat{sep,'{ __tostring = "',str,'" }'} or ""
        
  else natStr = "" end
    
  ------- ------- -------
    
  descriptor = concat{type,length,sep,offset,natStr}
    
  return descriptor --> returns: (string)
    
end

----- ----------- ----------- -----------
-- [private] - below this point -- >>
----- ----------- ----------- -----------

-------- ------ >>
-- helper: gets list of element(s) in object

_firstOrLast = function(self,dir,cnt) 
    
    local fromStart,count = dir == 1,cnt
    if not count or count == 1 then
        return fromStart and self[1] or self[#self] 
        
    else local val,out = abs(count),{}
        if fromStart then -- first entries
            for i = 1,count,1 do
                table.insert(out,self[i]) end        
        else -- last entries
            for i = #self - count + 1,#self,1 do  
                table.insert(out,self[i]) end
            
        end return unpack(out)
    end end -- returns: vararg of entries    

-------- ------ >>
-- helper: finds indexOf table elements  
  
_indexOf = function(self,last,...) 
    
  local count,first,args,keymap,matches = select("#",...), select(1,...)
    
  if count > 1 then
    args,keymap,matches = {...},{},{}
    for i = 1, #args do        
     if args[i] ~= nil then 
      keymap[args[i]] = false end
    end
  end

  local start,fin,step = last and #self or 1, last and 1 or #self, last and -1 or 1
    
  local found = 0
  for i = start,fin,step do
    
    if count ~= 1 then
     local arg = self[i]      
     if keymap[arg] == false then          
      keymap[arg],found = i,found + 1
      if found == count then break end    
     end
            
    elseif self[i] == first then
     return i end
          
  end
    
  for i = 1, #args do
    local index = keymap[args[i]]
    args[i] = index and index or "nil" 
  end
    
  return unpack(args)
    
end

-------- ------ >>
-- used to find objects in metadata

_isObject = function(self)
    
    if type(self) ~= "table" then return false end
    local meta = getmetatable(self)
    if not meta then return false end
    
    --[[
    -- legacy - maybe remove this later?
    if meta.__type ~= "object" then 
     return true end
    ]]
    
    local proto
    if meta.__index then
        while proto do
            if proto == object then 
                break 
            end
            proto = meta.__index
        end
    end
    
    return true
    
end

----- ----------- ----------- -----------

-- (object env) - The 'object' global variable space is used to represent the object environment and its methods. The object base class is referenced by the environment's meta.__index.

local meta = getmetatable(object) -- Allows object class to have independent extension instances

 setmetatable(_object,{__index = object, __call = meta.__call, 
  __version = meta.version, __type = "object env", __proto = object,
  __tostring = _handleToString })

object = _object; initExtensionLayer(object) -- updates object alias pointer

----- ----------- ----------- -----------

-- print("(object) was loaded ...", object)

return object

----- ----------- ----------- ----------- ----------- ----------- -----------
-- {{ File End - object.lua }}
----- ----------- ----------- ----------- ----------- ----------- -----------