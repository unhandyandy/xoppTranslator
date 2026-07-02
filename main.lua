
local browser="min"
-- local browser="google-chrome"
-- local browser="firefox"

local screenshotter="maim -s "
-- local screenshotcmd="xfce4-screenshooter -r -s "

-- local clipmanager = "xfce4-clipman"
local clipmanager = "clipboard-indicator"

local tmpImage = "/tmp/xournalpp_ocr_temp.png"
local tmpText = "/tmp/xournalpp_ocr_temp.txt"

-- Register both tools into Xournal++'s interface loop
function initUi()
   -- Option 1: Image Crop (Screenshots handwritten notes / diagrams)
   app.registerUi({
	 ["menu"] = "Translate Image Crop (Google Lens)",
	 ["callback"] = "OCR_Google",
	 ["accelerator"] = "<Shift><Alt>g"
   })

   -- Option 2: Text Selection (Translates copied PDF text strings)
   app.registerUi({
	 ["menu"] = "Translate Copied Text (Google Lens)",
	 ["callback"] = "translateClipboardText",
	 ["accelerator"] = "<Shift><Alt>t"
   })
end

function cleanAndEncode(str)
   if not str or str == "" then return nil end
   
   -- 1. Replace newlines/tabs with spaces and trim trailing whitespace
   str = string.gsub(str, "[\r\n\t]", " ")
   str = string.gsub(str, "^%s*(.-)%s*$", "%1")
   
   -- 2. Percent-encode every unsafe character via hexadecimal conversion
   str = string.gsub(str, "([^%w %-%_%.%~])", function(c)
			return string.format("%%%02X", string.byte(c))
   end)
   
   -- 3. Convert spaces to standard URL plus signs
   return string.gsub(str, " ", "+")
end

-- Option 1
function OCR_Google()
   -- Take regional screenshot and execute OCR via Tesseract
   local grabcmd = screenshotcmd .. tmpImage
   local ocrcmd = "tesseract " .. tmpImage .. " " .. string.sub(tmpText, 1, -5) .." > /dev/null 2>&1"
   -- print("\n--- DEBUG grab  ---\n" .. grabcmd .. "\n----------------------\n")
   os.execute(grabcmd)
   -- os.execute("feh "..tmpImage)
   -- print(os.execute("ls /tmp/xournalpp*"))
   os.execute(ocrcmd)
   -- Read the raw text file produced by Tesseract
   local file = io.open(tmpText, "r")
   if file then
      local text = file:read("*a")
      -- print("\n--- DEBUG TEXT  ---\n" .. text .. "\n----------------------\n")
      file:close()
      
      local encoded = cleanAndEncode(text)
      if encoded then
	 url = " \"https://google.com/search?q=translate:+"..encoded.."\" & "
	 print("\n--- DEBUG URL  ---\n" .. url .. "\n----------------------\n")
	 os.execute(browser..url)
      end
   end
   os.execute("rm "..tmpImage.." "..tmpText)
end


-- --- OPTION 2: TEXT SELECTION PIPELINE ---
-- Load the lightweight pure-Lua library from your folder
local getClipboardText
if clipmanager=="clipboard-indicator" then
   local json = require("json")

   function getClipboardText()
      local path = os.getenv("HOME") .. "/.cache/clipboard-indicator@tudmotu.com/registry.txt"
      local file,err = io.open(path, "r")
      
      if file then
	 local raw_json_string = file:read("*a")
	 file:close()
	 
	 -- Use pcall to parse the string safely without risking app crashes
	 local success, parsed_array = pcall(json.decode, raw_json_string)
	 
	 if success and parsed_array and #parsed_array > 0 then
	    -- Grab the absolute last index from the clipboard tracking array
	    local latest_item = parsed_array[#parsed_array]
	    
	    -- Extract the content text string
	    return latest_item["contents"]
	 end
      end
      print(err)
      return nil
   end
elseif clipmanager=="xfce4-clipman" then
   function getClipboardText()
      local clipCache = os.getenv("HOME") .. "/.cache/xfce4/clipman/textsrc"

      local file = io.open(clipCache, "r")
      if file then
	 local text = file:read("*a")
	 file:close()
	 text = string.gsub(text, "[%s;]*$", "")
	 text = string.match(text, ".*[^\\];%s*(.-)%s*$") or text
	 print("\n--- DEBUG text  ---\n" .. text .. "\n----------------------\n")
	 return text
      end
   end
end

function translateClipboardText()
   local text = getClipboardText()
   print("\n--- DEBUG text  ---\n" .. text .. "\n----------------------\n")
   
   -- 2. Clean up newlines and URL-encode natively
   local encoded = cleanAndEncode(text)
   print("\n--- DEBUG encoded  ---\n" .. encoded .. "\n----------------------\n")
   
   -- 3. Open directly in your default system browser if text exists
   if encoded and encoded ~= "" then
      url = " \"https://google.com/search?q=translate:+"..encoded.."\" & "
      print("\n--- DEBUG URL  ---\n" .. url .. "\n----------------------\n")
      os.execute(browser..url)
      -- os.execute("xdg-open 'https://google.com" .. encoded .. "' &")
   else
      print("Warning: Clipboard is empty or contains non-text data.")
   end
end
