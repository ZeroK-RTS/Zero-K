if GG.TransportAllowed then
	return
end

function GG.TransportAllowed(passengerID)
	if Spring.GetUnitAllyTeam(unitID) == Spring.GetUnitAllyTeam(passengerID) then
		return true
	end
	local _,_,_,speed = Spring.GetUnitVelocity(passengerID)
	if speed > 0.7 then
		return false
	end
	return true
end
