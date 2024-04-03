include "constants.lua"

local dyncomm = include('dynamicCommander.lua')
_G.dyncomm = dyncomm

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

--------------------------------------------------------------------------------
-- vars
--------------------------------------------------------------------------------
local restoreHeading, restorePitch = 0, 0

local canDgun = UnitDefs[unitDefID].canDgun

local dead = false
local bMoving = false
local bAiming = false
local inBuildAnim = false

local SPEED_MULT = 1.12
local sizeSpeedMult = 1

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
local function BuildDecloakThread()
	Signal(SIG_BUILD)
	SetSignalMask(SIG_BUILD)
	while true do
		GG.PokeDecloakUnit(unitID, unitDefID)
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
			Turn(larm, z_axis, math.rad(-22), math.rad(250))	 --up 22
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


local walkCycle = {
	{
		pelvis = -0.2,
		torso = math.rad(3),
		pass = {
			up = math.rad(4),
			mid = math.rad(15),
			foot = math.rad(-12),
		},
		ground = {
			up = math.rad(-34),
			mid = math.rad(35),
			foot = math.rad(0),
		},
	},
	{
		pelvis = -0.2,
		torso = math.rad(4),
		pass = {
			up = math.rad(10),
			mid = math.rad(20),
			foot = math.rad(-10),
		},
		ground = {
			up = math.rad(-32),
			mid = math.rad(4),
			foot = math.rad(10),
		},
	},
	{
		pelvis = -0.4,
		torso = math.rad(2),
		pass = {
			up = math.rad(-7),
			mid = math.rad(56),
			foot = math.rad(-10),
		},
		ground = {
			up = math.rad(-17),
			mid = math.rad(2),
			foot = math.rad(12),
		},
	},
	{
		pelvis = -0.3,
		torso = math.rad(0),
		pass = {
			up = math.rad(-20),
			mid = math.rad(53),
			foot = math.rad(-12),
		},
		ground = {
			up = math.rad(-6),
			mid = math.rad(10),
			foot = math.rad(-5),
		},
	},
}

local function Walk(groundUp, groundMid, groundFoot, passUp, passMid, passFoot, torsoParity)
	local speed = 5 * sizeSpeedMult * math.max(0.5, GG.att_MoveChange[unitID] or 1)
	
	for i = 1, #walkCycle do
		local cur = walkCycle[i]
		local prev = walkCycle[(i > 1 and (i - 1)) or #walkCycle]
		local prevPass = (i > 1 and prev.pass) or prev.ground
		local prevGround = (i > 1 and prev.ground) or prev.pass
		local prevTorso = (i > 1 and prev.torso) or (-1 * prev.torso)
		
		if not bAiming then
			Turn(torso, y_axis, torsoParity * cur.torso, speed * math.abs(cur.torso - prevTorso))
		end
		
		Move(pelvis, y_axis, cur.pelvis, speed * math.abs(cur.pelvis - prev.pelvis))
		Turn(passUp, x_axis, cur.pass.up, speed * math.abs(cur.pass.up - prevPass.up))
		Turn(passMid, x_axis, cur.pass.mid, speed * math.abs(cur.pass.mid - prevPass.mid))
		Turn(passFoot, x_axis, cur.pass.foot, speed * math.abs(cur.pass.foot - prevPass.foot))
		Turn(groundUp, x_axis, cur.ground.up, speed * math.abs(cur.ground.up - prevGround.up))
		Turn(groundMid, x_axis, cur.ground.mid, speed * math.abs(cur.ground.mid - prevGround.mid))
		Turn(groundFoot, x_axis, cur.ground.foot, speed * math.abs(cur.ground.foot - prevGround.foot))
		Sleep(1000 / speed)
		if not bMoving then
			return
		end
	end
end

local function MotionControl()
	local moving, aiming
	local justmoved = true
	local legParity = true or math.random() > 0.5
	while true do
		moving = bMoving
		aiming = bAiming

		if moving then
			justmoved = true
			if legParity then
				Walk(lupleg, lloleg, lfoot, rupleg, rloleg, rfoot, -1)
			else
				Walk(rupleg, rloleg, rfoot, lupleg, lloleg, lfoot, 1)
			end
			legParity = not legParity
		else
			if justmoved then
				Turn(pelvis, x_axis, 0, math.rad(60))
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
	sizeSpeedMult = dyncomm.GetPace() * SPEED_MULT
	--alert to dirt
	Turn(armhold, x_axis, math.rad(-45), math.rad(250)) --upspring
	Turn(ruparm, x_axis, 0, math.rad(250))
	Turn(ruparm, y_axis, 0, math.rad(250))
	Turn(ruparm, z_axis, 0, math.rad(250))
	Turn(rarm, x_axis, math.rad(2), math.rad(250))	 --
	Turn(rarm, y_axis, 0, math.rad(250))
	Turn(rarm, z_axis, math.rad(12), math.rad(250))	--up
	Turn(rloarm, x_axis, math.rad(47), math.rad(250)) --up
	Turn(rloarm, y_axis, math.rad(76), math.rad(250)) --up
	Turn(rloarm, z_axis, math.rad(47), math.rad(250)) --up
	Turn(luparm, x_axis, math.rad(12), math.rad(250))	 --up
	Turn(luparm, y_axis, 0, math.rad(250))
	Turn(luparm, z_axis, 0, math.rad(250))
	Turn(larm, x_axis, math.rad(-35), math.rad(250))	 --up
	Turn(larm, y_axis, math.rad(-3), math.rad(250))	 --up
	Turn(larm, z_axis, math.rad(-22), math.rad(250))	 --up
	Turn(lloarm, x_axis, math.rad(92), math.rad(250))	-- up
	Turn(lloarm, y_axis, 0, math.rad(250))
	Turn(lloarm, z_axis, math.rad(-94), math.rad(250)) --upspring

	Hide(flare)
	Hide(ac1)
	Hide(ac2)
	
	Move(nanospray, z_axis, 1*dyncomm.GetScale())
	Move(nanospray, y_axis, 1.8*dyncomm.GetScale())
	Move(nanospray, x_axis, 1.5*dyncomm.GetScale())

	StartThread(MotionControl)
	StartThread(RestoreAfterDelay)
	StartThread(GG.Script.SmokeUnit, unitID, smokePiece)
	Spring.SetUnitNanoPieces(unitID, nanoPieces)
end

function script.StartMoving()
	bMoving = true
end

function script.StopMoving()
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

function script.FireWeapon(num)
	dyncomm.EmitWeaponFireSfx(flare, num)
end

function script.Shot(num)
	dyncomm.EmitWeaponShotSfx(flare, num)
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
		Turn(lupleg, z_axis, math.rad(9), math.rad(250))
		
		GG.Script.InitializeDeathAnimation(unitID)
		Sleep(200) --give time to fall
		Turn(luparm, y_axis, math.rad(18), math.rad(350))
		Turn(luparm, z_axis, math.rad(45), math.rad(350))
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
