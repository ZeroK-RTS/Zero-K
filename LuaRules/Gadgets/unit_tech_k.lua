--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local modoption = Spring.GetModOptions().techk
function gadget:GetInfo()
	return {
		name      = "Tech-K",
		desc      = "Implements Tech-K",
		author    = "GoogleFrog",
		date      = "16 September 2024",
		license   = "GNU GPL, v2 or later",
		layer     = 500,
		enabled   = (modoption == "1"),
	}
end

if not (modoption == "1") then
	return
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local modCommands, modCmdMap = VFS.Include("LuaRules/Configs/modCommandsDefs.lua")
local CMD_TECH_UP = Spring.Utilities.CMD.TECH_UP
local techCommandData = modCmdMap[CMD_TECH_UP]

if not gadgetHandler:IsSyncedCode() then
	function gadget:Initialize()
		Spring.AssignMouseCursor(techCommandData.cursor, "cursortechup", true, true)
		Spring.SetCustomCommandDrawData(CMD_TECH_UP, techCommandData.cursor, {0.7, 0.7, 0.8, 0.8})
	end
	return
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local INLOS_ACCESS = {inlos = true}
local explosionDefID = {}
local explosionRadius = {}
local deathCloneDefID = {}
local Vector = Spring.Utilities.Vector

local goalSet = {}
local unitLevel = {}
local hasTechCommand = {}
local reclaimToRemoveUnit = {}

local tintCycle = {
	{1, 0.6, 0.9},
	{1, 0.75, 0.6},
	{0.72, 0.82, 1},
}

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local factoryDefs = {}
local function IsFactory(unitDefID)
	if not factoryDefs[unitDefID] then
		local ud = UnitDefs[unitDefID]
		factoryDefs[unitDefID] = (ud.isFactory and (not ud.customParams.notreallyafactory) and ud.buildOptions) and 1 or 0
	end
	return factoryDefs[unitDefID] == 1
end

local buildingDefs = {}
local function IsBuilding(unitDefID)
	if not buildingDefs[unitDefID] then
		local ud = UnitDefs[unitDefID]
		buildingDefs[unitDefID] = (ud.speed == 0) and (not ud.customParams.mobilebuilding) and 1 or 0
	end
	return buildingDefs[unitDefID] == 1
end

local hasFactory = {}
local function GetFactory(unitDefID)
	if not hasFactory[unitDefID] then
		local ud = UnitDefs[unitDefID]
		local factory = ud.customParams.from_factory
		if factory then
			factory = UnitDefNames[factory].id
		end
		hasFactory[unitDefID] = factory or -1
	end
	return (hasFactory[unitDefID] >= 0) and hasFactory[unitDefID]
end

