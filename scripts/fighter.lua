include "constants.lua"

--pieces
local  base, flare1, flare2, nozzle1, nozzle2, missile, rgun, lgun, rwing, lwing, rjet, ljet, body 
	= piece( "base", "flare1", "flare2", "nozzle1", "nozzle2", "missile", "rgun", "lgun", "rwing", "lwing", "rjet", "ljet", "body")

smokePiece = {base, rwing, lwing}

--variables
local shotCycle = 0
local flare = {
	[0] = flare1,
	[1] = flare2,
}

local SPEEDUP_FACTOR = 5

----------------------------------------------------------

function SprintThread()
	for i=1,15 do
		EmitSfx(ljet, 1027)
		EmitSfx(rjet, 1027)
		Sleep(66)
	end
	Spring.SetUnitRulesParam(unitID, "selfMoveSpeedChange", 1)
	Spring.MoveCtrl.SetAirMoveTypeData(unitID, "maxAcc", 0.5)
	GG.UpdateUnitAttributes(unitID)
	GG.UpdateUnitAttributes(unitID)
	
	Turn(rwing, y_axis, 0, math.rad(100))
	Turn(lwing, y_axis, 0, math.rad(100))
end

function Sprint()
	Turn(rwing, y_axis, math.rad(65), math.rad(300))
	Turn(lwing, y_axis, math.rad(-65), math.rad(300))

	StartThread(SprintThread)
	Spring.SetUnitRulesParam(unitID, "selfMoveSpeedChange", SPEEDUP_FACTOR)	
	Spring.MoveCtrl.SetAirMoveTypeData(unitID, "maxAcc", 3)
	GG.attUnits[unitID] = true
	GG.UpdateUnitAttributes(unitID)
	GG.UpdateUnitAttributes(unitID)
end

----------------------------------------------------------

local WING_DISTANCE = 8

local function activate()
	Move(rwing, x_axis, 0, 10)
	Move(lwing, x_axis, 0, 10)
end

local function deactivate()
	Move(rwing, x_axis, WING_DISTANCE, 10)
	Move(lwing, x_axis, -WING_DISTANCE, 10)
	Turn(rwing, y_axis, 0, math.rad(30))
	Turn(lwing, y_axis, 0, math.rad(30))
	Turn(ljet, y_axis, math.pi)
	Turn(rjet, y_axis, math.pi)
end

function script.Create()
	Move(rwing, x_axis, WING_DISTANCE)
	Move(lwing, x_axis, -WING_DISTANCE)
end

function script.StartMoving()
	activate()
end

function script.StopMoving()
	deactivate()
end

function script.QueryWeapon(num) 
	if num == 1 then
		return flare[shotCycle]
	elseif num == 2 then
		return flare2
	end
end

function script.AimFromWeapon(num) 
	return base
end

function script.AimWeapon(num, heading, pitch)
	return not (GetUnitValue(COB.CRASHING) == 1) 
end

function script.FireWeapon(num)
	if num == 1 then
		shotCycle = 1 - shotCycle
		EmitSfx( flare[shotCycle], UNIT_SFX3 )
	elseif num == 2 then
		EmitSfx( flare2, UNIT_SFX3 )
	elseif num == 3 then
		EmitSfx( missile, UNIT_SFX2 )
	end
end

function script.BlockShot(num)
	return (GetUnitValue(COB.CRASHING) == 1)
end

function script.Killed(recentDamage, maxHealth)
	local severity = (recentDamage/maxHealth) * 100
	if severity < 100 then
		Explode(base, sfxNone)
		Explode(rwing, sfxNone)
		Explode(lwing, sfxNone)
		Explode(rjet, sfxSmoke + sfxFire + sfxExplode + sfxShatter + sfxExplodeOnHit)
		Explode(ljet, sfxSmoke + sfxFire + sfxExplode + sfxShatter + sfxExplodeOnHit)
		return 1
	else
		Explode(base, sfxNone)
		Explode(rwing, sfxNone)
		Explode(lwing, sfxNone)
		Explode(rjet, sfxSmoke + sfxFire + sfxExplode + sfxShatter + sfxExplodeOnHit)
		Explode(ljet, sfxSmoke + sfxFire + sfxExplode + sfxShatter + sfxExplodeOnHit)
		return 2
	end
end
