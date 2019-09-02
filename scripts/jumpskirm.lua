local support = piece 'support'
local flare = piece 'flare'
local eye_flare = piece 'eye_flare'
local thigh1 = piece 'thigh1'
local thigh2 = piece 'thigh2'
local torso = piece 'torso'
local head = piece 'head'
local barrel = piece 'barrel'
local foot2 = piece 'foot2'
local foot1 = piece 'foot1'
local leg2 = piece 'leg2'
local leg1 = piece 'leg1'
local shoulder = piece 'shoulder'
local shoulder_left = piece 'shoulder_left'

include "constants.lua"

local aiming = false

local RESTORE_DELAY = 2000

-- Signal definitions
local SIG_MOVE = 1
local SIG_AIM = 2
local SIG_RESTORE = 4

local function walk()
	Signal(SIG_MOVE)
	SetSignalMask(SIG_MOVE)

	while true do
		if not aiming then
			Move(torso, y_axis, -0.050000)
			Turn(torso, x_axis, math.rad(1.758242))
			Turn(torso, z_axis, math.rad(-0.703297))
		end
		
		Turn(thigh1, x_axis, math.rad(16.879121))
		Turn(thigh2, x_axis, math.rad(-45.714286))
		Turn(leg2, x_axis, math.rad(50.983516))
		Turn(foot1, x_axis, math.rad(-16.527473))
		Sleep(100)
	
		if not aiming then
			Move(torso, y_axis, 0.000000)
			Turn(torso, x_axis, math.rad(0.351648))
			Turn(torso, z_axis, math.rad(-0.351648))
		end
		
		Turn(thigh1, x_axis, math.rad(24.263736))
		Turn(thigh2, x_axis, math.rad(-41.137363))
		Turn(leg2, x_axis, math.rad(43.247253))
		Turn(foot1, x_axis, math.rad(-11.956044))
		Sleep(102)
	
		if not aiming then
			Turn(torso, x_axis, 0)
			Turn(torso, z_axis, 0)
		end
		
		Turn(thigh1, x_axis, math.rad(37.620879))
		Turn(thigh2, x_axis, math.rad(-26.368132))
		Turn(leg2, x_axis, math.rad(26.368132))
		Turn(leg1, x_axis, math.rad(8.439560))
		Sleep(104)
	
		if not aiming then
			Move(torso, y_axis, -0.300000)
			Turn(torso, x_axis, 0)
		end
		
		Turn(thigh1, x_axis, math.rad(22.148352))
		Turn(thigh2, x_axis, math.rad(-11.956044))
		Turn(leg2, x_axis, math.rad(11.598901))
		Turn(leg1, x_axis, math.rad(27.428571))
		Sleep(102)
	
		if not aiming then
			Move(torso, y_axis, -0.250000)
			Turn(torso, x_axis, math.rad(1.758242))
			Turn(torso, z_axis, math.rad(1.406593))
		end
		
		Turn(thigh1, x_axis, math.rad(3.159341))
		Turn(thigh2, x_axis, math.rad(7.032967))
		Turn(leg2, x_axis, math.rad(-1.054945))
		Turn(foot2, x_axis, math.rad(-6.329670))
		Turn(leg1, x_axis, math.rad(53.450549))
		Sleep(102)
	
		if not aiming then
			Move(torso, y_axis, -0.100000)
			Turn(torso, x_axis, math.rad(2.461538))
			Turn(torso, z_axis, math.rad(0.703297))
		end
		
		Turn(thigh1, x_axis, math.rad(-20.747253))
		Turn(thigh2, x_axis, math.rad(20.747253))
		Turn(foot2, x_axis, math.rad(-19.692308))
		Turn(leg1, x_axis, math.rad(60.829670))
		Sleep(103)

		if not aiming then
			Move(torso, y_axis, -0.050000)
			Turn(torso, x_axis, math.rad(0.703297))
		end
		
		Turn(thigh1, x_axis, math.rad(-39.384615))
		Turn(thigh2, x_axis, math.rad(28.483516))
		Turn(foot2, x_axis, math.rad(-27.076923))
		Sleep(103)
	
		if not aiming then
			Move(torso, y_axis, 0.000000)
			Turn(torso, x_axis, math.rad(0.351648))
			Turn(torso, z_axis, math.rad(0.351648))
		end
		
		Turn(thigh1, x_axis, math.rad(-43.956044))
		Turn(thigh2, x_axis, math.rad(34.813187))
		Turn(foot2, x_axis, math.rad(-20.395604))
		Turn(leg1, x_axis, math.rad(43.956044))
		Turn(foot1, x_axis, 0)
		Sleep(103)
		
		if not aiming then
			Turn(torso, x_axis, 0)
			Turn(torso, z_axis, 0)
		end
		
		Turn(thigh1, x_axis, math.rad(-31.994505))
		Turn(thigh2, x_axis, math.rad(35.868132))
		Turn(leg2, x_axis, math.rad(16.175824))
		Turn(foot2, x_axis, math.rad(-13.714286))
		Turn(leg1, x_axis, math.rad(32.351648))
		Sleep(103)
	
		if not aiming then
			Move(torso, y_axis, -0.250000)
		end
		
		Turn(thigh1, x_axis, math.rad(-23.554945))
		Turn(thigh2, x_axis, math.rad(23.560440))
		Turn(leg2, x_axis, math.rad(40.434066))
		Turn(leg1, x_axis, math.rad(24.263736))
		Sleep(103)
	
		if not aiming then
			Move(torso, y_axis, -0.200000)
			Turn(torso, x_axis, math.rad(2.109890))
			Turn(torso, z_axis, math.rad(-2.109890))
		end
		
		Turn(thigh1, x_axis, math.rad(-1.406593))
		Turn(thigh2, x_axis, math.rad(-14.412088))
		Turn(leg2, x_axis, math.rad(69.269231))
		Turn(leg1, x_axis, math.rad(2.461538))
		Sleep(103)
	
		if not aiming then
			Move(torso, y_axis, -0.150000)
			Turn(torso, z_axis, math.rad(-1.054945))
		end
		
		Turn(thigh1, x_axis, math.rad(11.604396))
		Turn(thigh2, x_axis, math.rad(-35.164835))
		Turn(leg2, x_axis, math.rad(76.659341))
		Turn(foot1, x_axis, math.rad(-14.065934))
		Sleep(103)
	end
