-------------------------------------------
-- object.lua - 3.0 - (Beckett Dunning 2014 - 2025) - Object oriented lua programming 
---------- ---------- ---------- ---------- ---------- ---------- ---------- ----------
local Lib_Version = 3.05 -- object unified environment (dev build) - WIP (3-10-25)

-- This script adds an Object Oriented aproach to Lua Programming Calls. Traditionally in lua, there is little notion of inheritance or classes. This script allows for Javascript like progamming calls in chained sequence as opposed to the traditional structure of raw Lua

object,libs = {},{} local _object,object = object,{} -- aliases object class / stores libraries
local meta = {__index = self,__type = "object class", __version = Lib_Version,
    __tostring = function(self) -- gives objects a tostring native behavior
    local vals = {} for k,_ in pairs(self) do table.insert(vals,tostring(k)) end
    table.sort(vals) return "(object baseClass):["..table.concat(vals,", ").."]" end,
    __call = function(self,...) -- creates object class from initializer
    return -- self.init and self:init(...) or 
    self:new(...) end } 
    setmetatable(meta,{__type = "object meta", __index = object }) setmetatable(object,meta)
    
-- Local variable declaration for speed improvement
local type,pairs,table,unpack,setmetatable,getmetatable,getfenv,setfenv,object = 
type,pairs,table,table.unpack,setmetatable,getmetatable,getfenv,setfenv,object
local abs,pi,cos,min,max,pow,acos,floor,sqrt = math.abs,math.pi,math.cos,
math.min,math.max, math.pow,math.acos,math.floor,math.sqrt
    
-- accepted metatable keys to be parsed from object
local meta_tables,meta_ext = { __index = true, __tostring = true,  __newindex = true, __call = true, __add = true, __sub = true, __mul = true, __div = true, __unm = true, __concat = true, __len = true, __eq = true, __lt = true, __le = true}, { __type = true, __version = true, __namespace = true}

------------ ------------ ------------ ------------
-- Configuration methods for object instance behavior in code / within scopes

local _objectConfig = {
    
    ------ -------- ------ --------
    
    -- Allows for object.prefix expansion in a scope using dot syntax i.e - tree.insert.first("apple") inserts "apple" at the first index of object tree.
    
    -- Note: tree.insert:first("apple") would have the same effect.
    
    dotObjectRef = false,
    
    ------ -------- ------ --------
    
    -- Implicit 'self' - When in the scope of an object (i.e. tree:inScopeOf) pass self as first argument to base methods.
    
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
}

------------ ------------ ------------

-- Holds implicit self pointer ref. (see _objectConfig.implicitSelf)

local _implicitSelfObj = nil 

------------ ------------ ------------ 

-- Helper Functions

local function isCallableTable(value)
    local metatable = getmetatable(value)
    if metatable and metatable.__call then return true
    else return false end
end

local function isFunctionOrCallableTable(value)
    local valueType = type(value)
    if valueType == "function" then return true
    elseif valueType ~= "table" then return false end
    return isCallableTable(value)
end

-- pretty print data value (i.e. table)
local toStringHandler = function(value)

   local self = value
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
   table.sort(entries) 
    
    local type = tostring(getmetatable(self)).__type or type(self)
    
    local stringification = table.concat{"(",type,"):{",table.concat(entries,", "),"}"}
    
    return stringification -- sorts entries / returns: descriptor string
    
end

------------ ------------ ------------ ------------ ------------ ------------ ------------ 
-- Object Extension Module :init() - (object:ext()) ----------- ----------- ---------

local function getInheritedValue(self,prototype,key) 
    
    --print("I was called")
    local protoIndex = getmetatable(prototype).__index
    
    if isFunctionOrCallableTable(prototype[key]) and isCallableTable(protoIndex[key]) then
        local objectType = object.type(protoIndex[key])
        --print("This is self:",self)
        
        if objectType == "ext.prefix" then
            local wrapper = prototype._ext[key](self)
            local wrapperMeta = getmetatable(wrapper)
            
            wrapperMeta.__call = function(self,...) return prototype[key](...) end
            wrapperMeta.__modifiedExt = true
            return wrapper end
    end
    
    return prototype[key]     
    
end

