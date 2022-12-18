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

local SPEED_MULT = 1
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
			Turn(rarm, z_axis, math.rad(-(-12)), math.rad(250))	--up -12
			Turn(rloarm, x_axis, math.rad(47), math.rad(250)) --up 47
			Turn(rloarm, y_axis, math.rad(76), math.rad(250)) --up 76
			Turn(rloarm, z_axis, math.rad(-(-47)), math.rad(250)) --up -47
			Turn(luparm, x_axis, math.rad(-9), math.rad(250))	 --up -9
			Turn(luparm, y_axis, 0, math.rad(250))
			Turn(luparm, z_axis, 0, math.rad(250))
			Turn(larm, x_axis, math.rad(5), math.rad(250))	 --up 5
			Turn(larm, y_axis, math.rad(-3), math.rad(250))	 --up -3
			Turn(larm, z_axis, math.rad(-(22)), math.rad(250))	 --up 22
			Turn(lloarm, x_axis, math.rad(92), math.rad(250))	-- up 82
			Turn(lloarm, y_axis, 0, math.rad(250))
			Turn(lloarm, z_axis, math.rad(-(94)), math.rad(250)) --upspring 94
			-- done at ease
			Sleep(100)
		end
		bAiming = false
	end
end

local function Walk()
	if not bAiming then
		Turn(torso, x_axis, math.rad(12) * sizeSpeedMult) --tilt forward
		Turn(torso, y_axis, math.rad(3.335165) * sizeSpeedMult)
	end
	Move(pelvis, y_axis, 0)
	Turn(rupleg, x_axis, math.rad(5.670330) * sizeSpeedMult)
	Turn(lupleg, x_axis, math.rad(-26.467033) * sizeSpeedMult)
	Turn(lloleg, x_axis, math.rad(26.967033) * sizeSpeedMult)
	Turn(rloleg, x_axis, math.rad(26.967033) * sizeSpeedMult)
	Turn(rfoot, x_axis, math.rad(-19.824176) * sizeSpeedMult)
	Sleep(90/sizeSpeedMult) --had to + 20 to all sleeps in walk
	
	if not bMoving then
		return
	end
	if not bAiming then
		Turn(torso, y_axis, math.rad(1.681319) * sizeSpeedMult)
	end
	Turn(rupleg, x_axis, math.rad(-5.269231) * sizeSpeedMult)
	Turn(lupleg, x_axis, math.rad(-20.989011) * sizeSpeedMult)
	Turn(lloleg, x_axis, math.rad(20.945055) * sizeSpeedMult)
	Turn(rloleg, x_axis, math.rad(41.368132 * sizeSpeedMult))
	Turn(rfoot, x_axis, math.rad(-15.747253) * sizeSpeedMult)
	Sleep(70/sizeSpeedMult)
	
	if not bMoving then
		return
	end
	if not bAiming then
		Turn(torso, y_axis, 0 * sizeSpeedMult)
	end
	Turn(rupleg, x_axis, math.rad(-9.071429) * sizeSpeedMult)
	Turn(lupleg, x_axis, math.rad(-12.670330) * sizeSpeedMult)
	Turn(lloleg, x_axis, math.rad(12.670330) * sizeSpeedMult)
	Turn(rloleg, x_axis, math.rad(43.571429) * sizeSpeedMult)
	Turn(rfoot, x_axis, math.rad(-12.016484) * sizeSpeedMult)
	Sleep(50/sizeSpeedMult)
	
	if not bMoving then
		return
	end
	if not bAiming then
		Turn(torso, y_axis, math.rad(-1.77) * sizeSpeedMult)
	end
	Turn(rupleg, x_axis, math.rad(-21.357143) * sizeSpeedMult)
	Turn(lupleg, x_axis, math.rad(2.824176) * sizeSpeedMult)
	Turn(lloleg, x_axis, math.rad(3.560440) * sizeSpeedMult)
	Turn(lfoot, x_axis, math.rad(-4.527473) * sizeSpeedMult)
	Turn(rloleg, x_axis, math.rad(52.505495) * sizeSpeedMult)
	Turn(rfoot, x_axis, 0)
	Sleep(40/sizeSpeedMult)
	
	if not bMoving then
		return
	end
	if not bAiming then
		Turn(torso, y_axis, math.rad(-3.15) * sizeSpeedMult)
	end
	Turn(rupleg, x_axis, math.rad(-35.923077) * sizeSpeedMult)
	Turn(lupleg, x_axis, math.rad(7.780220) * sizeSpeedMult)
	Turn(lloleg, x_axis, math.rad(8.203297) * sizeSpeedMult)
	Turn(lfoot, x_axis, math.rad(-12.571429) * sizeSpeedMult)
	Turn(rloleg, x_axis, math.rad(54.390110) * sizeSpeedMult)
	Sleep(50/sizeSpeedMult)

	if not bMoving then
		return
	end
	if not bAiming then
		Turn(torso, y_axis, math.rad(-4.2) * sizeSpeedMult)
	end
	Turn(rupleg, x_axis, math.rad(-37.780220) * sizeSpeedMult)
	Turn(lupleg, x_axis, math.rad(10.137363) * sizeSpeedMult)
	Turn(lloleg, x_axis, math.rad(13.302198) * sizeSpeedMult)
	Turn(lfoot, x_axis, math.rad(-16.714286) * sizeSpeedMult)
	Turn(rloleg, x_axis, math.rad(32.582418) * sizeSpeedMult)
	Sleep(50/sizeSpeedMult)

	if not bMoving then
		return
	end
	if not bAiming then
		Turn(torso, y_axis, math.rad(-3.15) * sizeSpeedMult)
	end
	Turn(rupleg, x_axis, math.rad(-28.758242) * sizeSpeedMult)
	Turn(lupleg, x_axis, math.rad(12.247253) * sizeSpeedMult)
	Turn(lloleg, x_axis, math.rad(19.659341) * sizeSpeedMult)
	Turn(lfoot, x_axis, math.rad(-19.659341) * sizeSpeedMult)
	Turn(rloleg, x_axis, math.rad(28.758242) * sizeSpeedMult)
	Sleep(90/sizeSpeedMult)

	if not bMoving then
		return
	end
	if not bAiming then
		Turn(torso, y_axis, math.rad(-1.88) * sizeSpeedMult)
	end
	Turn(rupleg, x_axis, math.rad(-22.824176) * sizeSpeedMult)
	Turn(lupleg, x_axis, math.rad(2.824176) * sizeSpeedMult)
	Turn(lloleg, x_axis, math.rad(34.060440) * sizeSpeedMult)
	Turn(rfoot, x_axis, math.rad(-6.313187) * sizeSpeedMult)
	Sleep(70/sizeSpeedMult)

	if not bMoving then
		return
	end
	if not bAiming then
		Turn(torso, y_axis, 0 * sizeSpeedMult)
	end
	Turn(rupleg, x_axis, math.rad(-11.604396) * sizeSpeedMult)
	Turn(lupleg, x_axis, math.rad(-6.725275) * sizeSpeedMult)
	Turn(lloleg, x_axis, math.rad(39.401099) * sizeSpeedMult)
	Turn(lfoot, x_axis, math.rad(-13.956044) * sizeSpeedMult)
	Turn(rloleg, x_axis, math.rad(19.005495) * sizeSpeedMult)
	Turn(rfoot, x_axis, math.rad(-7.615385) * sizeSpeedMult)
	Sleep(50/sizeSpeedMult)

	if not bMoving then
		return
	end
	if not bAiming then
		Turn(torso, y_axis, math.rad(1.88) * sizeSpeedMult)
	end
	Turn(rupleg, x_axis, math.rad(1.857143) * sizeSpeedMult)
	Turn(lupleg, x_axis, math.rad(-24.357143) * sizeSpeedMult)
	Turn(lloleg, x_axis, math.rad(45.093407) * sizeSpeedMult)
	Turn(lfoot, x_axis, math.rad(-7.703297) * sizeSpeedMult)
	Turn(rloleg, x_axis, math.rad(3.560440) * sizeSpeedMult)
	Turn(rfoot, x_axis, math.rad(-4.934066) * sizeSpeedMult)
	Sleep(40/sizeSpeedMult)

	if not bMoving then
		return
	end
	if not bAiming then
		Turn(torso, y_axis, math.rad(3.15) * sizeSpeedMult)
	end
	Turn(rupleg, x_axis, math.rad(7.148352) * sizeSpeedMult)
	Turn(lupleg, x_axis, math.rad(-28.181319) * sizeSpeedMult)
	Turn(rfoot, x_axis, math.rad(-9.813187) * sizeSpeedMult)
	Sleep(50/sizeSpeedMult)

	if not bMoving then
		return
	end
	if not bAiming then
		Turn(torso, y_axis, math.rad(4.2) * sizeSpeedMult)
	end
	Turn(rupleg, x_axis, math.rad(8.423077) * sizeSpeedMult)
	Turn(lupleg, x_axis, math.rad(-32.060440) * sizeSpeedMult)
	Turn(lloleg, x_axis, math.rad(27.527473) * sizeSpeedMult)
	Turn(lfoot, x_axis, math.rad(-2.857143) * sizeSpeedMult)
	Turn(rloleg, x_axis, math.rad(24.670330) * sizeSpeedMult)
	Turn(rfoot, x_axis, math.rad(-33.313187) * sizeSpeedMult)
	Sleep(70/sizeSpeedMult)
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
		end
	end
