include "constants.lua"
include "JumpRetreat.lua"

local spSetUnitShieldState = Spring.SetUnitShieldState

--------------------------------------------------------------------------------
-- pieces
--------------------------------------------------------------------------------
local base = piece 'base'
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
		Turn(torso, x_axis, math.rad(12)) --tilt forward
		Turn(torso, y_axis, math.rad(3.335165))
	end
	Move(pelvis, y_axis, 0)
	Turn(rupleg, x_axis, math.rad(5.670330))
	Turn(lupleg, x_axis, math.rad(-26.467033))
	Turn(lloleg, x_axis, math.rad(26.967033))
	Turn(rloleg, x_axis, math.rad(26.967033))
	Turn(rfoot, x_axis, math.rad(-19.824176))
	Sleep(90) --had to + 20 to all sleeps in walk

	if not bAiming then
		Turn(torso, y_axis, math.rad(1.681319))
	end
	Turn(rupleg, x_axis, math.rad(-5.269231))
	Turn(lupleg, x_axis, math.rad(-20.989011))
	Turn(lloleg, x_axis, math.rad(20.945055))
	Turn(rloleg, x_axis, math.rad(41.368132))
	Turn(rfoot, x_axis, math.rad(-15.747253))
	Sleep(70)
	
	if not bAiming then
		Turn(torso, y_axis, 0)
	end
	Turn(rupleg, x_axis, math.rad(-9.071429))
	Turn(lupleg, x_axis, math.rad(-12.670330))
	Turn(lloleg, x_axis, math.rad(12.670330))
	Turn(rloleg, x_axis, math.rad(43.571429))
	Turn(rfoot, x_axis, math.rad(-12.016484))
	Sleep(50)

	if not bAiming then
		Turn(torso, y_axis, math.rad(-1.77))
	end
	Turn(rupleg, x_axis, math.rad(-21.357143))
	Turn(lupleg, x_axis, math.rad(2.824176))
	Turn(lloleg, x_axis, math.rad(3.560440))
	Turn(lfoot, x_axis, math.rad(-4.527473))
	Turn(rloleg, x_axis, math.rad(52.505495))
	Turn(rfoot, x_axis, 0)
	Sleep(40)
	
	if not bAiming then
		Turn(torso, y_axis, math.rad(-3.15))
	end
	Turn(rupleg, x_axis, math.rad(-35.923077))
	Turn(lupleg, x_axis, math.rad(7.780220))
	Turn(lloleg, x_axis, math.rad(8.203297))
	Turn(lfoot, x_axis, math.rad(-12.571429))
	Turn(rloleg, x_axis, math.rad(54.390110))
	Sleep(50)

	if not bAiming then
		Turn(torso, y_axis, math.rad(-4.2))
	end
	Turn(rupleg, x_axis, math.rad(-37.780220))
	Turn(lupleg, x_axis, math.rad(10.137363))
	Turn(lloleg, x_axis, math.rad(13.302198))
	Turn(lfoot, x_axis, math.rad(-16.714286))
	Turn(rloleg, x_axis, math.rad(32.582418))
	Sleep(50)

	if not bAiming then
		Turn(torso, y_axis, math.rad(-3.15))
	end
	Turn(rupleg, x_axis, math.rad(-28.758242))
	Turn(lupleg, x_axis, math.rad(12.247253))
	Turn(lloleg, x_axis, math.rad(19.659341))
	Turn(lfoot, x_axis, math.rad(-19.659341))
	Turn(rloleg, x_axis, math.rad(28.758242))
	Sleep(90)

	if not bAiming then
		Turn(torso, y_axis, math.rad(-1.88))
	end
	Turn(rupleg, x_axis, math.rad(-22.824176))
	Turn(lupleg, x_axis, math.rad(2.824176))
	Turn(lloleg, x_axis, math.rad(34.060440))
	Turn(rfoot, x_axis, math.rad(-6.313187))
	Sleep(70)

	if not bAiming then
		Turn(torso, y_axis, 0)
	end
	Turn(rupleg, x_axis, math.rad(-11.604396))
	Turn(lupleg, x_axis, math.rad(-6.725275))
	Turn(lloleg, x_axis, math.rad(39.401099))
	Turn(lfoot, x_axis, math.rad(-13.956044))
	Turn(rloleg, x_axis, math.rad(19.005495))
	Turn(rfoot, x_axis, math.rad(-7.615385))
	Sleep(50)

	if not bAiming then
		Turn(torso, y_axis, math.rad(1.88))
	end
	Turn(rupleg, x_axis, math.rad(1.857143))
	Turn(lupleg, x_axis, math.rad(-24.357143))
	Turn(lloleg, x_axis, math.rad(45.093407))
	Turn(lfoot, x_axis, math.rad(-7.703297))
	Turn(rloleg, x_axis, math.rad(3.560440))
	Turn(rfoot, x_axis, math.rad(-4.934066))
	Sleep(40)

	if not bAiming then
		Turn(torso, y_axis, math.rad(3.15))
	end
	Turn(rupleg, x_axis, math.rad(7.148352))
	Turn(lupleg, x_axis, math.rad(-28.181319))
	Turn(rfoot, x_axis, math.rad(-9.813187))
	Sleep(50)

	if not bAiming then
		Turn(torso, y_axis, math.rad(4.2))
	end
	Turn(rupleg, x_axis, math.rad(8.423077))
	Turn(lupleg, x_axis, math.rad(-32.060440))
	Turn(lloleg, x_axis, math.rad(27.527473))
	Turn(lfoot, x_axis, math.rad(-2.857143))
	Turn(rloleg, x_axis, math.rad(24.670330))
	Turn(rfoot, x_axis, math.rad(-33.313187))
	Sleep(70)
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
				Turn(rupleg, x_axis, 0, math.rad(200.071429))
				Turn(rloleg, x_axis, 0, math.rad(200.071429))
				Turn(rfoot, x_axis, 0, math.rad(200.071429))
				Turn(lupleg, x_axis, 0, math.rad(200.071429))
				Turn(lloleg, x_axis, 0, math.rad(200.071429))
				Turn(lfoot, x_axis, 0, math.rad(200.071429))
				if not aiming then
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
	return armhold
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
	if num >= 5 then
		Signal(SIG_AIM)
		SetSignalMask(SIG_AIM)
		bAiming = true
		return AimRifle(heading, pitch)
	elseif num == 3 then
		Signal(SIG_AIM)
		Signal(SIG_AIM_2)
		SetSignalMask(SIG_AIM_2)
		bAiming = true
		return AimRifle(heading, pitch, canDgun)
	elseif num == 2 or num == 4 then
		Sleep(100)
		return (shieldOn)
	end
	return false
