include "constants.lua"

local dyncomm = include('dynamicCommander.lua')
_G.dyncomm = dyncomm

local spSetUnitShieldState = Spring.SetUnitShieldState

-- pieces
local base = piece 'base'
local shield = piece 'shield'
local pelvis = piece 'pelvis'
local turret = piece 'turret'
local torso = piece 'torso'
local head = piece 'head'
local armhold = piece 'armhold'
local ruparm = piece 'ruparm'
local rarm = piece 'rarm'
local rloarm = piece 'rloarm'
local luparm = piece 'luparm'
local larm = piece 'larm'
local lloarm = piece 'lloarm'
local rupleg = piece 'rupleg'
local lupleg = piece 'lupleg'
local lloleg = piece 'lloleg'
local rloleg = piece 'rloleg'
local rfoot = piece 'rfoot'
local lfoot = piece 'lfoot'
local gun = piece 'gun'
local flare = piece 'flare'
local rhand = piece 'rhand'
local lhand = piece 'lhand'
local gunpod = piece 'gunpod'
local ac1 = piece 'ac1'
local ac2 = piece 'ac2'
local nanospray = piece 'nanospray'

local smokePiece = {torso}
local nanoPieces = {nanospray}

--------------------------------------------------------------------------------
-- constants
--------------------------------------------------------------------------------
local SIG_BUILD = 32
local SIG_RESTORE = 16
local SIG_AIM = 2
local SIG_AIM_2 = 4
local SIG_WALK = 1
--local SIG_AIM_3 = 8 --step on

--------------------------------------------------------------------------------
-- vars
--------------------------------------------------------------------------------
local restoreHeading, restorePitch = 0, 0

local canDgun = UnitDefs[unitDefID].canDgun

local dead = false
local bMoving = false
local bAiming = false
local inBuildAnim = false

local SPEEDUP_FACTOR = 1.1
local REF_TURN_SPEED = 185  -- deg/s
local walkTurnSpeed1 = 1
local walkSleepMult = 1.0
local walkAngleMult = 1.0
local animationSpeedMult = 1.0
local currentSpeed = 0
local REF_SPEED = 1
local sizeSpeedMult = 1.0

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
local function BuildDecloakThread()
	Signal(SIG_BUILD)
	SetSignalMask(SIG_BUILD)
	while true do
		GG.PokeDecloakUnit(unitID, 50)
		Sleep(1000)
	end
end

local function BuildPose(heading, pitch)
	inBuildAnim = true
	Turn(luparm, x_axis, math.rad(-60), math.rad(250))
	Turn(luparm, y_axis, math.rad(-15), math.rad(250))
	Turn(luparm, z_axis, math.rad(-10), math.rad(250))
	
	Turn(larm, x_axis, math.rad(5), math.rad(250))
	Turn(larm, y_axis, math.rad(30), math.rad(250))
	Turn(larm, z_axis, math.rad(-5), math.rad(250))
	
	Turn(lloarm, y_axis, math.rad(-37), math.rad(250))
	Turn(lloarm, z_axis, math.rad(-75), math.rad(450))
	Turn(gunpod, y_axis, math.rad(90), math.rad(350))
	
	Turn(turret, y_axis, heading, math.rad(350))
	Turn(lloarm, x_axis, -pitch, math.rad(250))
end

