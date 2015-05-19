
function gadget:GetInfo()
  return {
    name      = "Dev Commands",
    desc      = "Adds useful commands.",
    author    = "Google Frog",
    date      = "12 Sep 2011",
    license   = "GNU GPL, v2 or later",
    layer     = 0,
    enabled   = true,  --  loaded by default?
	handler   = true,
  }
end


local syncedGadgetList = {
	"Ceasefires2",
	"Perks",
	"UnitMorph",
	"DroppedStartPos",
	"Dont fire at radar",
	"Disable Buildoptions",
	"Teleporter",
	"Grey Goo",
	"No Self-D",
	"Attributes",
	"Fall Damage",
	"Transport Speed",
	"MarketPlace",
	"Refuel Pad Handler",
	"Windmill Control",
	"Weapon Timed Replace",
	"Mod statistics",
	"Unit Explosion Spawner",
	"astar.lua",
	"Tactical Unit AI",
	"Repair Speed Changer",
	"Terrain Texture Handler",
	"Spherical LOS",
	"Target Priority",
	"TransportAIbuttons",
	--"Dev Commands",
	"ranks api",
	"Nano Frame Death Handeling",
	"Terraformers",
	"Mex Placement",
	"AutoReadyStartpos",
	"Lups Cloak FX",
	"Test",
	"api_subdir_gadgets.lua",
	"NoAirNuke",
	"Lag Monitor",
	"Animator",
	"Control gunship strafe range",
	"Awards",
	"Carrier Drones",
	"Bounties",
	"Aircraft Command",
	"Boolean Disable",
	"DoLine",
	"Instant Self Destruct",
	"Missile Silo Controller",
	"Factory Anti Slacker",
	"Time slow v2",
	"Gunship Strafe Control",
	"Aircraft Crashing",
	"Game Over",
	"UnitStealth",
	"Noexplode Stopper",
	"Puppy Handler",
	"Blocking Tag Implementation",
	"Area Denial",
	"Water Effects",
	"UnitPriority",
	"Rezz Hp changer + effect",
	"Units on fire",
	"Metalspot Finder Gadget",
	"Allow Builder Hold Fire",
	"Target on the move",
	"Unit E-Stall Disable",
	"Stockpile",
	"Impulse Float Toggle",
	"Retreat Command",
	"LUS",
	--"Profiler",
	"Decloak when damaged",
	"ShareControl",
	"Center Offset",
	"Shield Link",
	"Set Nano Piece",
	"Self destruct blocker",
	"LockOptions",
	"AirTransport_SeaPickup",
	"Area Guard",
	"Reclaim HP changer",
	"Weapon Impulse ",
	"Bomber Dive",
	"Solar Force Closed",
	"Vertical Swarm",
	"Prevent Lab Hax",
	"lups_wrapper.lua",
	"Jumpjets",
	"One Click Weapon",
	"Paralysis",
	"Thrusters",
	"No Friendly Fire",
	"AirPlantParents",
	"UnitCloakShield",
	"StartSetup",
	"Save/Load",
	"Mex Control with energy link",
	"Capture",
	"Single-Hit Weapon",
	"IconGenerator",
	"Orbital Drop",
	"D-Gun Aim Fix",
	"lavarise",
	"Resign Gadget",
	"CMD_RAW_MOVE",
	"CEG Spawner",
	"LupsNanoSpray",
	"CustomUnitShaders",
	"Hide Autorepairlevel Command",
}

