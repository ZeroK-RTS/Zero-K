include "constants.lua"
include "bombers.lua"

local fuselage = piece 'fuselage'
local wingl = piece 'wingl'
local wingr = piece 'wingr'
local wingtipl = piece 'wingtipl'
local wingtipr = piece 'wingtipr'
local enginel = piece 'enginel'
local enginer = piece 'enginer'
local exhaustl = piece 'exhaustl'
local exhaustr = piece 'exhaustr'
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
local isMoving = false

local SIG_RESTORE = 1

local shotsPerRefuel = tonumber(UnitDefs[unitDefID].customParams.shots_per_refuel) or false
local shotsRemaining = shotsPerRefuel or true

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function ReammoComplete()
	Show(missiler)
	Show(missilel)
	if shotsPerRefuel then
		shotsRemaining = shotsPerRefuel
	end
end

function script.Create()
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
	Hide(exhaustl)
	Hide(exhaustr)
	
	Move(flaremissilel, y_axis, 13)
	Move(flaremissiler, y_axis, 13)
	Move(flaremissilel, z_axis, 1)
	Move(flaremissiler, z_axis, 1)
end

function script.StartMoving()
	Show(exhaustl)
	Show(exhaustr)
	Move(wingl, x_axis, 0, 7)
	Move(wingr, x_axis, 0, 7)
	isMoving = true
end

function script.StopMoving()
	Hide(exhaustl)
	Hide(exhaustr)
	Move(wingl, x_axis, -5, 7)
	Move(wingr, x_axis, 5, 7)
	isMoving = false
end

local function SetOutOfAmmo()
	shotsRemaining = false
	Hide(missiler)
	Hide(missilel)
	Explode(missiler, SFX.FALL)
	Explode(missilel, SFX.FALL)
	Spring.SetUnitRulesParam(unitID, "ammoFraction", nil)
end

function script.EndBurst()
	if shotsPerRefuel then
		shotsRemaining = shotsRemaining - 1
		if shotsRemaining <= 0 then
			SetOutOfAmmo()
			Reload()
		else
			Spring.SetUnitRulesParam(unitID, "ammoFraction", shotsRemaining / shotsPerRefuel)
		end
	end
end

function Pad_StopMoving()
	if shotsPerRefuel and shotsRemaining then
		SetOutOfAmmo()
		GG.SetRequireRefuelRaw(unitID) -- Waste excess ammo upon landing
	end
	script.StopMoving()
end

function Pad_StartMoving()
	script.StartMoving()
end

function script.QueryWeapon(num)
	return firstFirepoint and flaremissilel or flaremissiler
end

function script.AimFromWeapon(num)
	return firstFirepoint and flaremissilel or flaremissiler
end

local function RestoreAfterDelay()
	Signal(SIG_RESTORE)
	SetSignalMask(SIG_RESTORE)
	Sleep(2000)
	Turn(missiler, y_axis, 0, 1)
	Turn(missilel, y_axis, 0, 1)
	Turn(missiler, x_axis, 0, 1)
	Turn(missilel, x_axis, 0, 1)
end

function script.AimWeapon(num, heading, pitch)
	if shotsPerRefuel and RearmBlockShot() then
		return false
	end
	if (GetUnitValue(COB.CRASHING) == 1) or not isMoving then
		return false
	end
	local x,y,z = Spring.GetUnitVelocity(unitID)
	if (x == 0 and z == 0) then
		return false
	end
	if GG.PossiblySetExtendedTurnRadius then
		GG.PossiblySetExtendedTurnRadius(unitID, unitDefID)
	end
	Turn(missiler, y_axis, heading, 3)
	Turn(missilel, y_axis, heading, 3)
	Turn(missiler, x_axis, -pitch, 3)
	Turn(missilel, x_axis, -pitch, 3)
	StartThread(RestoreAfterDelay)
	return true
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
end

function script.AimFromWeapon(num)
	return firstFirepoint and flaremissilel or flaremissiler
end

function script.BlockShot(num, targetID)
	return shotsPerRefuel and RearmBlockShot()
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
