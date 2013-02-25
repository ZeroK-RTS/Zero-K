--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
  return {
    name      = "Metalmap Hide Decals",
    desc      = "Hides decals when in metal map view, shows when not.",
    author    = "CarRepairer",
    date      = "2009-06-29",
    license   = "GNU GPL, v2 or later",
    layer     = 1,
    enabled   = false  
  }
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local spGetMapDrawMode		= Spring.GetMapDrawMode
local spSendCommands		= Spring.SendCommands

local lastStateMetal = false

function widget:Update()
	if lastStateMetal and spGetMapDrawMode() == 'metal' then
		lastStateMetal = false
		spSendCommands{"grounddecals 0"}
	elseif not lastStateMetal and spGetMapDrawMode() ~= 'metal' then
		lastStateMetal = true
		spSendCommands{"grounddecals 1"}
	end	
end