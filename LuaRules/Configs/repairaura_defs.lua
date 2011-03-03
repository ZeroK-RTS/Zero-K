framesPerRepair = 30
delayAfterHit = 10 * 30 --units damaged within this many gameframes don't get repairs

repairerDefs = {
--[[
	armnanotc = {
		range = 500,
		rate = 3,		--buildpower, spread out among all healees
		selfRepair = true,	--currently unused
		ignoreDelay = false,	--repair recently damaged units? default off
	},
	cornanotc = {
		range = 500,
		rate = 3,
		selfRepair = true,
	},
	
]]--
}

local presets = {
	module_repairfield = {
		range = 450,
		rate = 24,
		ignoreDelay = true,
	},
}

for name, ud in pairs(UnitDefNames) do
	if ud.customParams.repairaura_preset then
		repairerDefs[name] = Spring.Utilities.CopyTable(presets[ud.customParams.repairaura_preset])
	end
end