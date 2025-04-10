-- Tests for object.lua 

----- ----- ----- ----- ----- -----
if true then return end
----- ----- ----- ----- ----- -----

testToString = function()

   local tree = object{"leaves","bark",
    kind = "oak", [function() end] = "foo",["1"]="one",[{"a","b","c"}]= "alpha"}
    
   print(tree) 
    
  -- (object[2]: 0x311d87500):{01:"leaves", 02:"bark", [(function: 0x15584d880)]:"foo", kind:"oak", [(table[3]: 0x311d85a00)]:"alpha", ["1"]:"one"}
    
  local tree = object{"leaves","bark",
   kind = "oak", ["1Value"] = "one", ["two"]=20}
    
  -- (object[2]: 0x311ca5980):{01:"leaves", 02:"bark", kind:"oak", two:20, ["1Value"]:"one"}
    
  print(tree) 

end

testToString = function()
    
    local tree = object{"leaves"}
    
    local multiArray = object{"a","b","c",{"d","e","f",{"g","h","i"}},"j","k","l","m",{"n","o","p"},"q","r","s"}
    
    print(tree)
    
    multiArray.toString:config{
      offsets = false,
      indents = " ",
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