local function initExtensionLayer(self) -- (private) initializes object extension layer
    local meta = getmetatable(self) if meta == nil then meta = {} setmetatable(self,meta) end
    if not meta.__exIndex then 
        meta.__exIndex = {} setmetatable(meta.__exIndex,{__type = "extLayer"})
    elseif meta.__exIndex == true then local exIndexMeta = {} -- makes new layer referencing superclass 
        for k,v in pairs(getmetatable(meta.__proto)) do exIndexMeta[k] = v end 
        meta.__exIndex = {} setmetatable(meta.__exIndex,exIndexMeta) end
    local exIndex,super = meta.__exIndex,{} setmetatable(super,{__index = meta.__index});  
    
    getmetatable(exIndex).__index = function(exIndex,key) -- (lazy unpack) instantiates extensions
        
        local protoIndex = getmetatable(meta.__proto).__index
        local keyIsModified = protoIndex and protoIndex[key] and isCallableTable(protoIndex[key]) and getmetatable(protoIndex[key]).__modifiedExt == true
    
        if (protoIndex and protoIndex[key] ~= super[key]) or keyIsModified then 
          exIndex[key] = getInheritedValue(self,meta.__proto,key) return exIndex[key]
        elseif super._ext and super._ext[key] then exIndex[key] = super._ext[key](self) return exIndex[key] end
        return super[key] end 
    
    -- sets a constructor instance for objects
    exIndex.constructor = super.new
    
    meta.__index = exIndex 
    
return meta.__exIndex end -- returns: extension layer

local function hasExtensionLayer(self) -- (private) determines if table has ext layer
    local meta = getmetatable(self) if meta and meta.__exIndex then return true, meta.__exIndex 
    else return false end end -- returns: true and extension layer if found or false otherwise

local function getExtensionIndex(self)
    local hasIndex,exIndex = hasExtensionLayer(self)
    if not hasIndex then exIndex = initExtensionLayer(self) end
    return exIndex 
end

------------ ------------ ------------ ------------ ------------ ------------ ------------ 
-- object extension module -> object:extension():method() | object.extension:method()

-- The extensions module creates extensions which can perform various functions which normally exceed the standard bounds of lua. This is not one single method, but more a collection of meethods which together extend the object class. Extensions are not private to objects, and any lua table can adopt an extension. Exposed extensions are below ...

-- [ :ext():prefix() / :ext():dictionary() ] These methods both create data structures which pass their selfness to an internal method call as their root object. Dictionary extensions store data internally in their meta.__dataStore and are pulled into an object when edited, while prefix extensions reference the keys in the root object which begn with their key name. Declaration and usage is below...
------------ ------------ ------------ ------------ ------------ ------------ ------------

local function getExtStore(self) -- (private) points to / creates object.ext store
    local target,ext 
    if self ~= object then -- stores extensions in __exIndex of metatable
        local layer,meta = getExtensionIndex(self),getmetatable(self)      
        target,ext = layer, meta.__proto and meta.__proto._ext or nil
        
    else target,ext = self,self._ext end -- stores extensions in self 
    if not rawget(target,"_ext") then -- creates .ext index if not present
        meta = {} target._ext = {} local cache = ext or object._ext 
        for k,v in pairs(getmetatable(cache)) do meta[k] = v end meta.__index,meta.__proto = ext,ext;   
    setmetatable(target._ext,meta) end return target._ext end

local function _extSetter(ext,wrapper) -- (private) creates setters ext().setter(val).key
    
    return function(self,name,method) -- (static) creates wrapper for calls
        
        local store = self ~= ext and getExtStore(self)(self) or self 
        if not name and not method then -- determines _:ext:prefix() method output
            
            local caller = {} setmetatable(caller,{ -- creates _:ext:wrapper() calling object
                
                __newindex = function(alias,key,value) store[key] = wrapper(key,value) end,
                
                __call = function(...) return wrapper(name,method)(store)(...) end }) return caller
            
        else store[tostring(name)] = wrapper(name,method or function() end) end end end

local function getBackReference(self) -- (private) gets target table of alias layers
    local target,meta = self while target do meta = getmetatable(target) 
        if meta and meta.__self then target = meta.__self -- iterates through aliases
        else return target end end end -- returns: alias root target

------------ ------------ ------------ 
object._ext = {} 
------------ ------------ ------------ 

