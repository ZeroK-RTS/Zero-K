include "constants.lua"
local WOBBLE_DIST = 2
local WOBBLE_SPEED = 2
local TURRET_AIM_SPEED = math.rad(300)
local TURRET_SPIN_SPEED = math.rad(60)
local RING_SPIN_SPEED = -1 * math.rad(120)
local CRYSTAL_TURN_SPEED = math.rad(150)


-- pieces --
local gp = piece('gp')
local base = piece('base')
local turret = piece('turret')
local ring = piece('ring')
local center = piece('center')
local firepoint = piece('firepoint')
local crystals = {piece('crystal1', 'crystal2', 'crystal3', 'crystal4')}
local state = true

local smokePiece = {base}

local function WobbleTurret()
	while true do
		Move(turret, y_axis, WOBBLE_DIST, WOBBLE_SPEED)
		WaitForMove(turret, y_axis)
		Move(turret, y_axis, -WOBBLE_DIST, WOBBLE_SPEED)
		WaitForMove(turret, y_axis)
	end
end

local function WobbleCrystals()
	local mult = -1
	while true do
		Move(crystals[1], x_axis, mult * WOBBLE_DIST, WOBBLE_SPEED)
		Move(crystals[2], y_axis, mult * WOBBLE_DIST, WOBBLE_SPEED)
		Move(crystals[3], x_axis, -mult * WOBBLE_DIST, WOBBLE_SPEED)
		Move(crystals[4], y_axis, -mult * WOBBLE_DIST, WOBBLE_SPEED)
		WaitForMove(crystals[4], y_axis)
		mult = -mult
	end
end

function script.Create()
	StartThread(WobbleTurret)
	StartThread(WobbleCrystals)
	StartThread(GG.Script.SmokeUnit, unitID, smokePiece)
	Hide(center)
	Hide(firepoint)
	Spin(turret, z_axis, TURRET_SPIN_SPEED)
	Spin(ring, z_axis, RING_SPIN_SPEED)
end

function script.Activate()
	state = true
	for i = 1, #crystals do
		Turn(crystals[i], z_axis, 0, CRYSTAL_TURN_SPEED)
	end
end

function script.Deactivate()
	state = false
	for i = 1, #crystals do
		Turn(crystals[i], z_axis, math.rad(180), CRYSTAL_TURN_SPEED)
	end
end

function script.AimFromWeapon(num)
	return center
end

function script.AimWeapon(num, heading, pitch)
	Turn(turret, y_axis, heading, TURRET_AIM_SPEED)
	Turn(turret, x_axis, -1 * pitch, TURRET_AIM_SPEED)
	WaitForTurn(turret, y_axis)
	WaitForTurn(turret, x_axis)
	return true
end

function script.BlockShot(num)
	if num == 1 and not state then
		return true
	elseif num == 2 and state then
		return true
	end
	return false
end

function script.QueryWeapon(num)
	return firepoint
end

function script.Killed(recentDamage, maxHealth)
	local severity = recentDamage / maxHealth
	if severity <= 0.5 then
		Explode(base, SFX.EXPLODE)
		Explode(ring, SFX.EXPLODE)
		Explode(turret, SFX.EXPLODE)
		return 1
	else
		Explode(base, SFX.SHATTER)
		Explode(ring, SFX.FALL)
		Explode(turret, SFX.SHATTER)
		return 2
	end
end

