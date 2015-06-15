include "constants.lua"
include "pieceControl.lua"

local base, body, aim = piece('base', 'body', 'aim')
local door1, door2, hinge1, hinge2 = piece('door1', 'door2', 'hinge1', 'hinge2')
local turret, launcher, firep1, firep2 = piece('turret', 'launcher', 'firep1', 'firep2')

local explodables1 = {turret, hinge1, hinge2} -- not visible on wreck so we can throw these
local explodables2 = {door2, door1, launcher}
local smokePiece = { body, turret }

local gun = false
local closed = true
local disarmed = false
local currentTask = 0

local SigAim = 1

local function Close ()
	currentTask = 1
	if disarmed then return	end
	closed = true

	Turn (launcher, x_axis, 0, math.rad(90))
	Move (turret, y_axis, -13.5, 15)
	WaitForMove (turret, y_axis)
	if disarmed then return	end

	Turn (door1, z_axis,  math.rad(150),math.rad(125))
	Turn (door2, z_axis, -math.rad(150),math.rad(125))
	WaitForTurn (door1, z_axis)
	if disarmed then return	end

	currentTask = 0
	Spring.SetUnitArmored (unitID, true)
end

local function RestoreAfterDelay()
	Sleep (5000)
	Close()
end

local function Open ()
	StartThread (RestoreAfterDelay)
	if not closed then return end
	currentTask = 2
	Spring.SetUnitArmored (unitID, false)

	Turn (door1, z_axis, 0, math.rad(275))
	Turn (door2, z_axis, 0, math.rad(275))
	WaitForTurn (door1, z_axis)

	if disarmed then return	end
	Move (turret, y_axis, 0, 50)
	WaitForMove (turret, y_axis)

	if disarmed then return	end
	currentTask = 0
	closed = false
end

local function StunThread ()
	if disarmed then return end
	disarmed = true
	Signal (SigAim)

	-- StopMove (turret, y_axis) -- seems gebork
	StopTurn (turret, y_axis)
	StopTurn (launcher, x_axis)
	StopTurn (door1, z_axis)
	StopTurn (door2, z_axis)

	while IsDisarmed() do
		Sleep (100)
	end

	SetSignalMask (SigAim)
	disarmed = false
	if currentTask == 1 then
		Close()
	elseif currentTask == 2 then
		Open()
	else
		RestoreAfterDelay()
	end
end

function Stunned ()
	StartThread (StunThread)
end

function script.Create()
	StartThread (SmokeUnit, smokePiece)
	while (select(5, Spring.GetUnitHealth(unitID)) < 1) do
		Sleep (1000)
	end
	SetSignalMask (SigAim)
	RestoreAfterDelay()
end

function script.QueryWeapon() return gun and firep1 or firep2 end
function script.AimFromWeapon() return aim end

function script.AimWeapon (num, heading, pitch)

	if disarmed and closed then return false end -- prevents slowpoke.jpg (when it opens up after stun wears off even if target is long gone)

	Signal (SigAim)
	SetSignalMask (SigAim)

	while disarmed do
		Sleep (100)
	end

	StartThread (Open)
	while closed do
		Sleep (100)
	end

	local slowMult = (1 - (Spring.GetUnitRulesParam(unitID,"slowState") or 0))
	Turn (turret, y_axis, heading, math.rad(270)*slowMult)
	Turn (launcher, x_axis, -pitch, math.rad(180)*slowMult)

	WaitForTurn (turret, y_axis)
	WaitForTurn (launcher, x_axis)

	return true
end

function script.FireWeapon ()
	gun = not gun
	EmitSfx (gun and firep1 or firep2, 1024)
end

function script.Killed (recentDamage, maxHealth)
	local severity = recentDamage / maxHealth

	for i = 1, #explodables1 do
		if (math.random() < severity) then
			Explode (explodables1[i], sfxSmoke + sfxFire)
		end
	end

	if (severity <= .5) then
		return 1
	else
		Explode (body, sfxShatter)
		for i = 1, #explodables2 do
			if (math.random() < severity) then
				Explode (explodables2[i], sfxSmoke + sfxFire)
			end
		end
		return 2
	end
end
