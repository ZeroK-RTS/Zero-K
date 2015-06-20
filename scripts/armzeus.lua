local base = piece 'base' 
local chest = piece 'chest' 
local aim = piece 'aim' 
local flare = piece 'flare' 
local hips = piece 'hips' 
local lthigh = piece 'lthigh' 
local rthigh = piece 'rthigh' 
local lforearm = piece 'lforearm' 
local rforearm = piece 'rforearm' 
local rshoulder = piece 'rshoulder' 
local lshoulder = piece 'lshoulder' 
local rshin = piece 'rshin' 
local rfoot = piece 'rfoot' 
local lshin = piece 'lshin' 
local lfoot = piece 'lfoot' 
--linear constant=65536

include "constants.lua"

local smokePiece = {chest}

local aiming = false
local walking = false

-- Signal definitions
local SIG_MOVE = 1
local SIG_RESTORE = 2
local SIG_AIM = 4
local SIG_STOPMOVE = 8

local RESTORE_DELAY = 3000


local function walk()
	
	Signal(SIG_MOVE)
	SetSignalMask(SIG_MOVE)

	while true do
		Move(hips, y_axis, 0.000000)
		Move(hips, y_axis, -0.169989, 3.000000)
		Move(lthigh, y_axis, 0.000000)
		Move(lthigh, y_axis, 0.169989, 3.000000)
		Move(rthigh, y_axis, 0.400000)
		Move(rthigh, y_axis, 0.319989, 1.000000)
		Turn(hips, x_axis, math.rad(7.027473))
		Turn(hips, x_axis, math.rad(9.000000), math.rad(50.000000))
		Turn(lthigh, x_axis, math.rad(17.923077))
		Turn(lthigh, x_axis, math.rad(20.000000), math.rad(46.000000))
		Turn(rthigh, x_axis, math.rad(-37.967033))
		Turn(rthigh, x_axis, math.rad(-33.005495), math.rad(82.000000))
		Turn(rshin, x_axis, math.rad(17.214286))
		Turn(rshin, x_axis, math.rad(13.000000), math.rad(78.000000))
		Turn(rfoot, x_axis, math.rad(-22.505495))
		Turn(rfoot, x_axis, math.rad(-13.000000), math.rad(175.000000))
		Turn(lshin, x_axis, 0)
		Turn(lshin, x_axis, math.rad(10.000000), math.rad(215.000000))
		Turn(lfoot, x_axis, math.rad(-16.868132))
		Turn(lfoot, x_axis, math.rad(-10.000000), math.rad(136.000000))
		
		if not aiming then
			Move(chest, y_axis, 0.000000)
			Move(chest, y_axis, -0.119989, 2.000000)
			Turn(chest, y_axis, math.rad(-9.137363))
			Turn(chest, y_axis, math.rad(-7.000000), math.rad(35.000000))
		end
		
		Sleep(49)

		Move(hips, y_axis, -0.350000, 3.000000)
		Move(lthigh, y_axis, 0.350000, 3.000000)
		Move(rthigh, y_axis, 0.250000, 1.000000)
		Turn(hips, x_axis, math.rad(11.000000), math.rad(50.000000))
		Turn(lthigh, x_axis, math.rad(22.000000), math.rad(46.000000))
		Turn(rthigh, x_axis, math.rad(-29.005495), math.rad(82.000000))
		Turn(rshin, x_axis, math.rad(9.000000), math.rad(78.000000))
		Turn(rfoot, x_axis, math.rad(8.000000), math.rad(462.000000))
		Turn(lshin, x_axis, math.rad(21.000000), math.rad(215.000000))
		Turn(lfoot, x_axis, math.rad(-3.000000), math.rad(136.000000))
		
		if not aiming then
			Move(chest, y_axis, -0.239990, 2.000000)
			Turn(chest, y_axis, math.rad(-5.000000), math.rad(35.000000))
		end
		
		Sleep(49)
	
		Move(hips, y_axis, -0.169989, 4.000000)
		Move(lthigh, y_axis, 0.369989, 0.000000)
		Move(rthigh, y_axis, 0.119989, 2.000000)
		Turn(hips, x_axis, math.rad(9.000000), math.rad(62.000000))
		Turn(lthigh, x_axis, math.rad(7.000000), math.rad(351.000000))
		Turn(rthigh, x_axis, math.rad(-20.000000), math.rad(221.000000))
		Turn(rshin, x_axis, math.rad(7.000000), math.rad(54.000000))
		Turn(rfoot, x_axis, math.rad(4.000000), math.rad(104.000000))
		Turn(lshin, x_axis, math.rad(27.005495), math.rad(163.000000))
		Turn(lfoot, x_axis, math.rad(-10.000000), math.rad(163.000000))
		
		if not aiming then
			Move(chest, y_axis, 0.500000, 7.000000)
			Turn(chest, y_axis, math.rad(-3.000000), math.rad(46.000000))
		end
		
		Sleep(42)
		
		Move(hips, y_axis, 0.000000, 3.000000)
		Move(lthigh, y_axis, 0.400000, 0.000000)
		Move(rthigh, y_axis, 0.000000, 2.000000)
		Turn(hips, x_axis, math.rad(6.000000), math.rad(58.000000))
		Turn(lthigh, x_axis, math.rad(-7.000000), math.rad(328.000000))
		Turn(rthigh, x_axis, math.rad(-11.000000), math.rad(207.000000))
		Turn(rshin, x_axis, math.rad(4.000000), math.rad(50.000000))
		Turn(rfoot, x_axis, 0, math.rad(97.000000))
		Turn(lshin, x_axis, math.rad(34.005495), math.rad(152.000000))
		Turn(lfoot, x_axis, math.rad(-17.000000), math.rad(152.000000))
		
		if not aiming then
			Move(chest, y_axis, 0.350000, 6.000000)
			Turn(chest, y_axis, math.rad(-1.000000), math.rad(42.000000))
		end
		
		Sleep(45)
	
		Move(lthigh, y_axis, 0.700000, 4.000000)
		Turn(hips, x_axis, math.rad(5.000000), math.rad(22.000000))
		Turn(lthigh, x_axis, math.rad(-13.000000), math.rad(91.000000))
		Turn(rthigh, x_axis, 0, math.rad(165.000000))
		Turn(rfoot, x_axis, math.rad(-8.000000), math.rad(113.000000))
		Turn(lshin, x_axis, math.rad(23.005495), math.rad(158.000000))
		Turn(lfoot, x_axis, math.rad(-12.000000), math.rad(69.000000))
		
		if not aiming then
			Move(chest, y_axis, 0.169989, 2.000000)
			Turn(chest, y_axis, math.rad(2.000000), math.rad(54.000000))
		end
		
		Sleep(71)
	
		Move(lthigh, y_axis, 1.000000, 4.000000)
		Turn(hips, x_axis, math.rad(3.000000), math.rad(21.000000))
		Turn(lthigh, x_axis, math.rad(-20.000000), math.rad(90.000000))
		Turn(rthigh, x_axis, math.rad(12.000000), math.rad(163.000000))
		Turn(rfoot, x_axis, math.rad(-16.000000), math.rad(112.000000))
		Turn(lshin, x_axis, math.rad(12.000000), math.rad(156.000000))
		Turn(lfoot, x_axis, math.rad(-7.000000), math.rad(68.000000))
		
		if not aiming then
			Move(chest, y_axis, 0.000000, 2.000000)
			Turn(chest, y_axis, math.rad(5.000000), math.rad(53.000000))
		end
		
		Sleep(72)
	
		Move(lthigh, y_axis, 0.700000, 3.000000)
		Turn(hips, x_axis, math.rad(5.000000), math.rad(18.000000))
		Turn(lthigh, x_axis, math.rad(-28.005495), math.rad(92.000000))
		Turn(rthigh, x_axis, math.rad(14.000000), math.rad(26.000000))
		Turn(rshin, x_axis, math.rad(2.000000), math.rad(26.000000))
		Turn(rfoot, x_axis, math.rad(-16.000000), 0)
		Turn(lshin, x_axis, math.rad(14.000000), math.rad(26.000000))
		Turn(lfoot, x_axis, math.rad(-16.000000), math.rad(100.000000))
		
		if not aiming then
			Turn(chest, y_axis, math.rad(7.000000), math.rad(18.000000))
		end
		
		Sleep(93)
	
		Move(lthigh, y_axis, 0.400000, 3.000000)
		Turn(hips, x_axis, math.rad(7.000000), math.rad(18.000000))
		Turn(lthigh, x_axis, math.rad(-37.005495), math.rad(90.000000))
		Turn(rthigh, x_axis, math.rad(17.000000), math.rad(25.000000))
		Turn(rshin, x_axis, 0, math.rad(25.000000))
		Turn(rfoot, x_axis, math.rad(-16.000000), 0)
		Turn(lshin, x_axis, math.rad(17.000000), math.rad(25.000000))
		Turn(lfoot, x_axis, math.rad(-26.005495), math.rad(98.000000))
		
		if not aiming then
			Turn(chest, y_axis, math.rad(9.000000), math.rad(18.000000))
		end
		
		Sleep(95)
	
		Move(hips, y_axis, -0.169989, 3.000000)
		Move(lthigh, y_axis, 0.319989, 1.000000)
		Move(rthigh, y_axis, 0.169989, 3.000000)
		Turn(hips, x_axis, math.rad(9.000000), math.rad(50.000000))
		Turn(lthigh, x_axis, math.rad(-33.005495), math.rad(78.000000))
		Turn(rthigh, x_axis, math.rad(19.000000), math.rad(53.000000))
		Turn(rshin, x_axis, math.rad(10.000000), math.rad(218.000000))
		Turn(rfoot, x_axis, math.rad(-8.000000), math.rad(161.000000))
		Turn(lshin, x_axis, math.rad(13.000000), math.rad(78.000000))
		Turn(lfoot, x_axis, math.rad(-9.000000), math.rad(344.000000))
		
		if not aiming then
			Move(chest, y_axis, -0.119989, 2.000000)
			Turn(chest, y_axis, math.rad(7.000000), math.rad(39.000000))
		end
		
		Sleep(49)

		Move(hips, y_axis, -0.350000, 3.000000)
		Move(lthigh, y_axis, 0.250000, 1.000000)
		Move(rthigh, y_axis, 0.350000, 3.000000)
		Turn(hips, x_axis, math.rad(11.000000), math.rad(50.000000))
		Turn(lthigh, x_axis, math.rad(-29.005495), math.rad(78.000000))
		Turn(rthigh, x_axis, math.rad(22.000000), math.rad(53.000000))
		Turn(rshin, x_axis, math.rad(21.000000), math.rad(218.000000))
		Turn(rfoot, x_axis, 0, math.rad(161.000000))
		Turn(lshin, x_axis, math.rad(9.000000), math.rad(78.000000))
		Turn(lfoot, x_axis, math.rad(7.000000), math.rad(344.000000))
		
		if not aiming then
			Move(chest, y_axis, -0.239990, 2.000000)
			Turn(chest, y_axis, math.rad(5.000000), math.rad(39.000000))
		end
		
		Sleep(49)
	
		Move(hips, y_axis, -0.169989, 3.000000)
		Move(lthigh, y_axis, 0.119989, 2.000000)
		Move(rthigh, y_axis, 0.369989, 0.000000)
		Turn(hips, x_axis, math.rad(9.000000), math.rad(56.000000))
		Turn(lthigh, x_axis, math.rad(-20.000000), math.rad(194.000000))
		Turn(rthigh, x_axis, math.rad(7.000000), math.rad(314.000000))
		Turn(rshin, x_axis, math.rad(36.005495), math.rad(329.000000))
		Turn(rfoot, x_axis, math.rad(-5.000000), math.rad(104.000000))
		Turn(lshin, x_axis, math.rad(7.000000), math.rad(52.000000))
		Turn(lfoot, x_axis, math.rad(3.000000), math.rad(82.000000))
		
		if not aiming then
			Move(chest, y_axis, 0.500000, 6.000000)
			Turn(chest, y_axis, math.rad(3.000000), math.rad(37.000000))
		end
		
		Sleep(47)

		Move(hips, y_axis, 0.000000, 3.000000)
		Move(lthigh, y_axis, 0.000000, 2.000000)
		Move(rthigh, y_axis, 0.400000, 0.000000)
		Turn(hips, x_axis, math.rad(6.000000), math.rad(54.000000))
		Turn(lthigh, x_axis, math.rad(-11.000000), math.rad(190.000000))
		Turn(rthigh, x_axis, math.rad(-7.000000), math.rad(307.000000))
		Turn(rshin, x_axis, math.rad(52.005495), math.rad(322.000000))
		Turn(rfoot, x_axis, math.rad(-10.000000), math.rad(102.000000))
		Turn(lshin, x_axis, math.rad(4.000000), math.rad(51.000000))
		Turn(lfoot, x_axis, 0, math.rad(80.000000))
		
		if not aiming then
			Move(chest, y_axis, 0.350000, 6.000000)
			Turn(chest, y_axis, math.rad(2.000000), math.rad(36.000000))
		end
		
		Sleep(48)

		Move(lthigh, y_axis, 0.000000, 0.000000)
		Move(rthigh, y_axis, 0.700000, 4.000000)
		Turn(hips, x_axis, math.rad(5.000000), math.rad(21.000000))
		Turn(lthigh, x_axis, 0, math.rad(161.000000))
		Turn(rthigh, x_axis, math.rad(-13.000000), math.rad(90.000000))
		Turn(rshin, x_axis, math.rad(39.005495), math.rad(180.000000))
		Turn(rfoot, x_axis, math.rad(-7.000000), math.rad(40.000000))
		Turn(lshin, x_axis, math.rad(4.000000), math.rad(2.000000))
		Turn(lfoot, x_axis, math.rad(-8.000000), math.rad(109.000000))
		
		if not aiming then
			Move(chest, y_axis, 0.169989, 2.000000)
			Turn(chest, y_axis, math.rad(-1.000000), math.rad(52.000000))
		end
		
		Sleep(74)
	
		Move(lthigh, y_axis, 0.000000, 0.000000)
		Move(rthigh, y_axis, 1.000000, 3.000000)
		Turn(hips, x_axis, math.rad(3.000000), math.rad(20.000000))
		Turn(lthigh, x_axis, math.rad(12.000000), math.rad(157.000000))
		Turn(rthigh, x_axis, math.rad(-20.000000), math.rad(87.000000))
		Turn(rshin, x_axis, math.rad(25.005495), math.rad(175.000000))
		Turn(rfoot, x_axis, math.rad(-4.000000), math.rad(39.000000))
		Turn(lshin, x_axis, math.rad(4.000000), math.rad(2.000000))
		Turn(lfoot, x_axis, math.rad(-16.000000), math.rad(106.000000))
		
		if not aiming then
			Move(chest, y_axis, 0.000000, 2.000000)
			Turn(chest, y_axis, math.rad(-5.000000), math.rad(50.000000))
		end
		
		Sleep(76)

		Move(lthigh, y_axis, 0.000000, 0.000000)
		Move(rthigh, y_axis, 0.700000, 3.000000)
		Turn(hips, x_axis, math.rad(5.000000), math.rad(18.000000))
		Turn(lthigh, x_axis, math.rad(15.000000), math.rad(28.000000))
		Turn(rthigh, x_axis, math.rad(-29.005495), math.rad(93.000000))
		Turn(chest, y_axis, math.rad(-7.000000), math.rad(18.000000))
		Turn(rshin, x_axis, math.rad(21.000000), math.rad(44.000000))
		Turn(rfoot, x_axis, math.rad(-12.000000), math.rad(86.000000))
		Turn(lshin, x_axis, math.rad(2.000000), math.rad(22.000000))
		Turn(lfoot, x_axis, math.rad(-16.000000), math.rad(3.000000))
		Sleep(94)
	end

