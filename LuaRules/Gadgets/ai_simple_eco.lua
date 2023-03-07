function gadget:GetInfo()
    return {
		name    = "Economist AI",
		desc    = "A simple economist AI",
		author  = "dyth68",
		date    = "2023-01-23",
		license = "Public Domain",

        layer   = 83,
        enabled = true
    }
end
------------------------------------------------------------
-- TODO 

-- Consider current E plus under construction E
-- Make mexers in proportion to how many remaining empty mexespots there are and current E production
-- Move "build close to" to lib
-- No duplicate pylons
-- gridders should separate
-- Don't make things close enough to chainsplode
-- terraform pylon spots when needed


include("LuaRules/Configs/customcmds.h.lua")
include("LuaRules/Configs/constants.lua")
------------------------------------------------------------
-- START INCLUDE
------------------------------------------------------------

local hard = true

local ai_lib_UnitDestroyed, ai_lib_UnitCreated, ai_lib_UnitGiven, ai_lib_Initialize, ai_lib_GameFrame, sqDistance, HandleAreaMex, GetMexSpotsFromGameRules, GetClosestBuildableMetalSpot, GetClosestBuildableMetalSpots = VFS.Include("LuaRules/Gadgets/ai_simple_lib.lua")
local GetClosestPylonInGrid
local SetPriorityState

local storageDefID = UnitDefNames["staticstorage"].id
local conjurerDefID = UnitDefNames["cloakcon"].id
local pylonDefID = UnitDefNames["energypylon"].id
local solarDefID = UnitDefNames["energysolar"].id
local fusionDefID = UnitDefNames["energyfusion"].id
local singuDefID = UnitDefNames["energysingu"].id
local caretakerDefID = UnitDefNames["staticcon"].id
local cloakfacDefID = UnitDefNames["factorycloak"].id
local mexDefID = UnitDefNames["staticmex"].id

local floor = math.floor
local max = math.max


------------------------------------------------------------
-- Vars
------------------------------------------------------------
local teamdata = {}

local conDefs = {}
local next = next
local Echo = Spring.Echo
local spGiveOrderToUnit = Spring.GiveOrderToUnit
local spGetUnitCommands = Spring.GetUnitCommands
local spGetUnitPosition = Spring.GetUnitPosition
local spGetUnitHealth = Spring.GetUnitHealth
local spTestBuildOrder = Spring.TestBuildOrder
local spGetUnitsInCylinder = Spring.GetUnitsInCylinder
local spGetTeamUnits = Spring.GetTeamUnits
local spGetTeamUnitsByDefs = Spring.GetTeamUnitsByDefs
local spGetUnitDefID = Spring.GetUnitDefID
local spGetUnitNearestEnemy = Spring.GetUnitNearestEnemy
local spGetFactoryCommands = Spring.GetFactoryCommands
local spGetGroundHeight = Spring.GetGroundHeight
local spGetTeamUnitDefCount = Spring.GetTeamUnitDefCount
local spGetTeamResources = Spring.GetTeamResources
local spSendLuaRulesMsg = Spring.SendLuaRulesMsg
local spGetTeamRulesParam = Spring.GetTeamRulesParam
local spGetUnitIsDead = Spring.GetUnitIsDead
local spGetUnitResources = Spring.GetUnitResources
local spGetUnitRulesParam = Spring.GetUnitRulesParam
local spGetGameFrame = Spring.GetGameFrame

local unitVec = Spring.Utilities.Vector.Unit

local sqrt = math.sqrt
------------------------------------------------------------
-- Debug
------------------------------------------------------------
local function printThing(theKey, theTable, indent)
	indent = indent or ""
	if (type(theTable) == "table") then
		Echo(indent .. theKey .. ":")
		for a, b in pairs(theTable) do
			printThing(tostring(a), b, indent .. "  ")
		end
	else
		Echo(indent .. theKey .. ": " .. tostring(theTable))
	end
end

------------------------------------------------------------
-- AI
------------------------------------------------------------