local function RestoreAfterDelay()
	Signal(SIG_RESTORE)
	SetSignalMask(SIG_RESTORE)
	Sleep(6000)
	if not dead then
		if GetUnitValue(COB.INBUILDSTANCE) == 1 then
			BuildPose(restoreHeading, restorePitch)
		else
			Turn(turret, x_axis, 0, math.rad(150))
			Turn(turret, y_axis, 0, math.rad(150))
			--torso
			Turn(torso, x_axis, 0, math.rad(250))
			Turn(torso, y_axis, 0, math.rad(250))
			Turn(torso, z_axis, 0, math.rad(250))
			--head
			Turn(head, x_axis, 0, math.rad(250))
			Turn(head, y_axis, 0, math.rad(250))
			Turn(head, z_axis, 0, math.rad(250))
			
			-- at ease pose
			Turn(armhold, x_axis, math.rad(-45), math.rad(250)) --upspring at -45
			Turn(ruparm, x_axis, 0, math.rad(250))
			Turn(ruparm, y_axis, 0, math.rad(250))
			Turn(ruparm, z_axis, 0, math.rad(250))
			Turn(rarm, x_axis, math.rad(2), math.rad(250))	 --up 2
			Turn(rarm, y_axis, 0, math.rad(250))
			Turn(rarm, z_axis, math.rad(12), math.rad(250))	--up -12
			Turn(rloarm, x_axis, math.rad(47), math.rad(250)) --up 47
			Turn(rloarm, y_axis, math.rad(76), math.rad(250)) --up 76
			Turn(rloarm, z_axis, math.rad(47), math.rad(250)) --up -47
			--left
			Turn(luparm, x_axis, math.rad(12), math.rad(250))	 --up -9
			Turn(luparm, y_axis, 0, math.rad(250))
			Turn(luparm, z_axis, 0, math.rad(250))
			Turn(larm, x_axis, math.rad(-35), math.rad(250))	 --up 5
			Turn(larm, y_axis, math.rad(-3), math.rad(250))	 --up -3
			Turn(larm, z_axis, math.rad(-(22)), math.rad(250))	 --up 22
			Turn(lloarm, x_axis, math.rad(92), math.rad(250))	-- up 82
			Turn(lloarm, y_axis, 0, math.rad(250))
			Turn(lloarm, z_axis, math.rad(-94), math.rad(250)) --upspring 94
			
			Turn(gun, x_axis, 0, math.rad(250))
			Turn(gun, y_axis, 0, math.rad(250))
			Turn(gun, z_axis, 0, math.rad(250))
			-- done at ease
			Sleep(100)
		end
		bAiming = false
	end
end

