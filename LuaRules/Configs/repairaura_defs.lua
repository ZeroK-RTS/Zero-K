framesPerRepair = 30
delayAfterHit = 10 * 30 --units damaged within this many gameframes don't get repairs

--deep not safe with circular tables! defaults To false
function CopyTable(tableToCopy, deep)
	local copy = {}
		for key, value in pairs(tableToCopy) do
		if (deep and type(value) == "table") then
			copy[key] = CopyTable(value, true)
		else
			copy[key] = value
		end
	end
	return copy
end

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
	commsupport2 = {
		range = 450,
		rate = 12,
		ignoreDelay = true,
	}
}

for name, ud in pairs(UnitDefNames) do
	if ud.customParams.repairaura_preset then
		repairerDefs[name] = CopyTable(presets[ud.customParams.repairaura_preset])
	end
end