-- Eco constants
local MEXER = "mexer"
local GRIDDER = "grider"
local E_MAKER = "emaker"
local pylonRadius = 500 -- TODO: don't hardcode

local function starts_with(str, start)
	if not str or not start then
		return false
	end
	return str:sub(1, #start) == start
end

local function initializeTeams()
	Echo("Initializing teams")
    for _,t in ipairs(Spring.GetTeamList()) do
        local _,_,_,isAI,side = Spring.GetTeamInfo(t)
        if starts_with(Spring.GetTeamLuaAI(t), gadget:GetInfo().name) then
            Echo("Team Super "..t.." assigned to "..gadget:GetInfo().name)
            local pos = {}
            local home_x,home_y,home_z = Spring.GetTeamStartPosition(t)
			teamdata[t] = {
				cons = {},
				conRoles = {},
				mexBuildOwners = {},
				numMexers = 0,
				numGridders = 0,
				numEMakers = 0,
				startpos = {home_x,home_y,home_z}
			}
        end
    end
end

for unitDefID, def in pairs(UnitDefs) do
	if def.isBuilder and (def.canMove or not def.canPatrol) then -- TODO: probably want to exclude facs
		conDefs[unitDefID] = true
	end
end


function gadget:UnitCreated(unitID, unitDefID, teamId)
	--Echo("Unit created called")

	if next(teamdata) == nil then
		initializeTeams()
	end
	if not (teamdata[teamId] == nil) and conDefs[unitDefID] then
		--Echo("is con")
		--printThing("teamdata", teamdata, "")
		teamdata[teamId].cons[unitID] = true
	end
	ai_lib_UnitCreated(unitID, unitDefID, teamId)
end

function gadget:UnitDestroyed(unitID, unitDefID, teamId)
	if teamdata[teamId] then
		if teamdata[teamId].cons[unitID] then
			teamdata[teamId].cons[unitID] = nil
		end
	end
	ai_lib_UnitDestroyed(unitID, unitDefID, teamId)
end

function gadget:Initialize()
	Echo("Initialize called")
	GetMexSpotsFromGameRules()
	if next(teamdata) == nil then
		initializeTeams()
	end
    for teamId,_ in pairs(teamdata) do
		local units = Spring.GetTeamUnits(teamId)
		for i=1, #units do
			local unitID = units[i].unitID
			local DefID = spGetUnitDefID(units[i])
			if conDefs[DefID]  then
				teamdata[teamId].cons[unitID] = true
			end
		end
	end
	GetClosestPylonInGrid = GG.GetClosestPylonInGrid
	SetPriorityState = GG.SetPriorityState

	ai_lib_Initialize()
end

local function getOneDistLengthTowardsUnit(dist, unitId1, unitId2) -- TODO: move to utils
	local x1, _, z1 = spGetUnitPosition(unitId1)
	local x2, _, z2 = spGetUnitPosition(unitId2)
	Spring.MarkerAddPoint ( x1, 100, z1,"u1", true)
	Spring.MarkerAddPoint ( x2, 100, z2,"u2", true)
	--printThing("unit Positions", {u1={x1, z1}, u2={x2,z2}})
	--printThing("dist", dist)
	local v = unitVec({x2 - x1, z2 - z1})
	--printThing("v", v)
	Spring.MarkerAddPoint ( x1 + v[1] * dist, 100, z1 + v[2] * dist,"v", true)
	return x1 + v[1] * dist, z1 + v[2] * dist
end

local function buildCloseTo(unitId, buildId, x, y, z)
	local xx = x - 10
	local yy = y
	local zz = z - 10
	local i = 0
	local maxDist = 10
	while (spTestBuildOrder(buildId, xx, yy, zz, 0) == 0) and i < 10000 do
		xx = xx + 10
		if xx > xx + maxDist then
			if yy > yy + maxDist then
				maxDist = maxDist + 10
				yy = y - maxDist
			end
			xx = xx - maxDist
		end
		yy = max(0, spGetGroundHeight(xx, zz))
		i = i + 1
	end
	if i > 100 then
		Echo("ERROR! Could not place building! " .. tostring(buildId))
		Spring.MarkerAddPoint ( x, y, z,tostring(buildId), true)
	end
	spGiveOrderToUnit(unitId, -buildId, {xx, yy, zz, 0}, {shift=true})
	return xx, yy, zz
end

local function assistBuild(conId, unitToConsiderId)
	local buildDefId = spGetUnitDefID ( unitToConsiderId)
	local xx, yy, zz = spGetUnitPosition ( unitToConsiderId)
	spGiveOrderToUnit(conId, -buildDefId, {xx, yy, zz, 0}, {shift=true})
end

local function isBuildingUnitDef(conId, buildId)
	local cmdQueue = spGetUnitCommands(conId, 2)
	for _,cmd in ipairs(cmdQueue) do
		if cmd.id == -buildId then
			return {cmd.params[1],cmd.params[2],cmd.params[3], cmd.params[4]}
		end
	end
	return nil
end

local function buildOrAssistCloseTo(unitId, buildId, teamId, x, y, z, maxAssistRange)
	local unitsToConsider
	local consToConsider = {}
	if maxAssistRange == nil or maxAssistRange == -1 then
		unitsToConsider = spGetTeamUnitsByDefs (teamId, buildId)
	else
		local allTypesUnitsToConsider = spGetUnitsInCylinder (x, z, maxAssistRange, teamId )
		unitsToConsider = {}
		local i = 1
		local consNum = 1
		for _,unitToConsiderId in ipairs(allTypesUnitsToConsider) do
			local unitDefId = spGetUnitDefID(unitToConsiderId)
			if unitDefId == buildId then
				unitsToConsider[i] = unitToConsiderId
				i = i + 1
			end
			if conDefs[unitDefId] then
				consToConsider[consNum] = unitToConsiderId
				consNum = consNum + 1
			end
		end
	end
	for _,unitToConsiderId in ipairs(unitsToConsider) do
		local build = select(5, spGetUnitHealth(unitToConsiderId))
		if build and build < 1 then
			assistBuild(unitId, unitToConsiderId)
			return
		end
	end
	for _,conToConsiderId in ipairs(consToConsider) do
		local buildingPosition = isBuildingUnitDef(conToConsiderId, buildId)
		if buildingPosition then
			spGiveOrderToUnit(unitId, -buildId, buildingPosition, {shift=true})
			return
		end
	end

	buildCloseTo(unitId, buildId, x, y, z)
end

local function unitVec(x,y)
	return x/sqrt(x*x+y*y), y/sqrt(x*x+y*y)
end

local function isBeingBuilt(unitId)
	local _, _, _, _, buildProgress = spGetUnitHealth(unitId)
	return buildProgress < 1
end

local function placeFac(facDefID, teamId)
	local data = teamdata[teamId]
	if spGetTeamUnitDefCount(teamId, facDefID) == 0 then
		for unitId,_ in pairs(data.cons) do
			local x, y, z = spGetUnitPosition(unitId)
			local xx = x - 150
			local zz = z
			local yy = max(0, spGetGroundHeight(xx, zz))
			buildCloseTo(unitId, facDefID, xx, yy, zz)
			data.startpos = {xx, zz}
			--startpos = {xx, zz}
			--printThing("startpos", thisTeamData.startpos, "")
			--printThing("teamdata", thisTeamData, "")
			--printThing("teamdataAll", teamdata, "")
			spSendLuaRulesMsg('sethaven|' .. xx .. '|' .. yy .. '|' .. zz )
		end
	end
end

local function isXInRange(teamId, x, z, radius, unitDefID, beingBuiltCounts)
	local inRangeUnits = spGetUnitsInCylinder (x, z, radius, teamId)
	for _, unitId in pairs(inRangeUnits) do
		if spGetUnitDefID(unitId) == unitDefID and (beingBuiltCounts or not isBeingBuilt(unitId)) then
			return true
		end
	end
	return false
end

local function needMoreE(teamId)
	local _, _, _, mIncome = spGetTeamResources(teamId, "metal")
	local energy, _, _, _ = spGetTeamResources(teamId, "energy")
	Echo("current e: ")
	Echo(energy)
	local eIncome = spGetTeamRulesParam(teamId, "OD_energyIncome") or 0
	local frame = Spring.GetGameFrame()
	local frameMulti = (1 + frame / (30 * 60 * 3) )
	return eIncome <= mIncome * frameMulti or (eIncome < 10 and energy < 300)
end

local function tryClaimNearestMex(teamId, unitId)
	local mexBuildOwners = teamdata[teamId].mexBuildOwners
	local x, y, z = spGetUnitPosition(unitId)
	local adjustdX, adjustedZ = x + math.random(-100, 100), z + math.random(-100, 100) -- Slight bunching reduction
	local spots = GetClosestBuildableMetalSpots(adjustdX, adjustedZ, teamId)
	if #spots == 0 then
		return false
	else
		local cmdQueue = spGetUnitCommands(unitId, 2)
		if (#cmdQueue == 0) then
			--printThing("mexBuildOwners", mexBuildOwners)
			for i,spotData in ipairs(spots) do
				local spot = spotData.bestSpot
				local spotKey = tostring(spot.x) .. "_" .. tostring(spot.z)
				if not mexBuildOwners[spotKey] then
					--Echo("Found unclaimed mex " .. spotKey)
					local xx = spot.x
					local zz = spot.z
					local yy = max(0, spGetGroundHeight(xx, zz))
					HandleAreaMex(nil, xx, yy, zz, 100, {alt=false}, {unitId})
					--Echo("Claimed mex " .. spotKey)
					return true
				end
			end
		end
	end
	return false
end

local function getClosestUngriddedMex(teamId, x, y, z)
	local mexes = spGetTeamUnitsByDefs(teamId, mexDefID)
	local maxOverdriveFactor = 0
	local mexData = {}
	local mexNum = 0
	for _, mexId in pairs(mexes) do
		--local mexMetal, _,_,_ = spGetUnitResources(mexId)
		local totalMexMetal = (spGetUnitRulesParam(mexId, "current_metalIncome") or 0)
		local eDrain = (spGetUnitRulesParam(mexId, "overdrive_energyDrain") or 0)
		local mexMetal = totalMexMetal / (1 + sqrt(eDrain)/4)
		local overDriveFactor = eDrain / mexMetal
		if mexMetal == 0 then
			overDriveFactor = 0
		end
		if maxOverdriveFactor < overDriveFactor then
			maxOverdriveFactor = overDriveFactor
		end

		mexNum = mexNum + 1
		local mx, my, mz = spGetUnitPosition(mexId)
		local dx, dz = x - mx, z - mz
		local dist = dx*dx + dz*dz
		mexData[mexNum] = {
			id = mexId,
			dist = dist,
			overDriveFactor = overDriveFactor
		}
	end
	local maxMexData = {}
	local numMaxMex = 1
	for mexArrId, mexDatum in pairs(mexData) do
		if mexDatum.overDriveFactor >= maxOverdriveFactor - 0.2 then -- Very differences in overdrive don't matter
			maxMexData[numMaxMex] = {
				id = mexDatum.id,
				dist = mexDatum.dist
			}
			mexData[mexArrId].dist = mexData[mexArrId].dist + 99999999
			numMaxMex = numMaxMex + 1
		end
	end
	table.sort(mexData, function (k1, k2) return k1.dist < k2.dist end )
	table.sort(maxMexData, function (k1, k2) return k1.dist < k2.dist end )
	--printThing("mexData", mexData)
	--printThing("maxMexData", maxMexData)
	return mexData[1].id, maxMexData[1].id
end

local function GetClosestPylonInGridToUnit(pylonId, unitId)
	local x, y, z = spGetUnitPosition(unitId)
	return GetClosestPylonInGrid(pylonId, x, z)
end

local gridConJobHunting = {}

local function conRoleOrders(teamId, unitId, thisTeamData)
	-- Keep existing orders
	if spGetUnitCommands(unitId, 0) > 0 then
		return
	end
	local role = thisTeamData.conRoles[unitId]
	--Echo("con role orders")
	--Echo(unitId)
	--Echo(role)
	local x, y, z = spGetUnitPosition(unitId)
	if role == GRIDDER then
		local ungridMexId, maxGridMexId = getClosestUngriddedMex(teamId, x, y, z)
		if ungridMexId == maxGridMexId then -- In this case we're E-stalling
			buildOrAssistCloseTo(unitId, solarDefID, teamId, x + 100, y, z - 50, 200)
		else
			if gridConJobHunting[unitId] and gridConJobHunting[unitId] + TEAM_SLOWUPDATE_RATE < spGetGameFrame() then -- Don't look for a new job on the first few frames after finishing to wait for grid reconnect
				local x1, y1, z1 = spGetUnitPosition(ungridMexId)
				Spring.MarkerAddPoint ( x1, y1, z1,"ungridMexId", true)
				local x2, y2, z2 = spGetUnitPosition(maxGridMexId)
				Spring.MarkerAddPoint ( x2, y2, z2,"maxGridMexId", true)
				local ungridPylonId, destPylonRadius = GetClosestPylonInGridToUnit(ungridMexId, maxGridMexId)
				local gridPylonId, sourcePylonRadius = GetClosestPylonInGridToUnit(maxGridMexId, ungridMexId)
				local xx, zz = getOneDistLengthTowardsUnit(sourcePylonRadius + pylonRadius + destPylonRadius - 100,gridPylonId, ungridPylonId)
				local yy = max(0, spGetGroundHeight(xx, zz))
				-- TODO: terraform if needed for pylons
				buildOrAssistCloseTo(unitId, pylonDefID, teamId, xx, yy, zz, 70)
				gridConJobHunting[unitId] = nil
			else
				if not gridConJobHunting[unitId] then
					gridConJobHunting[unitId] = spGetGameFrame()
				end
			end
		end

		--buildOrAssistCloseTo(unitId, pylonDefID, teamId, x + 100, y, z - 50, 300)
	elseif role == MEXER then
		tryClaimNearestMex(teamId, unitId)
	elseif role == E_MAKER then
		local eIncome = spGetTeamRulesParam(teamId, "OD_energyIncome") or 0
		if eIncome < 40 then
			HandleAreaMex(nil, x, y, z, 600, {alt=true, ctrl=true}, {unitId}, false)
			local cmdQueue = spGetUnitCommands(unitId, 2)
			if #cmdQueue == 0 then
				buildOrAssistCloseTo(unitId, solarDefID, teamId, x + 100, y, z - 150, 300)
				Echo("solar")
			end
		else
			if eIncome < 100 then
				buildOrAssistCloseTo(unitId, fusionDefID, teamId, x + 100, y, z - 50, 1200)
				Echo("fusion")
			else
				buildOrAssistCloseTo(unitId, singuDefID, teamId, x + 100, y, z - 50, 3000)
				Echo("singu")
			end
		end
	end
end

local function newConRoles(unitId, thisTeamData)
	if not thisTeamData.conRoles[unitId] then
		if thisTeamData.numMexers < 2 then
			thisTeamData.conRoles[unitId] = MEXER
			thisTeamData.numMexers = thisTeamData.numMexers + 1
		elseif thisTeamData.numEMakers < 2 then
			thisTeamData.conRoles[unitId] = E_MAKER
			thisTeamData.numEMakers = thisTeamData.numEMakers + 1
		elseif thisTeamData.numMexers < 3 then
			thisTeamData.conRoles[unitId] = MEXER
			thisTeamData.numMexers = thisTeamData.numMexers + 1
		elseif thisTeamData.numEMakers < 4 then
			thisTeamData.conRoles[unitId] = E_MAKER
			thisTeamData.numEMakers = thisTeamData.numEMakers + 1
		elseif thisTeamData.numGridders * 6 < thisTeamData.numEMakers - 2 then
			thisTeamData.conRoles[unitId] = GRIDDER
			thisTeamData.numGridders = thisTeamData.numGridders + 1
		else
			thisTeamData.conRoles[unitId] = E_MAKER
			thisTeamData.numEMakers = thisTeamData.numEMakers + 1
		end
		printThing("thisTeamData.conRoles", thisTeamData.conRoles)
		local x, y, z = spGetUnitPosition(unitId)
		--Spring.MarkerAddPoint ( x, y, z, thisTeamData.conRoles[unitId], true)
	end
end

local function startAreaConOrders(teamId, unitId)
	local current, storage, _, income = spGetTeamResources(teamId, "metal")
	local facs = spGetTeamUnitsByDefs(teamId, cloakfacDefID)
	local x, y, z = spGetUnitPosition(unitId)
	local facX, facY, facZ = spGetUnitPosition(facs[1])
	--Echo("Storage " .. storage)
	if storage < HIDDEN_STORAGE + 100 and not isXInRange(teamId, facX, facZ, 9000, storageDefID, true)  then
		local xx = x - 100
		local zz = z
		local yy = max(0, spGetGroundHeight(xx, zz))

		buildOrAssistCloseTo(unitId, storageDefID, teamId, xx, yy, zz, 2000)
		return
	end
end

local function newConOrders(teamId, unitId, thisTeamData)
	startAreaConOrders(teamId, unitId)
	conRoleOrders(teamId, unitId, thisTeamData)
end

local function oldConOrders(teamId, cmdQueue, unitId, thisTeamData)
	local facs = spGetTeamUnitsByDefs(teamId, cloakfacDefID)
	local x, y, z = spGetUnitPosition(unitId)
	-- Rebuild fac
	if #facs == 0 then
		-- TODO
		buildOrAssistCloseTo(unitId, cloakfacDefID, teamId, x + 150, y, z + 50, 2000)
		return
	end

	local startpos = thisTeamData.startpos

	if sqDistance(x,z, startpos[1], startpos[2]) < 1000000 then
		--Echo("new con orders")
		startAreaConOrders(teamId, unitId)
	end

	-- Always reclaim
	--if hard then
	--	spGiveOrderToUnit(unitId, 90, {x, y, z, 300}, {shift=true})
	--end
	conRoleOrders(teamId, unitId, thisTeamData)
end

local function factoryOrders(teamId, unitId, frame)
	if spGetFactoryCommands(unitId, 0) == 0 then
		spGiveOrderToUnit(unitId, -conjurerDefID, {}, {})
		spGiveOrderToUnit(unitId, 115, {1}, {}) -- repeat build
		spGiveOrderToUnit(unitId, 34220, {0}, {}) -- priority low
	end
	if frame > 3000 then
		local current, _, _, income = spGetTeamResources(teamId, "metal")
		if current > 200 then
			spGiveOrderToUnit(unitId, 13921, {1}, {})
		else
			spGiveOrderToUnit(unitId, 13921, {0}, {})
		end
	end
end

local function updateRoleList(teamData)
	for unitId,role in pairs(teamData.conRoles) do
		if spGetUnitIsDead ( unitId ) == nil then
			if role == MEXER then
				teamData.numMexers = teamData.numMexers - 1
			elseif role == GRIDDER then
				teamData.numGridders = teamData.numGridders - 1
			elseif role == E_MAKER then
				teamData.numEMakers = teamData.numEMakers - 1
			end
		end
	end
end

local function populateMexBuildClaimList(teamId, teamData)
	local teamMexBuildOwners = {}
	for unitId,_ in pairs(teamData.cons) do
		local cmdQueue = spGetUnitCommands(unitId, -1) -- TODO: very inefficient
		local mexIsClaimed = false
		for _, cmd in pairs(cmdQueue) do
			if cmd.id == -mexDefID then
				mexIsClaimed = cmd
			end
		end
		if mexIsClaimed then
			local params = mexIsClaimed.params
			local x, z = params[1], params[3]
			local spot = GetClosestBuildableMetalSpot(x, z, teamId)
			local spotKey = tostring(spot.x) .. "_" .. tostring(spot.z)
			teamMexBuildOwners[spotKey] = unitId
		end
	end
	teamData.mexBuildOwners = teamMexBuildOwners
end

local ecoBuildings = {mexDefID, solarDefID, fusionDefID, singuDefID, pylonDefID}
local function adjustEcoPriorities(teamId)
	for _, unitDefID in ipairs(ecoBuildings) do
		local unitsOfType = spGetTeamUnitsByDefs ( teamId, unitDefID )
		if (not (unitDefID == singuDefID)) or #unitsOfType > 1 then
			local buildingToHighPriority = -1
			local bestPercentageComplete = -1
			for _, unitID in ipairs(unitsOfType) do
				local _, _, _, _, buildProgress = spGetUnitHealth(unitID)
				if buildProgress < 1 then
					if buildProgress > bestPercentageComplete then
						bestPercentageComplete = buildProgress
						buildingToHighPriority = unitID
					end
				end
			end
			if buildingToHighPriority > 0 then
				local x,y,z = spGetUnitPosition(buildingToHighPriority)
				SetPriorityState(buildingToHighPriority, 2, CMD_PRIORITY)
			end
		end
	end
end

function gadget:GameFrame(frame)
	if not gadgetHandler:IsSyncedCode() then
		return
	end
    for teamId, data in pairs(teamdata) do
		local thisTeamData = teamdata[teamId]
		if frame < 5 then
			placeFac(cloakfacDefID, teamId)
			for unitId,_ in pairs(data.cons) do
				local unitDef = spGetUnitDefID(unitId)
				if not (unitDef == cloakfacDefID) then
					newConRoles(unitId, thisTeamData)
				end
			end
		else
			GG.SetEnergyReserved(teamId, 50)
			GG.SetMetalReserved(teamId, 50)
			populateMexBuildClaimList(teamId, data)
			updateRoleList(data)
			-- Constructors and factories
			for unitId,_ in pairs(data.cons) do
				local cmdQueue = spGetUnitCommands(unitId, 2)
				local unitDef = spGetUnitDefID(unitId)
				if not isBeingBuilt(unitId) then
					if (#cmdQueue == 0) then
						-- Factories
						if unitDef == cloakfacDefID then
							factoryOrders(teamId, unitId, frame)
						else
							-- Constructors
							oldConOrders(teamId, cmdQueue, unitId, thisTeamData)
						end
					end
				else
					if unitDef == cloakfacDefID then
					else
						-- Orders for under construction cons
						newConOrders(teamId, unitId, thisTeamData)
						newConRoles(unitId, thisTeamData)
					end
				end
			end
			for _,unitId in ipairs(spGetTeamUnitsByDefs(teamId, caretakerDefID)) do
				--Echo("Found caretaker")
				local cmdNum = spGetUnitCommands(unitId, 0)
				if cmdNum == 0 then
					--Echo("Giving caretaker order")
					local x, y, z = spGetUnitPosition(unitId)
					spGiveOrderToUnit(unitId, CMD.PATROL, {x+100, y, z+100}, 0)
				end
			end
		end
		if frame%5 then
			adjustEcoPriorities(teamId)
		end
	end
	ai_lib_GameFrame(frame)
end

function gadget:UnitGiven(unitID, unitDefID, newTeamID, teamID)
	ai_lib_UnitGiven(unitID, unitDefID, newTeamID, teamID)
end

function gadget:GameStart() 
    -- Initialise AI for all teams that are set to use it
	Echo("Game start called")
	if next(teamdata) == nil then
		initializeTeams()
	end
end
Echo("Reached EOF3")