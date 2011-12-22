include 'constants.lua'

--------------------------------------------------------------------------------
-- pieces
--------------------------------------------------------------------------------
local base, pelvis, torso = piece('base', 'torso', 'torso')
local lfleg, rfleg, lbleg, rbleg = piece('lfleg', 'rfleg', 'lbleg', 'rbleg')
local lffoot, rffoot, lbfoot, rbfoot = piece('lffoot', 'rffoot', 'lbfoot', 'rbfoot')
local mainturret, lturret1, lturret2, rturret1, rturret2 = piece('mainturret', 'lturret1', 'lturret2', 'rturret1', 'rturret2')
local flaremain, flarel1, flarel2, flarer1, flarer2 = piece('flaremain', 'flarel1', 'flarel2', 'flarer1', 'flarer2')

local flares = {flarel1, flarer1, flarel2, flarer2}

smokePiece = {pelvis, torso}

--------------------------------------------------------------------------------
-- constants
--------------------------------------------------------------------------------

local restore_delay = 3000
local base_speed = 100

local SIG_WALK = 1	
local SIG_AIM1 = 2
local SIG_AIM2 = 4
local SIG_RESTORE = 8

local PACE = 1.4

local LEG_EXTEND_ANGLE_F = math.rad(40)
local LEG_EXTEND_ANGLE_R = math.rad(50)
local LEG_EXTEND_SPEED = math.rad(60) * PACE
local LEG_RETRACT_ANGLE_F = math.rad(-40)
local LEG_RETRACT_ANGLE_R = math.rad(-20)
local LEG_RETRACT_SPEED = math.rad(60) * PACE

local FOOT_EXTEND_ANGLE_F = math.rad(-60)
local FOOT_EXTEND_ANGLE_R = math.rad(-90)
local FOOT_EXTEND_SPEED_F = math.rad(80) * PACE
local FOOT_EXTEND_SPEED_R = math.rad(100) * PACE
local FOOT_RETRACT_ANGLE_F = math.rad(40)
local FOOT_RETRACT_ANGLE_R = math.rad(40)
local FOOT_RETRACT_SPEED_F = math.rad(80) * PACE
local FOOT_RETRACT_SPEED_R = math.rad(80) * PACE

--------------------------------------------------------------------------------
-- vars
--------------------------------------------------------------------------------
local gun_1 = 1

-- four-stroke tetrapedal walkscript
local function Walk()
	Signal(SIG_WALK)
	SetSignalMask(SIG_WALK)
	while true do
		-- extend front legs, retract rear legs
		Turn(lfleg, x_axis, LEG_EXTEND_ANGLE_F, LEG_EXTEND_SPEED)
		Turn(lffoot, x_axis, FOOT_EXTEND_ANGLE_F, FOOT_EXTEND_SPEED_F)
		Turn(rfleg, x_axis, LEG_EXTEND_ANGLE_F, LEG_EXTEND_SPEED)
		Turn(rffoot, x_axis, FOOT_EXTEND_ANGLE_F, FOOT_EXTEND_SPEED_F)
		
		Turn(lbleg, x_axis, -LEG_RETRACT_ANGLE_R, LEG_RETRACT_SPEED)
		Turn(lbfoot, x_axis, -FOOT_RETRACT_ANGLE_R, FOOT_RETRACT_SPEED_R)		
		Turn(rbleg, x_axis, -LEG_RETRACT_ANGLE_R, LEG_RETRACT_SPEED)
		Turn(rbfoot, x_axis, -FOOT_RETRACT_ANGLE_R, FOOT_RETRACT_SPEED_R)

		WaitForTurn(lfleg, x_axis)
		WaitForTurn(lffoot, x_axis)
		WaitForTurn(rbleg, x_axis)
		WaitForTurn(rbfoot, x_axis)
		Sleep(0)
		
		-- extend rear legs, retract front legs
		Turn(lfleg, x_axis, LEG_RETRACT_ANGLE_F, LEG_RETRACT_SPEED)
		Turn(lffoot, x_axis, FOOT_RETRACT_ANGLE_F, FOOT_RETRACT_SPEED_F)
		Turn(rfleg, x_axis, LEG_RETRACT_ANGLE_F, LEG_RETRACT_SPEED)
		Turn(rffoot, x_axis, FOOT_RETRACT_ANGLE_F, FOOT_RETRACT_SPEED_F)		
		
		Turn(lbleg, x_axis, -LEG_EXTEND_ANGLE_R, LEG_EXTEND_SPEED)
		Turn(lbfoot, x_axis, -FOOT_EXTEND_ANGLE_R, FOOT_EXTEND_SPEED_R)
		Turn(rbleg, x_axis, -LEG_EXTEND_ANGLE_R, LEG_EXTEND_SPEED)
		Turn(rbfoot, x_axis, -FOOT_EXTEND_ANGLE_R, FOOT_EXTEND_SPEED_R)		
		
		WaitForTurn(lfleg, x_axis)
		WaitForTurn(lffoot, x_axis)
		WaitForTurn(rbleg, x_axis)
		WaitForTurn(rbfoot, x_axis)		
		Sleep(0)
	end
