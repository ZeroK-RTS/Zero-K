
-- In-game, type "/luarules caiscout [x]" in the console to toggle scoutmap drawing for team [x]

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function gadget:GetInfo()
  return {
    name      = "CAI",
    desc      = "AI that plays normal ZK",
    author    = "Google Frog",
    date      = "June 8 2010",
    license   = "GNU GPL, v2 or later",
    layer     = 0,
    enabled   = true  --  loaded by default?
  }
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
local spGetAllUnits			= Spring.GetAllUnits
local spGetTeamInfo 		= Spring.GetTeamInfo
local spGetTeamLuaAI 		= Spring.GetTeamLuaAI
local spGetTeamList			= Spring.GetTeamList
local spGetAllyTeamList		= Spring.GetAllyTeamList
local spGetUnitAllyTeam 	= Spring.GetUnitAllyTeam
local spGiveOrderToUnit 	= Spring.GiveOrderToUnit
local spGetUnitPosition 	= Spring.GetUnitPosition
local spGetTeamResources 	= Spring.GetTeamResources
local spGetTeamRulesParam	= Spring.GetTeamRulesParam
local spGetUnitRulesParam 	= Spring.GetUnitRulesParam
local spGetCommandQueue 	= Spring.GetCommandQueue
local spGetUnitHealth		= Spring.GetUnitHealth
local spTestBuildOrder		= Spring.TestBuildOrder
local spGetUnitBuildFacing	= Spring.GetUnitBuildFacing
local spGetUnitRadius		= Spring.GetUnitRadius
local spGetUnitsInCylinder	= Spring.GetUnitsInCylinder
local spGetFactoryCommands	= Spring.GetFactoryCommands
local spGetUnitSeparation	= Spring.GetUnitSeparation
local spGetUnitNeutral		= Spring.GetUnitNeutral
local spIsPosInLos			= Spring.IsPosInLos
local spGetGroundHeight     = Spring.GetGroundHeight
local spGetUnitDefID		= Spring.GetUnitDefID
local spGetUnitsInRectangle	= Spring.GetUnitsInRectangle
local spGetUnitNearestEnemy = Spring.GetUnitNearestEnemy
local spGetGameFrame		= Spring.GetGameFrame
local spValidUnitID			= Spring.ValidUnitID
local spGetUnitTeam			= Spring.GetUnitTeam
--local spSetUnitSensorRadius = Spring.SetUnitSensorRadius
local spIsPosInRadar		= Spring.IsPosInRadar
local spGetTeamUnits		= Spring.GetTeamUnits

local GiveClampedOrderToUnit = Spring.Utilities.GiveClampedOrderToUnit

local jumpDefs = VFS.Include"LuaRules/Configs/jump_defs.lua"

local SAVE_FILE = "Gadgets/ai_cai.lua"

--------------------------------------------------------------------------------
-- commands
--------------------------------------------------------------------------------
VFS.Include("LuaRules/Configs/constants.lua")
include("LuaRules/Configs/customcmds.h.lua")

local CMD_MOVE_STATE	= CMD.MOVE_STATE
local CMD_FIRE_STATE	= CMD.FIRE_STATE
local CMD_RECLAIM    	= CMD.RECLAIM
local CMD_REPAIR		= CMD.REPAIR
local CMD_MOVE_TO_USE	= CMD_RAW_MOVE
local CMD_FIGHT			= CMD.FIGHT
local CMD_ATTACK		= CMD.ATTACK
local CMD_PATROL        = CMD.PATROL
local CMD_STOP          = CMD.STOP
local CMD_GUARD			= CMD.GUARD
local CMD_OPT_SHIFT		= CMD.OPT_SHIFT
local CMD_OPT_INTERNAL	= CMD.OPT_INTERNAL
local CMD_INSERT 		= CMD.INSERT
local CMD_REMOVE 		= CMD.REMOVE

local twoPi = math.pi*2

--------------------------------------------------------------------------------
-- *** Config

include "LuaRules/Configs/cai/general.lua"


if (gadgetHandler:IsSyncedCode()) then

--------------------------------------------------------------------------------
-- SYNCED
--------------------------------------------------------------------------------

local function CopyTable(original)   -- Warning: circular table references lead to
	local copy = {}               -- an infinite loop.
	for k, v in pairs(original) do
		if (type(v) == "table") then
			copy[k] = CopyTable(v)
		else
			copy[k] = v
		end
	end
	return copy
end

--unused
local function ModifyTable(original, modify)   -- Warning: circular table references lead to an infinite loop.
	for k, v in pairs(modify) do
		--Spring.Echo("Original entry: "..original[k])
		--Spring.Echo("Modifier entry: "..k)
		--if not (original and modify) then return end
		if (type(v) == "table") then
			ModifyTable(original[k], v)
		else
			original[k] = v
		end
	end
end
--------------------------------------------------------------------------------
-- *** 'Globals'

local usingAI -- whether there is AI in the game

local gameframe = spGetGameFrame()

-- array of allyTeams to draw heatmap data for
local debugData = {
	drawScoutmap = {},
	drawOffensemap = {},
	drawEconmap = {},
	drawDefencemap = {},
	showEnemyForceCompostion = {},
	showConJobList = {},
	showFacJobList = {},
}

local aiTeamData = {} -- all the information a single AI stores
local allyTeamData = {} -- all the information that each ally team is required to store
-- some information is stored by all. Other info is stored only be allyTeams with AI

-- is this even needed to transmit to unsynced any more?
_G.debugData = debugData
_G.aiTeamData = aiTeamData
_G.allyTeamData = allyTeamData

-- spots that mexes can be built on
mexSpot = {count = 0}

local econAverageMemory = 3 -- how many econ update steps economy is averaged over

-- size of heatmap arrays and squares
mapWidth = Game.mapSizeX
mapHeight = Game.mapSizeZ

-- elements in array
heatArrayWidth = math.ceil(mapWidth/HEATSQUARE_MIN_SIZE)
heatArrayHeight = math.ceil(mapHeight/HEATSQUARE_MIN_SIZE)
-- size of a single square in elmos
heatSquareWidth = mapWidth/heatArrayWidth
heatSquareHeight = mapHeight/heatArrayHeight
-- how many elements there are in total
heatSquares = heatArrayWidth*heatArrayHeight

-- Initialise heatmap position data
heatmapPosition = {}
for i = 1,heatArrayWidth do -- init array
	heatmapPosition[i] = {}
	for j = 1, heatArrayHeight do
		heatmapPosition[i][j] = {
			x = heatSquareWidth*(i-0.5), z = heatSquareHeight*(j-0.5),
			left = heatSquareWidth*(i-1), right = heatSquareWidth*i,
			top = heatSquareHeight*(j-1), bottom = heatSquareHeight*j,
		}
		heatmapPosition[i][j].y = spGetGroundHeight(heatmapPosition[i][j].x,heatmapPosition[i][j].z)
	end
end

_G.heatmapPosition = heatmapPosition

-- area of a command placed in the centre of the map
local areaCommandRadius = math.sqrt( (mapWidth/2)^2 + (mapHeight/2)^2 )

-- *** Little Helper Functions
-- places text on map at unit position
local function mapEcho(unitID,text)
	local x,y,z = spGetUnitPosition(unitID)
	Spring.MarkerAddPoint(x,y,z,text)
end

-- returns 2D distance^2 between 2 points
local function disSQ(x1,y1,x2,y2)
	return (x1 - x2)^2 + (y1 - y2)^2
end

-- removes the index i from the array
local function removeIndexFromArray(array,index)
	array[index] = array[array.count]
	array[array.count] = nil
	array.count = array.count - 1
end

-- chooses a unitDef at random from the chance of each being chosen
local function chooseUnitDefID(array)
	local count = array.count
	if count == 0 then return end
	local rand = math.random()
	
	local total = 0
	for i = 1, count do
		total = total + array[i].chance
		if rand < total then
			return array[i].ID
		end
	end
	Spring.Echo(" ******* Chance Wrong ******* ")
	return array[1].ID
end

-- chooses a unitDef at random from the chance of each being chosen and prints useful debug
local function chooseUnitDefIDWithDebug(array, unitID, ud, choice)
	local count = array.count
	if count == 0 then return end
	local rand = math.random()
	
	local total = 0
	for i = 1, count do
		if not array then
			Spring.Log(gadget:GetInfo().name, LOG.ERROR, "bad array for " .. ud.humanName .. " with choice " .. choice)
		end
		if not array[i] then
			Spring.Log(gadget:GetInfo().name, LOG.ERROR, "bad array index for " .. ud.humanName .. " with choice " .. choice)
		end
		total = total + array[i].chance
		if rand < total then
			return array[i].ID
		end
	end
	-- Very rarely chances do not add up correctly or math.random() >= 1
	return array[1].ID
	--Spring.Echo("Chance Wrong for " .. ud.humanName .. " with choice " .. choice)
end

-- normalises the importance factors in an importance array
local function normaliseImportance(array)

	local totalImportance = 0
	for _,data in pairs(array) do
		totalImportance = totalImportance + data.importance
	end
	
	if totalImportance > 0 then
		local scaleFactor = 1/totalImportance
		for _,data in pairs(array) do
			data.importance = data.importance*scaleFactor
		end
	end
end

-- is the enemy unitID position knowable to an allyteam
local function isUnitVisible(unitID, allyTeam)
	if spValidUnitID(unitID) then
		local state = Spring.GetUnitLosState(unitID,allyTeam)
		return state and (state.los or state.radar) --(state.radar and state.typed) -- typed for has unit icon
	else
		return false
	end
end

-- updates the economy information of the team. Averaged over a few queries
local function updateTeamResourcing(team)

	local a = aiTeamData[team]
	local averagedEcon = a.averagedEcon
	
	-- get resourcing
	local eCur, eMax, ePull, eInc, eExp, eShare, eSent, eRec = spGetTeamResources(team, "energy")
	local mCur, mMax, mPull, mInc, mExp, mShare, mSent, mRec = spGetTeamResources(team, "metal")
	
	averagedEcon.mStor = mMax - HIDDEN_STORAGE -- m storage
	
	--// average the resourcing over the past few updates to reduce sharp spikes and dips
	-- update previous frame info
	for i = econAverageMemory, 2, -1 do
		averagedEcon.prevEcon[i] = averagedEcon.prevEcon[i-1]
	end
	-- @see gui_chili_economy_panel2.lua for eco-params reference
	local oddEnergyIncome = spGetTeamRulesParam(team, "OD_energyIncome") or 0
	local oddEnergyChange = spGetTeamRulesParam(team, "OD_energyChange") or 0
	averagedEcon.prevEcon[1] = {
		eInc     = eInc + oddEnergyIncome - math.max(0, oddEnergyChange),
		mInc     = mInc + mRec,
		activeBp = mPull
	}
	-- calculate average
	averagedEcon.aveEInc = 0
	averagedEcon.aveMInc = 0
	averagedEcon.aveActiveBP = 0
	for i = 1,econAverageMemory do
		averagedEcon.aveEInc = averagedEcon.aveEInc + averagedEcon.prevEcon[i].eInc
		averagedEcon.aveMInc = averagedEcon.aveMInc + averagedEcon.prevEcon[i].mInc
		averagedEcon.aveActiveBP = averagedEcon.aveActiveBP + averagedEcon.prevEcon[i].activeBp
	end
	averagedEcon.aveEInc = averagedEcon.aveEInc/econAverageMemory
	averagedEcon.aveMInc = averagedEcon.aveMInc/econAverageMemory
	averagedEcon.aveActiveBP = averagedEcon.aveActiveBP/econAverageMemory
	averagedEcon.mCur = mCur
	averagedEcon.eCur = eCur
	
	if averagedEcon.aveMInc > 0 then
		averagedEcon.energyToMetalRatio = averagedEcon.aveEInc/averagedEcon.aveMInc
		averagedEcon.activeBpToMetalRatio = averagedEcon.aveActiveBP/averagedEcon.aveMInc
	else
		averagedEcon.energyToMetalRatio = false
		averagedEcon.activeBpToMetalRatio = false
	end
end

-- changes the weighting on con and factory jobs based on brain, can do other things too
local function executeControlFunction(team, frame)

	local a = aiTeamData[team]
	local at = allyTeamData[a.allyTeam]
	
	local averagedEcon = a.averagedEcon
	
	if averagedEcon.energyToMetalRatio then
		a.controlFunction(a, at, frame)
	end -- no metal income no con
		
	normaliseImportance(a.facJob)
	normaliseImportance(a.conJob)

end

-- allocates the con so the BP factors of each job matches the allocated importance of each job
local function conJobAllocator(team)
	--Spring.Echo{"totalBP: " .. totalBP}
	local a = aiTeamData[team]
	local conJob = a.conJob
	local conJobByIndex = a.conJobByIndex
	local unassignedCons = a.unassignedCons
	local controlledUnit = a.controlledUnit
	
	local lackingCons = {} -- jobs that need more cons
	local lackingConCount = 0 -- number of jobs that need more cons
	
	-- remove con from jobs with too much BP
	for _,data in pairs(conJob) do
		data.bpChange = data.importance*a.totalBP - data.assignedBP
		while data.bpChange <= -4.8 do
			local unitID = next(data.con)
			if not unitID then
				break
			end
			if controlledUnit.conByID[unitID] then
				data.bpChange = data.bpChange + controlledUnit.conByID[unitID].bp
				data.assignedBP = data.assignedBP - controlledUnit.conByID[unitID].bp
			end
			data.con[unitID] = nil
			if Spring.ValidUnitID(unitID) and not Spring.GetUnitIsDead(unitID) then
				unassignedCons.count = unassignedCons.count + 1
				unassignedCons[unassignedCons.count] = unitID
			end
		end
		
		if data.bpChange > 0 then
			lackingConCount = lackingConCount + 1
			lackingCons[lackingConCount] = data
		end
	end
	
	-- add con to jobs with not enough BP
	while unassignedCons.count > 0 do
		local largestChange = 0
		local largestID = -1
		
		-- find the job with the largest bp need
		for i = 1,lackingConCount do
			if lackingCons[i].bpChange > largestChange then
				largestID = i
				largestChange = lackingCons[i].bpChange
			end
		end
		
		-- add a con to the job with the largest bp need
		if largestID ~= -1 then
			local data = lackingCons[largestID]
			local i = unassignedCons.count
			local unitID = unassignedCons[i]
			local oldConJob = conJobByIndex[controlledUnit.conByID[unitID].oldJob]
			
			-- find the closest free con
			while oldConJob and oldConJob.location ~= data.location and i > 1 do
				i = i-1
				unitID = unassignedCons[i]
				oldConJob = conJobByIndex[controlledUnit.conByID[testUnitID].oldJob]
			end
			
			data.bpChange = data.bpChange - controlledUnit.conByID[unitID].bp
			data.con[unitID] = true
			data.assignedBP = data.assignedBP + controlledUnit.conByID[unitID].bp
			
			if controlledUnit.conByID[unitID].oldJob > 0 and controlledUnit.conByID[unitID].oldJob ~= data.index then
				if conJobByIndex[controlledUnit.conByID[unitID].oldJob].interruptable then
					controlledUnit.conByID[unitID].idle = true
				end
			end
			controlledUnit.conByID[unitID].currentJob = data.index
			
			removeIndexFromArray(unassignedCons,i)
			
			--mapEcho(unitID,"con added to " .. data.name)
		else
			Spring.Log(gadget:GetInfo().name, LOG.ERROR, "broke 'add con to jobs with not enough BP'") -- should not happen
			break
		end
	end
	
end

-- faces the building towards the centre of the map - facing values { S = 0, E = 1, N = 2, W = 3 }
local function getBuildFacing(left,top)
	
	local right = mapWidth - left
	local bottom = mapHeight - top
	
	if right < top then
		if right < left then
			if right < bottom then
				return 3
			else
				return 2
			end
		else
			if left < bottom then
				return 1
			else
				return 2
			end
		end
	else
		if top < left then
			if top < bottom then
				return 0
			else
				return 2
			end
		else
			if left < bottom then
				return 1
			else
				return 2
			end
		end
	end
end

-- returns if position is within distance of a unit in unit array
local function nearRadar(team,tx,tz,distance)
	
	local unitArray = allyTeamData[aiTeamData[team].allyTeam].units.radarByID
	
	for unitID,_ in pairs(unitArray) do
		local x,_,z = spGetUnitPosition(unitID)
		if x and disSQ(x,z,tx,tz) < distance^2 then
			return true
		end
	end
	return false
end

-- returns if position is within distance of a unit in unit array
local function nearFactory(team,tx,tz,distance)
	
	local unitArray = allyTeamData[aiTeamData[team].allyTeam].units.factoryByID
	
	for unitID, data in pairs(unitArray) do
		--mapEcho(unitID,"factroyChecked")
		local x,_,z = spGetUnitPosition(unitID)
		if x and disSQ(x,z,tx,tz) < distance^2 then
			return true
		end
		if disSQ(data.wayX,data.wayZ,tx,tz) < (distance*1.5)^2 then
			return true
		end
	end
	return false
end

-- returns if position is within distance of a unit in unit array
local function nearEcon(team,tx,tz,distance)
	
	local unitArray = allyTeamData[aiTeamData[team].allyTeam].units.econByID
	for unitID,_ in pairs(unitArray) do
		local x,_,z = spGetUnitPosition(unitID)
		if x and disSQ(x,z,tx,tz) < distance^2 then
			return true
		end
	end
	return false
end

-- returns if position is within distance of a mex spot
local function nearMexSpot(tx,tz,distance)

	for i = 1, #GG.metalSpots do
		local x = GG.metalSpots[i].x
		local z = GG.metalSpots[i].z
		if disSQ(x,z,tx,tz) < distance^2 then
			return true
		end
	end
	return false
end

-- returns if position is within distance of defence structure or wanted defence location
local function nearDefence(team,tx,tz,distance)

	local a = aiTeamData[team]
	local unitArray = allyTeamData[aiTeamData[team].allyTeam].units.turretByID
	
	for unitID,_ in pairs(unitArray) do
		local x,_,z = spGetUnitPosition(unitID)
		if x and disSQ(x,z,tx,tz) < distance^2 then
			return true
		end
	end
	
	for i = 1, a.wantedDefence.count do
		if disSQ(a.wantedDefence[i].x,a.wantedDefence[i].z,tx,tz) < distance^2 then
			return true
		end
	end
	
	return false
end

-- check if a spot is covered by enemies within attack range
-- FIXME: this actually involves maphax - 'course it wouldn't need to if it remembered where bad guy turrets are...
local function isPosThreatened(allyTeam, x, z)
	local cache = allyTeamData[allyTeam].isPosThreatenedCache
	local threatened = false
	
	if cache[x] and cache[x][z] then
		if cache[x][z].time + CACHE_POS_THREATENED_TTL < gameframe then
			return cache[x][z].isThreatened or false
		else
			cache[x][z] = nil
		end
	end
	
	local units = spGetUnitsInCylinder(x, z, RADIUS_CHECK_POS_FOR_ENEMY_DEF)
	for i=1,#units do
		local unitID = units[i]
		local unitAllyTeam = Spring.GetUnitAllyTeam(unitID)
		if unitAllyTeam ~= allyTeam then
			local ud = UnitDefs[spGetUnitDefID(unitID)]
			if ud.maxWeaponRange > MIN_RANGE_TO_THREATEN_SPOT and ud.weapons[1].onlyTargets.land then
				if ud.isImmobile then -- fixed def
					local px, py, pz = spGetUnitPosition(unitID)
					local dist = disSQ(x, z, px, pz)
					if dist < ud.maxWeaponRange + 50 then
						threatened = true
						break
					end
				else	-- armed mobile
					threatened = true
					break
				end
			end
		end
	end
	
	cache[x] = cache[x] or {}
	cache[x][z] = cache[x][z] or {}
	cache[x][z] = {isThreatened = threatened, time = gameframe}
	--Spring.Echo(x, z, threatened)
	return threatened
end

-- checks if the location is within distance of map edge
local function nearMapEdge(tx,tz,distance)
	if tx <= distance or tz <= distance or mapWidth - tx <= distance or mapHeight - tz <= distance then
		return true
	end
	return false
end