end

function script.Create()
	StartThread(SmokeUnit, smokePiece)
end

function script.StartMoving()
	Signal(SIG_STOPMOVE)
	if walking == false then

		walking = true
		StartThread(walk)
	end
end

local function StopMovingThread()
	
	Signal(SIG_STOPMOVE)
	SetSignalMask(SIG_STOPMOVE)
	Sleep(33)
	
	walking = false
	Signal(SIG_MOVE)

	Turn(rthigh, x_axis, 0, math.rad(400.000000))
	Turn(rshin, x_axis, 0, math.rad(400.000000))
	Turn(rfoot, x_axis, 0, math.rad(400.000000))
	Turn(lthigh, x_axis, 0, math.rad(400.000000))
	Turn(lshin, x_axis, 0, math.rad(400.000000))
	Turn(lfoot, x_axis, 0, math.rad(400.000000))
	
	if not aiming then
		Turn(chest, y_axis, 0, math.rad(180.000000))
		Turn(rshoulder, x_axis, 0, math.rad(400.000000))
		Turn(rforearm, x_axis, 0, math.rad(400.000000))
		Turn(lshoulder, x_axis, 0, math.rad(400.000000))
		Turn(lforearm, x_axis, 0, math.rad(400.000000))
	end
end

function script.StopMoving()
	StartThread(StopMovingThread)
