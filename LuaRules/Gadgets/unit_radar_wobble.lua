-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
if (not gadgetHandler:IsSyncedCode()) then
    return
end
-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------

function gadget:GetInfo()
	return {
		name      = "Radar Wobble Control",
		desc      = "Implements customParams for custom radar wobble behaviour.",
		author    = "GoogleFrog",
		date      = "22 August 2020",
		license   = "GNU GPL, v2 or later",
		layer     = 0,
		enabled   = true  --  loaded by default?
	}
end

local staticDefs = {}
for i = 1, #UnitDefs do
	local ud = UnitDefs[i]
	if ud.customParams.like_structure then
		staticDefs[i] = true
	end
end

local allySeenUnit = {}
local allyTeamCount = #Spring.GetAllyTeamList()

function gadget:UnitEnteredLos(unitID, unitTeam, allyTeam, unitDefID)
	if not (unitDefID and staticDefs[unitDefID]) then
		return
	end
	if not allySeenUnit[allyTeam] then
		allySeenUnit[allyTeam] = {}
	end
	if allySeenUnit[allyTeam][unitID] then
		return
	end
	
	local x1, y1, z1, x2, y2, z2, update, allyMask = Spring.GetUnitPosErrorParams(unitID)
	Spring.SetUnitPosErrorParams(unitID, x1, y1, z1, x2, y2, z2, update, allyTeam, false)
end

function gadget:UnitDestroyed(unitID, unitDefID, unitTeam)
	if not staticDefs[unitDefID] then
		return
	end
	
	for i = 1, allyTeamCount do
		if allySeenUnit[i] and allySeenUnit[i][unitID] then
			allySeenUnit[i][unitID] = nil
		end
	end
end
