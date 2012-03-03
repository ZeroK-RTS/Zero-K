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
local PERIOD = 0.4
local PACE = 1.5

local THIGH_FRONT_ANGLE = math.rad(-50)
local THIGH_BACK_ANGLE = math.rad(0)
local THIGH_FRONT_SPEED = math.rad(50)/PERIOD
local THIGH_BACK_SPEED =  math.rad(50)/PERIOD

local CALF_RETRACT_ANGLE = math.rad(0)
local CALF_STRAIGHTEN_ANGLE = math.rad(50)
local CALF_RETRACT_SPEED = math.rad(50)/PERIOD*2
local CALF_STRAIGHTEN_SPEED = math.rad(50)/PERIOD*2

local FOOT_FRONT_ANGLE = -THIGH_FRONT_ANGLE - math.rad(20)
local FOOT_BACK_ANGLE = -(THIGH_BACK_ANGLE + CALF_STRAIGHTEN_ANGLE)
local FOOT_FRONT_SPEED = FOOT_FRONT_ANGLE-FOOT_BACK_ANGLE/PERIOD*1.5
local FOOT_BACK_SPEED = FOOT_FRONT_ANGLE-FOOT_BACK_ANGLE/PERIOD*1.5

local BODY_TILT_ANGLE = math.rad(5)
local BODY_TILT_SPEED = BODY_TILT_ANGLE/PERIOD * 2
local BODY_RISE_HEIGHT = 2
local BODY_LOWER_HEIGHT = 0
local BODY_RISE_SPEED = (BODY_RISE_HEIGHT - BODY_LOWER_HEIGHT)/PERIOD*2

local SIG_WALK = 1
local SIG_CHANGE_MODE = 2

--PERIOD = PERIOD + 0.001

--------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------
-- Create beacon animation and delay

local function Create_Beacon_Thread(x,z)
	local y = Spring.GetGroundHeight(x,z) or 0
	
	local dx, dy, dz = Spring.GetUnitDirection(unitID)
	local ux, uy, uz = Spring.GetUnitBasePosition(unitID)
	
	local nx, ny, nz = Spring.GetGroundNormal(ux,uz)
	
	Turn( body , z_axis, math.rad(120), math.rad(80) )
	Sleep(1500)
	Turn( body , z_axis, math.rad(240), math.rad(80) )
	Sleep(1500)
	Turn( body , z_axis, math.rad(0), math.rad(80) )
	Sleep(1500)

	Spring.MoveCtrl.Disable(unitID)
	GG.tele_createBeacon(unitID,x,z)
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
	Turn( rthigh , x_axis, 0, math.rad(80)*PACE  )
	Turn( rshin , x_axis, 0, math.rad(120)*PACE  )
	Turn( rfoot , x_axis, 0, math.rad(80)*PACE  )
	Turn( lthigh , x_axis, 0, math.rad(80)*PACE  )
	Turn( lshin , x_axis, 0, math.rad(80)*PACE  )
	Turn( lfoot , x_axis, 0, math.rad(80)*PACE  )
	Turn( pelvis , z_axis, 0, math.rad(20)*PACE  )
	Move( pelvis , y_axis, 0, 12*PACE )
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
                else
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

	Signal(SIG_WALK)
	SetSignalMask(SIG_WALK)
	while true do
		local speed =  1 - (Spring.GetUnitRulesParam(unitID,"slowState") or 0)
		--straighten left leg and draw it back, raise body, center right leg
		Move(pelvis, y_axis, BODY_RISE_HEIGHT, BODY_RISE_SPEED*speed)
		Turn(pelvis, z_axis, BODY_TILT_ANGLE, BODY_TILT_SPEED*speed)
		Turn(lthigh, x_axis, THIGH_BACK_ANGLE, THIGH_BACK_SPEED*speed)
		Turn(lshin, x_axis, CALF_STRAIGHTEN_ANGLE, CALF_STRAIGHTEN_SPEED*speed)
		Turn(lfoot, x_axis, FOOT_BACK_ANGLE, FOOT_BACK_SPEED*speed)		
		Turn(rthigh, x_axis, 0, THIGH_FRONT_SPEED*speed)
		Turn(rshin, x_axis, 0, CALF_RETRACT_SPEED*speed)
		Turn(rfoot, x_axis, 0, FOOT_FRONT_SPEED*speed)
		Sleep(PERIOD * 1000/speed)
		
		-- lower body, draw right leg forwards
		Move(pelvis, y_axis, BODY_LOWER_HEIGHT, BODY_RISE_SPEED*speed)
		Turn(pelvis, z_axis, 0, BODY_TILT_SPEED*speed)
		--Turn(lshin, x_axis, CALF_STRAIGHTEN_ANGLE, CALF_STRAIGHTEN_SPEED*speed)
		Turn(rthigh, x_axis, THIGH_FRONT_ANGLE, THIGH_FRONT_SPEED*speed)
		Turn(rfoot, x_axis, FOOT_FRONT_ANGLE, FOOT_FRONT_SPEED*speed)	
		Sleep(PERIOD * 1000/speed/2)
		
		--straighten right leg and draw it back, raise body, center left leg
		Move(pelvis, y_axis, BODY_RISE_HEIGHT, BODY_RISE_SPEED*speed)
		Turn(pelvis, z_axis, -BODY_TILT_ANGLE, BODY_TILT_SPEED*speed)
		Turn(lthigh, x_axis, 0, THIGH_FRONT_SPEED*speed)
		Turn(lshin, x_axis, 0, CALF_RETRACT_SPEED*speed)
		Turn(lfoot, x_axis, 0, FOOT_FRONT_SPEED*speed)		
		Turn(rthigh, x_axis, THIGH_BACK_ANGLE, THIGH_BACK_SPEED*speed)
		Turn(rshin, x_axis, CALF_STRAIGHTEN_ANGLE, CALF_STRAIGHTEN_SPEED*speed)
		Turn(rfoot, x_axis, FOOT_BACK_ANGLE, FOOT_BACK_SPEED*speed)		
		Sleep(PERIOD * 1000/speed)
		
		-- lower body, draw left leg forwards
		Move(pelvis, y_axis, BODY_LOWER_HEIGHT, BODY_RISE_SPEED*speed)
		Turn(pelvis, z_axis, 0, BODY_TILT_SPEED*speed)
		Turn(lthigh, x_axis, THIGH_FRONT_ANGLE, THIGH_FRONT_SPEED*speed)
		Turn(lfoot, x_axis, FOOT_FRONT_ANGLE, FOOT_FRONT_SPEED*speed)			
		--Turn(rshin, x_axis, CALF_STRAIGHTEN_ANGLE, CALF_STRAIGHTEN_SPEED*speed)
		Sleep(PERIOD * 1000/speed/2)
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
	StartThread(Walk)
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