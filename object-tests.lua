-------------------------------------------
-- objectTests.lua - Tests for object.lua 
-------------------------------------------
local object = require(asset.object)
-------------------------------------------

-- run tests for the object.lua class
-- local runTests = require(asset.objectTests)
-- runTests("*") -- run test(s)

-------------------------------------------
----- ----- ----- ----- ----- -----
-- if true then return end -- 
----- ----- ----- ----- ----- -----
-------------------------------------------

-------------------------------------------
local _timestamp -- today: (hh:mm:ss)
-------------------------------------------

local objectTests = {
 extend = {}, api = {}, tostring = {}, 
 print = {}, class = {}, structs = {}
}

------------------------------------------->
-- methods to run tests ...
------------------------------------------->

local function runTests(categories) 
  
  ---------- ------ ---------- ------
  local concat = table.concat
  ---------- ------ ---------- ------
  
  local header = { concat {
   "======================== \n", "'objectTests.lua': "},
   "\n========================" }
  
  if not object then
    print(concat{header[1],
     "object.lua is missing ...",
     header[2]}) return
  end
  
  ---------- ------ ---------- ------
  local concat,tostring,keys = object.concat or table.concat, object.tostring or tostring, object.keys
  ---------- ------ ---------- ------
  
  if not categories then
    print(concat{header[1],"No category argument to 'runTests'. Possible category options: {", keys(objectTests),"}.",
     header[2]})
  end
  
  -- run all tests - runTests("*")
  if categories == "*" then
   categories = {keys(objectTests)}
     
  -- run selected tests - runTests(category)
  elseif type(categories) == "string" then categories = {categories} 
    
  end
  
  ---------- ------ ---------- ------
  local count = {errors = 0, tests = 0}
  local spacer = "---- ---- ---- ---- ----"
  ---------- ------ ---------- ------
  local testCount,step = 0,1
  ---------- ------ ---------- ------
  
  for i = 1, #categories do
   local category = categories[i]
   if objectTests[category] then
    testCount = testCount + #{keys(objectTests[category])}
    end end
  
  ---------- ------ ---------- ------
  
  local testsWillRun = testCount > 0
  
  if not testsWillRun then
    print(concat{header[1],
      "No tests to run ...", header[2] })
   return end
  
  print(concat{header[1], 
   "Running tests for object class ...",
    "\n -- tests to run: ", testCount,
   header[2] })
  
  ---------- ------ ---------- ------
  
  for i = 1, #categories do
   local category = categories[i]
   
   local testLookup = objectTests[category]
   for key,test in pairs(testLookup) do
      
    local testName = 
     concat{"('",category,"':[",key,'])'}
      
    print(concat{spacer.." ","\n:: start test (",step,"/",testCount,") :: ",testName,": ",_timestamp(),"\n",spacer})
    local status,message = pcall(test)
      
    if status == false then 
     print(concat{spacer.." ","\n:: end test :: ",testName,": ",_timestamp(),' -  test failed with error message: "',message,' - 1"\n',spacer})
     count.errors = count.errors + 1
    else 
      print(concat{spacer.." ","\n::: end test :: ",testName,": ", _timestamp(),' - test finished running. - 0\n',spacer})
    end  
      
    count.tests = count.tests + 1
    step = step + 1
      
   end 
    
  end
  
  print(concat{
   "======================== \n", 
   "|| end of tests ...",
   "\n--> errors: ",count.errors,
   " tests: ",count.tests,
   "\n========================" 
  })

end


------------------------------------------->
-- test inplementations: (4-15) note: currently the tests are self contained so values are not passed in or returned ... 
------------------------------------------->

