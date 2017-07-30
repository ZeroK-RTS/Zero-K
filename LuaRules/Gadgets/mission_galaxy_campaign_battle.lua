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
local missionDifficulty = tonumber(Spring.GetModOptions().planetmissiondifficulty) or 2
if not campaignBattleID then
	return
end

local CRASH_CIRCUIT = Spring.GetModOptions().crashcircuit

local COMPARE = {
	AT_LEAST = 1,
	AT_MOST = 2
}

local alliedTrueTable = {allied = true}
local CMD_INSERT = CMD.INSERT
local PLAYER_ALLY_TEAM_ID = 0
local PLAYER_TEAM_ID = 0

local SAVE_FILE = "Gadgets/mission_galaxy_campaign_battle.lua"
local loadGameFrame = 0

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
if gadgetHandler:IsSyncedCode() then --SYNCED
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Variables

-- Variables that require saving
local unitLineage = {}
local initialUnitData = {}
local bonusObjectiveList = {}

local commandsToGive = nil -- Give commands just after game start

-- Regeneratable
local vitalUnits = {}
local defeatConditionConfig
local victoryAtLocation = {}

local unlockedUnitsByTeam = {}
local teamCommParameters = {}

local enemyUnitDefBonusObj = {}
local myUnitDefBonusObj = {}
local checkForLoseAfterSeconds = false
local completeAllBonusObjectiveID
local timeLossObjectiveID

-- Small speedup things.
local firstGameFrame = true
local gameIsOver = false
local allyTeamList = Spring.GetAllyTeamList()

GG.terraformRequiresUnlock = true
GG.terraformUnlocked = {}

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- For gadget:Save

_G.saveTable = {
	unitLineage        = unitLineage,
	initialUnitData    = initialUnitData,
	bonusObjectiveList = bonusObjectiveList,
}

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

local function SumUnits(units, limit)
	if not units then
		return 0
	end
	local count = 0
	for unitID, wantedAllyTeamID in pairs(units) do
		local inbuild = select(3, Spring.GetUnitIsStunned(unitID))
		if not inbuild then
			local allyTeamID = Spring.GetUnitAllyTeam(unitID)
			if allyTeamID == wantedAllyTeamID then
				count = count + 1
				if count >= limit then
					return count
				end
			end
		end
	end
	return count
end

local function ComparisionSatisfied(compareType, targetNumber, number)
	if compareType == COMPARE.AT_LEAST then
		return number >= targetNumber
	elseif compareType == COMPARE.AT_MOST then
		return number <= targetNumber
	end
	return false
end

local function SanitizeBuildPositon(x, z, ud, facing)
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
	return x, z
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
			local unitDefMap = {}
			for i = 1, #defeatConfig.vitalUnitTypes do
				local ud = UnitDefNames[defeatConfig.vitalUnitTypes[i]]
				if ud then
					unitDefMap[ud.id] = true
				end
			end
			defeatConfig.vitalUnitTypes = unitDefMap
		end
		if defeatConfig.loseAfterSeconds then
			checkForLoseAfterSeconds = true
		end
		defeatConditionConfig[allyTeamID] = defeatConfig
	end
end

local function AddDefeatIfUnitDestroyed(unitID, allyTeamID, objectiveID)
	local defeatConfig = defeatConditionConfig[allyTeamID]
	defeatConfig.defeatIfUnitDestroyed = defeatConfig.defeatIfUnitDestroyed or {}
	defeatConfig.defeatIfUnitDestroyed[unitID] = (objectiveID or true)
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Victory at location units

local function AddVictoryAtLocationUnit(unitID, location, allyTeamID)
	victoryAtLocation = victoryAtLocation or {}
	victoryAtLocation[unitID] = {
		x = location.x,
		z = location.z,
		radiusSq = location.radius*location.radius,
		allyTeamID = allyTeamID
	}
	
	if location.mapMarker then
		SendToUnsynced("AddMarker", math.floor(location.x) .. math.floor(location.z), location.x, location.z, location.mapMarker.text, location.mapMarker.color)
	end
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
			if data.objectiveID then
				Spring.SetGameRulesParam("objectiveSuccess_" .. data.objectiveID, (Spring.GetUnitAllyTeam(unitID) == PLAYER_ALLY_TEAM_ID and 1) or 0)
			end
			GG.CauseVictory(data.allyTeamID)
			return
		end
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Bonus Objectives

