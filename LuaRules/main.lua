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
--VFS.Include('LuaRules/gadgets.lua', nil, VFS.ZIP_ONLY)
Spring.Echo("Synced LuaRules: finished loading")
