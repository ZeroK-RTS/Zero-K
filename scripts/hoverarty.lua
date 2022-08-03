include "constants.lua"

local base = piece 'base'
local turret = piece 'turret'
local barrel1 = piece 'barrel1'
local aim = piece 'aim'
local wheels = {piece 'frdirt', piece 'fldirt', piece 'rrdirt', piece 'rldirt'}
local frpontoon = piece 'frpontoon'
local flpontoon = piece 'flpontoon'
local rrpontoon = piece 'rrpontoon'
local rlpontoon = piece 'rlpontoon'
local flare = piece 'firepoint1'

local smokePiece = {base, turret}

local RESTORE_DELAY = 4000
local WOBBLE_HEIGHT = 2
local WOBBLE_SPEED = 2.5

-- Signal definitions
local SIG_AIM = 2
local SIG_WOBBLE = 4

local curTerrainType = 4
local wobbleRising = false
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
	Signal(SIG_WOBBLE)
	SetSignalMask(SIG_WOBBLE)
	while true do
		local rand = WOBBLE_SPEED + math.random()
		if wobbleRising then
			Move(base, y_axis, -WOBBLE_HEIGHT, rand)
		else
			Move(base, y_axis, WOBBLE_HEIGHT, rand)
		end
		wobbleRising = not wobbleRising
		Sleep(( 2000 * WOBBLE_HEIGHT / rand ) + ( 1000 / 6 ))
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
	StartThread(Tilt)
	
	for i = 1, 4 do
		Hide(wheels[i])
	end
	StartThread(GG.Script.SmokeUnit, unitID, smokePiece)
	StartThread(HoverFX)
end

local function RestoreAfterDelay()
	Sleep(RESTORE_DELAY)
	Turn(turret, y_axis, 0, math.rad(30))
	Turn(barrel1, x_axis, 0, math.rad(10))
end

function script.AimWeapon(num, heading, pitch)
	Signal(SIG_AIM)
	SetSignalMask(SIG_AIM)

	while firing do
		Sleep(100)
	end

	GG.DontFireRadar_CheckAim(unitID)
	
	Turn(turret, y_axis, heading, math.rad(70))
	Turn(barrel1, x_axis, -pitch, math.rad(20))
	WaitForTurn(turret, y_axis)
	WaitForTurn(barrel1, x_axis)
	StartThread(RestoreAfterDelay)
	return true
end

function script.BlockShot(num, targetID)
	-- Partial OKP damage because long beam means the unit can dodge and just get grazed
	-- Underestimate beam time so that fully-hit targets always have more pending damage in reality than in theory.
	return (targetID and (GG.DontFireRadar_CheckBlock(unitID, targetID) or GG.OverkillPrevention_CheckBlock(unitID, targetID, 1000, 20))) or false
end

function script.AimFromWeapon(num)
	return aim
end

function script.QueryWeapon(num)
	return flare
end

local beam_duration = WeaponDefs[UnitDef.weapons[1].weaponDef].beamtime * 1000
function script.FireWeapon()
	firing = true
	Signal(SIG_WOBBLE)
	if not wobbleRising then
		Move(base, y_axis, -WOBBLE_HEIGHT, WOBBLE_SPEED*0.25)
		Sleep(100)
		Move(base, y_axis, WOBBLE_HEIGHT, WOBBLE_SPEED*0.35)
		Sleep(100)
		Move(base, y_axis, WOBBLE_HEIGHT + 1, WOBBLE_SPEED*0.66)
		Sleep(100)
		Sleep(beam_duration - 300)
		Move(base, y_axis, WOBBLE_HEIGHT, WOBBLE_SPEED*0.4)
	else
		Move(base, y_axis, WOBBLE_HEIGHT, WOBBLE_SPEED*0.8)
		Sleep(100)
		Move(base, y_axis, WOBBLE_HEIGHT + 1, WOBBLE_SPEED*0.66)
		Sleep(beam_duration - 100)
	end
	Move(base, y_axis, WOBBLE_HEIGHT, WOBBLE_SPEED)
	WaitForMove(base, y_axis)
	wobbleRising = true
	StartThread(WobbleUnit)
	firing = false
end

function script.Killed(recentDamage, maxHealth)
	local severity = recentDamage/maxHealth
	if severity <= .25 then
		Explode(barrel1, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE_ON_HIT)
		Explode(base, SFX.NONE)
		Explode(turret, SFX.NONE)
		return 1
	elseif severity <= .50 then
		Explode(barrel1, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE_ON_HIT)
		Explode(base, SFX.NONE)
		Explode(turret, SFX.FALL)
		return 1
	elseif severity <= .99 then
		Explode(barrel1, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE_ON_HIT)
		Explode(base, SFX.NONE)
		Explode(turret, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE_ON_HIT)
		Explode(flpontoon, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE_ON_HIT)
		Explode(frpontoon, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE_ON_HIT)
		Explode(rlpontoon, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE_ON_HIT)
		Explode(rrpontoon, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE_ON_HIT)
		return 2
	else
		Explode(barrel1, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE_ON_HIT)
		Explode(base, SFX.NONE)
		Explode(turret, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE_ON_HIT)
		Explode(flpontoon, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE_ON_HIT)
		Explode(frpontoon, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE_ON_HIT)
		Explode(rlpontoon, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE_ON_HIT)
		Explode(rrpontoon, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE_ON_HIT)
		return 2
	end
end
