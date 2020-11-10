local cmdPosDef, factoryUnitPosDef, factory_commands, econ_commands, defense_commands, special_commands = include("Configs/integral_menu_commands.lua", nil, VFS.RAW_FIRST)

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Panel Configuration Loading

local function AddBuildQueue(name)
	factoryUnitPosDef[name] = {}
	local ud = UnitDefNames[name]
	if ud and ud.buildOptions then
		local row = 1
		local col = 1
		local order = 1
		for i = 1, #ud.buildOptions do
			local buildName = UnitDefs[ud.buildOptions[i]].name
			factoryUnitPosDef[name][buildName] = {row = row, col = col, order = order}
			col = col + 1
			if col == 7 then
				col = 1
				row = row + 1
			end
			order = order + 1
		end
	end
end

AddBuildQueue("striderhub")
AddBuildQueue("staticmissilesilo")

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Support for tweakunits changing panel orders.

-- test case:
--e2ZhY3Rvcnl0YW5rID0gewpidWlsZG9wdGlvbnMgPSB7CltbY2xvYWtjb25dXSwKW1tzcGlkZXJzY291dF1dLApbW3ZlaHJhaWRdXSwKW1tob3ZlcnNraXJtXV0sCltbanVtcGJsYWNraG9sZV1dLApbW2d1bnNoaXBhYV1dLApbW2Nsb2Frc25pcGVdXSwKW1tndW5zaGlwaGVhdnlza2lybV1dLApbW3NwaWRlcmNyYWJlXV0sCltbYm9tYmVyZGlzYXJtXV0sCltbcGxhbmVmaWdodGVyXV0sCn0sCmN1c3RvbVBhcmFtcyA9IHsKcG9zX2NvbnN0cnVjdG9yPVtbY2xvYWtjb25dXSwKcG9zX3JhaWRlcj1bW3ZlaHJhaWRdXSwKcG9zX3dlaXJkX3JhaWRlcj1bW3NwaWRlcnNjb3V0XV0sCnBvc19za2lybWlzaGVyPVtbaG92ZXJza2lybV1dLApwb3NfcmlvdD1bW2p1bXBibGFja2hvbGVdXSwKcG9zX2FudGlfYWlyPVtbZ3Vuc2hpcGFhXV0sCnBvc19hc3NhdWx0PVtbY2xvYWtzbmlwZV1dLApwb3NfYXJ0aWxsZXJ5PVtbZ3Vuc2hpcGhlYXZ5c2tpcm1dXSwKcG9zX2hlYXZ5X3NvbWV0aGluZz1bW3NwaWRlcmNyYWJlXV0sCnBvc19zcGVjaWFsPVtbYm9tYmVyZGlzYXJtXV0sCnBvc191dGlsaXR5PVtbcGxhbmVmaWdodGVyXV0sCn19LH0K

local typeNames = {
	"CONSTRUCTOR",
	"RAIDER",
	"SKIRMISHER",
	"RIOT",
	"ASSAULT",
	"ARTILLERY",
	"WEIRD_RAIDER",
	"ANTI_AIR",
	"HEAVY_SOMETHING",
	"SPECIAL",
	"UTILITY",
}

-- Replicated here rather than included from integral_menu_commands to reduce
-- enduser footgun via local integral_menu_commands.
local unitTypes = {
	CONSTRUCTOR     = {order = 1, row = 1, col = 1},
	RAIDER          = {order = 2, row = 1, col = 2},
	SKIRMISHER      = {order = 3, row = 1, col = 3},
	RIOT            = {order = 4, row = 1, col = 4},
	ASSAULT         = {order = 5, row = 1, col = 5},
	ARTILLERY       = {order = 6, row = 1, col = 6},

	-- note: row 2 column 1 purposefully skipped, since
	-- that allows giving facs Attack orders via hotkey
	WEIRD_RAIDER    = {order = 7, row = 2, col = 2},
	ANTI_AIR        = {order = 8, row = 2, col = 3},
	HEAVY_SOMETHING = {order = 9, row = 2, col = 4},
	SPECIAL         = {order = 10, row = 2, col = 5},
	UTILITY         = {order = 11, row = 2, col = 6},
}

local typeNamesLower = {}
for i = 1, #typeNames do
	typeNamesLower[i] = "pos_" .. typeNames[i]:lower()
end

-- Tweakunits support
for unitName, factoryData in pairs(factoryUnitPosDef) do
	local ud = UnitDefNames[unitName]
	if ud then
		local cp = ud.customParams
		for i = 1, #typeNamesLower do
			local value = cp[typeNamesLower[i]]
			if value then
				factoryData[value] = unitTypes[typeNames[i]]
			end
		end
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Translate to unitDefIDs

local buildCmdFactory = {}
local buildCmdEconomy = {}
local buildCmdDefence = {}
local buildCmdSpecial = {}
local buildCmdUnits   = {}

local function ProcessBuildArray(source, target)
	for name, value in pairs(source) do
		udef = (UnitDefNames[name])
		if udef then
			target[-udef.id] = value
		elseif type(name) == "number" then
			-- Terraform
			target[name] = value
		end
	end
end

ProcessBuildArray(factory_commands, buildCmdFactory)
ProcessBuildArray(econ_commands, buildCmdEconomy)
ProcessBuildArray(defense_commands, buildCmdDefence)
ProcessBuildArray(special_commands, buildCmdSpecial)

for name, listData in pairs(factoryUnitPosDef) do
	local unitDefID = UnitDefNames[name]
	unitDefID = unitDefID and unitDefID.id
	if unitDefID then
		buildCmdUnits[unitDefID] = {}
		ProcessBuildArray(listData, buildCmdUnits[unitDefID])
	end
end

return buildCmdFactory, buildCmdEconomy, buildCmdDefence, buildCmdSpecial, buildCmdUnits, cmdPosDef, factoryUnitPosDef
