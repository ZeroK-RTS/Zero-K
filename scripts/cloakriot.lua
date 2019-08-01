
include "constants.lua"

local chest = piece 'chest' 
local rflare = piece 'rflare' 
local lflare = piece 'lflare' 
local hips = piece 'hips' 
local lthigh = piece 'lthigh' 
local rthigh = piece 'rthigh' 
local head = piece 'head' 
local lforearm = piece 'lforearm' 
local rforearm = piece 'rforearm' 
local rshoulder = piece 'rshoulder' 
local lshoulder = piece 'lshoulder' 
local rshin = piece 'rshin' 
local rfoot = piece 'rfoot' 
local lshin = piece 'lshin' 
local lfoot = piece 'lfoot' 
local lgun = piece 'lgun' 
local lejector = piece 'lejector' 
local rejector = piece 'rejector' 
local rgun = piece 'rgun' 
local lbelt = piece 'lbelt' 
local rbelt = piece 'rbelt' 

local gunBelts = {
	{
		main = rbelt,
		other = lbelt,
	},
	{
		main = lbelt,
		other = rbelt,
	},
}

local gunFlares = {rflare, lflare}
local gun = 1
local aiming = false

-- Signal definitions
local SIG_WALK = 1
local SIG_RESTORE = 2
local SIG_AIM = 4

local RESTORE_DELAY = 3000

-- future-proof running animation against balance tweaks
local PACE = 1.8 * (UnitDefs[unitDefID].speed / 51)

