
include "bombers.lua"
include "constants.lua"

local center = piece("center");

function script.Deactivate()
end

function script.Activate()
end

function script.Create()
	Spring.SetUnitMidAndAimPos(unitID, 0,50,0, 0,50,0, true);
	StartThread(SmokeUnit, smokePiece)
end

function script.QueryWeapon(num)
	return center
end

function script.AimFromWeapon(num)
	return center
end

function script.AimWeapon(num, heading, pitch)
	return true;
end

function script.FireWeapon(num)
	return true;
end

local predictMult = 3

function script.Killed(recentDamage, maxHealth)
	local severity = recentDamage/maxHealth
	if  severity <= .25  then
		return 1
	elseif severity <= .50  then

		return 1
	elseif severity <= 0.75  then

		return 1
	else

		return 2
	end
end
