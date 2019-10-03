local gun = piece 'gun'
local yaw = piece 'yaw'
local pelvis = piece 'pelvis'
local fire = piece 'fire'
local rcalf = piece 'rcalf'
local rfoot = piece 'rfoot'
local lcalf = piece 'lcalf'
local lfoot = piece 'lfoot'
local lthigh = piece 'lthigh'
local rthigh = piece 'rthigh'

include "constants.lua"

-- Signal definitions
local SIG_MOVE = 1
local SIG_AIM = 2
local SIG_RESTORE = 4

local function WalkThread()

	Signal(SIG_MOVE)
	SetSignalMask(SIG_MOVE)
	
	Move(pelvis, y_axis, -0.450000)
	Move(rcalf, y_axis, 0.000000)
	Move(rcalf, z_axis, 0.000000)
	Move(rfoot, z_axis, 0.000000)
	Move(lcalf, y_axis, 0.000000)
	Move(lcalf, z_axis, 0.000000)

	while true do
	
		Turn(pelvis, x_axis, math.rad(-0.423077))
		Turn(lthigh, x_axis, math.rad(11.060440))
		Turn(rthigh, x_axis, math.rad(-42.060440))
		Turn(rcalf, x_axis, math.rad(-4.857143))
		Turn(rfoot, x_axis, math.rad(46.934066))
		Turn(lcalf, x_axis, math.rad(61.000000))
		Turn(lfoot, x_axis, math.rad(-50.390110))
		Sleep(60)
	
		Move(pelvis, y_axis, -0.400000)
		Turn(pelvis, x_axis, math.rad(-3.082418))
		Turn(lthigh, x_axis, math.rad(34.093407))
		Turn(rthigh, x_axis, math.rad(-27.890110))
		Turn(rcalf, x_axis, math.rad(-6.637363))
		Turn(rfoot, x_axis, math.rad(37.637363))
		Turn(lcalf, x_axis, math.rad(33.615385))
		Turn(lfoot, x_axis, math.rad(-24.604396))
		Sleep(60)
		
		Move(pelvis, y_axis, -0.300000)
		Turn(pelvis, x_axis, math.rad(-4.857143))
		Turn(lthigh, x_axis, math.rad(28.747253))
		Turn(rthigh, x_axis, math.rad(-19.027473))
		Turn(rcalf, x_axis, math.rad(-4.412088))
		Turn(rfoot, x_axis, math.rad(27.890110))
		Turn(lcalf, x_axis, math.rad(13.725275))
		Turn(lfoot, x_axis, math.rad(-25.978022))
		Sleep(60)
		
		Move(pelvis, y_axis, -0.100000)
		Turn(pelvis, x_axis, math.rad(-6.181319))
		Turn(lthigh, x_axis, math.rad(12.813187))
		Turn(rthigh, x_axis, 0)
		Turn(rcalf, x_axis, math.rad(3.082418))
		Turn(rfoot, x_axis, math.rad(2.203297))
		Turn(lcalf, x_axis, math.rad(-12.335165))
		Turn(lfoot, x_axis, math.rad(7.648352))
		Sleep(60)

		Move(pelvis, y_axis, 0.000000)
		Turn(pelvis, x_axis, math.rad(-4.857143))
		Turn(lthigh, x_axis, math.rad(-19.467033))
		Turn(rthigh, x_axis, math.rad(1.758242))
		Turn(rcalf, x_axis, math.rad(8.401099))
		Turn(rfoot, x_axis, math.rad(-6.181319))
		Turn(lcalf, x_axis, math.rad(-16.813187))
		Turn(lfoot, x_axis, math.rad(42.505495))
		Sleep(60)

		Move(pelvis, y_axis, -0.350000)
		Turn(pelvis, x_axis, math.rad(-3.082418))
		Turn(lthigh, x_axis, math.rad(-32.324176))
		Turn(rthigh, x_axis, math.rad(13.280220))
		Turn(rcalf, x_axis, math.rad(23.159341))
		Turn(rfoot, x_axis, math.rad(-33.170330))
		Turn(lfoot, x_axis, math.rad(7.357143))
		Sleep(60)

		Move(pelvis, y_axis, -0.400000)
		Turn(pelvis, x_axis, math.rad(-0.423077))
		Turn(lthigh, x_axis, math.rad(-36.291209))
		Turn(rcalf, x_axis, math.rad(43.571429))
		Turn(rfoot, x_axis, math.rad(-43.148352))
		Turn(lcalf, x_axis, math.rad(-10.082418))
		Turn(lfoot, x_axis, math.rad(28.236264))
		Sleep(60)

		Move(pelvis, y_axis, -0.450000)
		Turn(pelvis, x_axis, math.rad(-0.423077))
		Turn(lthigh, x_axis, math.rad(-42.060440))
		Turn(rthigh, x_axis, math.rad(12.824176))
		Turn(rcalf, x_axis, math.rad(60.692308))
		Turn(rfoot, x_axis, math.rad(-44.824176))
		Turn(lcalf, x_axis, math.rad(-4.412088))
		Turn(lfoot, x_axis, math.rad(46.934066))
		Sleep(60)

		Move(pelvis, y_axis, -0.400000)
		Turn(pelvis, x_axis, math.rad(-3.082418))
		Turn(lthigh, x_axis, math.rad(-32.758242))
		Turn(rthigh, x_axis, math.rad(34.093407))
		Turn(rcalf, x_axis, math.rad(23.615385))
		Turn(rfoot, x_axis, math.rad(-10.791209))
		Turn(lcalf, x_axis, math.rad(-5.747253))
		Turn(lfoot, x_axis, math.rad(42.505495))
		Sleep(60)

		Move(pelvis, y_axis, -0.300000)
		Turn(pelvis, x_axis, math.rad(-4.857143))
		Turn(lthigh, x_axis, math.rad(-25.225275))
		Turn(rthigh, x_axis, math.rad(28.769231))
		Turn(rcalf, x_axis, math.rad(10.527473))
		Turn(rfoot, x_axis, math.rad(-20.978022))
		Turn(lcalf, x_axis, math.rad(-3.978022))
		Turn(lfoot, x_axis, math.rad(33.648352))
		Sleep(60)

		Move(pelvis, y_axis, -0.900000)
		Turn(pelvis, x_axis, math.rad(-6.181319))
		Turn(lthigh, x_axis, math.rad(-12.390110))
		Turn(rthigh, x_axis, math.rad(-0.423077))
		Turn(rcalf, x_axis, math.rad(-11.659341))
		Turn(rfoot, x_axis, math.rad(22.978022))
		Turn(lcalf, x_axis, math.rad(4.115385))
		Turn(lfoot, x_axis, math.rad(14.016484))
		Sleep(60)

		Move(pelvis, y_axis, 0.000000)
		Turn(pelvis, x_axis, math.rad(-4.857143))
		Turn(lthigh, x_axis, 0)
		Turn(rthigh, x_axis, math.rad(-19.467033))
		Turn(rcalf, x_axis, math.rad(-20.302198))
		Turn(rfoot, x_axis, math.rad(23.445055))
		Turn(lcalf, x_axis, math.rad(24.203297))
		Turn(lfoot, x_axis, math.rad(-20.736264))
		Sleep(60)

		Move(pelvis, y_axis, -0.350000)
		Turn(pelvis, x_axis, math.rad(-3.082418))
		Turn(lthigh, x_axis, math.rad(9.280220))
		Turn(rthigh, x_axis, math.rad(-28.769231))
		Turn(rcalf, x_axis, math.rad(-25.225275))
		Turn(rfoot, x_axis, math.rad(26.115385))
		Turn(lcalf, x_axis, math.rad(31.868132))
		Turn(lfoot, x_axis, math.rad(-37.637363))
		Sleep(60)

		Move(pelvis, y_axis, -0.400000)
		Turn(pelvis, x_axis, math.rad(-0.423077))
		Turn(lthigh, x_axis, math.rad(11.060440))
		Turn(rthigh, x_axis, math.rad(-37.192308))
		Turn(rcalf, x_axis, math.rad(-9.280220))
		Turn(rfoot, x_axis, math.rad(6.104396))
		Turn(lcalf, x_axis, math.rad(47.604396))
		Turn(lfoot, x_axis, math.rad(-47.412088))
		Sleep(60)
	end
