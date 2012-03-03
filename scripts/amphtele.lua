--linear constant 65536

include "constants.lua"
include "utility.lua"
include 'letsNotFailAtTrig.lua'

local base, pelvis, body = piece('base', 'pelvis', 'body')
local rthigh, rshin, rfoot, lthigh, lshin, lfoot = piece('rthigh', 'rshin', 'rfoot', 'lthigh', 'lshin', 'lfoot')
local holder, sphere = piece('holder', 'sphere') 

smokePiece = {pelvis}
--------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------
local PACE = 1.5

local THIGH_FRONT_ANGLE = math.rad(-50)
local THIGH_FRONT_SPEED = math.rad(60) * PACE
local THIGH_BACK_ANGLE = math.rad(10)
local THIGH_BACK_SPEED = math.rad(60) * PACE
local CALF_RETRACT_ANGLE = math.rad(0)
local CALF_RETRACT_SPEED = math.rad(90) * PACE
local CALF_STRAIGHTEN_ANGLE = math.rad(70)
local CALF_STRAIGHTEN_SPEED = math.rad(90) * PACE
local FOOT_FRONT_ANGLE = -THIGH_FRONT_ANGLE - math.rad(20)
local FOOT_FRONT_SPEED = 2*THIGH_FRONT_SPEED
local FOOT_BACK_ANGLE = -(THIGH_BACK_ANGLE + CALF_STRAIGHTEN_ANGLE)
local FOOT_BACK_SPEED = THIGH_BACK_SPEED + CALF_STRAIGHTEN_SPEED
local BODY_TILT_ANGLE = math.rad(5)
local BODY_TILT_SPEED = math.rad(10)
local BODY_RISE_HEIGHT = 4
local BODY_LOWER_HEIGHT = 2
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
local SIG_DEPLOY = 2

--------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------
-- Create beacon animation and delay

local function Create_Beacon_Thread(x,z)
	local y = Spring.GetGroundHeight(x,z) or 0
	
	activity_mode(3)
	
	Turn( body , y_axis, math.rad(120), math.rad(80) )
	for i = 1, 15 do
		Sleep(100)
		Spring.SpawnCEG("teleport_progress", x, y, z, 0, 0, 0, 0)
	end
	Turn( body , y_axis, math.rad(240), math.rad(80) )
	for i = 1, 15 do
		Sleep(100)
		Spring.SpawnCEG("teleport_progress", x, y, z, 0, 0, 0, 0)
	end
	Turn( body , y_axis, math.rad(0), math.rad(80) )
	for i = 1, 15 do
		Sleep(100)
		Spring.SpawnCEG("teleport_progress", x, y, z, 0, 0, 0, 0)
	end

	Spring.MoveCtrl.Disable(unitID)
	GG.tele_createBeacon(unitID,x,z)
	
	Spring.SpawnCEG("teleport_in", x, y, z, 0, 0, 0, 1)
	
	activity_mode(1)
end

function Create_Beacon(x,z)
	Signal(SIG_WALK)
	StartThread(Create_Beacon_Thread,x,z)
end

--------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------
-- Deploy into static mode animation and delay

local deployed = false
local DEPLOY_SPEED = 0.3

local function DeployTeleport_Thread()
	
	SetSignalMask(SIG_DEPLOY)
	
	Turn( rthigh , x_axis, 0, math.rad(1000)  )
	Turn( rshin , x_axis, 0, math.rad(1000)  )
	Turn( rfoot , x_axis, 0, math.rad(1000)  )
	Turn( lthigh , x_axis, 0, math.rad(1000)  )
	Turn( lshin , x_axis, 0, math.rad(1000)  )
	Turn( lfoot , x_axis, 0, math.rad(1000)  )
	Turn( pelvis , z_axis, 0, math.rad(1000)  )
	Move( pelvis , y_axis, 0, 10 )
	
	Sleep(33)
	Spring.GiveOrderToUnit(unitID, CMD.WAIT, {}, {})
	
	Sleep(33)
	Turn( body , x_axis, math.rad(90), math.rad(90*DEPLOY_SPEED)  )
	Move( pelvis , y_axis, 11, 11*DEPLOY_SPEED )
	Move( pelvis , z_axis, -6, 6*DEPLOY_SPEED )
	
	Turn( rthigh , x_axis, math.rad(-50), math.rad(50*DEPLOY_SPEED)  )
	Turn( rshin , x_axis, math.rad(70), math.rad(70*DEPLOY_SPEED)  )
	Turn( rfoot , x_axis, math.rad(-15), math.rad(15*DEPLOY_SPEED)  )
	
	Turn( lthigh , x_axis, math.rad(-50), math.rad(50*DEPLOY_SPEED)  )
	Turn( lshin , x_axis, math.rad(70), math.rad(70*DEPLOY_SPEED)  )
	Turn( lfoot , x_axis, math.rad(-15), math.rad(15*DEPLOY_SPEED)  )

	Sleep(1000/DEPLOY_SPEED)
	
	GG.tele_deployTeleport(unitID)
	--Turn( pelvis , z_axis, 0, math.rad(20)*PACE  )
	--Move( pelvis , y_axis, 0, 12*PACE )

