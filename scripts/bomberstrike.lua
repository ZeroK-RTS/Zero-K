include "constants.lua"
include "bombers.lua"
include "fixedwingTakeOff.lua"

local fuselage = piece 'fuselage'
local wingl = piece 'wingl'
local wingr = piece 'wingr'
local wingtipl = piece 'wingtipl'
local wingtipr = piece 'wingtipr'
local enginel = piece 'enginel'
local enginer = piece 'enginer'
local head = piece 'head'
local turretbase = piece 'turretbase'
local turret = piece 'turret'
local sleevel = piece 'sleevel'
local sleever = piece 'sleever'
local barrell = piece 'barrell'
local barrelr = piece 'barrelr'
local flaremissilel = piece 'flaremissilel'
local flaremissiler = piece 'flaremissiler'
local missiler = piece 'missiler'
local missilel = piece 'missilel'

local firstFirepoint = false

local SIG_TAKEOFF = 1
local takeoffHeight = UnitDefNames["bomberstrike"].cruiseAltitude

local OKP_DAMAGE = tonumber(UnitDefs[unitDefID].customParams.okp_damage)

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function ReammoComplete()
	Show(missiler)
	Show(missilel)
end

function script.Create()
	SetInitialBomberSettings()
	StartThread(GG.TakeOffFuncs.TakeOffThread, takeoffHeight, SIG_TAKEOFF)
	StartThread(GG.Script.SmokeUnit, unitID, {wingtipl, wingtipr, head})
	Turn(turret, y_axis, math.pi)
	Move(wingl, x_axis, -5, 7)
	Move(wingr, x_axis, 5, 7)
	Hide(turretbase)
	Hide(turret)
	Hide(sleevel)
	Hide(barrell)
	Hide(sleever)
	Hide(barrelr)
	
	Move(flaremissilel, y_axis, 18)
	Move(flaremissiler, y_axis, 18)
	Move(flaremissilel, z_axis, 1)
	Move(flaremissiler, z_axis, 1)
end

function script.StartMoving()
	Move(wingl, x_axis, 0, 7)
	Move(wingr, x_axis, 0, 7)
end

function script.StopMoving()
	Move(wingl, x_axis, -5, 7)
	Move(wingr, x_axis, 5, 7)
	StartThread(GG.TakeOffFuncs.TakeOffThread, takeoffHeight, SIG_TAKEOFF)
end

function script.AimWeapon(num, heading, pitch)
	return true
end

function script.QueryWeapon(num)
	return firstFirepoint and flaremissilel or flaremissiler
end

function script.AimFromWeapon(num)
	return firstFirepoint and flaremissilel or flaremissiler
end

function script.AimWeapon(num, heading, pitch)
	return (Spring.GetUnitRulesParam(unitID, "noammo") ~= 1)
end

function script.Shot(num)
	EmitSfx(turret, 1025)
	if firstFirepoint then
		EmitSfx(flaremissilel, 1024)
	else
		EmitSfx(flaremissiler, 1024)
	end
	firstFirepoint = not firstFirepoint
end

function script.FireWeapon(num)
	Hide(missiler)
	Hide(missilel)
	Sleep(66)
	Reload()
end

function script.AimFromWeapon(num)
	return firstFirepoint and flaremissilel or flaremissiler
end

function script.BlockShot(num, targetID)
	if GG.OverkillPrevention_CheckBlockNoFire(unitID, targetID, OKP_DAMAGE, 40, false, false, false) then
		-- Remove attack command on blocked target, if it is followed by another attack command. This is commands queued in an area.
		local cmdID, _, cmdTag, cp_1, cp_2 = Spring.GetUnitCurrentCommand(unitID)
		if cmdID == CMD.ATTACK and (not cp_2) and cp_1 == targetID then
			local cmdID_2, _, _, cp_1_2, cp_2_2 = Spring.GetUnitCurrentCommand(unitID, 2)
			if cmdID_2 == CMD.ATTACK and (not cp_2_2) then
				local cQueue = Spring.GetCommandQueue(unitID, 1)
				Spring.GiveOrderToUnit(unitID, CMD.REMOVE, cmdTag, 0)
			end
		end
		return true
	end
	return GG.Script.OverkillPreventionCheck(unitID, targetID, OKP_DAMAGE, 550, 40, 0, true, false, 0.8)
end

function script.Killed(recentDamage, maxHealth)
	local severity = recentDamage/maxHealth
	if severity <= .5 then
		Explode(fuselage, SFX.NONE)
		Explode(head, SFX.NONE)
		Explode(wingl, SFX.NONE)
		Explode(wingr, SFX.NONE)
		Explode(enginel, SFX.NONE)
		Explode(enginer, SFX.NONE)
		Explode(turret, SFX.NONE)
		Explode(sleevel, SFX.NONE)
		Explode(sleever, SFX.NONE)
		return 1
	else
		Explode(fuselage, SFX.FALL + SFX.SMOKE)
		Explode(head, SFX.FALL + SFX.SMOKE + SFX.FIRE)
		Explode(wingl, SFX.FALL + SFX.SMOKE)
		Explode(wingr, SFX.FALL + SFX.SMOKE)
		Explode(enginel, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE)
		Explode(enginer, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE)
		Explode(turret, SFX.FALL + SFX.SMOKE + SFX.FIRE)
		Explode(sleevel, SFX.FALL + SFX.SMOKE)
		Explode(sleever, SFX.FALL + SFX.SMOKE)
		return 2
	end
end