objectTests.extend["4-14-25"] = function()
    
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

    print([[ expected output:

      (object[3]: 0x311f94a80):{01:"a", 02:"b", 03:"c"}
      The plant grew:	(object[6]: 0x311f94a80):{01:"a", 02:"b", 03:"c", 04:"a", 05:"b", 06:"c", grow:(function: 0x3048c9cb0)}
      Now there are leaves:	(object[8]: 0x311f94a80):{01:"leaves", 02:"a", 03:"b", 04:"c", 05:"a", 06:"b", 07:"c", 08:"leaves", growleaves:(function: 0x3048d1ad0), growLeaves:(function: 0x3048d1ad0), grow:(ext.prefix[0]: 0x311f7be80: { __tostring = "(ext.prefix _:grow|...|):{Leaves, leaves}" })}
      This is the clover:	(object[1]: 0x311f3bd40):{01:"sprout"}
      The plant grew:	(object[2]: 0x311f3bd40):{01:"sprout", 02:"sprout"}
      The plant grew:	(object[4]: 0x311f3bd40):{01:"sprout", 02:"sprout", 03:"sprout", 04:"sprout"}
      Now there are leaves:	(object[6]: 0x311f3bd40):{01:"leaves", 02:"sprout", 03:"sprout", 04:"sprout", 05:"sprout", 06:"leaves"}
      End test ext.prefix: plant: [	(object[8]: 0x311f94a80):{01:"leaves", 02:"a", 03:"b", 04:"c", 05:"a", 06:"b", 07:"c", 08:"leaves", growleaves:(function: 0x3048d1ad0), growLeaves:(function: 0x3048d1ad0), grow:(ext.prefix[0]: 0x311f7be80: { __tostring = "(ext.prefix _:grow|...|):{Leaves, leaves}" })}	], clover: [	(object[6]: 0x311f3bd40):{01:"leaves", 02:"sprout", 03:"sprout", 04:"sprout", 05:"sprout", 06:"leaves"}	].

    ]])
    
end

------ ------ ------ ------ ------

objectTests.tostring["4-10-25"] = function()
    
    local toString = object.toString
    
    local multiArray = object{"a","b","c",{"d","e","f",{"g","h","i"}},"j","k","l","m",{"n","o","p"},"q","r","s"}
    
    print(multiArray)
    
    print(" ------- ---------- ------- ")
    
    print(multiArray:toString{
        offsets = false,
        depth = 3
    })
    
end

------ ------ ------ ------ ------

-- (04/05/25) :first / :last / :range
objectTests.api["4-05-25:(1)"] = function()
    
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

------ ------ ------ ------ ------

objectTests.api["4-05-25:(2)"] = function()
    
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

------ ------ ------ ------ ------

objectTests.print["4-11-25 (printing)"] = function()
    
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
  
  print( [[expected output: 

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

  ]])

end

------ ------ ------ ------ ------

objectTests.print["4-11-25 (prettyPrint)"] = function()
  
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
  
  print( [[ expected output:
  
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
  
]])

end

------ ------ ------ ------ ------

objectTests.extend["8-01-25:(nested)"] =
function()
  
   ------- ------ ----- ------ ------- >>
   -- Object class declarations ...
  
   local baseObject = object{"a",44,"b",a=4,22,"c","d",1,2,3,4,5,"e",3.14159,"ff","tree","leaves"}
  
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
  -- Tests below this point ...
  
  print("(*) ---- ----- ----")
  
  print("This is the baseObject:",
    baseObject:tostring("v"))
  
  print("numbers:",
    baseObject.list:numbers())
  
  print("strings:",
    baseObject.list:strings())
  
  print("odd numbers:",
    baseObject.list:numbersOdd())
  
  print("even numbers:",
    baseObject.list.numbers:even())
  
  print("---- ----- ---- (*)")
  
  ------ ---- ------ ---- ------ ----

  local wordsAndNumbers = baseObject({1,2,3,4,5,"string","table","print","tostring",10,9,16,25,36,49,64,81,121,144,169,"tree","leaves"})
  
  print("This is wordsAndNumbers:", wordsAndNumbers)
  
  print("List Indexies: (wordsAndNumbers):",
  wordsAndNumbers:list())
  
  print("strings:",
  wordsAndNumbers.list:strings())
  
  print("odd numbers:",
  wordsAndNumbers.list.numbers:odd())
  
end

-------------------------------------------
-- private methods ...
-------------------------------------------
if not object then return runTests end
-------------------------------------------
local concat,tostring,keys = object.concat or table.concat, object.tostring or tostring, object.keys
-------------------------------------------

-- gets a timestamp for logs
_timestamp = function()
  
  local t = os.date("*t")
  -- print("(os.date)",object.tostring(t))
  
  local formatNumber = function(val)
   local val = tostring(val)
   if string.len(val) == 1 then val = "0"..val
   end return val end
  local ft = formatNumber
    
  return concat {
   "(",ft(t.hour),":",ft(t.min),":",  ft(t.sec),")"
  } 
    
end --> (string) timestamp

-------------------------------------------
------ ------ ------ ------ ------
return runTests ------> ----> ------>
------ ------ ------ ------ ------
-------------------------------------------