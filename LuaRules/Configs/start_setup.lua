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

startUnitsAI = {
	armcom1 = 'armcom1',
	corcom1 = 'corcom1',
}

local aiComms = VFS.Include("gamedata/modularcomms/staticcomms.lua")
for name in pairs(aiComms) do
	startUnitsAI[name] = name
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

-- storage
START_STORAGE_CLASSIC=500
START_STORAGE=500
START_STORAGE_FACPLOP=500

BOOST_RATE = 2.0
START_BOOST=400

START_ENERGY_FACPLOP=400
START_METAL_FACPLOP=400

OVERDRIVE_BUFFER=10000

BASE_COMM_COST = UnitDefNames.armcom1.metalCost or 1200

COMM_SELECT_TIMEOUT = 30 * 15 -- 15 seconds

EXCLUDED_UNITS = {
  [ UnitDefNames['terraunit'].id ] = true,
}

DEFAULT_UNIT = "comm_trainer_strike"		--FIXME: hardcodey until I cba to identify precise source of problem
DEFAULT_UNIT_TEAMSIDES = "Strike Trainer"

JOKE_UNIT = "neebcomm"