end

local function RestoreAfterDelay()
	Signal(SIG_RESTORE)
	SetSignalMask(SIG_RESTORE)
	
	Sleep(RESTORE_DELAY)
	Turn(chest, y_axis, 0, math.rad(90))
	Turn(chest, x_axis, 0, math.rad(45))
	WaitForTurn(chest, y_axis)
	WaitForTurn(chest, x_axis)
	aiming = false
end

function script.AimFromWeapon()
	return aim
end

function script.QueryWeapon()
	return flare
end

function script.FireWeapon()
	EmitSfx(flare,  UNIT_SFX1)
	EmitSfx(flare,  UNIT_SFX1)
end

function script.AimWeapon(num, heading, pitch)

	Signal(SIG_AIM)
	SetSignalMask(SIG_AIM)
	StartThread(RestoreAfterDelay)
	aiming = true
	
	Turn(chest, y_axis, heading, math.rad(150))
	Turn(chest, x_axis, -pitch-0.08, math.rad(60))
	WaitForTurn(chest, y_axis)
	WaitForTurn(chest, x_axis)
	return true
end

function script.Killed(recentDamage, maxHealth)
	local severity = recentDamage / maxHealth
	if (severity <= .25) then
		Explode(lfoot, sfxNone)
		Explode(lshin, sfxNone)
		Explode(lshoulder, sfxNone)
		Explode(lthigh, sfxNone)
		Explode(lforearm, sfxNone)
		Explode(rfoot, sfxNone)
		Explode(rshin, sfxNone)
		Explode(rshoulder, sfxNone)
		Explode(rthigh, sfxNone)
		Explode(rforearm, sfxNone)
		Explode(chest, sfxNone)
		return 1 -- corpsetype
	elseif (severity <= .5) then
		Explode(lfoot, sfxFall)
		Explode(lshin, sfxFall)
		Explode(lshoulder, sfxFall)
		Explode(lthigh, sfxFall)
		Explode(lforearm, sfxFall)
		Explode(rfoot, sfxFall)
		Explode(rshin, sfxFall)
		Explode(rshoulder, sfxFall)
		Explode(rthigh, sfxFall)
		Explode(rforearm, sfxFall)
		Explode(chest, sfxShatter)
		return 1 -- corpsetype
	elseif (severity <= 1) then
		Explode(lfoot, sfxFall, sfxSmoke, sfxFire, sfxExplodeOnHit)
		Explode(lshin, sfxFall, sfxSmoke, sfxFire, sfxExplodeOnHit)
		Explode(lshoulder, sfxFall, sfxSmoke, sfxFire, sfxExplodeOnHit)
		Explode(lthigh, sfxFall, sfxSmoke, sfxFire, sfxExplodeOnHit)
		Explode(lforearm, sfxFall, sfxSmoke, sfxFire, sfxExplodeOnHit)
		Explode(rfoot, sfxFall, sfxSmoke, sfxFire, sfxExplodeOnHit)
		Explode(rshin, sfxFall, sfxSmoke, sfxFire, sfxExplodeOnHit)
		Explode(rshoulder, sfxFall, sfxSmoke, sfxFire, sfxExplodeOnHit)
		Explode(rthigh, sfxFall, sfxSmoke, sfxFire, sfxExplodeOnHit)
		Explode(rforearm, sfxFall, sfxSmoke, sfxFire, sfxExplodeOnHit)
		Explode(chest, sfxShatter)
		return 2
	end
	Explode(lfoot, sfxFall, sfxSmoke, sfxFire, sfxExplodeOnHit)
	Explode(lshin, sfxFall, sfxSmoke, sfxFire, sfxExplodeOnHit)
	Explode(lshoulder, sfxFall, sfxSmoke, sfxFire, sfxExplodeOnHit)
	Explode(lthigh, sfxFall, sfxSmoke, sfxFire, sfxExplodeOnHit)
	Explode(lforearm, sfxFall, sfxSmoke, sfxFire, sfxExplodeOnHit)
	Explode(rfoot, sfxFall, sfxSmoke, sfxFire, sfxExplodeOnHit)
	Explode(rshin, sfxFall, sfxSmoke, sfxFire, sfxExplodeOnHit)
	Explode(rshoulder, sfxFall, sfxSmoke, sfxFire, sfxExplodeOnHit)
	Explode(rthigh, sfxFall, sfxSmoke, sfxFire, sfxExplodeOnHit)
	Explode(rforearm, sfxFall, sfxSmoke, sfxFire, sfxExplodeOnHit)
	Explode(chest, sfxShatter, sfxExplodeOnHit)
	return 2
end
