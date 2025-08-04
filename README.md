object.lua
==========

This class has a collection of methods and functionality which could be used to build and debug code when working in Lua. There are also certain structures which can make code structures feel like other scripting languages.

```
Constructor: object() / object.new()
```

```lua
local value = object() / object.new()
print("Hello object!")
```

------ ------ ------ ------

One of the goals with writing this class of methods is to provide more functions / methods to apply to the lua base classes. The :ext() is meant to help with dot or colon syntax chaining, while the inheritence is meant to help extend classes. Logging is meant to help with the debug process such that at any level of the code chain a table representation could potentially be expanded.

------ ------ ------ -----

```lua

-- Example of a pseudo class using object and :ext(?

getTestClass = function()
  
   ------- ------ ----- ------ ------- >>
   -- Object class declarations ...
  
   local baseObject = object()
  
   ------ ---- ------ ---- ------ ---- 
  
   baseObject.list = function(self)
    return self:indexies()
   end
  
   ------ ---- ------ ---- ------ ----  
   baseObject:ext("list") 
   ------ ---- ------ ---- ------ ----
     
   baseObject.list.numbers = function(self)

    local numbers = object()
    for _,index in pairs({self:indexies()}) do
     if type(index) == "number" then
      numbers:push(index) end end
     return numbers
  
   end 
  
   baseObject.list.strings = function(self)
    
     local strings = object()
     for _,index in pairs({self:indexies()}) do
       if type(index) == "string" then
        strings:push(index) end end
      return strings
    
   end
  
   ------ ---- ------ ---- ------ ----
   local list = baseObject.list
   ------ ---- ------ ---- ------ ----
   list:extend("numbers")
   ------ ---- ------ ---- ------ ----
  
   -- (helper) - list even or odd indexies
   local function _evenOrOdd(self,even)
     
    local numbers = self.list:numbers()
    local numberList = object()
    for i = 1,#numbers do
     local number = numbers[i]
     if number % 2 == (even and 0 or 1) then
       numberList:push(number)
     end end    
    return numberList
    
  end
  
  ---- ---- ----
  
  list.numbers.even = function(self)
    return _evenOrOdd(self,true)  
   end
  
  list.numbers.odd = function(self)
    return _evenOrOdd(self,false)  
  end
  
  
  ------- ------ ----- ------ ------- >>
  
  return baseObject -- returns: test object 
  
end

```

```lua

-- Tests the pseudo class code ...

testObject = function()
  
  local sampleObject = {"a",44,"b",a=4,22,"c","d",1,2,3,4,5,"e" 
  ,3.14159,"ff"}
  
  local testClass = getTestClass()
  
  local test = testClass(sampleObject)
  
  test:extend("unshift")
  test.unshift.twice = function(self,...)
    for i = 1,2 do self:unshift(...) end
    return self 
  end
  
  test:push(343,357):unshift(547)
  test.unshift:twice("foo","bar")
  
  print(test,testClass:tostring("v"))
  
  print(test.listnumbers:odd())
  
  print(test.list.numbers.self) -- self pointer for proxy :ext() object

end

```

------ ------ ------ ------

`object.ext / object.extend` - Object Extensions


```
-- object:ext("name") -> object.name 
-- object:name.value = ??
-- object.name.value:ext("otherName")
-- object.name.value.otherName = ?? ...

-- local someObject = object()

-- someObject inherits from object (base class) and ":exts" allow for dot / colon chaining back to the self object (someObject)

```

------ ------ ------ ------

Custom Object Syntax

```
-- These prefix extensions search for the insert or remove prefix when referenced to create custom method call blocks. Using the declaration syntax, subclasses can append custom local methods to these extensions. The usage structure is below:
Declaration: object.|insert/remove|Extension IE: object.insertValue
Calling Syntax Examples: 

object:insertValue() 

object.insert:value() / object.insert:Value()
object.insert.value() / object.insert.Value() 

object:insert():Value() / object:insert():value()
object:insert().Value() / object:insert().value()
```

Usage example:

```lua
local tree = object{leaves = "green")
tree:insertFirst("branches") --> tree{"branches",leaves = "green"}
tree.insert.first("bark") --> tree{"bark","branches",leaves = "green"}
tree.insert:Last("dew") --> tree{"bark","branches",leaves = "green","dew"}
```

------ ------ ------ ------

Note: In the case of object.insert, the key of insert (on the object) is a custom object which passes its 'selfness' as the instance of the object which it is a part of. i.e in the case of object.insert.first, insert.first takes an object (self) as its first argument to the function call. This argument takes 'object' as the implicit self as opposed to insert.

```
-- syntax options -> i.e. object.insert.first
-- note: this is implemented in the object base class using object:extend("insert"). It should later also work on subclasses without unexpected overrides. - WIP

local myObject = object{"bar"}
local val = "foo"

-- These would all have the same effect ...

---- ----- ----- ----- 
object.insert:first(val)
object:insertFirst(val)
object.insert:First(val)
object.insertfirst(val)
---- ----- ----- ----- 
object.insert.first(val) -- with (dotObjectRef) flag
---- ----- ----- ----- 
object:unshift(val) -- alias
---- ----- ----- ----- 

-- output:
-- (object[2]):{01:"foo", 02:"bar"}

```
------ ------ ------ ------

`object.insert` - extension / custom object

```lua
 object.insert.first(self,...) --> self
 -- alias: object.unshift
 object.insert.last(self,...) --> self
 -- alias: object.push
 object.insert.atIndex(self,...) --> self
```

```
object.insert.firstIndexiesFromTable
object.insert.lastIndexiesFromTable
object.insert.atIndexIndexiesFromTable
object.insert.keysFromTable
```

------ ------ ------ ------

`object.remove` - extension / custom object

