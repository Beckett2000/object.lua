-------------------------------------------
-- encodings.lua - (BD 2025) - Playing around with trying to build some cipher encoding / decryption functions ...
-------------------------------------------

-------------------------------------------
-- if true then return end -- --- ---- -- 
-------------------------------------------

------------ ------------ ------------ 
-- local decs. for speed improvements ...
------------ ------------ ------------ 
local cat,insert,sort =
table.concat,table.insert, table.sort
------------ ------------ ------------ 

------- -------- ------- -------- ------
-- Vigenère Cipher -- --- ------
------- -------- ------- -------- ------

-- I thought it was kind of interesting to think about how some text data can be encoded through the use of ciphers so took a pass at creating a rudimentary implementation of Vigenère encoding based on this article:

-- reference: https://en.wikipedia.org/wiki/Vigenère_cipher

------- -------- ------- -------- ------

------------ ------------ ------------ 
-- private (helper) method declarations
------------ ------------ ------------ 
local _vigenere, _getCharset, _tokenizeStr 
------------ ------------ ------------ 

local defaults = {
  chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
}

--- --- --- --- --- --- --- --- --- (*)

-- vigenere --> holds the Vigenère encoding methods which are exposed for external calls ...

 -- vigenere.encode(txt,key,opt) 
 -- vigenere.decode(txt,key,opt)

 --[[
 
  -- txt (string) -- text to be encoded
  -- key (string) -- key to encode with

  -- options: (optional - table): {
  --- chars: (string)
  --- keys: (string - regexp) -- allowed keys beyond charaset -- uses Lua lightweight regex i.e '*' or '%s'
  --- decode: (boolean
  
  }
  
  -- TODO - opt.chars - could be an expresion or ordered list as either a table or string ...
  
--]] 

--- (*) --- --- --- --- --- --- --- ---

local vigenere  = {
 
  --> ------ ------ ------ ------ 
  -- vigenere.encode(txt,key,options) - converts to an encoded string using a key / cipher and a given charset ...
  ------ ------ ------ --> 
  
  encode = function(txt,key,opt)
    opt = opt or {}; opt.decode = false
    return _vigenere(txt,key,opt)
  end,
  
  -- <-- ------ ------ ------ ------ 
  -- vigenere.decode(txt,key,options) - converts an encoded string to plain text using key / cyper and a given charset ...
  ------ ------ ------ <--
  
  decode = function(txt,key,opt)
    opt = opt or {}; opt.decode = true
    return _vigenere(txt,key,opt)
  end
  
  ------ ------ ------ ------
  
}

-------- ------ -------- ------- --------
-- helper functions below this point ...
-------- ------ -------- ------- --------

-- (helper) - this method is used when the 'vigenere.encode' or 'vigenere.decode' methods are called on a given strin to convert to / from plain text ...

_vigenere = function(txt,key,opt)
  
  if not txt then return end
  if not key then return txt end
  
  local charset = opt and opt.chars and opt.chars or defaults.chars
  local decode = opt and opt.decode
  
  local ignoreInvalid = 0
  if opt and opt.keys and opt.keys then
    if opt.keys == "*" then ignoreInvalid = 1 
    elseif type(opt.keys) == "string" then
      ignoreInvalid = -1
    end end
  
  local cat,insert =
  table.concat,table.insert
  
  ---- ----- ----- -----
  
  local set,char = _getCharset(charset)
  local idx,chars,skipped,delta,_idx = not decode and 1 or set[txt:sub(1,1)], #charset,0,0,0
  
  local out = {}
  
  for i = 1,#txt do
    
    char = txt:sub(i,i)
    if set[char] then 
      
      local keyChar = key:sub(i - skipped,i - skipped)
      
      -- skip invalid characters in key / password
      
      if ignoreInvalid == 1 or 
      ignoreInvalid == -1 then
        
        while not set[keyChar] do
          if ignoreInvalid == -1 and not keyChar:match(opt.keys) then break end
          skipped = skipped + 1
          keyChar = key:sub(i - skipped, i - skipped)      
        end end
      
      ---- ----- -----
      
      delta = set[keyChar] - 1
      delta = decode and delta * -1 or delta
      
      idx = (idx + delta) % chars
      idx = idx > 0 and idx % chars or
      chars + idx
      
      _idx = (set[char] + delta) % chars
      _idx = _idx > 0 and _idx % chars or
      chars + _idx
      
      char = charset:sub(_idx,_idx)    
      
      ---- ----- -----
      
    else skipped = skipped + 1  end
    
    insert(out,char) 
    
  end;
  
return cat(out) end

--- --- --- --- --- --- --- --- --- (*)

-- (helper) -- gets charset table for vigenere. note: character repetitions are parsed out.

_getCharset = function(charset)
  
  local out,offset,char = {},0
  
  for idx = 1,#charset do
    idx = idx - offset
    char = charset:sub(idx,idx)
    if not out[char] then 
      out[char] = idx
    else offset = offset + 1 end
  end table.sort(out); 
  
  return out --> returns: table {char:index,...}
end

--- --- --- --- --- --- --- --- --- (*)

-- (helper) breakkes string into a sorted list of characters or expession sets for the sake of character comparison

_tokenizeStr = function(str)
  
  
end

-- (*) --- --- --- --- --- --- --- ---  

-------- ------ -------- ------- --------
--[[ -- testing first pass en(code)ings ...
-------- ------ -------- ------- --------

-- example input/outpt taken from wikipedia article (see above ...)

local function testVigenereCipher()

  local txt = "attacking tonight"
  local key = "oculorhinolaryngology"
  local charset = "abcdefghijklmnopqrstuvwxyz"

  print("Testing Vigenère Cipher!")

  local encoded = vigenere.encode(txt,key, {
    chars = charset })
  local decoded = vigenere.decode(encoded,
    key, { chars = charset })
  
  print("output A: ",
   encoded,decoded )
  
  print("output B: ",
   vigenere.encode(txt,key))
  
  print("expected output: ","ovnlqbpvt hznzeuz")

  txt = "the quick brown fox ran down the road"
  
  local encode = vigenere.encode
  print(encode(txt,txt,{keys = "%s"}))

end 

-- testVigenereCipher()

--]]

----- ----------- ----------- -----------  
return vigenere --> --- ---- -----
----- ----------- ----------- -----------  

-------- ------ -------- ------- --------
-- {{ File End - encodings.lua }}
-------- ------ -------- ------- --------