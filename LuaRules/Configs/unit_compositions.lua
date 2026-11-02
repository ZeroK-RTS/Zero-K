-- compositions defined for the compositionbuilder,
-- bundled in a config file for ease of access and cross gadget sharing


local allCompositions = {
    -- Get your static composition today! 
    staticCompositions = {
        tinyCost = { -- less than 500 cost, a few light defences and eco structures
            {turretsLight = 1, ecoLight = 1},
            {turretsRiot = 1,turretsLight = 0, ecoLight = 1,},
            {factoryPlates = 1, turretsLight =1,},
            {factoryPlates = 1, turretsLight =1, ecoLight = 1},
            {turretsRiot = 1,turretsLight = 0, factoryPlates = 1,},
            {turretsRiot = 1,turretsLight = 0, ecoLight = 1, ecoSupport = 1},
        },
        lowCost = { -- less than 1000 cost, riot turrets, maybe a factory, no skirmsher turrets yet, light aa
            {factories = 10,turretsLight =1,ecoLight =1,},
            {turretsRiot = 1,turretsLight = 0, ecoLight = 1,},
            {factoryPlates = 1, turretsLight =3, ecoLight = 3, ecoSupport = 1},
            {turretsRiot = 1,turretsLight = 3, factoryPlates = 1,},
            {turretsRiot = 1,turretsLight = 3, ecoLight = 2, ecoSupport = 1},
            {turretsRiot = 1,turretsLight = 3, ecoLight = 2, turretsAALight = 1},
            {factoryPlates = 1,turretsLight = 3, ecoLight = 2, turretsAALight = 1}
        },
        mediumCost = { --less than 3000 cost, turrets skirmishers may struggle with, maybe a fusion or so tossed in
            {factories = 1,turretsLight =1,ecoLight =3, ecoSupport = 3, turretsRiot = 1,},
            {ecoHeavy = 1,turretsLight =1, ecoSupport = 3, turretsRiot = 1, staticSupport =1},
            {turretsSkirm = 1, ecoLight =3, ecoSupport = 1, turretsAALight = 1, factoryPlates = 1,},
            {turretsSkirm = 1, turretsLight =3, ecoLight =3, ecoSupport = 1, turretsAALight = 1, factoryPlates = 1,},
            {turretsSkirm = 1, turretsRiot = 3,ecoLight =3, ecoSupport = 1, turretsAALight = 1,},
            {ecoHeavy = 1, turretsHeavy = 1, ecoLight = 0, ecoSupport= 0.1}
        },
        highCost = { -- less than 7500 cost, a relatively developed base, turrets, factories, caretakers, maybe a desolator, big AA?
            {ecoHeavy = 1,turretsHeavy = 1,turretsSkirm = 1, ecoSupport = 0.5, turretsLight =1, turretsRiot = 1, staticSupport =1,ecoLight = 0.5,factories = 0.5},
            {ecoHeavy = 1,turretsHeavy = 1,turretsSkirm = 1, ecoSupport = 0.5, factories = 0.5,turretsLight =1, turretsRiot = 1, staticSupport =1},
            {ecoHeavy = 1, staticStrategic = 1, turretsRiot =1, turretsSkirm =1,ecoLight = 0.5, factoryPlates = 0.05, factories = 0.1, ecoSupport = 0.1}
        },
        ludicrousCost = {-- 7500 or more, anything goes! but we may want another tier
            {super = 1, turretsHeavy = 1, ecoHeavy = 1, staticStrategic = 1, turretsRiot =1, turretsSkirm =1,ecoLight = 0.5, factoryPlates = 0.05, factories = 0.1, ecoSupport = 0.1, factories = 0.1}
        }
    },
    -- everything defined here should be mobile
    -- TODO harddefine some support for things?
    mobileCompositions = {
        tinyCost = { -- less than 500 cost, small groups or single units
            {scouts = 1},
            {raiders = 1},
            {riots = 1},
            {riots = 1},
            {skirmishers = 1},
            {bombs = 1},
            {assaults = 1},
            {drones = 0.1,raiders = 1},--unsure about drones...
            {scouts = 1,raiders = 1}
        },
        lowCost = { -- less than 1000 cost, light compositions, raider riot skirms and assaults, and maybe support tools
            {raiders = 1,skirmishers = 1},
            {raiders = 1,riots = 1},
            {riots = 1,skirmishers = 1},
            {riots = 1,assaults = 1},
            {assaults = 1},
            {assaults = 1,skirmishers = 1,},
            {assaults = 1,bombs = 0.2,},
            {transports = 1,raiders = 1},
            {drones = 0.3,riots = 1}, --unsure about drones...
        },
        mediumCost = { --less than 3000 cost, start for demis aswell as larger compositions with some support tools
            {constructors = 0.1,assaults = 1,skirmishers = 1,},
            {assaults = 1, riots = 1,},
            {assaults = 1,artillery = 1,scouts = 0.1,},
            {raiders = 1,artillery = 1,},
            {antiSub = 1, artillery = 1,},
            {gunships = 1,},
            {bombersLight = 1,},
            {stridersDemi = 1,antiAir = 0.01},
            {riots = 1, transports = 0.5,},
            {antiHeavy = 1},
            {aerialAA = 1, raider = 0.5}
        },
        highCost = { -- less than 7500 cost, demis and some light striders and big army comps
            {assaults = 1,artillery = 1,raiders = 0.5,},
            {stridersDemi = 1,raiders = 0.2,},
            {stridersDemi = 1,antiSub = 0.5,},
            {aerialAA = 1,bombersLight = 1},
            {bombersHeavy = 1},
            {stridersMedium = 1,{unitGroup = "support", budgetFraction = 0, minUnits = 1,},},
            {stridersDemi = 1,assaults = 1},
            {antiHeavy = 1}
        },
        ludicrousCost = {-- 7500 or more, anything goes! but we may want another tier
            {antiHeavy = 1,{unitGroup = "support", budgetFraction = 0, minUnits = 1,}},
            {stridersDemi = 1,bombersHeavy = 1},
            {stridersMedium = 3,assaults = 1,{unitGroup = "support", budgetFraction = 0, minUnits = 1,}},
            {stridersMedium = 1,{unitGroup = "support", budgetFraction = 0, minUnits = 1,}},
            {stridersDemi = 1,aerialAA = 1,{unitGroup = "support", budgetFraction = 0, minUnits = 1,}},
            {stridersHeavy = 1, stridersMedium = 0,{unitGroup = "support", budgetFraction = 0, minUnits = 1,}}
        }
    },
    -- mix of static an mobile units
    mixedCompositions = {
      -- could hardcode, but will just mix the above instead! there is benefits to it ig :O
      --[[
      ]]
    }
}

