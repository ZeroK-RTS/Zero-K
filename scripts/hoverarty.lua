include "constants.lua"

local base = piece 'base'
local turret = piece 'turret'
local gun = piece 'barrel1'
local wheels = {piece 'frdirt', piece 'fldirt', piece 'rrdirt', piece 'rldirt'}
local frpontoon = piece 'frpontoon'
local flpontoon = piece 'flpontoon'
local rrpontoon = piece 'rrpontoon'
local rlpontoon = piece 'rlpontoon'
local flare = piece 'firepoint1'

local smokePiece = {base, turret}

local RESTORE_DELAY = 4000

-- Signal definitions
local SIG_AIM = 2
local SIG_MOVE = 4

local curTerrainType = 4
local wobble = false
local firing = false

local function Tilt()
	while true do
		local angle1 = math.random(-15, 15)
		local angle2 = math.random(-15, 15)
		Turn(base, x_axis, math.rad(angle1*0.1), math.rad(1))
		Turn(base, z_axis, math.rad(angle2*0.1), math.rad(1))
		WaitForTurn(base, x_axis)
		WaitForTurn(base, z_axis)
	end
end

local function WobbleUnit()
	StartThread(Tilt)
	while true do
		if wobble == true then
			Move(base, y_axis, 2, 3)
		end
		if wobble == false then
			Move(base, y_axis, -2, 3)
		end
		wobble = not wobble
		Sleep(1500)
	end
end

local function HoverFX()
	while true do
		if not Spring.GetUnitIsCloaked(unitID) then
			local isOnWater = (curTerrainType == 1 or curTerrainType == 2) and select(2, Spring.GetUnitPosition(unitID)) == 0
			local emitType = isOnWater and 5 or 1024
			for i = 1, 4 do
				EmitSfx(wheels[i], emitType)
			end
		end
		Sleep(150)
	end
end

function script.setSFXoccupy(num)
	curTerrainType = num
end

function script.Create()
	Hide(flare)

	StartThread(WobbleUnit)
	
	for i = 1, 4 do
		Hide(wheels[i])
	end
	StartThread(GG.Script.SmokeUnit, unitID, smokePiece)
	StartThread(HoverFX)
end

local function RestoreAfterDelay()
	Sleep(RESTORE_DELAY)
	Turn(turret, y_axis, 0, math.rad(30))
	Turn(gun, x_axis, 0, math.rad(10))
end

function script.AimWeapon(num, heading, pitch)
	Signal(SIG_AIM)
	SetSignalMask(SIG_AIM)

	while firing do
		Sleep(100)
	end

	GG.DontFireRadar_CheckAim(unitID)
	
	Turn(turret, y_axis, heading, math.rad(70))
	Turn(gun, x_axis, -pitch, math.rad(60))
	WaitForTurn(turret, y_axis)
	WaitForTurn(gun, x_axis)
	StartThread(RestoreAfterDelay)
	return true
end

function script.BlockShot(num, targetID)
	return (targetID and GG.DontFireRadar_CheckBlock(unitID, targetID)) and true or false
end

function script.AimFromWeapon(num)
	return gun
end

function script.QueryWeapon(num)
	return flare
end

local beam_duration = WeaponDefs[UnitDef.weapons[1].weaponDef].beamtime * 1000
function script.FireWeapon()
	firing = true
	Sleep (beam_duration)
	firing = false
end

function script.Killed(recentDamage, maxHealth)
	local severity = recentDamage/maxHealth
	if severity <= .25 then
		Explode(gun, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE_ON_HIT)
		Explode(base, SFX.NONE)
		Explode(turret, SFX.NONE)
		return 1
	elseif severity <= .50 then
		Explode(gun, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE_ON_HIT)
		Explode(base, SFX.NONE)
		Explode(turret, SFX.FALL)
		return 1
	elseif severity <= .99 then
		Explode(gun, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE_ON_HIT)
		Explode(base, SFX.NONE)
		Explode(turret, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE_ON_HIT)
		Explode(flpontoon, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE_ON_HIT)
		Explode(frpontoon, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE_ON_HIT)
		Explode(rlpontoon, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE_ON_HIT)
		Explode(rrpontoon, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE_ON_HIT)
		return 2
	else
		Explode(gun, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE_ON_HIT)
		Explode(base, SFX.NONE)
		Explode(turret, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE_ON_HIT)
		Explode(flpontoon, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE_ON_HIT)
		Explode(frpontoon, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE_ON_HIT)
		Explode(rlpontoon, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE_ON_HIT)
		Explode(rrpontoon, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE_ON_HIT)
		return 2
	end
end
