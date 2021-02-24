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
local crystals = {}
local state = true
crystals[1] = piece('crystal1')
crystals[2] = piece('crystal2')
crystals[3] = piece('crystal3')
crystals[4] = piece('crystal4')

local smokePiece = {base}

local function WobbleTurret()
	while true do
		Move(turret, y_axis, WOBBLE_DIST, WOBBLE_SPEED)
		WaitForMove(turret, y_axis)
		Move(turret, y_axis, -1 * WOBBLE_DIST, WOBBLE_SPEED)
		WaitForMove(turret, y_axis)
		Sleep(100)
	end
end

local function WobbleCrystals()
	local mult = -1
	while true do
		for i = 1, #crystals do
			if i == 3 then
				mult = 1
			elseif i == 4 then
				mult = -1
			end
			if i%2 == 0 then
				Move(crystals[i], y_axis, mult * WOBBLE_DIST, WOBBLE_SPEED)
			else
				Move(crystals[i], x_axis, mult * WOBBLE_DIST, WOBBLE_SPEED)
			end
		end
		WaitForMove(crystals[4], x_axis)
		for i = 1, #crystals do
			if i == 3 then
				mult = -1
			elseif i == 4 then
				mult = 1
			end
			if i%2 == 0 then
				Move(crystals[i], y_axis, mult * WOBBLE_DIST, WOBBLE_SPEED)
			else
				Move(crystals[i], x_axis, mult * WOBBLE_DIST, WOBBLE_SPEED)
			end
		end
		WaitForMove(crystals[4], x_axis)
		Sleep(100)
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

