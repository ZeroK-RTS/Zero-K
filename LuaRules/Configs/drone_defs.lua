-- reloadTime is in seconds

local carrierDefs = {}

local carrierDefNames = {
	armcarry = {drone = UnitDefNames.carrydrone.id, reloadTime = 15, maxDrones = 8, spawnSize = 2, range = 1600},
	--corcrw = {drone = UnitDefNames.attackdrone.id, reloadTime = 15, maxDrones = 6, spawnSize = 2, range = 900},
	funnelweb = {drone = UnitDefNames.attackdrone.id, reloadTime = 15, maxDrones = 6, spawnSize = 2, range = 600},
}

local presets = {
	module_companion_drone = {drone = UnitDefNames.attackdrone.id, reloadTime = 10, maxDrones = 2, spawnSize = 1, range = 450},
}

--[[
for name, ud in pairs(UnitDefNames) do
	if ud.customParams.sheath_preset then
		sheathDefNames[name] = Spring.Utilities.CopyTable(presets[ud.customParams.sheath_preset], true)
	end
end
]]--
for id, ud in pairs(UnitDefs) do
	if ud.customParams and ud.customParams.drone_preset then
		carrierDefs[id] = Spring.Utilities.CopyTable(presets[ud.customParams.drone_preset])
	end
end

for name, data in pairs(carrierDefNames) do
	if UnitDefNames[name] then carrierDefs[UnitDefNames[name].id] = data	end
end

return carrierDefs