local extMeta = { -- .ext() is a dynamic module
    
    __tostring = function(self) -- reports details when converted to string
        local names,layer,name = {},self while layer do for k,v in pairs(layer) do 
            table.insert(names,tostring(k)..":("..getmetatable(v(object)).__type..")") end 
        layer = getmetatable(layer).__proto end table.sort(names)
    return "(ext cache):{"..table.concat(names,", ").."}" end,
    
    __index = function(ext,key) return ext(getBackReference(ext))[key] end, -- object.ext:method()
    
    __call = function(ext,obj)  -- invoked when calling object:ext()
        if not obj then error("invalid arg. no.1 (lua table) to object.ext().",2) return end 
        
        local extender,meta = {},{ -- extender -> returned by object:ext()   
            
            __newindex = function(self,key,value) -- [newindex] object.ext[key] set / object[key] unwrapped
                local store = getExtStore(obj) store[key],obj[key] = value, value(obj) end,
            
            __index = function(extension,key) 
                
                local ext = {} -- handles indexes to _:ext()        
                
                ---------- ---------- ---------- ---------- ---------- ---------- ---------- ----------
                -- [ext().prefix()] - Declare: :ext():|prefix|().name = method / :ext():|prefix|(name,method)
                -- Declare Key: :|prefix|().|key| = method / .|prefix||key| = method
                -- Call Key: object:prefix():key() / object.prefix:key() / object:|prefix||key|()     
                ---------- ---------- ---------- ---------- ---------- ---------- ---------- ----------
                
                ext._prefix = _extSetter(extension, function(name,method) -- (passUp) object indexer / sorter
                    return function(self)  
                        
                        local extension,meta = {_isPrefix = true},
                         { __type = "ext.prefix", __self = obj,
                            
                            __tostring = function(pointer) -- (ext) returns prefix descriptor string
                                local level,list,entry,key,val = self,{} while level do key,val = next(level)
                                    while val do if string.find(key,"^"..name) then entry = string.gsub(key,"^"..name,"") 
                                            if entry ~= "" then for i = 1,#list do if list[i] == entry then entry = "" break end end end
                                            list[#list + 1] = entry ~= "" and entry or nil end key,val = next(level,key) end       
                                level = getmetatable(level) level = level and level.__proto end table.sort(list)
                            return "(ext.prefix _:"..name.."|...|):{"..table.concat(list,", ").."}" end,      
                            
                            __newindex = function(pointer,key,value) -- declaration: obj.|prefix|.|name| = method        
                            
                                -- _caseStr: converts first char of string to lowercase or uppercase 
                                
                                local _caseStr = function(str,upper)
                                 local format = function(a,b) 
                                  local upperOrLower = upper and string.upper or string.lower
                                    return upperOrLower(a)..b end
                                    return string.gsub(str,"(%a)(%a+)",format) 
                                end
                                
                                local entry,internal = tostring(key) 
                                local names = {_caseStr(entry,true),_caseStr(entry,false)}
                                
                                for i = 1,2 do
                                  local entry = name..names[i]
                                  if not value and not rawget(self,entry) then
                                  internal = false error("Extension cannot modify superclass.",2) else internal = true end
                                  self[entry] = (not value and internal) and nil or value
                                end
                            
                            end,
                            
                            __index = function(pointer,key) -- indexing statement: _.|prefix|:|name|()
                                
                                local key = name..tostring(key)
                                local path = self[key] local format = type(path)
                                
                                if format == "function" then return function(v,...) -- redirector function for calls
                                
                                 --[[
                                 if true and path then return function(...) 
                                  return path( ...) end end
                                 ]] --end
                                        
                                 --- --- -----
                                 if v == pointer then return path(self,...)
                                 -- elseif pointer._isPrefix == true then print("ok") return pointer
                                 elseif self == object then return object[key](v,...) 
                                 end
                                 --- --- ----
                                        
                                 ---- ------ ---- ------ ---- ------
                                 -- overload: objectInst.[ext].[val] points to objectInst i.e. tree.insert.first("apple") -> tree{"apple"}
                                        
                                 if _objectConfig.dotObjectRef == true then
                                  return path(self,v,...)       
                                 end
                                        
                                 ---- ------ ---- ------ ---- ------
                                    
                                end 
                            
                                elseif key ~= "__self" then return path end  
                                return path
                            
                            end, -- returns: redirector or key actual 
                            
                            __call = function(pointer,obj,...) -- calling statement: _:|prefix|() / _:|prefix|():|name|()          
                                     
                                if not obj then return end local extra = select("#",...)
                                local meta = obj and getmetatable(pointer)
                                
                                if obj == pointer and extra == 0 then return pointer
                                elseif extra == 0 and type(obj) == "table" then 
                                  return obj[name] and obj[name] or
                                   getBackReference(pointer)[name]                    
                                else return method(obj,...) end end 
                            
                        } setmetatable(extension,meta) return extension end end ) 
                
                return ext[key]  
                
            end
            
        } -- returns: pointer to method in entry
        
        setmetatable(extender,meta) 
        
    return extender end }

-- Sets up metatable for object.ext
setmetatable(object._ext,extMeta)

------------------------------------------------------------------
-- Primative Object Constructor -> object:new() | object()

-- The new metamethods for an object subclass are passed at the time of initialization. If metatable elements are detected, they are removed from the objects methods and added to its metatable. The imput object as well as the output object retured can be used to add new methods and values to a class, but new metamethods will not be detected after initial initialization.

-- object.init = function(self) end -- Called upon object initiation

object.new = function(super,self) -- (object) - base constructor 
    local meta,superMeta = {},getmetatable(super) meta.__index = super == object and superMeta.__proto or super
    
    -- Note (3-9-25): meta.__proto used to be set to meta.__index. This was changed to meta.__index = super. This may have unexpected effects in classes which use object (see below)
    
    meta.__proto,meta.__exIndex = meta.__index,superMeta.__exIndex and true for k,v in pairs(superMeta) do 
        if not meta[k] then meta[k] = type(v) ~= "table" and v or object.copy(v) end end
    meta.__type = super == _object and "object" or meta.__type 
    self = type(self) == "table" and self or {}
    
    -- object.constructor = super.new
    
    -- Iterates over passed in table and moves metamethods to metatable
    for key,value in pairs(self) do
        if meta_tables[key] or meta_ext[key] then
            meta[key], self[key] = value, nil
        end
    end
    
    setmetatable(self,meta) initExtensionLayer(self) -- creates and initializes object meta
return self end -- returns: new object instance

-------------------- -------------------- --------------------     
-- (_.insert, _.remove) - Prefix Block Extensions
------------------- - -------------------- --------------------     
-- These hardcoded prefix extensions search for the insert or remove prefix when referenced to create custom method call blocks. Using the declaration syntax, subclasses can append custom local methods to these extensions. The usage structure is below:
-- Declaration: object.|insert/remove|Extension IE: object.insertValue
-- Calling Examples: object:insertValue() object.insert:Value() object:insert():Value() 
-------------------- -------------------- --------------------     

object:_ext():_prefix().remove = table.remove; object:_ext():_prefix().insert = table.insert

-- object:_extPreix().remove = table.remove; object:_extPrefix().insert = table.insert

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

-- Values can be inserted from an existing table rather than having to be ennumerated manually in the insert declaration. Other simpler method namespaces ( will also be ) utilized.

object.insert.FirstIndexiesFromTable = function(self,source) -- inserts indexies first into self
    if not source then return self else for i = 1,#source do -- coppies indexies from source into self
            table.insert(self,i,source[i]) end return self end end

object.insert.LastIndexiesFromTable = function(self,source) -- inserts indexies last into self
    if not source then return self else local total = #self -- coppies indexies from source into self
        for i = 1,#source do table.insert(self,i + total,source[i]) end return self end end

object.insert.AtIndexIndexiesFromTable = function(self,index,source) 
    if not index or not source then return end local total = #self + 1
    local index = index <= 1 and 1 or index >= total and total or index
    for i = 1,#source do table.insert(self,index + i - 1, source[i]) end return self end 

object.insert.IndexiesFromTable = function(self,source,overwrite) -- inserts indexies from table
    if not source then return self end if overwrite ~= false and overwrite ~= 0 then 
        for i = 1,#source do self[i] = source[i] end -- coppies indexies from source into self
    else for i = 1,#source do -- coppies entries if not present in self
            if not rawget(self,i) then self[i] = source[i] end end return self end end

object.insert.KeysFromTable = function(self,source,overwrite) -- inserts keys from existing table
    if not source then return self end local index,value = next(source)
    if overwrite ~= false and overwrite ~= 0 then while index do -- overwrite: defaults to true
            self[index] = value index,value = next(source,index) end -- overwrites duplicate keys in self       
    else while index do if not rawget(self,index) then self[index] = value end -- only adds new keys
        index,value = next(source,index) end end return self end

---- ------ -------- ---------- --------

-- object.remove|...| -- These functions are used to remove data from the array portion of an object. All the methods can be referenced from calling their direct method name or by using the object:remove() 

object.remove.Index = function(self,index) -- bridged for table.remove method
return table.remove(self,index) end -- returns: table.remove output

object.remove.Indexies = function(self,...) -- removes vararg of indexies from table
    local out,length = {},select("#",...) if length == 0 then return end
    local args = {...} table.sort(args, function(a,b) return a > b and true or false end)        
    local pos,last,index = 0 for i = length,1,-1 do index = args[i]
        if index ~= last and self[index] then pos = pos + 1 out[pos] = table.remove(self,index)
        last = index end end table.sort(out, function(a,b) return a < b and true or false end) 
return unpack(out) end -- returns: vararg of removed values

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

object.remove.IndexiesOf = function(self,...)
    
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

object.remove.Entry = function(self,entry) -- finds entry in table and removes all instances
    if not self then error("Invalid argument no.1 'self' to object.removeEntry().") end
    --print(self)
    object.removeIndexiesOf(self,entry)
    local keys = object.keysOf(self,entry) 
    for i = 1,#keys do self[keys[i]] = nil end
return entry end

object.remove.Entries = function(self,...) -- finds values in table and removes them
    if not self then error("Invalid argument no.1 'self' to object.removeEntries().") end
    local args,pos = {...} for i = 1,#args do 
        object.removeEntry(self,args[i]) end 
return unpack(args) end

-- (alias names) - object.insert|...| / object.remove|...| declaration point ...

object.unshift, object.shift, object.push, object.pop, object.slice =
object.insertFirst, object.removeFirst, object.insertLast, object.removeLast, object.removeAtIndex

------------------------------------------------------------------
-- (public) Object Native Logistics / Querying Methods
------------------------------------------------------------------

-- An object is created with pointers to methods which can evaluate and modify data which is contained within an object. While these functions do exist in deeper object classes, they can be overriden by methods inherited from those classes.

object.countElements = function(self) -- gets number of elements in object
    local i,index = 0,next(self) while index do i = i + 1 index = next(self,index) end return i end
object.length, object.size = object.countElements, object.countElements

object.contains = function(self,val,...) -- determines if table contains entry
    local num = select("#",...) if val and num == 0 then -- used if only one argument is passed
        local pairs = pairs for _,v in pairs(self) do if v == val then return true end end return false     
    else local vals = {val,...} -- used if more than one argument is passed
        local next,remove,total = next,table.remove,#vals local index,value = next(self)             
        while index do for i = 1, total do if vals[i] == value then remove(vals,i) 
                    if total - 1 == 0 then return true else total = total - 1 break end end end      
        index,value = next(self,index) end end return false end -- returns: true or false

--object.hasKeys = function(self,val,...)

object.indexiesOf = function(self,val,...) -- finds all numerical indexies of arguments
    local out = {} if select("#",...) == 0 then for index = 1,#self do -- handles one index query
            if self[index] == val then table.insert(out,index) end end return out -- returns: indexies array
    else local values,target,val = {val,...} -- handles multiple index queries
        for i = 1,#values do val,target = values[i],{} table.insert(out,target) for index = 1,#self do
                if self[index] == val then table.insert(target,index) end end  end
    return unpack(out) end end -- returns: vararg of index arrays

object.keysOf = function(self,val,...) -- finds all numerical indexies and keys of arguments
    local out = {} if select("#",...) == 0 then -- handles one keys query
        local key,value = next(self) while key do if value == val then table.insert(out,key) end 
        key,value = next(self,key) end return out -- returns: array of keys
    else local values,target,key,val,value = {val,...} -- handles multiple index queries
        for i = 1,#values do val,target = values[i],{} table.insert(out,target) key,value = next(self) 
            while key do if value == val then table.insert(target,key) end key,value = next(self,key) end end
    return unpack(out) end end -- returns: vararg of key arrays

object.keys = function(self) -- gets keys of an object 
    local keys = {} local pos,index = 1,next(self) while index do 
        keys[pos],index = index,next(self,index) pos = pos + 1 end
return keys end -- returns: array of table keys

-- (_:first) Prefix - returns firsts in calling
-------------------- -------------------- --------------------     
object.first = function(self,number) -- gets first element(s) of object
    if not number or number == 1 then return self[1] else local val,out = abs(number),{}
        for i = 1,val do if self[i] then out[i] = self[i] else break end end 
    return unpack(out) end end -- returns: vararg of entries

object.firstIndexOf = function(self,val,...) -- finds first numerical indexies of args
    if select("#",...) == 0 then for index = 1,#self do -- handles one index query
            if self[index] == val then return index end end return nil -- returns: first index o
    else local values,target,val,found = {val,...} local max = #values -- handles multiple index queries
        for i = 1,max do val = values[i] found = false for index = 1,#self do if self[index] == val then 
                    values[i] = index found = true break end end if not found then values[i] = nil end end
    return unpack(values,1,max) end end -- returns: vararg of index numbers or nils

-- (_:last) Prefix - returns lasts in calling
-------------------- -------------------- --------------------     
object.last = function(self,number) -- gets last element(s) of object
    if not number or number == 1 then return self[#self] else local val,out,max = abs(number),{},#self
        for i = max, (max + 1) - val, -1 do if self[i] then out[(max + 1) - i] = self[i] else break end end 
    return unpack(out) end end -- returns: vararg of entries

object.lastIndexOf = function(self,val,...) -- finds last numerical indexies of args
    if select("#",...) == 0 then for index = #self,1,-1 do -- handles one index query
            if self[index] == val then return index end end return nil -- returns: last indes of val
    else local values,target,val,found = {val,...} local max = #values -- handles multiple index queries
        for i = 1,max do val = values[i] found = false for index = #self,1,-1 do if self[index] == val then 
                    values[i] = index found = true break end end if not found then values[i] = nil end end
    return unpack(values,1,max) end end -- returns: vararg of index numbers or nils

--[[object:ext():prefix().copy = function(self,layers,layersM) -- 
local meta,out,rep = getmetatable(self),{},1
end

object:copy(0,0)
object.copy:Keys() object.copy:Hash() object.copy:Indexies() object.copy:Meta()
]]

-- Object Status / Configuration Methods
-------- -------- -------- -------- -------- -------- -------- --------

object.inverseIndexies = function(self) -- Inverses numerical indexies of array
  local pos = 0 for i = #self,1,-1 do i = i + pos self:insert(pos + 1, self:remove(i)) 
  pos = pos + 1 end  return self
 end

object.concat = function(self,sep) -- Concantinates table indexies
  local concat = table.concat return concat(self,sep)
 end -- returns: "indexies..sep,... string"

---------- -------- ----------

-- Gets objects' __type values or data type

object.type = function(self) 
    if not self then return error("Invalid argument no.1 to object.type().",2) end
    local meta = getmetatable(self) if meta and meta.__type then return meta.__type 
    else return type(self) end 
end -- returns: type string of object

-- Tests if an object is subclass / instance of another object or a data value is a certain type

object.isTypeOf = function(self,...) 
    
    local count = select("#",...)
    if not self then return false end
    
    local baseType,argStep = type(self), 1
    local objType = baseType == "table" and self.type and self:type()
    local arg = select(argStep,...)
    
    local objClass = object:proto()
    local isOfType = true
    
    while true do
        
        local argType = type(arg)    
        
        -- (object) - object pointer
        if argType == "table" and baseType == "table" and self._isObject and self._isObject() == true and arg._isObject and arg:_isObject() == true then
            
            local proto = self:proto()
            local match = false
            
            if arg == object then
                match = true        
                
            else
                while proto ~= nil do
                    if proto == arg then match = true break end  
                    proto = proto:proto()   
                end     
            end
            
            isOfType = match and true or false
            
            -- (string) - object:type() or type()
        elseif argType == "string" then
            if baseType == arg or objType == arg then match = true
            elseif baseType ~= argType and objType ~= argType then 
            return false end  
        end
        
        argStep = argStep + 1, true
        if argStep > count then break end
        arg = select(argStep,...)
        
    end
    
    return isOfType 
    
end

object.isInstanceOf = object.isTypeOf
object.isOfType = object.isTypeOf

---------- -------- ----------

-- Binding Methods

-- TBD - Binding to a super which is already part of an object should do nothing. Binding a table to an object should do what? binding an object to an object with the same super should make a multiple inherited object and change the bindee object to this object. The bindees super doesnt directly become the object which it is bound to

object.bind = function(self,...)
    
    if object.isObject(self) then return self
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
    if format ~= "table" or object.isObject(self) == false
    then return self end
    
    setmetatable(self,nil)
    return self
    
end

object.unbind = object.release

-- object:releaseFrom(...)

---------- -------- ----------

-- object super / meta / proto methods

object.meta = function(self) -- Creates object reference to metatable
    local meta = getmetatable return meta(self)
end -- returns: object metatable

object.super = function(self) -- Returns super class / prototype of object
    local meta = getmetatable(self)
return meta and meta.__proto end 

object.prototype = object.super 
object.proto = object.super

---------- -------- ----------

object.meta = function(self) -- Creates object reference to metatable
  local meta = getmetatable return meta(self)
 end -- returns: object metatable

object.super = function(self) -- Returns super class / prototype of object
  return getmetatable(self).__proto end 
object.prototype = object.super -- alias for object.super

object.copy = function(self) -- Creates a deep copy of object table and metatable
  local meta,metaFm,copy = {}, getmetatable(self) or {},{} for k,v in pairs(metaFm) do meta[k] = v end
  for key,value in pairs(self) do if type(value) ~= "table" then copy[key] = value
  else copy[key] = object.copy(value) end end setmetatable(copy,meta) 
  return copy 
end -- Returns: object - copy of object

object.toString = toStringHandler -- Pretty print table / object

------------------------------------------------------------------
-- Extra Utility Methods

object.asIterator = function(self) -- Creates iterator from index part of table
  local pos = 0 return function() pos = pos + 1 if self[pos] then return self[pos] end end 
end

-------------------------------------------
-- (alias names)

object.proto = object.super

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
    
    if (_objectConfig.implicitSelf == true or _implicitSelfObj ~= nil) and format == "function" and (type(self) == "table" and self[key] ~= nil and self._isObject() == true) then
        
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

-- The :focus() and :blur() methods are used to enable/disabe the object which it is called on as the self (first argument) to methods within an objects class. i.e. If an object is in scope -> obj:inScopeOf() - push() would implicitly be called as push(self) / push(obj) 

--  Note: _objectConfig.implicitSelf set to true overrides these methods.

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
      local scope = _ENV or _G
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
            
     if foundEnv then debug.setupvalue(scopeWrapper,foundIndex,environment); 
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

----- ----------- ----------- -----------
-- private methods below this point

object._isObject = function()
    return true
end

----- ----------- ----------- ----------- ----------- ----------- -----------
----------- ----------- -----------  ----------- ----------- ----------- -----------

-- (object env) - The 'object' global variable space is used to represent the object environment and its methods. The object base class is referenced by the environment's meta.__index.

local meta = getmetatable(object) -- Allows object class to have independent extension instances

 setmetatable(_object,{__index = object, __call = meta.__call, 
  __version = meta.version, __type = "object env", __proto = object,
  __tostring = toStringHandler })

object = _object; initExtensionLayer(object) -- updates object alias pointer

---------- ---------- ----------

-- Private Class Methods entered after this point ...

----------- ----------- ------ ----- ----------- ----------- ----------- -----------
----- ----------- ----------- ----------- ----------- ----------- -----------

--[[
function iter(self)
    local env,step = _ENV or _G, 0
    return function() step =step + 1
        if step == 1 then local a = getScope(self) _ENV = a return a
        else _ENV = env return end
    end
end
]]

-- return object

----- ----------- ----------- ----------- ----------- ----------- -----------

----- ----------- ----------- ----------- ----------- ----------- -----------
-- {{ File End - object.lua }}
----- ----------- ----------- ----------- ----------- ----------- -----------