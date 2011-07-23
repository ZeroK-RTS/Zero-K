include "constants.lua"

local base = piece "base"
local gen1 = piece "gen1"
local gen2 = piece "gen2"

smokePiece = {gen1}

function script.Create()
	Move( gen2, y_axis, 9001)
	StartThread(SmokeUnit)
end

function script.Activate ( )
	Spin(gen1, y_axis, 1, 0.01)
	Spin(gen2, y_axis, -1, 0.01)
end

function script.Deactivate ( )
	StopSpin(gen1, y_axis, 0.1)
	StopSpin(gen2, y_axis, 0.1)
end

function script.QueryWeapon1() 
	return gen2
end

function script.AimFromWeapon1()
	return gen2
end

function script.AimWeapon1()
	return true
end

function script.FireWeapon1()
end

function script.Killed(recentDamage, maxHealth)
	local severity = recentDamage/maxHealth
	if severity < 0.5 then
		return 1
	else
		return 2
	end
end