startUnits = {
	strikecomm = 'armcom',
	battlecomm = 'corcom',
	supportcomm = 'commsupport',
	reconcomm = 'commrecon',
}
altCommNames = {
	corcom = 'commbattle',
	armcom = 'commstrike',
}

ploppables = {
  "factoryhover",
  "factoryveh",
  "factorytank",
  "factoryshield",
  "factorycloak",
  "factoryjump",
  "factoryspider",
  "factoryplane",
  "factorygunship",
  "corsy",
  "armcsa",
}

-- storage
START_STORAGE_CLASSIC=1000
START_STORAGE=500
START_STORAGE_FACPLOP=1000

BOOST_RATE = 2.0
START_BOOST=600

START_ENERGY_FACPLOP=500
START_METAL_FACPLOP=500

OVERDRIVE_BUFFER=10000

EXCLUDED_UNITS = {
  [ UnitDefNames['terraunit'].id ] = true,
}

DEFAULT_UNIT = "armcom"		--FIXME: hardcodey until I cba to identify precise source of problem