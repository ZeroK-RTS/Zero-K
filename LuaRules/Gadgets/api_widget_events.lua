if gadgetHandler:IsSyncedCode() then return end

function gadget:GetInfo() return {
	name      = "Widget Events",
	desc      = "Tells widgets about events they can know about",
	author    = "Sprung",
	date      = "2015-05-27",
	license   = "PD",
	layer     = 0,
	enabled   = true,
} end

local spAreTeamsAllied     = Spring.AreTeamsAllied
local spGetMyAllyTeamID    = Spring.GetMyAllyTeamID
local spGetMyTeamID        = Spring.GetMyTeamID
local spGetSpectatingState = Spring.GetSpectatingState
local spGetUnitLosState    = Spring.GetUnitLosState

function gadget:UnitDestroyed (unitID, unitDefID, unitTeam)
	if not spAreTeamsAllied(unitTeam, spGetMyTeamID()) then
		local spec, specFullView = spGetSpectatingState()
		if ((spec and specFullView) or spGetUnitLosState(unitID, spGetMyAllyTeamID()).los) then
			Script.LuaUI.UnitDestroyed (unitID, unitDefID, unitTeam)
		end
	end
end