```lua
 object.remove.indexies(self,...) --> vararg - removals
 object.remove.keys(self,...) --> vararg - removals
 object.remove.first(self,number) --> vararg - removals
  -- alias: object.unshift
 object.remove.last(self,number) --> vararg - removals
  -- alias: object.pop
```

```
object.remove.atIndex
object.remove.beforeIndex
object.remove.afterIndex
object.remove.firstIndexOf
object.remove.lastIndexOf
object.remove.indexiesOf
object.remove.range
object.remove.entry
object.remove.entries
```

------ ------ ------ ------

`object.first` / `object.last` - extensions / custom objects

```lua

 object.first(count) --> vararg - elements at first (count) indicies
 object.last(count) --> vararg - elements at last (count) indiciez

 object.first.indexOf(...) --> vararg - first indice of occurance of elements passed into method
 object.last.indexOf(...) --> vararg - last indice of occurance of elements passed into method

```

------ ------ ------ ------
utility functions / methods:

```
object.countElements | object.length
object.contains

object.indexiesOf
object.keysOf

object.keys
object.hasKeys

object.range

object.inverseIndexies
object.type
object.isTypeOf

object.copy
```

```
object.meta
object.super | object.prototype | object.proto
```

---------- ---------- ---------- ------

Logging / Pretty Print: 
object has a (.toString) method which can be used to handle converting lua data to strings and decorating them in the serial display.

---------- ---------- ---------- ------

`object.toString` - extension / custom object

```lua
 object.toString(value,options) --> string (see __tostring below)

 object.toString:config { --> nill - (sets behavior for toStringHandler) -> object:meta().__tostring

  offsets = true,
  length = true,
  depth = 1

  style = "block"
  spacer = "  "
  
 }
```

```lua
 object.concat(table,sep) --> string
```

```lua

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

```

```lua
 local tree = object{"leaves","bark",
  kind = "oak", ["1"] = "one", alpha = {"a","b","c"}}
    
 print(tree:toString{
 ---- ---- ---- ----
  style = "vertical",
  depth = 2,
  spacer = "..",
  ---- ---- ---- ----
  offsets = true,
  lengths = true
  ---- ---- ---- ----
 })
```

```
output:

(object[2]: 0x306f20140):{
....01:"leaves", 
....02:"bark", 
....["1"]:"one", 
....kind:"oak", 
....alpha:(table[3]: 0x306f20bc0):{
......01:"a", 
......02:"b", 
......03:"c"
....}
}
```
```lua
print(tree) -- uses defaults
```
```
(object[2]: 0x306f20140):{01:"leaves", 02:"bark", alpha:(table[3]: 0x306f20bc0), kind:"oak", ["1"]:"one"}
```

```lua

-- configure the default behavior of __tostring for object instance (tree)
-- note: this only changes defined properties and does not overwrite the entire config table
tree.toString:config {
 offsets = false,
 depth = 2
}

print(tree) -- uses new configs
```
```
(object[2]):{01:"leaves", 02:"bark", ["1"]:"one", kind:"oak", alpha:(table[3]):{01:"a", 02:"b", 03:"c"}}
```
------ ------ ------ ------

Chaining: Calls which return an object can be chained

```lua
local colors = object()
colors:unshift("red","green"):push("blue") 
print(colors) --> colors{"red","green","blue"}
```
```
(object[3]: 0x306c9f440):{01:"red", 02:"green", 03:"blue"}
```
------ ------ ------ ------
Note 4/10/25 - The scope stack methods are being updated. The code below isn't currently working with module imports in all cases.
------ ------ ------ ------

Object Methods: Scope Stack

```

object:inScopeOf() -- Iterator overload - Iterate once and set scope to object implicitly -> local scope becomes object 

for scope in object:inScopeOf do
end

pushScope() -- Add to array and set dynamic pointer
popScope() -- Remove from array and set dynamic pointer
(WIP) setScope(scope,bind/reset) - Update Dynamic Pointer

for all) -> returns: scope

```

------ ------ ------ ------

Usage Example: (object scope)

```lua

    local plant = object{"seed"}
    object.unshift(plant,"flower") -- plant{"flower","seed"}
    print("The plant:",plant)
    plant:shift()

    for scope in plant:inScopeOf() do
     plant:push("water")
     push("nutrients")
     print("The plant:",self) -- plant{"seed","water","nutrients"}
    end

    local tree = plant{"branch","leaves"}
    local bush = plant{leaves = "green"}
    
    bush:pushScope()
    print("The initial bush (out of scope)",bush)
    
    for scope in plant:inScopeOf() do
        
     pushScope(tree)

      print(self) -- tree{"branch","leaves"}
      print(self[1]) -- "branch"

      insert.first(self,"bark")
      print("The tree:",self) --> tree{"bark","branch","leaves"}

      pushScope(bush)

       print("The bush:",self) --> bush{["leaves"] = "green}

       print(leaves) -- "green"
       self.leaves = "purple"
       print(leaves) -- "purple"

      popScope()

      print("The tree:",self) -- tree{"branch","leaves","bark"}

      -- Note: These are all reference pointers to the same var.
      print(leaves,tree.leaves,self.leaves) -- "purple","purple","purple"

     popScope()
        
     print("The plant:",self) -- plant{"seed","water","nutrients"}
     print(plant == self) --> true

    end
    
    print("The bush (out of scope)",self) -- bush{["leaves"]="purple"}
    popScope()
    
    print("Self - should be nil!",self)

```

------ ------ ------ ------

Scope Object Methods - WIP

```
  scope:next() / scope:previous() - scope stack movement

  scope:release() - clear stack / return to main scope
  scope:bind(scope) - (alias) - clear scope stack and set to new scope - scope:bind(nil) - same as scope:release()
```

------ ------ ------ ------
