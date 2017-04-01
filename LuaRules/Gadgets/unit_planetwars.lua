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

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
local DEBUG_MODE = true

--local defenderTeam = nil
local defenderFaction = Spring.GetModOptions().defendingfaction

local spAreTeamsAllied		= Spring.AreTeamsAllied
local floor = math.floor

include "LuaRules/Configs/customcmds.h.lua"

local abandonCMD = {
	id      = CMD_ABANDON_PW,
	name    = "Evacuate",
	action  = "evacuate",
	cursor  = 'Repair',
	type    = CMDTYPE.ICON,
	tooltip = "Teleports building to safety for the duration of the battle",
}

local spGetGroundHeight = Spring.GetGroundHeight
local spAreTeamsAllied  = Spring.AreTeamsAllied

local mapWidth = Game.mapSizeX
local mapHeight = Game.mapSizeZ
local lava = (Game.waterDamage > 0)
local DEFENDER_ALLYTEAM = 1
local HQ_DEF_ID = UnitDefNames.pw_hq.id

local TELEPORT_CHARGE_NEEDED = 20*60 -- 20 minutes to charge without any modifiers.
local TELEPORT_BASE_CHARGE = 1 -- per second
local TELEPORT_FRAMES = 30*60 -- 1 minute

local allyTeamRole = {
	[0] = "attacker",
	[1] = "defender",
}

if DEBUG_MODE then
	TELEPORT_CHARGE_NEEDED = 60 * 0.5
	TELEPORT_FRAMES = 30*15
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local unitData = {}
local unitsByID = {}
local hqs = {}
local hqsDestroyed = {}
local stuffToReport = {data = {}, count = 0}
local haveEvacuable = false

local planetwarsBoxes = {}

local vector = Spring.Utilities.Vector

local BUILD_RESOLUTION = 16

GG.PlanetWars = {}
GG.PlanetWars.unitsByID = unitsByID
GG.PlanetWars.hqs = hqs

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local teleportCharge = 0
local teleportChargeRate = 1
local teleportingUnit, teleportFrame

local function SetTeleportCharge(newCharge)
	if newCharge > TELEPORT_CHARGE_NEEDED then
		newCharge = TELEPORT_CHARGE_NEEDED
	end
	if newCharge == teleportCharge then
		return
	end
	teleportCharge = newCharge
	Spring.SetGameRulesParam("pw_teleport_charge", teleportCharge)
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

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

local function addStuffToReport(stuff)
	stuffToReport.count = stuffToReport.count + 1
	stuffToReport.data[stuffToReport.count] = stuff
end