local function AllOtherObjectivesSucceeded(ignoreObjectiveID)
	for i = 1, #bonusObjectiveList do
		if i ~= ignoreObjectiveID then
			if not bonusObjectiveList[i].success then
				return false
			end
		end
	end
	return true
end

local function CompleteBonusObjective(bonusObjectiveID, success)
	local objectiveData = bonusObjectiveList[bonusObjectiveID]
	Spring.SetGameRulesParam("bonusObjectiveSuccess_" .. bonusObjectiveID, (success and 1) or 0)
	
	objectiveData.success = success
	objectiveData.terminated = true
	
	if completeAllBonusObjectiveID and bonusObjectiveID ~= completeAllBonusObjectiveID then
		if success then
			if AllOtherObjectivesSucceeded(completeAllBonusObjectiveID) then
				CompleteBonusObjective(completeAllBonusObjectiveID, true)
			end
		else
			CompleteBonusObjective(completeAllBonusObjectiveID, false)
		end
	end
end

local function CheckBonusObjective(bonusObjectiveID, gameSeconds, victory)
	local objectiveData = bonusObjectiveList[bonusObjectiveID]
	gameSeconds = gameSeconds or math.floor(Spring.GetGameFrame()/30), victory
	
	-- Cbeck whether the objective is open
	if objectiveData.terminated then
		return
	end
	
	if objectiveData.completeAllBonusObjectives then
		return -- Not handled here
	end
	
	-- Check for victory timer
	if objectiveData.victoryByTime then
		if victory then
			CompleteBonusObjective(bonusObjectiveID, true)
		elseif gameSeconds > objectiveData.victoryByTime then
			CompleteBonusObjective(bonusObjectiveID, false)
		end
		return
	end
	
	-- Check whether the objective is in the right timeframe and whether it passes/fails
	-- Times: satisfyAtTime, satisfyByTime, satisfyUntilTime, satisfyAfterTime, satisfyForeverAfterFirstSatisfied, satisfyOnce or satisfyForever
	if objectiveData.satisfyByTime and (objectiveData.satisfyByTime < gameSeconds) then
		CompleteBonusObjective(bonusObjectiveID, false)
		return
	end
	if objectiveData.satisfyUntilTime and (objectiveData.satisfyUntilTime < gameSeconds) then
		CompleteBonusObjective(bonusObjectiveID, true)
		return
	end
	if objectiveData.satisfyAfterTime and (objectiveData.satisfyAfterTime >= gameSeconds) then
		return
	end
	if objectiveData.satisfyAtTime and (objectiveData.satisfyAtTime ~= gameSeconds) then
		return
	end
	
	-- Objective may have succeeded if the game ends.
	if gameIsOver and (objectiveData.satisfyForever or objectiveData.satisfyUntilTime or objectiveData.satisfyAfterTime or objectiveData.satisfyForever) then
		CompleteBonusObjective(bonusObjectiveID, true)
		return
	end
	
	-- Check satisfaction
	local unitCount = SumUnits(objectiveData.units, objectiveData.targetNumber + 1) + (objectiveData.removedUnits or 0)
	if objectiveData.onlyCountRemovedUnits then
		unitCount = objectiveData.removedUnits or 0
	end
	local satisfied = ComparisionSatisfied(objectiveData.comparisionType, objectiveData.targetNumber, unitCount)
	if satisfied then
		if objectiveData.satisfyAtTime or objectiveData.satisfyByTime or objectiveData.satisfyOnce then
			CompleteBonusObjective(bonusObjectiveID, true)
		end
		if objectiveData.satisfyForeverAfterFirstSatisfied then
			objectiveData.satisfyForeverAfterFirstSatisfied = nil
			objectiveData.satisfyForever = true
		end
		if objectiveData.lockUnitsOnSatisfy then
			objectiveData.lockUnitsOnSatisfy = nil
			objectiveData.unitsLocked = true
		end
	else
		if objectiveData.satisfyAtTime or objectiveData.satisfyUntilTime or objectiveData.satisfyAfterTime or objectiveData.satisfyForever then
			CompleteBonusObjective(bonusObjectiveID, false)
		end
	end
end