end

function DeployTeleport()
	if GG.tele_ableToDeploy(unitID) then
		deployed = true
		Signal(SIG_WALK)
		StartThread(DeployTeleport_Thread)
	end
end

function UndeployTeleport()
	deployed = false
	Turn( body , x_axis, math.rad(0), math.rad(90))
	Move( body , z_axis, 0, 5 )
	Turn( rthigh , x_axis, 0, math.rad(80)  )
	Turn( rshin , x_axis, 0, math.rad(120)  )
	Turn( rfoot , x_axis, 0, math.rad(80)  )
	Turn( lthigh , x_axis, 0, math.rad(80)  )
	Turn( lshin , x_axis, 0, math.rad(80)  )
	Turn( lfoot , x_axis, 0, math.rad(80)  )
	Turn( pelvis , z_axis, 0, math.rad(20)  )
	Move( pelvis , y_axis, 0, 12 )
end


--------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------
-- Ball animation
local spinmodes = {
	[1] = {holder = 30, sphere = 25},
	[2] = {holder = 50, sphere = 45},
	[3] = {holder = 100, sphere = 130},
}

local holderDirection = plusOrMinusOne()
local mode

function activity_mode(n)
	if (not mode) or mode ~= n then
		--Spring.Echo(n)
		if n < 2 then
			SetUnitValue(COB.ACTIVATION, 0)
		elseif mode < 2 then
			SetUnitValue(COB.ACTIVATION, 1)
		end
                
		Spin(holder, z_axis, math.rad(spinmodes[n].holder*holderDirection) )
		Spin(sphere, x_axis, math.rad((math.random(spinmodes[n].sphere)+spinmodes[n].sphere)*plusOrMinusOne()))
		Spin(sphere, y_axis, math.rad((math.random(spinmodes[n].sphere)+spinmodes[n].sphere)*plusOrMinusOne()))
		Spin(sphere, z_axis, math.rad((math.random(spinmodes[n].sphere)+spinmodes[n].sphere)*plusOrMinusOne()))
		mode = n
	end
end

--------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------
-- four-stroke bipedal (reverse-jointed) walkscript

