include "constants.lua"

local base, pelvis, torso, aimpoint = piece('base', 'pelvis', 'torso', 'aimpoint')
local rthigh, rcalf, rfoot, lthigh, lcalf, lfoot = piece('rthigh', 'rcalf', 'rfoot', 'lthigh', 'lcalf', 'lfoot')
local rshoulder, rgun, rflare, lshoulder, lgun, lflare = piece('rshoulder', 'rgun', 'rflare', 'lshoulder', 'lgun', 'lflare')

local firepoints = {[0] = lflare, [1] = rflare}

smokePiece = {torso}
--------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------
local PACE = 2

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
local BODY_TILT_ANGLE = math.rad(10)
local BODY_TILT_SPEED = math.rad(20)
local BODY_RISE_HEIGHT = 6
local BODY_RISE_SPEED = 8*PACE

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

--------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------
-- Weapon config

local SOUND_PERIOD = 1
local soundIndex = SOUND_PERIOD
local TANK_MAX 

--------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------
local gun_1 = 1

--------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------
-- four-stroke bipedal (reverse-jointed) walkscript
local function Walk()
	Signal(SIG_WALK)
	SetSignalMask(SIG_WALK)
	while true do
		--straighten left leg and draw it back, raise body, center right leg
		Move(pelvis, y_axis, BODY_RISE_HEIGHT, BODY_RISE_SPEED)
		Turn(pelvis, z_axis, BODY_TILT_ANGLE, BODY_TILT_SPEED)
		Turn(lthigh, x_axis, THIGH_BACK_ANGLE, THIGH_BACK_SPEED)
		Turn(lcalf, x_axis, CALF_STRAIGHTEN_ANGLE, CALF_STRAIGHTEN_SPEED)
		Turn(lfoot, x_axis, FOOT_BACK_ANGLE, FOOT_BACK_SPEED)		
		Turn(rthigh, x_axis, 0, THIGH_FRONT_SPEED)
		Turn(rcalf, x_axis, 0, CALF_RETRACT_SPEED)
		Turn(rfoot, x_axis, 0, FOOT_FRONT_SPEED)
		WaitForTurn(lthigh, y_axis)
		Sleep(200)
		
		-- lower body, draw right leg forwards
		Move(pelvis, y_axis, 0, BODY_RISE_SPEED)
		Turn(pelvis, z_axis, 0, BODY_TILT_SPEED)
		--Turn(lcalf, x_axis, CALF_STRAIGHTEN_ANGLE, CALF_STRAIGHTEN_SPEED)
		Turn(rthigh, x_axis, THIGH_FRONT_ANGLE, THIGH_FRONT_SPEED)
		Turn(rfoot, x_axis, FOOT_FRONT_ANGLE, FOOT_FRONT_SPEED)	
		WaitForMove(pelvis, y_axis)
		Sleep(200)
		
		--straighten right leg and draw it back, raise body, center left leg
		Move(pelvis, y_axis, BODY_RISE_HEIGHT, BODY_RISE_SPEED)
		Turn(pelvis, z_axis, -BODY_TILT_ANGLE, BODY_TILT_SPEED)
		Turn(lthigh, x_axis, 0, THIGH_FRONT_SPEED)
		Turn(lcalf, x_axis, 0, CALF_RETRACT_SPEED)
		Turn(lfoot, x_axis, 0, FOOT_FRONT_SPEED)		
		Turn(rthigh, x_axis, THIGH_BACK_ANGLE, THIGH_BACK_SPEED)
		Turn(rcalf, x_axis, CALF_STRAIGHTEN_ANGLE, CALF_STRAIGHTEN_SPEED)
		Turn(rfoot, x_axis, FOOT_BACK_ANGLE, FOOT_BACK_SPEED)		
		WaitForTurn(rthigh, y_axis)
		Sleep(200)
		
		-- lower body, draw left leg forwards
		Move(pelvis, y_axis, 0, BODY_RISE_SPEED)
		Turn(pelvis, z_axis, 0, BODY_TILT_SPEED)
		Turn(lthigh, x_axis, THIGH_FRONT_ANGLE, THIGH_FRONT_SPEED)
		Turn(lfoot, x_axis, FOOT_FRONT_ANGLE, FOOT_FRONT_SPEED)			
		--Turn(rcalf, x_axis, CALF_STRAIGHTEN_ANGLE, CALF_STRAIGHTEN_SPEED)
		WaitForMove(pelvis, y_axis)
		Sleep(200)
	end
end

function script.StartMoving()
	StartThread(Walk)
end

function script.StopMoving()
	Signal(SIG_WALK)
	Turn( rthigh , x_axis, 0, math.rad(80)*PACE  )
	Turn( rcalf , x_axis, 0, math.rad(120)*PACE  )
	Turn( rfoot , x_axis, 0, math.rad(80)*PACE  )
	Turn( lthigh , x_axis, 0, math.rad(80)*PACE  )
	Turn( lcalf , x_axis, 0, math.rad(80)*PACE  )
	Turn( lfoot , x_axis, 0, math.rad(80)*PACE  )
	Turn( pelvis , z_axis, 0, math.rad(20)*PACE  )
	Move( pelvis , y_axis, 0, 12*PACE )
