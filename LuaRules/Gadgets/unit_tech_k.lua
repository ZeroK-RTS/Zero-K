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

local autoAiTech = Spring.GetModOptions().aiusetechk ~= "0"

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local IterableMap = VFS.Include("LuaRules/Gadgets/Include/IterableMap.lua")
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

local aiAllyTeamInfo = autoAiTech and {}
local aiTeamAlly = autoAiTech and {}

local tintCycle = {
	{1, 0.6, 0.9},
	{1, 0.75, 0.6},
	{0.72, 0.82, 1},
}

local commUpgraders = {
	[UnitDefNames["striderhub"].id] = true
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

local mexDefs = {}
local function IsMex(unitDefID)
	if not mexDefs[unitDefID] then
		local ud = UnitDefs[unitDefID]
		mexDefs[unitDefID] = ud.customParams.ismex and 1 or 0
	end
	return mexDefs[unitDefID] == 1
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

local isComm = {}
local function IsComm(unitDefID)
	if not isComm[unitDefID] then
		local ud = UnitDefs[unitDefID]
		isComm[unitDefID] = (ud.customParams.dynamic_comm or ud.customParams.commtype) and 1 or 0
	end
	return isComm[unitDefID] == 1
end

local isBuilder = {}
local function IsBuilder(unitDefID)
	if not isBuilder[unitDefID] then
		local ud = UnitDefs[unitDefID]
		isBuilder[unitDefID] = ud.canRepair and 1 or 0
	end
	return isBuilder[unitDefID] == 1
end

local function IsTechBuilder(unitID, unitDefID)
	if not IsBuilder(unitDefID) then
		return
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
	if not unitDefID then
		return
	end
	--Spring.Utilities.UnitEcho(unitID, level)
	
	local sizeScale = math.pow(1.6, math.pow(level, 0.45) - 1)
	local projectiles = math.pow(2, level - 1)
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
		--move =  math.pow(0.95, level - 1),
		range = range,
		jumpRange = range,
		cost = simpleDoubling,
		econ = math.pow(4/3, level - 1),
		energy = math.pow(9/4, level - 1), -- Effective 3x
		mass = simpleDoubling,
		shieldRegen = simpleDoubling,
		shieldMax = math.pow(1.8, level - 1),
		healthRegen = simpleDoubling,
		build = simpleDoubling,
		healthMult = simpleDoubling,
		projSpeed = math.sqrt(range), -- Maintains Cannon range.
		minSpray = (math.pow(level, 0.25) - 1) * 0.04,
		deathExplode = simpleDoubling,
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
	if not IsBuilding(targetUnitDef) and not (commUpgraders[unitDefID] and IsComm(targetUnitDef)) then
		return false
	end
	local builderLevel = (unitLevel[unitID] or 1)
	local targetLevel = (unitLevel[targetID] or 1)
	if GetFactory(unitDefID) == targetUnitDef then
		-- Constructors can upgrade their factory to one beyond their own level
		builderLevel = builderLevel + 1
	end
	local plateParent = GG.FactoryPlate_GetPlateParent(targetID)
	if plateParent and (unitLevel[plateParent] or 1) > builderLevel then
		builderLevel = (unitLevel[plateParent] or 1)
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
	local distance = Spring.GetUnitSeparation(unitID, targetID, true, true)
	if distance < buildRange then
		local health, maxHealth, _, _, buildProgress = Spring.GetUnitHealth(targetID)
		if buildProgress >= 1 then
			if (unitLevel[targetID] or 1) >= builderLevel then
				return true -- Nothing to do
			end
			local midDistance = Spring.GetUnitSeparation(unitID, targetID, true)
			if midDistance < buildRange - 10 then
				-- https://github.com/beyond-all-reason/spring/issues/1698
				Spring.GiveOrderToUnit(unitID, CMD.INSERT, {0, CMD.RECLAIM, 0, targetID}, CMD.OPT_ALT)
				local cmdID, cmdOpts, cmdTag, cp_1, cp_2, cp_3 = Spring.GetUnitCurrentCommand(unitID)
				reclaimToRemoveUnit = reclaimToRemoveUnit or {}
				reclaimToRemoveUnit[unitID] = Spring.GetGameFrame() + 150
			else
				if not goalSet[unitID] then
					Spring.SetUnitMoveGoal(unitID, tx, ty, tz, buildRange - 50)
					goalSet[unitID] = true
				end
			end
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
		Spring.SetUnitMoveGoal(unitID, tx, ty, tz, buildRange - 50)
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
-- AI Handling

local function SpawnCeg(unitID, level)
	local ux, uy, uz = Spring.GetUnitPosition(unitID)
	local ud = UnitDefs[Spring.GetUnitDefID(unitID)]
	Spring.SpawnCEG("resurrect", ux, uy, uz, 0, 0, 0, (ud.xsize or 4) * (1 + 0.05*level))
end

local function SetNormalTechInvestment(allyTeamID)
	local allyData = aiAllyTeamInfo[allyTeamID]
	if not allyData then
		return
	end
	allyData.onlyUpgradeMax = (math.random() > 0.8)
	for i = 1, #allyData.aiTeams do
		local teamID = allyData.aiTeams[i]
		GG.Overdrive.SetMetalIncomeSkim(teamID, "tech_factory", allyData.factoryMult * (0.05 + 0.04*math.random()) * (3 / (1 + allyData.techLevel)))
		GG.Overdrive.SetMetalIncomeSkim(teamID, "tech_mex", 0.12 + 0.06*math.random())
		GG.Overdrive.SetMetalIncomeSkim(teamID, "tech_other", 0.02 + 0.04*math.random())
	end
end

local function SetCatchupTechInvestment(allyTeamID)
	local allyData = aiAllyTeamInfo[allyTeamID]
	if not allyData then
		return
	end
	allyData.onlyUpgradeMax = true
	for i = 1, #allyData.aiTeams do
		local teamID = allyData.aiTeams[i]
		GG.Overdrive.SetMetalIncomeSkim(teamID, "tech_factory", allyData.factoryMult * (0.15 + 0.1*math.random()) * (1.5 / (1 + allyData.techLevel / 2)))
		GG.Overdrive.SetMetalIncomeSkim(teamID, "tech_mex", 0.04 + 0.03*math.random())
		GG.Overdrive.SetMetalIncomeSkim(teamID, "tech_other",  0.01)
	end
end

local function UpdateTechStatus(allyTeamID, myLevel, enemyLevel, factoryMult)
	local allyData = aiAllyTeamInfo[allyTeamID]
	local change = false
	if myLevel and myLevel > allyData.techLevel then
		allyData.techLevel = myLevel
		change = true
	end
	if enemyLevel and enemyLevel > allyData.spottedTechLevel then
		allyData.spottedTechLevel = enemyLevel
		change = true
	end
	if factoryMult and factoryMult ~= allyData.factoryMult then
		allyData.factoryMult = factoryMult
		change = true
	end
	if not change then
		return
	end
	if allyData.techLevel < allyData.spottedTechLevel then
		SetCatchupTechInvestment(allyTeamID)
	else
		SetNormalTechInvestment(allyTeamID)
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- AI Setup

local function AddFactorySkimMetal(teamID, metal)
	local allyData = aiAllyTeamInfo[aiTeamAlly[teamID]]
	local unitID = IterableMap.Next(allyData.factories)
	if not unitID then
		return
	end
	if not Spring.ValidUnitID(unitID) then
		IterableMap.Remove(allyData.factories, unitID)
		return
	end
	local unitLevel = (unitLevel[unitID] or 1)
	allyData.factoryMetal = allyData.factoryMetal + metal
	local cost = Spring.Utilities.GetUnitCost(unitID)
	if allyData.factoryMetal >= cost and not Spring.GetUnitIsStunned(unitID) then
		if (not allyData.onlyUpgradeMax) or (unitLevel == allyData.techLevel) then
			allyData.factoryMetal = allyData.factoryMetal - cost
			allyData.bestFactoryProgress = 0
			UpdateTechStatus(aiTeamAlly[teamID], unitLevel + 1)
			SetUnitTechLevel(unitID, unitLevel + 1)
			SpawnCeg(unitID, unitLevel)
		end
	end
	allyData.bestFactoryProgress = math.max(allyData.bestFactoryProgress, allyData.factoryMetal / cost)
	UpdateTechStatus(aiTeamAlly[teamID], false, false, (allyData.bestFactoryProgress > 0.15 and 3.5) or 0.2)
	--Spring.Echo("allyData.factoryMetal", allyData.factoryMetal)
	return true
end

local function AddMexSkimMetal(teamID, metal)
	local allyData = aiAllyTeamInfo[aiTeamAlly[teamID]]
	local unitID = IterableMap.Next(allyData.mexes)
	if not unitID then
		return
	end
	if not Spring.ValidUnitID(unitID) then
		IterableMap.Remove(allyData.mexes, unitID)
		return
	end
	local unitLevel = (unitLevel[unitID] or 1)
	if unitLevel >= allyData.techLevel then
		return
	end
	allyData.mexMetal = allyData.mexMetal + metal
	local cost = Spring.Utilities.GetUnitCost(unitID)
	if allyData.mexMetal >= cost and not Spring.GetUnitIsStunned(unitID) then
		allyData.mexMetal = allyData.mexMetal - cost
		SetUnitTechLevel(unitID, unitLevel + 1)
		SpawnCeg(unitID, unitLevel)
	end
	return true
end

local function AddOtherSkimMetal(teamID, metal)
	local allyData = aiAllyTeamInfo[aiTeamAlly[teamID]]
	local unitID = IterableMap.Next(allyData.other)
	if not unitID then
		return
	end
	if not Spring.ValidUnitID(unitID) then
		IterableMap.Remove(allyData.other, unitID)
		return
	end
	local unitLevel = (unitLevel[unitID] or 1)
	if unitLevel >= allyData.techLevel then
		return
	end
	allyData.otherMetal = allyData.otherMetal + metal
	local cost = Spring.Utilities.GetUnitCost(unitID)
	if allyData.otherMetal >= cost and not Spring.GetUnitIsStunned(unitID) then
		allyData.otherMetal = allyData.otherMetal - cost
		SetUnitTechLevel(unitID, unitLevel + 1)
		SpawnCeg(unitID, unitLevel)
	end
	return true
end

local function AddAiUnit(unitID, unitDefID, teamID)
	if IsFactory(unitDefID) then
		local allyData = aiAllyTeamInfo[aiTeamAlly[teamID]]
		UpdateTechStatus(aiTeamAlly[teamID], unitLevel[unitID] or 1)
		IterableMap.Add(allyData.factories, unitID)
	elseif IsMex(unitDefID) then
		local allyData = aiAllyTeamInfo[aiTeamAlly[teamID]]
		IterableMap.Add(allyData.mexes, unitID)
	elseif IsBuilding(unitDefID) then
		local allyData = aiAllyTeamInfo[aiTeamAlly[teamID]]
		IterableMap.Add(allyData.other, unitID)
	end
end

local function RemoveAiUnit(unitID, unitDefID, teamID)
	if IsFactory(unitDefID) then
		local allyData = aiAllyTeamInfo[aiTeamAlly[teamID]]
		IterableMap.Remove(allyData.factories, unitID)
		allyData.techLevel = 1
		for unitID, _ in IterableMap.Iterator(allyData.factories) do
			allyData.techLevel = math.max(allyData.techLevel, unitLevel[unitID] or 1)
		end
	elseif IsMex(unitDefID) then
		local allyData = aiAllyTeamInfo[aiTeamAlly[teamID]]
		IterableMap.Remove(allyData.mexes, unitID)
	elseif IsBuilding(unitDefID) then
		local allyData = aiAllyTeamInfo[aiTeamAlly[teamID]]
		IterableMap.Remove(allyData.other, unitID)
	end
end

local function SetupAiTeams()
	if not autoAiTech then
		return
	end
	
	local teamList = Spring.GetTeamList()
	for i = 1, #teamList do
		local teamID = teamList[i]
		local _, _, _, isAiTeam, _, allyTeamID = Spring.GetTeamInfo(teamID, false)
		if isAiTeam then
			if not aiAllyTeamInfo[allyTeamID] then
				aiAllyTeamInfo[allyTeamID] = {
					aiTeams = {},
					factories = IterableMap.New(),
					mexes = IterableMap.New(),
					other = IterableMap.New(),
					factoryMetal = 0,
					mexMetal = 0,
					otherMetal = 0,
					techLevel = 1,
					spottedTechLevel = 1,
					factoryMult = 1,
					bestFactoryProgress = 0,
				}
			end
			local allyData = aiAllyTeamInfo[allyTeamID]
			allyData.aiTeams[#allyData.aiTeams + 1] = teamID
			aiTeamAlly[teamID] = allyTeamID
			GG.Overdrive.SetMetalIncomeSkim(teamID, "tech_factory", 0, AddFactorySkimMetal)
			GG.Overdrive.SetMetalIncomeSkim(teamID, "tech_mex", 0, AddMexSkimMetal)
			GG.Overdrive.SetMetalIncomeSkim(teamID, "tech_other", 0, AddOtherSkimMetal)
		end
	end
	
	local allyTeamList = Spring.GetAllyTeamList()
	for i = 1, #allyTeamList do
		SetNormalTechInvestment(allyTeamList[i])
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

function gadget:UnitCreated(unitID, unitDefID, teamID, builderID)
	if builderID and Spring.GetUnitCurrentCommand(builderID) == CMD.RESURRECT then
		return
	end
	if builderID and (unitLevel[builderID] or 1) > 1 then
		SetUnitTechLevel(unitID, unitLevel[builderID])
	end
	if IsTechBuilder(unitID, unitDefID) then
		hasTechCommand[unitID] = true
		Spring.InsertUnitCmdDesc(unitID, techCommandData.cmdDesc)
	end
	if aiTeamAlly and aiTeamAlly[teamID] then
		AddAiUnit(unitID, unitDefID, teamID)
	end
end

function gadget:UnitDestroyed(unitID, unitDefID, teamID)
	hasTechCommand[unitID] = nil
	if (unitLevel[unitID] or 1) <= 1 then
		return
	end
	if aiTeamAlly and aiTeamAlly[teamID] then
		RemoveAiUnit(unitID, unitDefID, teamID)
	end
	local _,_,_,_,build  = Spring.GetUnitHealth(unitID)
	if build and build < 0.8 then
		return
	end
	if GG.MorphDestroy ~= unitID then
		AddFeature(unitID, unitDefID, teamID, unitLevel[unitID])
	end
end

if autoAiTech then
	function gadget:UnitGiven(unitID, unitDefID, teamID, oldTeamID)
		local _,_,_,_,_,newAllyTeam = Spring.GetTeamInfo(teamID, false)
		local _,_,_,_,_,oldAllyTeam = Spring.GetTeamInfo(oldTeamID, false)
		if newAllyTeam ~= oldAllyTeam and aiTeamAlly and aiTeamAlly[teamID] then
			AddAiUnit(unitID, unitDefID, teamID)
		end
	end

	function gadget:UnitTaken(unitID, unitDefID, oldTeamID, teamID)
		local _,_,_,_,_,newAllyTeam = Spring.GetTeamInfo(teamID, false)
		local _,_,_,_,_,oldAllyTeam = Spring.GetTeamInfo(oldTeamID, false)
		if newAllyTeam ~= oldAllyTeam and aiTeamAlly and aiTeamAlly[teamID] then
			RemoveAiUnit(unitID, unitDefID, teamID)
		end
	end
		
	function gadget:UnitEnteredLos(unitID, teamID, allyTeamID, unitDefID)
		if not aiAllyTeamInfo[allyTeamID] then
			return
		end
		if Spring.GetUnitAllyTeam(unitID) ~= allyTeamID then
			local level = unitLevel[unitID] or 1
			UpdateTechStatus(allyTeamID, false, level)
		end
	end
end

function GG.GetUnitTechLevel(unitID)
	return unitLevel and unitID and unitLevel[unitID] or 1
end

local function TechUpAll(cmd,line,words,player)
	if not Spring.IsCheatingEnabled() then
		return
	end
	for _, unitID in ipairs(Spring.GetAllUnits()) do
		SetUnitTechLevel(unitID, (unitLevel[unitID] or 1) + 1)
	end
end

function gadget:Initialize()
	gadgetHandler:AddChatAction("techup", TechUpAll, "Increment tech levels by 1.")
	GG.SetUnitTechLevel = SetUnitTechLevel
	SetupAiTeams()
	gadgetHandler:RegisterCMDID(CMD_TECH_UP)
	for _, unitID in ipairs(Spring.GetAllUnits()) do
		local level = Spring.GetUnitRulesParam(unitID, "tech_level")
		if level or autoAiTech then
			if level then
				SetUnitTechLevel(unitID, level)
			end
			local unitDefID = Spring.GetUnitDefID(unitID)
			local teamID = Spring.GetUnitTeam(unitID)
			gadget:UnitCreated(unitID, unitDefID, teamID)
		end
	end
end
