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

local INLOS = {inlos = true}

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

wepTable = nil
local canDgun = UnitDefs[unitDefID].canDgun

local dead = false
local bMoving = false
local bAiming = false
local armsFree = true
local shieldOn = true
local dgunning = false
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

local dgunTable

function script.Create()

	-- copy the dgun command table because we sometimes need to reinsert it
	local cmdID = Spring.FindUnitCmdDesc(unitID, CMD.MANUALFIRE)
	dgunTable = Spring.GetUnitCmdDescs(unitID, cmdID)[1]

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
	StartThread(SmokeUnit, smokePiece)
	Spring.SetUnitNanoPieces(unitID, nanoPieces)
	
	if Spring.GetUnitRulesParam(unitID, "comm_weapon_id_1") then
		UpdateWeapons(
			{
				weaponDefID = Spring.GetUnitRulesParam(unitID, "comm_weapon_id_1"),
				num = Spring.GetUnitRulesParam(unitID, "comm_weapon_num_1"),
				manualFire = Spring.GetUnitRulesParam(unitID, "comm_weapon_manual_1"),
			},
			{
				weaponDefID = Spring.GetUnitRulesParam(unitID, "comm_weapon_id_2"),
				num = Spring.GetUnitRulesParam(unitID, "comm_weapon_num_2"),
				manualFire = Spring.GetUnitRulesParam(unitID, "comm_weapon_manual_2"),
			},
			{
				weaponDefID = Spring.GetUnitRulesParam(unitID, "comm_shield_id"),
				num = Spring.GetUnitRulesParam(unitID, "comm_shield_num"),
			},
			Spring.GetUnitRulesParam(unitID, "comm_range_mult")
		)
	end
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
	if isDgun then dgunning = true end
	--[[
	if dgunning and not isDgun then
		return false
	end
	]]--
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
	if isDgun then dgunning = false end	
	return true
end

local isManual = {}

local weapon1
local weapon2
local shield

function UpdateWeapons(w1, w2, sh, rangeMult)
	weapon1 = w1 and w1.num
	weapon2 = w2 and w2.num
	shield  = sh and sh.num
	
	local hasManualFire = (w1 and w1.manualFire) or (w2 and w2.manualFire)
	local cmdDesc = Spring.FindUnitCmdDesc(unitID, CMD.MANUALFIRE)
	if not hasManualFire and cmdDesc then
		Spring.RemoveUnitCmdDesc(unitID, cmdDesc)
	elseif hasManualFire and not cmdDesc then
		cmdDesc = Spring.FindUnitCmdDesc(unitID, CMD.ATTACK) + 1 -- insert after attack so that it appears in the correct spot in the menu
		Spring.InsertUnitCmdDesc(unitID, cmdDesc, dgunTable)
	end

	local maxRange = 0
	local otherRange = false
	if w1 then
		isManual[weapon1] = w1.manualFire
		local range = tonumber(WeaponDefs[w1.weaponDefID].range)*rangeMult
		if w1.manualFire then
			otherRange = range
		else
			maxRange = range
		end
		Spring.SetUnitWeaponState(unitID, w1.num, "range", range)
	end
	if w2 then
		isManual[weapon2] = w2.manualFire
		local range = tonumber(WeaponDefs[w2.weaponDefID].range)*rangeMult
		if maxRange then
			if w2.manualFire then
				otherRange = range
			elseif range > maxRange then
				otherRange = maxRange
				maxRange = range
			elseif range < maxRange then
				otherRange = range
			end
		else
			maxRange = range
		end
		Spring.SetUnitWeaponState(unitID, w2.num, "range", range)
	end
	
	Spring.SetUnitWeaponState(unitID, 1, "range", maxRange)
	Spring.SetUnitMaxRange(unitID, maxRange)
	
	if otherRange then
		Spring.SetUnitRulesParam(unitID, "secondary_range", otherRange, INLOS)
	end
	
	-- shields
	Spring.SetUnitShieldState(unitID, 2, false)
	Spring.SetUnitShieldState(unitID, 3, false)
	
	if (shield) then
		Spring.SetUnitShieldState(unitID, shield, true)
	end
end

function script.AimWeapon(num, heading, pitch)
	if num == shield then 
		return true 
	end
	
	local curWep
	
	if num == weapon1 then
		Signal(SIG_AIM)
		SetSignalMask(SIG_AIM)
	elseif num == weapon2 then
		Signal(SIG_AIM_2)
		SetSignalMask(SIG_AIM_2)
	else
		return false
	end

	return AimRifle(heading, pitch, isManual[num])	
end

function script.Activate()
	--spSetUnitShieldState(unitID, true)
end

function script.Deactivate()
	--spSetUnitShieldState(unitID, false)
end

function script.QueryWeapon(num)
	if num == shield or not weapon1 then
		return pelvis
	end
	return flare
end

function script.FireWeapon(num)
	EmitSfx(flare, 1024)
end

function script.Shot(num)
	EmitSfx(flare, 1025)
	if flamers[num] then
		--GG.LUPS.FlameShot(unitID, unitDefID, _, num)
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

local commWreckUnitRulesParam = {"comm_baseWreckID", "comm_baseHeapID"}
local moduleWreckNamePrefix = {"module_wreck_", "module_heap_"}

