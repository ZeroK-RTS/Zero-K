include "constants.lua"

local base, pelvis, torso, aimpoint = piece('base', 'pelvis', 'torso', 'aimpoint')
local rthigh, rcalf, rfoot, lthigh, lcalf, lfoot = piece('rthigh', 'rcalf', 'rfoot', 'lthigh', 'lcalf', 'lfoot')
local rshoulder, rgun, rflare, lshoulder, lgun, lflare, forwards = piece('rshoulder', 'rgun', 'rflare', 'lshoulder', 'lgun', 'lflare', 'forwards')

local firepoints = {[0] = lflare, [1] = rflare}

local smokePiece = {torso}
--------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------
local PACE = 3

local THIGH_FRONT_ANGLE = math.rad(-50)
local THIGH_FRONT_SPEED = math.rad(60) * PACE
local THIGH_BACK_ANGLE = math.rad(10)
local THIGH_BACK_SPEED = math.rad(60) * PACE
local CALF_RETRACT_ANGLE = math.rad(0)
local CALF_RETRACT_SPEED = math.rad(90) * PACE
local CALF_STRAIGHTEN_ANGLE = math.rad(70)
local CALF_STRAIGHTEN_SPEED = math.rad(90) * PACE
local FOOT_FRONT_ANGLE = -THIGH_FRONT_ANGLE - math.rad(10)
local FOOT_FRONT_SPEED = 2*THIGH_FRONT_SPEED
local FOOT_BACK_ANGLE = -(THIGH_BACK_ANGLE + CALF_STRAIGHTEN_ANGLE)
local FOOT_BACK_SPEED = THIGH_BACK_SPEED + CALF_STRAIGHTEN_SPEED
local BODY_TILT_ANGLE = math.rad(5)
local BODY_TILT_SPEED = math.rad(10)
local BODY_RISE_HEIGHT = 4
local BODY_RISE_SPEED = 6*PACE

local ARM_FRONT_ANGLE = -math.rad(20)
local ARM_FRONT_SPEED = math.rad(22.5) * PACE
local ARM_BACK_ANGLE = math.rad(10)
local ARM_BACK_SPEED = math.rad(22.5) * PACE
local FOREARM_FRONT_ANGLE = -math.rad(40)
local FOREARM_FRONT_SPEED = math.rad(45) * PACE
local FOREARM_BACK_ANGLE = math.rad(10)
local FOREARM_BACK_SPEED = math.rad(45) * PACE

local SIG_WALK = 1
local SIG_AIM1 = 2
local SIG_AIM2 = 4
local SIG_RESTORE = 8
local SIG_FLOAT = 16
local SIG_BOB = 32

--------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------

local spGetUnitRulesParam = Spring.GetUnitRulesParam
local spGetGroundHeight = Spring.GetGroundHeight

local wd = WeaponDefNames["amphimpulse_watercannon"]

local impulse = tonumber(wd.customParams.impulse)
local maxProjectiles = 8

local impulseMaxDepth = -tonumber(wd.customParams.impulsemaxdepth)
local impulseDepthMult = -tonumber(wd.customParams.impulsedepthmult)
--------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------
-- Weapon config

local SOUND_PERIOD = 2
local soundIndex = SOUND_PERIOD
local TANK_MAX 

--------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------
local gun_1 = 1

--------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------
-- Swim functions

local floatState = nil
-- rising, sinking, static

local function Bob()
	Signal(SIG_BOB)
	SetSignalMask(SIG_BOB)
	while true do
		Turn(base, x_axis, math.rad(math.random(-2,2)), math.rad(math.random()))
		Turn(base, z_axis, math.rad(math.random(-2,2)), math.rad(math.random()))
		Move(base, y_axis, math.rad(math.random(0,2)), math.rad(math.random()))
		Sleep(2000)
		Turn(base, x_axis, math.rad(math.random(-2,2)), math.rad(math.random()))
		Turn(base, z_axis, math.rad(math.random(-2,2)), math.rad(math.random()))
		Move(base, y_axis, math.rad(math.random(-2,0)), math.rad(math.random()))
		Sleep(2000)
	end
end

local function FloatBubbles()
	--[[
	SetSignalMask(SIG_FLOAT)
	local isSubmerged = true
	while true do
		--EmitSfx(vent, SFX.BUBBLE)
		
		if isSubmerged then -- water breaking anim - kind of overkill?
			local x,y,z = Spring.GetUnitPosition(unitID)
			y = y + Spring.GetUnitHeight(unitID)*0.5
			if y > 0 then
				--Spring.Echo("splash")
				Spring.SpawnCEG("water_breaksurface", x, 0, z, 0, 1, 0, 20, 0)
				isSubmerged = false
			end
		end
		Sleep(33)
		
	end
	]]
