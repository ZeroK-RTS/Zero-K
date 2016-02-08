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
local disatbledCount = 0
local disabledUnits = {}

local UnitDefBothNames = {} -- Includes humanName and name

local function AddName(name, unitDefId)
	UnitDefBothNames[name] = UnitDefBothNames[name] or {}
	UnitDefBothNames[name][#UnitDefBothNames[name] + 1] = unitDefId
end

for unitDefID = 1, #UnitDefs do
	AddName(UnitDefs[unitDefID].humanName, unitDefID)
	AddName(UnitDefs[unitDefID].name, unitDefID)
end

if (disabledunitsstring == "") then --no unit to disable, exit
	return
end

if disabledunitsstring ~= "" then
	local alreadyDisabled = {}
	GG.TableEcho(UnitDefBothNames)
	for name in string.gmatch(disabledunitsstring, '([^+]+)') do
		Spring.Echo(name)
		if UnitDefBothNames[name] then
			for i = 1, #UnitDefBothNames[name] do
				local unitDefID = UnitDefBothNames[name][i]
				if not alreadyDisabled[unitDefID] then
					disatbledCount = disatbledCount + 1
					disabledUnits[disatbledCount] = unitDefID
					alreadyDisabled[unitDefID] = true
				end
			end
		end
	end
end

local function UnlockUnit(unitID, lockDefID)
	local cmdDescID = Spring.FindUnitCmdDesc(unitID, -lockDefID)
	if (cmdDescID) then
		local cmdArray = {disabled = false}
		Spring.EditUnitCmdDesc(unitID, cmdDescID, cmdArray)
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
	end
end

local function SetBuildOptions(unitID, unitDefID)
	local unitDef = UnitDefs[unitDefID]
	if (unitDef.isBuilder) then
		for _, buildoptionID in pairs(unitDef.buildOptions) do
			for i = 1, disatbledCount do
				RemoveUnit(unitID, disabledUnits[i])
			end
		end
	end
end

function gadget:UnitCreated(unitID, unitDefID)
	SetBuildOptions(unitID, unitDefID)
end

function gadget:Initialize()
	local units = Spring.GetAllUnits()
	for i=1, #units do
		local udid = Spring.GetUnitDefID(units[i])
		gadget:UnitCreated(units[i], udid)
	end
end
