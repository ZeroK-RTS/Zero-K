local THRESHOLD_EXPENSIVE = 1200
INCOME_TO_SPLURGE = 20	-- ignore expensive warning if you have this much income
METAL_PER_NANO = 8		-- suggested nanos per metal ^ -1
MIN_PULL_FOR_NANOS = -10	-- don't make more nanos if our pull is already this low	--unused
NANO_DEF_ID = UnitDefNames.staticcon.id
ENERGY_TO_METAL_RATIO = 6	-- suggested maximum for energy
ENERGY_LOW_THRESHOLD = 200
DEFENSE_QUOTA = 0.4	-- suggested maximum proportion of total assets that is defense

RANK_LIMIT = 3

DELAY_BETWEEN_FACS = 5*60*30	-- gameframes

--seconds
TIMER_EXPENSIVE_UNITS = 60 * 10
TIMER_ADV_FACTORY = 60 * 6
TIMER_SUPERWEAPON = 60 * 10
TIMER_HYPERWEAPON = 60 * 20

tips = {
	nano_excess = {str = {"We already have plenty of\nCaretakers. We should get more\nresources before building more."}, life = 9, cooldown = 20},
	expensive_unit = {str = {"Boss, I'm not sure\nwe can afford that at\nthis stage of the game.",
				"Sir, I don't think that\nunit is in our price\nrange right now."}, life = 9, cooldown = 20, verbosity = 2},
	superweapon = {str = {"A superweapon now?\nThat may not be\nsuch a good idea."}, life = 7, cooldown = 60},
	adv_factory = {str = {"Are you sure that's\na good starting\nfac, chief?"}, life = 7, cooldown = 60},
	
	retreat_repair = {str = {"Getting shot up!\nRequesting permission\nto pull out, sir!",
				"Get me out of here!\nI need repairs!",}, life = 7, cooldown = 20},
				
	energy_excess  = {str = {"I think we've got\nenough energy for\nnow, boss.",
				"Energy storage already\nat full capacity.",
				"Sir, we've got plenty\nof energy as it is."}, life = 7, cooldown = 20},
	energy_deficit  = {str = {"Got an energy deficit, sir.\nMore energy structures?",
				"Commander, we'll soon run\nout of energy. Build more\nenergy structures."}, life = 7, cooldown = 45},
	metal_excess  = {str = {"Sir, we have a metal glut.\nPut some more buildpower\ninto making units.",
				"Boss, we have too much metal.\nGet more of us making stuff."}, life = 7, cooldown = 30},
	metal_deficit = {str = {"Running low on metal, chief.\nWe should try reclaiming\nor getting more mexes."}, life = 7, cooldown = 60, verbosity = 3},
	
	facplop = {str = {"Remember to place your\nfirst free factory."}, life = 7, cooldown = 30},
	factory_duplicate = {str = {"We already have one of\nthat factory. Remember you can\nassist it with constructors."}, life = 9, cooldown = 60},
	factory_multiple = {str = {"Sir, we might not need another\nfactory so soon. You can assist your\nfirst factory with constructors."}, life = 10, cooldown = 60, verbosity = 2},
	
	defense_excess = {str = {"Boss, we have plenty of defence.\nMight want some mobile units instead.",
				"Chief, we should build mobile\nunits instead. We already\nhave plenty of defence."}, life = 9, cooldown = 20}
}

for name,data in pairs(tips) do
	data.lastUsed = -10000
end

local superweaponDefs = {
	"staticheavyarty",
	"staticnuke",
}
local hyperweaponDefs = {
	"mahlazer",
	"zenith",
	"raveparty",
	"striderdetriment",
}
local canRetreatDefs = {
	"gunshipheavyskirm",
	"gunshipassault",
	"gunshipkrow",
	
	"tankassault",
	"tankheavyassault",
	--"tankheavyarty",
	"jumpassault",
	"jumpsumo",
	
	"striderdante",
	--"striderarty",
	"striderscorpion",
	"striderbantha",
	"striderdetriment",
	
	"shipheavyarty",
	"reef",
}

local energyDefs = {
	"energysolar",
	"energywind",
	"energyfusion",
	--"energygeo",
	"energysingu",
}

local defenseDefs = {
	"turretlaser",
	"turretmissile",
	"turretriot",
	"turretimpulse",
	"turretheavylaser",
	"turretgauss",
	
	"turretaalaser",
	"turretaaclose",
	"turretaaflak",
	"turretaafar",
	"turretaaheavy",
	
	"turretheavy",
	"turretantiheavy",
	
	"turrettorp",
	
	"staticjammer",
	"staticshield"
}

factoryDefs = {
	"factoryship",
	"striderhub",
}
for name in pairs(UnitDefNames) do
	if string.find(name, "factory") then factoryDefs[#factoryDefs+1] = name end
end

--unitDefID-indexed tables
expensive_units = {}
superweapons = {}
hyperweapons = {}
commanders = {}
factories = {}
adv_factories = {}
energy = {}
defenses = {}
canRetreat = {}

for i=1,#UnitDefs do
	if UnitDefs[i].customParams.commtype then commanders[i]=true
	--elseif (not UnitDefs[i].canMove) and UnitDefs[i].canAttack then defenses[i]=true	-- bad idea: includes superweapons
	elseif UnitDefs[i].metalCost >= THRESHOLD_EXPENSIVE then expensive_units[i] = true end
end

local function CreateArray(source, target)
	for i=1, #source do
		local def = UnitDefNames[source[i]]
		if def then target[def.id] = true end
	end
end

CreateArray(superweaponDefs, superweapons)
CreateArray(hyperweaponDefs, hyperweapons)
CreateArray(canRetreatDefs, canRetreat)
CreateArray(energyDefs, energy)
CreateArray(defenseDefs, defenses)
CreateArray(factoryDefs, factories)