end

local function riseFloat_thread()
	if floatState ~= 0 then
		floatState = 0
	else
		return
	end
	Signal(SIG_FLOAT)
	SetSignalMask(SIG_FLOAT)
		--StartThread(FloatBubbles)
		
	Turn(lthigh,x_axis, math.rad(30), math.rad(240))
	Turn(lcalf,x_axis, math.rad(-50), math.rad(240))
	Turn(lfoot,x_axis, math.rad(80), math.rad(240))
	
	Turn(rthigh,x_axis, math.rad(30), math.rad(240))
	Turn(rcalf,x_axis, math.rad(-50), math.rad(240))
	Turn(rfoot,x_axis, math.rad(80), math.rad(240))
	
	Sleep(400)
	
	while true do
		
		Turn(lthigh,x_axis, math.rad(10+25), math.rad(75))
		Turn(rthigh,x_axis, math.rad(10-25), math.rad(75))
		
		
		Sleep(200)
		
		Turn(lcalf,x_axis, math.rad(-25-20), math.rad(100))
		Turn(lfoot,x_axis, math.rad(10+20), math.rad(100))
		Turn(rcalf,x_axis, math.rad(-25+20), math.rad(100))
		Turn(rfoot,x_axis, math.rad(10-20), math.rad(100))
		
		Sleep(200)
		
		Turn(lthigh,x_axis, math.rad(10-25), math.rad(75))
		Turn(rthigh,x_axis, math.rad(10+25), math.rad(75))
		
		Sleep(200)
		
		Turn(lcalf,x_axis, math.rad(-25+20), math.rad(100))
		Turn(lfoot,x_axis, math.rad(10-20), math.rad(100))
		Turn(rcalf,x_axis, math.rad(-25-20), math.rad(100))
		Turn(rfoot,x_axis, math.rad(10+20), math.rad(100))
		
		Sleep(200)
	end
end

local function staticFloat_thread()
	if floatState ~= 2 then
		floatState = 2
	else
		return
	end
	Signal(SIG_FLOAT)
	SetSignalMask(SIG_FLOAT)
		
	Turn(lcalf,x_axis, math.rad(-25-20), math.rad(50))
	Turn(lfoot,x_axis, math.rad(10+20), math.rad(50))
	Turn(rcalf,x_axis, math.rad(-25+20), math.rad(50))
	Turn(rfoot,x_axis, math.rad(10-20), math.rad(50))
	
	while true do
		
		Turn(lthigh,x_axis, math.rad(10+25), math.rad(37.5))
		Turn(rthigh,x_axis, math.rad(10-25), math.rad(37.5))
		
		
		Sleep(400)
		
		Turn(lcalf,x_axis, math.rad(-25-20), math.rad(50))
		Turn(lfoot,x_axis, math.rad(10+20), math.rad(50))
		Turn(rcalf,x_axis, math.rad(-25+20), math.rad(50))
		Turn(rfoot,x_axis, math.rad(10-20), math.rad(50))
		
		Sleep(400)
		
		Turn(lthigh,x_axis, math.rad(10-25), math.rad(37.5))
		Turn(rthigh,x_axis, math.rad(10+25), math.rad(37.5))
		
		Sleep(400)
		
		Turn(lcalf,x_axis, math.rad(-25+20), math.rad(50))
		Turn(lfoot,x_axis, math.rad(10-20), math.rad(50))
		Turn(rcalf,x_axis, math.rad(-25-20), math.rad(50))
		Turn(rfoot,x_axis, math.rad(10+20), math.rad(50))
		
		Sleep(400)
	end
end

local function sinkFloat_thread()
	if floatState ~= 1 then
		floatState = 1
	else
		return
	end
	
	Signal(SIG_FLOAT)
	SetSignalMask(SIG_FLOAT)
	
	Turn(rthigh, x_axis, 0, math.rad(80)*PACE)
	Turn(rcalf, x_axis, 0, math.rad(120)*PACE)
	Turn(rfoot, x_axis, 0, math.rad(80)*PACE)
	Turn(lthigh, x_axis, 0, math.rad(80)*PACE)
	Turn(lcalf, x_axis, 0, math.rad(80)*PACE)
	Turn(lfoot, x_axis, 0, math.rad(80)*PACE)
	Turn(pelvis, z_axis, 0, math.rad(20)*PACE)
	Move(pelvis, y_axis, 0, 12*PACE)
	
	Turn(base, x_axis,0, math.rad(math.random(1,2)))
	Turn(base, z_axis, 0, math.rad(math.random(1,2)))
	Move(base, y_axis, 0, math.rad(math.random(1,2)))
	
	while true do --FIXME: not stopped when sinking ends!
		EmitSfx(torso, SFX.BUBBLE)
		Sleep(66)
	end
	
