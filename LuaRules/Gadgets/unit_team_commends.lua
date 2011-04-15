

function gadget:GetInfo()
return {
	name      = "Team Commends",
	desc      = "Implements team commends mode",
	author    = "Google Frog",
	date      = "14 April 2011",
	license   = "GNU GPL, v2 or later",
	layer     = 0,
	enabled   = true  --  loaded by default?
	}
end

function gadget:Initialize()
	if (not Spring.GetModOptions()) or (not tobool(Spring.GetModOptions().commends)) then
		gadgetHandler:RemoveGadget()
	end
end

local function killAllyTeam(allyTeamID)
	local teamList = Spring.GetTeamList(allyTeamID)
	if teamList then
		for i = 1,#teamList do
			local teamUnits = Spring.GetTeamUnits(teamList[i]) 
			for j = 1,#teamUnits do
				Spring.DestroyUnit(teamUnits[j], true)
			end
		end
	end
end

local function checkForComm(allyTeamID, exceptionUnitID)
	local teamList = Spring.GetTeamList(allyTeamID)
	if teamList then
		for i = 1,#teamList do
			local teamUnits = Spring.GetTeamUnits(teamList[i]) 
			for j = 1,#teamUnits do
				local ud = Spring.GetUnitDefID(teamUnits[j]) and UnitDefs[Spring.GetUnitDefID(teamUnits[j])]
				if ud and ud.isCommander and exceptionUnitID ~= teamUnits[j] then
					return true
				end
			end
		end
	end
	return false
end

function gadget:UnitDestroyed(unitID, unitDefID, unitTeam)
	if UnitDefs[unitDefID].isCommander then
		local _,_,_,_,_,allyTeamID = Spring.GetTeamInfo(unitTeam)
		if not checkForComm(allyTeamID, unitID) then
			killAllyTeam(allyTeamID)
		end
	end
end

function gadget:UnitGiven(unitID, unitDefID, newTeam, oldTeam)
	if UnitDefs[unitDefID].isCommander then
		local _,_,_,_,_,allyTeamID = Spring.GetTeamInfo(oldTeam)
		if not checkForComm(allyTeamID, unitID) then
			killAllyTeam(allyTeamID)
		end
	end
end