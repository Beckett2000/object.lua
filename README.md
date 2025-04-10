object.lua
==========

------ ------ ------ ------
Object Oriented Lua Programming
------ ------ ------ ------

```
Constructor: object() / object.new()
```

```lua
local value = object() / object.new()
print("Hello object!")
```

------ ------ ------ ------

Insert / Remove (_.insert, _.remove) - Custom Object Syntax - (prefix)

These prefix extensions search for the insert or remove prefix when referenced to create custom method call blocks. Using the declaration syntax, subclasses can append custom local methods to these extensions. The usage structure is below:
Declaration: object.|insert/remove|Extension IE: object.insertValue
Calling Syntax Examples: 

```
  object:insertValue() 

  object.insert:value() / object.insert:Value()
  object.insert.value() / object.insert.Value() 

  object:insert():Value() / object:insert():value()
  object:insert().Value() / object:insert().value()
```

------ ------ ------ ------

Usage example:

```lua
local tree = object{leaves = "green")
tree:insertFirst("branches") -> tree{"branches",leaves = "green"}
tree.insert.first("bark") -> tree{"bark","branches",leaves = "green"}
tree.insert:Last("dew") -> tree{"bark","branches",leaves = "green","dew"}
```

------ ------ ------ ------

Note: In the case of object.insert, the key of insert (on the object) is a custom object which passes its 'selfness' as the instance of the object which it is a part of. i.e in the case of object.insert.first, insert.first takes an object (self) as its first argument to the function call. This argument takes 'object' as the implicit self as opposed to insert.

```
-- syntax options -> i.e. object.insert.first
-- note: this uses object:extend("insert") - WIP

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

(_.insert) extension / custom object

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

(_.remove) extension / custom object

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

(_.first / _.last) extensions / custom objects

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

```lua
 object.toString(value,options) --> string (see __tostring below)
 object.concat(table,sep) --> string
```

---------- ---------- ---------- ------

Logging / Pretty Print: object has a (.toString) method which can be used to handle converting lua data to strings and decorating them in the serial display.

---------- ---------- ---------- ------

__toString Settings / Options

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
  kind = "oak", ["1"]="one", alpha = {"a","b","c"}}
    
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