local unsyncedGadgetList = {
	"Ceasefires2",
	"LockOptions",
	"Awards",	
	"Noexplode Stopper",	
	"Perks",	
	"Ore mexes!",
	"Control gunship strafe range",
	"Area Denial",
	"Bounties",
	"Aircraft Command",
	"DoLine",
	"CAI",
	"Lups",
	"Dont fire at radar",
	"Teleporter",
	"Rezz Hp changer + effect",
	"Factory Anti Slacker",
	"Bomber Dive",
	"Attributes",
	"Thrusters",
	"Planet Wars Structures",
	"Fall Damage",
	"DroppedStartPos",
	"BOXXY R1 w volume type",
	"Transport Speed",
	"Aircraft Crashing",
	"Game Over",
	"Terraformers",
	"UnitStealth",
	"Windmill Control",
	"Target on the move",
	"Spherical LOS",
	"Chicken Spawner",
	"Animator",
	"Shield Link",
	"Self destruct blocker",
	"Units on fire",
	"Metalspot Finder Gadget",
	"Allow Builder Hold Fire",
	"UnitPriority",
	"Prevent Lab Hax",
	"One Click Weapon",
	"Impulse Float Toggle",
	"Jugglenaut Juggle",
	"Retreat Command",
	"Unit Explosion Spawner",
	"UnitMorph",
	"Chicken control",
	"ShareControl",
	"Area Guard",
	"astar.lua",
	"unit_missilesilo.lua",
	"MarketPlace",
	"IconGenerator",	
	"AirTransport_SeaPickup",
	"lavarise",
	"Unit E-Stall Disable",
	"Disable Features",	
	"Weapon Impulse ",
	"Water Effects",
	"Resign Gadget",
	"Solar Force Closed",
	"Center Offset",
	"Target Priority",
	"Capture",
	"TransportAIbuttons",
	--"Dev Commands",
	"unit_carrier_drones.lua",
	"Lag Monitor",
	"AirPlantParents",	
	"ranks api",
	"UnitCloakShield",	
	"StartSetup",
	"Save/Load",
	"Mex Control with energy link",
	"LupsNanoSpray",
	"Mex Placement",
	"Single-Hit Weapon",
	"CMD_RAW_MOVE",
	"Zombies!",
	"CustomUnitShaders",	
	"Lups Cloak FX",
	"Test",
	"Hide Autorepairlevel Command",
	"CEG Spawner",
	"api_subdir_gadgets.lua",
}

local gadgetList = {
	"Ceasefires2",
	"Perks",
	"UnitMorph",
	"DroppedStartPos",
	"Dont fire at radar",
	"Disable Buildoptions",
	"Teleporter",
	"Grey Goo",
	"No Self-D",
	"Attributes",
	"Fall Damage",
	"Transport Speed",
	"MarketPlace",
	"Refuel Pad Handler",
	"Windmill Control",
	"Weapon Timed Replace",
	"Mod statistics",
	"Unit Explosion Spawner",
	"astar.lua",
	"Tactical Unit AI",
	"Repair Speed Changer",
	"Terrain Texture Handler",
	"Spherical LOS",
	"Target Priority",
	"TransportAIbuttons",
	"ranks api",
	"Nano Frame Death Handeling",
	"Terraformers",
	"Mex Placement",
	"AutoReadyStartpos",
	"Lups Cloak FX",
	"Test",
	"api_subdir_gadgets.lua",
	"NoAirNuke",
	"Lag Monitor",
	"Animator",
	"Control gunship strafe range",
	"Awards",
	"Carrier Drones",
	"Bounties",
	"Aircraft Command",
	"Boolean Disable",
	"DoLine",
	"Instant Self Destruct",
	"Missile Silo Controller",
	"Factory Anti Slacker",
	"Time slow v2",
	"Gunship Strafe Control",
	"Aircraft Crashing",
	"Game Over",
	"UnitStealth",
	"Noexplode Stopper",
	"Puppy Handler",
	"Blocking Tag Implementation",
	"Area Denial",
	"Water Effects",
	"UnitPriority",
	"Rezz Hp changer + effect",
	"Units on fire",
	"Metalspot Finder Gadget",
	"Allow Builder Hold Fire",
	"Target on the move",
	"Unit E-Stall Disable",
	"Stockpile",
	"Impulse Float Toggle",
	"Retreat Command",
	"LUS",
	"Decloak when damaged",
	"ShareControl",
	"Center Offset",
	"Shield Link",
	"Set Nano Piece",
	"Self destruct blocker",
	"LockOptions",
	"AirTransport_SeaPickup",
	"Area Guard",
	"Reclaim HP changer",
	"Weapon Impulse ",
	"Bomber Dive",
	"Solar Force Closed",
	"Vertical Swarm",
	"Prevent Lab Hax",
	"lups_wrapper.lua",
	"Jumpjets",
	"One Click Weapon",
	"Paralysis",
	"Thrusters",
	"No Friendly Fire",
	"AirPlantParents",
	"UnitCloakShield",
	"StartSetup",
	"Save/Load",
	"Mex Control with energy link",
	"Capture",
	"Single-Hit Weapon",
	"IconGenerator",
	"Orbital Drop",
	"D-Gun Aim Fix",
	"lavarise",
	"Resign Gadget",
	"CMD_RAW_MOVE",
	"CEG Spawner",
	"LupsNanoSpray",
	--"CustomUnitShaders",
	"Hide Autorepairlevel Command",
	"Ore mexes!",
	"CAI",
	"Lups",
	"Planet Wars Structures",
	"BOXXY R1 w volume type",
	"Chicken Spawner",
	"Jugglenaut Juggle",
	"Chicken control",
	"unit_missilesilo.lua",
	"Disable Features",
	"unit_carrier_drones.lua",
	"Zombies!",
}

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------

