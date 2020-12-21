include 'constants.lua'
include "JumpRetreat.lua"

local pelvis = piece 'pelvis'
local pole = piece 'pole'
local aimpitch = piece 'aimpitch'
local aimyaw = piece 'aimyaw'
local lthigh, lcalf, lfoot = piece('lthigh', 'lcalf', 'lfoot')
local rthigh, rcalf, rfoot = piece('rthigh', 'rcalf', 'rfoot')
local leftLeg = { thigh = piece'lthigh', calf = piece'lcalf', foot = piece'lfoot'}
local rightLeg = { thigh = piece'rthigh', calf = piece'rcalf', foot = piece'rfoot'}
local base = piece 'base'
local box = piece 'box'

local smokePiece = { box }

-- signals
local SIG_WALK = 1
local SIG_AIM = 2
local SIG_RESTORE = 4

--[[ messy but does tell you how spin works
local function SpinScienceThread()
	local startSpinTime = Spring.GetGameFrame()
	
	local startFrame = Spring.GetGameFrame()
	Turn(pelvis, y_axis, 0)
	Spin(pelvis, y_axis, math.rad(1000000), math.rad(1))
	
	while true do
		Sleep(30)
		local frame = Spring.GetGameFrame()
		--Spring.Echo(frame - startFrame)
		local x,y,z = Spring.UnitScript.GetPieceRotation(pelvis)
		Spring.Echo(y)
	end
end
--]]

function script.Create()
	StartThread(GG.Script.SmokeUnit, unitID, smokePiece)
	--StartThread(SpinScienceThread)
end

-----------------------------
-- Jumping

local doingSomersault = false

local function jumpTuckInLegs(leg)
	Turn(leg.thigh, x_axis, math.rad(-120), math.rad(100))
	Turn(leg.calf, x_axis, math.rad(-10), math.rad(100))
	Turn(leg.foot, x_axis, math.rad(-20), math.rad(100))
end

local function jumpUnTuckLegs(leg)
	Turn(leg.thigh, x_axis, math.rad(0), math.rad(200))
	Turn(leg.calf, x_axis, math.rad(0), math.rad(200))
	Turn(leg.foot, x_axis, math.rad(0), math.rad(200))
end

local function somersaultThread(jumpDuration)
	Turn(pelvis, x_axis, math.rad(0))
	Sleep(jumpDuration/4)

	jumpTuckInLegs(leftLeg)
	jumpTuckInLegs(rightLeg)
	
	local speed = 4*math.pi/(9/16*jumpDuration/1000)
	local accel = speed*(16/6)/(jumpDuration/1000)/30
	
	Spin(pelvis, x_axis, speed, accel)
	
	Sleep(jumpDuration/2)
	
	jumpUnTuckLegs(leftLeg)
	jumpUnTuckLegs(rightLeg)
end

local function jumpLegLaunch(leg)
	Signal(SIG_WALK)
	Turn(leg.thigh, x_axis, math.rad(0))
	Turn(leg.calf, x_axis, math.rad(0))
	Turn(leg.foot, x_axis, math.rad(-40))
	
	Turn(leg.thigh, x_axis, math.rad(-30), math.rad(100))
	Turn(leg.calf, x_axis, math.rad(60), math.rad(500))
	Turn(leg.foot, x_axis, math.rad(-10), math.rad(600))
end

local function jumpLegLand(leg)
	Turn(leg.thigh, x_axis, math.rad(0), math.rad(100))
	Turn(leg.calf, x_axis, math.rad(-30), math.rad(300))
	Turn(leg.foot, x_axis, math.rad(10), math.rad(100))
end

function beginJump(turn,lineDist,flightDist,duration)
	Turn(box, x_axis, math.rad(20))
	jumpLegLaunch(leftLeg)
	jumpLegLaunch(rightLeg)
	Turn(box, x_axis, math.rad(0), math.rad(150))
	
	doingSomersault = math.random() < 0.15
	
	if doingSomersault then
		StartThread(somersaultThread, duration*GG.Script.frameToMs)
	end
end

function jumping()
end

function halfJump()
	if not doingSomersault then
		script.StopMoving()
	end
end

function endJump()
	Spring.UnitScript.StopSpin(pelvis, x_axis)
	Turn(pelvis, x_axis, math.rad(0))
	Turn(box, x_axis, math.rad(40),math.rad(400))
	Move(pelvis, y_axis, -8, 80)
	jumpLegLand(leftLeg)
	jumpLegLand(rightLeg)
end

-----------------------------
-- Walking

