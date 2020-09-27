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

local function findAirpadUnderCursour (cmdParams) 
	local mouseX,mouseY,mouseZ = cmdParams[1], cmdParams[2], cmdParams[3]
	--local mouseX, mouseY = Spring.GetMouseState()
	local type, id = Spring.TraceScreenRay(mouseX, mouseY, false)
	if type == "unit" then
		Spring.Echo(id)
	end
end

function widget:CommandNotify(cmdID, cmdParams, cmdOptions)
    if cmdID == CMD_EXCLUDEAIRPAD then
        findAirpadUnderCursour(cmdParams)
        Spring.Echo("Hi")
        return true,true
    end
    return false -- command not used
end