local factory_commands, econ_commands, defense_commands, special_commands, units_factory_commands, overrides, widgetSpaceHidden = include("Configs/integral_menu_commands.lua")

local units = {
}

local function AddBuildQueue(name)
	units[name] = {}
	local ud = UnitDefNames[name]
	if ud and ud.buildOptions then
		local row = 1
		local col = 1
		local order = 1
		for i = 1, #ud.buildOptions do
			local buildName = UnitDefs[ud.buildOptions[i]].name
			units[name][buildName] = {row = row, col = col, order = order}
			col = col + 1
			if col == 7 then
				col = 1
				row = row + 1
			end
			order = order + 1
		end
	end
end

AddBuildQueue("factorycloak")
AddBuildQueue("factoryshield")
AddBuildQueue("factoryveh")
AddBuildQueue("factoryhover")
AddBuildQueue("factorygunship")
AddBuildQueue("factoryplane")
AddBuildQueue("factoryspider")
AddBuildQueue("factoryjump")
AddBuildQueue("factorytank")
AddBuildQueue("factoyamph")
AddBuildQueue("factoryship")
AddBuildQueue("striderhub")
AddBuildQueue("staticmissilesilo")
AddBuildQueue("pw_bomberfac")
AddBuildQueue("pw_dropfac")

local units_factory_commands = {}

local function CopyBuildArray(source, target)
	for name, value in pairs(source) do
		udef = (UnitDefNames[name])
		if udef then
			target[-udef.id] = value
		end
	end
end

for name, listData in pairs(units) do
	local unitDefID = UnitDefNames[name]
	unitDefID = unitDefID and unitDefID.id
	if unitDefID then
		units_factory_commands[unitDefID] = {}
		CopyBuildArray(listData, units_factory_commands[unitDefID])
	end
end

return factory_commands, econ_commands, defense_commands, special_commands, units_factory_commands, overrides, widgetSpaceHidden