local function Walk()
	Signal(SIG_WALK)
	SetSignalMask(SIG_WALK)
	
	Move(hips, y_axis, 0)
	Move(lthigh, y_axis, 0)
	Move(rthigh, y_axis, 0.40)
	Turn(hips, x_axis, math.rad(7.027473))
	Turn(lthigh, x_axis, math.rad(17.923077))
	Turn(rthigh, x_axis, math.rad(-37.967033))
	Turn(rshin, x_axis, math.rad(17.214286))
	Turn(rfoot, x_axis, math.rad(-22.505495))
	Turn(lshin, x_axis, 0)
	Turn(lfoot, x_axis, math.rad(-16.868132))
	if not aiming then
		Move(chest, y_axis, 0)
		Turn(chest, y_axis, math.rad(-9.137363))
		Turn(head, y_axis, math.rad(9.835165))
	end
	
	while true do
	
		speedMult = (Spring.GetUnitRulesParam(unitID,"totalMoveSpeedChange") or 1)*PACE
		while speedMult <= 0 do
			speedMult = (Spring.GetUnitRulesParam(unitID,"totalMoveSpeedChange") or 1)*PACE
			Sleep(500)
		end
	
		Move(hips, y_axis, 2.5, 4 * speedMult)
		Move(lthigh, y_axis, 0.169989, 3 * speedMult)
		Move(rthigh, y_axis, 0.319989, 1 * speedMult)
		Turn(hips, x_axis, math.rad(9), math.rad(50) * speedMult)
		Turn(lthigh, x_axis, math.rad(20), math.rad(46) * speedMult)
		Turn(rthigh, x_axis, math.rad(-33.005495), math.rad(82) * speedMult)
		Turn(rshin, x_axis, math.rad(13), math.rad(78) * speedMult)
		Turn(rfoot, x_axis, math.rad(-13), math.rad(175) * speedMult)
		Turn(lshin, x_axis, math.rad(10), math.rad(215) * speedMult)
		Turn(lfoot, x_axis, math.rad(-10), math.rad(136) * speedMult)
		if not aiming then
			Move(chest, y_axis, -0.119989, 2 * speedMult)
			Turn(chest, y_axis, math.rad(-7), math.rad(35) * speedMult)
			Turn(head, y_axis, math.rad(7), math.rad(43) * speedMult)
		end
		Sleep(49 / speedMult)
	
		Move(hips, y_axis, 2.5, 1 * speedMult)
		Move(lthigh, y_axis, 0.35, 3 * speedMult)
		Move(rthigh, y_axis, 0.25, 1 * speedMult)
		Turn(hips, x_axis, math.rad(11), math.rad(50) * speedMult)
		Turn(lthigh, x_axis, math.rad(22), math.rad(46) * speedMult)
		Turn(rthigh, x_axis, math.rad(-29.005495), math.rad(82) * speedMult)
		Turn(rshin, x_axis, math.rad(9), math.rad(78) * speedMult)
		Turn(rfoot, x_axis, math.rad(8), math.rad(462) * speedMult)
		Turn(lshin, x_axis, math.rad(21), math.rad(215) * speedMult)
		Turn(lfoot, x_axis, math.rad(-3), math.rad(136) * speedMult)
		if not aiming then
			Move(chest, y_axis, -0.239990, 2 * speedMult)
			Turn(chest, y_axis, math.rad(-5), math.rad(35) * speedMult)
			Turn(head, y_axis, math.rad(5), math.rad(43) * speedMult)
		end
		Sleep(49 / speedMult)
	
		Move(hips, y_axis, -0.5, 1 * speedMult)
		Move(lthigh, y_axis, 0.369989, 0 * speedMult)
		Move(rthigh, y_axis, 0.119989, 2 * speedMult)
		Turn(hips, x_axis, math.rad(9), math.rad(62) * speedMult)
		Turn(lthigh, x_axis, math.rad(7), math.rad(351) * speedMult)
		Turn(rthigh, x_axis, math.rad(-20), math.rad(221) * speedMult)
		Turn(rshin, x_axis, math.rad(7), math.rad(54) * speedMult)
		Turn(rfoot, x_axis, math.rad(4), math.rad(104) * speedMult)
		Turn(lshin, x_axis, math.rad(27.005495), math.rad(163) * speedMult)
		Turn(lfoot, x_axis, math.rad(-10), math.rad(163) * speedMult)
		if not aiming then
			Move(chest, y_axis, 0.50, 7 * speedMult)
			Turn(chest, y_axis, math.rad(-3), math.rad(46) * speedMult)
			Turn(head, y_axis, math.rad(3), math.rad(54) * speedMult)
		end
		Sleep(42 / speedMult)
	
		Move(hips, y_axis, -0.5, 2 * speedMult)
		Move(lthigh, y_axis, 0.40, 0 * speedMult)
		Move(rthigh, y_axis, 0, 2 * speedMult)
		Turn(hips, x_axis, math.rad(6), math.rad(58) * speedMult)
		Turn(lthigh, x_axis, math.rad(-7), math.rad(328) * speedMult)
		Turn(rthigh, x_axis, math.rad(-11), math.rad(207) * speedMult)
		Turn(rshin, x_axis, math.rad(4), math.rad(50) * speedMult)
		Turn(rfoot, x_axis, 0, math.rad(97) * speedMult)
		Turn(lshin, x_axis, math.rad(34.005495), math.rad(152) * speedMult)
		Turn(lfoot, x_axis, math.rad(-17), math.rad(152) * speedMult)
		if not aiming then
			Move(chest, y_axis, 0.35, 6 * speedMult)
			Turn(chest, y_axis, math.rad(-1), math.rad(42) * speedMult)
			Turn(head, y_axis, math.rad(1), math.rad(50) * speedMult)
		end
		Sleep(45 / speedMult)
	
		Move(lthigh, y_axis, 0.70, 4 * speedMult)
		Turn(hips, x_axis, math.rad(5), math.rad(22) * speedMult)
		Turn(lthigh, x_axis, math.rad(-13), math.rad(91) * speedMult)
		Turn(rthigh, x_axis, 0, math.rad(165) * speedMult)
		Turn(rfoot, x_axis, math.rad(-8), math.rad(113) * speedMult)
		Turn(lshin, x_axis, math.rad(23.005495), math.rad(158) * speedMult)
		Turn(lfoot, x_axis, math.rad(-12), math.rad(69) * speedMult)
		if not aiming then
			Move(chest, y_axis, 0.169989, 2 * speedMult)
			Turn(chest, y_axis, math.rad(2), math.rad(54) * speedMult)
			Turn(head, y_axis, math.rad(-2), math.rad(44) * speedMult)
		end
		Sleep(71 / speedMult)
	
		Move(lthigh, y_axis, 1, 4 * speedMult)
		Turn(hips, x_axis, math.rad(3), math.rad(21) * speedMult)
		Turn(lthigh, x_axis, math.rad(-20), math.rad(90) * speedMult)
		Turn(rthigh, x_axis, math.rad(12), math.rad(163) * speedMult)
		Turn(rfoot, x_axis, math.rad(-16), math.rad(112) * speedMult)
		Turn(lshin, x_axis, math.rad(12), math.rad(156) * speedMult)
		Turn(lfoot, x_axis, math.rad(-7), math.rad(68) * speedMult)
		if not aiming then
			Move(chest, y_axis, 0, 2 * speedMult)
			Turn(chest, y_axis, math.rad(5), math.rad(53) * speedMult)
			Turn(head, y_axis, math.rad(-5), math.rad(43) * speedMult)
		end
		Sleep(72 / speedMult)
	
		Move(lthigh, y_axis, 0.70, 3 * speedMult)
		Turn(hips, x_axis, math.rad(5), math.rad(18) * speedMult)
		Turn(lthigh, x_axis, math.rad(-28.005495), math.rad(92) * speedMult)
		Turn(rthigh, x_axis, math.rad(14), math.rad(26) * speedMult)
		Turn(rshin, x_axis, math.rad(2), math.rad(26) * speedMult)
		Turn(rfoot, x_axis, math.rad(-16), 0 * speedMult)
		Turn(lshin, x_axis, math.rad(14), math.rad(26) * speedMult)
		Turn(lfoot, x_axis, math.rad(-16), math.rad(100) * speedMult)
		if not aiming then
			Turn(chest, y_axis, math.rad(7), math.rad(18) * speedMult)
			Turn(head, y_axis, math.rad(-7), math.rad(22) * speedMult)
		end
		Sleep(93 / speedMult)
	
		Move(lthigh, y_axis, 0.40, 3 * speedMult)
		Turn(hips, x_axis, math.rad(7), math.rad(18) * speedMult)
		Turn(lthigh, x_axis, math.rad(-37.005495), math.rad(90) * speedMult)
		Turn(rthigh, x_axis, math.rad(17), math.rad(25) * speedMult)
		Turn(rshin, x_axis, 0, math.rad(25) * speedMult)
		Turn(rfoot, x_axis, math.rad(-16), 0 * speedMult)
		Turn(lshin, x_axis, math.rad(17), math.rad(25) * speedMult)
		Turn(lfoot, x_axis, math.rad(-26.005495), math.rad(98) * speedMult)
		if not aiming then
			Turn(chest, y_axis, math.rad(9), math.rad(18) * speedMult)
			Turn(head, y_axis, math.rad(-9), math.rad(22) * speedMult)
		end
		Sleep(95 / speedMult)
	
		Move(hips, y_axis, 2.5, 4 * speedMult)
		Move(lthigh, y_axis, 0.319989, 1 * speedMult)
		Move(rthigh, y_axis, 0.169989, 3 * speedMult)
		Turn(hips, x_axis, math.rad(9), math.rad(50) * speedMult)
		Turn(lthigh, x_axis, math.rad(-33.005495), math.rad(78) * speedMult)
		Turn(rthigh, x_axis, math.rad(19), math.rad(53) * speedMult)
		Turn(rshin, x_axis, math.rad(10), math.rad(218) * speedMult)
		Turn(rfoot, x_axis, math.rad(-8), math.rad(161) * speedMult)
		Turn(lshin, x_axis, math.rad(13), math.rad(78) * speedMult)
		Turn(lfoot, x_axis, math.rad(-9), math.rad(344) * speedMult)
		if not aiming then
			Move(chest, y_axis, -0.119989, 2 * speedMult)
			Turn(chest, y_axis, math.rad(7), math.rad(39) * speedMult)
			Turn(head, y_axis, math.rad(-7), math.rad(35) * speedMult)
		end
		Sleep(49 / speedMult)
	
		Move(hips, y_axis, 2.5, 1 * speedMult)
		Move(lthigh, y_axis, 0.25, 1 * speedMult)
		Move(rthigh, y_axis, 0.35, 3 * speedMult)
		Turn(hips, x_axis, math.rad(11), math.rad(50) * speedMult)
		Turn(lthigh, x_axis, math.rad(-29.005495), math.rad(78) * speedMult)
		Turn(rthigh, x_axis, math.rad(22), math.rad(53) * speedMult)
		Turn(rshin, x_axis, math.rad(21), math.rad(218) * speedMult)
		Turn(rfoot, x_axis, 0, math.rad(161) * speedMult)
		Turn(lshin, x_axis, math.rad(9), math.rad(78) * speedMult)
		Turn(lfoot, x_axis, math.rad(7), math.rad(344) * speedMult)
		if not aiming then
			Move(chest, y_axis, -0.239990, 2 * speedMult)
			Turn(chest, y_axis, math.rad(5), math.rad(39) * speedMult)
			Turn(head, y_axis, math.rad(-5), math.rad(35) * speedMult)
		end
		Sleep(49 / speedMult)
	
		Move(hips, y_axis, -0.5, 1 * speedMult)
		Move(lthigh, y_axis, 0.119989, 2 * speedMult)
		Move(rthigh, y_axis, 0.369989, 0 * speedMult)
		Turn(hips, x_axis, math.rad(9), math.rad(56) * speedMult)
		Turn(lthigh, x_axis, math.rad(-20), math.rad(194) * speedMult)
		Turn(rthigh, x_axis, math.rad(7), math.rad(314) * speedMult)
		Turn(rshin, x_axis, math.rad(36.005495), math.rad(329) * speedMult)
		Turn(rfoot, x_axis, math.rad(-5), math.rad(104) * speedMult)
		Turn(lshin, x_axis, math.rad(7), math.rad(52) * speedMult)
		Turn(lfoot, x_axis, math.rad(3), math.rad(82) * speedMult)
		if not aiming then
			Move(chest, y_axis, 0.50, 6 * speedMult)
			Turn(chest, y_axis, math.rad(3), math.rad(37) * speedMult)
			Turn(head, y_axis, math.rad(-4), math.rad(41) * speedMult)
		end
		Sleep(47 / speedMult)
	
		Move(hips, y_axis, -0.5, 2 * speedMult)
		Move(lthigh, y_axis, 0, 2 * speedMult)
		Move(rthigh, y_axis, 0.40, 0 * speedMult)
		Turn(hips, x_axis, math.rad(6), math.rad(54) * speedMult)
		Turn(lthigh, x_axis, math.rad(-11), math.rad(190) * speedMult)
		Turn(rthigh, x_axis, math.rad(-7), math.rad(307) * speedMult)
		Turn(rshin, x_axis, math.rad(52.005495), math.rad(322) * speedMult)
		Turn(rfoot, x_axis, math.rad(-10), math.rad(102) * speedMult)
		Turn(lshin, x_axis, math.rad(4), math.rad(51) * speedMult)
		Turn(lfoot, x_axis, 0, math.rad(80) * speedMult)
		if not aiming then
			Move(chest, y_axis, 0.35, 6 * speedMult)
			Turn(chest, y_axis, math.rad(2), math.rad(36) * speedMult)
			Turn(head, y_axis, math.rad(-2), math.rad(40) * speedMult)
		end
		Sleep(48 / speedMult)
	
		Move(lthigh, y_axis, 0, 0 * speedMult)
		Move(rthigh, y_axis, 0.70, 4 * speedMult)
		Turn(hips, x_axis, math.rad(5), math.rad(21) * speedMult)
		Turn(lthigh, x_axis, 0, math.rad(161) * speedMult)
		Turn(rthigh, x_axis, math.rad(-13), math.rad(90) * speedMult)
		Turn(rshin, x_axis, math.rad(39.005495), math.rad(180) * speedMult)
		Turn(rfoot, x_axis, math.rad(-7), math.rad(40) * speedMult)
		Turn(lshin, x_axis, math.rad(4), math.rad(2) * speedMult)
		Turn(lfoot, x_axis, math.rad(-8), math.rad(109) * speedMult)
		if not aiming then
			Move(chest, y_axis, 0.169989, 2 * speedMult)
			Turn(chest, y_axis, math.rad(-1), math.rad(52) * speedMult)
			Turn(head, y_axis, math.rad(1), math.rad(52) * speedMult)
		end
		Sleep(74 / speedMult)
	
		Move(lthigh, y_axis, 0, 0 * speedMult)
		Move(rthigh, y_axis, 1, 3 * speedMult)
		Turn(hips, x_axis, math.rad(3), math.rad(20) * speedMult)
		Turn(lthigh, x_axis, math.rad(12), math.rad(157) * speedMult)
		Turn(rthigh, x_axis, math.rad(-20), math.rad(87) * speedMult)
		Turn(rshin, x_axis, math.rad(25.005495), math.rad(175) * speedMult)
		Turn(rfoot, x_axis, math.rad(-4), math.rad(39) * speedMult)
		Turn(lshin, x_axis, math.rad(4), math.rad(2) * speedMult)
		Turn(lfoot, x_axis, math.rad(-16), math.rad(106) * speedMult)
		if not aiming then
			Move(chest, y_axis, 0, 2 * speedMult)
			Turn(chest, y_axis, math.rad(-5), math.rad(50) * speedMult)
			Turn(head, y_axis, math.rad(5), math.rad(50) * speedMult)
		end
		Sleep(76 / speedMult)
	
		Move(lthigh, y_axis, 0, 0 * speedMult)
		Move(rthigh, y_axis, 0.70, 3 * speedMult)
		Turn(hips, x_axis, math.rad(5), math.rad(18) * speedMult)
		Turn(lthigh, x_axis, math.rad(15), math.rad(28) * speedMult)
		Turn(rthigh, x_axis, math.rad(-29.005495), math.rad(93) * speedMult)
		Turn(rshin, x_axis, math.rad(21), math.rad(44) * speedMult)
		Turn(rfoot, x_axis, math.rad(-12), math.rad(86) * speedMult)
		Turn(lshin, x_axis, math.rad(2), math.rad(22) * speedMult)
		Turn(lfoot, x_axis, math.rad(-16), math.rad(3) * speedMult)
		if not aiming then
			Turn(chest, y_axis, math.rad(-7), math.rad(18) * speedMult)
			Turn(head, y_axis, math.rad(7), math.rad(22) * speedMult)
		end
		Sleep(94 / speedMult)
	end
