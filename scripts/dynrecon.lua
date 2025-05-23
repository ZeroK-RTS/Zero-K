include "constants.lua"
include "JumpRetreat.lua"

local dyncomm = include('dynamicCommander.lua')
_G.dyncomm = dyncomm

--------------------------------------------------------------------------------
-- pieces
--------------------------------------------------------------------------------
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
local rsword = piece 'rsword'
local lsword = piece 'lsword'
local jet1 = piece 'jet1'
local jet2 = piece 'jet2'
local jx1 = piece 'jx1'
local jx2 = piece 'jx2'
local stab = piece 'stab'
local nanospray = piece 'nanospray'
local grenade = piece 'grenade'

local smokePiece = {torso}
local nanoPieces = {nanospray}

local SPEED_MULT = 1.2
local sizeSpeedMult = 1

--------------------------------------------------------------------------------
-- constants
--------------------------------------------------------------------------------
local SIG_RESTORE = 1
local SIG_AIM = 2
local SIG_AIM_2 = 4
--local SIG_AIM_3 = 8 --step on

--------------------------------------------------------------------------------
-- vars
--------------------------------------------------------------------------------
local restoreHeading, restorePitch = 0, 0

wepTable = nil
local canDgun = UnitDefs[unitDefID].canDgun

local dead = false
local bMoving = false
local bAiming = false
local shieldOn = true
local inJumpMode = false

--------------------------------------------------------------------------------
-- funcs
--------------------------------------------------------------------------------
local function BuildPose(heading, pitch)
	Turn(luparm, x_axis, math.rad(-60), math.rad(250))
	Turn(luparm, y_axis, math.rad(-15), math.rad(250))
	Turn(luparm, z_axis, math.rad(-10), math.rad(250))
	
	Turn(larm, x_axis, math.rad(5), math.rad(250))
	Turn(larm, y_axis, math.rad(-30), math.rad(250))
	Turn(larm, z_axis, math.rad(26), math.rad(250))
	
	Turn(lloarm, y_axis, math.rad(-37), math.rad(250))
	Turn(lloarm, z_axis, math.rad(-152), math.rad(450))

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
			Turn(luparm, x_axis, math.rad(-9), math.rad(250))	 --up -9
			Turn(luparm, y_axis, 0, math.rad(250))
			Turn(luparm, z_axis, 0, math.rad(250))
			Turn(larm, x_axis, math.rad(5), math.rad(250))	 --up 5
			Turn(larm, y_axis, math.rad(-3), math.rad(250))	 --up -3
			Turn(larm, z_axis, math.rad(-22), math.rad(250))	 --up 22
			Turn(lloarm, x_axis, math.rad(92), math.rad(250))	-- up 82
			Turn(lloarm, y_axis, 0, math.rad(250))
			Turn(lloarm, z_axis, math.rad(-94), math.rad(250)) --upspring 94
			-- done at ease
			Sleep(100)
		end
		bAiming = false
	end
end

local walkCycle = {
	{
		pelvis = 0,
		torso = math.rad(0),
		pass = {
			up = math.rad(-18),
			mid = math.rad(53),
			foot = math.rad(-20),
		},
		ground = {
			up = math.rad(-2),
			mid = math.rad(10),
			foot = math.rad(-8),
		},
	},
	{
		pelvis = 0.12,
		torso = math.rad(-3),
		pass = {
			up = math.rad(-33),
			mid = math.rad(35),
			foot = math.rad(-15),
		},
		ground = {
			up = math.rad(4),
			mid = math.rad(27),
			foot = math.rad(-20),
		},
	},
	{
		pelvis = 0.26,
		torso = math.rad(-4),
		pass = {
			up = math.rad(-27),
			mid = math.rad(8),
			foot = math.rad(0),
		},
		ground = {
			up = math.rad(18),
			mid = math.rad(26),
			foot = math.rad(-22),
		},
	},
	{
		pelvis = -0.2,
		torso = math.rad(-2),
		pass = {
			up = math.rad(-15),
			mid = math.rad(3),
			foot = math.rad(8),
		},
		ground = {
			up = math.rad(-2),
			mid = math.rad(65),
			foot = math.rad(-40),
		},
	},
}