end

function script.Activate()
	--spSetUnitShieldState(unitID, true)
end

function script.Deactivate()
	--spSetUnitShieldState(unitID, false)
end

function script.QueryWeapon(num)
	if num == 3 then
		return grenade
	elseif num == 2 or num == 4 then
		return torso
	end
	return flare
end

function script.FireWeapon(num)
	if num == 3 then
		EmitSfx(grenade, 1026)
	elseif num == 5 then
		EmitSfx(flare, 1024)
	end
end

function script.Shot(num)
	if num == 3 then
		EmitSfx(grenade, 1027)
	elseif num == 5 then
		EmitSfx(flare, 1025)
	end
end

local function JumpExhaust()
	while inJumpMode do
		EmitSfx(jx1, 1028)
		EmitSfx(jx2, 1028)
		Sleep(33)
	end
end

function preJump(turn, distance)
end

function beginJump()
	inJumpMode = true
	--[[
	StartThread(JumpExhaust)
	--]]
end

function jumping()
	GG.PokeDecloakUnit(unitID, 50)
	EmitSfx(jx1, 1028)
	EmitSfx(jx2, 1028)
end

function halfJump()
end

function endJump()
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

function script.QueryNanoPiece()
	GG.LUPS.QueryNanoPiece(unitID,unitDefID,Spring.GetUnitTeam(unitID),nanospray)
	return nanospray
end

function script.Killed(recentDamage, maxHealth)
	local severity = recentDamage/maxHealth
	dead = true
--	Turn(turret, y_axis, 0, math.rad(500))
	if severity <= 0.5 and not inJumpMode then
		Turn(base, x_axis, math.rad(80), math.rad(80))
		Turn(turret, x_axis, math.rad(-16), math.rad(50))
		Turn(turret, y_axis, 0, math.rad(90))
		Turn(rloleg, x_axis, math.rad(9), math.rad(250))
		Turn(rloleg, y_axis, math.rad(-73), math.rad(250))
		Turn(rloleg, z_axis, math.rad(-(3)), math.rad(250))
		Turn(lupleg, x_axis, math.rad(7), math.rad(250))
		Turn(lloleg, y_axis, math.rad(21), math.rad(250))
		Turn(lfoot, x_axis, math.rad(24), math.rad(250))
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
		return 1
	elseif severity <= 0.5 then
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
		return 1
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
		return 2
	end
end

