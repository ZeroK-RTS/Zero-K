-- $Id: morph_defs.lua 4643 2009-05-22 05:52:27Z carrepairer $
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local devolution = false


local morphDefs = {

 
  blastwing = {
    into = 'cormine1',
    time = 25,
  }, 
  

  --[[ // sample definition1 with multiple possible morphs... you nest arrays inside the definition
  armcom = {
    {
      into = 'armcomdgun',
      time = 20,
      metal = 10,
      energy = 10,
      tech = 1,
      xp = 0,
    },
    {
      into = 'corcom',
      time = 20,
      metal = 10,
      energy = 10,
      tech = 1,
      xp = 0,
    },
  }
  ]]--

  --[[armdecom = {
    into = 'armcom',
    time   = 20,    -- game seconds
    metal  = 10000, -- metal cost
    energy = 60000, -- energy cost
		tech = 2,				-- tech level
		xp = 0.5,				-- required unit XP
  },

  cordecom = {
    into = 'corcom',
    time   = 20,    -- game seconds
    metal  = 10000, -- metal cost
    energy = 60000, -- energy cost
		tech = 2,				-- tech level
  },]]--

--[[
  armcom = {
    {
      into = 'armcom_riot',
      time = 10,
      metal = 0,
      energy = 0,
      tech = 1,
      xp = 0,
    },
    {
      into = 'armcom_armored',
      time = 10,
      metal = 0,
      energy = 0,
      tech = 0,
      xp = 0,
    },
  },
  corcom = {
    {
      into = 'corcom_riot',
      time = 10,
      metal = 0,
      energy = 0,
      tech = 1,
      xp = 0,
    },
    {
      into = 'corcom_armored',
      time = 10,
      metal = 0,
      energy = 0,
      tech = 0,
      xp = 0,
    },
  },
--]]

  --// commanders
  armcom = {
    into = 'armadvcom',
	metal = 750,
	energy = 750,
    time = 75,
  },
  
  corcom = {
    into = 'coradvcom',
	metal = 750,
	energy = 750,
    time = 75,
  },
  
  commrecon = {
    into = 'commadvrecon',
	metal = 750,
	energy = 750,
    time = 75,
  },

  commsupport = {
    into = 'commadvsupport',
	metal = 750,
	energy = 750,
    time = 75,
  },  
  
  --// geos
  geo = {
    {
      into = 'amgeo',
      time = 90,
    },
--    {
--      into = 'armgmm',
--      time = 120,
--    },
  },
	-- //support units
   -- jammer
   armjamt = {
      into = 'spherecloaker',
      time = 25,
    }, 
	spherecloaker = {
      into = 'armjamt',
      time = 25,
    }, 
	
	-- shield
	corjamt = {
      into = 'core_spectre',
      time = 25,
    }, 
	core_spectre = {
      into = 'corjamt',
      time = 25,
    }, 

	-- radar
--[[
	corrad = {
      into = 'corvrad',
      time = 12,
    }, 
	corvrad = {
      into = 'corrad',
      time = 12,
    },	
--]]

  --// construction units
	
  --// combat units

  --// Evil4Zerggin: Revised time requirements. All rank requirements set to 3.
  --// Time requirements:
  --// To t1 unit: 10
  --// To t2 unit: 20
  --// To t1 structure: 30
  --// To t2 structure: 60
  
  --// KR: No longer consistently following tech time requirements, instead it's more correlated to cost difference (since there are no tech levels).

  --// cloakybots
  armflea = {
    { 
      into = 'armpw',
      time = 10,
      rank = 3,
    },
  }, 
  armrock = {
      into = 'armsptk',
      time = 20,
      rank = 3,
  },
  armjeth = {
    into = 'armaak',
    time = 20,
    rank = 3,
  }, 
  
  armpw = {
    {
      into = 'armwar',
      time = 10,
      rank = 3,
    },
    {
      into = 'spherepole',
      time = 10,
      rank = 3,
    },
  }, 
  armwar = {
    into = 'armzeus',
    time = 20,
    rank = 3,
  },
  armzeus = {
    into = 'armcrabe',
    time = 20,
    rank = 3,
  },
  armcrabe = {
    {
      into = 'armraz',
      time = 45,
      rank = 3,
    },
  },
  armraz = {
    into = 'armbanth',
    time = 90,
    rank = 3,
  },
  armbanth = {
    into = 'armorco',
    time = 180,
    rank = 3,
  },

  
  -- shield bots
  corak = {
    {
      into = 'cormak',
      time = 10,
      rank = 3,
    },
    {
      into = 'corpyro',
      time = 10,
      rank = 3,
    },
  },
  cormak = {
    into = 'corcan',
    time = 20,
    rank = 3,
  },
  corcan = {
    into = 'corsumo',
    time = 20,
    rank = 3,
  },
  corsumo = {
    {
      into = 'dante',
      time = 45,
      rank = 3,
    },
    {
      into = 'armraven',
      time = 45,
      rank = 3,
    },
  },
  corkarg = {
    into = 'gorg',
    time = 90,
    rank = 3,
  },
  gorg = {
    into = 'armorco',
    time = 180,
    rank = 3,
  },

  corstorm = {
    {
      into = 'punisher',
      time = 20,
      rank = 3,
    },
    {
      into = 'slowmort',
      time = 15,
      rank = 3,
    },
  },
  corthud = {			
    into = 'corcan',
    time = 20,
    rank = 3,
  },
  corcrash = {
    into = 'armaak',
    time = 20,
    rank = 3,
  },
  cormort = {
    into = 'cormortgold',
    time = 20,
    rank = 3,
  },

  -- // vehicles
  corfav = {
    into = 'corgator',
    time = 10,
    rank = 3,
  },
  corgator = {
    {
    into = 'corraid',
    time = 10,
    rank = 3,
    },
    {
    into = 'logkoda',
    time = 10,
    rank = 3,
    },
  },
  corraid = {
    into = 'correap',
    time = 20,
    rank = 3,
  },
  correap = {
    into = 'corgol',
    time = 20,
    rank = 3,   
  },
  corlevlr = {
    into = 'tawf114',
    time = 20,
    rank = 3,   
  },
  corgarp = {
    {
      into = 'cormart',
      time = 20,
      rank = 3,   
    },
    {
      into = 'armmerl',
      time = 20,
      rank = 3,   
    },
  },
  cormart = {
    {
      into = 'trem',
      time = 20,
      rank = 3,   
    },
  },
  cormist = {
    {
      into = 'corsent',
      time = 20,
      rank = 3,   
    },
  },
  
  --// hovers and amphs
  corsh = {
    {
      into = 'hoverassault',
      time = 10,
      rank = 3,   
    },
    {
      into = 'hoverriot',
      time = 15,
      rank = 3,   
    },
  },
  --//ships
  armpt = {
    {
      into = 'coresupp',
      time = 10,
      rank = 3,   
    },
  },
  armroy = {
    {
      into = 'corcrus',
      time = 20,
      rank = 3,   
    },
  },

  coresupp = {
    {
      into = 'corroy',
      time = 10,
      rank = 3,   
    },
	{
      into = 'armroy',
      time = 10,
      rank = 3,   
    },
  },
  corroy = {
    {
      into = 'corcrus',
      time = 20,
      rank = 3,   
    },
  },
  corcrus = {
    {
      into = 'armcarry',
      time = 30,
      rank = 3,   
    },
	{
      into = 'corbats',
      time = 30,
      rank = 3,   
    },
  },
--[[
  cormls = {
    {
      into = 'corarch',
      time = 20,
      rank = 3,   
    },
  },
--]]
  --// land turrets
  armdeva = {
    into = 'armpb',
    time = 60,
    rank = 3,
  },
  corllt = {
    {
      into = 'armdeva',
      time = 30,
      rank = 3,
    },
    {
      into = 'corgrav',
      time = 30,
      rank = 3,
    },
  }, 
  corhlt = {
    into = 'cordoom',
    time = 90,
    rank = 3,
  },
  corrl = {
	{
		into = 'corrazor',
		time = 60,
		rank = 3,
	},
	{
		into = 'missiletower',
		time = 60,
		rank = 3,
	},
  },
  corrazor = {
	{
		into = 'corflak',
		time = 60,
		rank = 3,
	},
  },
  armcir = {
    into = 'screamer',
    time = 60,
    rank = 3,
  },
  corflak = {
    into = 'screamer',
    time = 60,
    rank = 3,
  },
  
  --// sea turrets
  
  --// concept

  chicken_drone = {
    [1] = {
      into = 'chickend',
	  energy = 15,
      time = 20,
      rank = 0,
    },
   [2] = {
      into = 'nest',
	  energy = 30,
      time = 20,
      rank = 0,
    },
   [3] = {
      into = 'chickenspire',
	  energy = 600,
      time = 90,
      rank = 0,
    },
   [4] = {
      into = 'thicket',
      time = 4,
      rank = 0,
    },
  }, 

  nest = {
    into = 'roostfac',
    time = 60,
    rank = 0,
  },
  
  chicken_drone_starter = {
	
   [1] = {
      into = 'nest',
      time = 1,
      rank = 0,
    },
	
  }, 

  armfacinabox = {
    [1] = {into = 'armavp', metal = 0, energy = 0, time = 10, facing = true,},
    [2] = {into = 'armalab', metal = 0, energy = 0, time = 10, facing = true,},
    [3] = {into = 'armap', metal = 0, energy = 0, time = 10, facing = true,},
    [4] = {into = 'armfhp', metal = 0, energy = 0, time = 10, facing = true,},
    [5] = {into = 'armcsa', metal = 0, energy = 0, time = 10, facing = true,},
    [6] = {into = 'armaap', metal = 0, energy = 0, time = 10, facing = true,},
    [7] = {into = 'armlab', metal = 0, energy = 0, time = 10, facing = true,},
    [8] = {into = 'armsy', metal = 0, energy = 0, time = 10, facing = true,},
    [9] = {into = 'armvp', metal = 0, energy = 0, time = 10, facing = true,},
  },
  corfacinabox = {
    [1] = {into = 'coravp', metal = 0, energy = 0, time = 10, facing = true,},
    [2] = {into = 'coralab', metal = 0, energy = 0, time = 10, facing = true,},
    [3] = {into = 'corap', metal = 0, energy = 0, time = 10, facing = true,},
    [4] = {into = 'corfhp', metal = 0, energy = 0, time = 10, facing = true,},
    [5] = {into = 'corcsa', metal = 0, energy = 0, time = 10, facing = true,},
    [6] = {into = 'coraap', metal = 0, energy = 0, time = 10, facing = true,},
    [7] = {into = 'corlab', metal = 0, energy = 0, time = 10, facing = true,},
    [8] = {into = 'corsy', metal = 0, energy = 0, time = 10, facing = true,},
    [9] = {into = 'corvp', metal = 0, energy = 0, time = 10, facing = true,},
  },
}


local modOptions
if (Spring.GetModOptions) then
  modOptions = Spring.GetModOptions()
end

if (modOptions and modOptions.commtype == 'default') then

end



--
-- Here's an example of why active configuration
-- scripts are better then static TDF files...
--

--
-- devolution, babe  (useful for testing)
--
if (devolution) then
  local devoDefs = {}
  for src,data in pairs(morphDefs) do
    devoDefs[data.into] = { into = src, time = 10, metal = 1, energy = 1 }
  end
  for src,data in pairs(devoDefs) do
    morphDefs[src] = data
  end
end


return morphDefs

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
