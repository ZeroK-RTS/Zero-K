local flare = {piece 'flare1', piece 'flare2'}
local barrel = {piece 'barrel1', piece 'barrel2'}
local base = piece 'base'
local turret = piece 'turret'
local guns = piece 'guns'
local a1, a2, a3, a4 = piece('a1', 'a2', 'a3', 'neck')
local floatbase = piece 'floatbase'
local trueaim = piece 'trueaim'

local gun_to_use = 1

local SIG_AIM = 1

include "constants.lua"
include "pieceControl.lua"

local stuns = {false, false, false}
local disarmed = false

local StopTurn = GG.PieceControl.StopTurn

function script.Create()
	if not GG.Script.onWater(unitID) then
		Hide(floatbase)
	end
	StartThread(GG.Script.SmokeUnit, unitID, {guns})
end

local function RestoreAfterDelay()
	SetSignalMask(SIG_AIM)
	Sleep(6000)
	Turn (a1, x_axis, 0, math.rad(20))
	Turn (a2, x_axis, 0, math.rad(60))
	Turn (a3, x_axis, 0, math.rad(50))
	Turn (a4, x_axis, 0, math.rad(10))
end

local function StunThread ()
	Signal (SIG_AIM)
	SetSignalMask(SIG_AIM)
	disarmed = true

	StopTurn (turret, y_axis)
	StopTurn (guns, x_axis)
	StopTurn (a1, x_axis)
	StopTurn (a2, x_axis)
	StopTurn (a3, x_axis)
	StopTurn (a4, x_axis)
end

local function UnstunThread ()
	disarmed = false
	RestoreAfterDelay()
end

function Stunned (stun_type)
	stuns[stun_type] = true
	StartThread (StunThread)
end
function Unstunned (stun_type)
	stuns[stun_type] = false
	if not stuns[1] and not stuns[2] and not stuns[3] then
		StartThread (UnstunThread)
	end
end

function script.AimWeapon(num, heading, pitch)

	Signal (SIG_AIM)
	SetSignalMask (SIG_AIM)

	while disarmed do
		Sleep(34)
	end

	local slowMult = (Spring.GetUnitRulesParam(unitID,"baseSpeedMult") or 1)

	Turn (a1, x_axis, math.rad(-45),    math.rad(200)*slowMult)
	Turn (a2, x_axis, math.rad(135),    math.rad(600)*slowMult)
	Turn (a3, x_axis, math.rad(-112.5), math.rad(500)*slowMult)
	Turn (a4, x_axis, math.rad(22.5),   math.rad(100)*slowMult)

	Turn (turret, y_axis, heading, 3*slowMult)
	Turn (guns, x_axis, -pitch, 3*slowMult)

	WaitForTurn (turret, y_axis)
	WaitForTurn (guns, x_axis)

	StartThread(RestoreAfterDelay)
	return true
end

function script.AimFromWeapon()
	return trueaim
end

function script.QueryWeapon()
	return flare[gun_to_use]
end

function script.FireWeapon()
	Move(barrel[gun_to_use], z_axis, -15)
	EmitSfx(flare[gun_to_use], 1024)
	Move(barrel[gun_to_use], z_axis, 0, 40)
	gun_to_use = 3 - gun_to_use
end

local explodables = {barrel[1], barrel[2], a2, a4, turret}
function script.Killed (recentDamage, maxHealth)
	local severity = recentDamage / maxHealth
	local brutal = (severity > 0.5)
	local sfx = SFX

	local effect = sfx.FALL + (brutal and (sfx.SMOKE + sfx.FIRE) or 0)
	for i = 1, #explodables do
		if math.random() < severity then
			Explode (explodables[i], effect)
		end
	end

	if not brutal then
		return 1
	else
		Explode (base, sfx.SHATTER)
		return 2
	end
end