local function GetSpeedMod()
	local animFramesPerKeyframe = 4
	return animFramesPerKeyframe / (Spring.GetUnitRulesParam(unitID, "totalMoveSpeedChange") or 1)
end

local animSpeed = GetSpeedMod()

-- Generated from dirtbag.blend in https://github.com/psimyn/zk-blender 
-- Created by https://github.com/Beherith/Skeletor_S3O V((0, 3, 6))
local function Walk()
	Signal(SIG_WALK)
	SetSignalMask(SIG_WALK)
	-- Frame:4
	Turn(box, z_axis, math.rad(-2.568975), math.rad(77.069238) / animSpeed) -- delta=2.57
	Turn(box, y_axis, math.rad(7.341211), math.rad(220.236334) / animSpeed) -- delta=7.34
	Turn(lcalf, x_axis, math.rad(-1.514041), math.rad(45.421220) / animSpeed) -- delta=1.51
	Turn(lfoot, x_axis, math.rad(59.743439), math.rad(1792.303178) / animSpeed) -- delta=-59.74
	Turn(lfoot, y_axis, math.rad(0.108250), math.rad(3.247494) / animSpeed) -- delta=0.11
	Turn(lthigh, x_axis, math.rad(-100.054410), math.rad(3001.632294) / animSpeed) -- delta=100.05
	Turn(lthigh, z_axis, math.rad(0.336249), math.rad(10.087457) / animSpeed) -- delta=-0.34
	Turn(lthigh, y_axis, math.rad(0.314874), math.rad(9.446212) / animSpeed) -- delta=0.31
	Turn(rcalf, x_axis, math.rad(29.110341), math.rad(873.310233) / animSpeed) -- delta=-29.11
	Turn(rfoot, x_axis, math.rad(-61.844453), math.rad(1855.333543) / animSpeed) -- delta=61.84
	Turn(rthigh, x_axis, math.rad(36.897792), math.rad(1106.933707) / animSpeed) -- delta=-36.90
	Sleep((33 * animSpeed) -1)
	while true do
		animSpeed = GetSpeedMod()
		-- Frame:8
		Turn(box, z_axis, math.rad(5.601302), math.rad(245.108284) / animSpeed) -- delta=-8.17
		Turn(box, y_axis, math.rad(9.212200), math.rad(56.129658) / animSpeed) -- delta=1.87
		Turn(lcalf, x_axis, math.rad(16.125122), math.rad(529.174883) / animSpeed) -- delta=-17.64
		Turn(lfoot, x_axis, math.rad(31.054322), math.rad(860.673503) / animSpeed) -- delta=28.69
		Turn(lfoot, y_axis, math.rad(0.003523), math.rad(3.141793) / animSpeed) -- delta=-0.10
		Turn(lthigh, x_axis, math.rad(-47.246826), math.rad(1584.227510) / animSpeed) -- delta=-52.81
		Turn(lthigh, z_axis, math.rad(-0.006783), math.rad(10.290946) / animSpeed) -- delta=0.34
		Turn(lthigh, y_axis, math.rad(-0.015906), math.rad(9.923403) / animSpeed) -- delta=-0.33
		Turn(rcalf, x_axis, math.rad(51.066620), math.rad(658.688349) / animSpeed) -- delta=-21.96
		Move(rfoot, z_axis, -0.694088, 20.822643 / animSpeed) -- delta=-0.69
		Move(rfoot, y_axis, 1.335667, 40.069996 / animSpeed) -- delta=1.34
		Turn(rfoot, x_axis, math.rad(-57.792566), math.rad(121.556603) / animSpeed) -- delta=-4.05
		Turn(rthigh, x_axis, math.rad(46.468161), math.rad(287.111066) / animSpeed) -- delta=-9.57
		Sleep((33 * animSpeed) -1)
		-- Frame:12
		Move(base, y_axis, -3.394583, 101.837497 / animSpeed) -- delta=-3.39
		Move(base, z_axis, 4.023210, 120.696301 / animSpeed) -- delta=4.02
		Turn(box, x_axis, math.rad(12.028392), math.rad(360.851754) / animSpeed) -- delta=-12.03
		Turn(box, z_axis, math.rad(6.114756), math.rad(15.403643) / animSpeed) -- delta=-0.51
		Turn(box, y_axis, math.rad(4.729932), math.rad(134.468017) / animSpeed) -- delta=-4.48
		Turn(lcalf, x_axis, math.rad(-19.871788), math.rad(1079.907310) / animSpeed) -- delta=36.00
		Turn(lfoot, x_axis, math.rad(15.393249), math.rad(469.832218) / animSpeed) -- delta=15.66
		Turn(lthigh, x_axis, math.rad(5.265495), math.rad(1575.369630) / animSpeed) -- delta=-52.51
		Move(pelvis, y_axis, -3.394583, 101.837497 / animSpeed) -- delta=-3.39
		Turn(rcalf, x_axis, math.rad(-26.148073), math.rad(2316.440779) / animSpeed) -- delta=77.21
		Turn(rfoot, x_axis, math.rad(-1.225267), math.rad(1697.018982) / animSpeed) -- delta=-56.57
		Turn(rthigh, x_axis, math.rad(6.935949), math.rad(1185.966360) / animSpeed) -- delta=39.53
		Sleep((33 * animSpeed) -1)
		-- Frame:16
		Move(base, y_axis, -2.011605, 41.489346 / animSpeed) -- delta=1.38
		Move(base, z_axis, 2.765957, 37.717588 / animSpeed) -- delta=-1.26
		Turn(box, x_axis, math.rad(-0.000000), math.rad(360.851753) / animSpeed) -- delta=12.03
		Turn(box, z_axis, math.rad(2.406655), math.rad(111.243035) / animSpeed) -- delta=3.71
		Turn(box, y_axis, math.rad(-5.373214), math.rad(303.094387) / animSpeed) -- delta=-10.10
		Turn(lcalf, x_axis, math.rad(-13.805114), math.rad(182.000217) / animSpeed) -- delta=-6.07
		Turn(lfoot, x_axis, math.rad(-20.003592), math.rad(1061.905220) / animSpeed) -- delta=35.40
		Turn(lthigh, x_axis, math.rad(33.007340), math.rad(832.255353) / animSpeed) -- delta=-27.74
		Move(pelvis, y_axis, -2.011605, 41.489346 / animSpeed) -- delta=1.38
		Turn(rcalf, x_axis, math.rad(-6.633759), math.rad(585.429409) / animSpeed) -- delta=-19.51
		Move(rfoot, z_axis, 0.251930, 28.380541 / animSpeed) -- delta=0.95
		Move(rfoot, y_axis, 2.007736, 20.162090 / animSpeed) -- delta=0.67
		Turn(rfoot, x_axis, math.rad(6.775508), math.rad(240.023252) / animSpeed) -- delta=-8.00
		Turn(rthigh, x_axis, math.rad(-46.884522), math.rad(1614.614125) / animSpeed) -- delta=53.82
		Sleep((33 * animSpeed) -1)
		-- Frame:20
		Move(base, y_axis, 0.000000, 60.348151 / animSpeed) -- delta=2.01
		Move(base, z_axis, 0.000000, 82.978714 / animSpeed) -- delta=-2.77
		Turn(box, z_axis, math.rad(1.203328), math.rad(36.099827) / animSpeed) -- delta=1.20
		Turn(box, y_axis, math.rad(-11.420665), math.rad(181.423549) / animSpeed) -- delta=-6.05
		Turn(lcalf, x_axis, math.rad(25.319921), math.rad(1173.751061) / animSpeed) -- delta=-39.13
		Turn(lfoot, x_axis, math.rad(-56.752742), math.rad(1102.474494) / animSpeed) -- delta=36.75
		Turn(lthigh, x_axis, math.rad(38.004641), math.rad(149.919032) / animSpeed) -- delta=-5.00
		Move(pelvis, y_axis, 0.000000, 60.348151 / animSpeed) -- delta=2.01
		Turn(rcalf, x_axis, math.rad(3.639237), math.rad(308.189892) / animSpeed) -- delta=-10.27
		Move(rfoot, z_axis, 0.370765, 3.565055 / animSpeed) -- delta=0.12
		Move(rfoot, y_axis, 1.167700, 25.201095 / animSpeed) -- delta=-0.84
		Turn(rfoot, x_axis, math.rad(55.224026), math.rad(1453.455543) / animSpeed) -- delta=-48.45
		Turn(rthigh, x_axis, math.rad(-100.108867), math.rad(1596.730342) / animSpeed) -- delta=53.22
		Sleep((33 * animSpeed) -1)
		-- Frame:24
		Turn(box, z_axis, math.rad(-0.000000), math.rad(36.099827) / animSpeed) -- delta=1.20
		Turn(box, y_axis, math.rad(-12.189486), math.rad(23.064618) / animSpeed) -- delta=-0.77
		Turn(lcalf, x_axis, math.rad(40.228267), math.rad(447.250383) / animSpeed) -- delta=-14.91
		Turn(lfoot, x_axis, math.rad(-55.409548), math.rad(40.295828) / animSpeed) -- delta=-1.34
		Turn(lthigh, x_axis, math.rad(52.746460), math.rad(442.254578) / animSpeed) -- delta=-14.74
		Turn(rcalf, x_axis, math.rad(22.578053), math.rad(568.164467) / animSpeed) -- delta=-18.94
		Turn(rfoot, x_axis, math.rad(25.735895), math.rad(884.643933) / animSpeed) -- delta=29.49
		Turn(rthigh, x_axis, math.rad(-48.794223), math.rad(1539.439330) / animSpeed) -- delta=-51.31
		Sleep((33 * animSpeed) -1)
		-- Frame:28
		Move(base, y_axis, -4.148935, 124.468060 / animSpeed) -- delta=-4.15
		Move(base, z_axis, 3.520309, 105.609269 / animSpeed) -- delta=3.52
		Turn(box, x_axis, math.rad(11.222516), math.rad(336.675495) / animSpeed) -- delta=-11.22
		Turn(box, z_axis, math.rad(-6.360011), math.rad(190.800340) / animSpeed) -- delta=6.36
		Turn(box, y_axis, math.rad(-4.800000), math.rad(221.684594) / animSpeed) -- delta=7.39
		Turn(lcalf, x_axis, math.rad(-34.320789), math.rad(2236.471678) / animSpeed) -- delta=74.55
		Turn(lfoot, x_axis, math.rad(-14.861295), math.rad(1216.447590) / animSpeed) -- delta=-40.55
		Turn(lthigh, x_axis, math.rad(37.699383), math.rad(451.412325) / animSpeed) -- delta=15.05
		Move(pelvis, y_axis, -4.148935, 124.468060 / animSpeed) -- delta=-4.15
		Turn(rcalf, x_axis, math.rad(-18.327028), math.rad(1227.152426) / animSpeed) -- delta=40.91
		Turn(rfoot, x_axis, math.rad(15.272470), math.rad(313.902739) / animSpeed) -- delta=10.46
		Turn(rthigh, x_axis, math.rad(2.429312), math.rad(1536.706048) / animSpeed) -- delta=-51.22
		Sleep((33 * animSpeed) -1)
		-- Frame:32
		Move(base, y_axis, -2.137330, 60.348151 / animSpeed) -- delta=2.01
		Move(base, z_axis, 2.011605, 45.261118 / animSpeed) -- delta=-1.51
		Turn(box, x_axis, math.rad(-0.000000), math.rad(336.675495) / animSpeed) -- delta=11.22
		Turn(box, z_axis, math.rad(-2.568975), math.rad(113.731102) / animSpeed) -- delta=-3.79
		Turn(box, y_axis, math.rad(0.000000), math.rad(143.999996) / animSpeed) -- delta=4.80
		Turn(lcalf, x_axis, math.rad(-17.008144), math.rad(519.379332) / animSpeed) -- delta=-17.31
		Turn(lfoot, x_axis, math.rad(12.754232), math.rad(828.465789) / animSpeed) -- delta=-27.62
		Turn(lthigh, x_axis, math.rad(-42.326812), math.rad(2400.785846) / animSpeed) -- delta=80.03
		Move(pelvis, y_axis, -2.137330, 60.348151 / animSpeed) -- delta=2.01
		Turn(rcalf, x_axis, math.rad(-7.280399), math.rad(331.398866) / animSpeed) -- delta=-11.05
		Turn(rfoot, x_axis, math.rad(-26.984933), math.rad(1267.722110) / animSpeed) -- delta=42.26
		Turn(rthigh, x_axis, math.rad(33.463976), math.rad(931.039899) / animSpeed) -- delta=-31.03
		Sleep((33 * animSpeed) -1)
		-- Frame:36
		Move(base, y_axis, 0.000000, 64.119909 / animSpeed) -- delta=2.14
		Move(base, z_axis, 0.000000, 60.348151 / animSpeed) -- delta=-2.01
		Turn(box, y_axis, math.rad(7.341211), math.rad(220.236323) / animSpeed) -- delta=7.34
		Turn(lcalf, x_axis, math.rad(-1.514041), math.rad(464.823110) / animSpeed) -- delta=-15.49
		Turn(lfoot, x_axis, math.rad(59.743439), math.rad(1409.676229) / animSpeed) -- delta=-46.99
		Turn(lthigh, x_axis, math.rad(-100.054410), math.rad(1731.827932) / animSpeed) -- delta=57.73
		Turn(lthigh, z_axis, math.rad(0.336249), math.rad(10.411593) / animSpeed) -- delta=-0.35
		Turn(lthigh, y_axis, math.rad(0.314874), math.rad(9.984645) / animSpeed) -- delta=0.33
		Move(pelvis, y_axis, 0.000000, 64.119909 / animSpeed) -- delta=2.14
		Turn(rcalf, x_axis, math.rad(31.534813), math.rad(1164.456361) / animSpeed) -- delta=-38.82
		Turn(rfoot, x_axis, math.rad(-65.948400), math.rad(1168.903992) / animSpeed) -- delta=38.96
		Turn(rthigh, x_axis, math.rad(38.577568), math.rad(153.407756) / animSpeed) -- delta=-5.11
		Sleep((33 * animSpeed) -1)
	end
