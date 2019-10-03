local base = piece 'base'
local lWing = piece 'lWing'
local rWing = piece 'rWing'
local gun1 = piece 'gun1'
local gun2 = piece 'gun2'
local muzz1 = piece 'muzzle1'
local muzz2 = piece 'muzzle2'

local thrust1 = piece 'thrust1'
local thrust2 = piece 'thrust2'

local smokePiece = {base}

include "constants.lua"

local gun_1 = false

function script.Create()
	StartThread(GG.Script.SmokeUnit, unitID, smokePiece)
end

function script.Activate()
	Turn(lWing,z_axis, math.rad(-25),0.7)
	Turn(rWing,z_axis, math.rad(25),0.7)
end

function script.Deactivate()
	Turn(lWing,z_axis, math.rad(0),1)
	Turn(rWing,z_axis, math.rad(0),1)
end

function script.QueryWeapon(num)
	if gun_1 then return gun1
	else return gun2 end
end

function script.AimFromWeapon(num)
	return base
end

function script.AimWeapon(num, heading, pitch)
	return true
end

function script.FireWeapon(num)
end

function script.BlockShot(num, targetID)
	return GG.OverkillPrevention_CheckBlock(unitID, targetID, 200.1, 35)
end

function script.Shot(num)
	gun_1 = not gun_1
end

function script.Killed(recentDamage, maxHealth)
	local severity = recentDamage/maxHealth
	if severity <= 0.25 then
		Explode(base, SFX.NONE)
		Explode(lWing, SFX.NONE)
		Explode(rWing, SFX.NONE)
		return 1
	elseif severity <= 0.5 or ((Spring.GetUnitMoveTypeData(unitID).aircraftState or "") == "crashing") then
		Explode(base, SFX.FALL + SFX.FIRE + SFX.SMOKE + SFX.EXPLODE_ON_HIT)
		Explode(lWing, SFX.FALL)
		Explode(rWing, SFX.FALL + SFX.FIRE + SFX.SMOKE + SFX.EXPLODE_ON_HIT)
		return 1
	elseif severity <= 0.75 then
		Explode(base, SFX.FALL + SFX.FIRE + SFX.SMOKE + SFX.EXPLODE_ON_HIT)
		Explode(lWing, SFX.FALL)
		Explode(rWing, SFX.FALL + SFX.FIRE + SFX.SMOKE + SFX.EXPLODE_ON_HIT)
		return 2
	else
		Explode(base, SFX.SHATTER)
		Explode(lWing, SFX.SHATTER)
		Explode(rWing, SFX.SHATTER)
		return 2
	end
end
