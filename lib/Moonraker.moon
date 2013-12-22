-- moonraker
-- simple build system. so simple you probably shouldn't use it
-- look at example .moonraker
-- to do anything sufficiently useful you'll need luafilesystem
moonscript = require "moonscript"

tasks = {} -- each task
descs = {} -- descriptions of each task
done  = {} -- tasks already executed
multi = {} -- tasks that can be executed multiple times
requires = {} -- each task's required tasks

default   = nil -- default task
nextdesc  = nil -- description to assign to next defined task
nextmulti = nil -- whether the next defined task is able to execute multiple times
tmpname = os.tmpname! -- temporary file for output

-- functions available to moonraker
environment =
  task: (taskt, block) ->
    name = nil
    for k, v in pairs taskt
      name = k -- task name is the only element in the table
      requires[k] = v unless type(v) == "function"
      tasks[k] = v if type(v) == "function"
      descs[k] = nextdesc -- set our description

    tasks[name] = type(block) == "table" and block.do or block if block
    multi[name] = nextmulti if nextmulti
    nextdesc, nextmulti = nil, nil
  desc: (name) ->
    nextdesc = name
  multiple: ->
    nextmulti = true
  default: (name) ->
    print("Already set default task: #{default}") if default
    default = name

-- transforms unknown access to os execution
setmetatable environment, __index: (t, k) ->
  return _G[k] if _G[k]
  (x) =>
    returncode = os.execute("#{k} #{x or @} > #{tmpname}")
    result = [l for l in io.lines(tmpname)]
    table.concat(result, "\n"), returncode

doTask = (name) ->
  return if not multi[name] and done[name] -- task already executed
  unless tasks[name]
    return print("No task: " .. name)
  task = tasks[name]
  if requires[name]
    if type(requires[name]) == "table"
      for item in *requires[name]
        doTask(item)
    else
      doTask(requires[name])
  safe, res = pcall(task, environment)
  if safe
    print res if res
    done[name] = true
  else
    print "Error in task: #{name}\n #{res}"

help = "\tUsage: moonraker file (default: .moonraker) task (optional)"

doFile = (file) ->
  start = os.clock()
  filepath = file or arg[2] and arg[1] or ".moonraker"
  if filepath\match("%-h.*") --anything matching -h* must be a request for help
    print help
    return
  mrfile = table.concat([l for l in io.lines(filepath)], "\n")
  --try to load moonraker
  mrfunc = assert(moonscript.loadstring(mrfile))
  setfenv(mrfunc, environment)
  safe, errors = pcall(mrfunc)
  task = arg[1] and arg[2] or arg[1] or default
  if safe
    doTask(task)
  --always remove the temporary file
  os.remove(tmpname)
  -- print errors in moonraker file
  if errors
    print errors
  elapsed = os.clock() - start
  print(("Completed %s in %0.2fs.")\format(task, elapsed))

--public
doFile
