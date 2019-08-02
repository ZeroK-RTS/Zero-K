
local moveType = {}
for i = 1, #UnitDefs do
	local ud = UnitDefs[i]
	if ud.canFly or ud.isAirUnit then
		if ud.isHoveringAirUnit then
			moveType[i] = 1 -- gunship
		else
			moveType[i] = 2 -- fixedwing
		end
	elseif not ud.isImmobile then
		moveType[i] = 2 -- ground/sea
	end
	moveType[i] = false -- For structures or any other invalid movetype
end

function Spring.Utilities.getMovetype(ud)
	if ud.canFly or ud.isAirUnit then
		if ud.isHoveringAirUnit then
			return 1 -- gunship
		else
			return 0 -- fixedwing
		end
	elseif not ud.isImmobile then
		return 2 -- ground/sea
	end
	return false -- For structures or any other invalid movetype
end

function Spring.Utilities.GetMovetypeUnitDefID(unitDefID)
	return unitDefID and moveType[unitDefID]
end

function Spring.Utilities.getMovetypeByID(unitDefID)
	local ud = unitDefID and UnitDefs[unitDefID]
	if ud then
		return Spring.Utilities.getMovetype(ud)
	end
	return false
end
