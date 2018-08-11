if (not gadgetHandler:IsSyncedCode()) then
	return
end

function gadget:GetInfo()
	return {
		name = "LockOptions",
		desc = "Modoption for locking units. 90% Copypasted from game_perks.lua",
		author = "Storage, GoogleFrog",
		license = "Public Domain",
		layer = -1,
		enabled = true,
	}
end

local disabledunitsstring = Spring.GetModOptions().disabledunits or ""
if (disabledunitsstring == "") then --no unit to disable, exit
	return
end
disabledunitsstring = disabledunitsstring:gsub("[%s%+]*%+[%s%+]*","+"):gsub("^%s*",""):gsub("%s*$",""):lower()

local CMD_INSERT = CMD.INSERT

local disabledCount = 0
local disabledUnits = {}
local removedBuildOptions = {}

local UnitDefBothNames = {} -- Includes humanName and name

local function AddName(name, unitDefId)
	name = name:lower()
	UnitDefBothNames[name] = UnitDefBothNames[name] or {}
	UnitDefBothNames[name][#UnitDefBothNames[name] + 1] = unitDefId
end

for unitDefID = 1, #UnitDefs do
	AddName(UnitDefs[unitDefID].humanName, unitDefID)
	AddName(UnitDefs[unitDefID].name, unitDefID)
end

local alreadyDisabled = {}
for name in string.gmatch(disabledunitsstring, '([^+]+)') do
	if UnitDefBothNames[name] then
		for i = 1, #UnitDefBothNames[name] do
			local unitDefID = UnitDefBothNames[name][i]
			if not alreadyDisabled[unitDefID] then
				disabledCount = disabledCount + 1
				disabledUnits[disabledCount] = unitDefID
				alreadyDisabled[unitDefID] = true
			end
		end
	end
end

for i = 1, disabledCount do
	Spring.SetGameRulesParam("disabled_unit_" .. UnitDefs[disabledUnits[i]].name, 1)
end

local function UnlockUnit(unitID, lockDefID)
	local cmdDescID = Spring.FindUnitCmdDesc(unitID, -lockDefID)
	if (cmdDescID) then
		local cmdArray = {disabled = false}
		Spring.EditUnitCmdDesc(unitID, cmdDescID, cmdArray)
		if removedBuildOptions[unitID] and removedBuildOptions[unitID][lockDefID] then
			removedBuildOptions[unitID][lockDefID] = nil
		end
	end
end

local function LockUnit(unitID, lockDefID)
	local cmdDescID = Spring.FindUnitCmdDesc(unitID, -lockDefID)
	if (cmdDescID) then
		local cmdArray = {disabled = true}
		Spring.EditUnitCmdDesc(unitID, cmdDescID, cmdArray)
	end
end

local function RemoveUnit(unitID, lockDefID)
	local cmdDescID = Spring.FindUnitCmdDesc(unitID, -lockDefID)
	if (cmdDescID) then
		Spring.RemoveUnitCmdDesc(unitID, cmdDescID)
		removedBuildOptions[unitID] = removedBuildOptions[unitID] or {}
		removedBuildOptions[unitID][lockDefID] = true
	end
end

local function SetBuildOptions(unitID, unitDefID)
	local unitDef = UnitDefs[unitDefID]
	if (unitDef.isBuilder) then
		for _, buildoptionID in pairs(unitDef.buildOptions) do
			for i = 1, disabledCount do
				RemoveUnit(unitID, disabledUnits[i])
			end
		end
	end
end

-- The AllowCommand block is only needed for multiplayer and breaks circuit if you
-- disable a unit it often wants to build.
function gadget:AllowCommand(unitID, unitDefID, teamID, cmdID, cmdParams, cmdOptions)
	local removed = removedBuildOptions[unitID]
	if removed then
		if cmdID == CMD_INSERT then
			cmdID = cmdParams[2]
		end
		if removed[-cmdID] then
			return false
		end
	end
	return true
end

function gadget:UnitCreated(unitID, unitDefID)
	SetBuildOptions(unitID, unitDefID)
end

function gadget:UnitDestroyed(unitID, unitDefID)
	removedBuildOptions[unitID] = nil
end

function gadget:Initialize()
	local units = Spring.GetAllUnits()
	for i=1, #units do
		local udid = Spring.GetUnitDefID(units[i])
		gadget:UnitCreated(units[i], udid)
	end
end
