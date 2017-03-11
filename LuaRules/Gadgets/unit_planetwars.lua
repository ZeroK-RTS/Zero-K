--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
if not gadgetHandler:IsSyncedCode() then
	return
end
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
function gadget:GetInfo()
	return {
		name = "Planet Wars Structures",
		desc = "Spawns neutral structures for planetwars",
		author = "GoogleFrog",
		date = "27, April 2011",
		license = "Public Domain",
		layer = math.huge-10,
		enabled = true
	}
end

------------------------------------------------------------------------
------------------------------------------------------------------------
--local defenderTeam = nil
local defenderFaction = Spring.GetModOptions().defendingfaction

local spAreTeamsAllied		= Spring.AreTeamsAllied
local floor = math.floor

include "LuaRules/Configs/customcmds.h.lua"

local abandonCMD = {
    id      = CMD_ABANDON_PW,
    name    = "Abandon",
    action  = "abandon",
	cursor  = 'Repair',
    type    = CMDTYPE.ICON,
	tooltip = "Abandon this building (marks it as neutral)",
}

local spGetGroundHeight	= Spring.GetGroundHeight
local spAreTeamsAllied = Spring.AreTeamsAllied

local mapWidth = Game.mapSizeX
local mapHeight = Game.mapSizeZ
local lava = (Game.waterDamage > 0)
local TRANSLOCATION_MULT = 0.6		-- start box is dispaced towards center by (distance to center) * this to get PW spawning area
local DEFENDER_ALLYTEAM = 1
local HQ_DEF_ID = UnitDefNames.pw_hq.id

local unitData = {}
local unitsByID = {}
local hqs = {}
local hqsDestroyed = {}
local stuffToReport = {data = {}, count = 0}
local canAttackTeams = {}	-- teams that can attack PW structures

local BUILD_RESOLUTION = 16

GG.PlanetWars = {}
GG.PlanetWars.unitsByID = unitsByID
GG.PlanetWars.hqs = hqs

------------------------------------------------------------------------
------------------------------------------------------------------------

local noGoZones = {count = 0, data = {}}

local function initialiseNoGoZones()

	do
		local geoUnitDef = UnitDefNames["geo"]
		local features = Spring.GetAllFeatures()
		
		local sX = geoUnitDef.xsize*4
		local sZ = geoUnitDef.zsize*4
		local oddX = geoUnitDef.xsize % 4 == 2
		local oddZ = geoUnitDef.zsize % 4 == 2
		for i = 1, #features do
			local fID = features[i]
			if FeatureDefs[Spring.GetFeatureDefID(fID)].geoThermal then
				local x, _, z = Spring.GetFeaturePosition(fID)
				if (oddX) then
					x = (floor( x / BUILD_RESOLUTION) + 0.5) * BUILD_RESOLUTION
				else
					x = floor( x / BUILD_RESOLUTION + 0.5) * BUILD_RESOLUTION
				end
				if (oddZ) then
					z = (floor( z / BUILD_RESOLUTION) + 0.5) * BUILD_RESOLUTION
				else
					z = floor( z / BUILD_RESOLUTION + 0.5) * BUILD_RESOLUTION
				end
				
				noGoZones.count = noGoZones.count + 1
				noGoZones.data[noGoZones.count] = {zl = z-sZ, zu = z+sZ, xl = x-sX, xu = x-sZ}
			end
		end
	end

	do
		local mexUnitDef = UnitDefNames["cormex"]
		local metalSpots = GG.metalSpots
		
		if metalSpots then
			local sX = mexUnitDef.xsize*4
			local sZ = mexUnitDef.zsize*4
			for i = 1, #metalSpots do
				local x = metalSpots[i].x
				local z = metalSpots[i].z
				noGoZones.count = noGoZones.count + 1
				noGoZones.data[noGoZones.count] = {zl = z-sZ, zu = z+sZ, xl = x-sX, xu = x+sX}
			end
		end
	end
	--[[
	for i = 1, noGoZones.count do
		local d = noGoZones.data[i]
		--Spring.Echo("bla")
		Spring.MarkerAddPoint(d.xl,0,d.zl,"")
		Spring.MarkerAddPoint(d.xl,0,d.zu,"")
		Spring.MarkerAddPoint(d.xu,0,d.zl,"")
		Spring.MarkerAddPoint(d.xu,0,d.zu,"")
		Spring.MarkerAddLine(d.xl,0,d.zl,d.xu,0,d.zl)
		Spring.MarkerAddLine(d.xu,0,d.zl,d.xu,0,d.zu)
		Spring.MarkerAddLine(d.xu,0,d.zu,d.xl,0,d.zu)
		Spring.MarkerAddLine(d.xl,0,d.zu,d.xl,0,d.zl)
	end
	--]]
