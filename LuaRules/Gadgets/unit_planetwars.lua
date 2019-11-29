--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
if (not gadgetHandler:IsSyncedCode()) or VFS.FileExists("mission.lua") then
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
local DEBUG_MODE = false

--local defenderTeam = nil
local defenderFaction = Spring.GetModOptions().defendingfaction ~= "Mercenary"

local floor = math.floor

include "LuaRules/Configs/customcmds.h.lua"

local evacuateCmdDesc = {
	id      = CMD_ABANDON_PW,
	name    = "Evacuate",
	action  = "evacuate",
	cursor  = 'Repair',
	type    = CMDTYPE.ICON,
	tooltip = "Evacuates the structure from the battle via wormhole teleportation.",
}

local spGetGroundHeight = Spring.GetGroundHeight
local spSetHeightMap    = Spring.SetHeightMap
local spAreTeamsAllied  = Spring.AreTeamsAllied

local mapWidth = Game.mapSizeX
local mapHeight = Game.mapSizeZ
local lava = (Game.waterDamage > 0)
local INLOS_ACCESS = {inlos = true}
local DEFENDER_ALLYTEAM = 1

local gaiaTeamID = Spring.GetGaiaTeamID()

local TELEPORT_CHARGE_NEEDED = 10*60 -- seconds
local TELEPORT_FRAMES = 30*60 -- 1 minute
local TELEPORT_CHARGE_PERIOD = 30 -- Frames
local TELEPORT_CHARGE_RATE = TELEPORT_CHARGE_PERIOD/30 -- per update
local BATTLE_TIME_LIMIT = 30*60*60*2 -- Defenders win after 2 hours
local teleportChargeNeededMult = false

local STRUCTURE_SPACING = 192

local allyTeamRole = {
	[0] = "attacker",
	[1] = "defender",
}

local hqDefIDs = {
	[0] = UnitDefNames["pw_hq_attacker"].id,
	[1] = UnitDefNames["pw_hq_defender"].id,
}

if DEBUG_MODE then
	TELEPORT_CHARGE_NEEDED = 10
	TELEPORT_FRAMES = 30*5
end

local wormholeDefs = {}
for i = 1, #UnitDefs do
	local ud = UnitDefs[i]
	if ud.customParams.evacuation_speed then
		wormholeDefs[i] = 1/tonumber(ud.customParams.evacuation_speed)
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local structureSpawnData = {}
local unitsByID = {}
local hqs = {}
local hqsDestroyed = {}
local destroyedStructures = {data = {}, count = 0}
local evacuateStructureString = false
local haveEvacuable = false

local flattenAreas = {}

local planetwarsStructureCount = 0 -- For GameRulesParams structure list
local destroyedStructureCount = 0
local evacStructureCount = 0

local wormholeList = {}
local planetwarsBoxes = {}

local vector = Spring.Utilities.Vector

local BUILD_RESOLUTION = 16

local EVAC_STATE = {
	ACTIVE = 1,
	NO_WORMHOLE = 2,
	NOTHING_TO_EVAC = 3,
	WORMHOLE_DESTROYED = 4,
}

GG.PlanetWars = {}
GG.PlanetWars.unitsByID = unitsByID
GG.PlanetWars.hqs = hqs

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local function GeneratePlayerNameToTeamIDMap()
	local map = {}
	
	local playerList = Spring.GetPlayerList()
	for i = 1, #playerList do
		local name, active, spectator, teamID = Spring.GetPlayerInfo(playerList[i], false)
		if name and active and (not spectator) then
			map[name] = teamID
		end
	end
	
	return map
end

local playerNameToTeamID = GeneratePlayerNameToTeamIDMap()

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local function GetUnitCanEvac(unitDef)
	return (defenderFaction and unitDef.customParams.canbeevacuated) or DEBUG_MODE
end

local function RemoveEvacCommands()
	for unitID, data in pairs(unitsByID) do
		local cmdDesc = Spring.FindUnitCmdDesc(unitID, CMD_ABANDON_PW)
		if cmdDesc then
			Spring.RemoveUnitCmdDesc(unitID, cmdDesc)
		end
	end
