--  Cloak Levels
--
--  0:  disabled
--  1:  conditionally enabled, uses energy
--  2:  conditionally enabled, does no use energy
--  3:  enabled, unless stunned
--  4:  always enabled

local uncloakables = {}

for k, v in pairs(UnitDefNames) do
	if (v.customParams.cannotcloak) then
		uncloakables[k] = true
	end
end

local cloakShieldDefs = {}

for name, ud in pairs (UnitDefNames) do
	local cp = ud.customParams
	if cp.area_cloak and (cp.area_cloak ~= "0") then
		cloakShieldDefs[name] = {}

		cloakShieldDefs[name].energy = tonumber(cp.area_cloak_upkeep)
		cloakShieldDefs[name].maxrad = tonumber(cp.area_cloak_radius)

		cloakShieldDefs[name].growRate = tonumber(cp.area_cloak_grow_rate)
		cloakShieldDefs[name].shrinkRate = tonumber(cp.area_cloak_shrink_rate)
		cloakShieldDefs[name].selfDecloakDistance = tonumber(cp.area_cloak_self_decloak_distance) or ud.decloakDistance
		cloakShieldDefs[name].recloakRate = tonumber(cp.area_cloak_recloak_rate)

		cloakShieldDefs[name].init = (cp.area_cloak_init ~= "0")
		cloakShieldDefs[name].draw = (cp.area_cloak_draw ~= "0")
		cloakShieldDefs[name].selfCloak = (cp.area_cloak_self ~= "0")
		if cp.area_cloak_move_mult then
			cloakShieldDefs[name].moveSpeedMult = tonumber(cp.area_cloak_move_mult)
		end
	end
end

local radiusOverrideDefs = {}
for unitDefID, eud in pairs (UnitDefs) do
	if eud.customParams.cloaker_bestowed_radius then
		radiusOverrideDefs[unitDefID] = tonumber(eud.customParams.cloaker_bestowed_radius)
	end
end

return cloakShieldDefs, uncloakables, radiusOverrideDefs
