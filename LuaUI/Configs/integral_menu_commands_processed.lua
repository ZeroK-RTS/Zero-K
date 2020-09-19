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