end

local function ResetLegs()
	Turn(lfleg, x_axis, 0, LEG_EXTEND_SPEED)
	Turn(lffoot, x_axis, 0, FOOT_EXTEND_SPEED_F)
	Turn(rfleg, x_axis, 0, LEG_RETRACT_SPEED)
	Turn(rffoot, x_axis, 0, FOOT_RETRACT_SPEED_F)
	Turn(lbleg, x_axis, 0, LEG_EXTEND_SPEED)
	Turn(lbfoot, x_axis, 0, FOOT_EXTEND_SPEED_F)
	Turn(rbleg, x_axis, 0, LEG_RETRACT_SPEED)
	Turn(rbfoot, x_axis, 0, FOOT_RETRACT_SPEED_F)	
end

function script.Create()
	--StartThread(Walk)
	StartThread(SmokeUnit)
end

function script.StartMoving()
	--Spring.Echo("Moving")
	StartThread(Walk)
end

function script.StopMoving()
	--Spring.Echo("Stopped moving")
	Signal(SIG_WALK)
	ResetLegs()
end

local function RestoreAfterDelay()
	Sleep( 3000)
	Turn( torso , y_axis, 0, math.rad(70) )
	Turn( lturret1 , x_axis, 0, math.rad(50) )
	Turn( rturret1 , x_axis, 0, math.rad(50) )
	Turn( lturret2 , x_axis, 0, math.rad(50) )
	Turn( rturret2 , x_axis, 0, math.rad(50) )	
end

function script.AimWeapon(num, heading, pitch)
	if num == 1 then
		Signal( SIG_AIM1)
		SetSignalMask( SIG_AIM1)
		if pitch < -math.rad(10) then pitch = -math.rad(10)
		elseif pitch > math.rad(10) then pitch = math.rad(10) end
		
		Turn( torso , y_axis, heading, math.rad(360) )
		Turn( lturret1 , x_axis, -pitch, math.rad(180) )
		Turn( rturret1 , x_axis, -pitch, math.rad(180) )
		Turn( lturret2 , x_axis, -pitch, math.rad(180) )
		Turn( rturret2 , x_axis, -pitch, math.rad(180) )
		WaitForTurn(lturret1, x_axis)
		WaitForTurn(torso, y_axis)
		StartThread(RestoreAfterDelay)
		return true
	elseif num == 2 then
		Signal( SIG_AIM2)	
		SetSignalMask( SIG_AIM2)
		Turn( torso , y_axis, heading, math.rad(360) )	
		Turn( mainturret, x_axis, -pitch, math.rad(180) )
		WaitForTurn(torso, y_axis)
		WaitForTurn(mainturret, x_axis)
		StartThread(RestoreAfterDelay)
		return true
	end
end

function script.FireWeapon(num)
	if num == 1 then

	elseif num == 2 then
		EmitSfx(flaremain, 1024)
	end
end

function script.AimFromWeapon(num)
	return torso
end

function script.QueryWeapon(num)
	if num == 2 then return flaremain
	else return flares[gun_1] end
end

function script.Killed(recentDamage, maxHealth)
	local severity = recentDamage/maxHealth
	if severity <= .25  then
		Explode(base, sfxNone)
		return 1
	elseif (severity <= .50 ) then
		Explode(pelvis, sfxNone)
		return 1
	elseif (severity <= .99 ) then
		Explode(pelvis, sfxShatter)
		Explode(torso, sfxFall + sfxSmoke + sfxFire + sfxExplode)
		return 2
	else
		Explode(pelvis, sfxShatter)
		Explode(torso, sfxFall + sfxSmoke + sfxFire + sfxExplode)
		return 2
	end
end