local function Walk()
	
	Turn( body , x_axis, math.rad(0), math.rad(90))
	Move( body , z_axis, 0, 5 )
	
	Signal(SIG_DEPLOY)
	Signal(SIG_WALK)
	SetSignalMask(SIG_WALK)
	while true do
		local speed =  1 - (Spring.GetUnitRulesParam(unitID,"slowState") or 0)
		
		Turn(pelvis, z_axis, math.rad(5), math.rad(5))
		
		Turn(rthigh, x_axis, math.rad(-70), math.rad(80))
		
		Sleep(1000)
		
		Turn(pelvis, z_axis, math.rad(-5), math.rad(5))
		
		Turn(rthigh, x_axis, math.rad(10), math.rad(80))
		
		Sleep(1000)
		
		--[[
		--straighten left leg and draw it back, raise body, center right leg
		Move(pelvis, y_axis, BODY_RISE_HEIGHT, BODY_RISE_SPEED*speed)
		Turn(pelvis, z_axis, BODY_TILT_ANGLE, BODY_TILT_SPEED*speed)
		Turn(lthigh, x_axis, THIGH_BACK_ANGLE, THIGH_BACK_SPEED*speed)
		Turn(lshin, x_axis, CALF_STRAIGHTEN_ANGLE, CALF_STRAIGHTEN_SPEED*speed)
		Turn(lfoot, x_axis, FOOT_BACK_ANGLE, FOOT_BACK_SPEED*speed)		
		Turn(rthigh, x_axis, 0, THIGH_FRONT_SPEED*speed)
		Turn(rshin, x_axis, 0, CALF_RETRACT_SPEED*speed)
		Turn(rfoot, x_axis, 0, FOOT_FRONT_SPEED*speed)
		WaitForTurn(lthigh, x_axis)
		Sleep(0)
		
		-- lower body, draw right leg forwards
		Move(pelvis, y_axis, BODY_LOWER_HEIGHT, BODY_RISE_SPEED*speed)
		Turn(pelvis, z_axis, 0, BODY_TILT_SPEED*speed)
		--Turn(lshin, x_axis, CALF_STRAIGHTEN_ANGLE, CALF_STRAIGHTEN_SPEED)
		Turn(rthigh, x_axis, THIGH_FRONT_ANGLE, THIGH_FRONT_SPEED*speed)
		Turn(rfoot, x_axis, FOOT_FRONT_ANGLE, FOOT_FRONT_SPEED*speed)	
		WaitForMove(pelvis, y_axis)
		Sleep(0)
		
		--straighten right leg and draw it back, raise body, center left leg
		Move(pelvis, y_axis, BODY_RISE_HEIGHT, BODY_RISE_SPEED*speed)
		Turn(pelvis, z_axis, -BODY_TILT_ANGLE, BODY_TILT_SPEED*speed)
		Turn(lthigh, x_axis, 0, THIGH_FRONT_SPEED*speed)
		Turn(lshin, x_axis, 0, CALF_RETRACT_SPEED*speed)
		Turn(lfoot, x_axis, 0, FOOT_FRONT_SPEED*speed)		
		Turn(rthigh, x_axis, THIGH_BACK_ANGLE, THIGH_BACK_SPEED*speed)
		Turn(rshin, x_axis, CALF_STRAIGHTEN_ANGLE, CALF_STRAIGHTEN_SPEED*speed)
		Turn(rfoot, x_axis, FOOT_BACK_ANGLE, FOOT_BACK_SPEED*speed)		
		WaitForTurn(rthigh, x_axis)
		Sleep(0)
		
		-- lower body, draw left leg forwards
		Move(pelvis, y_axis, BODY_LOWER_HEIGHT, BODY_RISE_SPEED*speed)
		Turn(pelvis, z_axis, 0, BODY_TILT_SPEED*speed)
		Turn(lthigh, x_axis, THIGH_FRONT_ANGLE, THIGH_FRONT_SPEED*speed)
		Turn(lfoot, x_axis, FOOT_FRONT_ANGLE, FOOT_FRONT_SPEED*speed)			
		--Turn(rshin, x_axis, CALF_STRAIGHTEN_ANGLE, CALF_STRAIGHTEN_SPEED)
		WaitForMove(pelvis, y_axis)
		Sleep(0)--]]
	end
end

function script.StartMoving()
	deployed = false
	GG.tele_undeployTeleport(unitID)
	StartThread(Walk)
end

function script.StopMoving()
	Signal(SIG_WALK)
	if not deployed then
		Turn( rthigh , x_axis, 0, math.rad(80)*PACE  )
		Turn( rshin , x_axis, 0, math.rad(120)*PACE  )
		Turn( rfoot , x_axis, 0, math.rad(80)*PACE  )
		Turn( lthigh , x_axis, 0, math.rad(80)*PACE  )
		Turn( lshin , x_axis, 0, math.rad(80)*PACE  )
		Turn( lfoot , x_axis, 0, math.rad(80)*PACE  )
		Turn( pelvis , z_axis, 0, math.rad(20)*PACE  )
		Move( pelvis , y_axis, 0, 12*PACE )
	end
end

function script.Create()
	StartThread(SmokeUnit)
	--StartThread(Walk)
	activity_mode(1)
end


function script.Killed(recentDamage, maxHealth)
	local severity = recentDamage/maxHealth
    if severity <= 50 then
		Explode(lfoot, sfxNone)
		Explode(lshin, sfxNone)
		Explode(lthigh, sfxNone)
		Explode(rfoot, sfxNone)
		Explode(rshin, sfxNone)
		Explode(rthigh, sfxNone)
		Explode(body, sfxNone)
		Explode(sphere, sfxFall)
		return 1
	elseif severity <= 99 then
		Explode(lfoot, sfxFall)
		Explode(lshin, sfxFall)
		Explode(lthigh, sfxFall)
		Explode(rfoot, sfxFall)
		Explode(rshin, sfxFall)
		Explode(rthigh, sfxFall)
		Explode(body, sfxShatter)
		Explode(sphere, sfxFall)
		return 2
	else
		Explode(lfoot, sfxFall + sfxSmoke  + sfxFire  + sfxExplode )
		Explode(lshin, sfxFall + sfxSmoke  + sfxFire  + sfxExplode )
		Explode(lthigh, sfxFall + sfxSmoke  + sfxFire  + sfxExplode )
		Explode(rfoot, sfxFall + sfxSmoke  + sfxFire  + sfxExplode )
		Explode(rshin, sfxFall + sfxSmoke  + sfxFire  + sfxExplode )
		Explode(rthigh, sfxFall + sfxSmoke  + sfxFire  + sfxExplode )
		Explode(body, sfxShatter + sfxExplode )
		Explode(sphere, sfxFall)
		return 2
	end
end