local function Walk()
	if (bMoving ) then
		Turn(pelvis, x_axis, math.rad(6), math.rad(30 * animationSpeedMult)) --tilt forward
		if not bAiming then
			Turn(torso, y_axis, math.rad(3.335165), math.rad(walkTurnSpeed1))
		end

		Move(pelvis, y_axis, 0)
		Turn(rupleg, x_axis, math.rad(5.670330)*walkAngleMult, math.rad(walkTurnSpeed1))
		Turn(lupleg, x_axis, math.rad(-26.467033)*walkAngleMult, math.rad(walkTurnSpeed1))
		Turn(lloleg, x_axis, math.rad(26.967033)*walkAngleMult, math.rad(walkTurnSpeed1))
		Turn(rloleg, x_axis, math.rad(26.967033)*walkAngleMult, math.rad(walkTurnSpeed1))
		Turn(rfoot, x_axis, math.rad(-19.824176)*walkAngleMult, math.rad(walkTurnSpeed1))
		Sleep(180 * walkSleepMult )
	end

	if (bMoving ) then
		if not bAiming then
			Turn(torso, y_axis, math.rad(1.681319), math.rad(walkTurnSpeed1))
		end
		Turn(rupleg, x_axis, math.rad(-5.269231)*walkAngleMult, math.rad(walkTurnSpeed1))
		Turn(lupleg, x_axis, math.rad(-20.989011)*walkAngleMult, math.rad(walkTurnSpeed1))
		Turn(lloleg, x_axis, math.rad(20.945055)*walkAngleMult, math.rad(walkTurnSpeed1))
		Turn(rloleg, x_axis, math.rad(41.368132)*walkAngleMult, math.rad(walkTurnSpeed1))
		Turn(rfoot, x_axis, math.rad(-15.747253)*walkAngleMult)
		Sleep(160 * walkSleepMult )
	end
	
	if (bMoving ) then
		Turn(pelvis, x_axis, math.rad(0), math.rad(30 * animationSpeedMult))
		if not bAiming then
			Turn(torso, y_axis, 0, math.rad(walkTurnSpeed1))
		end
		Turn(rupleg, x_axis, math.rad(-9.071429)*walkAngleMult, math.rad(walkTurnSpeed1))
		Turn(lupleg, x_axis, math.rad(-12.670330)*walkAngleMult, math.rad(walkTurnSpeed1))
		Turn(lloleg, x_axis, math.rad(12.670330)*walkAngleMult, math.rad(walkTurnSpeed1))
		Turn(rloleg, x_axis, math.rad(43.571429)*walkAngleMult, math.rad(walkTurnSpeed1))
		Turn(rfoot, x_axis, math.rad(-12.016484)*walkAngleMult, math.rad(walkTurnSpeed1))
		Sleep(140 * walkSleepMult )
	end

	if (bMoving ) then
		if not bAiming then
			Turn(torso, y_axis, math.rad(-1.77), math.rad(walkTurnSpeed1))
		end
		Turn(rupleg, x_axis, math.rad(-21.357143)*walkAngleMult, math.rad(walkTurnSpeed1))
		Turn(lupleg, x_axis, math.rad(2.824176)*walkAngleMult, math.rad(walkTurnSpeed1))
		Turn(lloleg, x_axis, math.rad(3.560440)*walkAngleMult, math.rad(walkTurnSpeed1))
		Turn(lfoot, x_axis, math.rad(-4.527473)*walkAngleMult, math.rad(walkTurnSpeed1))
		Turn(rloleg, x_axis, math.rad(52.505495)*walkAngleMult, math.rad(walkTurnSpeed1))
		Turn(rfoot, x_axis, 0)
		Sleep(140 * walkSleepMult )
	end

	if (bMoving ) then
		if not bAiming then
			Turn(torso, y_axis, math.rad(-3.15), math.rad(walkTurnSpeed1))
		end
		Turn(rupleg, x_axis, math.rad(-35.923077)*walkAngleMult, math.rad(walkTurnSpeed1))
		Turn(lupleg, x_axis, math.rad(7.780220)*walkAngleMult, math.rad(walkTurnSpeed1))
		Turn(lloleg, x_axis, math.rad(8.203297)*walkAngleMult, math.rad(walkTurnSpeed1))
		Turn(lfoot, x_axis, math.rad(-12.571429)*walkAngleMult, math.rad(walkTurnSpeed1))
		Turn(rloleg, x_axis, math.rad(54.390110)*walkAngleMult, math.rad(walkTurnSpeed1))
		Sleep(140 * walkSleepMult )
	end

	if (bMoving ) then
	
		Turn(pelvis, x_axis, math.rad(6), math.rad(30 * animationSpeedMult)) --tilt forward
		if not bAiming then
			Turn(torso, y_axis, math.rad(-4.21), math.rad(walkTurnSpeed1))
		end
		Turn(rupleg, x_axis, math.rad(-37.780220)*walkAngleMult, math.rad(walkTurnSpeed1))
		Turn(lupleg, x_axis, math.rad(10.137363)*walkAngleMult, math.rad(walkTurnSpeed1))
		Turn(lloleg, x_axis, math.rad(13.302198)*walkAngleMult, math.rad(walkTurnSpeed1))
		Turn(lfoot, x_axis, math.rad(-16.714286)*walkAngleMult, math.rad(walkTurnSpeed1))
		Turn(rloleg, x_axis, math.rad(32.582418)*walkAngleMult, math.rad(walkTurnSpeed1))
		Sleep(140 * walkSleepMult )
	end
	
	if (bMoving ) then
		if not bAiming then
			Turn(torso, y_axis, math.rad(-3.15), math.rad(walkTurnSpeed1))
		end
		Turn(rupleg, x_axis, math.rad(-28.758242)*walkAngleMult, math.rad(walkTurnSpeed1))
		Turn(lupleg, x_axis, math.rad(12.247253)*walkAngleMult, math.rad(walkTurnSpeed1))
		Turn(lloleg, x_axis, math.rad(19.659341)*walkAngleMult, math.rad(walkTurnSpeed1))
		Turn(lfoot, x_axis, math.rad(-19.659341)*walkAngleMult, math.rad(walkTurnSpeed1))
		Turn(rloleg, x_axis, math.rad(28.758242)*walkAngleMult, math.rad(walkTurnSpeed1))
		Sleep(160 * walkSleepMult )
	end

	if (bMoving ) then
		if not bAiming then
			Turn(torso, y_axis, math.rad(-1.88), math.rad(walkTurnSpeed1))
		end
		Turn(rupleg, x_axis, math.rad(-22.824176)*walkAngleMult, math.rad(walkTurnSpeed1))
		Turn(lupleg, x_axis, math.rad(2.824176)*walkAngleMult, math.rad(walkTurnSpeed1))
		Turn(lloleg, x_axis, math.rad(34.060440)*walkAngleMult, math.rad(walkTurnSpeed1))
		Turn(rfoot, x_axis, math.rad(-6.313187)*walkAngleMult, math.rad(walkTurnSpeed1))
		Sleep(160 * walkSleepMult )
	end
	
	if (bMoving ) then
		Turn(pelvis, x_axis, math.rad(0), math.rad(30 * animationSpeedMult))
		if not bAiming then
			Turn(torso, y_axis, 0, math.rad(walkTurnSpeed1))
		end
		Turn(rupleg, x_axis, math.rad(-11.604396)*walkAngleMult, math.rad(walkTurnSpeed1))
		Turn(lupleg, x_axis, math.rad(-6.725275)*walkAngleMult, math.rad(walkTurnSpeed1))
		Turn(lloleg, x_axis, math.rad(39.401099)*walkAngleMult, math.rad(walkTurnSpeed1))
		Turn(lfoot, x_axis, math.rad(-13.956044)*walkAngleMult, math.rad(walkTurnSpeed1))
		Turn(rloleg, x_axis, math.rad(19.005495)*walkAngleMult, math.rad(walkTurnSpeed1))
		Turn(rfoot, x_axis, math.rad(-7.615385)*walkAngleMult, math.rad(walkTurnSpeed1))
		Sleep(140 * walkSleepMult )
	end
	
	if (bMoving ) then
		if not bAiming then
			Turn(torso, y_axis, math.rad(1.88), math.rad(walkTurnSpeed1))
		end
		Turn(rupleg, x_axis, math.rad(1.857143)*walkAngleMult, math.rad(walkTurnSpeed1))
		Turn(lupleg, x_axis, math.rad(-24.357143)*walkAngleMult, math.rad(walkTurnSpeed1))
		Turn(lloleg, x_axis, math.rad(45.093407)*walkAngleMult, math.rad(walkTurnSpeed1))
		Turn(lfoot, x_axis, math.rad(-7.703297)*walkAngleMult, math.rad(walkTurnSpeed1))
		Turn(rloleg, x_axis, math.rad(3.560440)*walkAngleMult, math.rad(walkTurnSpeed1))
		Turn(rfoot, x_axis, math.rad(-4.934066)*walkAngleMult, math.rad(walkTurnSpeed1))
		Sleep(140 * walkSleepMult )
	end

	if (bMoving ) then
		if not bAiming then
			Turn(torso, y_axis, math.rad(3.15), math.rad(walkTurnSpeed1))
		end
		Turn(rupleg, x_axis, math.rad(7.148352)*walkAngleMult, math.rad(walkTurnSpeed1))
		Turn(lupleg, x_axis, math.rad(-28.181319)*walkAngleMult, math.rad(walkTurnSpeed1))
		Sleep(140 * walkSleepMult )
	end
	
	if (bMoving ) then
		if not bAiming then
			Turn(torso, y_axis, math.rad(4.20), math.rad(walkTurnSpeed1))
		end
		Turn(rupleg, x_axis, math.rad(8.423077)*walkAngleMult, math.rad(walkTurnSpeed1))
		Turn(lupleg, x_axis, math.rad(-32.060440)*walkAngleMult, math.rad(walkTurnSpeed1))
		Turn(lloleg, x_axis, math.rad(27.527473)*walkAngleMult, math.rad(walkTurnSpeed1))
		Turn(lfoot, x_axis, math.rad(-2.857143)*walkAngleMult, math.rad(walkTurnSpeed1))
		Turn(rloleg, x_axis, math.rad(24.670330)*walkAngleMult, math.rad(walkTurnSpeed1))
		Turn(rfoot, x_axis, math.rad(-26.313187)*walkAngleMult, math.rad(walkTurnSpeed1))
		Sleep(160 * walkSleepMult )
	end
