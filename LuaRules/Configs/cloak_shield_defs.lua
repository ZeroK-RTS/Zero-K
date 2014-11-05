--  Cloak Levels
--
--  0:  disabled
--  1:  conditionally enabled, uses energy
--  2:  conditionally enabled, does no use energy
--  3:  enabled, unless stunned
--  4:  always enabled

local cloakShieldDefs = {}

for name, ud in pairs (UnitDefNames) do
	local cp = ud.customParams
	if (cp.area_cloak ~= "0") then
		cloakShieldDefs[name] = {}

		cloakShieldDefs[name].energy = tonumber (cp.area_cloak_upkeep)
		cloakShieldDefs[name].maxrad = tonumber (cp.area_cloak_radius)

		cloakShieldDefs[name].growRate = tonumber (cp.area_cloak_grow_rate)
		cloakShieldDefs[name].shrinkRate = tonumber (cp.area_cloak_shrink_rate)
		cloakShieldDefs[name].decloakDistance = tonumber (cp.area_cloak_decloak_distance)

		cloakShieldDefs[name].init = (cp.area_cloak_init ~= "0")
		cloakShieldDefs[name].draw = (cp.area_cloak_draw ~= "0")
		cloakShieldDefs[name].selfCloak = (cp.area_cloak_self ~= "0")
	end
end

local uncloakables = {}

for k, v in pairs(UnitDefNames) do
	if (v.customParams.cannotcloak) then
		uncloakables[k] = true
	end
end

return cloakShieldDefs, uncloakables
