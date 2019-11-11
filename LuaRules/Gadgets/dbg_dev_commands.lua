
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
	"Old Jugglenaut Juggle",
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
	"CAI",
	"Lups",
	"Planet Wars Structures",
	"BOXXY R1 w volume type",
	"Chicken Spawner",
	"Old Jugglenaut Juggle",
	"Chicken control",
	"unit_missilesilo.lua",
	"Disable Features",
	"unit_carrier_drones.lua",
	"Zombies!",
}

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------

local spIsCheatingEnabled = Spring.IsCheatingEnabled


local creationUnitList, creationIndex

local BUILD_RESOLUTION =  16
local function SanitizeBuildPositon(x, z, ud, facing)
	local oddX = (ud.xsize % 4 == 2)
	local oddZ = (ud.zsize % 4 == 2)
	
	if facing % 2 == 1 then
		oddX, oddZ = oddZ, oddX
	end
	
	if oddX then
		x = math.floor((x + 8)/BUILD_RESOLUTION)*BUILD_RESOLUTION - 8
	else
		x = math.floor(x/BUILD_RESOLUTION)*BUILD_RESOLUTION
	end
	if oddZ then
		z = math.floor((z + 8)/BUILD_RESOLUTION)*BUILD_RESOLUTION - 8
	else
		z = math.floor(z/BUILD_RESOLUTION)*BUILD_RESOLUTION
	end
	return x, z
end

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------

function GG.TableEcho(data, tableName, indent)
	indent = indent or ""
	tableName = tableName or "TableEcho"
	Spring.Echo(indent .. tableName .. " = {")
	for name, v in pairs(data) do
		local ty =  type(v)
		if ty == "table" then
			GG.TableEcho(v, name, indent .. "    ")
		elseif ty == "boolean" then
			Spring.Echo(indent .. name .. " = " .. (v and "true" or "false"))
		else
			Spring.Echo(indent .. name .. " = " .. v)
		end
	end
	Spring.Echo(indent .. "}")
end

function GG.UnitEcho(unitID, st)
	st = st or unitID
	if Spring.ValidUnitID(unitID) then
		local x,y,z = Spring.GetUnitPosition(unitID)
		Spring.MarkerAddPoint(x,y,z, st)
	else
		Spring.Echo("Invalid unitID")
		Spring.Echo(unitID)
		Spring.Echo(st)
	end
end

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------

if (gadgetHandler:IsSyncedCode()) then
   


-- '/luarules circle'
-- '/luarules give'
-- '/luarules gk'
-- '/luarules clear'
-- '/luarules restart'

local ORDERS_PASSIVE = {
	{
		CMD.FIRE_STATE,
		{0},
		0,
	},
	{
		CMD.MOVE_STATE,
		{0},
		0,
	},
}

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------

-- UnitName TeamID Number Radius [Xpos Zpos]
-- For example '/luarules circle turretlaser 1 60 420 3200 3200'
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

