if (not gadgetHandler:IsSyncedCode()) then
	return
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

-- Automatically generated local definitions

local spCallCOBScript        = Spring.CallCOBScript
local spGetLocalTeamID       = Spring.GetLocalTeamID
local spGetTeamList          = Spring.GetTeamList
local spGetTeamUnits         = Spring.GetTeamUnits
local spSetUnitCOBValue      = Spring.SetUnitCOBValue
local spGetUnitDefID         = Spring.GetUnitDefID
local spGetUnitTeam		     = Spring.GetUnitTeam
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function gadget:GetInfo()
	return {
		name = "Perks",
		desc = "don't leave the house without",
		author = "KDR_11k (David Becker)",
		date = "2008-03-04",
		license = "Public Domain",
		layer = -1,
		enabled = true,
	}
end

if not Spring.GetModOptions().enableunlocks then
	return
end

local perks = {}
local playerIDsByName = {}

local unlocks = {} -- indexed by teamID, value is a table of key unitDefID and value true or nil

local unlockUnits = {

}

local unlockUnitsMap = {}
for i=1,#unlockUnits do
	if UnitDefNames[unlockUnits[i]] then unlockUnitsMap[UnitDefNames[unlockUnits[i]].id] = true end
end

local luaTeam = {}

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local function UnlockUnit(unitID, lockDefID, team)
    local cmdDescID = Spring.FindUnitCmdDesc(unitID, -lockDefID)
    if (cmdDescID) then
        local cmdArray = {disabled = false}
        Spring.EditUnitCmdDesc(unitID, cmdDescID, cmdArray)
    end
end

local function LockUnit(unitID, lockDefID, team)
    local cmdDescID = Spring.FindUnitCmdDesc(unitID, -lockDefID)
    if (cmdDescID) then
        local cmdArray = {disabled = true}
        Spring.EditUnitCmdDesc(unitID, cmdDescID, cmdArray)
    end
end

-- right now we don't check if something else disabled/enabled the command before modifying it
-- this isn't a problem right now, but we may want it to be more robust
local function SetBuildOptions(unitID, unitDefID, team)
	local unitDef = UnitDefs[unitDefID]
	if (unitDef.isBuilder) then
		for _, buildoptionID in pairs(unitDef.buildOptions) do
			if unlockUnitsMap[buildoptionID] then
				if not (unlocks[team] and unlocks[team][buildoptionID]) then 
					LockUnit(unitID, buildoptionID, team)
				else
					UnlockUnit(unitID, buildoptionID, team)
				end
			end
		end
	end
end


-- for midgame modification - shouldn't be needed
function EnableUnit(unitDefID, team)
	local units = spGetTeamUnits(team)
	for i=1,#units do
		local udid2 = spGetUnitDefID(units[i])
		if UnitDefs[udid2].isBuilder then UnlockUnit(units[i], unitDefID, team) end
	end
end

function DisableUnit(unitDefID, team)
	local units = spGetTeamUnits(team)
	for i=1,#units do
		local udid2 = spGetUnitDefID(units[i])
		if UnitDefs[udid2].isBuilder then LockUnit(units[i], unitDefID, team) end
	end
end


function gadget:UnitCreated(unitID, unitDefID, team)
	if not luaTeam[team] then SetBuildOptions(unitID, unitDefID, team) end
end

function gadget:AllowUnitTransfer(unitID, unitDefID, oldTeam, newTeam, capture)
	gadget:UnitCreated(unitID, unitDefID, newTeam)
	return true
end

-- blocks command - prevent widget hax
function gadget:AllowCommand_GetWantedCommand()	
	return unlockUnitsMap
end

function gadget:AllowCommand_GetWantedUnitDefID()	
	return true
end

function gadget:AllowCommand(unitID, unitDefID, team, cmdID, cmdParams, cmdOpts)
	if unlockUnitsMap[-cmdID] then
		if not (unlocks[team] and unlocks[team][-cmdID]) and (not cmdOpts.right) then 
			return false
		end
	end
	return true
end

function gadget:AllowUnitCreation(unitDefID, builderID, builderTeam, x, y, z)
	if unlockUnitsMap[unitDefID] then
		if not (unlocks[builderTeam] and unlocks[builderTeam][unitDefID]) then 
			return false
		end
	end
	return true
end

local function InitUnsafe()
--[[
	local noUnlocks = true
	
	for index, id in pairs(Spring.GetPlayerList())
		local customKeys = select(10, Spring.GetPlayerInfo(id))
		if customKeys and customKeys.unlocks then
			noUnlocks = false
			break
		end
	end
	
	if noUnlocks then
		--nobody has unlocks, don't bother
		gadgetHandler:RemoveGadget()
		return
	end
]]--
	
	-- for name, id in pairs(playerIDsByName) do	
	for index, id in pairs(Spring.GetPlayerList()) do	
		-- copied from PlanetWars
		local unlockData, success
		local customKeys = select(10, Spring.GetPlayerInfo(id))
		local unlocksRaw = customKeys and customKeys.unlocks
		if not (unlocksRaw and type(unlocksRaw) == 'string') then
			if unlocksRaw then
				err = "Unlock data entry for player "..id.." is in invalid format"
			end
			unlockData = {}
		else
			unlocksRaw = string.gsub(unlocksRaw, '_', '=')
			unlocksRaw = Spring.Utilities.Base64Decode(unlocksRaw)
			local unlockFunc, err = loadstring("return "..unlocksRaw)
			if unlockFunc then 
				success, unlockData = pcall(unlockFunc)
				if not success then
					err = unlockData
					unlockData = {}
				end
			end
		end
		if err then 
			Spring.Log(gadget:GetInfo().name, LOG.WARNING, 'Unlock system error: ' .. err)
		end

		for index, name in pairs(unlockData) do
			local team = select(4, Spring.GetPlayerInfo(id, false))
			local udid = UnitDefNames[name] and UnitDefNames[name].id
			if udid then
				unlocks[team] = unlocks[team] or {}
				unlocks[team][udid] = true
			end
		end
	end

	
	-- /luarules reload compatibility
	local units = Spring.GetAllUnits()
	for i=1,#units do
		local udid = spGetUnitDefID(units[i])
		local teamID = spGetUnitTeam(units[i])
		gadget:UnitCreated(units[i], udid, teamID)
	end	
end

function gadget:Initialize()
	if (GG.Chicken) then
		--gadgetHandler:RemoveGadget()
	end
	local teams = Spring.GetTeamList()
	for _, teamID in ipairs(teams) do
		local teamLuaAI = Spring.GetTeamLuaAI(teamID)
		if (teamLuaAI and teamLuaAI ~= "") then
			luaTeam[teamID] = true
		end
	end
	
	InitUnsafe()
	local allUnits = Spring.GetAllUnits()
	for _, unitID in pairs(allUnits) do
		local udid = Spring.GetUnitDefID(unitID)
		if udid then
			gadget:UnitCreated(unitID, udid, Spring.GetUnitTeam(unitID))
		end
	end
end
