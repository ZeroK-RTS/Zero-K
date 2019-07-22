aiCommanders = {}
for unitDefID, unitDef in pairs(UnitDefs) do
	if unitDef.customParams.ai_start_unit then
		aiCommanders[unitDefID] = true
	end
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
START_METAL   = 250
START_ENERGY  = 250

INNATE_INC_METAL   = 2
INNATE_INC_ENERGY  = 2

START_STORAGE = 0

COMM_SELECT_TIMEOUT = 30 * 15 -- 15 seconds

DEFAULT_UNIT = UnitDefNames["dyntrainer_strike_base"].id
DEFAULT_UNIT_NAME = "Strike Trainer"