end

local function dustBottom()
	local x,y,z = Spring.GetUnitPiecePosDir(unitID,rfoot)
	Spring.SpawnCEG("uw_vindiback", x, y+5, z, 0, 0, 0, 0)
	local x,y,z = Spring.GetUnitPiecePosDir(unitID,lfoot)
	Spring.SpawnCEG("uw_vindiback", x, y+5, z, 0, 0, 0, 0)
end

--------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------
-- Swim gadget callins

function Float_startFromFloor()
	dustBottom()
	Signal(SIG_WALK)
	StartThread(riseFloat_thread)
	StartThread(Bob)
end

function Float_stopOnFloor()
	dustBottom()
	Signal(SIG_FLOAT)
	Signal(SIG_BOB)
end

function Float_rising()
	StartThread(riseFloat_thread)
end

function Float_sinking()
	StartThread(sinkFloat_thread)
end

function Float_crossWaterline(speed)
	StartThread(staticFloat_thread)
end

function Float_stationaryOnSurface()
	StartThread(staticFloat_thread)
end

function unit_teleported(position)
	return GG.Floating_UnitTeleported(unitID, position)
end

--------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------
-- four-stroke bipedal (reverse-jointed) walkscript
local function Walk()
	Signal(SIG_WALK)
	SetSignalMask(SIG_WALK)
	while true do
		local speed = (Spring.GetUnitRulesParam(unitID,"baseSpeedMult") or 1)
		--straighten left leg and draw it back, raise body, center right leg
		Move(pelvis, y_axis, BODY_RISE_HEIGHT, BODY_RISE_SPEED*speed)
		Turn(pelvis, z_axis, BODY_TILT_ANGLE, BODY_TILT_SPEED*speed)
		Turn(lthigh, x_axis, THIGH_BACK_ANGLE, THIGH_BACK_SPEED*speed)
		Turn(lcalf, x_axis, CALF_STRAIGHTEN_ANGLE, CALF_STRAIGHTEN_SPEED*speed)
		Turn(lfoot, x_axis, FOOT_BACK_ANGLE, FOOT_BACK_SPEED*speed)		
		Turn(rthigh, x_axis, 0, THIGH_FRONT_SPEED*speed)
		Turn(rcalf, x_axis, 0, CALF_RETRACT_SPEED*speed)
		Turn(rfoot, x_axis, 0, FOOT_FRONT_SPEED*speed)
		WaitForTurn(lthigh, x_axis)
		Sleep(0)
		
		-- lower body, draw right leg forwards
		Move(pelvis, y_axis, 0, BODY_RISE_SPEED*speed)
		Turn(pelvis, z_axis, 0, BODY_TILT_SPEED*speed)
		--Turn(lcalf, x_axis, CALF_STRAIGHTEN_ANGLE, CALF_STRAIGHTEN_SPEED)
		Turn(rthigh, x_axis, THIGH_FRONT_ANGLE, THIGH_FRONT_SPEED*speed)
		Turn(rfoot, x_axis, FOOT_FRONT_ANGLE, FOOT_FRONT_SPEED*speed)	
		WaitForMove(pelvis, y_axis)
		Sleep(0)
		
		--straighten right leg and draw it back, raise body, center left leg
		Move(pelvis, y_axis, BODY_RISE_HEIGHT, BODY_RISE_SPEED*speed)
		Turn(pelvis, z_axis, -BODY_TILT_ANGLE, BODY_TILT_SPEED*speed)
		Turn(lthigh, x_axis, 0, THIGH_FRONT_SPEED*speed)
		Turn(lcalf, x_axis, 0, CALF_RETRACT_SPEED*speed)
		Turn(lfoot, x_axis, 0, FOOT_FRONT_SPEED*speed)		
		Turn(rthigh, x_axis, THIGH_BACK_ANGLE, THIGH_BACK_SPEED*speed)
		Turn(rcalf, x_axis, CALF_STRAIGHTEN_ANGLE, CALF_STRAIGHTEN_SPEED*speed)
		Turn(rfoot, x_axis, FOOT_BACK_ANGLE, FOOT_BACK_SPEED*speed)		
		WaitForTurn(rthigh, x_axis)
		Sleep(0)
		
		-- lower body, draw left leg forwards
		Move(pelvis, y_axis, 0, BODY_RISE_SPEED*speed)
		Turn(pelvis, z_axis, 0, BODY_TILT_SPEED*speed)
		Turn(lthigh, x_axis, THIGH_FRONT_ANGLE, THIGH_FRONT_SPEED*speed)
		Turn(lfoot, x_axis, FOOT_FRONT_ANGLE, FOOT_FRONT_SPEED*speed)			
		--Turn(rcalf, x_axis, CALF_STRAIGHTEN_ANGLE, CALF_STRAIGHTEN_SPEED)
		WaitForMove(pelvis, y_axis)
		Sleep(0)
	end
