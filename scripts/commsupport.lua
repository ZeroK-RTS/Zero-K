include "constants.lua"

local spSetUnitShieldState = Spring.SetUnitShieldState

-- pieces
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
local SIG_RESTORE = 16
local SIG_AIM = 2
local SIG_AIM_2 = 4
local SIG_WALK = 1
--local SIG_AIM_3 = 8 --step on

--------------------------------------------------------------------------------
-- vars
--------------------------------------------------------------------------------
local flamers = {}
local wepTable = UnitDefs[unitDefID].weapons
wepTable.n = nil
for index, weapon in pairs(wepTable) do
	local weaponDef = WeaponDefs[weapon.weaponDef]
	if weaponDef.type == "Flame" or (weaponDef.customParams and weaponDef.customParams.flamethrower) then
		flamers[index] = true
	end
end

local restoreHeading, restorePitch = 0, 0

local canDgun = UnitDefs[unitDefID].canDgun

local shieldOn = false
local dead = false
local bMoving = false
local bAiming = false
local armsFree = true
local inBuildAnim = false
local dgunning = false

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
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
	if not bAiming then
		Turn(torso, x_axis, math.rad(12)) --tilt forward
		Turn(torso, y_axis, math.rad(3.335165))
	end
	Move(pelvis, y_axis, 0)
	Turn(rupleg, x_axis, math.rad(5.670330), math.rad(75))
	Turn(lupleg, x_axis, math.rad(-26.467033), math.rad(75))
	Turn(lloleg, x_axis, math.rad(26.967033), math.rad(75))
	Turn(rloleg, x_axis, math.rad(26.967033), math.rad(75))
	Turn(rfoot, x_axis, math.rad(-19.824176), math.rad(75))
	Sleep(180) --had to + 20 to all sleeps in walk
	
	if not bAiming then
		Turn(torso, y_axis, math.rad(1.681319))
	end
	Turn(rupleg, x_axis, math.rad(-5.269231), math.rad(75))
	Turn(lupleg, x_axis, math.rad(-20.989011), math.rad(75))
	Turn(lloleg, x_axis, math.rad(20.945055), math.rad(75))
	Turn(rloleg, x_axis, math.rad(41.368132), math.rad(75))
	Turn(rfoot, x_axis, math.rad(-15.747253))
	Sleep(160)
	
	if not bAiming then
		Turn(torso, y_axis, 0)
	end
	Turn(rupleg, x_axis, math.rad(-9.071429), math.rad(75))
	Turn(lupleg, x_axis, math.rad(-12.670330), math.rad(75))
	Turn(lloleg, x_axis, math.rad(12.670330), math.rad(75))
	Turn(rloleg, x_axis, math.rad(43.571429), math.rad(75))
	Turn(rfoot, x_axis, math.rad(-12.016484), math.rad(75))
	Sleep(140)
	
	if not bAiming then
		Turn(torso, y_axis, math.rad(-1.77))
	end
	Turn(rupleg, x_axis, math.rad(-21.357143), math.rad(75))
	Turn(lupleg, x_axis, math.rad(2.824176), math.rad(75))
	Turn(lloleg, x_axis, math.rad(3.560440), math.rad(75))
	Turn(lfoot, x_axis, math.rad(-4.527473), math.rad(75))
	Turn(rloleg, x_axis, math.rad(52.505495), math.rad(75))
	Turn(rfoot, x_axis, 0)
	Sleep(140)
	
	if not bAiming then
		Turn(torso, y_axis, math.rad(3.15))
	end
	Turn(rupleg, x_axis, math.rad(-35.923077), math.rad(75))
	Turn(lupleg, x_axis, math.rad(7.780220), math.rad(75))
	Turn(lloleg, x_axis, math.rad(8.203297), math.rad(75))
	Turn(lfoot, x_axis, math.rad(-12.571429), math.rad(75))
	Turn(rloleg, x_axis, math.rad(54.390110), math.rad(75))
	Sleep(140)
	
	if not bAiming then
		Turn(torso, y_axis, math.rad(-4.21))
	end
	Turn(rupleg, x_axis, math.rad(-37.780220), math.rad(75))
	Turn(lupleg, x_axis, math.rad(10.137363), math.rad(75))
	Turn(lloleg, x_axis, math.rad(13.302198), math.rad(75))
	Turn(lfoot, x_axis, math.rad(-16.714286), math.rad(75))
	Turn(rloleg, x_axis, math.rad(32.582418), math.rad(75))
	Sleep(140)
	
	if not bAiming then
		Turn(torso, y_axis, math.rad(-3.15))
	end
	Turn(rupleg, x_axis, math.rad(-28.758242), math.rad(75))
	Turn(lupleg, x_axis, math.rad(12.247253), math.rad(75))
	Turn(lloleg, x_axis, math.rad(19.659341), math.rad(75))
	Turn(lfoot, x_axis, math.rad(-19.659341), math.rad(75))
	Turn(rloleg, x_axis, math.rad(28.758242), math.rad(75))
	Sleep(160)
	
	if not bAiming then
		Turn(torso, y_axis, math.rad(-1.88))
	end
	Turn(rupleg, x_axis, math.rad(-22.824176), math.rad(75))
	Turn(lupleg, x_axis, math.rad(2.824176), math.rad(75))
	Turn(lloleg, x_axis, math.rad(34.060440), math.rad(75))
	Turn(rfoot, x_axis, math.rad(-6.313187), math.rad(75))
	Sleep(160)
	
	if not bAiming then
		Turn(torso, y_axis, 0)
	end
	Turn(rupleg, x_axis, math.rad(-11.604396), math.rad(75))
	Turn(lupleg, x_axis, math.rad(-6.725275), math.rad(75))
	Turn(lloleg, x_axis, math.rad(39.401099), math.rad(75))
	Turn(lfoot, x_axis, math.rad(-13.956044), math.rad(75))
	Turn(rloleg, x_axis, math.rad(19.005495), math.rad(75))
	Turn(rfoot, x_axis, math.rad(-7.615385), math.rad(75))
	Sleep(140)
	
	if not bAiming then
		Turn(torso, y_axis, math.rad(1.88))
	end
	Turn(rupleg, x_axis, math.rad(1.857143), math.rad(75))
	Turn(lupleg, x_axis, math.rad(-24.357143), math.rad(75))
	Turn(lloleg, x_axis, math.rad(45.093407), math.rad(75))
	Turn(lfoot, x_axis, math.rad(-7.703297), math.rad(75))
	Turn(rloleg, x_axis, math.rad(3.560440), math.rad(75))
	Turn(rfoot, x_axis, math.rad(-4.934066), math.rad(75))
	Sleep(140)
	
	if not bAiming then
		Turn(torso, y_axis, math.rad(3.15))
	end
	Turn(rupleg, x_axis, math.rad(7.148352), math.rad(75))
	Turn(lupleg, x_axis, math.rad(-28.181319), math.rad(75))
	Sleep(140)
	
	if not bAiming then
		Turn(torso, y_axis, math.rad(4.20))
	end
	Turn(rupleg, x_axis, math.rad(8.423077), math.rad(75))
	Turn(lupleg, x_axis, math.rad(-32.060440), math.rad(75))
	Turn(lloleg, x_axis, math.rad(27.527473), math.rad(75))
	Turn(lfoot, x_axis, math.rad(-2.857143), math.rad(75))
	Turn(rloleg, x_axis, math.rad(24.670330), math.rad(75))
	Turn(rfoot, x_axis, math.rad(-33.313187), math.rad(75))
	Sleep(160)
