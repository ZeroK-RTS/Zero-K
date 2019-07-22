--linear constant 65536

include "constants.lua"
include "utility.lua"
include 'letsNotFailAtTrig.lua'

local base, pelvis, body = piece('base', 'pelvis', 'body')
local rthigh, rshin, rfoot, lthigh, lshin, lfoot = piece('rthigh', 'rshin', 'rfoot', 'lthigh', 'lshin', 'lfoot')
local holder, sphere = piece('holder', 'sphere') 

local smokePiece = {pelvis}
--------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------
local SPEED = 3.6

local SIG_WALK = 1
local SIG_DEPLOY = 2
local SIG_BEACON = 2

local PRIVATE = {private = true}
local INLOS = {inlos = true}

local deployed = false
local beaconCreateX, beaconCreateZ

--------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------
-- Create beacon animation and delay
local spGetUnitRulesParam = Spring.GetUnitRulesParam
local BEACON_SPAWN_SPEED = 9 / tonumber(UnitDef.customParams.teleporter_beacon_spawn_time)


local function Create_Beacon_Thread(x,z)
	local y = Spring.GetGroundHeight(x,z) or 0
	
	Signal(SIG_DEPLOY)
	Signal(SIG_BEACON)
	Signal(SIG_WALK)
	SetSignalMask(SIG_BEACON)
	
	beaconCreateX, beaconCreateZ = x, z
	Spring.SetUnitRulesParam(unitID, "tele_creating_beacon_x", x, PRIVATE)
	Spring.SetUnitRulesParam(unitID, "tele_creating_beacon_z", z, PRIVATE)
	
	activity_mode(3)
	
	GG.PlayFogHiddenSound("sounds/misc/teleport_loop.wav", 3, x, y, z)
	for i = 1, 90 do
		local speedMult = (spGetUnitRulesParam(unitID,"baseSpeedMult") or 1) * BEACON_SPAWN_SPEED
		Turn(body, y_axis, math.rad(i*4), math.rad(40*speedMult))
		Sleep(100/speedMult)
		if i == 1 then
			Spring.GiveOrderToUnit(unitID, CMD.WAIT, {}, {})
			Spring.GiveOrderToUnit(unitID, CMD.WAIT, {}, {})
		end
		local stunnedOrInbuild = Spring.GetUnitIsStunned(unitID)
		local disarm = spGetUnitRulesParam(unitID,"disarmed") == 1
		while stunnedOrInbuild or disarm do
			Sleep(100)
			stunnedOrInbuild = Spring.GetUnitIsStunned(unitID)
			disarm = spGetUnitRulesParam(unitID,"disarmed") == 1
		end
		Spring.SpawnCEG("teleport_progress", x, y + 14, z, 0, 0, 0, 0)
		if i == 30 or i == 60 then
			GG.PlayFogHiddenSound("sounds/misc/teleport_loop.wav", 3, x, y, z)
		end
	end

	GG.tele_createBeacon(unitID,x,z)
	
	Spring.SetUnitRulesParam(unitID, "tele_creating_beacon_x", nil, PRIVATE)
	Spring.SetUnitRulesParam(unitID, "tele_creating_beacon_z", nil, PRIVATE)
	beaconCreateX, beaconCreateZ = nil, nil
	
	Spring.SpawnCEG("teleport_in", x, y, z, 0, 0, 0, 1)
	
	DeployTeleport()
end

function StopCreateBeacon(resetAnimation)
	Signal(SIG_BEACON)
	if beaconCreateX then
		Spring.SetUnitRulesParam(unitID, "tele_creating_beacon_x", nil, PRIVATE)
		Spring.SetUnitRulesParam(unitID, "tele_creating_beacon_z", nil, PRIVATE)
		beaconCreateX, beaconCreateZ = nil, nil
		Turn(body, y_axis, 0, math.rad(40))
		activity_mode(deployed and 3 or 1)
	end
end

function Create_Beacon(x,z)
	if x == beaconCreateX and z == beaconCreateZ then
		return
	end
	Signal(SIG_WALK)
	StartThread(Create_Beacon_Thread,x,z)
end

--------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------
-- Deploy into static mode animation and delay
local DEPLOY_SPEED = 0.3

local function DeployTeleport_Thread()
	
	Signal(SIG_DEPLOY)
	StopCreateBeacon()
	Signal(SIG_WALK)
	SetSignalMask(SIG_DEPLOY)
	
	Turn(rthigh, x_axis, 0, math.rad(1000))
	Turn(rshin, x_axis, 0, math.rad(1000))
	Turn(rfoot, x_axis, 0, math.rad(1000))
	Turn(lthigh, x_axis, 0, math.rad(1000))
	Turn(lshin, x_axis, 0, math.rad(1000))
	Turn(lfoot, x_axis, 0, math.rad(1000))
	Turn(pelvis, z_axis, 0, math.rad(1000))
	Move(pelvis, y_axis, 0, 10)
	
	Sleep(33)
	
	Sleep(33)
	Turn(body, x_axis, math.rad(90), math.rad(90*DEPLOY_SPEED))
	Move(pelvis, y_axis, 11, 11*DEPLOY_SPEED)
	Move(pelvis, z_axis, -6, 6*DEPLOY_SPEED)
	
	Turn(rthigh, x_axis, math.rad(-50), math.rad(50*DEPLOY_SPEED))
	Turn(rshin, x_axis, math.rad(70), math.rad(70*DEPLOY_SPEED))
	Turn(rfoot, x_axis, math.rad(-15), math.rad(15*DEPLOY_SPEED))
	
	Turn(lthigh, x_axis, math.rad(-50), math.rad(50*DEPLOY_SPEED))
	Turn(lshin, x_axis, math.rad(70), math.rad(70*DEPLOY_SPEED))
	Turn(lfoot, x_axis, math.rad(-15), math.rad(15*DEPLOY_SPEED))

	Sleep(1000/DEPLOY_SPEED)

	if not Spring.GetUnitIsDead(unitID) then
		-- script threads, like Cthulhu, can sleep while dead and still perform work after waking up
		-- this is by design, think death animations
		GG.tele_deployTeleport(unitID)
	end