end

local function StopWalk()
	Signal(SIG_WALK)

	Move(hips, x_axis, 0, 10.0)
	Move(hips, y_axis, 0, 10.0)
	Turn(rthigh, x_axis, 0, math.rad(400))
	Turn(rshin, x_axis, 0, math.rad(400))
	Turn(rfoot, x_axis, 0, math.rad(400))
	Turn(lthigh, x_axis, 0, math.rad(400))
	Turn(lshin, x_axis, 0, math.rad(400))
	Turn(lfoot, x_axis, 0, math.rad(400))
	if not aiming then
		Turn(chest, y_axis, 0, math.rad(180))
		Turn(rshoulder, x_axis, 0, math.rad(400))
		Turn(rforearm, x_axis, 0, math.rad(400))
		Turn(lshoulder, x_axis, 0, math.rad(400))
		Turn(lforearm, x_axis, 0, math.rad(400))
	end
end

function script.Create()
	Hide(lejector)
	Hide(rejector)
	Hide(rflare)
	Hide(lflare)
	
	StartThread(GG.Script.SmokeUnit, {chest})
end

function script.StartMoving()
	StartThread(Walk)
end

function script.StopMoving()
	StopWalk()
end

function script.AimFromWeapon(num)
	return chest
end

function script.QueryWeapon(num)
	return gunFlares[gun]
