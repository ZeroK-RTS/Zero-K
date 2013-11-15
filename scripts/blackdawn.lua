local base = piece 'base' 
local body = piece 'body' 
local firep1 = piece 'firep1' 
local firep2 = piece 'firep2' 

smokePiece = {base}

include "constants.lua"

local gun_1 = false
local firestate = Spring.GetUnitStates(unitID).firestate

function script.Create()
	StartThread(SmokeUnit)
end

function script.QueryWeapon(num)
	if gun_1 then return firep1
	else return firep2 end
end

function script.AimFromWeapon(num)
	return body
end

function script.AimWeapon(num, heading, pitch)
	--if num == 1 then return false end
	return true
end

function script.FireWeapon(num)
	--Spring.GiveOrderToUnit(unitID, CMD.FIRE_STATE, {firestate}, {})
end

--[[
function script.BlockShot(num)
	--Spring.Echo("Checking shot")
	firestate = Spring.GetUnitStates(unitID).firestate
	--Spring.GiveOrderToUnit(unitID, CMD.FIRE_STATE, {2}, {})
	return false
end
]]--

function script.Shot(num) 
	gun_1 = not gun_1
end

function script.Killed(recentDamage, maxHealth)
	local severity = recentDamage/maxHealth
	if severity <= .25  then
		Explode(base, sfxNone)
		Explode(body, sfxNone)
		return 1
	elseif  severity <= .50  then
		Explode(base, sfxNone)
		Explode(body, sfxNone)
		return 1
	elseif  severity <= .99  then
		Explode(base, sfxShatter)
		Explode(body, sfxShatter)
		return 2
	else
		Explode(base, sfxShatter)
		Explode(body, sfxShatter)
		return 2
	end
end