local function DebugPrintBonusObjective()
	Spring.Echo(" ====== Bonus Objectives ====== ")
	for i = 1, #bonusObjectiveList do
		local objectiveData = bonusObjectiveList[i]
		Spring.Echo("Objective", i, "Succeed", objectiveData.success, "Terminated", objectiveData.terminated)
	end
end

local function DoPeriodicBonusObjectiveUpdate(gameSeconds)
	for i = 1, #bonusObjectiveList do
		CheckBonusObjective(i, gameSeconds)
	end
	--DebugPrintBonusObjective()
end

local function AddBonusObjectiveUnit(unitID, bonusObjectiveID, allyTeamID, isCapture)
	if gameIsOver then
		return
	end
	local objectiveData = bonusObjectiveList[bonusObjectiveID]
	if objectiveData.unitsLocked or objectiveData.terminated then
		return
	end
	if isCapture and not objectiveData.capturedUnitsSatisfy then
		return
	end
	objectiveData.units = objectiveData.units or {}
	objectiveData.units[unitID] = allyTeamID or Spring.GetUnitAllyTeam(unitID)
	if objectiveData.lockUnitsOnSatisfy then
		CheckBonusObjective(bonusObjectiveID)
	end
end

local function RemoveBonusObjectiveUnit(unitID, bonusObjectiveID)
	if gameIsOver then
		return
	end
	local objectiveData = bonusObjectiveList[bonusObjectiveID]
	if not objectiveData.units then
		return
	end
	if objectiveData.units[unitID] then
		local inbuild
		if objectiveData.countRemovedUnits or objectiveData.onlyCountRemovedUnits then
			inbuild = (select(3, Spring.GetUnitIsStunned(unitID)) and 1) or 0
			if inbuild == 0 then
				objectiveData.removedUnits = (objectiveData.removedUnits or 0) + 1
			end
		end
		if objectiveData.failOnUnitLoss then
			inbuild = inbuild or ((select(3, Spring.GetUnitIsStunned(unitID)) and 1) or 0)
			if inbuild == 0 then
				CompleteBonusObjective(bonusObjectiveID, false)
			end
		end
		objectiveData.units[unitID] = nil
	end
end

local function SetWinBeforeBonusObjective(victory)
	local gameSeconds = math.floor(Spring.GetGameFrame()/30)
	for i = 1, #bonusObjectiveList do
		CheckBonusObjective(i, gameSeconds, victory)
	end
	DebugPrintBonusObjective()
end