end

function script.Create()
	dyncomm.Create()
	sizeSpeedMult = (1 - (1 - dyncomm.GetPace())/2.5) *SPEED_MULT
	--alert to dirt
	Turn(armhold, x_axis, math.rad(-45), math.rad(250)) --upspring at -45
	Turn(ruparm, x_axis, 0, math.rad(250))
	Turn(ruparm, y_axis, 0, math.rad(250))
	Turn(ruparm, z_axis, 0, math.rad(250))
	Turn(rarm, x_axis, math.rad(2), math.rad(250))	 --up 2
	Turn(rarm, y_axis, 0, math.rad(250))
	Turn(rarm, z_axis, math.rad(-(-12)), math.rad(250))	--up -12
	Turn(rloarm, x_axis, math.rad(47), math.rad(250)) --up 47
	Turn(rloarm, y_axis, math.rad(76), math.rad(250)) --up 76
	Turn(rloarm, z_axis, math.rad(-(-47)), math.rad(250)) --up -47
	Turn(luparm, x_axis, math.rad(-9), math.rad(250))	 --up -9
	Turn(luparm, y_axis, 0, math.rad(250))
	Turn(luparm, z_axis, 0, math.rad(250))
	Turn(larm, x_axis, math.rad(5), math.rad(250))	 --up 5
	Turn(larm, y_axis, math.rad(-3), math.rad(250))	 --up -3
	Turn(larm, z_axis, math.rad(-(22)), math.rad(250))	 --up 22
	Turn(lloarm, x_axis, math.rad(92), math.rad(250))	-- up 82
	Turn(lloarm, y_axis, 0, math.rad(250))
	Turn(lloarm, z_axis, math.rad(-(94)), math.rad(250)) --upspring 94

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
	bMoving = true
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
	Turn(ruparm, z_axis, math.rad(-(10)), math.rad(250))
	
	Turn(rarm, x_axis, math.rad(41), math.rad(250))
	Turn(rarm, y_axis, math.rad(19), math.rad(250))
	Turn(rarm, z_axis, math.rad(-(-3)), math.rad(250))
	
	Turn(rloarm, x_axis, math.rad(18), math.rad(250))
	Turn(rloarm, y_axis, math.rad(19), math.rad(250))
	Turn(rloarm, z_axis, math.rad(-(14)), math.rad(250))
	
	Turn(gun, x_axis, math.rad(15.0), math.rad(250))
	Turn(gun, y_axis, math.rad(-15.0), math.rad(250))
	Turn(gun, z_axis, math.rad(31), math.rad(250))
	--larm
	Turn(luparm, x_axis, math.rad(-80), math.rad(250))
	Turn(luparm, y_axis, math.rad(-15), math.rad(250))
	Turn(luparm, z_axis, math.rad(-10), math.rad(250))
	
	Turn(larm, x_axis, math.rad(5), math.rad(250))
	Turn(larm, y_axis, math.rad(-77), math.rad(250))
	Turn(larm, z_axis, math.rad(-(-26)), math.rad(250))
	
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
	script.StopMoving()
	inJumpMode = false
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
		Turn(rloleg, z_axis, math.rad(-(3)), math.rad(250))
		Turn(lupleg, x_axis, math.rad(7), math.rad(250))
		Turn(lloleg, y_axis, math.rad(21), math.rad(250))
		Turn(lfoot, x_axis, math.rad(24), math.rad(250))
		
		GG.Script.InitializeDeathAnimation(unitID)
		Sleep(200) --give time to fall
		Turn(ruparm, x_axis, math.rad(-48), math.rad(350))
		Turn(ruparm, y_axis, math.rad(32), math.rad(350)) --was -32
		Turn(luparm, x_axis, math.rad(-50), math.rad(350))
		Turn(luparm, y_axis, math.rad(47), math.rad(350))
		Turn(luparm, z_axis, math.rad(-(50)), math.rad(350))
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