local function Walk(groundUp, groundMid, groundFoot, passUp, passMid, passFoot, torsoParity, alreadyMoving)
	local speed = 5 * sizeSpeedMult * math.max(0.5, GG.att_MoveChange[unitID] or 1)
	if not alreadyMoving then
		speed = speed * 2
	end
	
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
		if not alreadyMoving then
			speed = speed * 0.8
		end
		if not bMoving then
			return
		end
	end
end

local function MotionControl()
	--for i = 1024, 1050 do
	--	Spring.Echo("Weapon", i)
	--	for j = 1, 12 do
	--		EmitSfx(flare, i)
	--		Sleep (100)
	--	end
	--end
	--for i = 1, 20 do
	--	local reloadTime = Spring.GetUnitWeaponState(unitID, i, "reloadTime")
	--	Spring.Echo("Weapon reload time", i, reloadTime)
	--end

	local moving, aiming, zeroSpeedCount
	local justmoved = true
	local legParity = math.random() > 0.5
	while true do
		moving = bMoving
		aiming = bAiming
		if moving then
			if legParity then
				Walk(lupleg, lloleg, lfoot, rupleg, rloleg, rfoot, -1, justmoved)
			else
				Walk(rupleg, rloleg, rfoot, lupleg, lloleg, lfoot, 1, justmoved)
			end
			legParity = not legParity
			justmoved = true
			
			local _,_,_, speed = Spring.GetUnitVelocity(unitID)
			if speed == 0 then
				zeroSpeedCount = zeroSpeedCount + 1
				if zeroSpeedCount > 2 then
					bMoving = false
				end
			else
				zeroSpeedCount = 0
			end
		else
			if justmoved then
				Turn(rupleg, x_axis, 0, math.rad(200.071429) * sizeSpeedMult)
				Turn(rloleg, x_axis, 0, math.rad(200.071429) * sizeSpeedMult)
				Turn(rfoot, x_axis, 0, math.rad(200.071429) * sizeSpeedMult)
				Turn(lupleg, x_axis, 0, math.rad(200.071429) * sizeSpeedMult)
				Turn(lloleg, x_axis, 0, math.rad(200.071429) * sizeSpeedMult)
				Turn(lfoot, x_axis, 0, math.rad(200.071429) * sizeSpeedMult)
				if not aiming then
					Turn(torso, x_axis, 0) --untilt forward
					Turn(torso, y_axis, 0, math.rad(90.027473) * sizeSpeedMult)
					Turn(ruparm, x_axis, 0, math.rad(200.071429) * sizeSpeedMult)
--					Turn(luparm, x_axis, 0, math.rad(200.071429))
				end
				justmoved = false
			end
			Sleep(100)
			zeroSpeedCount = 0
		end
	end
end

function script.Create()
	dyncomm.Create()
	sizeSpeedMult = (1 - (1 - dyncomm.GetPace())/2.5) * SPEED_MULT
	--alert to dirt
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
	Turn(luparm, x_axis, math.rad(-9), math.rad(250))	 --up -9
	Turn(luparm, y_axis, 0, math.rad(250))
	Turn(luparm, z_axis, 0, math.rad(250))
	Turn(larm, x_axis, math.rad(5), math.rad(250))	 --up 5
	Turn(larm, y_axis, math.rad(-3), math.rad(250))	 --up -3
	Turn(larm, z_axis, math.rad(-22), math.rad(250))	 --up 22
	Turn(lloarm, x_axis, math.rad(92), math.rad(250))	-- up 82
	Turn(lloarm, y_axis, 0, math.rad(250))
	Turn(lloarm, z_axis, math.rad(-94), math.rad(250)) --upspring 94

	Hide(flare)
	Hide(jx1)
	Hide(jx2)
	Hide(grenade)

	StartThread(MotionControl)
	StartThread(RestoreAfterDelay)
	StartThread(GG.Script.SmokeUnit, unitID, smokePiece)
	Spring.SetUnitNanoPieces(unitID, nanoPieces)
