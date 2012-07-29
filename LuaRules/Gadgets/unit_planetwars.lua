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
if (not gadgetHandler:IsSyncedCode()) then
	return
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
				if (geoDefInfo.oddX) then
					x = (floor( x / BUILD_RESOLUTION) + 0.5) * BUILD_RESOLUTION
				else
					x = floor( x / BUILD_RESOLUTION + 0.5) * BUILD_RESOLUTION
				end
				if (geoDefInfo.oddZ) then
					z = (floor( z / BUILD_RESOLUTION) + 0.5) * BUILD_RESOLUTION
				else
					z = floor( z / BUILD_RESOLUTION + 0.5) * BUILD_RESOLUTION
				end
				
				noGoZones.count = noGoZones.count + 1
				noGoZones.data[noGoZones.count] = {zl = z-sZ, zu = z+sZ, xl = x-sX, xu = x-xZ}
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

function gadget:UnitDamaged(unitID, unitDefID, unitTeam, damage, paralyzer, weaponID, attackerID, attackerDefID, attackerTeam)
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

local function normaliseBoxes(box)
	box.left = box.left/mapWidth
	box.top = box.top/mapHeight
	box.right = box.right/mapWidth
	box.bottom = box.bottom/mapHeight
end

local function TranslocateBoxes(box)
	local midX, midY = (box.left + box.right)/2, (box.top + box.bottom)/2
	local x1 = box.left + TRANSLOCATION_MULT*(0.5 - midX)
	local y1 = box.top + TRANSLOCATION_MULT*(0.5 - midY)
	local x2 = box.right + TRANSLOCATION_MULT*(0.5 - midX)
	local y2 = box.bottom + TRANSLOCATION_MULT*(0.5 - midY)
	return x1, y1, x2, y2
end

local function spawnStructures(left, top, right, bottom, team)
	local teamID = team or Spring.GetGaiaTeamID()
	local xBase = mapWidth*left
	local xRand = mapWidth*(right-left)
	local zBase = mapHeight*top
	local zRand = mapHeight*(bottom-top)
	
	for _,info in pairs(unitData) do
		if type(info) == "table" then
			Spring.Echo("Processing PW structure: "..info.unitname)
			local giveUp = 0
			local x = xBase + math.random()*xRand
			local z = zBase + math.random()*zRand
			local direction = math.floor(math.random()*4)
			local defID = UnitDefNames[info.unitname] and UnitDefNames[info.unitname].id
			
			if not defID then
				Spring.Log(gadget:GetInfo().name, LOG.ERROR, 'Planetwars error: Missing structure def ' .. info.unitname)
			elseif info.isDestroyed == 1 then
				--do nothing
			else
				local unitDef = UnitDefs[defID]
				local oddX = unitDef.xsize % 4 == 2
				local oddZ = unitDef.zsize % 4 == 2
				local sX = unitDef.xsize*4
				local sZ = unitDef.xsize*4
				
				if direction == 1 or direction == 3 then
					sX, sZ = sZ, sX
					oddX, oddZ = oddZ, oddX
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
				while (Spring.TestBuildOrder(defID, x, 0 ,z, direction) == 0 or
					  (lava and Spring.GetGroundHeight(x,z) <= 0) or 
					  checkOverlapWithNoGoZone(x-sX,z-sZ,x+sX,z+sZ)) 
					  and giveUp < 50 do
					x = xBase + math.random()*xRand
					z = zBase + math.random()*zRand
					giveUp = giveUp + 1
				end
				
				local unitID = Spring.CreateUnit(info.unitname, x, spGetGroundHeight(x,z), z, direction, teamID)
				Spring.SetUnitNeutral(unitID,true)
				Spring.InsertUnitCmdDesc(unitID, 500, abandonCMD)
				unitsByID[unitID] = {name = info.unitname, teamDamages = {}}
			end
		end
	end
end


local function SpawnHQ(left, top, right, bottom, team)
	local teamID = team or Spring.GetGaiaTeamID()
	local xBase = mapWidth*left
	local xRand = mapWidth*(right-left)
	local zBase = mapHeight*top
	local zRand = mapHeight*(bottom-top)
	
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
	
	while (Spring.TestBuildOrder(HQ_DEF_ID, x, 0 ,z, direction) == 0 or
		  (lava and Spring.GetGroundHeight(x,z) <= 0) or 
		  checkOverlapWithNoGoZone(x-sX,z-sZ,x+sX,z+sZ)) 
		  and giveUp < 25 do
		x = xBase + math.random()*xRand
		z = zBase + math.random()*zRand
		giveUp = giveUp + 1
	end
	
	local unitID = Spring.CreateUnit(HQ_DEF_ID, x, spGetGroundHeight(x,z), z, direction, teamID)
	hqs[unitID] = true
	Spring.SetUnitNeutral(unitID,true)
end

function gadget:GamePreload()
	local box = {[0] = {}, [1] = {}}
	box[0].left, box[0].top, box[0].right, box[0].bottom  = Spring.GetAllyTeamStartBox(0)
	box[1].left, box[1].top, box[1].right, box[1].bottom = Spring.GetAllyTeamStartBox(1)
	
	if not (box[0].left) then
		box[0].left, box[0].top, box[0].right, box[0].bottom = 0, 0, mapWidth, mapHeight
	end
	if not (box[1].left) then
		box[1].left, box[1].top, box[1].right, box[1].bottom = 0, 0, mapWidth, mapHeight
	end
	
	normaliseBoxes(box[0])
	normaliseBoxes(box[1])

	-- spawn PW planet structures
	if defenderFaction then
		local teams = Spring.GetTeamList(DEFENDER_ALLYTEAM)
		local team = teams[math.random(#teams)]
		local x1, y1, x2, y2 = TranslocateBoxes(box[DEFENDER_ALLYTEAM])
		spawnStructures(x1, y1, x2, y2, team)
	elseif box[0].right - box[0].left >= 0.9 and box[1].right - box[1].left >= 0.9 then -- north vs south
		spawnStructures(0.1,0.44,0.9,0.56)
	elseif box[0].bottom - box[0].top >= 0.9 and box[1].bottom - box[1].top >= 0.9 then -- east vs west
		spawnStructures(0.44,0.1,0.56,0.9)
	else -- random idk boxes
		spawnStructures(0.35,0.35,0.65,0.65)
	end
	
	-- spawn field command centers
	for i=0,(defenderFaction and 1 or 0) do
		local x1, y1, x2, y2 = TranslocateBoxes(box[i])
		local teams = Spring.GetTeamList(i)
		local team = teams[math.random(#teams)]
		SpawnHQ(x1, y1, x2, y2, team)
	end
end

function gadget:Initialize()
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
		local pwDataRaw = modOptions.planetwarsstructures
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
		
		if not spawningAnything then
			gadgetHandler:RemoveGadget()
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

function gadget:AllowCommand(unitID, unitDefID, unitTeam, cmdID, cmdParams, cmdOptions)
	if unitsByID[unitID] and cmdID == CMD_ABANDON_PW then
		local gaiaTeam = Spring.GetGaiaTeamID()
		Spring.TransferUnit(unitID, gaiaTeam, true)
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