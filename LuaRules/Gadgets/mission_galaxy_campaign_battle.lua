--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
if not gadgetHandler:IsSyncedCode() then
	return
end
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
function gadget:GetInfo()
	return {
		name = "Galaxy Campaign Battle Handler",
		desc = "Implements unit locks and structure placement.",
		author = "GoogleFrog",
		date = "6 February 2017",
		license = "GNU GPL, v2 or later",
		layer = 0, -- Before game_over.lua for the purpose of setting vitalUnit
		enabled = true
	}
end

local campaignBattleID = Spring.GetModOptions().singleplayercampaignbattleid
if not campaignBattleID then
	return
end

local alliedTrueTable = {allied = true}
local CMD_INSERT = CMD.INSERT

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Variables

local unlockedUnitsByTeam = {}
local unitLineage = {}
local vitalUnits = {}
local teamCommParameters = {}
local victoryAtLocation
local defeatConditionConfig
local firstGameFrame = true
local checkForLoseAfterSeconds = false
local allyTeamList = Spring.GetAllyTeamList()

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Utility

local BUILD_RESOLUTION = 16

local function CustomKeyToUsefulTable(dataRaw)
	if not dataRaw then
		return
	end
	if not (dataRaw and type(dataRaw) == 'string') then
		if dataRaw then
			Spring.Echo("Customkey data error for team", teamID)
		end
	else
		dataRaw = string.gsub(dataRaw, '_', '=')
		dataRaw = Spring.Utilities.Base64Decode(dataRaw)
		local dataFunc, err = loadstring("return " .. dataRaw)
		if dataFunc then 
			local success, usefulTable = pcall(dataFunc)
			if success then
				if collectgarbage then
					Spring.Echo("collectgarbage")
					collectgarbage("collect")
				end
				return usefulTable
			end
		end
		if err then
			Spring.Echo("Customkey error", err)
		end
	end
	if collectgarbage then
		collectgarbage("collect")
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Victory and Defeat functions

local function IsVitalUnitType(unitID, unitDefID)
	-- Commanders are handled seperately
	local allyTeamID = Spring.GetUnitAllyTeam(unitID)
	if not allyTeamID then
		Spring.Echo("IsVitalUnitType missing allyTeamID")
		return
	end
	local defeatConfig = defeatConditionConfig[allyTeamID]
	return defeatConfig.vitalUnitTypes and defeatConfig.vitalUnitTypes[unitDefID]
end

