package = "Moonraker"
version = "1.0-1"
source = {
   url = "git://github.com/szensk/moonraker",
   tag = "v1.0"
}
description = {
   summary = "A simple build system for MoonScript.",
   detailed = [[
      Inspired by rake, Moonraker is a simple build system for MoonScript. 
   ]],
   homepage = "http://github.com/szensk/moonraker",
   license = "MIT/X11" 
}
dependencies = {
   "lua >= 5.1",
   "moonscript >= 0.2.4"
}
build = {
   type = "builtin",
   modules = {
      moonraker = "src/init.lua"
   },
   install = {
      bin = {
         ["moonraker"] = "moonraker",
         ["moonraker.bat"] = "moonraker.bat"
      }
   }
}
