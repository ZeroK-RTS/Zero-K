aiCommanders = {}
ploppableDefs = {}
for unitDefID, unitDef in pairs(UnitDefs) do
	local cp = unitDef.customParams
	if cp.ai_start_unit then
		aiCommanders[unitDefID] = true
	end
	if cp.ploppable then
		ploppableDefs[unitDefID] = true
	end
end

-- starting resources
START_METAL   = 400
START_ENERGY  = 400

INNATE_INC_METAL   = 2
INNATE_INC_ENERGY  = 2

START_STORAGE = 0

COMM_SELECT_TIMEOUT = 30 * 15 -- 15 seconds

DEFAULT_UNIT = UnitDefNames["dyntrainer_strike_base"].id
DEFAULT_UNIT_NAME = "Strike Trainer"