end

function script.StartMoving()
	if not inJumpMode then
		bMoving = true
	end
end

function script.StopMoving()
	bMoving = false
end

function script.AimFromWeapon(num)
	return head
end

local function AimRifle(heading, pitch, isDgun)
	--torso
	Turn(torso, x_axis, math.rad(15), math.rad(250))
	Turn(torso, y_axis, math.rad(-25), math.rad(250))
	Turn(torso, z_axis, 0, math.rad(250))
	--head
	Turn(head, x_axis, math.rad(-15), math.rad(250))
	Turn(head, y_axis, math.rad(25), math.rad(250))
	Turn(head, z_axis, 0, math.rad(250))
	--rarm
	Turn(ruparm, x_axis, math.rad(-83), math.rad(250))
	Turn(ruparm, y_axis, math.rad(30), math.rad(250))
	Turn(ruparm, z_axis, math.rad(-10), math.rad(250))
	
	Turn(rarm, x_axis, math.rad(41), math.rad(250))
	Turn(rarm, y_axis, math.rad(19), math.rad(250))
	Turn(rarm, z_axis, math.rad(3), math.rad(250))
	
	Turn(rloarm, x_axis, math.rad(18), math.rad(250))
	Turn(rloarm, y_axis, math.rad(19), math.rad(250))
	Turn(rloarm, z_axis, math.rad(-14), math.rad(250))
	
	Turn(gun, x_axis, math.rad(15), math.rad(250))
	Turn(gun, y_axis, math.rad(-15), math.rad(250))
	Turn(gun, z_axis, math.rad(31), math.rad(250))
	--larm
	Turn(luparm, x_axis, math.rad(-80), math.rad(250))
	Turn(luparm, y_axis, math.rad(-15), math.rad(250))
	Turn(luparm, z_axis, math.rad(-10), math.rad(250))
	
	Turn(larm, x_axis, math.rad(5), math.rad(250))
	Turn(larm, y_axis, math.rad(-77), math.rad(250))
	Turn(larm, z_axis, math.rad(26), math.rad(250))
	
	Turn(lloarm, x_axis, math.rad(65), math.rad(250))
	Turn(lloarm, y_axis, math.rad(-37), math.rad(250))
	Turn(lloarm, z_axis, math.rad(-152), math.rad(450))
	WaitForTurn(ruparm, x_axis)
	
	Turn(turret, y_axis, heading, math.rad(350))
	Turn(armhold, x_axis, - pitch, math.rad(250))
	WaitForTurn(turret, y_axis)
	WaitForTurn(armhold, x_axis)
	WaitForTurn(lloarm, z_axis)
	StartThread(RestoreAfterDelay)
	
	return true
end

function script.AimWeapon(num, heading, pitch)
	local weaponNum = dyncomm.GetWeapon(num)
	
	if weaponNum == 3 then -- shield
		return true
	end
	
	if weaponNum == 1 then
		Signal(SIG_AIM)
		SetSignalMask(SIG_AIM)
	elseif weaponNum == 2 then
		Signal(SIG_AIM_2)
		SetSignalMask(SIG_AIM_2)
	else
		return false
	end

	bAiming = true
	return AimRifle(heading, pitch, dyncomm.IsManualFire(num))
end

function script.Activate()
	--spSetUnitShieldState(unitID, true)
end

function script.Deactivate()
	--spSetUnitShieldState(unitID, false)
end

local weaponFlares = {
	[1] = flare,
	[2] = flare,
	[3] = shield,
}

function script.QueryWeapon(num)
	return weaponFlares[dyncomm.GetWeapon(num) or 3]
end

function script.FireWeapon(num)
	dyncomm.EmitWeaponFireSfx(flare, num)
end

function script.Shot(num)
	dyncomm.EmitWeaponShotSfx(flare, num)
end

local function JumpExhaust()
	while inJumpMode do
		EmitSfx(jx1, 1028)
		EmitSfx(jx2, 1028)
		Sleep(33)
	end
