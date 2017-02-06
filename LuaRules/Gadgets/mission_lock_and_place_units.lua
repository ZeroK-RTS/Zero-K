--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
if not gadgetHandler:IsSyncedCode() then
	return
end
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
function gadget:GetInfo()
	return {
		name = "Mission Lock and Place Units",
		desc = "Implements locking of units and placement of structures.",
		author = "GoogleFrog",
		date = "6 February 2017",
		license = "GNU GPL, v2 or later",
		layer = 0,
		enabled = true
	}
end

if not Spring.GetModOptions().issingleplayercampaign then
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

local function InitializeUnlocks()
	local teamList = Spring.GetTeamList()
	for i = 1, #teamList do
		local teamID = teamList[i]
		local customKeys = select(7, Spring.GetTeamInfo(teamID))
		local unlocksRaw = customKeys and customKeys.campaignunlocks
		if not (unlocksRaw and type(unlocksRaw) == 'string') then
			if unlocksRaw then
				Spring.Echo("Unlock data entry for player " .. teamID .. " is in invalid format")
			end
		else
			unlocksRaw = string.gsub(unlocksRaw, '_', '=')
			unlocksRaw = Spring.Utilities.Base64Decode(unlocksRaw)
			local unlockFunc, err = loadstring("return " .. unlocksRaw)
			if unlockFunc then 
				local success, unlockData = pcall(unlockFunc)
				if success then
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
			end
			if err then
				Spring.Echo("Unlocks error", err)
			end
		end
	end
end

function gadget:Initialize()
	InitializeUnlocks()
	
	local allUnits = Spring.GetAllUnits()
	for _, unitID in pairs(allUnits) do
		local unitDefID = Spring.GetUnitDefID(unitID)
		if unitDefID then
			gadget:UnitCreated(unitID, unitDefID, Spring.GetUnitTeam(unitID))
		end
	end
end