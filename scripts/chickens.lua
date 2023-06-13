include "constants.lua"

local body,head,tail,lthigh,lknee = piece('body', 'head', 'tail', 'lthigh', 'lknee')
local lshin,lfoot,rthigh,rknee,rshin = piece('lshin', 'lfoot', 'rthigh', 'rknee', 'rshin')
local rfoot,rsack,lsack,rblade,lblade = piece('rfoot', 'rsack', 'lsack', 'rblade', 'lblade')
local mblade,spike1,spike2,spike3 = piece('mblade', 'spike1', 'spike2', 'spike3')

local bMoving   = false
local SIG_AIM   = 2
local SIG_AIM_2 = 4
local SIG_MOVE  = 8

local function Walk()
	Signal(SIG_MOVE)
	SetSignalMask(SIG_MOVE)
	while true do
		Turn(lthigh, x_axis, math.rad(70), math.rad(115))
		Turn(lknee, x_axis, math.rad(-40), math.rad(145))
		Turn(lshin, x_axis, math.rad(20), math.rad(145))
		Turn(lfoot, x_axis, math.rad(-50), math.rad(210))

		Turn(rthigh, x_axis, math.rad(-20), math.rad(210))
		Turn(rknee, x_axis, math.rad(-60), math.rad(210))
		Turn(rshin, x_axis, math.rad(50), math.rad(210))
		Turn(rfoot, x_axis, math.rad(30), math.rad(210))

		Turn(body, z_axis, math.rad(5), math.rad(20))
		Turn(lthigh, z_axis, math.rad(-5), math.rad(20))
		Turn(rthigh, z_axis, math.rad(-5), math.rad(20))
		Move(body, y_axis, 0.7, 11)
		Turn(tail, y_axis, math.rad(10), math.rad(40))
		Turn(head, x_axis, math.rad(-10), math.rad(20))
		Turn(tail, x_axis, math.rad(10), math.rad(20))
		WaitForTurn(lthigh, x_axis)

		Turn(lthigh, x_axis, math.rad(-10), math.rad(160))
		Turn(lknee, x_axis, math.rad(15), math.rad(145))
		Turn(lshin, x_axis, math.rad(-60), math.rad(250))
		Turn(lfoot, x_axis, math.rad(30), math.rad(145))

		Turn(rthigh, x_axis, math.rad(40), math.rad(145))
		Turn(rknee, x_axis, math.rad(-35), math.rad(145))
		Turn(rshin, x_axis, math.rad(-40), math.rad(145))
		Turn(rfoot, x_axis, math.rad(35), math.rad(145))

		Move(body, y_axis, 0, 11)
		Turn(head, x_axis, math.rad(10), math.rad(20))
		Turn(tail, x_axis, math.rad(-10), math.rad(20))
		WaitForTurn(lshin, x_axis)

		Turn(rthigh, x_axis, math.rad(70), math.rad(115))
		Turn(rknee, x_axis, math.rad(-40), math.rad(145))
		Turn(rshin, x_axis, math.rad(20), math.rad(145))
		Turn(rfoot, x_axis, math.rad(-50), math.rad(210))

		Turn(lthigh, x_axis, math.rad(-20), math.rad(210))
		Turn(lknee, x_axis, math.rad(-60), math.rad(210))
		Turn(lshin, x_axis, math.rad(50), math.rad(210))
		Turn(lfoot, x_axis, math.rad(30), math.rad(210))

		Turn(tail, y_axis, math.rad(-10), math.rad(40))
		Turn(body, z_axis, math.rad(-5), math.rad(20))
		Turn(lthigh, z_axis, math.rad(5), math.rad(20))
		Turn(rthigh, z_axis, math.rad(5), math.rad(20))
		Move(body, y_axis, 0.7, 11)
		Turn(head, x_axis, math.rad(-10), math.rad(20))
		Turn(tail, x_axis, math.rad(10), math.rad(20))
		WaitForTurn(rthigh, x_axis)

		Turn(rthigh, x_axis, math.rad(-10), math.rad(160))
		Turn(rknee, x_axis, math.rad(15), math.rad(145))
		Turn(rshin, x_axis, math.rad(-60), math.rad(250))
		Turn(rfoot, x_axis, math.rad(30), math.rad(145))

		Turn(lthigh, x_axis, math.rad(40), math.rad(145))
		Turn(lknee, x_axis, math.rad(-35), math.rad(145))
		Turn(lshin, x_axis, math.rad(-40), math.rad(145))
		Turn(lfoot, x_axis, math.rad(35), math.rad(145))

		Move(body, y_axis, 0, 11)
		Turn(head, x_axis, math.rad(10), math.rad(20))
		Turn(tail, x_axis, math.rad(-10), math.rad(20))
		WaitForTurn(rshin, x_axis)
	end
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

local function RecoilThread()
	Turn(lsack, y_axis, math.rad(40), math.rad(360))
	Turn(rsack, y_axis, math.rad(-40), math.rad(360))
	Move(rsack, x_axis, -1, 1)
	Move(lsack, x_axis, 1, 1)
	Move(mblade, z_axis, -24)
	WaitForTurn(lsack, y_axis)
	Turn(lsack, y_axis, 0, 0.3)
	Turn(rsack, y_axis, 0, 0.3)
	Move(rsack, x_axis, 0, 0.3)
	Move(lsack, x_axis, 0, 0.3)
	Move(mblade, z_axis, 0, 8)
end

function script.Shot(num)
	StartThread(RecoilThread) -- Needed because of WaitForTurn.
end

function script.QueryWeapon(num)
	return head
end

function script.AimFromWeapon(num)
	return head
end

function script.AimWeapon(num, heading, pitch)
	Signal(SIG_AIM)
	SetSignalMask(SIG_AIM)
	Turn(head, y_axis, heading, math.rad(250))
	Turn(head, x_axis, -pitch, math.rad(200))
	WaitForTurn(head, y_axis)
	return true
end

function script.HitByWeapon(x, z, weaponDefID, damage)
	EmitSfx(body, 1024)
	return damage
end

function script.StartMoving()
	StartThread(Walk)
end

function script.Create()
	EmitSfx(body, 1026)
end

function script.Killed(recentDamage, maxHealth)
	EmitSfx(body, 1025)
end