end


local function MotionSpeedControl()
	REF_SPEED = GetUnitValue(COB.MAX_SPEED)
	Sleep(33)
	while true do

		sizeSpeedMult = dyncomm.GetPace()
		animationSpeedMult = GetUnitValue(COB.CURRENT_SPEED) * sizeSpeedMult / REF_SPEED
		
		if (animationSpeedMult < 0.7) then
			animationSpeedMult = 0.7
		end
		walkTurnSpeed1 = REF_TURN_SPEED * animationSpeedMult * SPEEDUP_FACTOR
		walkAngleMult = animationSpeedMult
		if (walkAngleMult > 1.2) then
			walkAngleMult = 1.2
		elseif (walkAngleMult < 0.9) then
			walkAngleMult = 0.9
		end

		walkSleepMult = 0.7 * walkAngleMult/(animationSpeedMult * SPEEDUP_FACTOR)

		--Spring.Echo("animationSpeedMult="..animationSpeedMult.." commLevel="..tostring(Spring.GetUnitRulesParam(unitID, "comm_level") or 0).." commScale="..dyncomm.GetScale().." sizeSpeedMult="..sizeSpeedMult)

		Sleep(100)
	end
end

local function MotionControl()
	local moving, aiming
	local justmoved = true
	while true do
		moving = bMoving
		aiming = bAiming

		if moving then
			Walk()
			justmoved = true
		else
			if justmoved then
				Turn(pelvis, x_axis, math.rad(0), math.rad(60))
				Turn(rupleg, x_axis, 0, math.rad(200.071429))
				Turn(rloleg, x_axis, 0, math.rad(200.071429))
				Turn(rfoot, x_axis, 0, math.rad(200.071429))
				Turn(lupleg, x_axis, 0, math.rad(200.071429))
				Turn(lloleg, x_axis, 0, math.rad(200.071429))
				Turn(lfoot, x_axis, 0, math.rad(200.071429))
				if not (aiming or inBuildAnim) then
					Turn(torso, x_axis, 0) --untilt forward
					Turn(torso, y_axis, 0, math.rad(90.027473))
					Turn(ruparm, x_axis, 0, math.rad(200.071429))
