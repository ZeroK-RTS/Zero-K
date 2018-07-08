do  --  wrap print() in a closure
  local origPrint = print
  print = function(arg1,...)
    if (arg1) then
      arg1 = Script.GetName() .. ': ' .. tostring(arg1)
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

Spring.Echo("Synced LuaRules: starting loading")
VFS.Include('LuaRules/gadgets.lua', nil, VFS.ZIP_ONLY)
Spring.Echo("Synced LuaRules: finished loading")
