--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
--  file:    unitdefgen.lua
--  brief:   procedural generation of unitdefs for modular comms
--  author:  KingRaptor (L.J. Lim)
--
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
--	HOW IT WORKS: 
--	First, it makes one unitdef for each level of each player's comms, basing them off the template commanders.
--		The unitdefs are named: comm<type><level>_<playerID>
--	It then modifies each unitdef based on the upgrades selected for that player, comm type and level
--		For this test, the upgrade data is read from gamedata/modularcomms/testdata.lua.
--	Comm and upgrade types are defined in gamedata/modularcomms/moduledefs.lua.
--
--	TODO:
--		Code handling for gadget defs
--		Figure out how modstats should handle procedurally generated comms
--			* May be easiest to just hardcode gadget to treat them as baseline comms
--		Find a way to feed system the data it needs from server
--------------------------------------------------------------------------------

local NUM_LEVELS = 2

commDefs = {}	--holds precedurally generated comm defs

players = { [0] = {},  [1] = {} } 	
--Spring.GetPlayerList() donut work
--also for some reason ipairs ignores the item at index 0, wtf?

-- copy and edit comm defs
for level=1,NUM_LEVELS do --per level
	for commName, commData in pairs(commTypes) do	--per type
		Spring.Echo("Processing commtype: ".. commName .. " level ".. level)
		for id, playerData in ipairs(players) do --per player
			Spring.Echo("\tProcessing player "..id)
			local name = "comm"..commName..level.."_"..id
			commDefs[name] = CopyTable(commData[level], true)	--prep comm data by copying from template

			--upgrade handling
			if testdata[id][commName] and testdata[id][commName][level] then
				for _,upgradeName in pairs(testdata[id][commName][level]) do  --reads from testdata.lua, modify in future to read from other source
					upgrades[upgradeName].func(commDefs[name])	--apply upgrade function
					Spring.Echo("\t\tApplying upgrade: "..upgradeName)
				end
			end
			if testdata[id][commName] and testdata[id][commName].all then	-- upgrades applied to all levels 
				for _,upgradeName in pairs(testdata[id][commName].all) do  --reads from testdata.lua, modify in future to read from other source
					upgrades[upgradeName].func(commDefs[name])	--apply upgrade function
					Spring.Echo("\t\tApplying upgrade: "..upgradeName)
				end
			end
		end
	end
end

--set weapon1 range	- may need exception list in future depending on what weapons we add
--[[
for name, data in pairs(commDefs) do
	Spring.Echo("\tPostprocessing commtype: ".. name)
	if data.weapondefs then
		local minRange = 999999
		for name, weaponData in pairs(data.weapondefs) do
			if weaponData.range < minRange then minRange = weaponData.range end
		end
		if data.weapons and data.weapondefs then
			local wepName = data.weapondefs[1].def
			wepName = string.lower(wepName)
			data.weapondefs[wepName].range = minRange
		end
	end
end
--]]

--splice back into unitdefs
for name, data in pairs(commDefs) do
	UnitDefs[name] = data
end