local function MoveUnit(cmd, line, words, player)
	if not (spIsCheatingEnabled() and #words >= 3) then
		return
	end
	local unitID = tonumber(words[1])
	local x = tonumber(words[2])
	local z = tonumber(words[3])
	
	if not (unitID and x and z) then
		return
	end
	
	Spring.SetUnitPosition(unitID, x, z)
end

local function DestroyUnit(cmd, line, words, player)
	if not (spIsCheatingEnabled() and #words >= 1) then
		return
	end
	local unitID = tonumber(words[1])
	if unitID then
		Spring.DestroyUnit(unitID, false, true)
	end
end

local function RotateUnit(cmd, line, words, player)
	if not (spIsCheatingEnabled() and #words >= 2) then
		return
	end
	local unitID = tonumber(words[1])
	local facing = tonumber(words[2])
	if not (unitID and facing and Spring.ValidUnitID(unitID)) or Spring.GetUnitIsDead(unitID) then
		return
	end
	local teamID = Spring.GetUnitTeam(unitID)
	local unitDefID = Spring.GetUnitDefID(unitID)
	local x,y,z = Spring.GetUnitPosition(unitID)
	local ud = unitDefID and UnitDefs[unitDefID]
	if ud.isImmobile then
		x, z = SanitizeBuildPositon(x, z, ud, facing)
	end
	
	Spring.DestroyUnit(unitID, false, true)
	Spring.CreateUnit(unitDefID, x, y, z, facing, teamID)
end

local function SetupNanoUnit(unitID, nanoAmount)
	local _, maxHealth = Spring.GetUnitHealth(unitID)
	Spring.SetUnitHealth(unitID, {build = nanoAmount, health = maxHealth})
end

local function give(cmd,line,words,player)
	if not spIsCheatingEnabled() then
		return
	end
	
	local nanoAmount = math.max(0.01, math.min(1, tonumber(words[1] or "1") or 1))
	local build = (nanoAmount < 1)
	
	local buildlist = UnitDefNames["armcom1"].buildOptions
	local INCREMENT = 128
	local orderUnit = {}
	for i = 1, #buildlist do
		local udid = buildlist[i]
		local x, z = INCREMENT, i*INCREMENT
		local y = Spring.GetGroundHeight(x,z)
		local unitID = Spring.CreateUnit(udid, x, y, z, 0, 0, build)
		if build then
			SetupNanoUnit(unitID, nanoAmount)
		end
		local ud = UnitDefs[udid]
		if ud.buildOptions and #ud.buildOptions > 0 then
			local sublist = ud.buildOptions
			for j = 1, #sublist do
				local subUdid = sublist[j]
				local x2, z2 = (j+1)*INCREMENT, i*INCREMENT
				local y2 = Spring.GetGroundHeight(x2,z2)
				local subUnitID = Spring.CreateUnit(subUdid, x2, y2, z2+32, 0, 0, build)
				if build then
					SetupNanoUnit(subUnitID, nanoAmount)
				end
				orderUnit[#orderUnit + 1] = subUnitID
				--Spring.CreateUnit(subUdid, x2+32, y2, z2, 1, 0, false)
				--Spring.CreateUnit(subUdid, x2, y2, z2-32, 2, 0, false)
				--Spring.CreateUnit(subUdid, x2-32, y2, z2, 3, 0, false)
			end
		end
	end
	Spring.GiveOrderArrayToUnitArray(orderUnit, ORDERS_PASSIVE)
end

local function PlanetwarsGive(cmd,line,words,player)
	if not spIsCheatingEnabled() then
		return
	end
	
	local INCREMENT = 128
	local index = 1
	for unitDefID = 1, #UnitDefs do
		local ud = UnitDefs[unitDefID]
		if ud and string.find(ud.name, "pw_") then
			local x, z = INCREMENT, index*INCREMENT
			local y = Spring.GetGroundHeight(x,z)
			local unitID = Spring.CreateUnit(unitDefID, x, y, z, 0, 0, build)
			index = index + 1
		end
	end
end

local function ColorTest(cmd,line,words,player)
	if not spIsCheatingEnabled() then
		return
	end
	
	local displayDefID = UnitDefNames["energysolar"].id
	local displayDefID2 = UnitDefNames["dyntrainer_assault_base"].id
	local jumbleDefID = UnitDefNames["cloakraid"].id
	local INCREMENT = 96
	local orderUnit = {}
	
	local allyTeamList = Spring.GetAllyTeamList()
	for i = 1, #allyTeamList do
		local teamList = Spring.GetTeamList(allyTeamList[i])
		for j = 1, #teamList do
			local teamID = teamList[j]
			local x, z = j*INCREMENT, i*INCREMENT
			local y = Spring.GetGroundHeight(x,z)
			orderUnit[#orderUnit + 1] = Spring.CreateUnit(displayDefID, x, y, z, 0, teamID, false)
			orderUnit[#orderUnit + 1] = Spring.CreateUnit(displayDefID2, x, y, 800 + z, 0, teamID, false)
			
			for k = 1, 15 do
				local rx, rz = 2600 + math.random()*1000, 3000 + math.random()*1000
				local ry = Spring.GetGroundHeight(rx, rz)
				orderUnit[#orderUnit + 1] = Spring.CreateUnit(jumbleDefID, rx, ry, rz, 0, teamID, false)
			end
		end
	end
	
	Spring.GiveOrderArrayToUnitArray(orderUnit, ORDERS_PASSIVE)
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

local function nanoFrame(cmd,line,words,player)
	if not spIsCheatingEnabled() then
		return
	end
	local nanoAmount = math.max(0.01, math.min(1, tonumber(words[1] or "0.99") or 0.99))
	local units = Spring.GetAllUnits()
	for i=1, #units do
		local unitID = units[i]
		Spring.SetUnitHealth(unitID, {build = nanoAmount})
	end
end

local function rezAll(cmd,line,words,player)
	if not spIsCheatingEnabled() then
		return
	end

	local features = Spring.GetAllFeatures()
	for i = 1, #features do
		local featureID = features[i]
		local defName, facing = Spring.GetFeatureResurrect(featureID)
		if defName ~= "" then
			local x, y, z = Spring.GetFeaturePosition(featureID)
			local teamID = Spring.GetFeatureTeam(featureID)
			if teamID == -1 then
				teamID = Spring.GetGaiaTeamID()
			end
			Spring.DestroyFeature(featureID)
			Spring.CreateUnit(defName, x, y, z, facing, teamID)
		end
	end
end

local function damage(cmd,line,words,player)
	if spIsCheatingEnabled() then
		local units = Spring.GetAllUnits()
		for i=1, #units do
			local unitID = units[i]
			Spring.SetUnitHealth(unitID,1)
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

local function uclear(cmd,line,words,player)
	if spIsCheatingEnabled() then
		local units = Spring.GetAllUnits()
		for i=1, #units do
			local unitID = units[i]
			Spring.DestroyUnit(unitID, false, true)
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

local function serial(cmd,line,words,player)
	if not spIsCheatingEnabled() then
		return
	end
	local buildlist = UnitDefNames["armcom1"].buildOptions
	local unitList = {}
	for i = 1, #buildlist do
		local udid = buildlist[i]
		local ud = UnitDefs[udid]
		unitList[#unitList + 1] = udid
		if ud.buildOptions and #ud.buildOptions > 0 then
			local sublist = ud.buildOptions
			for j = 1, #sublist do
				unitList[#unitList + 1] = sublist[j]
			end
		end
	end
	
	creationIndex = tonumber(words[1]) or 1
	creationUnitList = unitList
	gadgetHandler:UpdateGadgetCallIn('GameFrame', gadget)
end

local function EchoCrush()
	if not spIsCheatingEnabled() then
		return
	end
	
	local features = Spring.GetAllFeatures()
	for i = 1, #features do
		local featureID = features[i]
		local fdid = Spring.GetFeatureDefID(featureID)
		local mass = fdid and FeatureDefs[fdid] and FeatureDefs[fdid].mass
		if mass then
			local crush = 1
			if mass < 50 then
				crush = 2
			elseif mass < 150 then
				crush = 3
			elseif mass < 500 then
				crush = 4
			else
				crush = "x"
			end
			Spring.Utilities.FeatureEcho(featureID, crush)
		end
	end
end

local function bisect(cmd,line,words,player)
	if not spIsCheatingEnabled() then
		return
	end
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

local function nocost(cmd,line,words,player)
	if not spIsCheatingEnabled() then
		return
	end
	local enabled = not (tonumber(words[1]) == 0)
	GG.SetFreeMorph(enabled)
	Spring.Echo("Free morph " .. ((enabled and "enabled") or "disabled") .. ".")
end

local function EmpiricalDps(cmd,line,words,player)
	if not spIsCheatingEnabled() then
		return
	end
	local enabled = not (tonumber(words[1]) == 0)
	if enabled then
		gadgetHandler:GotChatMsg("enablegadget Empirical DPS", 0)
	else
		gadgetHandler:GotChatMsg("disablegadget Empirical DPS", 0)
	end
	Spring.SetGameRulesParam("enable_EmpiricalDPS", enabled and 1 or 0)
end

function gadget:GameFrame(n)
	if not spIsCheatingEnabled() then
		return
	end
	if n%120 == 0 then
		if not creationUnitList[creationIndex] then
			creationIndex, creationUnitList = nil, nil
			gadgetHandler:RemoveGadgetCallIn('GameFrame', gadget)
			return
		end
		local INCREMENT = 128
		local unitDefID = creationUnitList[creationIndex]
		
		for i = 1, 25 do
			for j = 1, 25 do
				local x, z = 1000 + i*INCREMENT, 1000 + j*INCREMENT
				local y = Spring.GetGroundHeight(x,z)
				Spring.CreateUnit(unitDefID, x, y, z, 0, 0, false)
			end
		end
		Spring.Echo(UnitDefs[unitDefID].humanName, creationIndex)
		creationIndex = creationIndex + 1
	elseif n%120 == 100 then
		clear()
	end
end

function gadget:Initialize()
	if Spring.GetGameRulesParam("enable_EmpiricalDPS") == 1 then
		gadgetHandler:GotChatMsg("enablegadget Empirical DPS", 0)
	end

	gadgetHandler.actionHandler.AddChatAction(self,"bisect",bisect,"Bisect gadget disables.")
	gadgetHandler.actionHandler.AddChatAction(self,"emd",EmpiricalDps,"Toggle empirical DPS.")
	gadgetHandler.actionHandler.AddChatAction(self,"ecrush",EchoCrush,"Echos all crushabilities.")
	gadgetHandler.actionHandler.AddChatAction(self,"circle",circleGive,"Gives a bunch of units in a circle.")
	gadgetHandler.actionHandler.AddChatAction(self,"moveunit", MoveUnit, "Moves a unit.")
	gadgetHandler.actionHandler.AddChatAction(self,"destroyunit", DestroyUnit, "Destroys a unit.")
	gadgetHandler.actionHandler.AddChatAction(self,"rotateunit", RotateUnit, "Rotates a unit.")
	gadgetHandler.actionHandler.AddChatAction(self,"give",give,"Like give all but without all the crap.")
	gadgetHandler.actionHandler.AddChatAction(self,"pw",PlanetwarsGive,"Spawns all planetwars structures.")
	gadgetHandler.actionHandler.AddChatAction(self,"gk",gentleKill,"Gently kills everything.")
	gadgetHandler.actionHandler.AddChatAction(self,"nf",nanoFrame,"Sets nanoframe values.")
	gadgetHandler.actionHandler.AddChatAction(self,"rez",rezAll,"Resurrects wrecks for former owners.")
	gadgetHandler.actionHandler.AddChatAction(self,"damage",damage,"Damages everything.")
	gadgetHandler.actionHandler.AddChatAction(self,"color",ColorTest,"Spawns units for color test.")
	gadgetHandler.actionHandler.AddChatAction(self,"clear",clear,"Clears all units and wreckage.")
	gadgetHandler.actionHandler.AddChatAction(self,"uclear",uclear,"Clears all units.")
	gadgetHandler.actionHandler.AddChatAction(self,"serial",serial,"Gives all units in succession.")
	gadgetHandler.actionHandler.AddChatAction(self,"restart",restart,"Gives some commanders and clears everything else.")
	gadgetHandler.actionHandler.AddChatAction(self,"nocost",nocost,"Makes everything gadget-implemented free.")

	gadgetHandler:RemoveGadgetCallIn('GameFrame', gadget)
end

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
else -- UNSYNCED
-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------

local function bisect(cmd,line,words,player)
	if not spIsCheatingEnabled() then
		return
	end
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
   
