-- $Id: morph_defs.lua 4643 2009-05-22 05:52:27Z carrepairer $
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local devolution = false

local morphDefs = {
  --// Evil4Zerggin: Revised time requirements. All rank requirements set to 3.
  --// Time requirements:
  --// To t1 unit: 10
  --// To t2 unit: 20
  --// To t1 structure: 30
  --// To t2 structure: 60
  
  --// KR: No longer consistently following tech time requirements, instead it's more correlated to cost difference (since there are no tech levels).
  --// Hidden Chicken Faction

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
	[0] = {	time = 10, cost = 0},
	[1] = {	time = 25, cost = 250},
	[2] = {	time = 30, cost = 300},
	[3] = {	time = 40, cost = 400},
	[4] = {	time = 50, cost = 500},
}

--------------------------------------------------------------------------------
-- customparams
--------------------------------------------------------------------------------
for i=1,#UnitDefs do
  local ud = UnitDefs[i]
  local cp = ud.customParams
  local name = ud.name
  local morphTo = cp.morphto
  if morphTo then
    local targetDef = UnitDefNames[morphTo]
    morphDefs[name] = morphDefs[name] or {}
    morphDefs[name][#morphDefs[name] + 1] = {
      into = morphTo,
      time = cp.morphtime or (cp.level and math.floor((targetDef.metalCost - ud.metalCost) / (6 * (cp.level+1)))),	-- or 30,
      combatMorph = cp.combatmorph == "1"
    }
  end
end

--------------------------------------------------------------------------------
-- basic (non-modular) commander handling
--------------------------------------------------------------------------------
local comms = {"armcom", "corcom", "commrecon", "commsupport", "benzcom", "cremcom"}

for i=1,#comms do
  for j = 0,4 do
    local source = comms[i] .. j
    local destination = comms[i] .. (j+1)
    morphDefs[source] = {
      into = destination,
      time = baseComMorph[j].time,
      metal = baseComMorph[j].cost,
      energy = baseComMorph[j].cost,
      combatMorph = true,
    }
  end
end


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
