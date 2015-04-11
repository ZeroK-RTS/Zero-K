function widget:GetInfo() return {
	name	= "Morph Finished notification",
	desc	= "Evolution complete",
	author	= "sprung",
	license	= "pd",
	layer	= 0,
	enabled	= true,
} end

function widget:UnitDestroyed(unitID, unitDefID, unitTeam)
	if (unitTeam ~= Spring.GetMyTeamID()) then return end
	
	local newUnit = Spring.GetUnitRulesParam(unitID, "wasMorphedTo")
	if not newUnit then return end

	local newUnitDefID = Spring.GetUnitDefID(newUnit)
	Spring.Echo("game_message: Morph complete: " .. UnitDefs[newUnitDefID].humanName)
end