--					Turn(luparm, x_axis, 0, math.rad(200.071429))
				end
				justmoved = false
			end
			Sleep(100)
		end
	end
end

function script.Create()
	dyncomm.Create()
	--alert to dirt
	Turn(armhold, x_axis, math.rad(-45), math.rad(250)) --upspring
	Turn(ruparm, x_axis, 0, math.rad(250))
	Turn(ruparm, y_axis, 0, math.rad(250))
	Turn(ruparm, z_axis, 0, math.rad(250))
	Turn(rarm, x_axis, math.rad(2), math.rad(250))	 --
	Turn(rarm, y_axis, 0, math.rad(250))
	Turn(rarm, z_axis, math.rad(-(-12)), math.rad(250))	--up
	Turn(rloarm, x_axis, math.rad(47), math.rad(250)) --up
	Turn(rloarm, y_axis, math.rad(76), math.rad(250)) --up
	Turn(rloarm, z_axis, math.rad(-(-47)), math.rad(250)) --up
	Turn(luparm, x_axis, math.rad(12), math.rad(250))	 --up
	Turn(luparm, y_axis, 0, math.rad(250))
	Turn(luparm, z_axis, 0, math.rad(250))
	Turn(larm, x_axis, math.rad(-35), math.rad(250))	 --up
	Turn(larm, y_axis, math.rad(-3), math.rad(250))	 --up
	Turn(larm, z_axis, math.rad(-(22)), math.rad(250))	 --up
	Turn(lloarm, x_axis, math.rad(92), math.rad(250))	-- up
	Turn(lloarm, y_axis, 0, math.rad(250))
	Turn(lloarm, z_axis, math.rad(-(94)), math.rad(250)) --upspring

	Hide(flare)
	Hide(ac1)
	Hide(ac2)
	
	Move(nanospray, z_axis, 1*dyncomm.GetScale())
	Move(nanospray, y_axis, 1.8*dyncomm.GetScale())
	Move(nanospray, x_axis, 1.5*dyncomm.GetScale())

	StartThread(MotionSpeedControl)
	StartThread(MotionControl)
	StartThread(RestoreAfterDelay)
	StartThread(GG.Script.SmokeUnit, unitID, smokePiece)
	Spring.SetUnitNanoPieces(unitID, nanoPieces)