end

function script.Create()
	Hide(flare)
	Hide(support)
	Hide(barrel)
	StartThread(GG.Script.SmokeUnit, unitID, {torso})
end

function script.StartMoving()
	StartThread(walk)
end

function script.StopMoving()
	Signal(SIG_MOVE)
	
	Turn(thigh1, x_axis, 0)
	Turn(thigh2, x_axis, 0)
	Turn(leg2, x_axis, 0)
	Turn(foot1, x_axis, 0)
end


local function RestoreAfterDelay()
	Signal(SIG_RESTORE)
	SetSignalMask(SIG_RESTORE)
	Sleep(RESTORE_DELAY)
	Turn(torso, y_axis, 0, math.rad(160))
	Turn(head, x_axis, 0, math.rad(45))
	aiming = false
end

function script.AimWeapon(num, heading, pitch)
	Signal(SIG_AIM)
	SetSignalMask(SIG_AIM)
	StartThread(RestoreAfterDelay)
	aiming = true
	
	-- The aim check messes with unit targeting. This is not required for Moderator as
	-- it very rarely shoots at radar dots.
	--GG.DontFireRadar_CheckAim(unitID)
	
	Turn(torso, y_axis, heading, math.rad(300))
	Turn(head, x_axis, -pitch, math.rad(150))
	WaitForTurn(torso, y_axis)
	WaitForTurn(head, x_axis)
	return true
end

function script.FireWeapon()
	EmitSfx(eye_flare, 1024)
	Spin(shoulder, x_axis, math.rad(485), math.rad(5))
	Spin(shoulder_left, x_axis, math.rad(485), math.rad(5))
	Sleep(6600)
	Spin(shoulder, x_axis, 0, math.rad(5))
	Spin(shoulder_left, x_axis, 0, math.rad(5))
	Sleep(3100)
	Turn(shoulder, x_axis, 0, math.rad(50))
	Turn(shoulder_left, x_axis, 0, math.rad(50))
end

function script.QueryWeapon()
	return eye_flare
end

function script.AimFromWeapon()
	return head
end

function script.BlockShot(num, targetID)
	return (targetID and GG.DontFireRadar_CheckBlock(unitID, targetID)) or false
end

function script.Killed(recentDamage, maxHealth)
	local severity = recentDamage/maxHealth
	if severity <= 0.25 then
		Explode(foot1, SFX.NONE)
		Explode(foot2, SFX.NONE)
		Explode(leg1, SFX.NONE)
		Explode(leg2, SFX.NONE)
		Explode(thigh1, SFX.NONE)
		Explode(thigh2, SFX.NONE)
		Explode(torso, SFX.NONE)
		return 1
	elseif severity <= 0.50 then
		Explode(foot1, SFX.NONE)
		Explode(foot2, SFX.NONE)
		Explode(leg1, SFX.NONE)
		Explode(leg2, SFX.NONE)
		Explode(thigh1, SFX.NONE)
		Explode(thigh2, SFX.NONE)
		Explode(torso, SFX.SHATTER)
		return 1
	end

	Explode(foot1, SFX.SMOKE + SFX.FIRE)
	Explode(foot2, SFX.SMOKE + SFX.FIRE)
	Explode(leg1, SFX.SMOKE + SFX.FIRE)
	Explode(leg2, SFX.SMOKE + SFX.FIRE)
	Explode(thigh1, SFX.SMOKE + SFX.FIRE)
	Explode(thigh2, SFX.SMOKE + SFX.FIRE)
	Explode(torso, SFX.SHATTER)
	return 2
end