end

function script.Create()
	Turn(fire, x_axis, math.rad(-45.000000))
	StartThread(GG.Script.SmokeUnit, unitID, {pelvis})
end

function script.StartMoving()
	StartThread(WalkThread)
end

function script.StopMoving()
	Signal(SIG_MOVE)
	
	Move(pelvis, y_axis, 0.000000, 1.000000)
	Turn(rthigh, x_axis, 0, math.rad(200.000000))
	Turn(rcalf, x_axis, 0, math.rad(200.000000))
	Turn(rfoot, x_axis, 0, math.rad(200.000000))
	Turn(lthigh, x_axis, 0, math.rad(200.000000))
	Turn(lcalf, x_axis, 0, math.rad(200.000000))
	Turn(lfoot, x_axis, 0, math.rad(200.000000))
end


function script.AimFromWeapon()
	return gun
end

function script.QueryWeapon()
	return fire
end

local function RestoreAfterDelay()
	Signal(SIG_RESTORE)
	SetSignalMask(SIG_RESTORE)
	Sleep(800)
	Turn(yaw, y_axis, 0, math.rad(80))
	Turn(gun, x_axis, 0, math.rad(80))
end

function script.AimWeapon(num, heading, pitch)
	Signal(SIG_AIM)
	SetSignalMask(SIG_AIM)
	Turn(yaw, y_axis, heading, math.rad(420))
	Turn(gun, x_axis, -pitch, math.rad(220))
	WaitForTurn(yaw, y_axis)
	WaitForTurn(gun, x_axis)
	StartThread(RestoreAfterDelay)
	return true
