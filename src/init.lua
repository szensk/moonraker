local moonscript = require("moonscript")
local tasks = { }
local descs = { }
local done = { }
local multi = { }
local requires = { }
local default = nil
local nextdesc = nil
local nextmulti = nil
local separator = package.config:sub(0, 1)
local tmpname = os.tmpname()
local environment = {
  task = function(taskt, block)
    local name = nil
    for k, v in pairs(taskt) do
      name = k
      if not (type(v) == "function") then
        requires[k] = v
      end
      if type(v) == "function" then
        tasks[k] = v
      end
      descs[k] = nextdesc
    end
    if block then
      tasks[name] = type(block) == "table" and block["do"] or block
    end
    if nextmulti then
      multi[name] = nextmulti
    end
    nextdesc, nextmulti = nil, nil
  end,
  desc = function(name)
    nextdesc = name
  end,
  multiple = function()
    nextmulti = true
  end,
  default = function(name)
    if default then
      print("Already set default task: " .. tostring(default))
    end
    default = name
  end,
  windows = function()
    return package.config:sub(1, 1) == "\\"
  end,
  exec = os.execute,
  separator = separator
}
setmetatable(environment, {
  __index = function(t, k)
    if _G[k] then
      return _G[k]
    end
    return function(self, x)
      local returncode = os.execute(tostring(k) .. " " .. tostring(x or self) .. " > " .. tostring(tmpname))
      local result
      do
        local _accum_0 = { }
        local _len_0 = 1
        for l in io.lines(tmpname) do
          _accum_0[_len_0] = l
          _len_0 = _len_0 + 1
        end
        result = _accum_0
      end
      return table.concat(result, "\n"), returncode
    end
  end
})
local doTask
doTask = function(name)
  if not multi[name] and done[name] then
    return 
  end
  if not (tasks[name]) then
    return print("No task: " .. name)
  end
  local task = tasks[name]
  if requires[name] then
    if type(requires[name]) == "table" then
      local _list_0 = requires[name]
      for _index_0 = 1, #_list_0 do
        local item = _list_0[_index_0]
        doTask(item)
      end
    else
      doTask(requires[name])
    end
  end
  local start = os.clock()
  local safe, res = pcall(task, environment)
  if safe then
    done[name] = true
    local elapsed = os.clock() - start
    return print(("Completed %s in %0.2fs."):format(name, elapsed))
  else
    return print("Error in task: " .. tostring(name) .. "\n " .. tostring(res))
  end
end
local help = "\tUsage: moonraker tasks... (optional)"
local doFile
doFile = function(file)
  local start = os.clock()
  local filepath = file or ".moonraker"
  if arg[1] and arg[1]:match("%-h.*") then
    print(help)
    return 
  end
  if not io.open(filepath, "r") then
    print("Unable to open: " .. tostring(filepath))
    os.exit(1)
  end
  local mrfile = table.concat((function()
    local _accum_0 = { }
    local _len_0 = 1
    for l in io.lines(filepath) do
      _accum_0[_len_0] = l
      _len_0 = _len_0 + 1
    end
    return _accum_0
  end)(), "\n")
  local mrfunc = assert(moonscript.loadstring(mrfile))
  setfenv(mrfunc, environment)
  local safe, errors = pcall(mrfunc)
  local task = arg[1] or default
  if safe then
    local i = 1
    while task do
      doTask(task)
      i = i + 1
      task = arg[i]
    end
  end
  os.remove(tmpname)
  if errors then
    print(errors)
  end
  local elapsed = os.clock() - start
  return print(("Completed all tasks in %0.2fs."):format(elapsed))
end
return doFile
