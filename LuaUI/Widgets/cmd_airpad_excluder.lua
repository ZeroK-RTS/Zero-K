-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------

function widget:GetInfo()
    return {
      name      = "Airpad Excluder",
      desc      = "Handler for exclude airpads gadget.",
      author    = "SharkGameDev",
      date      = "2020-09-26",
      license   = "PD",
      handler   = true,
      layer     = 0,
      enabled   = true,
    }
end

VFS.Include("LuaRules/Configs/customcmds.h.lua")

function widget:CommandNotify(cmdID, cmdParams, cmdOptions)
    if cmdID == CMD_EXCLUDEAIRPAD then
        if type == "unit" then
            Spring.SendLuaRulesMsg('addExclusion|' .. cmdParams[1])
        end
        return true,true
    end
    return false -- command not used
end