end

local function ShotScript()
	Sleep(1)
	Explode(lcalf, SFX.FALL)
	Explode(rcalf, SFX.FALL)
	Explode(lfoot, SFX.FALL)
	Explode(rfoot, SFX.FALL)
	GG.PuppyHandler_Shot(unitID)
end

function script.Shot()
	StartThread(ShotScript)
end

function script.BlockShot(num, targetID)
	return GG.PuppyHandler_IsHidden(unitID) or GG.OverkillPrevention_CheckBlock(unitID, targetID, 407, 15, 0.25)
end

function script.Killed(recentDamage, maxHealth)
	local severity = recentDamage/maxHealth
	if severity <= 0.25 then
		Explode(lfoot, SFX.FALL)
		Explode(rfoot, SFX.FALL)
		return 1
	elseif severity <= 0.50 then
		Explode(lcalf, SFX.FALL)
		Explode(rcalf, SFX.FALL)
		Explode(lfoot, SFX.FALL)
		Explode(rfoot, SFX.FALL)
		return 1
	elseif severity <= 0.99 then
		Explode(pelvis, SFX.FALL + SFX.EXPLODE)
		Explode(lthigh, SFX.FALL)
		Explode(rthigh, SFX.FALL)
		Explode(lcalf, SFX.FALL)
		Explode(rcalf, SFX.FALL)
		Explode(lfoot, SFX.FALL)
		Explode(rfoot, SFX.FALL)
		return 2
	end
	Explode(pelvis, SFX.FALL + SFX.EXPLODE)
	Explode(lthigh, SFX.FALL + SFX.FIRE)
	Explode(rthigh, SFX.FALL + SFX.FIRE)
	Explode(lcalf, SFX.FALL)
	Explode(rcalf, SFX.FALL)
	Explode(lfoot, SFX.FALL)
	Explode(rfoot, SFX.FALL)
end