end

local function StopWalking()
	Signal(SIG_WALK)
	SetSignalMask(SIG_WALK)
	animSpeed = 10; -- tune restore speed here, higher values are slower restore speeds	
	Move(base, y_axis, 0, 311.170149 / animSpeed)
	Move(base, z_axis, 0, 301.740754 / animSpeed)
	Move(pelvis, y_axis, 0, 311.170149 / animSpeed)
	Move(rfoot, y_axis, 0, 100.174990 / animSpeed)
	Move(rfoot, z_axis, 0, 70.951353 / animSpeed)
	Turn(box, x_axis, 0, math.rad(902.129385) / animSpeed)
	Turn(box, y_axis, 0, math.rad(757.735968) / animSpeed)
	Turn(box, z_axis, 0, math.rad(612.770710) / animSpeed)
	Turn(lcalf, x_axis, 0, math.rad(5591.179194) / animSpeed)
	Turn(lfoot, x_axis, 0, math.rad(4480.757946) / animSpeed)
	Turn(lfoot, y_axis, 0, math.rad(8.118736) / animSpeed)
	Turn(lthigh, x_axis, 0, math.rad(7504.080734) / animSpeed)
	Turn(lthigh, y_axis, 0, math.rad(24.961612) / animSpeed)
	Turn(lthigh, z_axis, 0, math.rad(26.028982) / animSpeed)
	Turn(rcalf, x_axis, 0, math.rad(5791.101947) / animSpeed)
	Turn(rfoot, x_axis, 0, math.rad(4638.333857) / animSpeed)
	Turn(rthigh, x_axis, 0, math.rad(4036.535313) / animSpeed)
