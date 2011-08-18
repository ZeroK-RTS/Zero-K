-- $Id: tactics.lua 3171 2008-11-06 09:06:29Z det $
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
--  file:    LuaRules/Configs/deployment.lua
--  brief:   LuaRules deployment mode configuration
--  author:  Dave Rodgers
--
--  Copyright (C) 2007.
--  Licensed under the terms of the GNU GPL, v2 or later.
--
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------


local noCustomBuilds = false


local deployment = {

  maxFrames = 120 * Game.gameSpeed,

  maxUnits  = 5000,

  maxMetal  = 15000,
  maxEnergy = 15000,

  maxRadius = 1024,

  maxAutoBuildLevels = 2,

  customBuilds = {

    ['armcom'] = {
      allow = {
    		"armmstor",
    		"armestor",
    		"armsolar",
    		"armgeo",
    		"armwin",
    		"armfus",
    		"armuwfus",
    		"armdtm",
    		"armflea",
    		"armpw",
    		"armrock",
    		"armham",
    		"armwar",
    		"armjeth",
    		"armtick",
    		"armfav",
    		"armflash",
    		"armstump",
    		"tawf013",
    		"armjanus",
    		"armsam",
    		"armseer",
    		"armpeep",
    		"armfig",
    		"armthund",
    		"armatlas",
    		"armkam",
    		"armsub",
    		"armpt",
    		"decade",
    		"armroy",
    		"armtboat",
    		"armjamt",
    		"armnanotc",
    		"armgeo",
    		"armwin",
    		"armsonar",
    		"armfrad",
    		"armrectr",
    		"armfast",
    		"armamph",
    		"armzeus",
    		"armmav",
    		"armsptk",
    		"armfido",
    		"armsnipe",
    		"armcrabe",
    		"armaak",
    		"armscab",
    		"armaser",
    		"armspy",
    		"arm_marky",
    		"consul",
    		"panther",
    		"armbull",
    		"armst",
    		"armmerl",
    		"armmanni",
    		"armyork",
    		"armbrawl",
    		"armpnix",
    		"armlance",
    		"armhawk",
    		"armawac",
    		"armdfly",
    		"corgripn",
    		"armcybr",
    		"armmls",
    		"armrecl",
    		"armsubk",
    		"tawf009",
    		"armaas",
    		"armcrus",
    		"armcarry",
    		"armarad",
    		"armrad",
    		"armveil",
    		"armuwadves",
    		"armuwadvms",
    		"armemp",
    		"armdecom",
    		"armuwfus",
    		"armsehak",
    		"armsfig",
    		"armseap",
    		"armsaber",
    		"armsb",
    		"armsh",
    		"armanac",
    		"armah",
    		"armbanth",
    		"armraz",
    		"armshock",
    		"armorco"
      },
      forbid = {
      },
    },

    ['corcom'] = {
      allow = {
    		"corsolar",
    		"cortide",
    		"corwin",
    		"corgeo",
    		"cormstor",
    		"corestor",
    		"coruwadves",
    		"coruwadvms",
    		"cornanotc",
    		"corrad",
    		"corarad",
    		"corjamt",
    		"corsonar",
    		"corsonar",
    		"corfrad",
    		"pinchy",
    		"cornecro",
    		"corak",
    		"corstorm",
    		"corthud",
    		"cormak",
    		"corcrash",
    		"corroach",
    		"corclog",
    		"cormlv",
    		"corfav",
    		"corgator",
    		"corgarp",
    		"corraid",
    		"corlevlr",
    		"cormist",
    		"corvrad",
    		"corfink",
    		"fighter",
    		"corshad",
    		"corvalk",
    		"bladew",
    		"corsub",
    		"corpt",
    		"coresupp",
    		"corroy",
    		"corfast",
    		"cornecro",
    		"corpyro",
    		"coramph",
    		"corcan",
    		"corsumo",
    		"cormort",
    		"corhrk",
    		"coraak",
    		"corsktl",
    		"corvoyr",
    		"core_spectre",
    		"corseal",
    		"correap",
    		"corgol",
    		"tawf114",
    		"cormart",
    		"trem",
    		"corsent",
    		"cormabm",
    		"corape",
    		"corhurc",
    		"cortitan",
    		"corvamp",
    		"corawac",
    		"corbtrans",
    		"corcrw",
    		"cormls",
    		"correcl",
    		"corshark",
    		"corarch",
    		"corcrus",
    		"corbats",
    		"corcarry",
    		"cortron",
    		"cordecom",
    		"corhunt",
    		"corsfig",
    		"corseap",
    		"corcut",
    		"corsb",
    		"corsh",
    		"corsnap",
    		"corah",
    		"nsaclash",
    		"corkrog",
    		"corkarg",
    		"gorg",
    		"armraven"
      },
      forbid = {
      },
    },
  },
}


if (noCustomBuilds) then
  deployment.customBuilds = {}  -- FIXME --
end


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

return deployment

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