end

local function checkOverlapWithNoGoZone(xl,zl,xu,zu) -- intersection check does not include boundry points
	for i = 1, noGoZones.count do
		local d = noGoZones.data[i]
		if xl < d.xu and xu > d.xl and zl < d.zu and zu > d.zl then 
			return true
		end
	end
	return false
end

------------------------------------------------------------------------
------------------------------------------------------------------------

function gadget:UnitDamaged(unitID, unitDefID, unitTeam, damage, paralyzer, weaponDefID, attackerID, attackerDefID, attackerTeam)
	if unitsByID[unitID] and not paralyzer then
		unitsByID[unitID].totalDamage = (unitsByID[unitID].totalDamage or 0) + damage
		if attackerTeam then
			unitsByID[unitID].teamDamages[attackerTeam] = (unitsByID[unitID].teamDamages[attackerTeam] or 0) + damage
		else
			unitsByID[unitID].anonymous = (unitsByID[unitID].anonymous or 0) + damage
		end
	end
end

local function addStuffToReport(stuff)
	stuffToReport.count = stuffToReport.count + 1
	stuffToReport.data[stuffToReport.count] = stuff
end

function gadget:UnitDestroyed(unitID, unitDefID, unitTeam)
	if unitsByID[unitID] then
		local unit = unitsByID[unitID]
		local name = unit.name
		addStuffToReport(name .. ",total," .. (unit.totalDamage or 0))
		addStuffToReport(name .. ",anon," .. (unit.anonymous or 0))
		for teamID, damage in pairs(unit.teamDamages) do
			addStuffToReport(name .. "," .. teamID .. "," .. damage)
		end
		unitsByID[unitID] = nil
	end
	if hqs[unitID] then
		local allyTeam = select(6, Spring.GetTeamInfo(unitTeam))
		hqsDestroyed[#hqsDestroyed+1] = allyTeam
		hqs[unitID] = nil
	end
end

------------------------------------------------------------------------
------------------------------------------------------------------------

local function SpawnStructure(info, teamID, startBoxID, xBase, xRand, zBase, zRand)
	if not (type(info) == "table") then
		return
	end
	
	Spring.Echo("Processing PW structure: "..info.unitname)
	local giveUp = 0
	local x = xBase + math.random()*xRand
	local z = zBase + math.random()*zRand
	local direction = math.floor(math.random()*4)
	local defID = UnitDefNames[info.unitname] and UnitDefNames[info.unitname].id
	
	if not defID then
		Spring.Log(gadget:GetInfo().name, LOG.ERROR, 'Planetwars error: Missing structure def ' .. info.unitname)
		return
	end
	
	if info.isDestroyed == 1 then
		--do nothing
		return
	end
	
	local unitDef = UnitDefs[defID]
	local oddX = unitDef.xsize % 4 == 2
	local oddZ = unitDef.zsize % 4 == 2
	local sX = unitDef.xsize*4
	local sZ = unitDef.xsize*4
	
	if direction == 1 or direction == 3 then
		sX, sZ = sZ, sX
		oddX, oddZ = oddZ, oddX
	end
	
	while (Spring.TestBuildOrder(defID, x, 0 ,z, direction) == 0 or
		  (lava and Spring.GetGroundHeight(x,z) <= 0) or 
		  checkOverlapWithNoGoZone(x-sX,z-sZ,x+sX,z+sZ)) or
		  (startBoxID and not GG.CheckStartbox(startBoxID, x, z)) do
		x = xBase + math.random()*xRand
		z = zBase + math.random()*zRand
		giveUp = giveUp + 1
		if giveUp > 80 then
			if startBoxID then
				xBase = mapWidth*0.35
				xRand = mapWidth*0.3
				zBase = mapHeight*0.35
				zRand = mapHeight*0.3
				startBoxID = nil
				giveUp = 0 
			else
				break
			end
		end
	end
	
	if (unitDef.oddX) then
		x = (floor( x / BUILD_RESOLUTION) + 0.5) * BUILD_RESOLUTION
	else
		x = floor( x / BUILD_RESOLUTION + 0.5) * BUILD_RESOLUTION
	end
	if (unitDef.oddZ) then
		z = (floor( z / BUILD_RESOLUTION) + 0.5) * BUILD_RESOLUTION
	else
		z = floor( z / BUILD_RESOLUTION + 0.5) * BUILD_RESOLUTION
	end
	
	local unitID = Spring.CreateUnit(info.unitname, x, spGetGroundHeight(x,z), z, direction, teamID, false, false)
	Spring.SetUnitNeutral(unitID,true)
	Spring.InsertUnitCmdDesc(unitID, 500, abandonCMD)
	unitsByID[unitID] = {name = info.unitname, teamDamages = {}}
	Spring.SetUnitRulesParam(unitID, "can_share_to_gaia", 1)
end

local function SpawnStructuresInBox(left, top, right, bottom, team, startBoxID)
	local teamID = team or Spring.GetGaiaTeamID()
	local xBase = mapWidth*left
	local xRand = mapWidth*(right-left)
	local zBase = mapHeight*top
	local zRand = mapHeight*(bottom-top)
	for _,info in pairs(unitData) do
		SpawnStructure(info, teamID, startBoxID, xBase, xRand, zBase, zRand)
	end
end

local function SpawnHQ(teamID, startBoxID)
	teamID = teamID or Spring.GetGaiaTeamID()
	local xBase = mapWidth*0.05
	local xRand = mapWidth*0.9
	local zBase = mapHeight*0.05
	local zRand = mapHeight*0.9
	
	local giveUp = 0
	
	local x = xBase + math.random()*xRand
	local z = zBase + math.random()*zRand
	local direction = math.floor(math.random()*4)
	
	local unitDef = UnitDefs[HQ_DEF_ID]
	local oddX = unitDef.xsize % 4 == 2
	local oddZ = unitDef.zsize % 4 == 2
	local sX = unitDef.xsize*4
	local sZ = unitDef.xsize*4
	
	if direction == 1 or direction == 3 then
		sX, sZ = sZ, sX
		oddX, oddZ = oddZ, oddX
	end
	
	while (Spring.TestBuildOrder(HQ_DEF_ID, x, 0 ,z, direction) == 0 or
		  (lava and Spring.GetGroundHeight(x,z) <= 0) or 
		  checkOverlapWithNoGoZone(x-sX,z-sZ,x+sX,z+sZ)) or
		  (startBoxID and not GG.CheckStartbox(startBoxID, x, z)) do
		x = xBase + math.random()*xRand
		z = zBase + math.random()*zRand
		giveUp = giveUp + 1
		if giveUp > 80 then
			if startBoxID then
				xBase = mapWidth*0.35
				xRand = mapWidth*0.3
				zBase = mapHeight*0.35
				zRand = mapHeight*0.3
				startBoxID = nil
				giveUp = 0 
			else
				break
			end
		end
	end
	
	if (unitDef.oddX) then
		x = (floor( x / BUILD_RESOLUTION) + 0.5) * BUILD_RESOLUTION
	else
		x = floor( x / BUILD_RESOLUTION + 0.5) * BUILD_RESOLUTION
	end
	if (unitDef.oddZ) then
		z = (floor( z / BUILD_RESOLUTION) + 0.5) * BUILD_RESOLUTION
	else
		z = floor( z / BUILD_RESOLUTION + 0.5) * BUILD_RESOLUTION
	end
	
	local unitID = Spring.CreateUnit(HQ_DEF_ID, x, spGetGroundHeight(x,z), z, direction, teamID)
	hqs[unitID] = true
	Spring.SetUnitNeutral(unitID,true)
end

local function SpawnInDefenderBox()
	if defenderFaction then
		local teamList = Spring.GetTeamList(DEFENDER_ALLYTEAM) or {}
		if teamList[1] then
			local startBoxID = Spring.GetTeamRulesParam(teamList[1], "start_box_id")
			if startBoxID then
				local teamID = teamList[math.random(#teamList)]
				SpawnStructuresInBox(0.05, 0.05, 0.95, 0.95, teamID, startBoxID)
				return true
			end
		end
	end
	return false
end

function gadget:GamePreload()

	-- spawn PW planet structures
	if not SpawnInDefenderBox() then
		SpawnStructuresInBox(0.35,0.35,0.65,0.65)
	end
	
	-- spawn field command centers
	for i = 0, 1 do
		local teamList = Spring.GetTeamList(i) or {}
		local startBoxID = Spring.GetTeamRulesParam(teamList[1], "start_box_id")
		local teamID = teamList[math.random(#teamList)]
		SpawnHQ(teamID, startBoxID)
	end
end

function gadget:Initialize()
	if Spring.GetGameRulesParam("planetwars_structures") == 0 then
		gadgetHandler:RemoveGadget()
		return
	end

	initialiseNoGoZones()
	if Spring.GetGameFrame() > 0 then	--game has started
		local units = Spring.GetAllUnits()
		for i=1,#units do
			local unitID = units[i]
			local unitDefID = Spring.GetUnitDefID(unitID)
			local unitDef = UnitDefs[unitDefID]
			if unitDefID == HQ_DEF_ID then
				hqs[unitID] = true
			elseif unitDef.name:find("pw_") then	-- is PW
				unitsByID[unitID] = {name = unitDef.name, teamDamages = {}}
			end
		end
	else
		local modOptions = (Spring and Spring.GetModOptions and Spring.GetModOptions()) or {}
		local pwDataRaw = "ew0KICBzMTYgPSB7DQogICAgdW5pdG5hbWUgPSAicHdfd29ybWhvbGUiLA0KICAgIG5hbWUgPSAiIFdvcm1ob2xlIEdlbmVyYXRvciAodW5vd25lZCkiLA0KICAgIGRlc2NyaXB0aW9uID0gIkxpbmtzIHBsYW5ldCB0byBuZWlnaGJvdXJzIC0gc3ByZWFkcyBpbmZsdWVuY2UgcGVyIHR1cm47IGhhcmRlbmVkIGFnYWluc3QgYm9tYmVyIGF0dGFjayINCiAgfSwNCiAgczE3ID0gew0KICAgIHVuaXRuYW1lID0gInB3X3dvcm1ob2xlIiwNCiAgICBuYW1lID0gIiBXb3JtaG9sZSBHZW5lcmF0b3IgKHVub3duZWQpIiwNCiAgICBkZXNjcmlwdGlvbiA9ICJMaW5rcyBwbGFuZXQgdG8gbmVpZ2hib3VycyAtIHNwcmVhZHMgaW5mbHVlbmNlIHBlciB0dXJuOyBoYXJkZW5lZCBhZ2FpbnN0IGJvbWJlciBhdHRhY2siDQogIH0sDQogIHMxOCA9IHsNCiAgICB1bml0bmFtZSA9ICJwd193b3JtaG9sZSIsDQogICAgbmFtZSA9ICIgV29ybWhvbGUgR2VuZXJhdG9yICh1bm93bmVkKSIsDQogICAgZGVzY3JpcHRpb24gPSAiTGlua3MgcGxhbmV0IHRvIG5laWdoYm91cnMgLSBzcHJlYWRzIGluZmx1ZW5jZSBwZXIgdHVybjsgaGFyZGVuZWQgYWdhaW5zdCBib21iZXIgYXR0YWNrIg0KICB9LA0KICBzMTkgPSB7DQogICAgdW5pdG5hbWUgPSAicHdfd29ybWhvbGUiLA0KICAgIG5hbWUgPSAiIFdvcm1ob2xlIEdlbmVyYXRvciAodW5vd25lZCkiLA0KICAgIGRlc2NyaXB0aW9uID0gIkxpbmtzIHBsYW5ldCB0byBuZWlnaGJvdXJzIC0gc3ByZWFkcyBpbmZsdWVuY2UgcGVyIHR1cm47IGhhcmRlbmVkIGFnYWluc3QgYm9tYmVyIGF0dGFjayINCiAgfSwNCn0=" --modOptions.planetwarsstructures
		local pwDataFunc, err, success
		if not (pwDataRaw and type(pwDataRaw) == 'string') then
			err = "Planetwars data entry in modoption is empty or in invalid format"
			unitData = {}
		else
			pwDataRaw = string.gsub(pwDataRaw, '_', '=')
			pwDataRaw = Spring.Utilities.Base64Decode(pwDataRaw)
			pwDataFunc, err = loadstring("return "..pwDataRaw)
			if pwDataFunc then
				success, unitData = pcall(pwDataFunc)
				if not success then	-- execute Borat
					err = unitData
					unitData = {}
				end
			end
		end
		if err then 
			Spring.Log(gadget:GetInfo().name, LOG.WARNING, 'Planetwars warning: ' .. err)
		end

		if not unitData then 
			unitData = {} 
		end
		
		--[[
		for _,teamID in pairs(Spring.GetTeamList()) do
			local keys = select(7, Spring.GetTeamInfo(teamID))
			if keys and keys.defender then
				defenderTeam = teamID
				break
			end
		end
		]]
		
		-- spawning code
		--[[
		local spawningAnything = false
		for i,v in pairs(unitData) do
			if (v.isDestroyed~=1) then 
				spawningAnything = true
				break
			end
		end
		]]--
		spawningAnything = pwDataRaw
		
		if spawningAnything then
			Spring.SetGameRulesParam("planetwars_structures", 1)
		else
			Spring.SetGameRulesParam("planetwars_structures", 0)
			gadgetHandler:RemoveGadget()
			return
		end
	end
	
	-- get list of players that can attack PW structures
	local players = Spring.GetPlayerList()
	for i=1,#players do
		local player = players[i]
		local _,_,_,team,_,_,_,_,_,customkeys = Spring.GetPlayerInfo(player)
		if customkeys and tostring(customkeys.canattackpwstructures) == "1" then
			canAttackTeams[team] = true
		end
	end
	
end

function gadget:AllowCommand_GetWantedCommand()	
	return {[CMD_ABANDON_PW] = true}
end

function gadget:AllowCommand_GetWantedUnitDefID()	
	return true
end

function gadget:AllowCommand(unitID, unitDefID, unitTeam, cmdID, cmdParams, cmdOptions)
	if unitsByID[unitID] and cmdID == CMD_ABANDON_PW then
		local gaiaTeam = Spring.GetGaiaTeamID()
		GG.allowTransfer = true
		Spring.TransferUnit(unitID, gaiaTeam, true)
		GG.allowTransfer = false
		Spring.SetUnitNeutral(unitID, true)
		return false
	elseif cmdID == CMD.ATTACK and #cmdParams == 1 then
		local unitID = cmdParams[1]
		if unitsByID[unitID] and (not canAttackTeams[unitTeam]) then
			local unitName = UnitDefs[unitDefID].humanName
			--Spring.SendMessageToTeam(unitTeam, unitName .. ": Cannot attack that PW structure")
			return false
		end
	end
	return true
end

function gadget:UnitPreDamaged_GetWantedWeaponDef()
	return WeaponDefs
end

function gadget:UnitPreDamaged(unitID, unitDefID, unitTeam, damage, paralyzer, weaponID, attackerID, attackerDefID, attackerTeam)
	if attackerTeam and ((unitsByID[unitID] and (not canAttackTeams[attackerTeam])) or (spAreTeamsAllied(unitTeam, attackerTeam) and hqs[unitID])) then
		return 0
	end
	return damage
end

------------------------------------------------------------------------
------------------------------------------------------------------------

function gadget:GameOver()	
	for i =1, stuffToReport.count do
		Spring.SendCommands("wbynum 255 SPRINGIE:structurekilled,".. stuffToReport.data[i])
	end
	for i=1, #hqsDestroyed do
		Spring.SendCommands("wbynum 255 SPRINGIE:hqkilled,".. hqsDestroyed[i])
	end
end