end

function script.StartMoving()
	bMoving = true
end

function script.StopMoving()
	--Signal(SIG_WALK)
	bMoving = false
end

function script.AimFromWeapon(num)
	return head
end

function script.QueryWeapon(num)
	if dyncomm.GetWeapon(num) == 1 or dyncomm.GetWeapon(num) == 2 then
		return flare
	end
	return shield
end

local function AimRifle(heading, pitch, isDgun)
	if pitch < -0.3 then
		Move(flare, z_axis, pitch*20 - 10)
	else
		Move(flare, z_axis, -2)
	end
	
	--torso
	Turn(torso, x_axis, math.rad(5), math.rad(250))
	Turn(torso, y_axis, 0, math.rad(250))
	Turn(torso, z_axis, 0, math.rad(250))
	--head
	Turn(head, x_axis, 0, math.rad(250))
	Turn(head, y_axis, 0, math.rad(250))
	Turn(head, z_axis, 0, math.rad(250))
	--rarm
	Turn(ruparm, x_axis, math.rad(-55), math.rad(250))
	Turn(ruparm, y_axis, 0, math.rad(250))
	Turn(ruparm, z_axis, 0, math.rad(250))
	
	Turn(rarm, x_axis, math.rad(13), math.rad(250))
	Turn(rarm, y_axis, math.rad(46), math.rad(250))
	Turn(rarm, z_axis, math.rad(9), math.rad(250))
	
	Turn(rloarm, x_axis, math.rad(16), math.rad(250))
	Turn(rloarm, y_axis, math.rad(-23), math.rad(250))
	Turn(rloarm, z_axis, math.rad(11), math.rad(250))
	
	Turn(gun, x_axis, math.rad(17.0), math.rad(250))
	Turn(gun, y_axis, math.rad(-19.8), math.rad(250)) ---20 is dead straight
	Turn(gun, z_axis, math.rad(2.0), math.rad(250))
	--larm
	Turn(luparm, x_axis, math.rad(-70), math.rad(250))
	Turn(luparm, y_axis, math.rad(-20), math.rad(250))
	Turn(luparm, z_axis, math.rad(-10), math.rad(250))
	
	Turn(larm, x_axis, math.rad(-13), math.rad(250))
	Turn(larm, y_axis, math.rad(-60), math.rad(250))
	Turn(larm, z_axis, math.rad(9), math.rad(250))
	
	Turn(lloarm, x_axis, math.rad(73), math.rad(250))
	Turn(lloarm, y_axis, math.rad(19), math.rad(250))
	Turn(lloarm, z_axis, math.rad(58), math.rad(250))
	
	--aim
	Turn(turret, y_axis, heading, math.rad(350))
	Turn(armhold, x_axis, -pitch, math.rad(250))
	WaitForTurn(turret, y_axis)
	WaitForTurn(armhold, x_axis) --need to make sure not
	WaitForTurn(lloarm, x_axis) --still setting up
	WaitForTurn(rloarm, y_axis) --still setting up
	
	StartThread(RestoreAfterDelay)
	return true
end

function script.AimWeapon(num, heading, pitch)
	local weaponNum = dyncomm.GetWeapon(num)
	inBuildAnim = false
	if weaponNum == 1 then
		Signal(SIG_AIM)
		SetSignalMask(SIG_AIM)
		bAiming = true
		return AimRifle(heading, pitch)
	elseif weaponNum == 2 then
		Signal(SIG_AIM)
		Signal(SIG_AIM_2)
		SetSignalMask(SIG_AIM_2)
		bAiming = true
		return AimRifle(heading, pitch, canDgun)
	elseif weaponNum == 3 then
		return true
	end
	return false
