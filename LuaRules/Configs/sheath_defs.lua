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

-- delay is in gameframes
-- regen is HP/second

local sheathDefs = {}

local sheathDefNames = {
	corak = {maxHP = 200, initHP = 100, regen = 10, regenDelay = 90},
}

local presets = {}

--[[
for name, ud in pairs(UnitDefNames) do
	if ud.customParams.sheath_preset then
		sheathDefNames[name] = CopyTable(presets[ud.customParams.sheath_preset], true)
	end
end
]]--

for name, data in pairs(sheathDefNames) do
	if UnitDefNames[name] then sheathDefs[UnitDefNames[name].id] = data	end
end

return sheathDefs