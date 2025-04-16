-------------------------------------------
-- object.lua - template / boilerplate
-------------------------------------------
-- ---- ------ -- ---- ------ -- ----
if true then return end -- --- ---- --
-- ---- ------ -- ---- ------ -- ----
-------------------------------------------

local object = require(asset.object)
local runTests = require(asset.objectTests)

-------------------------------------------
-- inline test declarations here ...
-------------------------------------------
local testObject
-------------------------------------------

-- setup - called at start

function setup()
    
    print("Hello object!")
  
    testObject() 

    -- runTests("*")
        
end

-------------------------------------------
-- inline test implementatuons ...
-------------------------------------------

testObject = function()
  
  local obj = object{"a","b","c"}
  print(obj) -- out: (object[3]):{01:"a", 02:"b", 03:"c"}
  
end

-------------------------------------------

