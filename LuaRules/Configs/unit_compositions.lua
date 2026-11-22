-- compositions defined for the compositionbuilder,
-- bundled in a config file for ease of access and cross gadget sharing


local allCompositions = {
    -- Get your static composition today! 
    staticCompositions = {
        tinyCost = { -- less than 500 cost, a few light defences and eco structures
            {turretLight = 1, ecoLight = 1},
            {turretRiot = 1,turretLight = 0, ecoLight = 0.5},
            {factoryPlate = 1, turretLight =1},
            {factoryPlate = 1, turretLight =1, ecoLight = 0.5},
            {turretLight =1, ecoLight = 0.5, ecoSupport = 0.5},
        },
        lowCost = { -- less than 1000 cost, riot turrets, maybe a factory, no skirmsher turrets yet, light aa
            {turretRiot = 1,turretLight = 0, ecoLight = 1,},
            {factoryPlate = 1, turretLight =3, ecoLight = 3, ecoSupport = 1},
            {turretRiot = 1,turretLight = 3, factoryPlate = 1},
            {turretRiot = 1,turretLight = 3, ecoLight = 2, ecoSupport = 1},
            {turretRiot = 1,turretLight = 3, ecoLight = 2, turretAALight = 1},
            {factoryPlate = 1,turretLight = 3, ecoLight = 2, turretAALight = 1}
        },
        mediumCost = { --less than 3000 cost, turrets skirm may struggle with, maybe a fusion or so tossed in
            {{classGroup = "factory", budgetFraction = 3, minUnits = 1,},turretLight =1,ecoLight =1, turretAALight = 1, ecoSupport = 1, turretRiot = 1,},
            {ecoHeavy = 1,turretLight =1, ecoSupport = 3,  turretRiot = 1, turretAALight = 1,{classGroup = "staticSupport", budgetFraction = 0, minUnits = 1,}},
            {turretSkirm = 1, ecoLight =2, ecoSupport = 1, turretAALight = 1, factoryPlate = 0.2,},
            {turretSkirm = 1, turretLight =3, ecoLight =1, ecoSupport = 1, turretAALight = 1, factoryPlate = 0.2,},
            {turretSkirm = 1, turretRiot = 3,ecoLight =1, ecoSupport = 1, turretAALight = 1,},
            {ecoHeavy = 1, turretsHeavy = 1, ecoLight = 2, ecoSupport= 0.3, {classGroup = "factory", budgetFraction = 3, minUnits = 1,},{classGroup = "energypylon", budgetFraction = 0, minUnits = 1,}}
        },
        highCost = { -- less than 7500 cost, a relatively developed base, turrets, factory, caretakers, maybe a desolator, big AA?
            {ecoHeavy = 1,turretsHeavy = 1,turretSkirm = 1, ecoSupport = 0.5, turretLight =1, turretRiot = 1, {classGroup = "staticSupport", budgetFraction = 0, minUnits = 1,},ecoLight = 1,factory = 0.5, {classGroup = "energypylon", budgetFraction = 0, minUnits = 1,}},
            {ecoHeavy = 1,turretsHeavy = 1,turretSkirm = 1, ecoSupport = 0.5, ecoLight = 2, factory = 0.5,turretLight =1, turretRiot = 1, {classGroup = "staticSupport", budgetFraction = 0, minUnits = 1,}, {classGroup = "energypylon", budgetFraction = 0, minUnits = 1,}},
            {ecoHeavy = 1, staticStrategic = 1, turretRiot =1, ecoSupport = 0.5, turretSkirm =1,ecoLight = 2, factoryPlate = 0.05, factory = 0.5, {classGroup = "energypylon", budgetFraction = 0, minUnits = 1,}}
        },
        ludicrousCost = {-- 7500 or more, anything goes! but we may want another tier
            {super = 1, turretsHeavy = 1, ecoHeavy = 1, staticStrategic = 1, turretRiot =1, turretSkirm =1,ecoLight = 0.5, factoryPlate = 0.05, factory = 0.1, ecoSupport = 0.3,energypylon = 0.1}
        }
    },
    -- everything defined here should be mobile
    -- TODO harddefine some support for things?
    mobileCompositions = {
        tinyCost = { -- less than 500 cost, small groups or single units
            {scout = 1},
            {raider = 1},
            {riot = 1},
            {skirm = 1},
            {bomb = 1},
            {assault = 1},
            {drone = 0.1,raider = 1},--unsure about drone...
            {scout = 1,raider = 1}
        },
        lowCost = { -- less than 1000 cost, light compositions, raider riot skirms and assault, and maybe support tools
            {raider = 1,skirm = 1},
            {raider = 1,riot = 1},
            {riot = 1,skirm = 1},
            {riot = 1,assault = 1},
            {assault = 1,raider = 1},
            {assault = 1,skirm = 1,},
            {assault = 1,bomb = 0.2,},
            {transport = 0.3,raider = 1},
            {drone = 0.3,riot = 1}, --unsure about drone...
        },
        mediumCost = { --less than 3000 cost, start for demis aswell as larger compositions with some support tools
            {constructor = 0.1,assault = 1,skirm = 1,},
            {assault = 1, riot = 1,},
            {assault = 1,artillery = 1,scout = 0.1,},
            {raider = 1,artillery = 1,},
            {antiSub = 1, artillery = 1,raider = 1},
            {gunship = 1,skirm = 1},
            {bomberLight = 1,raider = 1},
            {striderDemi = 1,antiAir = 1},
            {riot = 1, transport = 0.5,},
            {antiHeavy = 1,raider = 1},
            {aerialAA = 1, raider = 0.5}
        },
        highCost = { -- less than 7500 cost, demis and some light striders and big army comps
            {assault = 1,artillery = 1,raider = 0.5,},
            {striderDemi = 1,raider = 0.2,},
            {striderDemi = 1,antiSub = 0.5,},
            {aerialAA = 1,bomberLight = 1, assault = 1},
            {bomberHeavy = 1,striderDemi = 1},
            {striderMedium = 1,{classGroup = "support", budgetFraction = 0, minUnits = 1,},},
            {striderDemi = 1,assault = 1},
            {antiHeavy = 1}
        },
        ludicrousCost = {-- 7500 or more, anything goes! but we may want another tier
            {antiHeavy = 1,{classGroup = "support", budgetFraction = 0, minUnits = 1,}},
            {striderDemi = 1,bomberHeavy = 1},
            {striderMedium = 3,assault = 1,{classGroup = "support", budgetFraction = 0, minUnits = 1,}},
            {striderMedium = 1,{classGroup = "support", budgetFraction = 0, minUnits = 1,}},
            {striderDemi = 1,aerialAA = 1,{classGroup = "support", budgetFraction = 0, minUnits = 1,}},
            {striderHeavy = 1, striderMedium = 0,{classGroup = "support", budgetFraction = 0, minUnits = 1,}}
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
		turretRiot = 0.1,
		raider = 2,
		scout = 3,
	},
	{
		ecoLight = 1,
		turretAALight = 0.1,
		riot = 2,
		skirm = 2,
	},
	{
		ecoLight = 1,
		turretLight = 0.1,
		assault = 2,
		riot = 1,
	},
	{
		ecoLight = 1,
		turretLight = 0.1,
		assault = 1,
		gunship = 1,
	}
}

local staticCamps = {
	{
		pwSupport = 1,
		ecoLight = 0.5,
		ecoSupport = 0.5,
		turretRiot = 1,
		turretAALight = 0.5,
		turretLight = 1
	},
	{
		pwGreebles = 1,
		ecoLight = 0.5,
		ecoSupport = 0.5,
		turretRiot = 1,
		turretAALight = 0.5,
		turretLight = 1
	},
	{
		pwSupport = 1,
		pwGreebles = 1,
		ecoSupport = 0.1,
		turretRiot = 1,
		turretAALight = 0.5,
		turretLight = 1
	},
	{
		factory = 1,
		pwGreebles = 1,
		ecoSupport = 0.1,
		turretRiot = 1,
		turretAALight = 0.5,
		turretLight = 1
	}
}
local largeCamp = {
	pwSupport = 1,
	pwGreebles = 1,
	ecoSupport = 1,
	pwDefence = 1,
	turretRiot = 1,
	turretAALight = 1,
	turretLight = 1,
	artillery = 1,
}
]]