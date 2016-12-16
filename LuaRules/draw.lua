-- $Id: draw.lua 4534 2009-05-04 23:35:06Z licho $

if (select == nil) then
  select = function(n,...) 
    local arg = arg
    if (not arg) then arg = {...}; arg.n = #arg end
    return arg[((n=='#') and 'n')or n]
  end
end


do  --  wrap print() in a closure
  local origPrint = print
  print = function(arg1,...)
    if (arg1) then
      arg1 = '>> ' .. tostring(arg1)
    end
    origPrint(arg1, ...)
  end
end


local allModOptions = Spring.GetModOptions()
function Spring.GetModOption(s,bool,default)
  if (bool) then
    local modOption = allModOptions[s]
    if (modOption==nil) then modOption = (default and "1") end
    return (modOption=="1")
  else
    local modOption = allModOptions[s]
    if (modOption==nil) then modOption = default end
    return modOption
  end
end


Spring.Echo("Unsynced LuaRules: starting loading")
VFS.Include('LuaRules/gadgets.lua', nil, VFS.ZIP_ONLY)
Spring.Echo("Unsynced LuaRules: finished loading")