end

function script.FireWeapon(num)
	local reloadSpeedMult = Spring.GetUnitRulesParam(unitID, "totalReloadSpeedChange") or 1
	if reloadSpeedMult and reloadSpeedMult < 0.5 then
		reloadSpeedMult = 0.5
	end
	EmitSfx(gunFlares[gun], 1024)
	EmitSfx(rejector, 1025)
	Sleep(100/reloadSpeedMult)
	EmitSfx(gunFlares[gun], 1024)
	EmitSfx(rejector, 1025)
	Sleep(100/reloadSpeedMult)
	EmitSfx(gunFlares[gun], 1024)
	EmitSfx(rejector, 1025)
	Turn(gunBelts[gun].main, x_axis, math.rad(-2), math.rad(50))
	Turn(gunBelts[gun].other, x_axis, math.rad(2), math.rad(50))
	Sleep(100/reloadSpeedMult)
	
	gun = 3 - gun
end

local function RestoreAim()
	Sleep(RESTORE_DELAY)
	Signal(SIG_RESTORE)
	SetSignalMask(SIG_RESTORE)
	
	Turn(chest, y_axis, 0, math.rad(90))
	Turn(rforearm, x_axis, 0, math.rad(45))
	Turn(rshoulder, y_axis, 0, math.rad(45))
	Turn(lforearm, x_axis, 0, math.rad(45))
	WaitForTurn(chest, y_axis)
	WaitForTurn(rforearm, x_axis)
	WaitForTurn(rshoulder, y_axis)
	WaitForTurn(lforearm, x_axis)
	
	aiming = false