return allCompositions

-- some thoughts on mixed compositions
--[[
local mobileCamps = {
	{
		ecoLight = 1,
		turretsRiot = 0.1,
		raiders = 2,
		scouts = 3,
	},
	{
		ecoLight = 1,
		turretsAALight = 0.1,
		riots = 2,
		skirmishers = 2,
	},
	{
		ecoLight = 1,
		turretsLight = 0.1,
		assaults = 2,
		riots = 1,
	},
	{
		ecoLight = 1,
		turretsLight = 0.1,
		assaults = 1,
		gunships = 1,
	}
}

local staticCamps = {
	{
		pwSupport = 1,
		ecoLight = 0.5,
		ecoSupport = 0.5,
		turretsRiot = 1,
		turretsAALight = 0.5,
		turretsLight = 1
	},
	{
		pwGreebles = 1,
		ecoLight = 0.5,
		ecoSupport = 0.5,
		turretsRiot = 1,
		turretsAALight = 0.5,
		turretsLight = 1
	},
	{
		pwSupport = 1,
		pwGreebles = 1,
		ecoSupport = 0.1,
		turretsRiot = 1,
		turretsAALight = 0.5,
		turretsLight = 1
	},
	{
		factories = 1,
		pwGreebles = 1,
		ecoSupport = 0.1,
		turretsRiot = 1,
		turretsAALight = 0.5,
		turretsLight = 1
	}
}
local largeCamp = {
	pwSupport = 1,
	pwGreebles = 1,
	ecoSupport = 1,
	pwDefence = 1,
	turretsRiot = 1,
	turretsAALight = 1,
	turretsLight = 1,
	artillery = 1,
}
]]