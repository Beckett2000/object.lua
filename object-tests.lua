-- Temp. - Tests for object.lua 

----- ----- ----- ----- ----- -----
if true then return end
----- ----- ----- ----- ----- -----

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
    
end 
