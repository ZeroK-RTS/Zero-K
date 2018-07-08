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

	Spring.Echo("game_message: " .. WG.Translate("interface", "morph_complete", {
		new = Spring.Utilities.GetHumanName(UnitDefs[Spring.GetUnitDefID(newUnit)], newUnit),
		old = Spring.Utilities.GetHumanName(UnitDefs[Spring.GetUnitDefID(unitID )], unitID ),
	}))
end