end

function script.AimWeapon(num, heading, pitch)

	Signal(SIG_AIM)
	SetSignalMask(SIG_AIM)
	aiming = true

	Turn(chest, y_axis, heading, math.rad(800))
	Turn(rforearm, x_axis, -pitch, math.rad(600))
	Turn(lforearm, x_axis, -pitch, math.rad(600))
	WaitForTurn(chest, y_axis)
	WaitForTurn(lforearm, x_axis)
	WaitForTurn(rforearm, x_axis)
	StartThread(RestoreAim)
	return true
end

function script.Killed(recentDamage, maxHealth)
	local severity = recentDamage / maxHealth
	if (severity <= 0.25) then

		Explode(lgun, SFX.NONE)
		Explode(lfoot, SFX.NONE)
		Explode(lshin, SFX.NONE)
		Explode(lshoulder, SFX.NONE)
		Explode(lthigh, SFX.NONE)
		Explode(lforearm, SFX.NONE)
		Explode(rgun, SFX.NONE)
		Explode(rfoot, SFX.NONE)
		Explode(rshin, SFX.NONE)
		Explode(rshoulder, SFX.NONE)
		Explode(rthigh, SFX.NONE)
		Explode(rforearm, SFX.NONE)
		Explode(chest, SFX.NONE)
		return 1
	elseif severity <= 0.50 then
		Explode(lgun, SFX.FALL)
		Explode(lfoot, SFX.FALL)
		Explode(lshin, SFX.FALL)
		Explode(lshoulder, SFX.FALL)
		Explode(lthigh, SFX.FALL)
		Explode(lforearm, SFX.FALL)
		Explode(rgun, SFX.FALL)
		Explode(rfoot, SFX.FALL)
		Explode(rshin, SFX.FALL)
		Explode(rshoulder, SFX.FALL)
		Explode(rthigh, SFX.FALL)
		Explode(rforearm, SFX.FALL)
		Explode(chest, SFX.SHATTER)
		return 1
	end

	Explode(lgun, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE_ON_HIT)
	Explode(lfoot, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE_ON_HIT)
	Explode(lshin, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE_ON_HIT)
	Explode(lshoulder, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE_ON_HIT)
	Explode(lthigh, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE_ON_HIT)
	Explode(lforearm, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE_ON_HIT)
	Explode(rgun, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE_ON_HIT)
	Explode(rfoot, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE_ON_HIT)
	Explode(rshin, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE_ON_HIT)
	Explode(rshoulder, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE_ON_HIT)
	Explode(rthigh, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE_ON_HIT)
	Explode(rforearm, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE_ON_HIT)
	Explode(chest, SFX.SHATTER + SFX.EXPLODE_ON_HIT)
	return 2
end