-- makes defence in response to an enemy
local function makeReponsiveDefence(team,unitID,eid,eUnitDefID,aidSearchRange)
	
	local a = aiTeamData[team]
	local turretByID = a.controlledUnit.turretByID
	local conByID = a.controlledUnit.conByID
	local buildDefs = a.buildDefs
	
	local eud = UnitDefs[eUnitDefID]
	local ux,uy,uz = spGetUnitPosition(unitID)
	
	-- check for nearby nanoframes
	for tid,data in pairs(turretByID) do
		local tx,_,tz = spGetUnitPosition(tid)
		if (not data.finished) and disSQ(ux,uz,tx,tz) < aidSearchRange^2 and not data.air then
			spGiveOrderToUnit(unitID, CMD_REPAIR, {tid}, 0)
			conByID[unitID].makingDefence = true
			return
		end
	end
	
	local ex,ey,ez = spGetUnitPosition(eid)
	local defenceDef = buildDefs.defenceIds[1][1].ID
	
	if not eud.isImmobile then
	
		local range = eud.maxWeaponRange
		if range > 500 then
			return
		end
	
		local searchRange = 40
		
		local x = ux + math.random(-searchRange,searchRange)
		local z = uz + math.random(-searchRange,searchRange)
		
		while (spTestBuildOrder(defenceDef, x, 0 ,z, 1) == 0 or not IsTargetReallyReachable(unitID, x, 0 ,z ,ux,uy,uz)) or nearMexSpot(x,z,60) or nearFactory(team,x,z,200) do
			x = ux + math.random(-searchRange,searchRange)
			z = uz + math.random(-searchRange,searchRange)
			searchRange = searchRange + 10
			if searchRange > 400 then
				return
			end
		end
		
		conByID[unitID].makingDefence = true
		GiveClampedOrderToUnit(unitID, -defenceDef, {x,0,z}, 0)
	else
		
		local vectorX = ex - ux
		local vectorZ = ez - uz
		local vectorMag = math.sqrt(disSQ(0,0,vectorX,vectorZ))
		if vectorMag == 0 then
			return
		end
		vectorX = vectorX/vectorMag
		vectorZ = vectorZ/vectorMag
		
		local range = eud.maxWeaponRange
		if range < 520 then
			if math.random() < 0.8 then
				defenceDef = buildDefs.defenceIds[1][2].ID -- build MT
			end
		end
		
		GiveClampedOrderToUnit(unitID, CMD_MOVE_TO_USE, { ex - vectorX*(range+200), 0, ez - vectorZ*(range+200)}, 0)
		
		local bx = ex - vectorX*(range+70)
		local bz = ez - vectorZ*(range+70)
		
		local searchRange = 30
		while (spTestBuildOrder(defenceDef, bx, 0 ,bz, 1) == 0 or not IsTargetReallyReachable(unitID, bx, 0 ,bz,ux,uy,uz)) or nearMexSpot(bx,bz,60) or nearFactory(team,bx,bz,200) do
			bx = ex + vectorZ*math.random(-searchRange,searchRange)
			bz = ez + vectorX*math.random(-searchRange,searchRange)
			searchRange = searchRange + 5
			if searchRange > 100 then
				return
			end
		end
		
		conByID[unitID].makingDefence = true
		GiveClampedOrderToUnit(unitID, -defenceDef, { bx, 0, bz}, CMD_OPT_SHIFT)
	end
end

local function runAway(unitID, enemyID, range)

	local ux,uy,uz = spGetUnitPosition(unitID)
	local ex,ey,ez = spGetUnitPosition(enemyID)

	local vectorX = ex - ux
	local vectorZ = ez - uz
	local vectorMag = math.sqrt(disSQ(0,0,vectorX,vectorZ))
	if vectorMag == 0 then
		return
	end
	
	vectorX = vectorX/vectorMag
	vectorZ = vectorZ/vectorMag
	
	local jump = spGetUnitRulesParam(unitID, "jumpReload")
	if ((not jump) or jump == 1) and jumpDefs[spGetUnitDefID(unitID)] then
		GiveClampedOrderToUnit(unitID, CMD_JUMP, { ex - vectorX*range, 0, ez - vectorZ*range}, 0)
	else
		GiveClampedOrderToUnit(unitID, CMD_MOVE_TO_USE, { ex - vectorX*range, 0, ez - vectorZ*range}, 0)
	end
end

-- makes defence using wantedDefence position
local function makeWantedDefence(team,unitID,searchRange, maxDistance, priorityDistance)
	local a = aiTeamData[team]
	local wantedDefence = a.wantedDefence
	local turretByID = a.controlledUnit.turretByID
	
	local x,y,z = spGetUnitPosition(unitID)
	
	if not x then
		return
	end
	
	-- check for nearby nanoframes
	for tid,data in pairs(turretByID) do
		local tx,_,tz = spGetUnitPosition(tid)
		if (not data.finished) and disSQ(x,z,tx,tz) < searchRange^2 and not data.air then
			spGiveOrderToUnit(unitID, CMD_REPAIR, {tid}, 0)
			return true
		end
	end
	
	
	local minDefDisSQ
	local minPriority = 0
	local minDeftID = 0
	
	x = x + math.random(-searchRange,searchRange)
	z = z + math.random(-searchRange,searchRange)
	
	for i = 1, wantedDefence.count do
		if (spTestBuildOrder(wantedDefence[i].ID, wantedDefence[i].x, 0 ,wantedDefence[i].z, 1) ~= 0 and IsTargetReallyReachable(unitID, wantedDefence[i].x, 0 ,wantedDefence[i].z)) then
			local dis = disSQ(wantedDefence[i].x,wantedDefence[i].z,x,z)
			if ((not maxDistance) or maxDistance^2 < dis) and minPriority == wantedDefence[i].priority then
				if ((not minDefDisSQ) or dis < minDefDisSQ) then
					minDefDisSQ = dis
					minDeftID = i
				end
			elseif ((not priorityDistance) or dis < priorityDistance^2) and minPriority < wantedDefence[i].priority then
				minDefDisSQ = dis
				minDeftID = i
				minPriority = wantedDefence[i].priority
			end
		else
			removeIndexFromArray(wantedDefence,i)
			break
		end
	end
	
	if minDeftID ~= 0 then
		GiveClampedOrderToUnit(unitID, -wantedDefence[minDeftID].ID, {wantedDefence[minDeftID].x,0,wantedDefence[minDeftID].z}, 0)
		return true
	else
		return false
		--Spring.Echo("No defence to make")
	end
end

-- makes air defence directly using the air defence heatmap
local function makeAirDefence(team,unitID, searchRange,maxDistance)
	
	local a = aiTeamData[team]
	local turretByID = a.controlledUnit.turretByID
	local selfDefenceAirTask = a.selfDefenceAirTask
	local selfDefenceHeatmap = a.selfDefenceHeatmap
	local buildDefs = a.buildDefs
	
	local x,y,z = spGetUnitPosition(unitID)
	if not x then
		return
	end
	
	-- check for nearby nanoframes
	for tid,data in pairs(turretByID) do
		local tx,_,tz = spGetUnitPosition(tid)
		if (not data.finished) and disSQ(x,z,tx,tz) < searchRange^2 and data.air then
			spGiveOrderToUnit(unitID, CMD_REPAIR, {tid}, 0)
			return true
		end
	end
	
	local minDisSQ
	local minID = 0
	
	--x = x + math.random(-searchRange,searchRange)
	--z = z + math.random(-searchRange,searchRange)
	for i = 1, selfDefenceAirTask.count do
		local dis = disSQ(selfDefenceAirTask[i].x,selfDefenceAirTask[i].z,x,z)
		if ((not minDisSQ) or dis < minDisSQ) and ((not maxDistance) or maxDistance^2 < dis) then
			minDisSQ = dis
			minID = i
		end
	end
	
	if minID ~= 0 then
		local aX = selfDefenceAirTask[minID].aX
		local aZ = selfDefenceAirTask[minID].aZ
		local data = selfDefenceHeatmap[aX][aZ]
		local defIndex = 0
		
		for i = buildDefs.airDefenceIdCount, 1, -1 do
			if data[i].air >= 1 then
				defIndex = i
				break
			end
		end
		
		if defIndex == 0 then
			removeIndexFromArray(selfDefenceAirTask,minID)
			return false
		end
		
		local deID = chooseUnitDefID(buildDefs.airDefenceIds[defIndex])
		
		local r = buildDefs.airDefenceRange[defIndex]
		local theta = math.random() * twoPi
		
		local ox = selfDefenceAirTask[minID].x
		local oz = selfDefenceAirTask[minID].z
		
		local vectorX = mapWidth*0.5 - ox
		local vectorZ = mapHeight*0.5 - oz
		local vectorMag = math.sqrt(disSQ(0,0,vectorX,vectorZ))
		if vectorMag == 0 then
			vectorMag = 1
		end
		local bx = ox + vectorX*r/vectorMag
		local bz = oz + vectorZ*r/vectorMag
		--Spring.MarkerAddLine(bx,0,bz,ox,0,oz)
		
		local searches = 0
		
		while (spTestBuildOrder(deID, bx, 0 ,bz, 1) == 0 or not IsTargetReallyReachable(unitID, bx,0,bz,x,y,z)) or nearFactory(team,bx,bz,250) or nearMexSpot(bx,bz,60) or nearMapEdge(bx,bz,300) do
			theta = math.random() * twoPi
			bx = ox + r*math.sin(theta)
			bz = oz + r*math.cos(theta)
			searches = searches + 1
			if searches > 15 then
				return false
			end
		end
		
		data[defIndex].air = data[defIndex].air - 1
		GiveClampedOrderToUnit(unitID, -deID, {bx,0,bz}, 0)
		
		local empty = true
		for i = 1, buildDefs.airDefenceIdCount do
			if data[i].air >= 0 then
				empty = false
				break
			end
		end
		
		if empty then
			removeIndexFromArray(selfDefenceAirTask,minID)
		end

		return true
	else
		return false
		--Spring.Echo("No defence to make")
	end
end

local function makeMiscBuilding(team, unitID, defId, searchRange, maxRange)
	
	local a = aiTeamData[team]
	local at = allyTeamData[a.allyTeam]
	local anyByID = a.controlledUnit.anyByID
	
	local ux,uy,uz = spGetUnitPosition(unitID)
	if not ux then
		return
	end
	-- check for nearby nanoframes
	for id,data in pairs(anyByID) do
		if data.ud.id == defId and (not data.finished) then
			local x,_,z = spGetUnitPosition(id)
			if disSQ(ux,uz,x,z) < maxRange^2 then
				spGiveOrderToUnit(unitID, CMD_REPAIR, {id}, 0)
				return true
			end
		end
	end

	x = ux + math.random(-searchRange,searchRange)
	z = uz + math.random(-searchRange,searchRange)
	
	while (spTestBuildOrder(defId, x, 0 ,z, 1) == 0 or not IsTargetReallyReachable(unitID, x, 0 ,z,ux,uy,uz)) or nearFactory(team,x,z,250) or nearMexSpot(x,z,100) do
		x = ux + math.random(-searchRange,searchRange)
		z = uz + math.random(-searchRange,searchRange)
		searchRange = searchRange + 10
		if searchRange > maxRange then
			return false
		end
	end
	
	GiveClampedOrderToUnit(unitID, -defId, {x,0,z}, 0)
	return true
end

local function makeRadar(team, unitID, searchRange, minDistance)
	
	local a = aiTeamData[team]
	local at = allyTeamData[a.allyTeam]
	local radar = a.controlledUnit.radar
	local radarByID = a.controlledUnit.radarByID
	local buildDefs = a.buildDefs
	
	local ux,uy,uz = spGetUnitPosition(unitID)
	if not ux then
		return
	end
	-- check for nearby nanoframes - helps with ally radar too!
	for rid,_ in pairs(at.units.radarByID) do
		local x,_,z = spGetUnitPosition(rid)
		if disSQ(ux,uz,x,z) < minDistance^2 then
			spGiveOrderToUnit(unitID, CMD_REPAIR, {rid}, 0)
			return true
		end
	end
	
	-- start my on construction
	local radarDefID = buildDefs.radarIds[1].ID

	x = ux + math.random(-searchRange,searchRange)
	z = uz + math.random(-searchRange,searchRange)
	
	while (spTestBuildOrder(radarDefID, x, 0 ,z, 1) == 0 or not IsTargetReallyReachable(unitID, x, 0 ,z,ux,uy,uz)) or nearFactory(team,x,z,250) or nearMexSpot(x,z,60) do
		x = ux + math.random(-searchRange,searchRange)
		z = uz + math.random(-searchRange,searchRange)
		searchRange = searchRange + 10
		if searchRange > minDistance then
			return false
		end
	end
	
	GiveClampedOrderToUnit(unitID, -radarDefID, {x,0,z}, 0)
	return true
end

-- queues nearest mex, checks for already under construction mexes
local function makeMex(team, unitID)

	local a = aiTeamData[team]
	local mex = a.controlledUnit.mex
	local mexByID = a.controlledUnit.mexByID
	local buildDefs = a.buildDefs
	
	local x,y,z = spGetUnitPosition(unitID)
	
	if not x then
		return
	end
	
	-- check for nearby nanoframes
	for i = 1, mex.count do
		local mid = mex[i]
		local ux = mexByID[mid].x
		local uz = mexByID[mid].z
		if (not mexByID[mid].finished) and disSQ(x,z,ux,uz) < 1000^2 then
			spGiveOrderToUnit(unitID, CMD_REPAIR, {mid}, 0)
			return
		end
	end
	
	x = x + math.random(-200,200)
	z = z + math.random(-200,200)
	
	local minMexSpotDisSQ = false
	local minMexSpotID = 0
	
	for i = 1, #GG.metalSpots do
		if CallAsTeam(team, function () return (spTestBuildOrder(buildDefs.mexIds[1].ID, GG.metalSpots[i].x, 0 ,GG.metalSpots[i].z, 1) ~= 0 and IsTargetReallyReachable(unitID, GG.metalSpots[i].x, 0 ,GG.metalSpots[i].z)) end) then
			local dis = disSQ(GG.metalSpots[i].x,GG.metalSpots[i].z,x,z)
			if (not minMexSpotDisSQ) or (dis < minMexSpotDisSQ) then
				minMexSpotDisSQ = dis
				minMexSpotID = i
			end
		end
	end
	
	if minMexSpotID ~= 0 then
		spGiveOrderToUnit(unitID, -buildDefs.mexIds[1].ID, {GG.metalSpots[minMexSpotID].x,0,GG.metalSpots[minMexSpotID].z}, 0)
	else
		--Spring.Echo("No free mex spots")
	end

end


-- makes a nano turret for nearest factory
local function makeNano(team,unitID)

	local a = aiTeamData[team]
	local factory = a.controlledUnit.factory
	local nano = a.controlledUnit.nano
	local nanoDefID = a.buildDefs.nanoDefID
	local nanoRangeSQ = (UnitDefs[nanoDefID].buildDistance-60)^2
	
	local ux,uy,uz = spGetUnitPosition(unitID)
	if not ux then
		return
	end
	-- check for nearby nano frames
	for i = 1, nano.count do
		local nid = nano[i]
		local data = a.controlledUnit.nanoByID[nid]
		if (not a.controlledUnit.nanoByID[nid].finished) and disSQ(data.x,data.z,ux,uz) < 1000^2 then
			spGiveOrderToUnit(unitID, CMD_REPAIR, {nid}, 0)
			return
		end
	end
	
	local closestFactory = nil
	local minDis = nil
	local minNanoCount = nil
	
	for i = 1, factory.count do
		local fid = factory[i]
		local data = a.controlledUnit.factoryByID[fid]
		local dis = disSQ(data.x, data.z, ux, uz)
		if (not minDis) or dis < minDis then
			closestFactory = fid
			minDis = dis
		end
		if (not minNanoCount) or data.nanoCount < minNanoCount then
			minNanoCount = data.nanoCount
		end
	end
	
	if not minNanoCount then
		return
	end
	
	local data = a.controlledUnit.factoryByID[closestFactory]
	
	if minNanoCount ~= data.nanoCount then
		return
	end
	
	local searchRange = 0
	
	x = data.nanoX + math.random(-searchRange,searchRange)
	z = data.nanoZ + math.random(-searchRange,searchRange)
	
	while (spTestBuildOrder(nanoDefID, x, 0 ,z, 1) == 0 or not IsTargetReallyReachable(unitID, x, 0 ,z,ux,uy,uz)) or disSQ(data.x, data.z, x ,z) > nanoRangeSQ do
		x = data.nanoX + math.random(-searchRange,searchRange)
		z = data.nanoZ + math.random(-searchRange,searchRange)
		searchRange = searchRange + 20
		if searchRange > 250 then
			return
		end
	end

	GiveClampedOrderToUnit(unitID, -nanoDefID, {x,0,z}, 0)
end

-- queues energy order or helps nearby construction
local function makeEnergy(team,unitID)

	local a = aiTeamData[team]
	local econ = a.controlledUnit.econ
	local econByID = a.controlledUnit.econByID
	local conByID = a.controlledUnit.conByID
	local averagedEcon = a.averagedEcon
	local conJob = a.conJob
	local buildDefs = a.buildDefs
	
	local ux,uy,uz = spGetUnitPosition(unitID)
	
	if not ux then
		return
	end
	
	-- check for nearby nanoframes
	for i = 1, econ.count do
		local eid = econ[i]
		local x = econByID[eid].x
		local z = econByID[eid].z
		if (not econByID[eid].finished) and disSQ(x,z,ux,uz) < 1000^2 then
			spGiveOrderToUnit(unitID, CMD_REPAIR, {eid}, 0)
			return
		end
	end
	
	-- check for nearby con
	for cid,_ in pairs(conJob.energy.con) do
		local cQueue = spGetCommandQueue(cid, 1)
		local cx,cy,cz = spGetUnitPosition(cid)
		if cQueue and #cQueue > 0 and disSQ(cx,cz,ux,uz) < 800^2 then
			for i = 1, buildDefs.energyIds.count do
				if cQueue[1].id == buildDefs.energyIds[i].ID then
					spGiveOrderToUnit(unitID, CMD_GUARD, {cid}, 0)
					conByID[unitID].idle = true
					return
				end
			end
		end
	end
	
	-- start my own construction
	local energyDefID = buildDefs.energyIds[buildDefs.energyIds.count].ID
	
	for i = 1, buildDefs.energyIds.count do
		local udID = buildDefs.energyIds[i].ID
		if averagedEcon.aveEInc >= buildDefs.econByDefId[udID].energyGreaterThan and
				((not buildDefs.econByDefId[udID].makeNearFactory) or nearFactory(team,ux,uz,buildDefs.econByDefId[udID].makeNearFactory)) and
				(averagedEcon.eCur > 200 or buildDefs.econByDefId[udID].whileStall) and buildDefs.econByDefId[udID].chance > math.random() then
			energyDefID = udID
			break
		end
	end
	
	local searchRange = 120
	local minDistance = 100
	
	x = ux + math.random(minDistance,searchRange)*math.ceil(math.random(-1,1))
	z = uz + math.random(minDistance,searchRange)*math.ceil(math.random(-1,1))
	
	while (spTestBuildOrder(energyDefID, x, 0 ,z, 1) == 0 or not IsTargetReallyReachable(unitID, x, 0 ,z,ux,uy,uz)) or nearFactory(team,x,z,250) or nearMexSpot(x,z,60) or nearEcon(team,x,z, buildDefs.econByDefId[energyDefID].energySpacing) do
		x = ux + math.random(minDistance,searchRange)*math.ceil(math.random(-1,1))
		z = uz + math.random(minDistance,searchRange)*math.ceil(math.random(-1,1))
		searchRange = searchRange + 10
		if searchRange > 500 then
			x = ux + math.random(-700,700)
			z = uz + math.random(-700,700)
			GiveClampedOrderToUnit(unitID, CMD_MOVE_TO_USE, { x , 0, z }, 0)
			return
		end
	end
	
	GiveClampedOrderToUnit(unitID, -energyDefID, {x,0,z}, 0)
	
end

