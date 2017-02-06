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
		layer = 0,
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
				return usefulTable
			end
		end
		if err then
			Spring.Echo("Customkey error", err)
		end
	end
end

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
	
	Spring.CreateUnit(ud.id, x, Spring.GetGroundHeight(x,z), z, facing, teamID)
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Implement the locks

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

function gadget:UnitCreated(unitID, unitDefID, teamID)
	SetBuildOptions(unitID, unitDefID, teamID)
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

local function InitializeUnlocksAndPlacement()
	local teamList = Spring.GetTeamList()
	for i = 1, #teamList do
		local teamID = teamList[i]
		local customKeys = select(7, Spring.GetTeamInfo(teamID))
		SetTeamUnlocks(teamID, customKeys)
		PlaceTeamUnits(teamID, customKeys)
	end
end

local Unlocks = {}

function Unlocks.GetIsUnitUnlocked(teamID, unitDefID)
	if unlockedUnitsByTeam[teamID] then
		if not (unlockedUnitsByTeam[teamID][unitDefID]) then 
			return false
		end
	end
	return true
end

function gadget:Initialize()
	InitializeUnlocksAndPlacement()
	
	local allUnits = Spring.GetAllUnits()
	for _, unitID in pairs(allUnits) do
		local unitDefID = Spring.GetUnitDefID(unitID)
		if unitDefID then
			gadget:UnitCreated(unitID, unitDefID, Spring.GetUnitTeam(unitID))
		end
	end
	
	GG.Unlocks = Unlocks
end
