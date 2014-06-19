-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------

local isNewEngine = not ((Game.version:find('91.0') == 1) and (Game.version:find('91.0.1') == nil))

function Spring.Utilities.getMovetype(ud)
	if ud.canFly or ud.isAirUnit then
		if isNewEngine then
			if ud.isHoveringAirUnit then
				return 1 -- gunship
			else
				return 0 -- fixedwing
			end
		else
			if (ud.isFighter or ud.isBomber) then
				return 0 -- fixedwing
			else
				return 1 -- gunship
			end
		end
	elseif not (ud.isBuilding or ud.isFactory or ud.speed == 0) then
		return 2 -- ground/sea
	end
	return false -- For structures or any other invalid movetype
end