end

local function UpdateEvacState()
	if not haveEvacuable then
		return
	end
	for unitID, data in pairs(unitsByID) do
		if data.canEvac then
			return
		end
	end
	
	haveEvacuable = false
	RemoveEvacCommands()
	
	Spring.SetGameRulesParam("pw_evacuable_state", EVAC_STATE.NOTHING_TO_EVAC)
end

local function MakeDefendersWinBattle()
	GG.CauseVictory(DEFENDER_ALLYTEAM)
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local teleportCharge = -1
local teleportingUnit, teleportFrame
local removingTeleportingUnit = false -- set to true prior to DestroyUnit call when teleporting out, then false immediately after

local function SetTeleportCharge(newCharge)
	if teleportChargeNeededMult and newCharge > TELEPORT_CHARGE_NEEDED*teleportChargeNeededMult then
		newCharge = TELEPORT_CHARGE_NEEDED*teleportChargeNeededMult
	end
	if newCharge == teleportCharge then
		return
	end
	teleportCharge = newCharge
	Spring.SetGameRulesParam("pw_teleport_charge", teleportCharge)
end

local function CheckSetWormhole(unitID)
	local unitDefID = Spring.GetUnitDefID(unitID)
	local chargeMult = wormholeDefs[unitDefID]
	if (not chargeMult) or (Spring.GetUnitRulesParam(unitID, "planetwarsDisable") == 1) then
		return
	end
	if (not teleportChargeNeededMult) or chargeMult < teleportChargeNeededMult then
		if wormholeList[1] then
			wormholeList[#wormholeList + 1] = wormholeList[1]
		end
		wormholeList[1] = unitID
		teleportChargeNeededMult = chargeMult
		Spring.SetGameRulesParam("pw_teleport_charge_needed", TELEPORT_CHARGE_NEEDED*teleportChargeNeededMult)
	else
		wormholeList[#wormholeList + 1] = unitID
	end
end

local function CancelTeleport()
	if teleportingUnit and Spring.ValidUnitID(teleportingUnit) then
		Spring.SetUnitRulesParam(teleportingUnit, "pw_teleport_frame", nil)
	end
	teleportingUnit = nil
	Spring.SetGameRulesParam("pw_teleport_frame", nil)
	Spring.SetGameRulesParam("pw_teleport_unitname", nil)
end

local function CheckRemoveWormhole(unitID, unitDefID)
	if not wormholeDefs[unitDefID] then
		return
	end
	
	if wormholeList[1] ~= unitID then
		for i = 2, #wormholeList do
			if unitID == wormholeList[i] then
				wormholeList[i] = wormholeList[#wormholeList]
				wormholeList[#wormholeList] = nil
				return
			end
		end
		Spring.Echo("PlanetWars error: wormhole not found", i)
		return
	end
	
	if teleportingUnit then
		CancelTeleport()
	end
	
	if #wormholeList == 1 then
		RemoveEvacCommands()
		wormholeList[1] = nil
		Spring.SetGameRulesParam("pw_evacuable_state", removingTeleportingUnit and EVAC_STATE.NO_WORMHOLE or EVAC_STATE.WORMHOLE_DESTROYED)
		return
	end
	
	local survivingWormholes = Spring.Utilities.CopyTable(wormholeList)
	teleportChargeNeededMult = false
	wormholeList = {}
	
	for i = 2, #survivingWormholes do
		CheckSetWormhole(survivingWormholes[i])
	end
end

local function TeleportChargeTick()
	if not (wormholeList[1] and teleportChargeNeededMult) then
		return
	end
	local stunnedOrInbuild = Spring.GetUnitIsStunned(wormholeList[1])
	local allyTeamID = Spring.GetUnitAllyTeam(wormholeList[1])
	local chargeFactor = ((stunnedOrInbuild or (allyTeamID ~= DEFENDER_ALLYTEAM)) and 0) or Spring.GetUnitRulesParam(wormholeList[1], "totalReloadSpeedChange") or 1
	
	if teleportingUnit then
		if chargeFactor == 0 then
			CancelTeleport()
		elseif chargeFactor ~= 1 then
			teleportFrame = teleportFrame + (1 - chargeFactor)*TELEPORT_CHARGE_PERIOD
			if teleportingUnit and Spring.ValidUnitID(teleportingUnit) then
				Spring.SetUnitRulesParam(teleportingUnit, "pw_teleport_frame", teleportFrame)
			end
			Spring.SetGameRulesParam("pw_teleport_frame", teleportFrame)
		end
	end
	SetTeleportCharge(teleportCharge + TELEPORT_CHARGE_RATE * chargeFactor)
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local noGoZones = {count = 0, data = {}}

local function AddNoGoZone(x, z, size)
	noGoZones.count = noGoZones.count + 1
	noGoZones.data[noGoZones.count] = {zl = z - size, zu = z + size, xl = x - size, xu = x + size}
end

local function initialiseNoGoZones()

	do
		local geoUnitDef = UnitDefNames["energygeo"]
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
		local mexUnitDef = UnitDefNames["staticmex"]
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

local function AddDestroyedStructureReport(stuff)
	destroyedStructures.count = destroyedStructures.count + 1
	destroyedStructures.data[destroyedStructures.count] = stuff
end

local function AddEvacuatedStructure(name, unit)
	evacStructureCount = evacStructureCount + 1
	Spring.SetGameRulesParam("pw_structureEvacuated_" .. evacStructureCount, name)
	
	if evacuateStructureString then
		evacuateStructureString = evacuateStructureString .. " " .. name
	else
		evacuateStructureString = name
	end
end

local function AddDestroyedStructure(name, unit)
	destroyedStructureCount = destroyedStructureCount + 1
	Spring.SetGameRulesParam("pw_structureDestroyed_" .. destroyedStructureCount, name)
	
	AddDestroyedStructureReport(name .. ",total," .. (unit.totalDamage or 0))
	AddDestroyedStructureReport(name .. ",anon," .. (unit.anonymous or 0))
	for teamID, damage in pairs(unit.teamDamages) do
		AddDestroyedStructureReport(name .. "," .. teamID .. "," .. damage)
	end
end

local function GetAllyTeamLeader(teamList)
	local bestRank, bestRankTeams
	for i = 1, #teamList do
		local teamID, leader, _, isAiTeam = Spring.GetTeamInfo(teamList[i], false)
		if leader and not isAiTeam then
			local customKeys = select(11, Spring.GetPlayerInfo(leader)) or {}
			local rank = customKeys.pwrank
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

local function FlattenFunc(left, top, right, bottom, height)
	-- top and bottom
	for x = left + 8, right - 8, 8 do
		spSetHeightMap(x, top, height, 0.5)
		spSetHeightMap(x, bottom, height, 0.5)
	end
	
	-- left and right
	for z = top + 8, bottom - 8, 8 do
		spSetHeightMap(left, z, height, 0.5)
		spSetHeightMap(right, z, height, 0.5)
	end
	
	-- corners
	spSetHeightMap(left, top, height, 0.5)
	spSetHeightMap(left, bottom, height, 0.5)
	spSetHeightMap(right, top, height, 0.5)
	spSetHeightMap(right, bottom, height, 0.5)
end

local function FlattenRectangle(left, top, right, bottom, height)
	Spring.LevelHeightMap(left + 8, top + 8, right - 8, bottom - 8, height)
	Spring.SetHeightMapFunc(FlattenFunc, left, top, right, bottom, height)
end

local function SpawnStructure(info, teamID, boxData)
	if not (type(info) == "table") then
		return
	end
	
	if info.isDestroyed == 1 then
		--do nothing
		return
	end
	
	teamID = (info.owner and playerNameToTeamID[info.owner]) or teamID
	Spring.Echo("Processing PW structure: "..info.unitname)
	
	local defID = UnitDefNames[info.unitname] and UnitDefNames[info.unitname].id
	if not defID then
		Spring.Log(gadget:GetInfo().name, LOG.ERROR, 'Planetwars error: Missing structure def ' .. info.unitname)
		return
	end
	
	local unitDef = UnitDefs[defID]
	if info.evacuated then
		planetwarsStructureCount = planetwarsStructureCount + 1
		Spring.SetGameRulesParam("pw_structureList_" .. planetwarsStructureCount, unitDef.name)
		return
	end
	
	local x, z = GetRandomPosition(boxData)
	local direction = math.floor(math.random()*4)
	
	local oddX = unitDef.xsize % 4 == 2
	local oddZ = unitDef.zsize % 4 == 2
	local sX = unitDef.xsize*4
	local sZ = unitDef.zsize*4
	
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
	
	local y = spGetGroundHeight(x,z)
	if (y > 0 or (not unitDef.floatOnWater)) and flattenAreas then
		flattenAreas[#flattenAreas + 1] = {x-sX, z-sZ, x+sX, z+sZ, y}
	end
	
	if info.isInactive then
		GG.applyPlanetwarsDisable = true
	end
	local unitID = Spring.CreateUnit(info.unitname, x, y, z, direction, teamID, false, false)
	if info.isInactive then
		GG.applyPlanetwarsDisable = false
	end
	CheckSetWormhole(unitID)
	
	AddNoGoZone(x, z, math.max(sX, sZ) + STRUCTURE_SPACING)
	
	planetwarsStructureCount = planetwarsStructureCount + 1
	Spring.SetGameRulesParam("pw_structureList_" .. planetwarsStructureCount, unitDef.name)
	
	if unitDef.customParams.invincible or teamID == gaiaTeamID then
		-- Makes structures not auto-attacked.
		Spring.SetUnitNeutral(unitID,true)
		Spring.SetUnitRulesParam(unitID, "avoidRightClickAttack", 1)
	end
	
	if GetUnitCanEvac(unitDef) then
		Spring.InsertUnitCmdDesc(unitID, 500, evacuateCmdDesc)
		haveEvacuable = true
	end
	
	unitsByID[unitID] = {name = info.unitname, teamDamages = {}, canEvac = GetUnitCanEvac(unitDef)}
	Spring.SetUnitRulesParam(unitID, "can_share_to_gaia", 1)
end

local function SpawnStructuresInBox(boxData, teamID)
	teamID = teamID or gaiaTeamID
	for _,info in pairs(structureSpawnData) do
		SpawnStructure(info, teamID, boxData)
	end
end

local function SpawnHQ(teamID, boxData, hqDefID)
	teamID = teamID or gaiaTeamID
	
	local x, z = GetRandomPosition(boxData)
	local direction = math.floor(math.random()*4)
	
	local unitDef = UnitDefs[hqDefID]
	local oddX = unitDef.xsize % 4 == 2
	local oddZ = unitDef.zsize % 4 == 2
	local sX = unitDef.xsize*4
	local sZ = unitDef.xsize*4
	
	if direction == 1 or direction == 3 then
		sX, sZ = sZ, sX
		oddX, oddZ = oddZ, oddX
	end
	
	local giveUp = 0
	while (Spring.TestBuildOrder(hqDefID, x, 0 ,z, direction) == 0 or
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
	
	local y = spGetGroundHeight(x,z)
	if (y > 0 or (not unitDef.floatOnWater)) and flattenAreas then
		flattenAreas[#flattenAreas + 1] = {x-sX, z-sZ, x+sX, z+sZ, y}
	end
	
	planetwarsStructureCount = planetwarsStructureCount + 1
	Spring.SetGameRulesParam("pw_structureList_" .. planetwarsStructureCount, unitDef.name)
	
	AddNoGoZone(x, z, math.max(sX, sZ) + STRUCTURE_SPACING)
	
	local unitID = Spring.CreateUnit(hqDefID, x, y, z, direction, teamID)
	hqs[unitID] = true
	
	--Spring.SetUnitNeutral(unitID,true) -- Makes structures not auto-attacked.
end

local function SpawnInDefenderBox()
	if defenderFaction then
		local teamList = Spring.GetTeamList(DEFENDER_ALLYTEAM) or {}
		if teamList and teamList[1] then
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
	Spring.PlaySoundFile("sounds/misc/teleport_alt.wav", 20, x, y, z)
	removingTeleportingUnit = true
	Spring.DestroyUnit(unitID, false, true)
	removingTeleportingUnit = false
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
	if flattenAreas then
		for i = 1, #flattenAreas do
			local rec = flattenAreas[i]
			FlattenRectangle(rec[1], rec[2], rec[3], rec[4], rec[5])
		end
		flattenAreas = nil
	end
	if not haveEvacuable then
		return
	end
	if (frame%TELEPORT_CHARGE_PERIOD == 0) then
		TeleportChargeTick()
	end
	if teleportingUnit then
		if frame >= teleportFrame then
			TeleportOut(teleportingUnit)
		else
			local _,_,_,x,y,z = Spring.GetUnitPosition(teleportingUnit, true)
			local progress = (teleportFrame - frame)/TELEPORT_FRAMES
			if frame % (3 + math.floor(30*progress)) == 0 then
				Spring.SpawnCEG("teleport_out", x, y, z)
			end
			if frame % 45 == 0 then
				Spring.PlaySoundFile("sounds/misc/teleport_loop.wav", 2, x, y, z)
			end
		end
	end
	if frame >= BATTLE_TIME_LIMIT then
		MakeDefendersWinBattle()
	end
end

function gadget:UnitCreated(unitID, unitDefID, unitTeam)
	if GG.applyPlanetwarsDisable then
		Spring.SetUnitRulesParam(unitID, "planetwarsDisable", 1, INLOS_ACCESS)
		GG.UpdateUnitAttributes(unitID)
	end
end

function gadget:UnitDestroyed(unitID, unitDefID, unitTeam)
	
	if unitsByID[unitID] then
		local unit = unitsByID[unitID]
		local name = unit.name
		if unitID == teleportingUnit and removingTeleportingUnit then
			Spring.SetGameRulesParam("pw_teleport_frame", nil)
			Spring.SetGameRulesParam("pw_teleport_unitname", nil)
			
			-- unit "died" from being teleported out
			AddEvacuatedStructure(name, unit)
		else
			AddDestroyedStructure(name, unit)
		end
		unitsByID[unitID] = nil
		UpdateEvacState()
		CheckRemoveWormhole(unitID, unitDefID)
	end
	if hqs[unitID] then
		local allyTeam = select(6, Spring.GetTeamInfo(unitTeam, false))
		hqsDestroyed[#hqsDestroyed+1] = allyTeam
		
		destroyedStructureCount = destroyedStructureCount + 1
		Spring.SetGameRulesParam("pw_structureDestroyed_" .. destroyedStructureCount, UnitDefs[unitDefID].name)
		
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
		local teamList = Spring.GetTeamList(i) or {0}
		local startBoxID = Spring.GetTeamRulesParam(teamList[1], "start_box_id")
		local teamID = GetAllyTeamLeader(teamList)
		SpawnHQ(teamID, planetwarsBoxes[allyTeamRole[i]], hqDefIDs[i])
	end
	
	Spring.SetGameRulesParam("pw_structureList_count", planetwarsStructureCount)
	
	SetTeleportCharge(0)
	
	if haveEvacuable then
		if wormholeList[1] then
			Spring.SetGameRulesParam("pw_evacuable_state", EVAC_STATE.ACTIVE)
		else
			Spring.SetGameRulesParam("pw_evacuable_state", EVAC_STATE.NO_WORMHOLE)
			RemoveEvacCommands()
		end
	else
		Spring.SetGameRulesParam("pw_evacuable_state", EVAC_STATE.NOTHING_TO_EVAC)
	end
end

local function InitializeUnitsToSpawn()
	local modOptions = (Spring and Spring.GetModOptions and Spring.GetModOptions()) or {}
	local pwDataRaw = modOptions.planetwarsstructures
	local pwDataFunc, err, success, unitData
	if not (pwDataRaw and type(pwDataRaw) == 'string') then
		err = "Planetwars data entry in modoption is empty or in invalid format"
		return {}, false
	else
		pwDataRaw = string.gsub(pwDataRaw, '_', '=')
		pwDataRaw = Spring.Utilities.Base64Decode(pwDataRaw)
		pwDataRaw = pwDataRaw:gsub("True,", "true,")
		pwDataRaw = pwDataRaw:gsub("False,", "false,")
		pwDataFunc, err = loadstring("return ".. pwDataRaw)
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
	
	local replacedStrucutres = {}
	for _, data in pairs(unitData) do
		local ud = UnitDefNames[data.unitname]
		if ud then
			if ud.customParams.pw_replaces then
				replacedStrucutres[ud.customParams.pw_replaces] = true
			end
		else
			replacedStrucutres[data.unitname] = true
		end
	end
	
	for key, data in pairs(unitData) do
		if replacedStrucutres[data.unitname] then
			AddEvacuatedStructure(data.unitname)
			unitData[key].evacuated = true
		end
	end
	
	return unitData, true
end

function gadget:Initialize()
	if not Spring.GetModOptions().planet or Spring.GetGameRulesParam("planetwars_structures") == 0 then
		gadgetHandler:RemoveGadget()
		return
	end

	local edgePadding = math.max(200, math.min(math.min(Game.mapSizeX, Game.mapSizeZ)/4 - 800, 800))
	planetwarsBoxes = GG.GetPlanetwarsBoxes(0.2, 0.25, 0.3, edgePadding)
	if not planetwarsBoxes then
		gadgetHandler:RemoveGadget()
		return
	end
	
	initialiseNoGoZones()
	structureSpawnData, spawningAnything = InitializeUnitsToSpawn()
	
	if spawningAnything then
		Spring.SetGameRulesParam("planetwars_structures", 1)
	else
		Spring.SetGameRulesParam("planetwars_structures", 0)
		gadgetHandler:RemoveGadget()
		return
	end
	
	-- get list of players that can attack PW structures
	--local players = Spring.GetPlayerList()
	--for i=1,#players do
	--	local player = players[i]
	--	local _,_,_,team,_,_,_,_,_,_,customkeys = Spring.GetPlayerInfo(player)
	--	if customkeys and tostring(customkeys.canattackpwstructures) == "1" then
	--		canAttackTeams[team] = true
	--	end
	--end
	
	Spring.SetGameRulesParam("pw_teleport_time", TELEPORT_FRAMES)
	Spring.SetGameRulesParam("pw_teleport_charge_needed", TELEPORT_CHARGE_NEEDED*(teleportChargeNeededMult or 1))
end

function gadget:AllowCommand_GetWantedCommand()
	return {[CMD_ABANDON_PW] = true}
end

function gadget:AllowCommand_GetWantedUnitDefID()
	return true
end

function gadget:AllowCommand(unitID, unitDefID, unitTeam, cmdID, cmdParams, cmdOptions)
	if not (unitsByID[unitID] and cmdID == CMD_ABANDON_PW) then
		return false -- command not used
	end
	
	if teleportingUnit then
		return true
	end
	
	if teleportCharge < TELEPORT_CHARGE_NEEDED*teleportChargeNeededMult then
		return true -- command used, do not remove
	end
	
	-- start teleporting
	teleportingUnit = unitID
	teleportFrame = Spring.GetGameFrame() + TELEPORT_FRAMES
	
	Spring.SetGameRulesParam("pw_teleport_frame", teleportFrame)
	Spring.SetUnitRulesParam(teleportingUnit, "pw_teleport_frame", teleportFrame)
	Spring.SetGameRulesParam("pw_teleport_unitname", UnitDefs[unitDefID].name)
	
	SetTeleportCharge(0)
	Spring.SetUnitAlwaysVisible(unitID, true)
	return true -- command used, remove from queue
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function gadget:GameOver()
	for i = 1, destroyedStructures.count do
		Spring.SendCommands("wbynum 255 SPRINGIE:structurekilled," .. destroyedStructures.data[i])
	end
	if evacuateStructureString then
		Spring.SendCommands("wbynum 255 SPRINGIE:pwEvacuate " .. evacuateStructureString)
	end
	for i = 1, #hqsDestroyed do
		Spring.SendCommands("wbynum 255 SPRINGIE:hqkilled,".. hqsDestroyed[i])
	end
end
