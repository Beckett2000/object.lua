-------------------------------------------
-- encodings.lua - (BD 2025) - Playing around with trying to build some cipher encoding / decryption functions ...
-------------------------------------------

------- -------- ------- -------- ------
-- Vigenère Cipher -- --- ------
------- -------- ------- -------- ------

-- I thought it was kind of interesting to think about how some text data can be encoded through the use of ciphers so took a pass at creating a rudimentary implementation of Vigenère encoding based on this article:

-- reference: https://en.wikipedia.org/wiki/Vigenère_cipher

------- -------- ------- -------- ------

--- --- --- --- --- --- --- --- --- (*)

-- (helper) -- gets charset table for vigenere. note: character repetitions are parsed out.

local function _getCharset(charset)
  
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

local vigenere = {
  
  ------ ------ ------ ------
  -- vigenere.encode(txt,key,options)
  -- change text to encoded text with string key / cipher ...
  
  --[[
  
  -- txt (string) -- text to be encoded
  -- key (string) -- key to encode with

  -- options: (optional - table): {
  --- chars: (string)
  --- keys: (string - regexp) -- allowed keys beyond charaset -- uses Lua lightweight regex i.e '*' or '%s'
  
  }
  
  --]]
  
  encode = function(txt,key,opt)

   if not txt then return end
   if not key then return txt end
  
   local charset = opt and opt.chars or "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    
   local ignoreInvalid = 0
   if opt and opt.keys then
    if opt.keys == "*" then ignoreInvalid = 1 
    elseif type(opt.keys) == "string" then
     ignoreInvalid = -1
   end end
      
   local cat,insert =
    table.concat,table.insert
  
   local idx,skipped,delta,_idx = 1,0,0,0
   local out = {}
  
   local set,char = _getCharset(charset)
  
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

     delta = set[keyChar] - 1
     idx = (idx + delta) % #charset
     _idx = (set[char] + delta) % #charset
     if _idx == 0 then _idx = #charset end
      char = charset:sub(_idx,_idx)    
     else skipped = skipped + 1  end
    
     insert(out,char) 
    end;
        
  return cat(out) end, 
  
  ------- ------ ------ ------ ------
  
  decode = function(txt,key)
    
  end
  
}

-- (*) --- --- --- --- --- --- --- ---  

--[[ -- testing first pass code ...

-- example input/outpt taken from wikipedia article (see above ...)

local function testVigenereCipher()

  local txt = "attacking tonight"
  local key = "oculorhinolaryngology"
  local charset = "abcdefghijklmnopqrstuvwxyz"

  print("Testing Vigenère Cipher!")

  print("output A: ",
   vigenere.encode(txt,key, {
    chars = charset }))
  
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