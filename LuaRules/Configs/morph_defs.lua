-- $Id: morph_defs.lua 4643 2009-05-22 05:52:27Z carrepairer $
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local devolution = false

--deep not safe with circular tables! defaults To false
local function CopyTable(tableToCopy, deep)
  local copy = {}
  for key, value in pairs(tableToCopy) do
    if (deep and type(value) == "table") then
      copy[key] = CopyTable(value, true)
    else
      copy[key] = value
    end
  end
  return copy
end

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

  --// commanders
--[[
  armcom = {
	{
		into = 'armadvcom',
		metal = 750,
		energy = 750,
		time = 75,
	},
  },
  
  corcom = {
	{
		into = 'coradvcom',
		metal = 750,
		energy = 750,
		time = 75,
	},
  },
  
  commrecon = {
	{
		into = 'commadvrecon',
		metal = 750,
		energy = 750,
		time = 75,
	},
  },

  commsupport = {
	{
		into = 'commadvsupport',
		metal = 750,
		energy = 750,
		time = 75,
	},
  },  
--]]
  
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
      time = 30,
    }, 
	spherecloaker = {
      into = 'armjamt',
      time = 30,
    }, 
	
	-- shield
	corjamt = {
      into = 'core_spectre',
      time = 30,
    }, 
	core_spectre = {
      into = 'corjamt',
      time = 30,
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
      into = 'dante',
      time = 45,
      rank = 3,
    },
  },
  dante = {
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
  gorg = {
    into = 'armorco',
    time = 180,
    rank = 3,
  },

  corstorm = {
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
      into = 'corroy',
      time = 20,
      rank = 3,   
    },
  },
  coresupp = {
	{
      into = 'armroy',
      time = 10,
      rank = 3,   
    },
  },
  corroy = {
    {
      into = 'corbats',
      time = 45,
      rank = 3,   
    },
  },
  corsub = {
    {
      into = 'serpent',
      time = 45,
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
    into = 'armanni',
    time = 90,
    rank = 3,
  },
  armpb = {
    into = 'cordoom',
    time = 75,
    rank = 3,
  },
  corrl = {
	{
		into = 'corrazor',
		time = 30,
		rank = 3,
	},
	{
		into = 'missiletower',
		time = 30,
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
  missiletower = {
	{
		into = 'armcir',
		time = 75,
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
    time = 75,
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
	{
      into = 'nest',
      time = 1,
      rank = 0,
    },
  }, 
}


--------------------------------------------------------------------------------
-- modular commander handling
--------------------------------------------------------------------------------
local comMorph = {
	[1] = {
		metal = 300,
		energy = 300,
		time = 30,
	},
	[2] = {
		metal = 650,
		energy = 650,
		time = 65,
	},
	[3] = {
		metal = 500,
		energy = 500,
		time = 50,
	},
}

--[[
local comMorphTree = {
	strike = {armcom, armadvcom},
	battle = {corcom, coradvcom},
	recon = {commrecon, commadvrecon},
	support = {commsupport, commadvsupport},
}
]]--

local customComms = {}

local function InitUnsafe()
	for name, id in pairs(Spring.GetPlayerList()) do	-- pairs(playerIDsByName) do
		-- copied from PlanetWars
		local commData, success
		local customKeys = select(10, Spring.GetPlayerInfo(id))
		local commDataRaw = customKeys and customKeys.commanders
		if not (commDataRaw and type(commDataRaw) == 'string') then
			err = "Comm data entry for player "..id.." is empty or in invalid format"
			commData = {}
		else
			commDataRaw = string.gsub(commDataRaw, '_', '=')
			commDataRaw = Spring.Utilities.Base64Decode(commDataRaw)
			--Spring.Echo(commDataRaw)
			local commDataFunc, err = loadstring("return "..commDataRaw)
			if commDataFunc then 
				success, commData = pcall(commDataFunc)
				if not success then
					err = commData
					commData = {}
				end
			end
		end
		if err then 
			Spring.Echo('Comm Morph error: ' .. err)
		end

		for chassis, subdata in pairs(commData) do
			customComms[id] = customComms[id] or {}
			customComms[id][chassis] = subdata
		end
		
		-- this method makes no sense, it's not like any given generated def will be used for more than one replacement/player!
		-- would be more logical to use replacee as key and replacement as value in player customkeys
		--[[
		customComms[id] = customComms[id] or {}
		for replacementComm, replacees in pairs(commData) do
			for _,name in pairs(replacees) do
				customComms[id][name] = replacementComm
			end
		end
		]]--
	end
end

local function CheckForExistingMorph(morphee, target)
	local array = morphDefs[morphee]
	if not array then return false end
	if array.into then
		if array.into == target then return true
		else return false end
	end
	for index,morphOpts in pairs(array) do
		if morphOpts.into and morphOpts.into == target then return true end
	end
	return false
end

InitUnsafe()
for id, playerData in pairs(customComms) do
	Spring.Echo("Setting morph for custom comms for player: "..id)
	for chassisName, array in pairs(playerData) do
		for i=1,#array do
			--Spring.Echo(array[i], array[i+1])
			local targetDef = array[i+1] and UnitDefNames[array[i+1]]
			local originDef = UnitDefNames[array[i]] or UnitDefNames[array[i]]
			if targetDef and originDef then
				Spring.Echo("Configuring comm morph: "..(array[i]) , array[i+1])
				local sourceName, targetName = originDef.name, targetDef.name
				local morphCost
				local morphOption = comMorph[i] and CopyTable(comMorph[i], true)
				if morphOption then
					morphOption.into = array[i+1]
					-- set cost
					morphCost = (targetDef.customParams and targetDef.customParams.morphCost) or 0
					morphTime = (targetDef.customParams and targetDef.customParams.morphTime) or 0
					morphCostDiscount = (originDef.customParams and originDef.customParams.morphCost) or 0
					morphTimeDiscount = (originDef.customParams and originDef.customParams.morphTime) or 0
					morphOption.metal = morphOption.metal + morphCost - morphCostDiscount
					morphOption.energy = morphOption.energy + morphCost - morphCostDiscount
					morphOption.time = morphOption.time + morphTime - morphTimeDiscount
				
					-- copy, checking that this morph isn't already defined
					morphDefs[sourceName] = morphDefs[sourceName]  or {}
					if not CheckForExistingMorph(sourceName, targetName) then
						morphDefs[sourceName][#(morphDefs[sourceName]) + 1] = morphOption
					else
						Spring.Echo("Duplicate morph, exiting")
					end
				else
					Spring.Echo("Comm Morph error: no setting for level "..i.."->"..i+1 .. " transition")
					break
				end
			end
		end
	end
end

--check that the morphs were actually inserted
--[[
for i,v in pairs(morphDefs) do
	Spring.Echo(i)
	if v.into then Spring.Echo("\t"..v.into)
	else
		for a,b in pairs(v) do Spring.Echo("\t"..b.into) end
	end
end
]]--
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