local isBuilder = {}
local function IsTechBuilder(unitID, unitDefID)
	if not isBuilder[unitDefID] then
		local ud = UnitDefs[unitDefID]
		isBuilder[unitDefID] = ud.canRepair and 1 or 0
	end
	if isBuilder[unitDefID] == 0 then
		return false
	end
	if not hasFactory[unitDefID] then
		local ud = UnitDefs[unitDefID]
		local factory = ud.customParams.from_factory
		if factory then
			factory = UnitDefNames[factory].id
		end
		hasFactory[unitDefID] = factory or -1
	end
	if hasFactory[unitDefID] >= 0 then
		return true
	end
	return (unitLevel[unitID] or 0) > 1
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local function SetUnitTechLevel(unitID, level)
	local unitDefID = Spring.GetUnitDefID(unitID)
	--Spring.Utilities.UnitEcho(unitID, level)
	
	local sizeScale = math.pow(1.6, math.pow(level, 0.45) - 1)
	local projectiles = math.pow(2, level - 1)
	local speed = math.pow(0.8, level - 1)
	local range = math.pow(1.1, level - 1)
	
	if level > 1 then
		local tintIndex = (level - 1)%(#tintCycle) + 1
		local tintTier = math.floor((level - 2)/(#tintCycle))
		local tint = tintCycle[tintIndex]
		local tr, tg, tb = math.pow(tint[1], 1 + tintTier), math.pow(tint[2], 1 + tintTier),math.pow(tint[3], 1 + tintTier)
		GG.TintUnit(unitID, tr, tg, tb)
	end
	
	local simpleDoubling = math.pow(2, level - 1)
	GG.Attributes.AddEffect(unitID, "tech", {
		projectiles = projectiles,
		speed = speed,
		range = range,
		cost = simpleDoubling,
		econ = math.pow(1.5, level - 1), -- 1.5x metal income
		energy = simpleDoubling, -- Effective 3x
		mass = simpleDoubling,
		shieldRegen = simpleDoubling,
		shieldMax = math.pow(1.75, level - 1),
		healthRegen = simpleDoubling,
		build = simpleDoubling,
		healthMult = simpleDoubling,
		projSpeed = math.sqrt(range), -- Maintains Cannon range.
		minSpray = (math.pow(level, 0.25) - 1) * 0.04,
		static = true,
	})
	GG.SetColvolScales(unitID, {1 + (sizeScale - 1)*0.1, sizeScale, 1 + (sizeScale - 1)*0.1})
	GG.UnitModelRescale(unitID, sizeScale)
	Spring.SetUnitRulesParam(unitID, "tech_level", level, INLOS_ACCESS)
	unitLevel[unitID] = level
	
	if (not hasTechCommand[unitID]) and IsTechBuilder(unitID, unitDefID) then
		hasTechCommand[unitID] = true
		Spring.InsertUnitCmdDesc(unitID, techCommandData.cmdDesc)
	end
	
	if GG.FactoryPlate_RefreshUnit then
		GG.FactoryPlate_RefreshUnit(unitID, unitDefID)
	end
end

local function AddExplosions(unitID, unitDefID, teamID, level)
	local extraExplosions = math.pow(2, level - 1) - 1
	if not explosionDefID[unitDefID] then
		local wd = WeaponDefNames[UnitDefs[unitDefID].deathExplosion]
		explosionDefID[unitDefID] = wd.id
		explosionRadius[unitDefID] = wd.damageAreaOfEffect or 0
	end
	local _, _, _, ux, uy, uz = Spring.GetUnitPosition(unitID, true)
	local projectileParams = {
		pos = {ux, uy, uz},
		["end"] = {ux, uy - 1, uz},
		owner = unitID,
		team = teamID,
		ttl = 0,
	}
	local radius = (5 + 15*level)*(50 + math.pow(explosionRadius[unitDefID], 0.8))/100
	for i = 1, extraExplosions do
		local rand = Vector.RandomPointInCircle(radius)
		projectileParams.pos[1] = ux + rand[1]
		projectileParams.pos[3] = uz + rand[2]
		local proID = Spring.SpawnProjectile(explosionDefID[unitDefID], projectileParams)
		if proID then
			Spring.SetProjectileCollision(proID)
		end
	end
end

local function AddFeature(unitID, unitDefID, teamID, level)
	local _,_,inBuild = Spring.GetUnitIsStunned(unitID)
	if inBuild then
		return
	end
	local extraFeatures = math.pow(2, level - 1) - 1
	if not deathCloneDefID[unitDefID] then
		local wreckName = UnitDefs[unitDefID].wreckName
		deathCloneDefID[unitDefID] = (wreckName and FeatureDefNames[wreckName] and FeatureDefNames[wreckName].id) or -1
	end
	if deathCloneDefID[unitDefID] == -1 then
		return
	end
	local _, _, _, ux, uy, uz = Spring.GetUnitPosition(unitID, true)
	local vx, vy, vz = Spring.GetUnitVelocity(unitID, true)
	local allyTeamID = Spring.GetUnitAllyTeam(unitID)
	local maxMag = 1 + 3*level
	for i = 1, extraFeatures do
		local rand, randMag = Vector.RandomPointInCircle(maxMag)
		local featureID = Spring.CreateFeature(deathCloneDefID[unitDefID], ux + rand[1]*0.4, uy, uz + rand[2]*0.4, math.random()*2^16, allyTeamID)
		if featureID then
			local ySpeed = (1.2*maxMag - randMag) * (0.7 + 0.3 * math.random())
			Spring.SetFeatureVelocity(featureID, rand[1]*0.1 + vx, ySpeed*0.1 + vy, rand[2]*0.1 + vz)
		end
	end
end

local function CheckTechCommand(unitID, unitDefID, unitTeam, cmdParams)
	local targetID = cmdParams[1]
	if not Spring.ValidUnitID(targetID) then
		return false
	end
	local isBuilder = IsTechBuilder(unitID, unitDefID)
	if not isBuilder then
		return false
	end
	local targetTeam = Spring.GetUnitTeam(targetID)
	if not (targetTeam and Spring.AreTeamsAllied(targetTeam, unitTeam)) then
		return false
	end
	local targetUnitDef = Spring.GetUnitDefID(targetID)
	if not IsBuilding(targetUnitDef) then
		return false
	end
	local builderLevel = (unitLevel[unitID] or 1)
	local targetLevel = (unitLevel[targetID] or 1)
	if GetFactory(unitDefID) == targetUnitDef then
		-- Constructors can upgrade their factory to one beyond their own level
		builderLevel = builderLevel + 1
	end
	local _, _, _, _, buildProgress = Spring.GetUnitHealth(targetID)
	local isNanoframe = buildProgress < 1
	return isNanoframe or builderLevel > targetLevel, builderLevel
end

local function HandleTechCommand(unitID, unitDefID, unitTeam, cmdID, cmdParams, cmdOptions)
	local validCommand, builderLevel = CheckTechCommand(unitID, unitDefID, unitTeam, cmdParams)
	if not validCommand then
		return true
	end
	local targetID = cmdParams[1]
	local tx, ty, tz = Spring.GetUnitPosition(targetID)
	if not tx then
		return true
	end

	local buildRange = Spring.Utilities.GetUnitBuildRange(unitID, unitDefID)
	if Spring.GetUnitSeparation(unitID, targetID, true, true) < buildRange - 10 then
		local health, maxHealth, _, _, buildProgress = Spring.GetUnitHealth(targetID)
		if buildProgress >= 1 then
			if (unitLevel[targetID] or 1) >= builderLevel then
				return true -- Nothing to do
			end
			-- https://github.com/beyond-all-reason/spring/issues/1698
			Spring.GiveOrderToUnit(unitID, CMD.INSERT, {0, CMD.RECLAIM, 0, targetID}, CMD.OPT_ALT)
			local cmdID, cmdOpts, cmdTag, cp_1, cp_2, cp_3 = Spring.GetUnitCurrentCommand(unitID)
			reclaimToRemoveUnit = reclaimToRemoveUnit or {}
			reclaimToRemoveUnit[unitID] = Spring.GetGameFrame() + 20
			return false
		end
		if (unitLevel[targetID] or 1) < builderLevel then
			local cost = Spring.Utilities.GetUnitCost(targetID)
			SetUnitTechLevel(targetID, builderLevel)
			local newCost = Spring.Utilities.GetUnitCost(targetID)
			Spring.SetUnitHealth(targetID, {build = cost / newCost * buildProgress, health = health})
		end
		Spring.GiveOrderToUnit(unitID, CMD.INSERT, {0, CMD.REPAIR, CMD.OPT_SHIFT, targetID}, CMD.OPT_ALT)
		return false
	end
	if not goalSet[unitID] then
		Spring.SetUnitMoveGoal(unitID, tx, ty, tz, buildRange - 30)
		goalSet[unitID] = true
	end
	return false
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function gadget:AllowCommand(unitID, unitDefID, unitTeam, cmdID, cmdParams, cmdOptions)
	if goalSet[unitID] then
		goalSet[unitID] = nil
	end
	if cmdID == CMD_TECH_UP then
		if cmdParams[2] then
			return false -- LuaUI can handle area-tech
		end
		return CheckTechCommand(unitID, unitDefID, unitTeam, cmdParams)
	end
	return true
end

function gadget:CommandFallback(unitID, unitDefID, unitTeam, cmdID, cmdParams, cmdOptions)
	if cmdID == CMD_TECH_UP then
		if cmdParams[2] then
			return true, true
		end
		return true, HandleTechCommand(unitID, unitDefID, unitTeam, cmdID, cmdParams, cmdOptions)
	end
	return false
end

function gadget:GameFrame(n)
	if not reclaimToRemoveUnit then
		return
	end
	local hasAny = false
	for unitID, frame in pairs(reclaimToRemoveUnit) do
		hasAny = true
		if Spring.ValidUnitID(unitID) then
			local cmdID, cmdOpts, cmdTag, cp_1, cp_2, cp_3 = Spring.GetUnitCurrentCommand(unitID)
			if cmdID == CMD.RECLAIM and Spring.ValidUnitID(cp_1) then
				local health, maxHealth, _, _, buildProgress = Spring.GetUnitHealth(cp_1)
				if buildProgress < 1 then
					Spring.GiveOrderToUnit(unitID, CMD.REMOVE, {cmdTag}, 0)
					reclaimToRemoveUnit[unitID] = nil
				end
			end
		end
		if frame < n then
			reclaimToRemoveUnit[unitID] = nil
		end
	end
	if not hasAny then
		reclaimToRemoveUnit = false
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local techInheritMechanics = {
	teleport_beacon = true,
	grey_goo = true,
	carrier_drones = true,
	morph = true,
}

function gadget:UnitCreatedByMechanic(unitID, parentID, mechanic, extraData)
	if techInheritMechanics[mechanic] then
		if unitLevel[parentID] then
			SetUnitTechLevel(unitID, unitLevel[parentID])
		end
	end
end

function gadget:UnitCreated(unitID, unitDefID, unitTeam, builderID)
	if builderID and (unitLevel[builderID] or 1) > 1 then
		SetUnitTechLevel(unitID, unitLevel[builderID])
	end
	if IsTechBuilder(unitID, unitDefID) then
		hasTechCommand[unitID] = true
		Spring.InsertUnitCmdDesc(unitID, techCommandData.cmdDesc)
	end
end

function gadget:UnitDestroyed(unitID, unitDefID, teamID)
	hasTechCommand[unitID] = nil
	if (unitLevel[unitID] or 1) <= 1 then
		return
	end
	local _,_,_,_,build  = Spring.GetUnitHealth(unitID)
	if build and build < 0.8 then
		return
	end
	AddExplosions(unitID, unitDefID, teamID, unitLevel[unitID])
	AddFeature(unitID, unitDefID, teamID, unitLevel[unitID])
end

function GG.GetUnitTechLevel(unitID)
	return unitLevel and unitID and unitLevel[unitID] or 1
end

function gadget:Initialize()
	GG.SetUnitTechLevel = SetUnitTechLevel
	gadgetHandler:RegisterCMDID(CMD_TECH_UP)
	for _, unitID in ipairs(Spring.GetAllUnits()) do
		local level = Spring.GetUnitRulesParam(unitID, "tech_level")
		if level then
			SetUnitTechLevel(unitID, level)
			local unitDefID = Spring.GetUnitDefID(unitID)
			local teamID = Spring.GetUnitTeam(unitID)
			gadget:UnitCreated(unitID, unitDefID, teamID)
		end
	end
end
