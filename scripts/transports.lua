if GG.TransportAllowed then
	return
end

function GG.TransportAllowed(unitID, passengerID)
	if Spring.GetUnitRulesParam(unitID, "disarmed") == 1 then
		return false
	end
	if Spring.GetUnitAllyTeam(unitID) == Spring.GetUnitAllyTeam(passengerID) then
		return true
	end
	local _,_,_,speed = Spring.GetUnitVelocity(passengerID)
	if speed > 0.7 then
		return false
	end
	return true
end
