startUnits = {
	--armcom = 'armcom1',
	--corcom = 'corcom1',
	--commsupport = 'commsupport1',
	--commrecon = 'commrecon1',
	--benzcom = 'benzcom1',
	--cremcom = 'cremcom1',
	commbasic = 'commbasic',
}

local trainerComms = VFS.Include("LuaRules/Configs/comm_trainer_defs.lua")
for name, def in pairs(trainerComms) do
	startUnits[name] = def[1]
end

--defaultComms = {}
--for i,v in pairs(startUnits) do defaultComms[v] = true end

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

-- starting resources
START_METAL   = 400
START_ENERGY  = 400

START_STORAGE = 500

OVERDRIVE_BUFFER = 10000

BASE_COMM_COST = UnitDefNames.armcom1.metalCost or 1200

COMM_SELECT_TIMEOUT = 30 * 15 -- 15 seconds

DEFAULT_UNIT = "comm_trainer_strike"		--FIXME: hardcodey until I cba to identify precise source of problem
DEFAULT_UNIT_TEAMSIDES = "Strike Trainer"