-- assigns con to a factory or builds a new one
local function assignFactory(team,unitID,cQueue)
	if not cQueue then
		return
	end

	local a = aiTeamData[team]
	local controlledUnit = a.controlledUnit
	local conJob = a.conJob
	local buildDefs = a.buildDefs

	if #cQueue == 0 or not buildDefs.factoryByDefId[-cQueue[1].id] then
		if (a.totalBP < a.totalFactoryBPQuota or a.uncompletedFactory ~= false) and controlledUnit.factory.count > 0 then
			
			--local assistAir = (math.random() < conJob.factory.airFactor)

			local randIndex = math.floor(math.random(1,controlledUnit.factory.count))
			local facID = controlledUnit.factory[randIndex]
			if a.uncompletedFactory ~= true and a.uncompletedFactory ~= false then
				facID = a.uncompletedFactory
			end
			
			local x, y, z = spGetUnitPosition(facID)
			local fd = controlledUnit.factoryByID[facID].ud
			
			if (not x) then
				return
			end
		
			local radius = spGetUnitRadius(facID)
			if (not radius) then
				return
			end
			local dist = radius * 2
		
			local frontDis = fd.xsize*4+32 -- 4 to edge
			local sideDis = ((fd.zsize or fd.ysize)*4+32)

			if frontDis > dist then
				dist = frontDis
			end
		
			if sideDis > dist then
				dist = sideDis
			end

			local facing = spGetUnitBuildFacing(facID)
			if (not facing) then
				return
			end
			-- facing values { S = 0, E = 1, N = 2, W = 3 }

			dist = dist * (math.floor(math.random(0,1))*2-1)
			if (facing == 0) or (facing == 2) then
				GiveClampedOrderToUnit(unitID, CMD_MOVE_TO_USE, { x + dist, y, z }, 0)
			else
				GiveClampedOrderToUnit(unitID, CMD_MOVE_TO_USE, { x , y, z + dist}, 0)
			end
			
			
			spGiveOrderToUnit(unitID, CMD_GUARD, {facID},CMD_OPT_SHIFT)
		else
			
			local buildableFactoryCount = 0
			local buildableFactory = {}
			local totalImportance = 0
			
			-- first see if we want to make an air fac
			if math.random() < conJob.factory.airFactor then
				for id,data in pairs(buildDefs.factoryByDefId) do
					if data.airFactory and data.minFacCount <= controlledUnit.factory.count and ((not a.factoryCountByDefID[id]) or a.factoryCountByDefID[id] == 0) and data.importance > 0 then
						buildableFactoryCount = buildableFactoryCount + 1
						buildableFactory[buildableFactoryCount] = {ID = id, importance = data.importance}
						totalImportance = totalImportance + data.importance
					end
				end
			end
			
			-- if we didn't try to make an air fac, or tried to but couldn't find one, try a land one
			if buildableFactoryCount == 0 then
				for id,data in pairs(buildDefs.factoryByDefId) do
					if (not data.airFactory) and data.minFacCount <= controlledUnit.factory.count and ((not a.factoryCountByDefID[id]) or a.factoryCountByDefID[id] == 0) and data.importance > 0  then
						buildableFactoryCount = buildableFactoryCount + 1
						buildableFactory[buildableFactoryCount] = {ID = id, importance = data.importance}
						totalImportance = totalImportance + data.importance
					end
				end
			end
			
			-- can't find any valid facs, try with loosened requirements
			-- before we could only build facs that we didn't have any of AND that met requirements for number of existing facs, now it's only an OR condition
			-- fac may be either air or land
			if buildableFactoryCount == 0 then
				for id,data in pairs(buildDefs.factoryByDefId) do
					if (data.minFacCount <= controlledUnit.factory.count or ((not a.factoryCountByDefID[id]) or a.factoryCountByDefID[id] == 0)) and data.importance > 0  then
						buildableFactoryCount = buildableFactoryCount + 1
						buildableFactory[buildableFactoryCount] = {ID = id, importance = data.importance}
						totalImportance = totalImportance + data.importance
					end
				end
			end

			-- give up and just allow any factory (that isn't disabled)
			if buildableFactoryCount == 0 then
				for id,data in pairs(buildDefs.factoryByDefId) do
					if data.importance > 0  then
						buildableFactoryCount = buildableFactoryCount + 1
						buildableFactory[buildableFactoryCount] = {ID = id, importance = data.importance}
						totalImportance = totalImportance + data.importance
					end
				end
			end

			if buildableFactoryCount == 0 then
				return
			end
			
			local choice = (buildableFactoryCount > 1) and math.random(buildableFactoryCount) or 1
			local rand = math.random()*totalImportance
			local total = 0
			--Spring.Echo(buildableFactoryCount, totalImportance, rand)
			for i = 1, buildableFactoryCount do
				total = total + buildableFactory[i].importance
				--Spring.Echo(UnitDefs[buildableFactory[i].ID].name, buildableFactory[i].importance, total)
				if rand < total then
					choice = i
					break
				end
			end
			
			local ux,uy,uz = spGetUnitPosition(unitID)
			local searchRange = 200
			x = ux + math.random(-searchRange,searchRange)
			z = uz + math.random(-searchRange,searchRange)
			while (spTestBuildOrder(buildableFactory[choice].ID, x, 0 ,z, 1) == 0 or not IsTargetReallyReachable(unitID, x, 0 ,z,ux,uy,uz)) or nearMexSpot(x,z,160) or nearEcon(team,x,z,200) or nearMapEdge(x,z,600) or nearFactory(team,x,z,1000) or nearDefence(team,x,z,120) do
				
				x = ux + math.random(-searchRange,searchRange)
				z = uz + math.random(-searchRange,searchRange)
				searchRange = searchRange + 10
				if searchRange > 2000 then
					return
				end
			end
			a.uncompletedFactory = true
			spGiveOrderToUnit(unitID, -buildableFactory[choice].ID, {x,0,z,getBuildFacing(x,z)}, 0)
		end
	end
	
end


-- updates the con state based on their current job
local function conJobHandler(team)
	
	local a = aiTeamData[team]
	local conJob = a.conJob
	local controlledUnit = a.controlledUnit
	local buildDefs = a.buildDefs
	--[[
	for id, data in pairs(conJob) do
		Spring.Echo(data.name .. " importance " .. data.importance)
	end
	--]]
	-- reclaim
	for unitID,_ in pairs(conJob.reclaim.con) do
		local cQueue = spGetCommandQueue(unitID, 1)
		if (cQueue and #cQueue == 0) or (unitID and controlledUnit.conByID[unitID] and controlledUnit.conByID[unitID].idle) then
			controlledUnit.conByID[unitID].idle = false
			controlledUnit.conByID[unitID].makingDefence = false
			controlledUnit.conByID[unitID].oldJob = conJob.reclaim.index
			spGiveOrderToUnit(unitID, CMD_RECLAIM, {mapWidth/2,0,mapHeight/2,areaCommandRadius}, 0)
		end
	end
	
	-- defence
	for unitID,_ in pairs(conJob.defence.con) do
		local cQueue = spGetCommandQueue(unitID, 1)
		if (cQueue and #cQueue) == 0 or (unitID and controlledUnit.conByID[unitID] and controlledUnit.conByID[unitID].idle) then
			local x,y,z = spGetUnitPosition(unitID)
			controlledUnit.conByID[unitID].oldJob = conJob.defence.index
			controlledUnit.conByID[unitID].idle = false
			if not
			(
				(
					(
						(not nearRadar(team,x,z,1600))
					or
						(not spIsPosInRadar(x,y,z,a.allyTeam))
					)
				and
					math.random() < conJob.defence.radarChance
				and
					makeRadar(team, unitID, 400, 400)
				)
			or
				(
					math.random() < conJob.defence.airChance
				and
					makeAirDefence(team,unitID,1000,false)
				)
			or
				(
					math.random() < conJob.defence.airpadChance
				and
					makeMiscBuilding(team,unitID,buildDefs.airpadDefID,200,1000)
				)
			or
				(
					math.random() < conJob.defence.metalStorageChance
				and
					makeMiscBuilding(team,unitID,buildDefs.metalStoreDefID,200,1000)
				)
			)
			then
				makeWantedDefence(team,unitID,1000,false, 1500)
			end
		end
	end
	
	-- mex
	for unitID,_ in pairs(conJob.mex.con) do
		local cQueue = spGetCommandQueue(unitID, 1)
		if (cQueue and #cQueue == 0) or (unitID and controlledUnit.conByID[unitID] and controlledUnit.conByID[unitID].idle) then
			controlledUnit.conByID[unitID].idle = false
			controlledUnit.conByID[unitID].oldJob = conJob.mex.index
			if math.random() < conJob.mex.defenceChance and makeWantedDefence(team,unitID,500,500,1000) then
				controlledUnit.conByID[unitID].makingDefence = true
			else
				controlledUnit.conByID[unitID].makingDefence = false
				makeMex(team,unitID)
			end
		end
	end
	
	-- check for queued factory
	if a.uncompletedFactory == true then
		a.uncompletedFactory = false
		for unitID,data in pairs(conJob.factory.con) do
			local cQueue = spGetCommandQueue(unitID, 1)
			if cQueue and #cQueue ~= 0 and buildDefs.factoryByDefId[-cQueue[1].id] then
				a.uncompletedFactory = true
			end
		end
	end
	
	-- factory assist/construction
	for unitID,data in pairs(conJob.factory.con) do
		local cQueue = spGetCommandQueue(unitID, 1)
		
		if (cQueue and #cQueue == 0) or (unitID and controlledUnit.conByID[unitID] and controlledUnit.conByID[unitID].idle) then
			controlledUnit.conByID[unitID].idle = false
			controlledUnit.conByID[unitID].makingDefence = false
			controlledUnit.conByID[unitID].oldJob = conJob.factory.index
			assignFactory(team,unitID,cQueue)
		elseif a.wantedNanoCount > controlledUnit.nano.count and math.random() < a.nanoChance then
			makeNano(team, unitID)
		end
	end
	
	-- energy
	for unitID,_ in pairs(conJob.energy.con) do
		local cQueue = spGetCommandQueue(unitID, 1)
		if (cQueue and #cQueue == 0) or (unitID and controlledUnit.conByID[unitID] and controlledUnit.conByID[unitID].idle) then
			controlledUnit.conByID[unitID].idle = false
			controlledUnit.conByID[unitID].makingDefence = false
			controlledUnit.conByID[unitID].oldJob = conJob.energy.index
			makeEnergy(team,unitID)
		end
	end
	
end

local function setUnitPosting(team, unitID)
	
	local a = aiTeamData[team]
	
	if a.conJob.mex.assignedBP == 0 then
		return
	end
	
	local rand = math.random(0,a.conJob.mex.assignedBP)
	local total = 0
	for cid,_ in pairs(a.conJob.mex.con) do
		total = total + a.controlledUnit.conByID[cid].bp
		if total > rand then
			local x,y,z = spGetUnitPosition(cid)
			GiveClampedOrderToUnit(unitID, CMD_FIGHT , {x+math.random(-100,100),y,z+math.random(-100,100)}, 0)
			break
		end
	end
	
end

local function setRetreatState(unitID, unitDefID, unitTeam, num)
	local unitDef = UnitDefs[unitDefID]
	if (unitDef.customParams.level) then
		if not aiTeamData[unitTeam].retreatComm then
			return
		end
	else
		if not aiTeamData[unitTeam].retreat then
			return
		end
	end
	spGiveOrderToUnit(unitID, CMD_RETREAT, {num}, 0)
end

local function getPositionTowardsMiddle(unitID, range, inc, count)
		count = count or 4
	local x,y,z = spGetUnitPosition(unitID)
	local vectorX = mapWidth*0.5 - x
	local vectorZ = mapHeight*0.5 - z
	
	local vectorMag = math.sqrt(disSQ(0,0,vectorX,vectorZ))
	if vectorMag == 0 then
		vectorMag = 1
	end
	vectorMag = 1/vectorMag
	local i = 1
	while (spTestBuildOrder(waypointTester, x + vectorX*range*vectorMag, 0, z + vectorZ*range*vectorMag, 1) == 0 or not IsTargetReallyReachable(unitID, x + vectorX*range*vectorMag, 0, z + vectorZ*range*vectorMag,x,y,z)) do
		--Spring.MarkerAddPoint(x + vectorX*range*vectorMag, 0, z + vectorZ*range*vectorMag,"test")
		range = range + inc
		i = i + 1
		if i > count then
			break
		end
	end
	
	return x + vectorX*range*vectorMag, y, z + vectorZ*range*vectorMag
end

-- updates factory that has finished it's queue with a new order
local function factoryJobHandler(team)

	local a = aiTeamData[team]
	local factoryByID = a.controlledUnit.factoryByID
	local facJob = a.facJob
	local buildDefs = a.buildDefs

	for unitID,data in pairs(factoryByID) do
		
		local scouting = false
		local raiding = false
		
		local cQueue = spGetFactoryCommands(unitID, 1)
		if cQueue and #cQueue == 0 then
			local defData = buildDefs.factoryByDefId[data.ud.id]
			local choice = 1
			if defData.airFactory then
				local facJobAir = a.facJobAir
				local totalImportance = 0
				for i = 1, 5 do
					totalImportance = totalImportance + facJobAir[i].importance*defData[i].importanceMult
				end

				local total = 0
				local rand = math.random()*totalImportance

				for i = 1, 5 do
					total = total + facJobAir[i].importance*defData[i].importanceMult
					if rand < total then
						choice = i
						scouting = (i == 2)
						break
					end
				end
			else
				if math.random() < a.unitHordingChance then
					setUnitPosting(team, unitID)
				else
					GiveClampedOrderToUnit(unitID, CMD_FIGHT, { data.wayX+math.random(-200,200), data.wayY, data.wayZ+math.random(-200,200)}, 0)
				end
				local totalImportance = 0
				for i = 1, 8 do
					totalImportance = totalImportance + facJob[i].importance*defData[i].importanceMult
				end

				local total = 0
				local rand = math.random()*totalImportance

				for i = 1, 8 do
					total = total + facJob[i].importance*defData[i].importanceMult
					if rand < total then
						choice = i
						scouting = (i == 2)
						raiding = (i == 3)
						break
					end
				end
			end
			
			local bud = chooseUnitDefIDWithDebug(defData[choice], unitID, data.ud, choice)
			data.producingScout = scouting
			data.producingRaider = raiding
			spGiveOrderToUnit(unitID, -bud , {}, 0)
		end
	end

end

local function removeValueFromHeatmap(indexer, heatmap, aX, aZ)

	if heatmap[aX][aZ].cost > 0 then
		indexer.totalCost = indexer.totalCost - heatmap[aX][aZ].cost
		heatmap[aX][aZ].cost = 0
		-- remove index
		local index = heatmap[aX][aZ].index
		indexer[index] = indexer[indexer.count]
		indexer[indexer.count] = nil
		if index ~= indexer.count then
			heatmap[indexer[index].aX][indexer[index].aZ].index = index
		end
		indexer.count = indexer.count - 1
	end

end

local function wipeSquareData(allyTeam,aX,aZ)
	
	local at = allyTeamData[allyTeam]
	
	removeValueFromHeatmap(at.enemyOffense, at.enemyOffenseHeatmap, aX, aZ)
	removeValueFromHeatmap(at.enemyDefence, at.enemyDefenceHeatmap, aX, aZ)
	removeValueFromHeatmap(at.enemyEconomy, at.enemyEconomyHeatmap, aX, aZ)
	
end

local function getEnemyAntiAirInRange(allyTeam, x, z)

	local at = allyTeamData[allyTeam]
	local static = 0
	local mobile = 0
	
	for id, data in pairs(at.enemyStaticAA) do
		if (x-data.x)^2 + (z-data.z)^2 < data.rangeSQ then
			static = static + data.cost
		end
	end
	
	for id, data in pairs(at.enemyMobileAA) do
		if data.x and data.z then
			if (x-data.x)^2 + (z-data.z)^2 < data.rangeSQ then
				mobile = mobile + data.cost
			end
		end
	end
	
	return static, mobile

end

local function gatherBattlegroupNeededAA(team, index)

	local a = aiTeamData[team]
	local at = allyTeamData[a.allyTeam]
	
	local aa = a.controlledUnit.aa
	local aaByID = a.controlledUnit.aaByID
	local unitInBattleGroupByID = a.unitInBattleGroupByID
	
	local bg = a.battleGroup[index]
	
	local cost = 0

	for unitID,_ in pairs(bg.aa) do
		if spValidUnitID(unitID) then
			cost = cost + aaByID[unitID].cost
		else
			bg.unit[unitID] = nil
			bg.aa[unitID] = nil
			unitInBattleGroupByID[unitID] = nil
		end
	end
	
	for unitID,data in pairs(aaByID) do
		if not unitInBattleGroupByID[unitID] then
			cost = cost + data.cost
			bg.unit[unitID] = true
			bg.aa[unitID] = true
			unitInBattleGroupByID[unitID] = true
			if cost > bg.neededAA then
				break
			end
		end
	end

end

local function battleGroupHandler(team, frame, slowUpdate)

	local a = aiTeamData[team]
	local at = allyTeamData[a.allyTeam]
	local battleGroup = a.battleGroup
	local unitInBattleGroupByID = a.unitInBattleGroupByID
	
	for i = 1, battleGroup.count do
		
		local data = battleGroup[i]

		for unitID,_ in pairs(data.unit) do
			if spValidUnitID(unitID) then
				if not unitInBattleGroupByID[unitID] then
					--mapEcho(unitID, "unit not in group")
				end
			end
		end

		local averageX = 0
		local averageZ = 0
		local averageCount = 0
		
		local maxX = false
		local minX = false
		local maxZ = false
		local minZ = false
		
		for unitID,_ in pairs(data.unit) do
			local retreating = Spring.GetUnitRulesParam(unitID, "retreat") == 1
			if spValidUnitID(unitID) and not retreating then
				local x, y, z = spGetUnitPosition(unitID)
				averageX = averageX + x
				averageZ = averageZ + z
				averageCount = averageCount + 1
				
				if not maxX or maxX < x then
					maxX = x
				end
				if not minX or minX > x then
					minX = x
				end
				if not maxZ or maxZ < z then
					maxZ = z
				end
				if not minZ or minZ > z then
					minZ = z
				end
				
				local cQueue = spGetCommandQueue(unitID, 1)
				if cQueue and #cQueue > 0 and cQueue[1].id == CMD_ATTACK and #cQueue[1].params == 1 then
					local udid = spGetUnitDefID(cQueue[1].params[1])
					if (not udid) or (not UnitDefs[udid].canFly) then
						data.tempTarget = cQueue[1].params[1]
					end
				end
			else
				data.unit[unitID] = nil
				data.aa[unitID] = nil
				unitInBattleGroupByID[unitID] = nil
			end
		end
		
		if averageCount == 0 then
			removeIndexFromArray(battleGroup,i)
			break
		end
		
		averageX = averageX/averageCount
		averageZ = averageZ/averageCount
		
		data.currentX = averageX
		data.currentZ = averageZ
	
		local gy = spGetGroundHeight(averageX,averageZ)
		for unitID,_ in pairs(data.aa) do
			GiveClampedOrderToUnit(unitID, CMD_MOVE_TO_USE , {averageX,gy,averageZ}, 0)
		end

		if data.tempTarget then
			if spValidUnitID(data.tempTarget) and isUnitVisible(data.tempTarget,a.allyTeam) then
				local x, y, z = spGetUnitPosition(data.tempTarget)
				for unitID,_ in pairs(data.unit) do
					if not data.aa[unitID] then
						GiveClampedOrderToUnit(unitID, CMD_FIGHT , {x,y,z}, 0)
					end
				end
			else
				data.tempTarget = false
			end
		else
			
			local aX = math.ceil(averageX/heatSquareWidth)
			local aZ = math.ceil(averageZ/heatSquareHeight)
			
			if aX == data.aX and aZ == data.aZ then
				wipeSquareData(a.allyTeam, aX, aZ)
				if data.disbandable then
					for unitID,_ in pairs(data.unit) do
						unitInBattleGroupByID[unitID] = nil
					end
					removeIndexFromArray(battleGroup,i)
					break
				else
					local minTargetDistance = false
					local changed = false
					local x = data.aimX
					local z = data.aimZ
					for j = 1, at.enemyEconomy.count do
						local dis = disSQ(x, z, at.enemyEconomy[j].x, at.enemyEconomy[j].z)
						if (not minTargetDistance) or minTargetDistance > dis and
								not (data.aX == at.enemyEconomy[j].aX and data.aZ == at.enemyEconomy[j].aZ) then
							data.aX = at.enemyEconomy[j].aX
							data.aZ = at.enemyEconomy[j].aZ
							minTargetDistance = dis
							changed = true
						end
					end
					
					if changed then
						data.aimX = heatmapPosition[data.aX][data.aZ].x
						data.aimY = heatmapPosition[data.aX][data.aZ].y
						data.aimZ = heatmapPosition[data.aX][data.aZ].z
						--Spring.MarkerAddPoint(data.aimX,0,data.aimZ, "New Target " .. at.enemyEconomyHeatmap[data.aX][data.aZ].cost)
						data.regroup = false
						local groupRange = 450 + averageCount*30
						local moveGroupRange = groupRange*0.4
						for unitID,_ in pairs(data.unit) do
							if not data.aa[unitID] then
								--GiveClampedOrderToUnit(unitID, CMD_FIGHT , {data.aimX ,data.aimY,data.aimZ,}, 0)
								GiveClampedOrderToUnit(unitID, CMD_FIGHT , {data.aimX + math.random(-moveGroupRange,moveGroupRange),
								data.aimY,data.aimZ + math.random(-moveGroupRange,moveGroupRange),}, 0)
							end
						end
					else
						for unitID,_ in pairs(data.unit) do
							unitInBattleGroupByID[unitID] = nil
						end
						removeIndexFromArray(battleGroup,i)
						break
					end
				end
				
			else
				local groupRange = 450 + averageCount*30
				local moveGroupRange = groupRange*0.4
				
				if data.regroup == true then
					groupRange = 400 + averageCount*20
				end

				if maxX - minX > groupRange or maxZ - minZ > groupRange then
					if (not data.regroup) or slowUpdate then
						
						local aDivX = 0
						local aDivZ = 0
						
						for unitID,_ in pairs(data.unit) do
							local x, y, z = spGetUnitPosition(unitID)
							aDivX = aDivX + math.abs(x - averageX)
							aDivZ = aDivZ + math.abs(z - averageZ)
						end
						aDivX = aDivX/averageCount
						aDivZ = aDivZ/averageCount
						
						if aDivX < 300 and aDivZ < 300 then
							for unitID,_ in pairs(data.unit) do
								local x, y, z = spGetUnitPosition(unitID)
								if math.abs(x-averageX) > aDivX*1.7 and math.abs(z-averageZ) > aDivX*1.7 then
									data.unit[unitID] = nil
									data.aa[unitID] = nil
									unitInBattleGroupByID[unitID] = nil
									--Spring.MarkerAddPoint(x,y,z, "Left Behind")
								end
							end
						end
						
						--[[Spring.MarkerAddPoint(averageX,0,averageZ, "Div")
						Spring.MarkerAddLine(averageX-aDivX,Spring.GetGroundHeight(averageX-aDivX,averageZ-aDivZ),averageZ-aDivZ,
							averageX+aDivX,Spring.GetGroundHeight(averageX+aDivX,averageZ-aDivZ),averageZ-aDivZ)
						Spring.MarkerAddLine(averageX-aDivX,Spring.GetGroundHeight(averageX-aDivX,averageZ+aDivZ),averageZ+aDivZ,
							averageX+aDivX,Spring.GetGroundHeight(averageX+aDivX,averageZ+aDivZ),averageZ+aDivZ)
						Spring.MarkerAddLine(averageX+aDivX,Spring.GetGroundHeight(averageX+aDivX,averageZ-aDivZ),averageZ-aDivZ,
							averageX+aDivX,Spring.GetGroundHeight(averageX+aDivX,averageZ+aDivZ),averageZ+aDivZ)
						Spring.MarkerAddLine(averageX-aDivX,Spring.GetGroundHeight(averageX-aDivX,averageZ-aDivZ),averageZ-aDivZ,
							averageX-aDivX,Spring.GetGroundHeight(averageX-aDivX,averageZ+aDivZ),averageZ+aDivZ)--]]
					end
					data.regroup = true
					for unitID,_ in pairs(data.unit) do
						if not data.aa[unitID] then
							GiveClampedOrderToUnit(unitID, CMD_FIGHT , {averageX,gy,averageZ}, 0)
						end
					end
				else
					if data.regroup == true then
						data.regroup = false
						for unitID,_ in pairs(data.unit) do
							if not data.aa[unitID] then
								--GiveClampedOrderToUnit(unitID, CMD_FIGHT , {data.aimX ,data.aimY,data.aimZ,}, 0)
								GiveClampedOrderToUnit(unitID, CMD_FIGHT , {data.aimX + math.random(-moveGroupRange,moveGroupRange),
								data.aimY,data.aimZ + math.random(-moveGroupRange,moveGroupRange),}, 0)
							end
							
						end
					end
				end
			end
		end
		
	end
	
end

local function raiderJobHandler(team)
	
	local a = aiTeamData[team]
	local at = allyTeamData[a.allyTeam]
	
	local raider = a.controlledUnit.raider
	local raiderByID = a.controlledUnit.raiderByID
	
	local battleGroup = a.battleGroup
	
	local enemyOffenseHeatmap = at.enemyOffenseHeatmap
	local enemyOffense = at.enemyOffense
	local enemyDefenceHeatmap = at.enemyDefenceHeatmap
	local enemyDefence = at.enemyDefence
	local enemyEconomyHeatmap = at.enemyEconomyHeatmap
	local enemyEconomy = at.enemyEconomy
	
	local unitInBattleGroupByID = a.unitInBattleGroupByID
	
	if raider.count == 0 then
		return
	end
	
	local tX = false
	local tY = false
	local tZ = false
	local idleCost = 0
	
	local averageX = 0
	local averageZ = 0
	local averageCount = 0
	
	for unitID,data in pairs(raiderByID) do
		local cQueue = spGetCommandQueue(unitID, 3)
		local retreating = Spring.GetUnitRulesParam(unitID, "retreat") == 1
		if cQueue and (#cQueue == 0 or (#cQueue == 2 and cQueue[1].id == CMD_MOVE_TO_USE)) and data.finished and not unitInBattleGroupByID[unitID] and not retreating then
			local x, y, z = spGetUnitPosition(unitID)
			idleCost = idleCost + data.cost
			averageX = averageX + x
			averageZ = averageZ + z
			averageCount = averageCount + 1
		end
	end

	if averageCount > 0 then
	
		averageX = averageX/averageCount
		averageZ = averageZ/averageCount
		local aX,aZ
		local idleFactor = idleCost/raider.cost
	
		if a.raiderBattlegroupCondition(idleFactor, idleCost) then
			local minCost = false
			
			for i = 1, enemyEconomy.count do
				aX = enemyEconomy[i].aX
				aZ = enemyEconomy[i].aZ
				if enemyOffenseHeatmap[aX][aZ].cost*2 < raider.cost and enemyDefenceHeatmap[aX][aZ].cost*2 < raider.cost then
					if (not minCost) or minCost < enemyEconomyHeatmap[aX][aZ].cost then
						tX = enemyEconomy[i].x
						tY = enemyEconomy[i].y
						tZ = enemyEconomy[i].z
					end
				end
			end
		end
		
		if tX then
			battleGroup.count = battleGroup.count+1
			battleGroup[battleGroup.count] = {
				aimX = tX, aimY = tY, aimZ = tZ,
				aX = aX, aZ = aZ,
				currentX = false, currentZ = false,
				respondToSOSpriority = 1,
				regroup = true,
				unit = {},
				tempTarget = false,
				disbandable = false,
				aa = {},
				neededAA = 0,
			}
			--wipeSquareData(team, aX, aZ)
		end
	end
	
	for unitID,data in pairs(raiderByID) do
		local cQueue = spGetCommandQueue(unitID, 3)
		local retreating = Spring.GetUnitRulesParam(unitID, "retreat") == 1
		if cQueue and (#cQueue == 0 or (#cQueue == 2 and cQueue[1].id == CMD_MOVE_TO_USE)) and data.finished and not retreating then
			local eID = spGetUnitNearestEnemy(unitID,1200)
			if eID and not spGetUnitNeutral(eID) then	-- FIXME: remove in 95.0
				spGiveOrderToUnit(unitID, CMD_ATTACK , {eID}, 0)
			elseif tX and not unitInBattleGroupByID[unitID] then
				--GiveClampedOrderToUnit(unitID, CMD_FIGHT , {tX + math.random(-200,200),tY,tZ + math.random(-200,200),}, 0)
				for i = 1, battleGroup.count do
					if battleGroup[i].unit[unitID] then
						Spring.Log(gadget:GetInfo().name, LOG.WARNING, "Unit already in battle group")
					end
				end
				battleGroup[battleGroup.count].unit[unitID] = true
				unitInBattleGroupByID[unitID] = true
			end
		end
	end
	
end

local function artyJobHandler(team)
	
	local a = aiTeamData[team]
	local at = allyTeamData[a.allyTeam]
	
	local arty = a.controlledUnit.arty
	local artyByID = a.controlledUnit.artyByID
	
	local enemyDefenceHeatmap = at.enemyDefenceHeatmap
	local enemyDefence = at.enemyDefence
	
	if arty.count == 0 then
		return
	end
	
	if enemyDefence.count > 0 then
		for unitID,data in pairs(artyByID) do
			local cQueue = spGetCommandQueue(unitID, 1)
			if cQueue and #cQueue == 0 then
				local randIndex = math.floor(math.random(1,enemyDefence.count))
				GiveClampedOrderToUnit(unitID, CMD_FIGHT , {enemyDefence[randIndex].x,enemyDefence[randIndex].y, enemyDefence[randIndex].z,}, 0)
			end
		end
	end
	
end

local function bomberJobHandler(team)
	
	local a = aiTeamData[team]
	local at = allyTeamData[a.allyTeam]
	
	local bomber = a.controlledUnit.bomber
	local bomberByID = a.controlledUnit.bomberByID
	
	local enemyOffenseHeatmap = at.enemyOffenseHeatmap
	local enemyOffense = at.enemyOffense
	
	if bomber.count == 0 then
		return
	end
	
	if enemyOffense.count > 0 then
		for unitID,data in pairs(bomberByID) do
			local cQueue = spGetCommandQueue(unitID, 1)
			if cQueue and #cQueue == 0 then
				local randIndex = math.floor(math.random(1,enemyOffense.count))
				local static, mobile = getEnemyAntiAirInRange(a.allyTeam, enemyOffense[randIndex].x, enemyOffense[randIndex].z)
				if static*2 + mobile < 600 then
					GiveClampedOrderToUnit(unitID, CMD_FIGHT , {enemyOffense[randIndex].x,enemyOffense[randIndex].y, enemyOffense[randIndex].z,}, 0)
				end
			end
		end
	end
	
end

local function gunshipJobHandler(team)

	local a = aiTeamData[team]
	local at = allyTeamData[a.allyTeam]
	
	local gunship = a.controlledUnit.gunship
	local gunshipByID = a.controlledUnit.gunshipByID
	
	local battleGroup = a.battleGroup
	
	local enemyOffenseHeatmap = at.enemyOffenseHeatmap
	local enemyOffense = at.enemyOffense
	local enemyDefenceHeatmap = at.enemyDefenceHeatmap
	local enemyDefence = at.enemyDefence
	local enemyEconomyHeatmap = at.enemyEconomyHeatmap
	local enemyEconomy = at.enemyEconomy
	
	local unitInBattleGroupByID = a.unitInBattleGroupByID

	if gunship.count == 0 then
		return
	end
	
	local tX = false
	local tY = false
	local tZ = false
	local idleCost = 0
	
	local averageX = 0
	local averageZ = 0
	local averageCount = 0
	
	for unitID,data in pairs(gunshipByID) do
		local cQueue = spGetCommandQueue(unitID, 3)
		local retreating = Spring.GetUnitRulesParam(unitID, "retreat") == 1
		if cQueue and (#cQueue == 0 or (#cQueue == 2 and cQueue[1].id == CMD_MOVE_TO_USE)) and data.finished and not unitInBattleGroupByID[unitID] and not retreating then
			local x, y, z = spGetUnitPosition(unitID)
			idleCost = idleCost + data.cost
			averageX = averageX + x
			averageZ = averageZ + z
			averageCount = averageCount + 1
		end
	end

	if averageCount > 0 then
	
		averageX = averageX/averageCount
		averageZ = averageZ/averageCount
		local aX,aZ
		local idleFactor = idleCost/gunship.cost
	
		if a.gunshipBattlegroupCondition(idleFactor, idleCost) then
			local minCost = false
			
			for i = 1, enemyEconomy.count do
				aX = enemyEconomy[i].aX
				aZ = enemyEconomy[i].aZ
				
				local static, mobile = getEnemyAntiAirInRange(a.allyTeam, enemyEconomy[i].x, enemyEconomy[i].z)
				
				if enemyOffenseHeatmap[aX][aZ].cost*2 < gunship.cost and enemyDefenceHeatmap[aX][aZ].cost*2 < gunship.cost and static*3 + mobile*2 < gunship.cost then
					if (not minCost) or minCost < enemyEconomyHeatmap[aX][aZ].cost then
						tX = enemyEconomy[i].x
						tY = enemyEconomy[i].y
						tZ = enemyEconomy[i].z
					end
				end
			end
		end
		
		if tX then
			battleGroup.count = battleGroup.count+1
			battleGroup[battleGroup.count] = {
				aimX = tX, aimY = tY, aimZ = tZ,
				aX = aX, aZ = aZ,
				currentX = false, currentZ = false,
				respondToSOSpriority = 1,
				regroup = true,
				unit = {},
				tempTarget = false,
				disbandable = true,
				aa = {},
				neededAA = 0,
			}
			--wipeSquareData(team, aX, aZ)
		end
	end
	
	for unitID,data in pairs(gunshipByID) do
		local cQueue = spGetCommandQueue(unitID, 3)
		local retreating = Spring.GetUnitRulesParam(unitID, "retreat") == 1
		if cQueue and (#cQueue == 0 or (#cQueue == 2 and cQueue[1].id == CMD_MOVE_TO_USE)) and data.finished and not retreating then
			local eID = spGetUnitNearestEnemy(unitID,1200)
			if eID and not spGetUnitNeutral(eID) then	-- FIXME: remove in 95.0
				spGiveOrderToUnit(unitID, CMD_ATTACK , {eID}, 0)
			elseif tX and not unitInBattleGroupByID[unitID] then
				--GiveClampedOrderToUnit(unitID, CMD_FIGHT , {tX + math.random(-200,200),tY,tZ + math.random(-200,200),}, 0)
				for i = 1, battleGroup.count do
					if battleGroup[i].unit[unitID] then
						Spring.Log(gadget:GetInfo().name, LOG.WARNING, "Unit already in battle group")
					end
				end
				battleGroup[battleGroup.count].unit[unitID] = true
				unitInBattleGroupByID[unitID] = true
			end
		end
	end

end

local function fighterJobHandler(team)
	
	local a = aiTeamData[team]
	local at = allyTeamData[a.allyTeam]
	local target = at.fighterTarget
	
	local fighter = a.controlledUnit.fighter
	local fighterByID = a.controlledUnit.fighterByID
	
	if fighter.count == 0 or not at.fighterTarget then
		return
	end
	
	if spValidUnitID( at.fighterTarget) then
		for unitID,data in pairs(fighterByID) do
			local cQueue = spGetCommandQueue(unitID, 1)
			if cQueue and #cQueue == 0 then
				spGiveOrderToUnit(unitID, CMD_ATTACK , { at.fighterTarget}, 0)
			end
		end
	else
		 at.fighterTarget = nil
	end
	
end

local function combatJobHandler(team)
	
	local a = aiTeamData[team]
	local at = allyTeamData[a.allyTeam]
	
	local combat = a.controlledUnit.combat
	local combatByID = a.controlledUnit.combatByID
	
	local battleGroup = a.battleGroup
	
	local enemyOffenseHeatmap = at.enemyOffenseHeatmap
	local enemyOffense = at.enemyOffense
	local enemyDefenceHeatmap = at.enemyDefenceHeatmap
	local enemyDefence = at.enemyDefence
	local enemyEconomyHeatmap = at.enemyEconomyHeatmap
	local enemyEconomy = at.enemyEconomy
	
	local unitInBattleGroupByID = a.unitInBattleGroupByID

	if combat.count == 0 then
		return
	end
	
	local tX = false
	local tY = false
	local tZ = false
	local idleCost = 0
	
	local averageX = 0
	local averageZ = 0
	local averageCount = 0

	for unitID,data in pairs(combatByID) do
		local cQueue = spGetCommandQueue(unitID, 3)
		local retreating = Spring.GetUnitRulesParam(unitID, "retreat") == 1
		if cQueue and (#cQueue == 0 or (#cQueue == 2 and cQueue[1].id == CMD_MOVE_TO_USE)) and data.finished and not unitInBattleGroupByID[unitID] and not retreating then
			local x, y, z = spGetUnitPosition(unitID)
			idleCost = idleCost + data.cost
			averageX = averageX + x
			averageZ = averageZ + z
			averageCount = averageCount + 1
		end
	end
	
	if averageCount > 0 then
	
		averageX = averageX/averageCount
		averageZ = averageZ/averageCount
		local aX,aZ
		local idleFactor = idleCost/combat.cost

		if a.combatBattlegroupCondition(idleFactor, idleCost) then
			local minTargetDistance = false
			
			for i = 1, enemyOffense.count do
				aX = enemyOffense[i].aX
				aZ = enemyOffense[i].aZ
				
				if enemyOffenseHeatmap[aX][aZ].cost*2 < combat.cost and enemyDefenceHeatmap[aX][aZ].cost < combat.cost then
					if (not minTargetDistance) or minTargetDistance > disSQ(averageX,averageZ,enemyOffense[i].x,enemyOffense[i].z) then
						tX = enemyOffense[i].x
						tY = enemyOffense[i].y
						tZ = enemyOffense[i].z
					end
				end
			end
			
			for i = 1, enemyEconomy.count do
				aX = enemyEconomy[i].aX
				aZ = enemyEconomy[i].aZ
				
				if enemyOffenseHeatmap[aX][aZ].cost*2 < combat.cost and enemyDefenceHeatmap[aX][aZ].cost < combat.cost then
					if (not minTargetDistance) or minTargetDistance > disSQ(averageX,averageZ,enemyEconomy[i].x,enemyEconomy[i].z) then
						tX = enemyEconomy[i].x
						tY = enemyEconomy[i].y
						tZ = enemyEconomy[i].z
					end
				end
			end
			
			if not tX then
				for i = 1, enemyDefence.count do
					aX = enemyDefence[i].aX
					aZ = enemyDefence[i].aZ
					
					if enemyOffenseHeatmap[aX][aZ].cost < combat.cost and enemyDefenceHeatmap[aX][aZ].cost*2 < combat.cost then
						if (not minTargetDistance) or minTargetDistance > disSQ(averageX,averageZ,enemyDefence[i].x,enemyDefence[i].z) then
							tX = enemyDefence[i].x
							tY = enemyDefence[i].y
							tZ = enemyDefence[i].z
						end
					end
				end
			end
		end

		if tX then
			battleGroup.count = battleGroup.count+1
			battleGroup[battleGroup.count] = {
				aimX = tX, aimY = tY, aimZ = tZ,
				aX = aX, aZ = aZ,
				currentX = false, currentZ = false,
				respondToSOSpriority = 0,
				regroup = true,
				unit = {},
				tempTarget = false,
				disbandable = false,
				aa = {},
				neededAA = idleCost/5,
			}
			--Spring.MarkerAddPoint(averageX,0,averageZ,"battlegroup created")
			gatherBattlegroupNeededAA(team,battleGroup.count)
			--wipeSquareData(team,aX, aZ)
		end
	end
	
	for unitID,data in pairs(combatByID) do
		local cQueue = spGetCommandQueue(unitID, 3)
		local retreating = Spring.GetUnitRulesParam(unitID, "retreat") == 1
		if cQueue and (#cQueue == 0 or (#cQueue == 2 and cQueue[1].id == CMD_MOVE_TO_USE)) and data.finished and not retreating then
			local eID = spGetUnitNearestEnemy(unitID,1200)
			if eID and not spGetUnitNeutral(eID) then	-- FIXME: remove in 95.0
				spGiveOrderToUnit(unitID, CMD_ATTACK , {eID}, 0)
			elseif tX and not unitInBattleGroupByID[unitID] then
				--GiveClampedOrderToUnit(unitID, CMD_FIGHT , {tX + math.random(-300,300),tY,tZ + math.random(-300,300),}, 0)
				for i = 1, battleGroup.count do
					if battleGroup[i].unit[unitID] then
						Spring.Echo("Unit already in battle group")
					end
				end
				battleGroup[battleGroup.count].unit[unitID] = true
				unitInBattleGroupByID[unitID] = true
			end
		end
	end
	
end

local function scoutJobHandler(team)

	local a = aiTeamData[team]
	local at = allyTeamData[a.allyTeam]
	
	local scoutByID = a.controlledUnit.scoutByID
	
	local unScoutedPoint = at.unScoutedPoint
	if unScoutedPoint.count > 0 then
		for unitID,data in pairs(scoutByID) do
			local cQueue = spGetCommandQueue(unitID, 1)
			if cQueue and #cQueue == 0 then
				local randIndex = math.floor(math.random(1,unScoutedPoint.count))
				GiveClampedOrderToUnit(unitID, CMD_FIGHT , {unScoutedPoint[randIndex].x,unScoutedPoint[randIndex].y,unScoutedPoint[randIndex].z}, 0)
			end

		end
	end
	
end

-- updates the scouted state of the map
local function updateScoutingHeatmap(allyTeam,frame,removeEmpty)

	local at = allyTeamData[allyTeam]
	
	local scoutingHeatmap = at.scoutingHeatmap
	local unScoutedPoint = at.unScoutedPoint

	unScoutedPoint.count = 0
	
	for i = 1, heatArrayWidth do -- init array
		for j = 1, heatArrayHeight do
			local data = scoutingHeatmap[i][j]
			if spIsPosInLos(heatmapPosition[i][j].x,0,heatmapPosition[i][j].z,allyTeam) then
				if debugData.drawScoutmap[allyTeam] and not data.scouted then
					--Spring.MarkerAddPoint(heatmapPosition[i][j].x,0,heatmapPosition[i][j].z,"now scouted")
				end
				if removeEmpty then -- called infrequently
					local units = CallAsTeam(at.aTeamOnThisTeam,
						function ()
							return spGetUnitsInRectangle(
									heatmapPosition[i][j].left,heatmapPosition[i][j].top,
									heatmapPosition[i][j].right, heatmapPosition[i][j].bottom)
						end
					)
					local empty = true
					for u = i, #units do
						if spGetUnitAllyTeam(units[u]) ~= allyTeam then
							empty = false
							break
						end
					end
					if empty then
						--Spring.MarkerAddPoint(heatmapPosition[i][j].x,0,heatmapPosition[i][j].z,"econ removed")
						if scoutingHeatmap[i][j].previouslyEmpty then
							wipeSquareData(allyTeam, i, j)
						else
							scoutingHeatmap[i][j].previouslyEmpty = true
						end
					else
						scoutingHeatmap[i][j].previouslyEmpty = false
					end
				end
				
				data.scouted = true
				data.lastScouted = frame
			else
				if frame - data.lastScouted > 2000 then
					unScoutedPoint.count = unScoutedPoint.count + 1
					unScoutedPoint[unScoutedPoint.count] = {x = heatmapPosition[i][j].x, y = heatmapPosition[i][j].y, z = heatmapPosition[i][j].z}
					if j <= 2 or heatArrayHeight-j <= 2 then -- weight scouting towards the edges
						unScoutedPoint.count = unScoutedPoint.count + 1
						unScoutedPoint[unScoutedPoint.count] = {x = heatmapPosition[i][j].x, y = heatmapPosition[i][j].y, z = heatmapPosition[i][j].z}
					end
					if i <= 2 or heatArrayWidth-i <= 2 then -- twice really weights towards the corners
						unScoutedPoint.count = unScoutedPoint.count + 1
						unScoutedPoint[unScoutedPoint.count] = {x = heatmapPosition[i][j].x, y = heatmapPosition[i][j].y, z = heatmapPosition[i][j].z}
					end
					data.scouted = false
					if debugData.drawScoutmap[allyTeam] then
						--Spring.MarkerErasePosition (heatmapPosition[i][j].x,0,heatmapPosition[i][j].z)
					end
				end
				
			end
		end
	end
end


-- decays offensive heatmap as it will likely move
local function decayEnemyHeatmaps(allyTeam,frame)

	local at = allyTeamData[allyTeam]
	
	local enemyOffense = at.enemyOffense
	local enemyOffenseHeatmap = at.enemyOffenseHeatmap
	local scoutingHeatmap = at.scoutingHeatmap

	for i = 1,enemyOffense.count do
		local aX = enemyOffense[i].aX
		local aZ = enemyOffense[i].aZ
		local data = scoutingHeatmap[aX][aZ]
		if frame - data.lastScouted > 2000 then
			removeValueFromHeatmap(enemyOffense, enemyOffenseHeatmap, aX, aZ)
			break
		end
	end

end

local function decayEnemyMobileAA(allyTeam,frame)

	local at = allyTeamData[allyTeam]
	local enemyMobileAA = at.enemyMobileAA

	for unitID,data in pairs(enemyMobileAA) do
		if frame - data.spottedFrame > 2000 then
			enemyMobileAA[unitID] = nil
		end
	end

end

local function diluteEnemyForceComposition(allyTeam)
	
	-- adds it's own mIncome to enemy force composition
	local at = allyTeamData[allyTeam]
	local mInc = 0
	local aiCount = 0
	
	for team,_ in pairs(at.teams)  do
		if aiTeamData[team] then
			mInc = mInc + aiTeamData[team].averagedEcon.aveMInc
			aiCount = aiCount + 1
		end
	end
	
	mInc = mInc/aiCount * 0.3
	
	local totalCost = 0
	
	-- strange algorithm!! put actual thought into one
	for index,_ in pairs(at.enemyForceComposition.unit) do
		at.enemyForceComposition.unit[index] = at.enemyForceComposition.unit[index] + mInc
		totalCost = totalCost + at.enemyForceComposition.unit[index]
		--value = (value-1000)*0.95 + 1000
	end
	
	for index,value in pairs(at.relativeEnemyForceComposition.unit) do
		at.relativeEnemyForceComposition.unit[index] = at.enemyForceComposition.unit[index]/totalCost*9
	end
end

local function addValueToHeatmap(indexer,heatmap, value, aX, aZ)
	if value > 0 and heatmap[aX] and heatmap[aX][aZ] then
		if heatmap[aX][aZ].cost == 0 then
			indexer.count = indexer.count + 1
			indexer[indexer.count] = {x = heatmapPosition[aX][aZ].x, y = heatmapPosition[aX][aZ].y, z = heatmapPosition[aX][aZ].z, aX = aX, aZ = aZ}
			heatmap[aX][aZ].index = indexer.count
		end
		indexer.totalCost = indexer.totalCost + value
		heatmap[aX][aZ].cost = heatmap[aX][aZ].cost + value
	end
end

local function addValueToHeatmapInArea(indexer,heatmap, value, x, z)

	local aX = math.ceil(x/heatSquareWidth)
	local aZ = math.ceil(z/heatSquareHeight)
	
	local aX2, aZ2
	
	local sXfactor = 1
	local sZfactor = 1
	
	if (aX-0.5)*heatSquareWidth > x then
		if aX == 1 then
			aX2 = 1
		else
			aX2 = aX - 1
			sXfactor = (aX-0.5) - x/heatSquareWidth
		end
	else
		if aX == heatArrayWidth then
			aX2 = heatArrayWidth
		else
			aX2 = aX + 1
			sXfactor = x/heatSquareWidth - (aX-0.5)
		end
	end
	
	if (aZ-0.5)*heatSquareHeight > z then
		if aZ == 1 then
			aZ2 = 1
		else
			aZ2 = aZ - 1
			sZfactor = (aZ-0.5) - z/heatSquareHeight
		end
	else
		if aZ == heatArrayHeight then
			aZ2 = heatArrayHeight
		else
			aZ2 = aZ + 1
			sZfactor = z/heatSquareHeight - (aZ-0.5)
		end
	end
	
	addValueToHeatmap(indexer, heatmap, value*(sXfactor + sZfactor)*0.5, aX, aZ)
	addValueToHeatmap(indexer, heatmap, value*((1-sXfactor) + sZfactor)*0.5, aX2, aZ)
	addValueToHeatmap(indexer, heatmap, value*(sXfactor + (1-sZfactor))*0.5, aX, aZ2)
	addValueToHeatmap(indexer, heatmap, value*((1-sXfactor) + (1-sZfactor))*0.5, aX2, aZ2)
	
end

local function editDefenceHeatmap(team,unitID,groundArray,airArray,range,sign,priority)

	local a = aiTeamData[team]
	local ux,uy,uz = spGetUnitPosition(unitID)
	local buildDefs = a.buildDefs
	
	local aX = math.ceil(ux/heatSquareWidth)
	local aZ = math.ceil(uz/heatSquareHeight)
	local selfDefenceHeatmap = a.selfDefenceHeatmap
	local selfDefenceAirTask = a.selfDefenceAirTask
	local wantedDefence = a.wantedDefence
	local defenceChoice = buildDefs.defenceIds
	
	
	for i = 1, buildDefs.airDefenceIdCount do
		local oldValue = selfDefenceHeatmap[aX][aZ][i].air
		selfDefenceHeatmap[aX][aZ][i].air = selfDefenceHeatmap[aX][aZ][i].air + airArray[i]*sign
		if sign > 0 then
			if oldValue < 1 and selfDefenceHeatmap[aX][aZ][i].air >= 1 and selfDefenceHeatmap[aX][aZ][i].airTask == 0 then
				selfDefenceAirTask.count = selfDefenceAirTask.count + 1
				selfDefenceAirTask[selfDefenceAirTask.count] = {aX = aX, aZ = aZ, x = ux, z = uz}
				selfDefenceHeatmap[aX][aZ][i].airTask = selfDefenceAirTask.count
			end
		else
			if oldValue >= 1 and selfDefenceHeatmap[aX][aZ][i].air < 1 and selfDefenceHeatmap[aX][aZ][i].airTask ~= 0 then
				removeIndexFromArray(selfDefenceAirTask,selfDefenceHeatmap[aX][aZ][i].airTask)
				selfDefenceHeatmap[aX][aZ][i].airTask = 0
			end
		end
	
	end
	
	for i = 1, buildDefs.defenceIdCount do
		selfDefenceHeatmap[aX][aZ][i].total = selfDefenceHeatmap[aX][aZ][i].total + groundArray[i]*sign
		
		if sign > 0 then
			selfDefenceHeatmap[aX][aZ][i].toBuild = selfDefenceHeatmap[aX][aZ][i].toBuild + groundArray[i]*sign
		
			local oldX = false
			local oldZ = false
			local x, z, ox, oz,searchRange
		
			while selfDefenceHeatmap[aX][aZ][i].toBuild >= 1 do
				
				local deID = chooseUnitDefID(defenceChoice[i])
				local success = true
				
				if oldX then
					x = 2*ux - oldX
					z = 2*uz - oldZ
					ox = x
					oz = z
					searchRange = 0
				else
					searchRange = range
					x = ux + math.random(-searchRange,searchRange)
					z = uz + math.random(-searchRange,searchRange)
					ox = ux
					oz = uz
				end
			
				while (spTestBuildOrder(deID, x, 0 ,z, 1) == 0 or not IsTargetReallyReachable(unitID, x, 0 ,z,ux,uy,uz)) or nearEcon(team,x,z,50) or nearFactory(team,x,z,200) or nearMexSpot(x,z,60) or nearDefence(team,x,z,140) do
					x = ox + math.random(-searchRange,searchRange)
					z = oz + math.random(-searchRange,searchRange)
					searchRange = searchRange + 10
					if searchRange > range+300 then
						success = false
						break
					end
				end
				
				if success then
					wantedDefence.count = wantedDefence.count + 1
					wantedDefence[wantedDefence.count] = {ID = deID, x = x, z = z, priority = priority}
					oldX = x
					oldZ = z
					--if priority ~= 0 then
						--Spring.MarkerAddPoint(x,0,z,"Defence Added")
					--end
				end
				
				selfDefenceHeatmap[aX][aZ][i].toBuild = selfDefenceHeatmap[aX][aZ][i].toBuild - 1
			end
		end
	end
	
end

local function callForMobileDefence(team ,unitID, attackerID, callRange, priority)

	local a = aiTeamData[team]
	local at = allyTeamData[a.allyTeam]
	
	--SOS code
	if not a.sosTimeout[unitID] or a.sosTimeout[unitID] < gameframe then
		if UnitDefs[Spring.GetUnitDefID(unitID)].commander then callRange = callRange * 2 end
		a.sosTimeout[unitID] = gameframe + SOS_TIME
		local dx, dy, dz = spGetUnitPosition(attackerID)
		local friendlies = spGetUnitsInCylinder(dx, dz, callRange, team)
		if friendlies then
			for i=1, #friendlies do
				local fid = friendlies[i]
				local retreating = Spring.GetUnitRulesParam(fid, "retreat") == 1
				if (a.controlledUnit.combatByID[fid] or a.controlledUnit.raiderByID[fid]) and (not a.unitInBattleGroupByID[fid]) and not retreating then
					GiveClampedOrderToUnit(fid, CMD_FIGHT, { dx, 0, dz }, 0)
				end
			end
		end
		local battleGroup = a.battleGroup
		for i = 1, battleGroup.count do
			if battleGroup[i].respondToSOSpriority <= priority and disSQ(dx, battleGroup[i].aX, dz, battleGroup[i].aZ) < callRange^2 then
				battleGroup[i].tempTarget = attackerID
			end
		end
	end
	
end

local function spotEnemyUnit(allyTeam, unitID, unitDefID,readd)

	local at = allyTeamData[allyTeam]

	local enemyOffenseHeatmap = at.enemyOffenseHeatmap
	local enemyOffense = at.enemyOffense
	local enemyDefenceHeatmap = at.enemyDefenceHeatmap
	local enemyDefence = at.enemyDefence
	local enemyEconomyHeatmap = at.enemyEconomyHeatmap
	local enemyEconomy = at.enemyEconomy

	local ud = UnitDefs[unitDefID]

	if readd then
		--mapEcho(unitID, "added heatmap")
	end
	
	if readd or (not at.unitInHeatmap[unitID]) then
		--mapEcho(unitID, "added heatmap")
		local x, y, z = spGetUnitPosition(unitID)
		local aX = math.ceil(x/heatSquareWidth)
		local aZ = math.ceil(z/heatSquareHeight)
		
		if ud.maxWeaponRange > 0 then -- combat
			at.enemyForceComposition.totalCost = at.enemyForceComposition.totalCost + ud.metalCost
			if ud.weapons[1].onlyTargets.land then
				if not ud.isImmobile then -- offense
					addValueToHeatmap(enemyOffense,enemyOffenseHeatmap, ud.metalCost, aX, aZ)
				else -- defence
					addValueToHeatmapInArea(enemyDefence,enemyDefenceHeatmap, ud.metalCost, x, z)
				end
			end
		elseif ud.buildSpeed > 0 or ud.isFactory or (ud.customParams.income_energy or ud.energyMake > 0 or tonumber(ud.customParams.upkeep_energy or 0) < 0) or ud.customParams.ismex then -- econ
			addValueToHeatmap(enemyEconomy, enemyEconomyHeatmap, ud.metalCost, aX, aZ)
		end
		
	end
	
	if not at.unitInHeatmap[unitID] then
		--mapEcho(unitID, "added composition")
		at.unitInHeatmap[unitID] = true
		
		local x, y, z = spGetUnitPosition(unitID)
		local aX = math.ceil(x/heatSquareWidth)
		local aZ = math.ceil(z/heatSquareHeight)
		
		if ud.maxWeaponRange > 0 then -- combat
			at.enemyForceComposition.totalCost = at.enemyForceComposition.totalCost + ud.metalCost
			if not ud.isImmobile then -- offense
				if ud.canFly then
					at.enemyForceComposition.unit.air = at.enemyForceComposition.unit.air + ud.metalCost
					at.enemyHasAir = true
				else
					if ud.weapons[1].onlyTargets.land then
						-- Add to enemy force composition by checking against a table.
						if assaultArray[unitDefID] then
							at.enemyForceComposition.unit.assault = at.enemyForceComposition.unit.assault + ud.metalCost
						elseif skirmArray[unitDefID] then
							at.enemyForceComposition.unit.skirm = at.enemyForceComposition.unit.skirm + ud.metalCost
						elseif riotArray[unitDefID] then
							at.enemyForceComposition.unit.riot = at.enemyForceComposition.unit.riot + ud.metalCost
						elseif raiderArray[unitDefID] then
							at.enemyForceComposition.unit.raider = at.enemyForceComposition.unit.raider + ud.metalCost
						elseif artyArray[unitDefID] then
							at.enemyForceComposition.unit.arty = at.enemyForceComposition.unit.arty + ud.metalCost
						end
						--Spring.MarkerAddPoint(heatmapPosition[aX][aZ].x,0,heatmapPosition[aX][aZ].z,data.cost)
					else
						at.enemyForceComposition.unit.antiAir = at.enemyForceComposition.unit.antiAir + ud.metalCost
					end
				end
			else -- defence
				if ud.weapons[1].onlyTargets.land then
					at.enemyForceComposition.unit.groundDefence = at.enemyForceComposition.unit.groundDefence + ud.metalCost
				else
					at.enemyStaticAA[unitID] = {x = x, z = z, rangeSQ = ud.maxWeaponRange^2, range = ud.maxWeaponRange, cost = ud.metalCost}
					at.enemyForceComposition.unit.airDefence = at.enemyForceComposition.unit.airDefence + ud.metalCost
				end
			end
		elseif ud.buildSpeed > 0 or ud.isFactory or (ud.customParams.income_energy or ud.energyMake > 0 or tonumber(ud.customParams.upkeep_energy or 0) < 0) or ud.customParams.ismex then -- econ
			
		end
	end
	
	if ud.canFly and not ud.isFighter then
		at.fighterTarget = unitID
	end
	
	if ud.maxWeaponRange > 0 and (not ud.weapons[1].onlyTargets.land) and not ud.isImmobile then
		at.enemyMobileAA[unitID] = {x = x, z = z, rangeSQ = ud.maxWeaponRange^2, range = ud.maxWeaponRange, cost = ud.metalCost, spottedFrame = gameframe}
	end

end

function gadget:UnitDamaged(unitID, unitDefID, unitTeam, damage, paralyzer, weaponID, attackerID, attackerDefID, attackerTeam)

	if (not aiTeamData[unitTeam]) or allyTeamData[aiTeamData[unitTeam].allyTeam].teams[attackerTeam] then
		return
	end
	
	local a = aiTeamData[unitTeam]
	
	if attackerID then
		if jumperArray[unitDefID] then
			local ud = UnitDefs[attackerDefID]
			if not ud.canFly then
				local jump = spGetUnitRulesParam(unitID, "jumpReload")
				if ((not jump) or jump == 1) and spGetUnitSeparation(unitID, attackerID, true) < jumpDefs[unitDefID].range + 100 then
					local cQueue = spGetCommandQueue(unitID, 1)
					if cQueue and (#cQueue == 0 or cQueue[1].id ~= CMD_JUMP) then
						local x,y,z = spGetUnitPosition(attackerID)
						GiveClampedOrderToUnit(unitID, CMD_JUMP, {x+math.random(-30,30),y,z+math.random(-30,30)}, CMD.OPT_ALT )
					end
				end
			end
		end
	
		spotEnemyUnit(a.allyTeam, attackerID, attackerDefID, false)
	
		if prioritySosArray[unitDefID] then
			callForMobileDefence(unitTeam, unitID, attackerID, PRIORITY_SOS_RADIUS, 1)
		else
			callForMobileDefence(unitTeam, unitID, attackerID, SOS_RADIUS, 0)
		end
		
	
		if a.controlledUnit.conByID[unitID] and not a.controlledUnit.conByID[unitID].makingDefence then
			local ud = UnitDefs[attackerDefID]
			if ud.isImmobile then
				makeReponsiveDefence(unitTeam,unitID,attackerID,attackerDefID,200)
			else
				runAway(unitID,attackerID,500)
			end
		end
	end

end

--update scout heatmap and add spotted enemy to enemy-stat counter
function gadget:UnitEnteredLos(unitID, unitTeam, allyTeam, unitDefID)

	if not allyTeamData[allyTeam].ai then
		return
	end
	local at = allyTeamData[allyTeam]
	
	at.inLOS[unitID] = true --remember temporarily until UnitLeftLos
	
	local scoutingHeatmap = at.scoutingHeatmap
	
	local x, y, z = spGetUnitPosition(unitID)
	local aX = math.ceil(x/heatSquareWidth)
	local aZ = math.ceil(z/heatSquareHeight)
	
	--[[if (scoutingHeatmap[aX] and scoutingHeatmap[aX][aZ]) then -- unit outside map
		scoutingHeatmap[aX][aZ].scouted = true
		scoutingHeatmap[aX][aZ].lastScouted = frame
	end--]]
	
	if (scoutingHeatmap[aX] and scoutingHeatmap[aX][aZ]) then
		spotEnemyUnit(allyTeam,unitID,unitDefID,true)
	end
end

function gadget:UnitLeftLos(unitID, unitTeam, allyTeam, unitDefID)
	if not allyTeamData[allyTeam].ai then
		return
	end
	local at = allyTeamData[allyTeam]
	
	at.inLOS[unitID] = nil
end

local function drawHeatmap(heatmap)

	for i = 1,heatArrayWidth do -- init array
		for j = 1, heatArrayHeight do
			local cost = heatmap[i][j].cost
			if cost > 0 then
				Spring.MarkerAddPoint(heatmapPosition[i][j].x,0,heatmapPosition[i][j].z,cost)
			else
				Spring.MarkerErasePosition(heatmapPosition[i][j].x,0,heatmapPosition[i][j].z)
			end
		end
	end

end

local function checkHeatmap(heatmap, indexer, name, team)
	for i = 1, indexer.count do -- init array
		local cost = heatmap[indexer[i].aX][indexer[i].aZ].cost
		if cost == 0 then
			Spring.MarkerAddPoint(indexer[i].x,0,indexer[i].z, "0 cost! " .. name .. ", allyTeam " .. team)
		else
			if heatmap[indexer[i].aX][indexer[i].aZ].index ~= i then
				Spring.MarkerAddPoint(indexer[i].x,0,indexer[i].z, "Index Mismatch from indexer")
			end
		end
	end
	
	for i = 1,heatArrayWidth do -- init array
		for j = 1, heatArrayHeight do
			if heatmap[i][j].cost ~= 0 then
				if heatmap[i][j].index == 0 then
					Spring.MarkerAddPoint(heatmapPosition[i][j].x,0,heatmapPosition[i][j].z, "Zero Index")
				end
				if not indexer[heatmap[i][j].index] == 0 then
					Spring.MarkerAddPoint(heatmapPosition[i][j].x,0,heatmapPosition[i][j].z, "Null Indexer")
				elseif indexer[heatmap[i][j].index].aX ~= i or indexer[heatmap[i][j].index].aZ ~= j then
					Spring.MarkerAddPoint(heatmapPosition[i][j].x,0,heatmapPosition[i][j].z, "Index Mismatch from heatmap")
				end
			end
		end
	end
	
end

local function drawHeatmapIndex(heatmap, indexer)
	for i = 1, indexer.count do -- init array
		Spring.MarkerAddPoint(indexer[i].x,0,indexer[i].z, heatmap[indexer[i].aX][indexer[i].aZ].cost)
	end
end

local function initialiseFaction(team)

	local a = aiTeamData[team]
	if a.buildDefs then
		return true
	end
	
	a.buildDefs = a.buildConfig.robots
	return true
end

local function echoEnemyForceComposition(allyTeam)
	local at = allyTeamData[allyTeam]
	Spring.Echo("")
	for index,value in pairs(at.relativeEnemyForceComposition.unit) do
		Spring.Echo(index .. " \t\t" .. value .. "\t\t" .. at.enemyForceComposition.unit[index])
	end
end

local function echoConJobList(team)
	local data = aiTeamData[team]
	Spring.Echo("")
	for index,value in pairs(data.conJob) do
		Spring.Echo(conJobNames[index] .. "   " .. math.floor(value.importance*1000) .. "   " .. value.assignedBP)
	end
end

local function echoFacJobList(team)
	local data = aiTeamData[team]
	Spring.Echo("")
	for index,value in ipairs(data.facJob) do
		Spring.Echo(factoryJobNames[index] .. "   " .. math.floor(value.importance*1000))
	end
	Spring.Echo("")
	for index,value in ipairs(data.facJobAir) do
		Spring.Echo(airFactoryJobNames[index] .. "   " .. math.floor(value.importance*1000))
	end
end

function gadget:GameFrame(n)
	gameframe = n
	for team,data in pairs(aiTeamData) do
	
		initialiseFaction(team)
		
		if not data.suspend then
		
			if n%60 == 0 + team then
				updateTeamResourcing(team)
				executeControlFunction(team, n)
				conJobAllocator(team)
			end
			
			if n%40 == 15 + team then
				battleGroupHandler(team, n, n%200 == 15)
			end
			
			if n%40 == (35 + team)%40 then
				raiderJobHandler(team)
				combatJobHandler(team)
				artyJobHandler(team)
				bomberJobHandler(team)
				fighterJobHandler(team)
				gunshipJobHandler(team)
			end
			
			if n%30 == 0 + team then
				conJobHandler(team)
				factoryJobHandler(team)
				scoutJobHandler(team)
			end
			
			if n%200 == 0 + team then
				if debugData.showConJobList[team] then
					echoConJobList(team)
				end
				if debugData.showFacJobList[team] then
					echoFacJobList(team)
				end
				local isDead = select(3, spGetTeamInfo(team, false))
				if isDead then
					aiTeamData[team] = nil	-- team is dead, stop working
				end
			end
		
		end
		
	end
	
	for allyTeam,data in pairs(allyTeamData) do
		
		if n%50 == 25 + allyTeam then
			if data.ai then
				updateScoutingHeatmap(allyTeam,n, n%500 == 25)
			end
		end
	
		if n%200 == 0 + allyTeam then
			if debugData.showEnemyForceCompostion[team] then
				echoEnemyForceComposition(allyTeam)
			end
		end
	
		if n%120 == 30 + allyTeam then
			if data.ai then
			
				decayEnemyHeatmaps(allyTeam,n)
				decayEnemyMobileAA(allyTeam,n)
				diluteEnemyForceComposition(allyTeam)
				
				-- DEBUG functions, check entire heatmap index consistency. They look slow
				--checkHeatmap(allyTeamData[allyTeam].enemyOffenseHeatmap, allyTeamData[allyTeam].enemyOffense,allyTeam,"Offense")
				--checkHeatmap(allyTeamData[allyTeam].enemyEconomyHeatmap, allyTeamData[allyTeam].enemyEconomy,allyTeam,"Economy")
				--checkHeatmap(allyTeamData[allyTeam].enemyDefenceHeatmap, allyTeamData[allyTeam].enemyDefence,allyTeam,"Defence")
				
				if debugData.drawOffensemap[allyTeam] then
					drawHeatmapIndex(allyTeamData[allyTeam].enemyOffenseHeatmap, allyTeamData[allyTeam].enemyOffense)
				end
				if debugData.drawEconmap[allyTeam] then
					drawHeatmapIndex(allyTeamData[allyTeam].enemyEconomyHeatmap, allyTeamData[allyTeam].enemyEconomy)
				end
				if debugData.drawDefencemap[allyTeam] then
					drawHeatmapIndex(allyTeamData[allyTeam].enemyDefenceHeatmap, allyTeamData[allyTeam].enemyDefence)
				end
			end
		end
		
	end
end

function gadget:UnitGiven(unitID, unitDefID, teamID, oldTeamID)
	gadget:UnitDestroyed(unitID, unitDefID, oldTeamID)
	gadget:UnitCreated(unitID, unitDefID, teamID)
	local _,_,_,_,build = spGetUnitHealth(unitID)
	if build == 1 then -- will catch reverse build, UnitFinished will not ever be called for this unit
		gadget:UnitFinished(unitID, unitDefID, team)
	end
end

--reduce owned-unit stat counter by 1 unit or enemy-stat counter by 1 unit
local function ProcessUnitDestroyed(unitID, unitDefID, unitTeam, changeAlly)
	local allyTeam = spGetUnitAllyTeam(unitID)
	local ud = UnitDefs[unitDefID]

	if (aiTeamData[unitTeam]) then
		
		local a = aiTeamData[unitTeam]
		local controlledUnit = a.controlledUnit

		if (ud ~= nil) and initialiseFaction(unitTeam) and controlledUnit.anyByID[unitID] then
			local buildDefs = a.buildDefs
			if unitDefID == buildDefs.airpadDefID then
				controlledUnit.airpad.cost = controlledUnit.airpad.cost - ud.metalCost
				controlledUnit.airpad.count = controlledUnit.airpad.count - 1
				controlledUnit.airpadByID[unitID] = nil
			elseif ud.customParams.ismex and buildDefs.econByDefId[unitDefID] then
				if controlledUnit.mexByID[unitID].onDefenceHeatmap then
					editDefenceHeatmap(unitTeam,unitID,buildDefs.econByDefId[unitDefID].defenceQuota,buildDefs.econByDefId[unitDefID].airDefenceQuota,buildDefs.econByDefId[unitDefID].defenceRange,-1,0)
				end
				controlledUnit.mex.cost = controlledUnit.mex.cost - ud.metalCost
				local index = controlledUnit.mexByID[unitID].index
				controlledUnit.mexByID[controlledUnit.mex[controlledUnit.mex.count]].index = index
				controlledUnit.mexByID[unitID] = nil
				removeIndexFromArray(controlledUnit.mex,index)
			elseif ud.isFactory and buildDefs.factoryByDefId[unitDefID] then -- factory
				local data = controlledUnit.factoryByID[unitID]
				if data.retreatPointSet then
					GG.Retreat_ToggleHaven(unitTeam, data.nanoX, data.nanoZ)
				end
				if controlledUnit.factoryByID[unitID].onDefenceHeatmap then
					editDefenceHeatmap(unitTeam,unitID,buildDefs.factoryByDefId[unitDefID].defenceQuota,buildDefs.factoryByDefId[unitDefID].airDefenceQuota,buildDefs.factoryByDefId[unitDefID].defenceRange,-1,0)
				end
				controlledUnit.factory.cost = controlledUnit.factory.cost - ud.metalCost
				if controlledUnit.factoryByID[unitID].finished then
					a.totalBP = a.totalBP - controlledUnit.factoryByID[unitID].bp
					a.conJob.factory.assignedBP = a.conJob.factory.assignedBP - controlledUnit.factoryByID[unitID].bp
				else
					a.uncompletedFactory = false
				end
				a.totalFactoryBPQuota = a.totalFactoryBPQuota - buildDefs.factoryByDefId[unitDefID].BPQuota
				a.factoryCountByDefID[unitDefID] = a.factoryCountByDefID[unitDefID] - 1
				local index = controlledUnit.factoryByID[unitID].index
				controlledUnit.factoryByID[controlledUnit.factory[controlledUnit.factory.count]].index = index
				controlledUnit.factoryByID[unitID] = nil
				removeIndexFromArray(controlledUnit.factory,index)
			elseif ud.isMobileBuilder then
					if controlledUnit.conByID[unitID].finished then
						a.totalBP = a.totalBP - controlledUnit.conByID[unitID].bp
						local jobIndex = controlledUnit.conByID[unitID].currentJob
						if jobIndex > 0 then
							a.conJobByIndex[jobIndex].assignedBP = a.conJobByIndex[jobIndex].assignedBP - controlledUnit.conByID[unitID].bp
							a.conJobByIndex[jobIndex].con[unitID] = nil
						end
						for i = 1, a.unassignedCons.count do
							if a.unassignedCons[i] == unitID then
								removeIndexFromArray(a.unassignedCons,i)
								break
							end
						end
					end
					controlledUnit.con.cost = controlledUnit.con.cost - ud.metalCost
					controlledUnit.con.count = controlledUnit.con.count - 1
					controlledUnit.conByID[unitID] = nil
			elseif ud.isStaticBuilder then
                    controlledUnit.nano.cost = controlledUnit.nano.cost - ud.metalCost
					local index = controlledUnit.nanoByID[unitID].index
                    controlledUnit.nanoByID[controlledUnit.nano[controlledUnit.nano.count]].index = index
					local closestFactory = controlledUnit.nanoByID[unitID].closestFactory
					if a.controlledUnit.factoryByID[closestFactory] then
						a.controlledUnit.factoryByID[closestFactory].nanoCount = a.controlledUnit.factoryByID[closestFactory].nanoCount - 1
					end
					controlledUnit.nanoByID[unitID] = nil
                    removeIndexFromArray(controlledUnit.nano,index)
			elseif controlledUnit.anyByID[unitID].isScout then
				controlledUnit.scout.cost = controlledUnit.scout.cost - ud.metalCost
				controlledUnit.scout.count = controlledUnit.scout.count - 1
				controlledUnit.scoutByID[unitID] = nil
			elseif controlledUnit.anyByID[unitID].isRaider then
				controlledUnit.raider.cost = controlledUnit.raider.cost - ud.metalCost
				controlledUnit.raider.count = controlledUnit.raider.count - 1
				controlledUnit.raiderByID[unitID] = nil
			elseif ud.canFly then -- aircraft
				if ud.maxWeaponRange > 0 then
					if ud.isFighter then -- fighter
						controlledUnit.fighter.cost = controlledUnit.fighter.cost - ud.metalCost
						controlledUnit.fighter.count = controlledUnit.fighter.count - 1
						controlledUnit.fighterByID[unitID] = nil
					elseif ud.isBomber then -- bomber
						controlledUnit.bomber.cost = controlledUnit.bomber.cost - ud.metalCost
						controlledUnit.bomber.count = controlledUnit.bomber.count - 1
						controlledUnit.bomberByID[unitID] = nil
					else -- gunship
						controlledUnit.gunship.cost = controlledUnit.gunship.cost - ud.metalCost
						controlledUnit.gunship.count = controlledUnit.gunship.count - 1
						controlledUnit.gunshipByID[unitID] = nil
					end
				else -- scout plane
					controlledUnit.scout.cost = controlledUnit.scout.cost - ud.metalCost
					controlledUnit.scout.count = controlledUnit.scout.count - 1
					controlledUnit.scoutByID[unitID] = nil
				end
			elseif ud.maxWeaponRange > 0 and not ud.isImmobile then -- land combat unit
				
				if ud.weapons[1].onlyTargets.land then -- land firing combat
					if ud.speed >= 3*30 then -- raider
						controlledUnit.raider.cost = controlledUnit.raider.cost - ud.metalCost
						controlledUnit.raider.count = controlledUnit.raider.count - 1
						controlledUnit.raiderByID[unitID] = nil
					elseif ud.maxWeaponRange > 650 then -- arty
						controlledUnit.arty.cost = controlledUnit.arty.cost - ud.metalCost
						controlledUnit.arty.count = controlledUnit.arty.count - 1
						controlledUnit.artyByID[unitID] = nil
					else -- other combat
						controlledUnit.combat.cost = controlledUnit.combat.cost - ud.metalCost
						controlledUnit.combat.count = controlledUnit.combat.count - 1
						controlledUnit.combatByID[unitID] = nil
					end
				else -- mobile anti air
					controlledUnit.aa.cost = controlledUnit.aa.cost - ud.metalCost
					controlledUnit.aa.count = controlledUnit.aa.count - 1
					controlledUnit.aaByID[unitID] = nil
				end
				
			elseif ud.isImmobile then -- building
				if ud.maxWeaponRange > 0 then -- turret
					a.wantedDefence.count = a.wantedDefence.count + 1
					a.wantedDefence[a.wantedDefence.count] = {ID = ud.id,
						x = controlledUnit.turretByID[unitID].x, z = controlledUnit.turretByID[unitID].z, priority = 0}
					controlledUnit.turret.cost = controlledUnit.turret.cost - ud.metalCost
					controlledUnit.turret.count = controlledUnit.turret.count - 1
					controlledUnit.turretByID[unitID] = nil
				elseif (ud.customParams.income_energy or ud.energyMake > 0 or tonumber(ud.customParams.upkeep_energy or 0) < 0 or (ud.customParams and ud.customParams.windgen)) then
					controlledUnit.econ.cost = controlledUnit.econ.cost - ud.metalCost
					if controlledUnit.econByID[unitID].onDefenceHeatmap then
						editDefenceHeatmap(unitTeam,unitID,buildDefs.econByDefId[unitDefID].defenceQuota,buildDefs.econByDefId[unitDefID].airDefenceQuota,buildDefs.econByDefId[unitDefID].defenceRange,-1,0)
					end
					local index = controlledUnit.econByID[unitID].index
					controlledUnit.econByID[controlledUnit.econ[controlledUnit.econ.count]].index = index
					controlledUnit.econByID[unitID] = nil
					removeIndexFromArray(controlledUnit.econ,index)
				end
			end
		
			controlledUnit.any.cost = controlledUnit.any.cost - ud.metalCost
			controlledUnit.any.count = controlledUnit.any.count - 1
			controlledUnit.anyByID[unitID] = nil
		end
	end
	
	if (ud ~= nil) and changeAlly then
		local units = allyTeamData[allyTeam].units
		
		units.cost = units.cost - ud.metalCost
		units.cost = units.cost + ud.metalCost
		
		if ud.customParams.ismex then
			units.mex.count = units.mex.count - 1
		end
		units.factoryByID[unitID] = nil
		units.econByID[unitID] = nil
		units.radarByID[unitID] = nil
		units.mexByID[unitID] = nil
		units.turretByID[unitID] = nil
		
		for i,at in pairs(allyTeamData) do
			if at.ai then
				at.enemyMobileAA[unitID] = nil
				at.enemyStaticAA[unitID] = nil
			end
			--[[if at.ai and at.unitInHeatmap[unitID] then
			
				if assaultArray[unitDefID] then
					at.enemyForceComposition.unit.assault = at.enemyForceComposition.unit.assault - ud.metalCost
				elseif skirmArray[unitDefID] then
					at.enemyForceComposition.unit.skirm = at.enemyForceComposition.unit.skirm - ud.metalCost
				elseif riotArray[unitDefID] then
					at.enemyForceComposition.unit.riot = at.enemyForceComposition.unit.riot - ud.metalCost
				elseif raiderArray[unitDefID] then
					at.enemyForceComposition.unit.raider = at.enemyForceComposition.unit.raider - ud.metalCost
				elseif artyArray[unitDefID] then
					at.enemyForceComposition.unit.arty = at.enemyForceComposition.unit.arty - ud.metalCost
				end
				
				if ud.maxWeaponRange > 0 and (not ud.weapons[1].onlyTargets.land) and not ud.isImmobile then
					at.enemyMobileAA[unitID] = nil
					at.enemyForceComposition.unit.antiAir = at.enemyForceComposition.unit.antiAir - ud.metalCost
				end
				
				if ud.maxWeaponRange > 0 and ud.canFly then
					at.enemyForceComposition.unit.air = at.enemyForceComposition.unit.air - ud.metalCost
				end
				
				if ud.maxWeaponRange > 0 and ud.isImmobile then
					if ud.weapons[1].onlyTargets.land then
						at.enemyForceComposition.unit.groundDefence = at.enemyForceComposition.unit.groundDefence - ud.metalCost
					else
						at.enemyStaticAA[unitID] = nil
						at.enemyForceComposition.unit.airDefence = at.enemyForceComposition.unit.airDefence - ud.metalCost
					end
				end
				
				at.unitInHeatmap[unitID] = nil
			end--]]
		end
	end
	--reassess enemy force reduction (enemy counted by individual AI). Note: enemy force increase reassessment from weapon damage is done in UnitDamaged()
	if (ud ~= nil) then
		for i,at in pairs(allyTeamData) do
			if at.ai and at.inLOS[unitID] and at.unitInHeatmap[unitID] then --this AI spotted this unit (as enemy) and it got destroyed
			
				if assaultArray[unitDefID] then
					at.enemyForceComposition.unit.assault = at.enemyForceComposition.unit.assault - ud.metalCost
				elseif skirmArray[unitDefID] then
					at.enemyForceComposition.unit.skirm = at.enemyForceComposition.unit.skirm - ud.metalCost
				elseif riotArray[unitDefID] then
					at.enemyForceComposition.unit.riot = at.enemyForceComposition.unit.riot - ud.metalCost
				elseif raiderArray[unitDefID] then
					at.enemyForceComposition.unit.raider = at.enemyForceComposition.unit.raider - ud.metalCost
				elseif artyArray[unitDefID] then
					at.enemyForceComposition.unit.arty = at.enemyForceComposition.unit.arty - ud.metalCost
				end
				
				if ud.maxWeaponRange > 0 and (not ud.weapons[1].onlyTargets.land) and not ud.isImmobile then
					at.enemyMobileAA[unitID] = nil
					at.enemyForceComposition.unit.antiAir = at.enemyForceComposition.unit.antiAir - ud.metalCost
				end
				
				if ud.maxWeaponRange > 0 and ud.canFly then
					at.enemyForceComposition.unit.air = at.enemyForceComposition.unit.air - ud.metalCost
				end
				
				if ud.maxWeaponRange > 0 and ud.isImmobile then
					if ud.weapons[1].onlyTargets.land then
						at.enemyForceComposition.unit.groundDefence = at.enemyForceComposition.unit.groundDefence - ud.metalCost
					else
						at.enemyStaticAA[unitID] = nil
						at.enemyForceComposition.unit.airDefence = at.enemyForceComposition.unit.airDefence - ud.metalCost
					end
				end
				
				-- if ud.buildSpeed > 0 or ud.isFactory or (ud.energyMake > 0 or tonumber(ud.customParams.upkeep_energy or 0) < 0) or ud.customParams.ismex then -- econ
					-- at.enemyForceComposition.unit.econ = at.enemyForceComposition.unit.econ - ud.metalCost
				-- end --handled by "at.enemyEconomy.totalCost"
				
				at.unitInHeatmap[unitID] = nil
			end
		end
	end
end

local function ProcessUnitCreated(unitID, unitDefID, unitTeam, builderID, changeAlly)

	local allyTeam = spGetUnitAllyTeam(unitID)
	local ud = UnitDefs[unitDefID]
	if (aiTeamData[unitTeam]) then
	
		local a = aiTeamData[unitTeam]
		local controlledUnit = a.controlledUnit
		
		local _,_,_,_,build  = spGetUnitHealth(unitID)
		local built = (build == 1)
		
		if (ud ~= nil) and initialiseFaction(unitTeam) then
			local buildDefs = a.buildDefs
		
			controlledUnit.any.cost = controlledUnit.any.cost + ud.metalCost
			controlledUnit.any.count = controlledUnit.any.count + 1
			controlledUnit.anyByID[unitID] = {ud = ud, cost = ud.metalCost, finished = false,
			isScout = (builderID and controlledUnit.factoryByID[builderID] and controlledUnit.factoryByID[builderID].producingScout),
			isRaider = (builderID and controlledUnit.factoryByID[builderID] and controlledUnit.factoryByID[builderID].producingRaider)}
			
			if unitDefID == buildDefs.airpadDefID then
				controlledUnit.airpad.cost = controlledUnit.airpad.cost + ud.metalCost
				controlledUnit.airpad.count = controlledUnit.airpad.count + 1
				controlledUnit.airpadByID[unitID] = { ud = ud, cost = ud.metalCost, finished = false}
			elseif ud.customParams.ismex and buildDefs.econByDefId[unitDefID] then
				local x,y,z = spGetUnitPosition(unitID)
				if not built then
					editDefenceHeatmap(unitTeam,unitID,buildDefs.econByDefId[unitDefID].defenceQuota,buildDefs.econByDefId[unitDefID].airDefenceQuota,buildDefs.econByDefId[unitDefID].defenceRange,1,0)
				end
				controlledUnit.mex.count = controlledUnit.mex.count + 1
				controlledUnit.mex[controlledUnit.mex.count] = unitID
				controlledUnit.mexByID[unitID] = {finished = false,index = controlledUnit.mex.count,
					ud = ud, x = x, y = y, z = z, cost = ud.metalCost, onDefenceHeatmap = not built}
			elseif ud.isFactory and buildDefs.factoryByDefId[unitDefID] then -- factory
				local x,y,z = spGetUnitPosition(unitID)
				local mx,my,mz = getPositionTowardsMiddle(unitID, 500, 25)
				local amx,amy,amz = getPositionTowardsMiddle(unitID, -250, -25)
				if not built then
					editDefenceHeatmap(unitTeam,unitID,buildDefs.factoryByDefId[unitDefID].defenceQuota,buildDefs.factoryByDefId[unitDefID].airDefenceQuota,buildDefs.factoryByDefId[unitDefID].defenceRange,1,1)
				end
				
				a.totalFactoryBPQuota = a.totalFactoryBPQuota + buildDefs.factoryByDefId[unitDefID].BPQuota
				a.uncompletedFactory = unitID
				if a.factoryCountByDefID[unitDefID] then
					a.factoryCountByDefID[unitDefID] = a.factoryCountByDefID[unitDefID] + 1
				else
					a.factoryCountByDefID[unitDefID] = 1
				end
				controlledUnit.factory.count = controlledUnit.factory.count + 1
				controlledUnit.factory.cost = controlledUnit.factory.cost + ud.metalCost
				controlledUnit.factory[controlledUnit.factory.count] = unitID
				controlledUnit.factoryByID[unitID] = {finished = false,index = controlledUnit.factory.count, nanoCount = 0,
					ud = ud,bp = ud.buildSpeed, x = x, y = y, z = z, cost = ud.metalCost, producingScout = false, producingRaider = false,
					wayX = mx, wayY = my, wayZ = mz, nanoX = amx, nanoY = amy, nanoZ = amz, onDefenceHeatmap = not built}
			elseif ud.buildSpeed > 0 then
				if not ud.isImmobile then -- constructor
					controlledUnit.con.count = controlledUnit.con.count + 1
					controlledUnit.con.cost = controlledUnit.con.cost + ud.metalCost
					controlledUnit.conByID[unitID] = {ud = ud,bp = ud.buildSpeed, finished = false, index = controlledUnit.con.count, idle = true, currentJob = 0, oldJob = 0, makingDefence  = false}
				else -- nano turret
					local x,y,z = spGetUnitPosition(unitID)
					controlledUnit.nano.count = controlledUnit.nano.count + 1
					controlledUnit.nano[controlledUnit.nano.count] = unitID
					local closestFactory = nil
					local minDis = nil
					for i = 1, a.controlledUnit.factory.count do
						local fid = a.controlledUnit.factory[i]
						local data = a.controlledUnit.factoryByID[fid]
						local dis = disSQ(data.x, data.z, x, z)
						if (not minDis) or dis < minDis then
							closestFactory = fid
							minDis = dis
						end
					end
					if closestFactory then
						local data = a.controlledUnit.factoryByID[closestFactory]
						data.nanoCount = a.controlledUnit.factoryByID[closestFactory].nanoCount + 1
						if not data.retreatPointSet then
							GG.Retreat_ToggleHaven(unitTeam, data.nanoX, data.nanoZ)
							data.retreatPointSet = true
						end
					end
					controlledUnit.nanoByID[unitID] = {index = controlledUnit.nano.count,  finished = false, ud = ud,
						bp = ud.buildSpeed, x = x, y = y, z = z, cost = ud.metalCost, closestFactory = closestFactory}
				end
			elseif controlledUnit.anyByID[unitID].isScout then
				controlledUnit.scout.cost = controlledUnit.scout.cost + ud.metalCost
				controlledUnit.scout.count = controlledUnit.scout.count + 1
				controlledUnit.scoutByID[unitID] = { ud = ud, cost = ud.metalCost, finished = false}
			elseif controlledUnit.anyByID[unitID].isRaider then
				controlledUnit.raider.cost = controlledUnit.raider.cost + ud.metalCost
				controlledUnit.raider.count = controlledUnit.raider.count + 1
				controlledUnit.raiderByID[unitID] = { ud = ud, cost = ud.metalCost, finished = false}
				if ud.canFly then
					Spring.Echo("flying raider")
				end
			elseif ud.canFly then -- aircraft
				if ud.maxWeaponRange > 0 then
					if ud.isFighter then -- fighter
						controlledUnit.fighter.cost = controlledUnit.fighter.cost + ud.metalCost
						controlledUnit.fighter.count = controlledUnit.fighter.count + 1
						controlledUnit.fighterByID[unitID] = { ud = ud, cost = ud.metalCost, finished = false}
					elseif ud.isBomber then -- bomber
						controlledUnit.bomber.cost = controlledUnit.bomber.cost + ud.metalCost
						controlledUnit.bomber.count = controlledUnit.bomber.count + 1
						controlledUnit.bomberByID[unitID] = { ud = ud, cost = ud.metalCost, finished = false}
					else -- gunship
						controlledUnit.gunship.cost = controlledUnit.gunship.cost + ud.metalCost
						controlledUnit.gunship.count = controlledUnit.gunship.count + 1
						controlledUnit.gunshipByID[unitID] = { ud = ud, cost = ud.metalCost, finished = false}
					end
				else -- scout plane
					controlledUnit.scout.cost = controlledUnit.scout.cost + ud.metalCost
					controlledUnit.scout.count = controlledUnit.scout.count + 1
					controlledUnit.scoutByID[unitID] = { ud = ud, cost = ud.metalCost, finished = false}
				end
			elseif ud.maxWeaponRange > 0 and not ud.isImmobile then -- land combat unit
	
				if ud.weapons[1].onlyTargets.land then -- land firing combat
					if ud.speed >= 3*30 then -- raider
						controlledUnit.raider.cost = controlledUnit.raider.cost + ud.metalCost
						controlledUnit.raider.count = controlledUnit.raider.count + 1
						controlledUnit.raiderByID[unitID] = { ud = ud, cost = ud.metalCost, finished = false}
					elseif ud.maxWeaponRange > 650 then -- arty
						--spSetUnitSensorRadius(unitID,"los",ud.maxWeaponRange + 20)
						controlledUnit.arty.cost = controlledUnit.arty.cost + ud.metalCost
						controlledUnit.arty.count = controlledUnit.arty.count + 1
						controlledUnit.artyByID[unitID] = { ud = ud, cost = ud.metalCost, finished = false}
					else -- other combat
						controlledUnit.combat.cost = controlledUnit.combat.cost + ud.metalCost
						controlledUnit.combat.count = controlledUnit.combat.count + 1
						controlledUnit.combatByID[unitID] = { ud = ud, cost = ud.metalCost, finished = false}
					end
				else -- mobile anti air
					controlledUnit.aa.cost = controlledUnit.aa.cost + ud.metalCost
					controlledUnit.aa.count = controlledUnit.aa.count + 1
					controlledUnit.aaByID[unitID] = { ud = ud, cost = ud.metalCost, finished = false}
				end
				
			elseif ud.isImmobile then -- building
				if ud.maxWeaponRange > 0 then -- turret
					local x,y,z = spGetUnitPosition(unitID)
					for i = 1, a.wantedDefence.count do
						if math.abs(a.wantedDefence[i].x - x) < 16 and math.abs(a.wantedDefence[i].z - z) < 16 then
							removeIndexFromArray(a.wantedDefence,i)
							break
						end
					end
					controlledUnit.turret.cost = controlledUnit.turret.cost + ud.metalCost
					controlledUnit.turret.count = controlledUnit.turret.count + 1
					controlledUnit.turretByID[unitID] = {index = controlledUnit.turret.count, ud = ud,x = x, y = y, z = z, cost = ud.metalCost, finished = false, air = not ud.weapons[1].onlyTargets.land }
				elseif (ud.customParams.income_energy or ud.energyMake > 0 or tonumber(ud.customParams.upkeep_energy or 0) < 0 or (ud.customParams and ud.customParams.windgen)) then
					local x,y,z = spGetUnitPosition(unitID)
					if econByDefId and econByDefId[unitDefID] and (not built) then
						editDefenceHeatmap(unitTeam,unitID,buildDefs.econByDefId[unitDefID].defenceQuota,buildDefs.econByDefId[unitDefID].airDefenceQuota,buildDefs.econByDefId[unitDefID].defenceRange,1,0)
					end
					controlledUnit.econ.cost = controlledUnit.econ.cost + ud.metalCost
					controlledUnit.econ.count = controlledUnit.econ.count + 1
					controlledUnit.econ[controlledUnit.econ.count] = unitID
					controlledUnit.econByID[unitID] = {index = controlledUnit.econ.count,finished = false,
						ud = ud,x = x, y = y, z = z, nearbyTurrets = 0, cost = ud.metalCost, onDefenceHeatmap = not built}
				elseif ud.radarRadius > 0 then -- radar
					controlledUnit.radar.cost = controlledUnit.econ.cost + ud.metalCost
					controlledUnit.radar.count = controlledUnit.econ.count + 1
					controlledUnit.radarByID[unitID] = {finished = false, ud = ud,x = x, y = y, z = z, cost = ud.metalCost}
				end
			end
		end
	end
	
	if (ud ~= nil) and changeAlly then
		local units = allyTeamData[allyTeam].units
	
		units.cost = units.cost + ud.metalCost
		
		if ud.customParams.ismex then
			units.mex.count = units.mex.count + 1
			units.mexByID[unitID] = true
		elseif ud.isFactory then -- factory
			local mx,my,mz = getPositionTowardsMiddle(unitID, 450, 25)
			units.factoryByID[unitID] = {wayX = mx, wayY = my, wayZ = mz}
			--mapEcho(unitID,"factory added")
		elseif ud.buildSpeed > 0 then
			
		elseif ud.canFly then -- aircraft
		
		elseif ud.maxWeaponRange > 0 and not ud.isImmobile then -- land combat unit
			
		elseif ud.isImmobile then -- building
			if ud.maxWeaponRange > 0 then
				units.turretByID[unitID] = true
			elseif (ud.customParams.income_energy or ud.energyMake > 0 or tonumber(ud.customParams.upkeep_energy or 0) < 0) then
				units.econByID[unitID] = true
			elseif ud.radarRadius > 0 then -- radar
				units.radarByID[unitID] = true
			end
		end
	end
	
end

-- adds some things that can only be done on unit completion
function gadget:UnitFinished(unitID, unitDefID, unitTeam)

	local allyTeam = spGetUnitAllyTeam(unitID)
	local ud = UnitDefs[unitDefID]
	
	if (aiTeamData[unitTeam]) then
		
		local a = aiTeamData[unitTeam]
		local controlledUnit = a.controlledUnit

		if (ud ~= nil) and initialiseFaction(unitTeam) and controlledUnit.anyByID[unitID] then
			local buildDefs = a.buildDefs
		
			controlledUnit.anyByID[unitID].finished = true
			if unitDefID == buildDefs.airpadDefID then
				controlledUnit.airpadByID[unitID].finished = true
			elseif ud.customParams.ismex and buildDefs.econByDefId[unitDefID] then
				controlledUnit.mexByID[unitID].finished = true
			elseif ud.isFactory and buildDefs.factoryByDefId[unitDefID] then -- factory
				a.conJob.factory.assignedBP = a.conJob.factory.assignedBP + ud.buildSpeed
				a.totalBP = a.totalBP + controlledUnit.factoryByID[unitID].bp
				a.uncompletedFactory = false
				controlledUnit.factoryByID[unitID].finished = true
			elseif ud.buildSpeed > 0 then
				if not ud.isImmobile then -- constructor
					a.totalBP = a.totalBP + controlledUnit.conByID[unitID].bp
					a.unassignedCons.count = a.unassignedCons.count + 1
					a.unassignedCons[a.unassignedCons.count] = unitID
					controlledUnit.conByID[unitID].finished = true
					setRetreatState(unitID, unitDefID, unitTeam, 2)
				else -- nano turret
					local x,y,z = spGetUnitPosition(unitID)
					spGiveOrderToUnit(unitID, CMD_MOVE_STATE, { 2 }, 0)
					GiveClampedOrderToUnit(unitID, CMD_PATROL, { x + 25, y, z - 25 }, 0)
					controlledUnit.nanoByID[unitID].finished = true
				end
			elseif controlledUnit.anyByID[unitID].isScout then
				controlledUnit.scoutByID[unitID].finished = true
				setRetreatState(unitID, unitDefID, unitTeam, 3)
			elseif controlledUnit.anyByID[unitID].isRaider then
				controlledUnit.raiderByID[unitID].finished = true
				setRetreatState(unitID, unitDefID, unitTeam, 1)
			elseif ud.canFly then -- aircraft
				if ud.maxWeaponRange > 0 then
					spGiveOrderToUnit(unitID, CMD_MOVE_STATE, { 1 }, 0)
					spGiveOrderToUnit(unitID, CMD_FIRE_STATE, { 2 }, 0)
					if ud.isFighter then -- fighter
						controlledUnit.fighterByID[unitID].finished = true
						setRetreatState(unitID, unitDefID, unitTeam, 2)
					elseif ud.isBomber then -- bomber
						controlledUnit.bomberByID[unitID].finished = true
					else -- gunship
						controlledUnit.gunshipByID[unitID].finished = true
						setRetreatState(unitID, unitDefID, unitTeam, 2)
					end
				else -- scout plane
					controlledUnit.scoutByID[unitID].finished = true
				end
			elseif ud.maxWeaponRange > 0 and not ud.isImmobile then -- land combat unit
				spGiveOrderToUnit(unitID, CMD_MOVE_STATE, { 1 }, 0)
				spGiveOrderToUnit(unitID, CMD_FIRE_STATE, { 2 }, 0)
				if ud.weapons[1].onlyTargets.land then -- land firing combat
					if ud.speed >= 3*30 then -- raider
						controlledUnit.raiderByID[unitID].finished = true
						setRetreatState(unitID, unitDefID, unitTeam, 1)
					elseif ud.maxWeaponRange > 650 then -- arty
						controlledUnit.artyByID[unitID].finished = true
						setRetreatState(unitID, unitDefID, unitTeam, 3)
					else -- other combat
						controlledUnit.combatByID[unitID].finished = true
						setRetreatState(unitID, unitDefID, unitTeam, 2)
					end
				else -- mobile anti air
					controlledUnit.aaByID[unitID].finished = true
					setRetreatState(unitID, unitDefID, unitTeam, 3)
				end
				
			elseif ud.isImmobile then -- building
				if ud.maxWeaponRange > 0 then -- turret
					controlledUnit.turretByID[unitID].finished = true
				elseif (ud.customParams.income_energy or ud.energyMake > 0 or tonumber(ud.customParams.upkeep_energy or 0) < 0 or (ud.customParams and ud.customParams.windgen)) then
					controlledUnit.econByID[unitID].finished = true
				elseif ud.radarRadius > 0 then -- radar
					controlledUnit.radarByID[unitID].finished = true
				end
			end
		end
	end

end

function gadget:UnitDestroyed(unitID, unitDefID, unitTeam)
	ProcessUnitDestroyed(unitID, unitDefID, unitTeam, true)
end

function gadget:UnitCreated(unitID, unitDefID, unitTeam, builderID)
	ProcessUnitCreated(unitID, unitDefID, unitTeam, builderID, true)
end

function gadget:UnitGiven(unitID, unitDefID, teamID, oldTeamID) -- add unit
	local _,_,_,_,_,newAllyTeam = Spring.GetTeamInfo(teamID, false)
	local _,_,_,_,_,oldAllyTeam = Spring.GetTeamInfo(oldTeamID, false)
	for team,_ in pairs(aiTeamData) do
		if teamID == team then
			ProcessUnitCreated(unitID, unitDefID, teamID, nil, newAllyTeam ~= oldAllyTeam)
			local _,_,_,_,build  = spGetUnitHealth(unitID)
			if build == 1 then
				gadget:UnitFinished(unitID, unitDefID, team)
			end
		end
	end
end

function gadget:UnitTaken(unitID, unitDefID, teamID, newTeamID) -- remove unit
	local _,_,_,_,_,newAllyTeam = Spring.GetTeamInfo(newTeamID, false)
	local _,_,_,_,_,oldAllyTeam = Spring.GetTeamInfo(teamID, false)
	for team,_ in pairs(aiTeamData) do
		if teamID == team then
			ProcessUnitDestroyed(unitID, unitDefID, teamID, newAllyTeam ~= oldAllyTeam)
		end
	end
end

function gadget:UnitFromFactory(unitID, unitDefID, unitTeam, factID, factDefID, userOrders)
	if (aiTeamData[unitTeam]) then
		MoveUnitOutOfFactory(unitID, factDefID)
	end
end

local function initialiseAiTeam(team, allyteam, aiConfig)

	Spring.Echo("AI taken control of team " .. team .. " on allyTeam " .. allyteam)

	aiTeamData[team] = {
	
		allyTeam = allyteam,
		
		controlFunction = aiConfig.controlFunction,
		--buildConfig = aiConfig.buildConfig,
		buildConfig = CopyTable(aiConfig.buildConfig),
		raiderBattlegroupCondition = aiConfig.raiderBattlegroupCondition,
		combatBattlegroupCondition = aiConfig.combatBattlegroupCondition,
		gunshipBattlegroupCondition = aiConfig.gunshipBattlegroupCondition,

		averagedEcon = {
			prevEcon = {},
			aveMInc = 3,
			aveEInc = 3,
			aveActiveBp = 0,
			eCur = 0,
			mCur = 0,
			mStor = 500,
			energyToMetalRatio = 1,
			activeBpToMetalRatio = 0,
		},
		
		buildDefs = nil,
		
		selfDefenceHeatmap = {},
		
		selfDefenceAirTask = {count = 0},
		
		battleGroup = {count = 0},
		unitInBattleGroupByID = {},
		
		sosTimeout = {},
		factoryCountByDefID = {},
		
		wantedDefence = {count = 0},
		
		unitHordingChance = 0.3, -- factor from 0 to 1 of percentage of units horded at main base
		wantedNanoCount = 0,
		nanoChance = 0.05, -- factor from 0 to 1 chance of making nano if current nano lower than wantedNanoCount
		
		totalBP = 0, -- total controlled build power
		totalFactoryBPQuota = 0, -- build more factories when over this
		unassignedCons = {count = 0}, -- con that do not have a job
		
		conJob = {
			reclaim = {importance = 0, con = {}, assignedBP = 0, name = "reclaim", interruptable = true, index = 1, grouping = 1},
			defence = {importance = 0, con = {}, assignedBP = 0, name = "defence", interruptable = false, index = 2, grouping = 2,
				radarChance = 0, airChance = 0, airpadChance = 0, metalStorageChance = 0},
			mex = {importance = 0, con = {}, assignedBP = 0, name = "mex", interruptable = false, defenceChance = 0, index = 3, grouping = 1},
			factory = {importance = 0, con = {}, assignedBP = 0, name = "factory", airFactor = 0,interruptable = true, index = 4, grouping = 2},
			energy = {importance = 0, con = {}, assignedBP = 0, name = "energy", interruptable = false, index = 5, grouping = 2},
		},
		
		-- jobs that a factory can have and the weighted importance on each
		facJob = {
			[1] = {importance = 0}, -- con
			[2] = {importance = 0}, -- scout
			[3] = {importance = 0}, -- raider
			[4] = {importance = 0}, -- arty
			[5] = {importance = 0}, -- assault
			[6] = {importance = 0}, -- skirm
			[7] = {importance = 0}, -- riot
			[8] = {importance = 0}, -- aa
		},
		
		facJobAir = {
			[1] = {importance = 0}, -- con
			[2] = {importance = 0}, -- scout
			[3] = {importance = 0}, -- fighter
			[4] = {importance = 0}, -- bomber
			[5] = {importance = 0}, -- gunship
		},

		uncompletedFactory = false,
		
		controlledUnit = {	-- only factory, mex and econ hold an ordered array. the rest have only count and cost
			any = {cost = 0, count = 0,},
			anyByID = {},
			mex = {cost = 0, count = 0,},
			mexByID = {},
			factory = {cost = 0, count = 0,},
			factoryByID = {},
			nano = {cost = 0, count = 0,},
			nanoByID = {},
			con = {cost = 0, count = 0,},
			conByID = {},
			scout = {cost = 0, count = 0,},
			scoutByID = {},
			raider = {cost = 0, count = 0,},
			raiderByID = {},
			arty = {cost = 0, count = 0,},
			artyByID = {},
			combat = {cost = 0, count = 0,},
			combatByID = {},
			aa = {cost = 0, count = 0,},
			aaByID = {},
			fighter = {cost = 0, count = 0,},
			fighterByID = {},
			bomber = {cost = 0, count = 0,},
			bomberByID = {},
			gunship = {cost = 0, count = 0,},
			gunshipByID = {},
			econ = {cost = 0, count = 0,},
			econByID = {},
			turret = {cost = 0, count = 0,},
			turretByID = {},
			radar = {cost = 0,count = 0,},
			radarByID = {},
			airpad = {cost = 0,count = 0,},
			airpadByID = {},
		},
		
		suspend = false,
		retreat = true,	-- only applies to new units
		retreatComm = true,	-- ditto
	}
	
	local a = aiTeamData[team]
	
	a.conJobByIndex = { -- con job by index
		[1] = a.conJob.reclaim,
		[2] = a.conJob.defence,
		[3] = a.conJob.mex,
		[4] = a.conJob.factory,
		[5] = a.conJob.energy,
	}
	
	for i = 1, econAverageMemory do
		a.averagedEcon.prevEcon[i] = {eInc = 3, mInc = 3, activeBp = 0}
	end
	
	for i = 1,heatArrayWidth do -- init array
		a.selfDefenceHeatmap[i] = {}
		for j = 1, heatArrayHeight do
			a.selfDefenceHeatmap[i][j] = {
				[1] = {
					total = 0,
					toBuild = 0,
					air = 0,
					airTask = 0,
				},
				[2] = {
					total = 0,
					toBuild = 0,
					air = 0,
					airTask = 0,
				},
				[3] = {
					total = 0,
					toBuild = 0,
					air = 0,
					airTask = 0,
				},
			}
		end
	end
	
	local player = select(2, Spring.GetTeamInfo(team, false))
	local stratIndex = SelectRandomStrat(player, team)
	--Spring.Echo(a.buildConfig)
	--ModifyTable(a.buildConfig, buildTasksMods)
	strategies[stratIndex].buildTasksMods(aiTeamData[team].buildConfig)
end

local function initialiseAllyTeam(allyTeam, aiOnTeam)

	Spring.Echo("Ally Team " .. allyTeam .. " intialised")
	
	allyTeamData[allyTeam] = {
	
		teams = {},
		aTeamOnThisTeam = 0,
		ai = aiOnTeam,
		listOfAis = {count = 0, data = {}},
		inLOS = {}, --temporarily remember spotted unit for counting destroyed unit in a non-cheating way
		
		units = { -- most of these are unused - would be used in cheating AI
			cost = 0,
			mex = {count = 0,},
			mexByID = {},
			--factory = {count = 0,},
			factoryByID = {},
			--[[con = {count = 0,},
			conByID = {},
			scout = {cost = 0, count = 0,},
			scoutByID = {},
			raider = {cost = 0, count = 0,},
			raiderByID = {},
			arty = {cost = 0, count = 0,},
			artyByID = {},
			combat = {cost = 0, count = 0,},
			combatByID = {},
			econ = {cost = 0, count = 0,},--]]
			econByID = {},
			radarByID = {},
			--turret = {cost = 0, count = 0,},
			turretByID = {},
			--[[nano = {count = 0,},
			nanoByID = {},--]]
		},
		
		isPosThreatenedCache = {},	-- [x] = { [z] = {isThreatened = false, time = timeCreated} }
	}
	
	local at = allyTeamData[allyTeam]
	
	for _,t in pairs(spGetTeamList()) do
		local _,_,_,_,_,myAllyTeam = spGetTeamInfo(t, false)
		if myAllyTeam == allyTeam then
			Spring.Echo("Team " .. t .. " on allyTeam " .. allyTeam)
			at.teams[t] = true
			at.aTeamOnThisTeam = t
			if aiTeamData[t] then
				at.listOfAis.count = at.listOfAis.count + 1
				at.listOfAis.data[at.listOfAis.count] = t
			end
		end
	end
	
	if aiOnTeam then
		Spring.Echo("AI on ally team " .. allyTeam)
		
		at.fighterTarget = false
		
		at.unitInHeatmap = {}
		
		at.enemyForceComposition = {
			totalCost = 1,
			unit = {
				raider = 500,
				skirm = 500,
				assault = 500,
				riot = 500,
				arty = 500,
				antiAir = 500,
				air = 500,
				airDefence = 500,
				groundDefence = 500,
			},
		}
		
		at.relativeEnemyForceComposition = { -- adds to 9
			unit = {
				raider = 1,
				skirm = 1,
				assault = 1,
				riot = 1,
				arty = 1,
				antiAir = 1,
				air = 1,
				airDefence = 1,
				groundDefence = 1,
			},
		}
		
		at.enemyHasAir = false
	
		at.enemyStaticAA = {}
		at.enemyMobileAA = {}
		
		at.enemyOffense = {totalCost = 0, count = 0}
		at.enemyOffenseHeatmap = {}
		
		at.enemyEconomy = {totalCost = 0, count = 0}
		at.enemyEconomyHeatmap = {}
		
		at.enemyDefence = {totalCost = 0, count = 0}
		at.enemyDefenceHeatmap = {}
		
		at.unScoutedPoint = {count = 0}
		at.scoutingHeatmap = {}
		
		for i = 1,heatArrayWidth do -- init array
			at.enemyOffenseHeatmap[i] = {}
			for j = 1, heatArrayHeight do
				at.enemyOffenseHeatmap[i][j] = {cost = 0, index = 0}
			end
		end
		
		for i = 1,heatArrayWidth do -- init array
			at.enemyEconomyHeatmap[i] = {}
			for j = 1, heatArrayHeight do
				at.enemyEconomyHeatmap[i][j] = {cost = 0, index = 0}
			end
		end
		
		for i = 1,heatArrayWidth do -- init array
			at.enemyDefenceHeatmap[i] = {}
			for j = 1, heatArrayHeight do
				at.enemyDefenceHeatmap[i][j] = {cost = 0, index = 0}
			end
		end
		
		for i = 1,heatArrayWidth do
			at.scoutingHeatmap[i] = {}
			for j = 1, heatArrayHeight do
				at.scoutingHeatmap[i][j] = {scouted = false, lastScouted = -10000, previouslyEmpty = false}
			end
		end
	
	end
end

local function SuspendAI(team, bool)
	if not aiTeamData[team] then
		Spring.Log(gadget:GetInfo().name, LOG.ERROR, "attempt to suspend a non-existent CAI team")
	end
	aiTeamData[team].suspend = (bool and bool) or (not aiTeamData[team].suspend)
end

local function SetFactoryDefImportance(team, factoryDefID, importance)
	local a = aiTeamData[team]
	if not a then
		Spring.Log(gadget:GetInfo().name, LOG.ERROR, "attempt to modify a non-existent CAI team")
	end
	
	importance = importance or 1
	a.buildDefs.factoryByDefId[factoryDefID].importance = importance
	--Spring.Echo(a.buildDefs.factoryByDefId[factoryDefID])
end

local function RemoveUnit(unitID, unitDefID, unitTeam)
	unitDefID = unitDefID or spGetUnitDefID(unitID)
	unitTeam = unitTeam or spGetUnitTeam(unitID)
	if not aiTeamData[unitTeam] then
		Spring.Log(gadget:GetInfo().name, LOG.ERROR, "attempt to remove unit from a non-existent CAI team")
	end
	ProcessUnitDestroyed(unitID, unitDefID, unitTeam)
end

-- these only apply to new units
-- for this reason, it needs to be done before Create Units in a mission
local function SetRetreat(team, bool)
	if not aiTeamData[team] then
		Spring.Log(gadget:GetInfo().name, LOG.ERROR, "attempt to set retreat toggle for a non-existent CAI team")
	end
	aiTeamData[team].retreat = (bool and bool) or (not aiTeamData[team].retreat)
end

local function SetRetreatComm(team, bool)
	if not aiTeamData[team] then
		Spring.Log(gadget:GetInfo().name, LOG.ERROR, "attempt to set retreat toggle for a non-existent CAI team")
	end
	aiTeamData[team].retreatComm = (bool and bool) or (not aiTeamData[team].retreatComm)
end

local function setAllyteamStartLocations(allyTeam)
	if Game.startPosType ~= 2 then -- 'choose ingame'
		return
	end

	local teamList = Spring.GetTeamList(allyTeam)
	if (not teamList) or (#teamList == 0) then return end

	local at = allyTeamData[allyTeam]
	local listOfAis = at.listOfAis

	local boxID = Spring.GetTeamRulesParam(teamList[1], "start_box_id")
	if boxID then
		local boxConfig = GG.startBoxConfig[boxID] and GG.startBoxConfig[boxID].startpoints
		if boxConfig and boxConfig[1] then
			for i = 1, listOfAis.count do
				local team = listOfAis.data[i]
				local startpos = boxConfig[i] or boxConfig[1]
				GG.SetStartLocation (team, startpos[1], startpos[2])
			end
			return
		end
	end

	for i = 1, listOfAis.count do
		local team = listOfAis.data[i]
		GG.SetStartLocation (team, math.random(1, Game.mapSizeX-1), math.random(1, Game.mapSizeZ-1))
	end
end

----------------------------
-- Debug (based on KPAI)


local function changeAIscoutmapDrawing(cmd,line,words,player)
	local allyTeam=tonumber(words[1])
	if allyTeam and allyTeamData[allyTeam] and allyTeamData[allyTeam].ai then
		if debugData.drawScoutmap[allyTeam] then
			debugData.drawScoutmap[allyTeam] = nil
			Spring.Echo("CAI scoutmap drawing for allyTeam " .. allyTeam .. " OFF")
		else
			debugData.drawScoutmap[allyTeam] = true
			Spring.Echo("CAI scoutmap drawing for allyTeam " .. allyTeam .. " ON")
		end
	else
		Spring.Echo("Incorrect allyTeam for CAI")
	end
	return true
end

local function changeAIoffenseDrawing(cmd,line,words,player)
	local allyTeam=tonumber(words[1])
	if allyTeam and allyTeamData[allyTeam] and allyTeamData[allyTeam].ai then
		if debugData.drawOffensemap[allyTeam] then
			debugData.drawOffensemap[allyTeam] = false
			Spring.Echo("CAI offense drawing for allyTeam " .. allyTeam .. " OFF")
		else
			debugData.drawOffensemap[allyTeam] = true
			Spring.Echo("CAI offense drawing for allyTeam " .. allyTeam .. " ON")
		end
	else
		Spring.Echo("Incorrect allyTeam CAI")
	end
	return true
end

local function changeAIeconDrawing(cmd,line,words,player)
	local allyTeam=tonumber(words[1])
	if allyTeam and allyTeamData[allyTeam] and allyTeamData[allyTeam].ai then
		if debugData.drawEconmap[allyTeam] then
			debugData.drawEconmap[allyTeam] = false
			Spring.Echo("CAI economy drawing for allyTeam " .. allyTeam .. " OFF")
		else
			debugData.drawEconmap[allyTeam] = true
			Spring.Echo("CAI economy drawing for allyTeam " .. allyTeam .. " ON")
		end
	else
		Spring.Echo("Incorrect allyTeam CAI")
	end
	return true
end

local function changeAIdefenceDrawing(cmd,line,words,player)
	local allyTeam=tonumber(words[1])
	if allyTeam and allyTeamData[allyTeam] and allyTeamData[allyTeam].ai then
		if debugData.drawDefencemap[allyTeam] then
			debugData.drawDefencemap[allyTeam] = false
			Spring.Echo("CAI defence drawing for allyTeam " .. allyTeam .. " OFF")
		else
			debugData.drawDefencemap[allyTeam] = true
			Spring.Echo("CAI defence drawing for allyTeam " .. allyTeam .. " ON")
		end
	else
		Spring.Echo("Incorrect allyTeam CAI")
	end
	return true
end

local function changeAIshowEnemyForceComposition(cmd,line,words,player)
	local team=tonumber(words[1])
	if team and aiTeamData[team] then
		if debugData.showEnemyForceCompostion[team] then
			debugData.showEnemyForceCompostion[team] = false
			Spring.Echo("CAI enemy force composition " .. team .. " OFF")
		else
			debugData.showEnemyForceCompostion[team] = true
			Spring.Echo("CAI enemy force composition " .. team .. " ON")
		end
	else
		Spring.Echo("Incorrect CAI team")
	end
	return true
end

local function changeAIshowConJob(cmd,line,words,player)
	local team=tonumber(words[1])
	if team and aiTeamData[team] then
		if debugData.showConJobList[team] then
			debugData.showConJobList[team] = false
			Spring.Echo("CAI con job " .. team .. " OFF")
		else
			debugData.showConJobList[team] = true
			Spring.Echo("CAI con job " .. team .. " ON")
		end
	else
		Spring.Echo("Incorrect CAI team")
	end
	return true
end

local function changeAIshowFacJob(cmd,line,words,player)
	local team=tonumber(words[1])
	if team and aiTeamData[team] then
		if debugData.showFacJobList[team] then
			debugData.showFacJobList[team] = false
			Spring.Echo("CAI factory job " .. team .. " OFF")
		else
			debugData.showFacJobList[team] = true
			Spring.Echo("CAI factory job " .. team .. " ON")
		end
	else
		Spring.Echo("Incorrect CAI team")
	end
	return true
end

local function SetupCmdChangeAIDebug()
	gadgetHandler:AddChatAction("caiscout",changeAIscoutmapDrawing,"toggles CAI scoutmap drawing")
	Script.AddActionFallback("caiscout"..' ',"toggles CAI scoutmap drawing")

	gadgetHandler:AddChatAction("caioffense",changeAIoffenseDrawing,"toggles CAI offense drawing")
	Script.AddActionFallback("caioffense"..' ',"toggles CAI offense drawing")
	
	gadgetHandler:AddChatAction("caiecon",changeAIeconDrawing,"toggles CAI economy drawing")
	Script.AddActionFallback("caiecon"..' ',"toggles CAI economy drawing")
	
	gadgetHandler:AddChatAction("caidefence",changeAIdefenceDrawing,"toggles CAI defence drawing")
	Script.AddActionFallback("caidefence"..' ',"toggles CAI defence drawing")
	
	gadgetHandler:AddChatAction("caicomp",changeAIshowEnemyForceComposition,"toggles CAI enemy composition output")
	Script.AddActionFallback("caicomp"..' ',"toggles CAI enemy composition output")
	
	gadgetHandler:AddChatAction("caicon",changeAIshowConJob,"toggles CAI con job output")
	Script.AddActionFallback("caicon"..' ',"toggles CAI con job output")
	
	gadgetHandler:AddChatAction("caifac",changeAIshowFacJob,"toggles CAI factory job output")
	Script.AddActionFallback("caifac"..' ',"toggles CAI factory job output")
end

function gadget:Initialize()
	-- Initialise AI for all team that are set to use it
	local aiOnTeam = {}
	usingAI = false
	
	if not GG.metalSpots then
		Spring.Log(gadget:GetInfo().name, LOG.ERROR, "CAI: Fatal error, map not supported due to metal map.")
		Spring.SetGameRulesParam("CAI_disabled", 1)
		gadgetHandler:RemoveGadget()
	end
	
	for _,team in ipairs(spGetTeamList()) do
		--local _,_,_,isAI,side = spGetTeamInfo(team, false)
		if aiConfigByName[spGetTeamLuaAI(team)] then
			local _,_,_,_,_,allyTeam,_,CustomTeamOptions = spGetTeamInfo(team)
			if (not CustomTeamOptions) or (not CustomTeamOptions["aioverride"]) then -- what is this for?
				initialiseAiTeam(team, allyTeam, aiConfigByName[spGetTeamLuaAI(team)])
				aiOnTeam[allyTeam] = true
				usingAI = true
			end
		end
	end
	
	if usingAI then
		for _,allyTeam in ipairs(spGetAllyTeamList()) do
			initialiseAllyTeam(allyTeam, aiOnTeam[allyTeam])
			if aiOnTeam[allyTeam] then
				setAllyteamStartLocations(allyTeam)
			end
		end
	else
		Spring.SetGameRulesParam("CAI_disabled", 1)
		gadgetHandler:RemoveGadget()
		return
	end
	
	SetupCmdChangeAIDebug()
	
	GG.CAI = GG.CAI or {
		SuspendAI = SuspendAI,
		SetFactoryDefImportance = SetFactoryDefImportance,
		RemoveUnit = RemoveUnit,
		SetRetreat = SetRetreat,
		SetRetreatComm = SetRetreatComm,
	}
	
	--// mex spot detection
	GG.metalSpots = GG.metalSpots
	if not GG.metalSpots then
		Spring.Echo("Mex spot detection failed, AI failed to initalise")
		Spring.SetGameRulesParam("CAI_disabled", 1)
		gadgetHandler:RemoveGadget()
		return
	end

	--local x,z
	-- get team units
	for _, unitID in ipairs(spGetAllUnits()) do
		local unitDefID = spGetUnitDefID(unitID)
		local team = spGetUnitTeam(unitID)
		gadget:UnitCreated(unitID, unitDefID, team)
		local _,_,_,_,build  = spGetUnitHealth(unitID)
		if build == 1 then
			gadget:UnitFinished(unitID, unitDefID, team)
		end
		--x,_,z = spGetUnitPosition(unitID)
	end
	
end

function gadget:Shutdown()
	GG.CAI = nil
end

local function ReloadUnitIDs()
	local GetNewKeys = GG.SaveLoad.GetNewUnitIDKeys

	for teamID, teamData in pairs(aiTeamData) do
		teamData.unitInBattleGroupByID = GetNewKeys(teamData.unitInBattleGroupByID)
		for battleGroupID, battleGroupData in pairs(teamData.battleGroup) do
			if type(battleGroupData) == "table" then
				battleGroupData.unit = GetNewKeys(battleGroupData.unit)
				battleGroupData.aa = GetNewKeys(battleGroupData.aa)
			end
		end
		for job, jobData in pairs(teamData.conJob) do
			jobData.con = GetNewKeys(jobData.con)
		end
		for jobIndex, jobData in pairs(teamData.conJobByIndex) do
			jobData.con = GetNewKeys(jobData.con)
		end
		teamData.sosTimeout = GetNewKeys(teamData.sosTimeout)
		
		for controlledUnitCategory, controlledUnitData in pairs(teamData.controlledUnit) do
			local isID = string.sub(controlledUnitCategory, -4) == "ByID"
			Spring.Echo("category", controlledUnitCategory)
			if isID then
				teamData.controlledUnit[controlledUnitCategory] = GetNewKeys(controlledUnitData)
			else
				local new = {cost = controlledUnitData.cost, count = controlledUnitData.count}
				for index, oldID in ipairs(controlledUnitData) do
					new[index] = GG.SaveLoad.GetNewUnitID(oldID)
				end
				teamData.controlledUnit[controlledUnitCategory] = new
			end
		end
	end
	
	for teamID, teamData in pairs(allyTeamData) do
		for unitCategory, unitData in pairs(teamData.units) do
			if type(unitData) == "table" then
				local isID = string.sub(unitCategory, -4) == "ByID"
				if isID then
					teamData.units[unitCategory] = GetNewKeys(unitData)
				else
					local new = {cost = unitData.cost, count = unitData.count}
					for index, oldID in ipairs(unitData) do
						new[index] = GG.SaveLoad.GetNewUnitID(oldID)
					end
					teamData.units[unitCategory] = new
				end
			end
		end
	end
end

function gadget:Load(zip)
	if not (GG.SaveLoad and GG.SaveLoad.ReadFile) then
		Spring.Log(gadget:GetInfo().name, LOG.ERROR, "CAI failed to access save/load API")
		return
	end
	local data = GG.SaveLoad.ReadFile(zip, "CAI", SAVE_FILE) or {}
	aiTeamData = data.aiTeamData
	allyTeamData = data.allyTeamData

	local toResetUnitDefs = {
		"anyByID",
		"combatByID",
		"conByID",
		"econByID",
		"mexByID",
		"factoryByID",
		"nanoByID",
		"radarByID",
		"airpadByID",
		"scoutByID",
		"raiderByID",
		"artyByID",
		"aaByID",
		"turretByID",
		"fighterByID",
		"bomberByID",
		"gunshipByID",
	}
	
	ReloadUnitIDs()
	
	-- reassign function variables and unitDef information
	for teamID,teamData in pairs(aiTeamData) do
		local aiConfig = aiConfigByName[spGetTeamLuaAI(teamID)]
		teamData.controlFunction = aiConfig.controlFunction
		--teamData.buildConfig = aiConfig.buildConfig
		teamData.buildConfig = CopyTable(aiConfig.buildConfig)
		teamData.raiderBattlegroupCondition = aiConfig.raiderBattlegroupCondition
		teamData.combatBattlegroupCondition = aiConfig.combatBattlegroupCondition
		teamData.gunshipBattlegroupCondition = aiConfig.gunshipBattlegroupCondition
		for i=1,#toResetUnitDefs do
			local key = toResetUnitDefs[i]
			local units = teamData.controlledUnit[key]
			for unitID,unitData in pairs(units) do
				local unitDefID = Spring.GetUnitDefID(unitID)
				unitData.ud = UnitDefs[unitDefID]
			end
		end
	end
end

--------------------------------------------------------------------------------
-- UNSYNCED
--------------------------------------------------------------------------------


else

--------------------------------------------------------------------------------
-- UNSYNCED
--------------------------------------------------------------------------------
local MakeRealTable = Spring.Utilities.MakeRealTable

local heatmapPosition

-- draw scoutmap
-- FIXME: could use some big time optimizations
--[[
function gadget:DrawWorldPreUnit()
	if Spring.IsCheatingEnabled() then
		if SYNCED and SYNCED.debugData and SYNCED.debugData.drawScoutmap then
			local scoutmaps = SYNCED.debugData.drawScoutmap
			for allyTeam in spairs(scoutmaps) do
				local scoutmap = SYNCED.allyTeamData[allyTeam].scoutingHeatmap
				for x,xdata in spairs(scoutmap) do
					for z,zdata in spairs(xdata) do
						local px, pz = heatmapPosition[x][z].x, heatmapPosition[x][z].z
						if not zdata.scouted then
							gl.Color(0,0,0,0.5)
							gl.DrawGroundQuad(px-256,pz-256,px+256,pz+256)
						end
					end
				end
				gl.Color(1,1,1,1)
				break
			end
		end
	end
end
--]]

function gadget:Initialize()
	local usingAI = false
	for _,team in ipairs(spGetTeamList()) do
		--local _,_,_,isAI,side = spGetTeamInfo(team, false)
		if aiConfigByName[spGetTeamLuaAI(team)] then
			local _,_,_,_,_,_,_,CustomTeamOptions = spGetTeamInfo(team)
			if (not CustomTeamOptions) or (not CustomTeamOptions["aioverride"]) then -- what is this for?
				usingAI = true
			end
		end
	end
	if not usingAI then
		gadgetHandler:RemoveGadget()
		return
	end
	
	if Spring.GetGameRulesParam("CAI_disabled") == 1 then
		gadgetHandler:RemoveGadget()
		return
	end
	--heatmapPosition = MakeRealTable(SYNCED.heatmapPosition)
end

function gadget:Save(zip)
	if not GG.SaveLoad then
		Spring.Log(gadget:GetInfo().name, LOG.ERROR, "CAI failed to access save/load API")
		return
	end
	local allyTeamData = MakeRealTable(SYNCED.allyTeamData, "CAI ally team data")
	local aiTeamData = MakeRealTable(SYNCED.aiTeamData, "CAI AI team data")
	local toSave = {allyTeamData = allyTeamData, aiTeamData = aiTeamData}
	GG.SaveLoad.WriteSaveData(zip, SAVE_FILE, toSave)
end

end
