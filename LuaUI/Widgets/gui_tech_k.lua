
local modoption = Spring.GetModOptions().techk
if not (modoption == "1") then
	return
end

function widget:GetInfo()
	return {
		name      = "Tech-K Helper",
		desc      = "Adds UI element support for Tech-K.",
		author    = "GoogleFrog",
		date      = "26 September, 2024",
		license   = "GNU GPL, v2 or later",
		layer     = 0,
		enabled   = true --  loaded by default?
	}
end

local CMD_TECH_UP = Spring.Utilities.CMD.TECH_UP

WG.SelectedTechLevel = 1

------------------------------------------------------------
------------------------------------------------------------
-- Utilities

local isTechConstructor = {}
local function IsTechConstructor(unitDefID)
	if not isTechConstructor[unitDefID] then
		local ud = UnitDefs[unitDefID]
		isTechConstructor[unitDefID] = ud.canRepair and 1 or 0
	end
	return isTechConstructor[unitDefID] == 1
end

local isTechHaver = {}
local function IsTechHaver(unitDefID)
	if not isTechHaver[unitDefID] then
		local ud = UnitDefs[unitDefID]
		isTechHaver[unitDefID] = (ud.canRepair or ud.isFactory or ud.customParams.morphto or ud.customParams.isfakefactory) and 1 or 0
	end
	return isTechHaver[unitDefID] == 1
end

local buildingDefs = {}
local function IsBuilding(unitDefID)
	if not buildingDefs[unitDefID] then
		local ud = UnitDefs[unitDefID]
		buildingDefs[unitDefID] = (ud.speed == 0) and (not ud.customParams.mobilebuilding) and 1 or 0
	end
	return buildingDefs[unitDefID] == 1
end

local isMex = {}
local function IsMex(unitDefID)
	if not isMex[unitDefID] then
		local ud = UnitDefs[unitDefID]
		isMex[unitDefID] = (ud.customParams.ismex) and 1 or 0
	end
	return isMex[unitDefID] == 1
end

local isEcon = {}
local function IsEcon(unitDefID)
	if not isEcon[unitDefID] then
		local ud = UnitDefs[unitDefID]
		isEcon[unitDefID] = (ud.customParams.income_energy or ud.customParams.windgen) and 1 or 0
	end
	return isEcon[unitDefID] == 1
end

local function DistanceSq(x1,z1,x2,z2)
	local dis = (x1-x2)*(x1-x2)+(z1-z2)*(z1-z2)
	return dis
end

------------------------------------------------------------
------------------------------------------------------------
-- Selections/UI

function widget:SelectionChanged(selection, subselection)
	if subselection then
		return
	end
	local maxLevel = 1
	for i = 1, #selection do
		local unitID = selection[i]
		if Spring.ValidUnitID(unitID) then
			local unitDefID = Spring.GetUnitDefID(unitID)
			if unitDefID and IsTechHaver(unitDefID) then
				local level = Spring.GetUnitRulesParam(unitID, "tech_level")
				if level and level > maxLevel then
					maxLevel = level
				end
			end
		end
	end
	WG.SelectedTechLevel = maxLevel
	WG.PlacementMetalMult = math.pow(1.5, maxLevel - 1)
	WG.PlacementEnergyMult = math.pow(3, maxLevel - 1)
	WG.PlacementCostMult = math.pow(2, maxLevel - 1)
end

------------------------------------------------------------
------------------------------------------------------------
-- Area Command

local function CheckFilter(unitDefID, ctrl, alt)
	if ctrl and IsMex(unitDefID) then
		return true
	end
	if alt and IsEcon(unitDefID) then
		return true
	end
	return false
end

local function HandleAreaTech(cmdID, cmdParams, cmdOpts)
	local aveX = 0
	local aveZ = 0
	local aveCount = 0

	local selectedUnits = Spring.GetSelectedUnits()
	local unitArrayToReceive = {}
	for i = 1, #selectedUnits do
		local unitID = selectedUnits[i]
		local unitDefID = Spring.GetUnitDefID(unitID)
		if IsTechConstructor(unitDefID) then
			local x, _, z = Spring.GetUnitPosition(unitID)
			aveX = aveX + x
			aveZ = aveZ + z
			aveCount = aveCount + 1
			unitArrayToReceive[#unitArrayToReceive+1] = unitID
		end
	end
	if aveCount < 1 then
		return true
	end
	aveX = aveX/aveCount
	aveZ = aveZ/aveCount

	local areaUnits = Spring.GetUnitsInCylinder(cmdParams[1], cmdParams[3], cmdParams[4])
	local allyTeamID = Spring.GetMyAllyTeamID()
	local commands = {}
	local orderedCommands = {}
	local dis = {}
	local filter = cmdOpts.alt or cmdOpts.ctrl

	for i = 1, #areaUnits do
		local unitID = areaUnits[i]
		if Spring.GetUnitAllyTeam(unitID) == allyTeamID then
			local unitDefID = Spring.GetUnitDefID(unitID)
			if IsBuilding(unitDefID) and ((not filter) or CheckFilter(unitDefID, cmdOpts.ctrl, cmdOpts.alt)) then
				local x, _, z = Spring.GetUnitPosition(unitID)
				commands[#commands + 1] = {
					x = x,
					z = z,
					d = DistanceSq(aveX, aveZ, x, z),
					target = unitID,
				}
			end
		end
	end
	if #commands == 0 then
		return
	end

	local commandCount = #commands
	while commandCount > 0 do
		table.sort(commands, function(a,b) return a.d < b.d end)
		orderedCommands[#orderedCommands+1] = commands[1]
		aveX = commands[1].x
		aveZ = commands[1].z
		table.remove(commands, 1)
		for k, com in pairs(commands) do
			com.d = DistanceSq(aveX, aveZ, com.x, com.z)
		end
		commandCount = commandCount - 1
	end

	if not (cmdOpts.shift or cmdOpts.meta) then
		WG.CommandInsert(CMD.STOP, {}, cmdOpts, 0, true)
	end
	
	for i = 1, #orderedCommands do
		WG.CommandInsert(CMD_TECH_UP, {orderedCommands[i].target}, cmdOpts, i - 1, true)
	end
	return true
end

function widget:CommandNotify(cmdID, cmdParams, cmdOpts)
	if cmdID == CMD_TECH_UP and (cmdParams[4] or 0) > 1 then
		return HandleAreaTech(cmdID, cmdParams, cmdOpts)
	end
end
