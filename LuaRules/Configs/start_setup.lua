startUnits = {
	strikecomm = 'armcom1',
	battlecomm = 'corcom1',
	supportcomm = 'commsupport1',
	reconcomm = 'commrecon1',
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
START_STORAGE_CLASSIC=1000
START_STORAGE=500
START_STORAGE_FACPLOP=1000

BOOST_RATE = 2.0
START_BOOST=600

START_ENERGY_FACPLOP=650
START_METAL_FACPLOP=650

OVERDRIVE_BUFFER=10000

BASE_COMM_COST = UnitDefNames.armcom1.metalCost or 1200

COMM_SELECT_TIMEOUT = 30 * 60 * 0.5 -- half a minute

EXCLUDED_UNITS = {
  [ UnitDefNames['terraunit'].id ] = true,
}

DEFAULT_UNIT = "armcom1"		--FIXME: hardcodey until I cba to identify precise source of problem

JOKE_UNIT = "neebcomm"