end

local function MotionControl(moving, aiming, justmoved)
	justmoved = true
	while true do
		moving = bMoving
		aiming = bAiming
		if moving then
			if aiming then
				armsFree = true
			else
				armsFree = false
			end
			Walk()
			justmoved = true
		else
			armsFree = true
			if justmoved then
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

	StartThread(MotionControl)
	StartThread(RestoreAfterDelay)
	StartThread(GG.Script.SmokeUnit, smokePiece)
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
	return armhold
end

function script.QueryWeapon(num)
	if num == 2 or num == 4 then
		return pelvis
	end
	return flare
end

local function AimRifle(heading, pitch, isDgun)
	if isDgun then dgunning = true end
	--[[
	if dgunning and not isDgun then
		return false
	end
	]]--
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
	WaitForTurn(lloarm, x_axis) --stil setting up
	StartThread(RestoreAfterDelay)
	if isDgun then dgunning = false end
	return true
end

function script.AimWeapon(num, heading, pitch)
	inBuildAnim = false
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

function script.FireWeapon(num)
	if num == 5 then
		EmitSfx(flare, 1024)
	elseif num == 3 then
		EmitSfx(flare, 1026)
	end
	--recoil
	--[[
	if num ~= 4 then
		Sleep(50)
		Turn(gun, x_axis, math.rad(-2), math.rad(1250))
		Sleep(250)
		Turn(gun, x_axis, 0, math.rad(250))
		Sleep(800)
		if (math.random() < 0.33) then
			Turn(armhold, x_axis, math.rad(15), math.rad(75)) --check the sexy shot
		end
	end
	]]--
end

function script.Shot(num)
	if num == 5 then
		EmitSfx(flare, 1025)
	elseif num == 3 then
		EmitSfx(flare, 1027)
	end
	if flamers[num] then
		--GG.LUPS.FlameShot(unitID, unitDefID, _, num)
	end	
end

function script.QueryNanoPiece()
	GG.LUPS.QueryNanoPiece(unitID,unitDefID,Spring.GetUnitTeam(unitID),nanospray)
	return nanospray
end

function script.StopBuilding()
	inBuildAnim = false
	SetUnitValue(COB.INBUILDSTANCE, 0)
	if not bAiming then
		StartThread(RestoreAfterDelay)
	end
end

function script.StartBuilding(heading, pitch) 
	restoreHeading, restorePitch = heading, pitch
	BuildPose(heading, pitch)
	SetUnitValue(COB.INBUILDSTANCE, 1)
end

function script.Killed(recentDamage, maxHealth)
	local severity = recentDamage/maxHealth
	dead = 1
	--Turn(turret, y_axis, 0, math.rad(500))
	if severity <= .5 then
	
		Turn(base, x_axis, math.rad(79), math.rad(80))
		Turn(rloleg, x_axis, math.rad(25), math.rad(250))	
		Turn(lupleg, x_axis, math.rad(7), math.rad(250))	
		Turn(lupleg, y_axis, math.rad(34), math.rad(250))	
		Turn(lupleg, z_axis, math.rad(-(-9)), math.rad(250))	
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