end

function beginJump()
	script.StopMoving()
	GG.PokeDecloakUnit(unitID, unitDefID)
	inJumpMode = true
	--[[
	StartThread(JumpExhaust)
	--]]
end

function jumping()
	GG.PokeDecloakUnit(unitID, unitDefID)
	EmitSfx(jx1, 1028)
	EmitSfx(jx2, 1028)
end

function endJump()
	inJumpMode = false
	script.StopMoving()
	EmitSfx(base, 1029)
end

function script.StopBuilding()
	SetUnitValue(COB.INBUILDSTANCE, 0)
	restoreHeading, restorePitch = 0, 0
	if not bAiming then
		StartThread(RestoreAfterDelay)
	end
end

function script.StartBuilding(heading, pitch)
	--larm
	restoreHeading, restorePitch = heading, pitch
	BuildPose(heading, pitch)
	SetUnitValue(COB.INBUILDSTANCE, 1)
	restoreHeading, restorePitch = heading, pitch
end

function script.Killed(recentDamage, maxHealth)
	local severity = recentDamage/maxHealth
	dead = true
--	Turn(turret, y_axis, 0, math.rad(500))
	if severity <= 0.5 and not inJumpMode then
		dyncomm.SpawnModuleWrecks(1)
		Turn(base, x_axis, math.rad(80), math.rad(80))
		Turn(turret, x_axis, math.rad(-16), math.rad(50))
		Turn(turret, y_axis, 0, math.rad(90))
		Turn(rloleg, x_axis, math.rad(9), math.rad(250))
		Turn(rloleg, y_axis, math.rad(-73), math.rad(250))
		Turn(rloleg, z_axis, math.rad(-3), math.rad(250))
		Turn(lupleg, x_axis, math.rad(7), math.rad(250))
		Turn(lloleg, y_axis, math.rad(21), math.rad(250))
		Turn(lfoot, x_axis, math.rad(24), math.rad(250))
		
		GG.Script.InitializeDeathAnimation(unitID)
		Sleep(200) --give time to fall
		Turn(ruparm, x_axis, math.rad(-48), math.rad(350))
		Turn(ruparm, y_axis, math.rad(32), math.rad(350)) --was -32
		Turn(luparm, x_axis, math.rad(-50), math.rad(350))
		Turn(luparm, y_axis, math.rad(47), math.rad(350))
		Turn(luparm, z_axis, math.rad(-50), math.rad(350))
		Sleep(600)
		EmitSfx(turret, 1027) --impact
		--StartThread(burn)
		--Sleep((1000 * rand (2, 5)))
		Sleep(100)
		dyncomm.SpawnWreck(1)
	elseif severity <= 0.5 then
		dyncomm.SpawnModuleWrecks(1)
		Explode(gun,	SFX.FALL + SFX.SMOKE + SFX.EXPLODE)
		Explode(head, SFX.FIRE + SFX.EXPLODE)
		Explode(pelvis, SFX.FIRE + SFX.EXPLODE)
		Explode(lloarm, SFX.FIRE + SFX.EXPLODE)
		Explode(luparm, SFX.FIRE + SFX.EXPLODE)
		Explode(lloleg, SFX.FIRE + SFX.EXPLODE)
		Explode(lupleg, SFX.FIRE + SFX.EXPLODE)
		Explode(rloarm, SFX.FIRE + SFX.EXPLODE)
		Explode(rloleg, SFX.FALL + SFX.FIRE + SFX.SMOKE + SFX.EXPLODE)
		Explode(ruparm, SFX.FALL + SFX.FIRE + SFX.SMOKE + SFX.EXPLODE)
		Explode(rupleg, SFX.FALL + SFX.FIRE + SFX.SMOKE + SFX.EXPLODE)
		Explode(torso, SFX.SHATTER + SFX.EXPLODE)
		dyncomm.SpawnWreck(1)
	else
		dyncomm.SpawnModuleWrecks(2)
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
		dyncomm.SpawnWreck(2)
	end
end