end

local walking = false
function script.StartMoving()
	if not walking then
		walking = true
		StartThread(Walk)
	end
end

function script.StopMoving()
	walking = false
	StartThread(StopWalking)
end

-----------------------------
-- Weapon

function script.AimFromWeapon()
	return pelvis
end

function script.QueryWeapon()
	return pelvis
end

local function RestoreAfterDelay()
	Signal(SIG_RESTORE)
	SetSignalMask(SIG_RESTORE)
	Sleep(1000)
	Turn(aimyaw, y_axis, 0, math.rad(135))
	Turn(aimpitch, x_axis, 0, math.rad(85))
end

function script.AimWeapon(num, heading, pitch)
	StartThread(RestoreAfterDelay)
	Signal(SIG_AIM)
	SetSignalMask(SIG_AIM)
	Turn(aimyaw, y_axis, heading, math.rad(360)) -- left-right
	Turn(aimpitch, x_axis, -pitch, math.rad(270)) --up-down
	WaitForTurn(aimyaw, y_axis)
	WaitForTurn(aimpitch, x_axis)
	gunHeading = heading
	return true
end

function script.FireWeapon(num)
	Turn(pole, x_axis, math.rad(90), math.rad(40000))
	Turn(box, x_axis, -math.rad(50), math.rad(40000))
	Move(box, y_axis, 15, 300)
	Sleep(30)
	Turn(pole, x_axis, math.rad(0), math.rad(80))
	Turn(box, x_axis, math.rad(0), math.rad(40))
	Move(box, y_axis, 0, 10)
end


-----------------------------
-- Death

function Detonate() -- Giving an order causes recursion.
	GG.QueueUnitDescruction(unitID)
end

function script.Killed(recentDamage, maxHealth)
	Explode(box, SFX.SHATTER + SFX.SMOKE)
	
	local severity = recentDamage / maxHealth
	if (severity <= 0.5) then
		return 1 -- corpsetype
	else
		return 2 -- corpsetype
	end
end
