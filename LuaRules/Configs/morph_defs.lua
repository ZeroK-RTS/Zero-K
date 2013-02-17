-- $Id: morph_defs.lua 4643 2009-05-22 05:52:27Z carrepairer $
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local devolution = false

local morphDefs = {
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
    {
      into = 'armraven',
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
  shieldarty = {
    into = 'firewalker',
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
  nsaclash = {
    {
      into = 'armmanni',
      time = 20,
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
  {
    into = 'armanni',
    time = 90,
    rank = 3,
	},
	{
    into = 'cordoom',
    time = 90,
    rank = 3,
	}
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

local baseComMorph = {
	[1] = {	time = 25, cost = 250},
	[2] = {	time = 30, cost = 300},
	[3] = {	time = 40, cost = 400},
	[4] = {	time = 50, cost = 500},
}

--------------------------------------------------------------------------------
-- basic (non-modular) commander handling
--------------------------------------------------------------------------------
local comms = {"armcom", "corcom", "commrecon", "commsupport", "benzcom", "cremcom"}
--[[
for i=1,#comms do
  for j=1,4 do
    local source = comms[i]..j
    local destination = comms[i]..(j+1)
    morphDefs[source] = {
      into = destination,
      time = baseComMorph[j].time,
      metal = baseComMorph[j].cost,
      energy = baseComMorph[j].cost,
      combatMorph = true,
    }
  end
end
]]

--------------------------------------------------------------------------------
-- modular commander handling
--------------------------------------------------------------------------------
local comMorph = {	-- not needed
	[1] = {	time = 20,},
	[2] = {	time = 25,},
	[3] = {	time = 30,},
	[4] = {	time = 35,},
	[5] = {	time = 40,},
}

local customComms = {}

local function InitUnsafe()
	if not Spring.GetPlayerList then
		return
	end
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
			Spring.Log(gadget:GetInfo().name, LOG.WARNING, 'Comm Morph warning: ' .. err)
		end

		for series, subdata in pairs(commData) do
			customComms[id] = customComms[id] or {}
			customComms[id][series] = subdata
		end
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
				--Spring.Echo("Configuring comm morph: "..(array[i]) , array[i+1])
				local sourceName, targetName = originDef.name, targetDef.name
				local morphCost
				local morphOption = comMorph[i] and Spring.Utilities.CopyTable(comMorph[i], true) or {}
				--if morphOption then
					morphOption.into = array[i+1]
					-- set time
					morphOption.time = math.floor( (targetDef.metalCost - originDef.metalCost) / (6 * (i+1)) ) or morphOption.time
					--morphOption.time = math.floor((targetDef.metalCost - originDef.metalCost)/10) or morphOption.time
					--morphOption.time = math.floor(15 + i*5) or morphOption.time
					morphOption.combatMorph = true
					-- copy, checking that this morph isn't already defined
					morphDefs[sourceName] = morphDefs[sourceName]  or {}
					if not CheckForExistingMorph(sourceName, targetName) then
						morphDefs[sourceName][#(morphDefs[sourceName]) + 1] = morphOption
					else
						Spring.Echo("Duplicate morph, exiting")
					end
				--else
					--Spring.Log(gadget:GetInfo().name, LOG.ERROR, "Comm Morph error: no setting for level "..i.."->"..i+1 .. " transition")
					--break
				--end
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
