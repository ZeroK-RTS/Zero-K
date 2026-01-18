
local rewardDefs = VFS.Include("LuaRules/Configs/RogueK/reward_defs.lua")

local loadout = {
	rerolls = 3,
	factories = {
		{
			baseDef = "factoryjump",
			units = {},
		},
		{
			baseDef = "factorytank",
			units = {},
		},
		{
			baseDef = "factoryplane",
			units = {},
		},
	},
	commander = {
	},
	structures = {
		"staticmex",
		"energywind",
		"energysolar",
		"staticrearm",
		"staticradar",
	},
}

local function TranslateStringList(data)
	for i = 1, #data do
		if type(data[i]) == "string" then
			data[i] = rewardDefs.flatRewards[data[i]]
		end
	end
end

TranslateStringList(loadout.structures)
TranslateStringList(loadout.commander)
for i = 1, #loadout.factories do
	TranslateStringList(loadout.factories[i])
end


return loadout
