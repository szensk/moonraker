Description
===========
Moonraker is a simple build system I use to define common tasks (such as packaging a .love file).

```moonscript
default "echo"

desc "Find moon's path"
task test: =>
  "MOON_PATH: " .. where "moon" -- results returned from a task are printed to screen

desc "List some stuff"
task dir: "test", =>
  cd = echo "%CD%" -- calls to any unknown global will call to your operating system and return the value as a string
  "PWD: " .. cd

desc "Echo some useless information"
task echo: {"test", "dir"}, =>
  echo "doing echo"
```

Usage
==================

Simply call moonraker. Without any arguments it will call the default task from the .moonraker file. The first argument is an optional file, the second is the task to run.