local spIsCheatingEnabled = Spring.IsCheatingEnabled

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------

if (gadgetHandler:IsSyncedCode()) then
   


-- '/luarules circle'
-- '/luarules give'
-- '/luarules gk'
-- '/luarules clear'
-- '/luarules restart'

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------

-- UnitName TeamID Number Radius [Xpos Zpos]
-- For example '/luarules circle corllt 1 60 420 3200 3200'
local function circleGive(cmd, line, words, player)
	if not (spIsCheatingEnabled() and #words >= 4) then 
		return
	end
	local unitName = words[1]
	local team = math.abs(tonumber(words[2]) or 0)
	local count = math.floor(tonumber(words[3]) or 0)
	local radius = math.abs(tonumber(words[4]) or 0)
	local ox = tonumber(words[5]) or Game.mapSizeX/2
	local oz = tonumber(words[6]) or Game.mapSizeZ/2
	if not (type(unitName) == "string" and UnitDefNames[unitName] and team >= 0 and count > 0 and radius > 0) then
		return
	end
	local unitDefID = UnitDefNames[unitName].id
	local increment = 2*math.pi/count
	for i = 1, count do
		local angle = i*increment
		local x = ox + math.cos(angle)*radius
		local z = oz + math.sin(angle)*radius
		local y = Spring.GetGroundHeight(x,z)
		Spring.CreateUnit(unitDefID, x, y, z, 0, team, false)
	end
end

local function give(cmd,line,words,player)
	if spIsCheatingEnabled() then
		local buildlist = UnitDefNames["armcom1"].buildOptions
		local INCREMENT = 128
		for i = 1, #buildlist do
			local udid = buildlist[i]
			local x, z = INCREMENT, i*INCREMENT
			local y = Spring.GetGroundHeight(x,z)
			Spring.CreateUnit(udid, x, y, z, 0, 0, false)
			local ud = UnitDefs[udid]
			if ud.buildOptions and #ud.buildOptions > 0 then
				local sublist = ud.buildOptions
				for j = 1, #sublist do
					local subUdid = sublist[j]
					local x2, z2 = (j+1)*INCREMENT, i*INCREMENT
					local y2 = Spring.GetGroundHeight(x2,z2)
					Spring.CreateUnit(subUdid, x2, y2, z2+32, 0, 0, false)
					--Spring.CreateUnit(subUdid, x2+32, y2, z2, 1, 0, false)
					--Spring.CreateUnit(subUdid, x2, y2, z2-32, 2, 0, false)
					--Spring.CreateUnit(subUdid, x2-32, y2, z2, 3, 0, false)
				end	
			end
		end
	end
end

local function gentleKill(cmd,line,words,player)
	if spIsCheatingEnabled() then
		local units = Spring.GetAllUnits()
		for i=1, #units do
			local unitID = units[i]
			Spring.SetUnitHealth(unitID,0.1)
			Spring.AddUnitDamage(unitID,1, 0, nil, -7)
		end
	end
end

local function clear(cmd,line,words,player)
	if spIsCheatingEnabled() then
		local units = Spring.GetAllUnits()
		for i=1, #units do
			local unitID = units[i]
			Spring.DestroyUnit(unitID, false, true)
		end
		local features = Spring.GetAllFeatures()
		for i=1, #features do
			local featureID = features[i]
			Spring.DestroyFeature(featureID)
		end
	end
end

local function restart(cmd,line,words,player)
	if spIsCheatingEnabled() then
		local units = Spring.GetAllUnits()
		
		local teams = Spring.GetTeamList()
		for i=1,#teams do
			local teamID = teams[i]
			if GG.startUnits[teamID] and GG.CommanderSpawnLocation[teamID] then
				local spawn = GG.CommanderSpawnLocation[teamID]
				local unitID = GG.DropUnit(GG.startUnits[teamID], spawn.x, spawn.y, spawn.z, spawn.facing, teamID, nil, 0)
				Spring.SetUnitRulesParam(unitID, "facplop", 1, {inlos = true})
			end
		end
		
		for i=1, #units do
			local unitID = units[i]
			Spring.DestroyUnit(unitID, false, true)
		end
		local features = Spring.GetAllFeatures()
		for i=1, #features do
			local featureID = features[i]
			Spring.DestroyFeature(featureID)
		end
	end
end

local function bisect(cmd,line,words,player)
	local increment = math.abs(tonumber(words[1]) or 1)
	local offset = math.floor(tonumber(words[2]) or 0)
	local invert = (math.abs(tonumber(words[3]) or 0) == 1) or false
	
	--[[
	local occured = {}
	for i = 1, #syncedGadgetList do
		occured[syncedGadgetList[i] ] = true
	end
	for i = 1, #unsyncedGadgetList do 
		if not occured[unsyncedGadgetList[i] ] then
			syncedGadgetList[#syncedGadgetList+1] = unsyncedGadgetList[i]
		end
	end
	
	for i = 1, #syncedGadgetList do
		Spring.Echo("\"" .. syncedGadgetList[i] .. "\",")
	end
	--]]
	
	for i = 1, #gadgetList do
		if i >= offset and (offset-i)%increment == 0 then
			if not invert then
				gadgetHandler:GotChatMsg("disablegadget " .. gadgetList[i], 0)
			end
		elseif invert then
			gadgetHandler:GotChatMsg("disablegadget " .. gadgetList[i], 0)
		end
	end
end

function gadget:Initialize()
	gadgetHandler.actionHandler.AddChatAction(self,"bisect",bisect,"Bisect gadget disables.")
	gadgetHandler.actionHandler.AddChatAction(self,"circle",circleGive,"Gives a bunch of units in a circle.")
	gadgetHandler.actionHandler.AddChatAction(self,"give",give,"Like give all but without all the crap.")
	gadgetHandler.actionHandler.AddChatAction(self,"gk",gentleKill,"Gently kills everything.")
	gadgetHandler.actionHandler.AddChatAction(self,"clear",clear,"Clears all units and wreckage.")
	gadgetHandler.actionHandler.AddChatAction(self,"restart",restart,"Gives some commanders and clears everything else.")
end

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
else -- UNSYNCED
-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------

local function bisect(cmd,line,words,player)
	local increment = math.abs(tonumber(words[1]) or 1)
	local offset = math.floor(tonumber(words[2]) or 0)
	local invert = (math.abs(tonumber(words[3]) or 0) == 1) or false
	
	for i = 1, #gadgetList do
		if i >= offset and (offset-i)%increment == 0 then
			if not invert then
				gadgetHandler:GotChatMsg("disablegadget " .. gadgetList[i], 0)
			end
		elseif invert then
			gadgetHandler:GotChatMsg("disablegadget " .. gadgetList[i], 0)
		end
	end
	collectgarbage("collect")
end

local function gc()
	collectgarbage("collect")
end

function gadget:Initialize()
	gadgetHandler.actionHandler.AddChatAction(self,"bisect",bisect,"Bisect gadget disables.")
	gadgetHandler.actionHandler.AddChatAction(self,"gc",gc,"Garbage collect.")
end

end
   