local function SpawnModuleWreck(moduleDefID, wreckLevel, totalCount, teamID, x, y, z, vx, vy, vz)
	local featureDefID = FeatureDefNames[moduleWreckNamePrefix[wreckLevel] .. moduleDefID]
	if not featureDefID then
		Spring.Echo("Cannot find module wreck", moduleWreckNamePrefix[wreckLevel] .. moduleDefID)
		return
	end
	featureDefID = featureDefID.id
	
	local dir = math.random(2*math.pi)
	local pitch = (math.random(2)^2 - 1)*math.pi/2
	local heading = math.random(65536)
	local mag = 10 + math.random(10)*totalCount
	local horScale = mag*math.cos(pitch)
	vx, vy, vz = vx + math.cos(dir)*horScale, vy + math.sin(pitch)*mag, vz + math.sin(dir)*horScale
	
	local featureID = Spring.CreateFeature(featureDefID, x + vx, y, z + vz, heading, teamID)
end

local function SpawnModuleWrecks(wreckLevel)
	local x, y, z, mx, my, mz = Spring.GetUnitPosition(unitID, true)
	local vx, vy, vz = Spring.GetUnitVelocity(unitID)
	local teamID	= Spring.GetUnitTeam(unitID)
	
	local weaponCount = Spring.GetUnitRulesParam(unitID, "comm_weapon_count")
	local moduleCount = Spring.GetUnitRulesParam(unitID, "comm_module_count")
	local totalCount = weaponCount + moduleCount
	
	for i = 1, weaponCount do
		SpawnModuleWreck(Spring.GetUnitRulesParam(unitID, "comm_weapon_" .. i), wreckLevel, totalCount, teamID, x, y, z, vx, vy, vz)
	end
	
	for i = 1, moduleCount do
		SpawnModuleWreck(Spring.GetUnitRulesParam(unitID, "comm_module_" .. i), wreckLevel, totalCount, teamID, x, y, z, vx, vy, vz)
	end
end

local function SpawnWreck(wreckLevel)
	local makeRezzable = (wreckLevel == 1)
	local wreckDef = FeatureDefs[Spring.GetUnitRulesParam(unitID, commWreckUnitRulesParam[wreckLevel])]
	
	local x, y, z = Spring.GetUnitPosition(unitID)
	
	local vx, vy, vz = Spring.GetUnitVelocity(unitID)
	
	if (wreckDef) then
		local heading   = Spring.GetUnitHeading(unitID)
		local teamID	= Spring.GetUnitTeam(unitID)
		local featureID = Spring.CreateFeature(wreckDef.id, x, y, z, heading, teamID)
		Spring.SetFeatureVelocity(featureID, vx, vy, vz)
		if makeRezzable then
			local baseUnitDefID = Spring.GetUnitRulesParam(unitID, "comm_baseUnitDefID") or unitDefID
			Spring.SetFeatureResurrect(featureID, UnitDefs[baseUnitDefID].name)
		end
	end
end

function script.Killed(recentDamage, maxHealth)
	local severity = recentDamage/maxHealth
	dead = true
--	Turn(turret, y_axis, 0, math.rad(500))
	if severity <= 0.5 and not inJumpMode then
		SpawnModuleWrecks(1)
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
		SpawnWreck(1)
	elseif severity <= 0.5 then
		SpawnModuleWrecks(1)
		Explode(gun,	sfxFall + sfxSmoke + sfxExplode)
		Explode(head, sfxFire + sfxExplode)
		Explode(pelvis, sfxFire + sfxExplode)
		Explode(lloarm, sfxFire + sfxExplode)
		Explode(luparm, sfxFire + sfxExplode)
		Explode(lloleg, sfxFire + sfxExplode)
		Explode(lupleg, sfxFire + sfxExplode)
		Explode(rloarm, sfxFire + sfxExplode)
		Explode(rloleg, sfxFall + sfxFire + sfxSmoke + sfxExplode)
		Explode(ruparm, sfxFall + sfxFire + sfxSmoke + sfxExplode)
		Explode(rupleg, sfxFall + sfxFire + sfxSmoke + sfxExplode)
		Explode(torso, sfxShatter + sfxExplode)
		SpawnWreck(1)
	else
		SpawnModuleWrecks(2)
		Explode(gun, sfxFall + sfxFire + sfxSmoke + sfxExplode)
		Explode(head, sfxFall + sfxFire + sfxSmoke + sfxExplode)
		Explode(pelvis, sfxFall + sfxFire + sfxSmoke + sfxExplode)
		Explode(lloarm, sfxFall + sfxFire + sfxSmoke + sfxExplode)
		Explode(luparm, sfxFall + sfxFire + sfxSmoke + sfxExplode)
		Explode(lloleg, sfxFall + sfxFire + sfxSmoke + sfxExplode)
		Explode(lupleg, sfxFall + sfxFire + sfxSmoke + sfxExplode)
		Explode(rloarm, sfxFall + sfxFire + sfxSmoke + sfxExplode)
		Explode(rloleg, sfxFall + sfxFire + sfxSmoke + sfxExplode)
		Explode(ruparm, sfxFall + sfxFire + sfxSmoke + sfxExplode)
		Explode(rupleg, sfxFall + sfxFire + sfxSmoke + sfxExplode)
		Explode(torso, sfxShatter + sfxExplode)
		SpawnWreck(2)
	end
end

