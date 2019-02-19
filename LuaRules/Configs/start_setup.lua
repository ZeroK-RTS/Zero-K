
aiCommanders = {
	[UnitDefNames["dyntrainer_recon_base"].id] = true,
	[UnitDefNames["dyntrainer_support_base"].id] = true,
	[UnitDefNames["dyntrainer_assault_base"].id] = true,
	[UnitDefNames["dyntrainer_strike_base"].id] = true,
}

if Spring.GetModOptions().campaign_chassis == "1" then
	--[[ Not sure about this, nabs like to feel special.
	     We could always limit it to hard/brutal and it's
	     not that amazing anyway ]]
	aiCommanders[UnitDefNames["dyntrainer_knight_base"].id] = true
end

ploppables = {
  "factoryhover",
  "factoryveh",
  "factorytank",
  "factoryshield",
  "factorycloak",
  "factoryamph",
  "factoryjump",
  "factoryspider",
  "factoryship",
  "factoryplane",
  "factorygunship",
}

ploppableDefs = {}
for i = 1, #ploppables do
	local ud = UnitDefNames[ploppables[i]]
	if ud and ud.id then
		ploppableDefs[ud.id ] = true
	end
end

-- starting resources
START_METAL   = 200
START_ENERGY  = 200

START_STORAGE = 0

COMM_SELECT_TIMEOUT = 30 * 15 -- 15 seconds

DEFAULT_UNIT = UnitDefNames["dyntrainer_strike_base"].id
DEFAULT_UNIT_NAME = "Strike Trainer"