local function GetAllyTeamLeader(teamList)
	local bestRank, bestRankTeams
	for i = 1, #teamList do
		local teamID, leader, _, isAiTeam = Spring.GetTeamInfo(teamList[i])
		if leader and not isAiTeam then
			local customKeys = select(10, Spring.GetPlayerInfo(leader))
			local rank = customKeys.pwRank
			if rank then
				if (not bestRank) or (rank < bestRank) then
					bestRank = rank
					bestRankTeams = {teamID}
				elseif rank == bestRank then
					bestRankTeams[#bestRankTeams + 1] = teamID
				end
			end
		end
	end
	bestRankTeams = bestRankTeams or teamList
	return bestRankTeams[math.random(#bestRankTeams)]
end

local function GetRandomPosition(rectangle)
	local position = vector.Add(rectangle[1], vector.Add(vector.Mult(math.random(), rectangle[2]),vector.Mult(math.random(), rectangle[3])))
	return position[1], position[2]
end

local function SpawnStructure(info, teamID, boxData)
	if not (type(info) == "table") then
		return
	end
	
	teamID = info.owner or teamID
	
	Spring.Echo("Processing PW structure: "..info.unitname)
	local x, z = GetRandomPosition(boxData)
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
	
	local giveUp = 0
	while (Spring.TestBuildOrder(defID, x, 0 ,z, direction) == 0 or
		  (lava and Spring.GetGroundHeight(x,z) <= 0) or 
		  checkOverlapWithNoGoZone(x-sX,z-sZ,x+sX,z+sZ)) or
		  (startBoxID and not GG.CheckStartbox(startBoxID, x, z)) do
		x, z = GetRandomPosition(boxData)
		giveUp = giveUp + 1
		if giveUp > 80 then
			break
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
	if unitDef.customParams.canbeevacuated or DEBUG_MODE then
		Spring.InsertUnitCmdDesc(unitID, 500, abandonCMD)
		haveEvacuable = true
	end
	
	unitsByID[unitID] = {name = info.unitname, teamDamages = {}}
	Spring.SetUnitRulesParam(unitID, "can_share_to_gaia", 1)
end

local function SpawnStructuresInBox(boxData, teamID)
	teamID = teamID or Spring.GetGaiaTeamID()
	for _,info in pairs(unitData) do
		SpawnStructure(info, teamID, boxData)
	end
end

local function SpawnHQ(teamID, boxData)
	teamID = teamID or Spring.GetGaiaTeamID()
	
	local x, z = GetRandomPosition(boxData)
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
	
	local giveUp = 0
	while (Spring.TestBuildOrder(HQ_DEF_ID, x, 0 ,z, direction) == 0 or
		  (lava and Spring.GetGroundHeight(x,z) <= 0) or 
		  checkOverlapWithNoGoZone(x-sX,z-sZ,x+sX,z+sZ)) or
		  (startBoxID and not GG.CheckStartbox(startBoxID, x, z)) do
		x, z = GetRandomPosition(boxData)
		giveUp = giveUp + 1
		if giveUp > 80 then
			break
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
				local teamID = GetAllyTeamLeader(teamList)
				SpawnStructuresInBox(planetwarsBoxes.defender, teamID)
				return true
			end
		end
	end
	return false
end

local function TeleportOut(unitID)
	local _,_,_,x,y,z = Spring.GetUnitPosition(unitID, true)
	Spring.SpawnCEG("gate", x, y, z)
	Spring.DestroyUnit(unitID, false, true)
	teleportingUnit = nil
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- callins

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

function gadget:GameFrame(frame)
	if not haveEvacuable then
		return
	end
	if (frame%30 == 0) then
		SetTeleportCharge(teleportCharge + teleportChargeRate)
	end
	if teleportingUnit then
		if frame >= teleportFrame then
			TeleportOut(teleportingUnit)
		elseif frame % 5 == 0 then
			local _,_,_,x,y,z = Spring.GetUnitPosition(teleportingUnit, true)
			Spring.SpawnCEG("teleport_out", x, y, z)
		end
	end
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
	if unitID == teleportingUnit then
		teleportingUnit = nil
	end
end

function gadget:GamePreload()
	-- spawn PW planet structures
	if not SpawnInDefenderBox() then
		SpawnStructuresInBox(planetwarsBoxes.neutral)
	end
	
	-- spawn field command centers
	for i = 0, 1 do
		local teamList = Spring.GetTeamList(i) or {}
		local startBoxID = Spring.GetTeamRulesParam(teamList[1], "start_box_id")
		local teamID = GetAllyTeamLeader(teamList)
		SpawnHQ(teamID, planetwarsBoxes[allyTeamRole[i]])
	end
	
	SetTeleportCharge(teleportCharge + teleportChargeRate)
	Spring.SetGameRulesParam("pw_have_evacuable", haveEvacuable and 1 or 0)
end

function gadget:Initialize()
	if Spring.GetGameRulesParam("planetwars_structures") == 0 then
		gadgetHandler:RemoveGadget()
		return
	end

	local edgePadding = math.max(200, math.min(math.min(Game.mapSizeX, Game.mapSizeZ)/4 - 800, 800))
	planetwarsBoxes = GG.GetPlanetwarsBoxes(0.2, 0.25, 0.3, edgePadding)
	
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
			
			-- TODO: some buildings make teleport charge faster
			--local chargeModifier = unitDef.customParams
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
		
		if spawningAnything then
			Spring.SetGameRulesParam("planetwars_structures", 1)
		else
			Spring.SetGameRulesParam("planetwars_structures", 0)
			gadgetHandler:RemoveGadget()
			return
		end
	end
	
	-- get list of players that can attack PW structures
	--local players = Spring.GetPlayerList()
	--for i=1,#players do
	--	local player = players[i]
	--	local _,_,_,team,_,_,_,_,_,customkeys = Spring.GetPlayerInfo(player)
	--	if customkeys and tostring(customkeys.canattackpwstructures) == "1" then
	--		canAttackTeams[team] = true
	--	end
	--end
	
	Spring.SetGameRulesParam("pw_teleport_time", TELEPORT_FRAMES)
	Spring.SetGameRulesParam("pw_teleport_charge_needed", TELEPORT_CHARGE_NEEDED)
end

function gadget:AllowCommand_GetWantedCommand()	
	return {[CMD_ABANDON_PW] = true}
end

function gadget:AllowCommand_GetWantedUnitDefID()	
	return true
end

function gadget:CommandFallback(unitID, unitDefID, unitTeam, cmdID, cmdParams, cmdOptions)
	if not (unitsByID[unitID] and cmdID == CMD_ABANDON_PW) then
		return false -- command not used
	end
	
	if teleportingUnit then
		return true
	end
	
	if teleportCharge < TELEPORT_CHARGE_NEEDED then
		Spring.Echo("Charge needed", teleportCharge, TELEPORT_CHARGE_NEEDED)
		return true -- command used, do not remove
	end
	
	-- start teleporting
	teleportingUnit = unitID
	teleportFrame = Spring.GetGameFrame() + TELEPORT_FRAMES
	Spring.SetUnitRulesParam(teleportingUnit, "pw_teleport_frame", teleportFrame)
	SetTeleportCharge(0)
	Spring.SetUnitAlwaysVisible(unitID, true)
	return true -- command used, remove from queue
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function gadget:GameOver()	
	for i = 1, stuffToReport.count do
		Spring.SendCommands("wbynum 255 SPRINGIE:structurekilled,".. stuffToReport.data[i])
	end
	for i = 1, #hqsDestroyed do
		Spring.SendCommands("wbynum 255 SPRINGIE:hqkilled,".. hqsDestroyed[i])
	end
end