--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
  return {
    name      = "Specialmap Hide Decals",
    desc      = "Show decals when in normal view, hide in other views.",
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

local lastStateNormal = false

function widget:Update()
	if not lastStateNormal and (spGetMapDrawMode() == 'normal' or spGetMapDrawMode() == 'los') then
		lastStateNormal = true
		spSendCommands{"grounddecals 1"}
	elseif lastStateNormal and spGetMapDrawMode() ~= 'normal' and spGetMapDrawMode() ~= 'los' then
		lastStateNormal = false
		spSendCommands{"grounddecals 0"}
	end
end
