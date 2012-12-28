startUnits = {
	armcom = 'armcom1',
	corcom = 'corcom1',
	commsupport = 'commsupport1',
	commrecon = 'commrecon1',
	benzcom = 'benzcom1',
	cremcom = 'cremcom1',
	commbasic = 'commbasic',
}

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
  "factoryplane",
  "factorygunship",
  "corsy",
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

COMM_SELECT_TIMEOUT = 30 * 60 * 0.5 -- half a minute

EXCLUDED_UNITS = {
  [ UnitDefNames['terraunit'].id ] = true,
}

DEFAULT_UNIT = "armcom1"		--FIXME: hardcodey until I cba to identify precise source of problem

JOKE_UNIT = "neebcomm"