end

function DeployTeleport()
	if GG.tele_ableToDeploy(unitID) then
		deployed = true
		StartThread(DeployTeleport_Thread)
	end
end

function DeployTeleportInstant()
	if GG.tele_ableToDeploy(unitID) then
		deployed = true
		Turn(rthigh, x_axis, 0)
		Turn(rshin, x_axis, 0)
		Turn(rfoot, x_axis, 0)
		Turn(lthigh, x_axis, 0)
		Turn(lshin, x_axis, 0)
		Turn(lfoot, x_axis, 0)
		Turn(pelvis, z_axis, 0)
		Move(pelvis, y_axis, 0)
		
		Turn(body, x_axis, math.rad(90))
		Move(pelvis, y_axis, 11)
		Move(pelvis, z_axis, -6)
		
		Turn(rthigh, x_axis, math.rad(-50))
		Turn(rshin, x_axis, math.rad(70))
		Turn(rfoot, x_axis, math.rad(-15))
		
		Turn(lthigh, x_axis, math.rad(-50))
		Turn(lshin, x_axis, math.rad(70))
		Turn(lfoot, x_axis, math.rad(-15))
		
		GG.tele_deployTeleport(unitID)
	end
end

function UndeployTeleport()
	deployed = false
	Turn(body, x_axis, math.rad(0), math.rad(90))
	Move(body, z_axis, 0, 5)
	Turn(rthigh, x_axis, 0, math.rad(80))
	Turn(rshin, x_axis, 0, math.rad(120))
	Turn(rfoot, x_axis, 0, math.rad(80))
	Turn(lthigh, x_axis, 0, math.rad(80))
	Turn(lshin, x_axis, 0, math.rad(80))
	Turn(lfoot, x_axis, 0, math.rad(80))
	Turn(pelvis, z_axis, 0, math.rad(20))
	Move(pelvis, y_axis, 0, 12)
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
			Spring.SetUnitRulesParam(unitID, "teleActive", 0, INLOS)
		elseif mode < 2 then
			Spring.SetUnitRulesParam(unitID, "teleActive", 1, INLOS)
		end

		Spin(holder, z_axis, math.rad(spinmodes[n].holder*holderDirection))
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
	
	Turn(body, x_axis, math.rad(0), math.rad(90))
	Move(body, z_axis, 0, 5)
	Turn(body, y_axis, math.rad(0), math.rad(80))
	
	Signal(SIG_DEPLOY)
	StopCreateBeacon()
	Signal(SIG_WALK)
	SetSignalMask(SIG_WALK)
	while true do
		local speedmult = (Spring.GetUnitRulesParam(unitID,"baseSpeedMult") or 1)*SPEED
		
		Turn(pelvis, z_axis, math.rad(0), math.rad(2)*speedmult)
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
		
		Turn(pelvis, z_axis, math.rad(2), math.rad(2)*speedmult)
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
		
		Turn(pelvis, z_axis, math.rad(0), math.rad(2)*speedmult)
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

local function Stopping()
	Signal(SIG_WALK)
	SetSignalMask(SIG_WALK)
	if not deployed then
		Turn(rthigh, x_axis, 0, math.rad(80))
		Turn(rshin, x_axis, 0, math.rad(120))
		Turn(rfoot, x_axis, 0, math.rad(80))
		Turn(lthigh, x_axis, 0, math.rad(80))
		Turn(lshin, x_axis, 0, math.rad(80))
		Turn(lfoot, x_axis, 0, math.rad(80))
		Turn(pelvis, z_axis, 0, math.rad(20))
		Move(pelvis, y_axis, 0, 12)
	end
	DeployTeleport()
end

function script.StartMoving()
	deployed = false
	GG.tele_undeployTeleport(unitID)
	StartThread(Walk)
end

function script.StopMoving()
	Signal(SIG_WALK)
	StartThread(Stopping)
end

function script.Create()
	StartThread(GG.Script.SmokeUnit, smokePiece)
	--StartThread(Walk)
	activity_mode(1)
end


function script.Killed(recentDamage, maxHealth)
	local severity = recentDamage/maxHealth
		if severity <= .50 then
		Explode(lfoot, SFX.NONE)
		Explode(lshin, SFX.NONE)
		Explode(lthigh, SFX.NONE)
		Explode(rfoot, SFX.NONE)
		Explode(rshin, SFX.NONE)
		Explode(rthigh, SFX.NONE)
		Explode(body, SFX.NONE)
		Explode(sphere, SFX.FALL)
		return 1
	elseif severity <= .99 then
		Explode(lfoot, SFX.FALL)
		Explode(lshin, SFX.FALL)
		Explode(lthigh, SFX.FALL)
		Explode(rfoot, SFX.FALL)
		Explode(rshin, SFX.FALL)
		Explode(rthigh, SFX.FALL)
		Explode(body, SFX.SHATTER)
		Explode(sphere, SFX.FALL)
		return 2
	else
		Explode(lfoot, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE)
		Explode(lshin, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE)
		Explode(lthigh, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE)
		Explode(rfoot, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE)
		Explode(rshin, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE)
		Explode(rthigh, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE)
		Explode(body, SFX.SHATTER + SFX.EXPLODE)
		Explode(sphere, SFX.FALL)
		return 2
	end
end
