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
		sheathDefNames[name] = Spring.Utilities.CopyTable(presets[ud.customParams.sheath_preset], true)
	end
end
]]--

for name, data in pairs(sheathDefNames) do
	if UnitDefNames[name] then sheathDefs[UnitDefNames[name].id] = data	end
end

return sheathDefs