local function InitializeBonusObjectives()
	local bonusObjectiveConfig = CustomKeyToUsefulTable(Spring.GetModOptions().bonusobjectiveconfig) or {}
	for objectiveID = 1, #bonusObjectiveConfig do
		local bonusObjective = bonusObjectiveConfig[objectiveID] or {}
		if bonusObjective.unitTypes then
			local unitDefMap = {}
			for i = 1, #bonusObjective.unitTypes do
				local ud = UnitDefNames[bonusObjective.unitTypes[i]]
				if ud then
					unitDefMap[ud.id] = true
					myUnitDefBonusObj[ud.id] = myUnitDefBonusObj[ud.id] or {}
					myUnitDefBonusObj[ud.id][#myUnitDefBonusObj[ud.id] + 1] = objectiveID
				end
			end
			bonusObjective.unitTypes = unitDefMap
		end
		if bonusObjective.enemyUnitTypes then
			local unitDefMap = {}
			for i = 1, #bonusObjective.enemyUnitTypes do
				local ud = UnitDefNames[bonusObjective.enemyUnitTypes[i]]
				if ud then
					unitDefMap[ud.id] = true
					enemyUnitDefBonusObj[ud.id] = enemyUnitDefBonusObj[ud.id] or {}
					enemyUnitDefBonusObj[ud.id][#enemyUnitDefBonusObj[ud.id] + 1] = objectiveID
				end
			end
			bonusObjective.enemyUnitTypes = unitDefMap
		end
		if bonusObjective.completeAllBonusObjectives then
			completeAllBonusObjectiveID = objectiveID
		end
		bonusObjectiveList[objectiveID] = bonusObjective
	end
end

local function AddUnitToBonusObjectiveList(unitID, objectiveList, isCapture)
	if not objectiveList then
		return
	end
	for i = 1, #objectiveList do
		AddBonusObjectiveUnit(unitID, objectiveList[i], nil, isCapture)
	end
end

local function RemoveUnitFromBonusObjectiveList(unitID, objectiveList)
	if not objectiveList then
		return
	end
	for i = 1, #objectiveList do
		RemoveBonusObjectiveUnit(unitID, objectiveList[i])
	end
end

local function BonusObjectiveUnitCreated(unitID, unitDefID, teamID, isCapture)
	if teamID == PLAYER_TEAM_ID then
		AddUnitToBonusObjectiveList(unitID, myUnitDefBonusObj[unitDefID], isCapture)
	elseif Spring.GetUnitAllyTeam(unitID) ~= PLAYER_ALLY_TEAM_ID then
		AddUnitToBonusObjectiveList(unitID, enemyUnitDefBonusObj[unitDefID], isCapture)
	end
end

local function CheckInitialUnitDestroyed(unitID)
	if not initialUnitData[unitID] then
		return
	end
	
	if initialUnitData[unitID].mapMarker then
		SendToUnsynced("RemoveMarker", unitID)
	end
	
	initialUnitData[unitID] = nil
end

local function BonusObjectiveUnitDestroyed(unitID, unitDefID, teamID)
	RemoveUnitFromBonusObjectiveList(unitID, myUnitDefBonusObj[unitDefID])
	RemoveUnitFromBonusObjectiveList(unitID, enemyUnitDefBonusObj[unitDefID])
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Unit Placement

local function AddInitialUnitObjectiveParameters(unitID, parameters)
	initialUnitData[unitID] = parameters
	initialUnitData[unitID].allyTeamID = initialUnitData[unitID].allyTeamID or Spring.GetUnitAllyTeam(unitID)
	if parameters.defeatIfDestroyedObjectiveID or parameters.defeatIfDestroyed then
		AddDefeatIfUnitDestroyed(unitID, initialUnitData[unitID].allyTeamID, parameters.defeatIfDestroyedObjectiveID)
	end
	if parameters.victoryAtLocation then
		AddVictoryAtLocationUnit(unitID, parameters.victoryAtLocation, initialUnitData[unitID].allyTeamID)
	end
	if parameters.bonusObjectiveID then
		AddBonusObjectiveUnit(unitID, parameters.bonusObjectiveID, initialUnitData[unitID].allyTeamID)
	end
end

local function PlaceUnit(unitData, teamID)
	if unitData.difficultyAtLeast and (unitData.difficultyAtLeast > missionDifficulty) then
		return
	end
	if unitData.difficultyAtMost and (unitData.difficultyAtMost < missionDifficulty) then
		return
	end
	
	local name = unitData.name
	local ud = UnitDefNames[name]
	if not (ud and ud.id) then
		Spring.Echo("Missing unit placement", name)
		return
	end
	
	local x, z, facing = unitData.x, unitData.z, unitData.facing
	
	if ud.isBuilding or ud.speed == 0 then
		x, z = SanitizeBuildPositon(x, z, ud, facing)
	end
	
	local build = (unitData.buildProgress and unitData.buildProgress < 1) or false
	local unitID = Spring.CreateUnit(ud.id, x, Spring.GetGroundHeight(x,z), z, facing, teamID, build)
	
	if not unitID then
		Spring.MarkerAddPoint(x, 0, z, "Error creating unit " .. (((ud or {}).humanName) or "???"))
		return 
	end
	
	if unitData.commands then
		local commands = unitData.commands
		commandsToGive = commandsToGive or {}
		commandsToGive[#commandsToGive + 1] = {
			unitID = unitID,
			commands = commands,
		}
	end
	
	if unitData.mapMarker then
		SendToUnsynced("AddMarker", unitID, x, z, unitData.mapMarker.text, unitData.mapMarker.color)
	end
	
	AddInitialUnitObjectiveParameters(unitID, unitData)
	
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
	AddInitialUnitObjectiveParameters(unitID, commParameters)
end

local function ProcessUnitCommand(unitID, command)
	if command.unitName then
		local ud = UnitDefNames[command.unitName]
		command.cmdID = ud and ud.id and -ud.id
		if not command.cmdID then
			return
		end
		if command.pos then
			command.pos[1], command.pos[2] = SanitizeBuildPositon(command.pos[1], command.pos[2], ud, command.facing or 0)
		else -- Must be a factory production command
			Spring.GiveOrderToUnit(unitID, command.cmdID, {}, command.options or {})
			return
		end
	end
	
	local team = Spring.GetUnitTeam(unitID)
	
	if command.pos then
		local x, z = command.pos[1], command.pos[2]
		local y = CallAsTeam(team,
			function ()
				return Spring.GetGroundHeight(x, z) 
			end
		)
		
		Spring.GiveOrderToUnit(unitID, command.cmdID, {x, y, z, command.facing or command.radius}, command.options or {})
		return
	end
	
	if command.atPosition then
		local p = command.atPosition
		local units = Spring.GetUnitsInRectangle(p[1] - BUILD_RESOLUTION, p[2] - BUILD_RESOLUTION, p[1] + BUILD_RESOLUTION, p[2] + BUILD_RESOLUTION)
		if units and units[1] then
			Spring.GiveOrderToUnit(unitID, command.cmdID, {units[1]}, command.options or {})
		end
		return
	end
	
	local params = {}
	if command.params then
		for i = 1, #command.params do -- Somehow tables lose their order
			params[i] = command.params[i]
		end
	end
	Spring.GiveOrderToUnit(unitID, command.cmdID, params, command.options or {})
end

local function GiveCommandsToUnit(unitID, commands)
	for i = 1, #commands do
		ProcessUnitCommand(unitID, commands[i])
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
	unitDefID = unitDefID or Spring.GetUnitDefID(unitID)
	local ud = unitDefID and UnitDefs[unitDefID]
	if ud and ud.isBuilder then
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

local function LineageUnitCreated(unitID, unitDefID, teamID, builderID)
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

local function SetTeamAbilities(teamID, customKeys)
	local abilityData = CustomKeyToUsefulTable(customKeys and customKeys.campaignabilities)
	if not abilityData then
		return
	end
	for i = 1, #abilityData do
		-- TODO, move to a defs file
		if abilityData[i] == "terraform" then
			Spring.SetTeamRulesParam(teamID, "terraformUnlocked", 1)
			GG.terraformUnlocked[teamID] = true
		end
	end
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
	Spring.SetGameRulesParam("terraformRequiresUnlock", 1)
	
	local teamList = Spring.GetTeamList()
	for i = 1, #teamList do
		local teamID = teamList[i]
		local customKeys = select(7, Spring.GetTeamInfo(teamID))
		SetTeamAbilities(teamID, customKeys)
		SetTeamUnlocks(teamID, customKeys)
		InitializeCommanderParameters(teamID, customKeys)
	end
end

local function DoInitialUnitPlacement()
	local teamList = Spring.GetTeamList()
	for i = 1, #teamList do
		local teamID = teamList[i]
		local customKeys = select(7, Spring.GetTeamInfo(teamID))
		PlaceTeamUnits(teamID, customKeys)
	end
	
	if commandsToGive then
		for i = 1, #commandsToGive do
			GiveCommandsToUnit(commandsToGive[i].unitID, commandsToGive[i].commands)
		end
		commandsToGive = nil
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

local function IsWinner(winners)
	for i = 1, #winners do
		if winners[i] == PLAYER_ALLY_TEAM_ID then
			return true
		end
	end
	return false
end

function gadget:GameOver(winners)
	gameIsOver = true
	SetWinBeforeBonusObjective(IsWinner(winners))
end

function gadget:UnitFinished(unitID, unitDefID, teamID, builderID)
	if IsVitalUnitType(unitID, unitDefID) then
		vitalUnits[unitID] = true
	end
end

function gadget:UnitCreated(unitID, unitDefID, teamID, builderID)
	LineageUnitCreated(unitID, unitDefID, teamID, builderID)
	BonusObjectiveUnitCreated(unitID, unitDefID, teamID)
end

-- note: Taken comes before Given
function gadget:UnitGiven(unitID, unitDefID, newTeamID, oldTeamID)
	BonusObjectiveUnitCreated(unitID, unitDefID, newTeamID, true)
end

function gadget:UnitDestroyed(unitID, unitDefID, teamID)
	if vitalUnits[unitID] then
		vitalUnits[unitID] = false
	end
	BonusObjectiveUnitDestroyed(unitID, unitDefID, teamID)
	CheckInitialUnitDestroyed(unitID)
end

function gadget:Initialize()
	InitializeUnlocks()
	InitializeVictoryConditions()
	InitializeBonusObjectives()
	
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

if CRASH_CIRCUIT then
	function gadget:GamePreload(n)
		if not Spring.GetGameRulesParam("loadedGame") then
			DoInitialUnitPlacement()
		end
	end
end

function gadget:GameFrame(n)
	-- Would use GamePreload if it didn't cause Circuit to crash.
	if firstGameFrame then
		firstGameFrame = false
		if not CRASH_CIRCUIT then
			if not Spring.GetGameRulesParam("loadedGame") then
				DoInitialUnitPlacement()
			end
		end
	end
	
	-- Check objectives
	n = n + loadGameFrame
	if n%30 == 0 and not gameIsOver then
		VictoryAtLocationUpdate()
		local gameSeconds = n/30
		if checkForLoseAfterSeconds then
			for i = 1, #allyTeamList do
				local lostAfterSeconds = defeatConditionConfig[allyTeamList[i]].loseAfterSeconds
				if lostAfterSeconds and lostAfterSeconds <= gameSeconds then
					local defeatConfig = defeatConditionConfig[allyTeamList[i]]
					if defeatConfig.timeLossObjectiveID then
						Spring.SetGameRulesParam("objectiveSuccess_" .. defeatConfig.timeLossObjectiveID, (allyTeamList[i] == PLAYER_ALLY_TEAM_ID and 0) or 1)
					end
					GG.DestroyAlliance(allyTeamList[i])
				end
			end
		end
		DoPeriodicBonusObjectiveUpdate(gameSeconds)
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Load

function gadget:Load(zip)
	if not GG.SaveLoad then
		Spring.Log(gadget:GetInfo().name, LOG.ERROR, "Galaxy campaign mission failed to access save/load API")
		return
	end
	
	local loadData = GG.SaveLoad.ReadFile(zip, "Galaxy Campaign Battle Handler", SAVE_FILE) or {}
	loadGameFrame = Spring.GetGameRulesParam("lastSaveGameFrame")
	
	-- Unit Lineage. Reset because nonsense would be in it from UnitCreated.
	unitLineage = {}
	for oldUnitID, teamID in pairs(loadData.unitLineage) do
		local unitID = GG.SaveLoad.GetNewUnitID(oldUnitID)
		unitLineage[unitID] = teamID
		SetBuildOptions(unitID, unitDefID, unitLineage[unitID])
	end
	
	for i = 1, #loadData.bonusObjectiveList do
		bonusObjectiveList[i] = loadData.bonusObjectiveList[i]
		local oldUnits = loadData.bonusObjectiveList[i].units
		if oldUnits then
			bonusObjectiveList[i].units = {}
			for oldUnitID, allyTeamID in pairs(oldUnits) do
				local unitID = GG.SaveLoad.GetNewUnitID(oldUnitID)
				bonusObjectiveList[i].units[unitID] = allyTeamID
			end
		end
	end
	
	-- Clear the commanders out of victoryAtLocation
	victoryAtLocation = {}
	initialUnitData = {}
	
	-- Put the units back in the objectives
	for oldUnitID, data in pairs(loadData.initialUnitData) do
		local unitID = GG.SaveLoad.GetNewUnitID(oldUnitID)
		AddInitialUnitObjectiveParameters(unitID, data)
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
else --UNSYNCED
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local MakeRealTable = Spring.Utilities.MakeRealTable

function gadget:Save(zip)
	if not GG.SaveLoad then
		Spring.Log(gadget:GetInfo().name, LOG.ERROR, "Galaxy campaign mission failed to access save/load API")
		return
	end
	GG.SaveLoad.WriteSaveData(zip, SAVE_FILE, MakeRealTable(SYNCED.saveTable))
end

local function AddMarker(cmd, markerID, x, z, text, color)
	if (Script.LuaUI('AddCustomMapMarker')) then
		Script.LuaUI.AddCustomMapMarker(markerID, x, z, text, color)
	end
end

local function RemoveMarker(cmd, markerID)
	if (Script.LuaUI('RemoveCustomMapMarker')) then
		Script.LuaUI.RemoveCustomMapMarker(markerID)
	end
end

function gadget:Initialize()
	gadgetHandler:AddSyncAction("AddMarker", AddMarker)
	gadgetHandler:AddSyncAction("RemoveMarker", RemoveMarker)
end

function gadget:Shutdown()
	gadgetHandler:RemoveSyncAction("AddMarker")
	gadgetHandler:RemoveSyncAction("RemoveMarker")
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
end -- END UNSYNCED
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------