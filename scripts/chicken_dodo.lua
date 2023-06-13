include "constants.lua"

local body, head, tail, lthigh, lknee, lshin, lfoot = piece('body', 'head', 'tail', 'lthigh', 'lknee', 'lshin', 'lfoot')
local rthigh, rknee, rshin, rfoot, rsack, lsack, rblade = piece('rthigh', 'rknee', 'rshin', 'rfoot', 'rsack', 'lsack', 'rblade') 
local lblade, spike1, spike2, spike3 = piece('lblade', 'spike1', 'spike2', 'spike3')

local SIG_MOVE = 1

local function WalkThread()
	Signal(SIG_MOVE)
	SetSignalMask(SIG_MOVE)
	while true do
		Turn(lthigh, x_axis, math.rad(70), math.rad(230))
		Turn(lknee, x_axis, math.rad(-40), math.rad(270))
		Turn(lshin, x_axis, math.rad(20), math.rad(270))
		Turn(lfoot, x_axis, math.rad(-50), math.rad(420))

		Turn(rthigh, x_axis, math.rad(-20), math.rad(420))
		Turn(rknee, x_axis, math.rad(-60), math.rad(420))
		Turn(rshin, x_axis, math.rad(50), math.rad(420))
		Turn(rfoot, x_axis, math.rad(30), math.rad(420))

		Turn(body, z_axis, math.rad(5), math.rad(40))
		Turn(lthigh, z_axis, math.rad(-5), math.rad(40))
		Turn(rthigh, z_axis, math.rad(-5), math.rad(40))
		Move(body, y_axis, 0.7, 22)
		Turn(tail, y_axis, math.rad(10), math.rad(80))
		Turn(head, x_axis, math.rad(-10), math.rad(40))
		Turn(tail, x_axis, math.rad(10), math.rad(40))
		WaitForTurn(lthigh, x_axis)

		Turn(lthigh, x_axis, math.rad(-10), math.rad(320))
		Turn(lknee, x_axis, math.rad(15), math.rad(270))
		Turn(lshin, x_axis, math.rad(-60), math.rad(500))
		Turn(lfoot, x_axis, math.rad(30), math.rad(270))

		Turn(rthigh, x_axis, math.rad(40), math.rad(270))
		Turn(rknee, x_axis, math.rad(-35), math.rad(270))
		Turn(rshin, x_axis, math.rad(-40), math.rad(270))
		Turn(rfoot, x_axis, math.rad(35), math.rad(270))

		Move(body, y_axis, 0, 22)
		Turn(head, x_axis, math.rad(10), math.rad(40))
		Turn(tail, x_axis, math.rad(-10), math.rad(40))
		WaitForTurn(lshin, x_axis)

		Turn(rthigh, x_axis, math.rad(70), math.rad(230))
		Turn(rknee, x_axis, math.rad(-40), math.rad(270))
		Turn(rshin, x_axis, math.rad(20), math.rad(270))
		Turn(rfoot, x_axis, math.rad(-50), math.rad(420))

		Turn(lthigh, x_axis, math.rad(-20), math.rad(420))
		Turn(lknee, x_axis, math.rad(-60), math.rad(420))
		Turn(lshin, x_axis, math.rad(50), math.rad(420))
		Turn(lfoot, x_axis, math.rad(30), math.rad(420))

		Turn(tail, y_axis, math.rad(-10), math.rad(80))
		Turn(body, z_axis, math.rad(-5), math.rad(40))
		Turn(lthigh, z_axis, math.rad(5), math.rad(40))
		Turn(rthigh, z_axis, math.rad(5), math.rad(40))
		Move(body, y_axis, 0.7, 22)
		Turn(head, x_axis, math.rad(-10), math.rad(40))
		Turn(tail, x_axis, math.rad(10), math.rad(40))
		WaitForTurn(rthigh, x_axis)

		Turn(rthigh, x_axis, math.rad(-10), math.rad(320))
		Turn(rknee, x_axis, math.rad(15), math.rad(270))
		Turn(rshin, x_axis, math.rad(-60), math.rad(500))
		Turn(rfoot, x_axis, math.rad(30), math.rad(270))

		Turn(lthigh, x_axis, math.rad(40), math.rad(270))
		Turn(lknee, x_axis, math.rad(-35), math.rad(270))
		Turn(lshin, x_axis, math.rad(-40), math.rad(270))
		Turn(lfoot, x_axis, math.rad(35), math.rad(270))

		Move(body, y_axis, 0, 22)
		Turn(head, x_axis, math.rad(10), math.rad(40))
		Turn(tail, x_axis, math.rad(-10), math.rad(40))
		WaitForTurn(rshin, x_axis)
	end
end

function script.Create()
	EmitSfx(body, 1026)
end

function script.StopMoving()
	Signal(SIG_MOVE)
	Turn(lfoot, x_axis, 0, math.rad(200))
	Turn(rfoot, x_axis, 0, math.rad(200))
	Turn(rthigh, x_axis, 0, math.rad(200))
	Turn(lthigh, x_axis, 0, math.rad(200))
	Turn(lshin, x_axis, 0, math.rad(200))
	Turn(rshin, x_axis, 0, math.rad(200))
	Turn(lknee, x_axis, 0, math.rad(200))
	Turn(rknee, x_axis, 0, math.rad(200))
end

function script.StartMoving()
	StartThread(WalkThread)
end

function script.HitByWeapon(x, z, weaponDefID, damage)
	if damage > 0 then
		EmitSfx(body, 1024)
	end
	return damage
end

function script.Killed(recentDamage, maxHealth)
	for i = 1, 3 do
		Explode(spike1, SFX.EXPLODE)
		Explode(spike2, SFX.EXPLODE)
		Explode(spike3, SFX.EXPLODE)
	end

	Explode(body, SFX.SHATTER)
	Explode(head, 0)
end
