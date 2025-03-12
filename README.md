object.lua
==========

------ ------ ------ ------
Object Oriented Lua Programming
------ ------ ------ ------

------------
API Methods
------------

Constructor: object() / object.new()
i.e. local value = object() / object.new()

------ ------ ------ ------

-- (_.insert, _.remove) - Prefix Block Extensions

-- These prefix extensions search for the insert or remove prefix when referenced to create custom method call blocks. Using the declaration syntax, subclasses can append custom local methods to these extensions. The usage structure is below:
-- Declaration: object.|insert/remove|Extension IE: object.insertValue
-- Calling Syntax Examples: 

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

---------------

-- Add data to object

object.insert.first / object.unshift
object.insert.last / object.push
object.insert.atIndex
object.insert.firstIndexiesFromTable
object.insert.lastIndexiesFromTable
object.insert.atIndexIndexiesFromTable
object.insert.keysFromTable

------ ------

-- Remove data from object

object.remove.index
object.remove.indexies
object.remove.first / object.shift
object.remove.last / object.pop
object.remove.atIndex
object.remove.beforeIndex
object.remove.afterIndex
object.remove.firstIndexOf
object.remove.lastIndexOf
object.remove.indexiesOf
object.remove.range
object.remove.entry
object.remove.entries

------ ------

object.countElements
object.contains
object.indexiesOf
object.keysOf
object.keys

object.first
object.last
object.firstIndexOf
object.lastIndexOf

object.inverseIndexies
object.concat
object.type
object.isTypeOf

object.meta
object.super
object.copy

------ ------ ------ ------

-- Chaining - Calls which return an object can be chained

local colors = object()
colors:unshift("red","green"):push("blue") -> colors{"red","green","blue"}

------ ------ ------ ------

-- Object Methods - Scope Stack

-- object:inScopeOf() -- Iterator overload - Iterate once and set scope to object implicitly -> local scope becomes object 

-- for scope in object:inScopeOf do
-- end

-- setScope(scope,bind/reset) - Update Dynamic Pointer
-- pushScope() -- Add to array and set dynamic pointer
-- popScope() -- Remove from array and set dynamic pointer

-- (for all) -> returns: scope

------ ------ ------ ------

-- object:scope example

```lua

    local plant = object{"seed"}
    object.unshift(plant,"flower")
    print("The plant:",plant)
    
    local tree = object{"branch","leaves"}
    local bush = plant{leaves = "green"}
    
    bush:pushScope()
    print("The initial bush (out of scope)",bush)
    
    for scope in plant:inScopeOf() do
        
     pushScope(tree)
     print("The tree:",self)    
     pushScope(bush)
     print("The bush:",self)    
     popScope()
     print("The tree:",self)  
     popScope()
        
     print("The plant:",self,plant == self)
        
    end
    
    print("The bush (out of scope)",self)
    popScope()
    
    print("Selfness:",self)

```

------ ------ ------ ------

-- Scope Object Methods

```
  scope:next() / scope:previous() - scope stack movement

  scope:release() - clear stack / return to main scope
  scope:bind(scope) - (alias) - clear scope stack and set to new scope - scope:bind(nil) - same as scope:release()
```

------ ------ ------ ------
