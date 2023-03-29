include "constants.lua"

local body, head, tail, lwing, rwing, rblade, lblade = piece("body", "head", "tail", "lwing", "rwing", "rblade", "lblade")

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

function script.StartMoving()
	StartThread(FlyThread)
end

function script.StopMoving()
	Turn(lwing, z_axis, 0, math.rad(240))
	Turn(rwing, z_axis, 0, math.rad(240))
	Signal(SIG_MOVE)
end

function script.Shot()
	Turn(lblade, y_axis, math.rad(45))
	Turn(rblade, y_axis, math.rad(-45))
	Turn(lblade, y_axis, 0, 0.3)
	Turn(rblade, y_axis, 0, 0.3)
end

function script.AimWeapon(num, heading, pitch)
	return true
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
	Explode(body, SFX.SHATTER)
	local explodables = {head, tail, lwing, rwing, rblade, lblade}
	for i = 1, #explodables do
		Explode(explodables[i], SFX.FALL)
	end
	return 0
end
