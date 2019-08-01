include "constants.lua"

--pieces
local rocketR, rocketL = piece("RocketR", "RocketL");
local droneMain = piece("DroneMain");

local smokePiece = {rocketR, rocketL,droneMain};

--variables
local shotCycle = 0
local flare = {
	[0] = rocketR,
	[1] = rocketL,
}

----------------------------------------------------------

----------------------------------------------------------

function script.Create()
end

function script.QueryWeapon(num) 
	if num == 1 then
		return flare[shotCycle]
	end
end

function script.AimFromWeapon(num) 
	return droneMain
end

function script.AimWeapon(num, heading, pitch)
	return not (GetUnitValue(COB.CRASHING) == 1) 
end

function script.FireWeapon(num)
	shotCycle = 1 - shotCycle
	EmitSfx(flare[shotCycle], GG.Script.UNIT_SFX3)
end

function script.BlockShot(num)
	return (GetUnitValue(COB.CRASHING) == 1)
end

function script.Killed(recentDamage, maxHealth)
--[[
	local severity = (recentDamage/maxHealth) * 100
	if severity < 100 then
		return 1
	else
		return 2
	end
]]--
end
