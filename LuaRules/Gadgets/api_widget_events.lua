if gadgetHandler:IsSyncedCode() then return end

function gadget:GetInfo() return {
	name      = "Widget Events",
	desc      = "Tells widgets about events they can know about",
	author    = "Sprung, Klon",
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

function gadget:UnitDestroyed (unitID, unitDefID, unitTeam, attUnitID, attUnitDefID, attTeamID)	
	local myAllyTeamID = spGetMyAllyTeamID()
	local spec, specFullView = spGetSpectatingState()
	local isAllyUnit = spAreTeamsAllied(unitTeam, spGetMyTeamID())
	
	if spec then
		--Script.LuaUI.UnitDestroyedByTeam (unitID, unitDefID, unitTeam, attTeamID)		
		if not specFullView and not isAllyUnit and spGetUnitLosState(unitID, myAllyTeamID).los then
			Script.LuaUI.UnitDestroyed (unitID, unitDefID, unitTeam)
		end
	else
		local attackerInLos = attUnitID and spGetUnitLosState(attUnitID, myAllyTeamID).los
		if isAllyUnit then			
			--Script.LuaUI.UnitDestroyedByTeam (unitID, unitDefID, unitTeam, attackerInLos and attTeamID or nil)
		elseif spGetUnitLosState(unitID, myAllyTeamID).los then
			Script.LuaUI.UnitDestroyed (unitID, unitDefID, unitTeam)
			--Script.LuaUI.UnitDestroyedByTeam (unitID, unitDefID, unitTeam, attackerInLos and attTeamID or nil)
		end		
	end
end
