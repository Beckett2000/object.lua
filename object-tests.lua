-- Tests for object.lua 

----- ----- ----- ----- ----- -----
if true then return end
----- ----- ----- ----- ----- -----

testExtend = function()
    
    local plant = object{"a","b","c"}

    print(plant)
    
    plant.grow = function(self)
     self:insertLast(self:indexies())
     print("The plant grew:",self)
     return self -- chaining
    end
    
    plant:grow()
    
    plant:extend("grow")
    
    plant.grow.leaves = function(self)
     self:unshift("leaves"):push("leaves")
     print("Now there are leaves:",self)
    end
    
    plant.grow:Leaves()
    
    local clover = plant{"sprout"}
    print("This is the clover:",clover)
    
    clover:grow():grow()
    
    clover.grow:leaves()
    
    print("End test ext.prefix: plant: [",plant,"], clover: [",clover,"].")

    --[[ expected output:

      (object[3]: 0x311f94a80):{01:"a", 02:"b", 03:"c"}
      The plant grew:	(object[6]: 0x311f94a80):{01:"a", 02:"b", 03:"c", 04:"a", 05:"b", 06:"c", grow:(function: 0x3048c9cb0)}
      Now there are leaves:	(object[8]: 0x311f94a80):{01:"leaves", 02:"a", 03:"b", 04:"c", 05:"a", 06:"b", 07:"c", 08:"leaves", growleaves:(function: 0x3048d1ad0), growLeaves:(function: 0x3048d1ad0), grow:(ext.prefix[0]: 0x311f7be80: { __tostring = "(ext.prefix _:grow|...|):{Leaves, leaves}" })}
      This is the clover:	(object[1]: 0x311f3bd40):{01:"sprout"}
      The plant grew:	(object[2]: 0x311f3bd40):{01:"sprout", 02:"sprout"}
      The plant grew:	(object[4]: 0x311f3bd40):{01:"sprout", 02:"sprout", 03:"sprout", 04:"sprout"}
      Now there are leaves:	(object[6]: 0x311f3bd40):{01:"leaves", 02:"sprout", 03:"sprout", 04:"sprout", 05:"sprout", 06:"leaves"}
      End test ext.prefix: plant: [	(object[8]: 0x311f94a80):{01:"leaves", 02:"a", 03:"b", 04:"c", 05:"a", 06:"b", 07:"c", 08:"leaves", growleaves:(function: 0x3048d1ad0), growLeaves:(function: 0x3048d1ad0), grow:(ext.prefix[0]: 0x311f7be80: { __tostring = "(ext.prefix _:grow|...|):{Leaves, leaves}" })}	], clover: [	(object[6]: 0x311f3bd40):{01:"leaves", 02:"sprout", 03:"sprout", 04:"sprout", 05:"sprout", 06:"leaves"}	].

    --]]
    
end



testPrinting = function()
    
  local myTable = {"a","b"}
  setmetatable(myTable,{__tostring =
   function() return "a b c d e f" end })
    
  local tree = object{"leaves","bark",
  kind = "oak", [function() end] = "foo",["1"]="one",[{"a","b","c"}]= "alpha",
  ["customTable"] = myTable, [myTable] = "custom"}
    
  print(object.toString(tree,{
    style = "vertical",
    spacer = " ", 
    offsets = true,
    lengths = true,
    depth = 1
  }))

--[[

output: 

(object[2]: 0x307a7a1c0):{
  01:"leaves", 
  02:"bark", 
  [(table[3]: 0x307a7a6c0)]:"alpha", 
  ["1"]:"one", 
  kind:"oak", 
  [(table[2]: 0x307a78b00: { __tostring = "a b c d e f" })]:"custom", 
  [(function: 0x30a46b0a0)]:"foo", 
  customTable:(table[2]: 0x307a78b00: { __tostring = "a b c d e f" })
}

]]

end



testPrettyPrint = function()

   ------ ------ ------ ------>>

   local tree = object{"leaves","bark",
     kind = "oak",["1"]="one",alpha = {"a","b","c"}}
    
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

    ------ ------ ------ ------>>

    --[[ output:

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

    ]]

end

testToString = function()

   local tree = object{"leaves","bark",
    kind = "oak", [function() end] = "foo",["1"]="one",[{"a","b","c"}]= "alpha"}
    
   print(tree) 
    
  -- (object[2]: 0x311d87500):{01:"leaves", 02:"bark", [(function: 0x15584d880)]:"foo", kind:"oak", [(table[3]: 0x311d85a00)]:"alpha", ["1"]:"one"}
    
  local tree = object{"leaves","bark",
   kind = "oak", ["1Value"] = "one", ["two"]=20}
  
  print(tree) 

  -- (object[2]: 0x311ca5980):{01:"leaves", 02:"bark", kind:"oak", two:20, ["1Value"]:"one"}
    
end


testToString = function()
    
    local tree = object{"leaves"}
    
    local multiArray = object{"a","b","c",{"d","e","f",{"g","h","i"}},"j","k","l","m",{"n","o","p"},"q","r","s"}
    
    print(tree)
    
    multiArray.toString:config{
      offsets = false,
      spacer = " ",
      lengths = true,
      depth = 2
    }

    print(multiArray)
    
end


testObjectToString = function()
    
    local toString = object.toString
    
    local multiArray = object{"a","b","c",{"d","e","f",{"g","h","i"}},"j","k","l","m",{"n","o","p"},"q","r","s"}
    
    print(multiArray)
    
    print(" ------- ---------- ------- ")
    
    print(multiArray:toString{
        offsets = false,
        depth = 3
    })
    
end


-- :first / :last / :range
testObject = function()
    
    local tree = object()
    
    for i = 1,100 do 
        tree:insert(i,i*10) 
    end
    
    print(tree:range(50,20))
    print(tree:first(5))
    print(tree:last(8))
    print(tree.last:indexOf(490))

    tree.insert:atIndex(50,"nil")
    print(tree.last:indexOf(490,nil,20,"nil",100,5,80))
    
end 

testObject = function()
    
    local test = object{"a","b","c","d","b","e","a","f"}
    
    print(test)
    
    print(test:first())
    print(test.first:indexOf("b","c","a"))
    print(test:lastIndexOf("b","c","a"))
    
    test.insert:atIndex(4,"abc")
    print(test)
    
    test.remove:indexiesOf("a")
    print(test)
    
end

