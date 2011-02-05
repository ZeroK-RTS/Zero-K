--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
--  file:    unitdefgen.lua
--  brief:   procedural generation of unitdefs for modular comms
--  author:  KingRaptor (L.J. Lim)
--
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
Spring.Utilities = Spring.Utilities or {}
VFS.Include("LuaRules/Utilities/base64.lua")
--------------------------------------------------------------------------------
--	HOW IT WORKS: 
--	First, it makes one unitdef for each level of each player's comms, basing them off the template commanders.
--		The unitdefs are named: comm<type><level>_<playerID>
--	It then modifies each unitdef based on the upgrades selected for that player, comm type and level
--		For this test, the upgrade data is read from gamedata/modularcomms/testdata.lua.
--	Comm and upgrade types are defined in gamedata/modularcomms/moduledefs.lua.
--
--	TODO:
--		Figure out how modstats should handle procedurally generated comms
--			* May be easiest to just hardcode gadget to treat them as baseline comms
--------------------------------------------------------------------------------
VFS.Include("gamedata/modularcomms/moduledefs.lua")

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
local playerDataRaw = Spring.GetModOptions().unlocks
local playerDataFunc, err, success, playerData

playerDataRaw = VFS.Include("gamedata/modularcomms/testdata.lua")
--playerDataRaw = string.gsub(playerDataRaw, '_', '=')
--playerDataRaw = Spring.Utilities.Base64Decode(playerDataRaw)
Spring.Echo(playerDataRaw)
playerData = playerDataRaw

--[[
playerDataFunc, err = loadstring(playerDataRaw)
if playerDataFunc then
	success,playerData = pcall(playerDataFunc)
	if not success then	-- execute Borat
		err = playerData
		playerData = {}
	end
end
if err then 
	Spring.Echo('Modular Comms error: ' .. err)
end
]]--

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
local NUM_LEVELS = 2

commDefs = {}	--holds precedurally generated comm defs

players = {}
for id,_ in pairs(playerData) do
	players[id] = {}
end

-- copy and edit comm defs
for level=1,NUM_LEVELS do --per level
	for commName, commData in pairs(commTypes) do	--per type
		Spring.Echo("Processing commtype: ".. commName .. " level ".. level)
		for id, _ in pairs(players) do -- per player; uses pairs because ipairs breaks for some inane reason
			Spring.Echo("\tProcessing player "..id)
			local name = "comm"..commName..level.."_"..id
			commDefs[name] = CopyTable(commData[level], true)	--prep comm data by copying from template

			--upgrade handling
			if playerData[id][commName] and playerData[id][commName][level] then
				for _,upgradeName in pairs(playerData[id][commName][level].upgrades) do
					upgrades[upgradeName].func(commDefs[name])	--apply upgrade function
					Spring.Echo("\t\tApplying upgrade: "..upgradeName)
				end
				
				if playerData[id][commName][level].name then
					commDefs[name].name = playerData[id][commName][level].name
				end
				
				if playerData[id][commName][level].allowMorph then
					commDefs[name].customparams.comm_morph_target = "comm"..commName..(level+1).."_"..id
				end
				
				commDefs[name].customparams.comm_level = tostring(level)
			end
			--[[
			if playerData[id][commName] and playerData[id][commName].all then	-- upgrades applied to all levels 
				for _,upgradeName in pairs(playerData[id][commName].all.upgrades) do
					upgrades[upgradeName].func(commDefs[name])	--apply upgrade function
					Spring.Echo("\t\tApplying upgrade: "..upgradeName)
				end
			end
			]]--
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

-- splice back into unitdefs
for name, data in pairs(commDefs) do
	UnitDefs[name] = data
end