end

function script.Create()
	TANK_MAX = UnitDefs[Spring.GetUnitDefID(unitID)].customParams.maxwatertank
	--StartThread(Walk)

	StartThread(SmokeUnit)	
end

local function RestoreAfterDelay()
	Signal(SIG_RESTORE)
	SetSignalMask(SIG_RESTORE)
	Sleep(5000)
	Turn( torso, y_axis, 0, math.rad(65) )
end

function script.AimFromWeapon()
	return aimpoint
end

function script.AimWeapon(num, heading, pitch)
	if num == 1 then
		Signal(SIG_AIM1)
		SetSignalMask(SIG_AIM1)
		Turn( torso, y_axis, heading, math.rad(480) )
		Turn( lshoulder, x_axis, -pitch, math.rad(200) )
		Turn( rshoulder, x_axis, -pitch, math.rad(200) )
		WaitForTurn(torso, y_axis)
		WaitForTurn(lshoulder, x_axis)
		StartThread(RestoreAfterDelay)
		return true
	end
end

function script.QueryWeapon(num)
	return firepoints[gun_1]
end

function script.FireWeapon(num)
	soundIndex = soundIndex - 1
	if soundIndex <= 0 then
		local proportion = 0
		local waterTank = Spring.GetUnitRulesParam(unitID,"watertank")
		if waterTank then
			proportion = waterTank/TANK_MAX
		end
		soundIndex = SOUND_PERIOD*(2 - proportion)
		local px, py, pz = Spring.GetUnitPosition(unitID)
		Spring.PlaySoundFile("sounds/weapon/hiss.wav", 5-proportion*2, px, py, pz)
	end

	GG.shotWaterWeapon(unitID)
end

function script.Shot(num)
    if math.random() < 0.4 then
		EmitSfx(firepoints[gun_1], 1024)
	end
	--[[
	local waterTank = Spring.GetUnitRulesParam(unitID,"watertank")
	if waterTank then
        local proportion = waterTank/TANK_MAX
		if proportion > 0.4 then
			EmitSfx(firepoints[gun_1], 1024)
			if math.random() < (proportion-0.4)/0.6 then
				EmitSfx(firepoints[gun_1], 1024)
			end
		else
			if math.random() < (proportion + 0.2)/0.6 then
				EmitSfx(firepoints[gun_1], 1024)
			end
		end
	end--]]
	--Spring.Echo(Spring.GetGameFrame())
	gun_1 = 1 - gun_1
end

function script.Killed(recentDamage, maxHealth)
	local severity = recentDamage/maxHealth
	if severity >= .25  then
		Explode(lfoot, sfxNone)
		Explode(lcalf, sfxNone)
		Explode(lthigh, sfxNone)
		Explode(pelvis, sfxNone)
		Explode(rfoot, sfxNone)
		Explode(rcalf, sfxNone)
		Explode(rthigh, sfxNone)
		Explode(torso, sfxNone)
		return 1
	elseif severity >= .50  then
		Explode(lfoot, sfxFall)
		Explode(lcalf, sfxFall)
		Explode(lthigh, sfxFall)
		Explode(pelvis, sfxFall)
		Explode(rfoot, sfxFall)
		Explode(rcalf, sfxFall)
		Explode(rthigh, sfxFall)
		Explode(torso, sfxShatter)
		return 1
	elseif severity >= .99  then
		Explode(lfoot, sfxFall + sfxSmoke  + sfxFire  + sfxExplode )
		Explode(lcalf, sfxFall + sfxSmoke  + sfxFire  + sfxExplode )
		Explode(lthigh, sfxFall + sfxSmoke  + sfxFire  + sfxExplode )
		Explode(pelvis, sfxFall + sfxSmoke  + sfxFire  + sfxExplode )
		Explode(rfoot, sfxFall + sfxSmoke  + sfxFire  + sfxExplode )
		Explode(rcalf, sfxFall + sfxSmoke  + sfxFire  + sfxExplode )
		Explode(rthigh, sfxFall + sfxSmoke  + sfxFire  + sfxExplode )
		Explode(torso, sfxShatter)
		return 2
	else
		Explode(lfoot, sfxFall + sfxSmoke  + sfxFire  + sfxExplode )
		Explode(lcalf, sfxFall + sfxSmoke  + sfxFire  + sfxExplode )
		Explode(lthigh, sfxFall + sfxSmoke  + sfxFire  + sfxExplode )
		Explode(pelvis, sfxFall + sfxSmoke  + sfxFire  + sfxExplode )
		Explode(rfoot, sfxFall + sfxSmoke  + sfxFire  + sfxExplode )
		Explode(rcalf, sfxFall + sfxSmoke  + sfxFire  + sfxExplode )
		Explode(rthigh, sfxFall + sfxSmoke  + sfxFire  + sfxExplode )
		Explode(torso, sfxShatter + sfxExplode )
		return 2
	end
end