local function InitializeVictoryConditions()
	defeatConditionConfig = CustomKeyToUsefulTable(Spring.GetModOptions().defeatconditionconfig) or {}
	for i = 1, #allyTeamList do
		local allyTeamID = allyTeamList[i]
		local defeatConfig = defeatConditionConfig[allyTeamID] or {}
		if defeatConfig.vitalUnitTypes then
			local unitsByDefID = {}
			for i = 1, #defeatConfig.vitalUnitTypes do
				local ud = UnitDefNames[defeatConfig.vitalUnitTypes[i]]
				if ud then
					unitsByDefID[#unitsByDefID + 1] = ud.id
				end
			end
			defeatConfig.vitalUnitTypes = unitsByDefID
		end
		if defeatConfig.loseAfterSeconds then
			checkForLoseAfterSeconds = true
		end
		defeatConditionConfig[allyTeamID] = defeatConfig
	end
	
	Spring.Utilities.TableEcho(defeatConditionConfig, "defeatConditionConfig")
end

local function AddDefeatIfUnitDestroyed(unitID)
	local allyTeamID = Spring.GetUnitAllyTeam(unitID)
	local defeatConfig = defeatConditionConfig[allyTeamID]
	defeatConfig.defeatIfUnitDestroyed = defeatConfig.defeatIfUnitDestroyed or {}
	defeatConfig.defeatIfUnitDestroyed[unitID] = true
	
	if allyTeamID == 0 then
		Spring.Utilities.UnitEcho(unitID, "Protect")
	else
		Spring.Utilities.UnitEcho(unitID, "Kill")
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Victory at location units

local function AddVictoryAtLocationUnit(unitID, location)
	victoryAtLocation = victoryAtLocation or {}
	victoryAtLocation[unitID] = {
		x = location.x,
		z = location.z,
		radiusSq = location.radius*location.radius,
		allyTeamID = Spring.GetUnitAllyTeam(unitID)
	}
	
	Spring.MarkerAddPoint(location.x, 0, location.z, "Walk Here")
end

local function DoVictoryAtLocationCheck(unitID, location)
	if not Spring.ValidUnitID(unitID) then
		return false
	end
	if Spring.GetUnitAllyTeam(unitID) ~= location.allyTeamID then
		return false
	end
	local x, _, z = Spring.GetUnitPosition(unitID)
	if (x - location.x)^2 + (z - location.z)^2 <= location.radiusSq then
		return true
	end
	return false
end

local function VictoryAtLocationUpdate()
	if not victoryAtLocation then
		return
	end
	for unitID, data in pairs(victoryAtLocation) do
		if DoVictoryAtLocationCheck(unitID, data) then
			GG.CauseVictory(data.allyTeamID)
			return
		end
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Unit Placement

local function PlaceUnit(unitData, teamID)
	local name = unitData.name
	local ud = UnitDefNames[name]
	if not (ud and ud.id) then
		Spring.Echo("Missing unit placement", name)
		return
	end
	
	local x, z, facing = unitData.x, unitData.z, unitData.facing
	
	if ud.isBuilding or ud.speed == 0 then
		local oddX = (ud.xsize % 4 == 2)
		local oddZ = (ud.zsize % 4 == 2)
		
		if facing % 2 == 1 then
			oddX, oddZ = oddZ, oddX
		end
		
		if oddX then
			x = math.floor((x + 8)/BUILD_RESOLUTION)*BUILD_RESOLUTION - 8
		else
			x = math.floor(x/BUILD_RESOLUTION)*BUILD_RESOLUTION
		end
		if oddZ then
			z = math.floor((z + 8)/BUILD_RESOLUTION)*BUILD_RESOLUTION - 8
		else
			z = math.floor(z/BUILD_RESOLUTION)*BUILD_RESOLUTION
		end
	end
	
	local build = (unitData.buildProgress and unitData.buildProgress < 1) or false
	local unitID = Spring.CreateUnit(ud.id, x, Spring.GetGroundHeight(x,z), z, facing, teamID, build)
	
	if not unitID then
		Spring.MarkerAddPoint(x, 0, z, "Error creating unit " .. (((ud or {}).humanName) or "???"))
		return 
	end
	
	if unitData.defeatIfDestroyed then
		AddDefeatIfUnitDestroyed(unitID)
	end
	if unitData.victoryAtLocation then
		AddVictoryAtLocationUnit(unitID, unitData.victoryAtLocation)
	end
	
	if build then
		local _, maxHealth = Spring.GetUnitHealth(unitID)
		Spring.SetUnitHealth(unitID, {build = unitData.buildProgress, health = maxHealth*unitData.buildProgress})
	end
end

local function PlaceRetinueUnit(retinueID, range, unitDefName, spawnX, spawnZ, facing, teamID, experience)
	local unitDefID = UnitDefNames[unitDefName]
	unitDefID = unitDefID and unitDefID.id
	if not unitDefID then
		return
	end
	
	local validPlacement = false
	local x, z
	local tries = 0
	while not validPlacement do
		x, z = spawnX + math.random()*range*2 - range, spawnZ + math.random()*range*2 - range
		if tries < 10 then
			validPlacement = Spring.TestBuildOrder(unitDefID, x, 0, z, facing)
		elseif tries < 20 then
			validPlacement = Spring.TestMoveOrder(unitDefID, x, 0, z)
		else
			x, z =  spawnX + math.random()*2 - 1, spawnZ + math.random()*2 - 1
		end
	end
	
	local retinueUnitID = Spring.CreateUnit(unitDefID, x, Spring.GetGroundHeight(x,z), z, facing, teamID)
	Spring.SetUnitRulesParam(retinueUnitID, "retinueID", retinueID, {ally = true})
	Spring.SetUnitExperience(retinueUnitID, experience)
end

local function HandleCommanderCreation(unitID, teamID)
	local commParameters = teamCommParameters[teamID]
	if not commParameters then
		return
	end
	if commParameters.defeatIfDestroyed then
		AddDefeatIfUnitDestroyed(unitID)
	end
	if commParameters.victoryAtLocation then
		AddVictoryAtLocationUnit(unitID, commParameters.victoryAtLocation)
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Unit Locking System

local function RemoveUnit(unitID, lockDefID)
	local cmdDescID = Spring.FindUnitCmdDesc(unitID, -lockDefID)
	if (cmdDescID) then
		Spring.RemoveUnitCmdDesc(unitID, cmdDescID)
	end
end

local function LockUnit(unitID, lockDefID)
	local cmdDescID = Spring.FindUnitCmdDesc(unitID, -lockDefID)
	if (cmdDescID) then
		local cmdArray = {disabled = true}
		Spring.EditUnitCmdDesc(unitID, cmdDescID, cmdArray)
	end
end

local function SetBuildOptions(unitID, unitDefID, teamID)
	local ud = UnitDefs[unitDefID]
	if (ud.isBuilder) then
		local unlockedUnits = unlockedUnitsByTeam[teamID]
		if unlockedUnits then
			local buildoptions = ud.buildOptions
			for i = 1, #buildoptions do
				if not unlockedUnits[buildoptions[i]] then
					RemoveUnit(unitID, buildoptions[i])
				end
			end
		end
	end
end

function gadget:AllowCommand(unitID, unitDefID, unitTeamID, cmdID, cmdParams, cmdOpts)
	if cmdID == CMD_INSERT and cmdParams and cmdParams[2] then
		cmdID = cmdParams[2]
	end
	if cmdID < 0 and unlockedUnitsByTeam[unitTeamID] then
		if not (unlockedUnitsByTeam[unitTeamID][-cmdID]) then 
			return false
		end
	end
	return true
end

function gadget:AllowUnitCreation(unitDefID, builderID, builderTeamID, x, y, z)
	if unlockedUnitsByTeam[builderTeamID] then
		if not (unlockedUnitsByTeam[builderTeamID][unitDefID]) then 
			return false
		end
	end
	return true
end

function gadget:UnitCreated(unitID, unitDefID, teamID, builderID)
	local ud = UnitDefs[unitDefID]
	if ud.customParams.dynamic_comm then
		HandleCommanderCreation(unitID, teamID)
	end
	
	if builderID and unitLineage[builderID] then
		unitLineage[unitID] = unitLineage[builderID]
	else
		unitLineage[unitID] = teamID
	end
	SetBuildOptions(unitID, unitDefID, unitLineage[unitID])
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Initialization

local function SetTeamUnlocks(teamID, customKeys)
	local unlockData = CustomKeyToUsefulTable(customKeys and customKeys.campaignunlocks)
	if not unlockData then
		return
	end
	local unlockedUnits = {}
	local unlockCount = 0
	for i = 1, #unlockData do
		local ud = UnitDefNames[unlockData[i]]
		if ud and ud.id then
			unlockCount = unlockCount + 1
			Spring.SetTeamRulesParam(teamID, "unlockedUnit" .. unlockCount, ud.name, alliedTrueTable)
			unlockedUnits[ud.id] = true
		end
	end
	Spring.SetTeamRulesParam(teamID, "unlockedUnitCount", unlockCount, alliedTrueTable)
	unlockedUnitsByTeam[teamID] = unlockedUnits
end

local function PlaceTeamUnits(teamID, customKeys)
	local unitData = CustomKeyToUsefulTable(customKeys and customKeys.extrastartunits)
	if not unitData then
		return
	end
	
	for i = 1, #unitData do
		PlaceUnit(unitData[i], teamID)
	end
end

local function InitializeCommanderParameters(teamID, customKeys)
	local commParameters = CustomKeyToUsefulTable(customKeys and customKeys.commanderparameters)
	if not commParameters then
		return
	end
	teamCommParameters[teamID] = commParameters
end

local function InitializeUnlocks()
	local teamList = Spring.GetTeamList()
	for i = 1, #teamList do
		local teamID = teamList[i]
		local customKeys = select(7, Spring.GetTeamInfo(teamID))
		SetTeamUnlocks(teamID, customKeys)
		InitializeCommanderParameters(teamID, customKeys)
	end
end

local function DoInitialUnitPlacement()
	if Spring.GetGameRulesParam("loadedGame") then
		return
	end
	local teamList = Spring.GetTeamList()
	for i = 1, #teamList do
		local teamID = teamList[i]
		local customKeys = select(7, Spring.GetTeamInfo(teamID))
		PlaceTeamUnits(teamID, customKeys)
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Gadget Interface

local Unlocks = {}
local GalaxyCampaignHandler = {}

function Unlocks.GetIsUnitUnlocked(teamID, unitDefID)
	if unlockedUnitsByTeam[teamID] then
		if not (unlockedUnitsByTeam[teamID][unitDefID]) then 
			return false
		end
	end
	return true
end

function GalaxyCampaignHandler.VitalUnit(unitID)
	return vitalUnits[unitID]
end

function GalaxyCampaignHandler.GetDefeatConfig(allyTeamID)
	return defeatConditionConfig[allyTeamID]
end

function GalaxyCampaignHandler.DeployRetinue(unitID, x, z, facing, teamID)
	local customKeys = select(7, Spring.GetTeamInfo(teamID))
	local retinueData = CustomKeyToUsefulTable(customKeys and customKeys.retinuestartunits)
	if retinueData then
		local range = 70 + #retinueData*20
		for i = 1, #retinueData do
			local unitData = retinueData[i]
			PlaceRetinueUnit(unitData.retinueID, range, unitData.unitDefName, x, z, facing, teamID, unitData.experience)
		end
	end
end

function GalaxyCampaignHandler.DeployRetinue(unitID, x, z, facing, teamID)
	local customKeys = select(7, Spring.GetTeamInfo(teamID))
	local retinueData = CustomKeyToUsefulTable(customKeys and customKeys.retinuestartunits)
	if retinueData then
		local range = 70 + #retinueData*20
		for i = 1, #retinueData do
			local unitData = retinueData[i]
			PlaceRetinueUnit(unitData.retinueID, range, unitData.unitDefName, x, z, facing, teamID, unitData.experience)
		end
	end
end

function GalaxyCampaignHandler.HasFactoryPlop(teamID)
	return teamCommParameters[teamID] and teamCommParameters[teamID].facplop
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- (Most) callins

function gadget:UnitFinished(unitID, unitDefID, teamID, builderID)
	if IsVitalUnitType(unitID, unitDefID) then
		vitalUnits[unitID] = true
	end
end

function gadget:UnitDestroyed(unitID, unitDefID, teamID)
	if vitalUnits[unitID] then
		vitalUnits[unitID] = false
	end
end
function gadget:Initialize()
	InitializeUnlocks()
	InitializeVictoryConditions()
	
	local allUnits = Spring.GetAllUnits()
	for _, unitID in pairs(allUnits) do
		local unitDefID = Spring.GetUnitDefID(unitID)
		if unitDefID then
			gadget:UnitCreated(unitID, unitDefID, Spring.GetUnitTeam(unitID))
		end
	end
	
	GG.Unlocks = Unlocks
	GG.GalaxyCampaignHandler = GalaxyCampaignHandler
end

function gadget:GameFrame(n)
	if n%30 == 0 then
		VictoryAtLocationUpdate()
		if checkForLoseAfterSeconds then
			for i = 1, #allyTeamList do
				local lostAfterSeconds = defeatConditionConfig[allyTeamList[i]].loseAfterSeconds
				if lostAfterSeconds and lostAfterSeconds <= n/30 then
					GG.DestroyAlliance(allyTeamList[i])
				end
			end
		end
	end
	
	-- Would use GamePreload if it didn't cause Circuit to crash.
	if firstGameFrame then
		firstGameFrame = false
		DoInitialUnitPlacement()
	end
end
