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
local SPEED = 3

local SIG_WALK = 1
local SIG_DEPLOY = 2
local SIG_BEACON = 2

--------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------
-- Create beacon animation and delay

local function Create_Beacon_Thread(x,z)
	local y = Spring.GetGroundHeight(x,z) or 0
	
	Signal(SIG_DEPLOY)
	Signal(SIG_BEACON)
	Signal(SIG_WALK)
	SetSignalMask(SIG_BEACON)
	
	activity_mode(3)
	
	Turn( body , y_axis, math.rad(120), math.rad(80) )
	Spring.PlaySoundFile("sounds/misc/teleport_loop.wav", 3, x, y, z)
	for i = 1, 15 do
		Sleep(100)
		Spring.SpawnCEG("teleport_progress", x, y, z, 0, 0, 0, 0)
	end
	Turn( body , y_axis, math.rad(240), math.rad(80) )
	Spring.PlaySoundFile("sounds/misc/teleport_loop.wav", 3, x, y, z)
	for i = 1, 15 do
		Sleep(100)
		Spring.SpawnCEG("teleport_progress", x, y, z, 0, 0, 0, 0)
	end
	Turn( body , y_axis, math.rad(0), math.rad(80) )
	Spring.PlaySoundFile("sounds/misc/teleport_loop.wav", 3, x, y, z)
	for i = 1, 15 do
		Sleep(100)
		Spring.SpawnCEG("teleport_progress", x, y, z, 0, 0, 0, 0)
	end

	Spring.MoveCtrl.Disable(unitID)
	GG.tele_createBeacon(unitID,x,z)
	
	Spring.SpawnCEG("teleport_in", x, y, z, 0, 0, 0, 1)
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
	
	Signal(SIG_DEPLOY)
	Signal(SIG_BEACON)
	Signal(SIG_WALK)
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
	
end

function DeployTeleport()
	if GG.tele_ableToDeploy(unitID) then
		deployed = true
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
	Turn( body , y_axis, math.rad(0), math.rad(80) )
	
	Signal(SIG_DEPLOY)
	Signal(SIG_BEACON)
	Signal(SIG_WALK)
	SetSignalMask(SIG_WALK)
	while true do
		local speedmult = (1 - (Spring.GetUnitRulesParam(unitID,"slowState") or 0))*SPEED
		
		Turn(pelvis, z_axis,  math.rad(0), math.rad(2)*speedmult)
		Move(pelvis, y_axis, 2, 1.5*speedmult)
		
		-- Right leg mid
		Turn(rthigh, x_axis, math.rad(-15), math.rad(35)*speedmult)
		Turn(rshin, x_axis, math.rad(0), math.rad(15)*speedmult)
		Turn(rfoot, x_axis, math.rad(15), math.rad(20)*speedmult)
		
		-- Left leg raise
		Turn(lthigh, x_axis, math.rad(-10), math.rad(15)*speedmult)
		Turn(lshin, x_axis, math.rad(-25), math.rad(50)*speedmult)
		Turn(lfoot, x_axis, math.rad(-25), math.rad(5)*speedmult)
		
		Sleep(1000/speedmult)
		
		Turn(pelvis, z_axis,  math.rad(2), math.rad(2)*speedmult)
		Move(pelvis, y_axis, 3.5, 1.5*speedmult)
		
		-- Right leg back
		Turn(rthigh, x_axis, math.rad(5), math.rad(20)*speedmult)
		Turn(rshin, x_axis, math.rad(25), math.rad(25)*speedmult)
		Turn(rfoot, x_axis, math.rad(-30), math.rad(45)*speedmult)
		
		-- Left foot forward
		Turn(lthigh, x_axis, math.rad(-50), math.rad(40)*speedmult)
		Turn(lshin, x_axis, math.rad(15), math.rad(40)*speedmult)
		Turn(lfoot, x_axis, math.rad(35), math.rad(60)*speedmult)
		
		Sleep(1000/speedmult)
		
		Turn(pelvis, z_axis,  math.rad(0), math.rad(2)*speedmult)
		Move(pelvis, y_axis, 2, 1.5*speedmult)
		
		-- Right leg raise
		Turn(rthigh, x_axis, math.rad(-10), math.rad(15)*speedmult)
		Turn(rshin, x_axis, math.rad(-25), math.rad(50)*speedmult)
		Turn(rfoot, x_axis, math.rad(-25), math.rad(5)*speedmult)
		
		-- Left leg mid
		Turn(lthigh, x_axis, math.rad(-15), math.rad(35)*speedmult)
		Turn(lshin, x_axis, math.rad(0), math.rad(15)*speedmult)
		Turn(lfoot, x_axis, math.rad(15), math.rad(20)*speedmult)
		
		Sleep(1000/speedmult)
		
		Turn(pelvis, z_axis, math.rad(-2), math.rad(2)*speedmult)
		Move(pelvis, y_axis, 3.5, 1.5)
		
		-- Right foot forward
		Turn(rthigh, x_axis, math.rad(-50), math.rad(40)*speedmult)
		Turn(rshin, x_axis, math.rad(15), math.rad(40)*speedmult)
		Turn(rfoot, x_axis, math.rad(35), math.rad(60)*speedmult)
		
		-- Left leg back
		Turn(lthigh, x_axis, math.rad(5), math.rad(20)*speedmult)
		Turn(lshin, x_axis, math.rad(25), math.rad(25)*speedmult)
		Turn(lfoot, x_axis, math.rad(-30), math.rad(45)*speedmult)
		
		Sleep(1000/speedmult)
		
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
		Turn( rthigh , x_axis, 0, math.rad(80)  )
		Turn( rshin , x_axis, 0, math.rad(120)  )
		Turn( rfoot , x_axis, 0, math.rad(80)  )
		Turn( lthigh , x_axis, 0, math.rad(80)  )
		Turn( lshin , x_axis, 0, math.rad(80)  )
		Turn( lfoot , x_axis, 0, math.rad(80)  )
		Turn( pelvis , z_axis, 0, math.rad(20)  )
		Move( pelvis , y_axis, 0, 12 )
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