end

local function Stopping()
	Signal(SIG_WALK)
	SetSignalMask(SIG_WALK)
	
	Turn(rthigh, x_axis, 0, math.rad(80)*PACE)
	Turn(rcalf, x_axis, 0, math.rad(120)*PACE)
	Turn(rfoot, x_axis, 0, math.rad(80)*PACE)
	Turn(lthigh, x_axis, 0, math.rad(80)*PACE)
	Turn(lcalf, x_axis, 0, math.rad(80)*PACE)
	Turn(lfoot, x_axis, 0, math.rad(80)*PACE)
	Turn(pelvis, z_axis, 0, math.rad(20)*PACE)
	Move(pelvis, y_axis, 0, 12*PACE)
end

function script.StartMoving()
	StartThread(Walk)
end

function script.StopMoving()
	Signal(SIG_START_FLOAT)
	StartThread(Stopping)
	GG.Floating_StopMoving(unitID)
end

function script.Create()
	TANK_MAX = UnitDefs[Spring.GetUnitDefID(unitID)].customParams.maxwatertank
	--StartThread(Walk)

	StartThread(GG.Script.SmokeUnit, smokePiece)	
end

local function RestoreAfterDelay()
	Signal(SIG_RESTORE)
	SetSignalMask(SIG_RESTORE)
	Sleep(5000)
	Turn(torso, y_axis, 0, math.rad(65))
	Turn(lshoulder, x_axis, 0, math.rad(45))
	Turn(rshoulder, x_axis, 0, math.rad(45))
end

function script.AimFromWeapon()
	return aimpoint
end

function script.AimWeapon(num, heading, pitch)
	if num == 1 then
		Signal(SIG_AIM1)
		SetSignalMask(SIG_AIM1)
		Turn(torso, y_axis, heading, math.rad(480))
		Turn(lshoulder, x_axis, -pitch, math.rad(200))
		Turn(rshoulder, x_axis, -pitch, math.rad(200))
		WaitForTurn(torso, y_axis)
		WaitForTurn(lshoulder, x_axis)
		StartThread(RestoreAfterDelay)
		return true
	elseif num == 2 then
		GG.Floating_AimWeapon(unitID)
		return false
	end
end

function script.QueryWeapon(num)
	return firepoints[gun_1]
end

function script.Shot(num)
	GG.Floating_AimWeapon(unitID)
	EmitSfx(firepoints[gun_1], 1024)
	gun_1 = 1 - gun_1
end

function script.Killed(recentDamage, maxHealth)
	local severity = recentDamage/maxHealth
	if severity <= .25 then
		Explode(lfoot, SFX.NONE)
		Explode(lcalf, SFX.NONE)
		Explode(lthigh, SFX.NONE)
		Explode(pelvis, SFX.NONE)
		Explode(rfoot, SFX.NONE)
		Explode(rcalf, SFX.NONE)
		Explode(rthigh, SFX.NONE)
		Explode(torso, SFX.NONE)
		return 1
	elseif severity <= .50 then
		Explode(lfoot, SFX.FALL)
		Explode(lcalf, SFX.FALL)
		Explode(lthigh, SFX.FALL)
		Explode(pelvis, SFX.FALL)
		Explode(rfoot, SFX.FALL)
		Explode(rcalf, SFX.FALL)
		Explode(rthigh, SFX.FALL)
		Explode(torso, SFX.SHATTER)
		return 1
	elseif severity <= .99 then
		Explode(lfoot, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE)
		Explode(lcalf, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE)
		Explode(lthigh, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE)
		Explode(pelvis, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE)
		Explode(rfoot, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE)
		Explode(rcalf, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE)
		Explode(rthigh, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE)
		Explode(torso, SFX.SHATTER)
		return 2
	else
		Explode(lfoot, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE)
		Explode(lcalf, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE)
		Explode(lthigh, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE)
		Explode(pelvis, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE)
		Explode(rfoot, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE)
		Explode(rcalf, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE)
		Explode(rthigh, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE)
		Explode(torso, SFX.SHATTER + SFX.EXPLODE)
		return 2
	end
end