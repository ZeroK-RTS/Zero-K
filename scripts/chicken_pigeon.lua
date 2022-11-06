include "constants.lua"

local body, head, tail, lwing, rwing, rblade, lblade = piece("body", "head", "tail", "lwing", "rwing", "rblade", "lblade")


local SIG_AIM  = 2 -- doesn't really have an aiming animation. Why is this here?
local SIG_MOVE = 4

local function FlyThread()
	Signal (SIG_MOVE)
	SetSignalMask(SIG_MOVE)
	while true do
		Turn(lwing, z_axis, math.rad(-40), math.rad(120))
		Turn(rwing, z_axis, math.rad(40), math.rad(120))
		WaitForTurn(lwing, z_axis)
		Turn(lwing, z_axis, math.rad(40), math.rad(240))
		Turn(rwing, z_axis, math.rad(-40), math.rad(240))
		WaitForTurn(lwing, z_axis)
	end
end

local function StopFlying()
	Turn(lwing, z_axis, 0, math.rad(240))
	Turn(rwing, z_axis, 0, math.rad(240))
	Signal(SIG_MOVE)
end

local function RestoreAfterDelay()
	Sleep(3000)
	Turn(head, x_axis, 0, math.rad(100))
	Turn(head, y_axis, 0, math.rad(100))
end

local function MoveMouth()
	Turn(lblade, y_axis, math.rad(20), 1)
	Turn(rblade, y_axis, math.rad(-20), 1)
	WaitForTurn(lblade, y_axis)
	Turn(lblade, y_axis, 0, 0.3)
	Turn(rblade, y_axis, 0, 0.3)
end

function script.StartMoving()
	StartThread(FlyThread)
end

function script.StopMoving()
	StopFlying()
end

function script.Shot()
	StartThread(MoveMouth)
end

function script.AimWeapon(num, heading, pitch)
	if num == 1 then
		Signal(SIG_AIM)
		SetSignalMask(SIG_AIM)
		Turn(head, x_axis, -pitch, math.rad(200))
		Turn(head, y_axis, heading, math.rad(200))
		WaitForTurn(head, y_axis)
		WaitForTurn(head, x_axis)
		StartThread(RestoreAfterDelay)
		return true
	end
	return true
end

function script.BlockShot(num)
	return num == 2
end

function script.HitByWeapon(x, z, weaponDefID, damage)
	if damage > 0 then
		EmitSfx(body, 1024)
	end
	return damage
end

function script.AimFromWeapon(num)
	return head
end

function script.Killed(recentDamage, maxHealth)
	EmitSfx(body, 1025)
	local explodables = {body, head, tail, lwing, rwing, rblade, lblade}
	for i = 1, #explodables do
		Explode(explodables[i], SFX.FALL)
	end
	return 0
end
