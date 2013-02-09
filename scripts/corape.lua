local base = piece 'base' 
local lWing = piece 'lWing' 
local rWing = piece 'rWing' 
local gun1 = piece 'gun1' 
local gun2 = piece 'gun2' 
local muzz1 = piece 'muzzle1' 
local muzz2 = piece 'muzzle2' 

local thrust1 = piece 'thrust1' 
local thrust2 = piece 'thrust2' 

smokePiece = {base}

include "constants.lua"

local gun_1 = false
local firestate = Spring.GetUnitStates(unitID).firestate

function script.Create()
	StartThread(SmokeUnit)
end


function script.Activate()
	Turn(lWing,z_axis, rad(-25),0.7)
	Turn(rWing,z_axis, rad(25),0.7)
end

function script.Deactivate()
	Turn(lWing,z_axis, rad(0),1)
	Turn(rWing,z_axis, rad(0),1)
end

function script.QueryWeapon(num)
	if gun_1 then return gun1
	else return gun2 end
end

function script.AimFromWeapon(num)
	return body
end

function script.AimWeapon(num, heading, pitch)
	return true
end

function script.FireWeapon(num)
end



function script.Shot(num) 
	gun_1 = not gun_1
end

function script.Killed(recentDamage, maxHealth)
	local severity = recentDamage/maxHealth
	if severity <= .25  then
		
		Explode(base, SFX.FALL + SFX.FIRE  + SFX.SMOKE  + SFX.EXPLODE_ON_HIT )
		Explode(lWing, sfxFall)
		Explode(rWing, SFX.FALL + SFX.FIRE  + SFX.SMOKE  + SFX.EXPLODE_ON_HIT)
		return 1
	elseif  severity <= .50  then
		Explode(base, SFX.FALL + SFX.FIRE  + SFX.SMOKE  + SFX.EXPLODE_ON_HIT )
		Explode(lWing, sfxFall)
		Explode(rWing, SFX.FALL + SFX.FIRE  + SFX.SMOKE  + SFX.EXPLODE_ON_HIT)

		return 1
	elseif  severity <= .99  then
		Explode(base, SFX.FALL + SFX.FIRE  + SFX.SMOKE  + SFX.EXPLODE_ON_HIT )
		Explode(lWing, sfxFall)
		Explode(rWing, SFX.FALL + SFX.FIRE  + SFX.SMOKE  + SFX.EXPLODE_ON_HIT)

		return 2
	else
		Explode(base, sfxShatter)
		Explode(lWing, sfxShatter)
		Explode(rWing, sfxShatter)
		return 2
	end
end
