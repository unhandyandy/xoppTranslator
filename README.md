# xoppTranslator
Plugin for xournalpp to provide translation of texts

This arose out my need for translation support.  I'm not a real programmer.

There are two modes:

Copy text into the clipboard, hit Shift-Alt t, and a browser opens with google's response to
"translate: " + <clipboard text>.

Hit Shift-Alt g, select a region, and tesseract is used to convert image to text, 
which is then passed to the browser as above.

You can set your preferred browser and screenshotter by editing the prefs.lua file

This requires a clipboard managet, like xfce4-clipman or clipboard-manager.  This is also set in the prefs.lua file.

This is alpha level.  It was written with the help of Gemini.  
I tried to avoid any unnecessary dependencies.

Please try it and let me know what I did wrong.

Specific language support is on my todo list.