end

function script.Activate()
	--spSetUnitShieldState(unitID, true)
end

function script.Deactivate()
	--spSetUnitShieldState(unitID, false)
end

function script.FireWeapon(num)
	dyncomm.EmitWeaponFireSfx(flare, num)
end

function script.Shot(num)
	dyncomm.EmitWeaponShotSfx(flare, num)
end

function script.QueryNanoPiece()
	GG.LUPS.QueryNanoPiece(unitID,unitDefID,Spring.GetUnitTeam(unitID),nanospray)
	return nanospray
end

function script.StopBuilding()
	Signal(SIG_BUILD)
	inBuildAnim = false
	SetUnitValue(COB.INBUILDSTANCE, 0)
	if not bAiming then
		StartThread(RestoreAfterDelay)
	end
end

function script.StartBuilding(heading, pitch)
	StartThread(BuildDecloakThread)
	restoreHeading, restorePitch = heading, pitch
	BuildPose(heading, pitch)
	SetUnitValue(COB.INBUILDSTANCE, 1)
end

function script.Killed(recentDamage, maxHealth)
	local severity = recentDamage/maxHealth
	dead = 1
	--Turn(turret, y_axis, 0, math.rad(500))
	if severity <= 0.5 then
		dyncomm.SpawnModuleWrecks(1)
		
		Turn(base, x_axis, math.rad(79), math.rad(80))
		Turn(rloleg, x_axis, math.rad(25), math.rad(250))
		Turn(lupleg, x_axis, math.rad(7), math.rad(250))
		Turn(lupleg, y_axis, math.rad(34), math.rad(250))
		Turn(lupleg, z_axis, math.rad(-(-9)), math.rad(250))
		
		GG.Script.InitializeDeathAnimation(unitID)
		Sleep(200) --give time to fall
		Turn(luparm, y_axis, math.rad(18), math.rad(350))
		Turn(luparm, z_axis, math.rad(-(-45)), math.rad(350))
		Sleep(650)
		--EmitSfx(turret, 1026) --impact

		Sleep(100)
--[[
		Explode(gun)
		Explode(head)
		Explode(pelvis)
		Explode(lloarm)
		Explode(luparm)
		Explode(lloleg)
		Explode(lupleg)
		Explode(rloarm)
		Explode(rloleg)
		Explode(ruparm)
		Explode(rupleg)
		Explode(torso)
]]--
		dyncomm.SpawnWreck(1)
	else
		Explode(gun, SFX.FALL + SFX.FIRE + SFX.SMOKE + SFX.EXPLODE)
		Explode(head, SFX.FALL + SFX.FIRE + SFX.SMOKE + SFX.EXPLODE)
		Explode(pelvis, SFX.FALL + SFX.FIRE + SFX.SMOKE + SFX.EXPLODE)
		Explode(lloarm, SFX.FALL + SFX.FIRE + SFX.SMOKE + SFX.EXPLODE)
		Explode(luparm, SFX.FALL + SFX.FIRE + SFX.SMOKE + SFX.EXPLODE)
		Explode(lloleg, SFX.FALL + SFX.FIRE + SFX.SMOKE + SFX.EXPLODE)
		Explode(lupleg, SFX.FALL + SFX.FIRE + SFX.SMOKE + SFX.EXPLODE)
		Explode(rloarm, SFX.FALL + SFX.FIRE + SFX.SMOKE + SFX.EXPLODE)
		Explode(rloleg, SFX.FALL + SFX.FIRE + SFX.SMOKE + SFX.EXPLODE)
		Explode(ruparm, SFX.FALL + SFX.FIRE + SFX.SMOKE + SFX.EXPLODE)
		Explode(rupleg, SFX.FALL + SFX.FIRE + SFX.SMOKE + SFX.EXPLODE)
		Explode(torso, SFX.SHATTER + SFX.EXPLODE)
		dyncomm.SpawnModuleWrecks(2)
		dyncomm.SpawnWreck(2)
	end
end
