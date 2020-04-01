VFS.Include("LuaUI/Widgets/MyUtils.lua")
VFS.Include("LuaRules/Configs/customcmds.h.lua")

local widgetName = "Eco Helper"

function widget:GetInfo()
  return {
    name      = widgetName,
    desc      = "Reminds about various economic events, automates some stuff",
    author    = "ivand",
    date      = "2017",
    license   = "public",
    layer     = 0,
    enabled   = true  --  loaded by default?
  }
end

--[[
local widgetEnabled = true

options_path = "Settings/Interface/" .. widgetName
options_order = { "enabled", "showidle", "showeco", "showwreckfields" }
options =
{
	enabled = {
		name = "Enable widget",
		type = "button",
		value = true,
		OnChange = function(self)
			widgetEnabled = self.value
		end
	}
}
]]--

local screenx, screeny

local myTeamID
local myAllyTeamID
local function UpdateTeamAndAllyTeamID()
	myTeamID = Spring.GetMyTeamID()
	myAllyTeamID = Spring.GetMyAllyTeamID()
end

local Benchmark = VFS.Include("LuaUI/Widgets/libs/Benchmark.lua")
local benchmark = Benchmark.new()


local TableEcho = Spring.Utilities.TableEcho

local iconTypes = VFS.Include("LuaUI/Configs/icontypes.lua")

local function ToggleIdleOne(uId)
	--Spring.Echo("ToggleIdleOne")
	local commandQueueTableSize=spGetCommandQueue(uId, 0)
	--if not(commandQueueTable) or #commandQueueTable==0 then
	--Spring.Echo("#commandQueueTable"..#commandQueueTable)
	if commandQueueTableSize==0 then
		local unitDefId=spGetUnitDefID(uId)
		widget:UnitIdle(uId, unitDefId, myTeamID)
	end
end

local function ToggleIdle()
	local units=spGetTeamUnits(myTeamID)
	for _, uId in pairs(units) do
		ToggleIdleOne(uId)
	end
end


local stateCommands = {
	[CMD.ONOFF] = true,
	[CMD.FIRE_STATE] = true,
	[CMD.MOVE_STATE] = true,
	[CMD.REPEAT] = true,
	[CMD.CLOAK] = true,
	[CMD.STOCKPILE] = true,
	[CMD.TRAJECTORY] = true,
	[CMD.IDLEMODE] = true,
	[CMD_GLOBAL_BUILD] = true,
	[CMD_STEALTH] = true,
	[CMD_CLOAK_SHIELD] = true,
	[CMD_UNIT_FLOAT_STATE] = true,
	[CMD_PRIORITY] = true,
	[CMD_MISC_PRIORITY] = true,
	[CMD_RETREAT] = true,
	[CMD_UNIT_BOMBER_DIVE_STATE] = true,
	[CMD_AP_FLY_STATE] = true,
	[CMD_AP_AUTOREPAIRLEVEL] = true,
	[CMD_UNIT_SET_TARGET] = true,
	[CMD_UNIT_CANCEL_TARGET] = true,
	[CMD_UNIT_SET_TARGET_CIRCLE] = true,
	[CMD_ABANDON_PW] = true,
	[CMD_RECALL_DRONES] = true,
	[CMD_UNIT_KILL_SUBORDINATES] = true,
	[CMD_UNIT_AI] = true,
	[CMD_WANT_CLOAK] = true,
	[CMD_DONT_FIRE_AT_RADAR] = true,
	[CMD_AIR_STRAFE] = true,
	[CMD_PREVENT_OVERKILL] = true,
	[CMD_SELECTION_RANK] = true,
}

local energyUnitDefs = {
	[UnitDefNames["energywind"].id] = true,
	[UnitDefNames["energysolar"].id] = true,
	[UnitDefNames["energygeo"].id] = true,
	[UnitDefNames["energyfusion"].id] = true,
}
local storageUnitDef = UnitDefNames["staticstorage"].id
local mexUnitDef = UnitDefNames["staticmex"].id
local caretakerUnitDef = UnitDefNames["staticcon"].id
local caretakerBuildRange = UnitDefs[caretakerUnitDef].buildDistance

local factoriesAndHubs = {
	[UnitDefNames["factoryamph"].id] = true,
	[UnitDefNames["factorycloak"].id] = true,
	[UnitDefNames["factorygunship"].id] = true,
	[UnitDefNames["factoryhover"].id] = true,
	[UnitDefNames["factoryjump"].id] = true,
	[UnitDefNames["factoryplane"].id] = true,
	[UnitDefNames["factoryshield"].id] = true,
	[UnitDefNames["factoryship"].id] = true,
	[UnitDefNames["factoryspider"].id] = true,
	[UnitDefNames["factorytank"].id] = true,
	[UnitDefNames["factoryveh"].id] = true,
	[UnitDefNames["striderhub"].id] = true,
}


local heavenRadius = 160
local heavenRadiusSq = heavenRadius * heavenRadius
local heavenZones = {}

local function FindNearestHeavenZone(x, z)
	local minZoneID = nil
	local minZoneDist = math.huge

	for hash, heavenZone in pairs(heavenZones) do
		local DistSq = (heavenZone.x - x)^2 + (heavenZone.z - z)^2
		if (DistSq <= heavenRadiusSq) and (DistSq < minZoneDist) then
			minZoneID = hash
			minZoneDist = DistSq
		end
	end
	if minZoneID ~= nil then
		return minZoneID, math.sqrt(minZoneDist), heavenZones[minZoneID].x, heavenZones[minZoneID].z
	else
		return nil
	end
end

local function UpdateExistingHeavenZones()
	local heavenCount = Spring.GetTeamRulesParam(myTeamID, "haven_count")
	for i = 1, heavenCount do
		local x = Spring.GetTeamRulesParam(myTeamID, "haven_x" .. i)
		local z = Spring.GetTeamRulesParam(myTeamID, "haven_z" .. i)
		local hash = z + x * mapSizeZ
		heavenZones[hash] = {
			thisWidget = false,
			unitID = nil,
			x = x,
			z = z,
		}
	end
end


local scanInterval = 1 * Game.gameSpeed
local scanForRemovalInterval = 10 * Game.gameSpeed --10 sec

local minDistance = 300
local minSqDistance = minDistance^2
local minPoints = 2
local minFeatureMetal = 8 --flea

local knownFeatures = {}

local featureNeighborsMatrix = {}
local function UpdateFeatureNeighborsMatrix(fID, added, posChanged, removed)
	local fInfo = knownFeatures[fID]

	if added then
		featureNeighborsMatrix[fID] = {}
		for fID2, fInfo2 in pairs(knownFeatures) do
			if fID2 ~= fID then --don't include self into featureNeighborsMatrix[][]
				local sqDist = (fInfo.x - fInfo2.x)^2 + (fInfo.z - fInfo2.z)^2
				if sqDist <= minSqDistance then
					featureNeighborsMatrix[fID][fID2] = true
					featureNeighborsMatrix[fID2][fID] = true
				end
			end
		end
	end

	if removed then
		for fID2, _ in pairs(featureNeighborsMatrix[fID]) do
			featureNeighborsMatrix[fID2][fID] = nil
			featureNeighborsMatrix[fID][fID2] = nil
		end
	end

	if posChanged then
		UpdateFeatureNeighborsMatrix(fID, false, false, true) --remove
		UpdateFeatureNeighborsMatrix(fID, true, false, false) --add again
	end
end

local featureClusters = {}

local E2M = 2 / 70 --solar ratio

local featuresUpdated = false
local clusterMetalUpdated = false

local function UpdateFeatures(gf)
	benchmark:Enter("UpdateFeatures")
	featuresUpdated = false
	clusterMetalUpdated = false
	benchmark:Enter("UpdateFeatures 1loop")
	for _, fID in ipairs(Spring.GetAllFeatures()) do
		local metal, _, energy = Spring.GetFeatureResources(fID)
		metal = metal + energy * E2M

		if (not knownFeatures[fID]) and (metal >= minFeatureMetal) then --first time seen
			knownFeatures[fID] = {}
			knownFeatures[fID].lastScanned = gf

			--local fx, fy, fz = Spring.GetFeaturePosition(fID)
			local fx, _, fz = Spring.GetFeaturePosition(fID)
			local fy = Spring.GetGroundHeight(fx, fz)
			knownFeatures[fID].x = fx
			knownFeatures[fID].y = fy
			knownFeatures[fID].z = fz

			knownFeatures[fID].isGaia = (Spring.GetFeatureTeam(fID) == gaiaTeamId)
			knownFeatures[fID].height = Spring.GetFeatureHeight(fID)
			knownFeatures[fID].drawAlt = ((fy > 0 and fy) or 0) + knownFeatures[fID].height + 10

			knownFeatures[fID].metal = metal

			UpdateFeatureNeighborsMatrix(fID, true, false, false)
			featuresUpdated = true
		end

		if knownFeatures[fID] and gf - knownFeatures[fID].lastScanned >= scanInterval then
			knownFeatures[fID].lastScanned = gf

			--local fx, fy, fz = Spring.GetFeaturePosition(fID)
			local fx, _, fz = Spring.GetFeaturePosition(fID)
			local fy = Spring.GetGroundHeight(fx, fz)

			if knownFeatures[fID].x ~= fx or knownFeatures[fID].y ~= fy or knownFeatures[fID].z ~= fz then
				knownFeatures[fID].x = fx
				knownFeatures[fID].y = fy
				knownFeatures[fID].z = fz

				knownFeatures[fID].drawAlt = ((fy > 0 and fy) or 0) + knownFeatures[fID].height + 10

				UpdateFeatureNeighborsMatrix(fID, false, true, false)
				featuresUpdated = true
			end

			if knownFeatures[fID].metal ~= metal then
				--Spring.Echo("knownFeatures[fID].metal ~= metal", metal)
				if knownFeatures[fID].clID then
					--Spring.Echo("knownFeatures[fID].clID")
					local thisCluster = featureClusters[ knownFeatures[fID].clID ]
					thisCluster.metal = thisCluster.metal - knownFeatures[fID].metal
					if metal >= minFeatureMetal then
						thisCluster.metal = thisCluster.metal + metal
						knownFeatures[fID].metal = metal
						--Spring.Echo("clusterMetalUpdated = true", thisCluster.metal)
						clusterMetalUpdated = true
					else
						UpdateFeatureNeighborsMatrix(fID, false, false, true)
						knownFeatures[fID] = nil
						featuresUpdated = true
					end
				end
			end
		end
	end
	benchmark:Leave("UpdateFeatures 1loop")

	benchmark:Enter("UpdateFeatures 2loop")
	for fID, fInfo in pairs(knownFeatures) do

		if fInfo.isGaia and Spring.ValidFeatureID(fID) == false then
			--Spring.Echo("fInfo.isGaia and Spring.ValidFeatureID(fID) == false")

			UpdateFeatureNeighborsMatrix(fID, false, false, true)
			fInfo = nil
			knownFeatures[fID] = nil
			featuresUpdated = true
		end

		if fInfo and gf - fInfo.lastScanned >= scanForRemovalInterval then --long time unseen features, maybe they were relcaimed or destroyed?
			local los = Spring.IsPosInLos(fInfo.x, fInfo.y, fInfo.z, myAllyTeamID)
			if los then --this place has no feature, it's been moved or reclaimed or destroyed
				--Spring.Echo("this place has no feature, it's been moved or reclaimed or destroyed")

				UpdateFeatureNeighborsMatrix(fID, false, false, true)
				fInfo = nil
				knownFeatures[fID] = nil
				featuresUpdated = true
			end
		end

		if fInfo and featuresUpdated then
			knownFeatures[fID].clID = nil
		end
	end
	benchmark:Leave("UpdateFeatures 2loop")
	benchmark:Leave("UpdateFeatures")
end

local Optics = VFS.Include("LuaUI/Widgets/libs/Optics.lua")

--local minRequiredForce = 1

local function ClusterizeFeatures()
	benchmark:Enter("ClusterizeFeatures")
	local pointsTable = {}

	local unclusteredPoints  = {}

	--Spring.Echo("#knownFeatures", #knownFeatures)

	for fID, fInfo in pairs(knownFeatures) do
		pointsTable[#pointsTable + 1] = {
			x = fInfo.x,
			z = fInfo.z,
			fID = fID,
		}
		unclusteredPoints[fID] = true
	end

	--TableEcho(featureNeighborsMatrix, "featureNeighborsMatrix")

	local opticsObject = Optics.new(pointsTable, featureNeighborsMatrix, minPoints, benchmark)
	benchmark:Enter("opticsObject:Run()")
	opticsObject:Run()
	benchmark:Leave("opticsObject:Run()")

	benchmark:Enter("opticsObject:Clusterize(minDistance)")
	featureClusters = opticsObject:Clusterize(minDistance)
	benchmark:Leave("opticsObject:Clusterize(minDistance)")

	--Spring.Echo("#featureClusters", #featureClusters)


	for i = 1, #featureClusters do
		local thisCluster = featureClusters[i]

		thisCluster.xmin = math.huge
		thisCluster.xmax = -math.huge
		thisCluster.zmin = math.huge
		thisCluster.zmax = -math.huge


		local metal = 0
		for j = 1, #thisCluster.members do
			local fID = thisCluster.members[j]
			local fInfo = knownFeatures[fID]

			thisCluster.xmin = math.min(thisCluster.xmin, fInfo.x)
			thisCluster.xmax = math.max(thisCluster.xmax, fInfo.x)
			thisCluster.zmin = math.min(thisCluster.zmin, fInfo.z)
			thisCluster.zmax = math.max(thisCluster.zmax, fInfo.z)

			metal = metal + fInfo.metal
			knownFeatures[fID].clID = i
			unclusteredPoints[fID] = nil
		end

		thisCluster.metal = metal
	end

	for fID, _ in pairs(unclusteredPoints) do --add Singlepoint featureClusters
		local fInfo = knownFeatures[fID]
		local thisCluster = {}

		thisCluster.members = {fID}
		thisCluster.metal = fInfo.metal

		thisCluster.xmin = fInfo.x
		thisCluster.xmax = fInfo.x
		thisCluster.zmin = fInfo.z
		thisCluster.zmax = fInfo.z

		featureClusters[#featureClusters + 1] = thisCluster
		knownFeatures[fID].clID = #featureClusters
	end

	benchmark:Leave("ClusterizeFeatures")
end

local ConvexHull = VFS.Include("LuaUI/Widgets/libs/ConvexHull.lua")

local minDim = 100

local featureConvexHulls = {}
local function ClustersToConvexHull()
	benchmark:Enter("ClustersToConvexHull")
	featureConvexHulls = {}
	--Spring.Echo("#featureClusters", #featureClusters)
	for fc = 1, #featureClusters do
		local clusterPoints = {}
		benchmark:Enter("ClustersToConvexHull 1st Part")
		for fcm = 1, #featureClusters[fc].members do
			local fID = featureClusters[fc].members[fcm]
			clusterPoints[#clusterPoints + 1] = {
				x = knownFeatures[fID].x,
				y = knownFeatures[fID].drawAlt,
				z = knownFeatures[fID].z
			}
			--Spring.MarkerAddPoint(knownFeatures[fID].x, 0, knownFeatures[fID].z, string.format("%i(%i)", fc, fcm))
		end
		benchmark:Leave("ClustersToConvexHull 1st Part")

		--- TODO perform pruning as described in the article below, if convex hull algo will start to choke out
		-- http://mindthenerd.blogspot.ru/2012/05/fastest-convex-hull-algorithm-ever.html

		benchmark:Enter("ClustersToConvexHull 2nd Part")
		local convexHull
		if #clusterPoints >= 3 then
			--Spring.Echo("#clusterPoints >= 3")
			--convexHull = ConvexHull.JarvisMarch(clusterPoints, benchmark)
			convexHull = ConvexHull.MonotoneChain(clusterPoints, benchmark) --twice faster
		else
			--Spring.Echo("not #clusterPoints >= 3")
			local thisCluster = featureClusters[fc]

			local xmin, xmax, zmin, zmax = thisCluster.xmin, thisCluster.xmax, thisCluster.zmin, thisCluster.zmax

			local dx, dz = xmax - xmin, zmax - zmin

			if dx < minDim then
				xmin = xmin - (minDim - dx) / 2
				xmax = xmax + (minDim - dx) / 2
			end

			if dz < minDim then
				zmin = zmin - (minDim - dz) / 2
				zmax = zmax + (minDim - dz) / 2
			end

			local height = clusterPoints[1].y
			if #clusterPoints == 2 then
				height = math.max(height, clusterPoints[2].y)
			end

			convexHull = {
				{x = xmin, y = height, z = zmin},
				{x = xmax, y = height, z = zmin},
				{x = xmax, y = height, z = zmax},
				{x = xmin, y = height, z = zmax},
			}
		end

		local cx, cz, cy = 0, 0, 0
		for i = 1, #convexHull do
			local convexHullPoint = convexHull[i]
			cx = cx + convexHullPoint.x
			cz = cz + convexHullPoint.z
			cy = math.max(cy, convexHullPoint.y)
		end
		benchmark:Leave("ClustersToConvexHull 2nd Part")

		benchmark:Enter("ClustersToConvexHull 3rd Part")
		local totalArea = 0
		local pt1 = convexHull[1]
		for i = 2, #convexHull - 1 do
			local pt2 = convexHull[i]
			local pt3 = convexHull[i + 1]
			--Heron formula to get triangle area
			local a = math.sqrt((pt2.x - pt1.x)^2 + (pt2.z - pt1.z)^2)
			local b = math.sqrt((pt3.x - pt2.x)^2 + (pt3.z - pt2.z)^2)
			local c = math.sqrt((pt3.x - pt1.x)^2 + (pt3.z - pt1.z)^2)
			local p = (a + b + c)/2 --half perimeter

			local triangleArea = math.sqrt(p * (p - a) * (p - b) * (p - c))
			totalArea = totalArea + triangleArea
		end
		benchmark:Leave("ClustersToConvexHull 3rd Part")

		convexHull.area = totalArea
		convexHull.center = {x = cx/#convexHull, z = cz/#convexHull, y = cy + 1}

		featureConvexHulls[fc] = convexHull

--[[
		for i = 1, #convexHull do
			Spring.MarkerAddPoint(convexHull[i].x, convexHull[i].y, convexHull[i].z, string.format("C%i(%i)", fc, i))
		end
]]--
		benchmark:Leave("ClustersToConvexHull")
	end
end


--local reclaimColor = (1.0, 0.2, 1.0, 0.7);
local reclaimColor = {1.0, 0.2, 1.0, 0.04}
local reclaimEdgeColor = {1.0, 0.2, 1.0, 0.1}
local flashColor = {1.0, 0.0, 0.0, 0}
local flashMetalTextColor = {1.0, 0.0, 0.0, 0.9}

local flashIdleTextColor = {1.0, 1.0, 0.0, 0.9}
local idleFillColor = {1.0, 1.0, 0.0, 0.4}
local idleModelColor = {1.0, 1.0, 0.0, 1.0}

local flashEStallTextColor = {1.0, 0.0, 1.0, 0.9}

local textScale = {1.0, 0.4, 1.0}


local function ColorMul(scalar, actionColor)
	return {scalar * actionColor[1], scalar * actionColor[2], scalar * actionColor[3], actionColor[4]}
end

function widget:Initialize()
	CheckSpecState(widgetName)
	curModID = string.upper(Game.modShortName or "")
	if ( curModID ~= "ZK" ) then
		widgetHandler:RemoveWidget()
		return
	end

	UpdateTeamAndAllyTeamID()

	--local iconDist = Spring.GetConfigInt("UnitIconDist")
	UpdateExistingHeavenZones()

	screenx, screeny = widgetHandler:GetViewSizes()

	local units=spGetTeamUnits(myTeamID)
	for _, unitID in pairs(units) do
		widget:UnitGiven(unitID, Spring.GetUnitDefID(unitID), myTeamID, nil)
	end
	--ToggleIdle()
end

function widget:TeamChanged(teamID)
	UpdateTeamAndAllyTeamID()
end

function widget:PlayerChanged(playerID)
	UpdateTeamAndAllyTeamID()
end

function widget:PlayerAdded(playerID)
	UpdateTeamAndAllyTeamID()
end

function widget:PlayerRemoved(playerID)
	UpdateTeamAndAllyTeamID()
end

function widget:TeamDied(teamID)
	UpdateTeamAndAllyTeamID()
end

function widget:TeamChanged(teamID)
	UpdateTeamAndAllyTeamID()
end

local idleList={}

function widget:UnitIdle(unitID, unitDefID, unitTeam)
	if unitTeam == myTeamID then
		local units=FilterMobileConstructors({unitID})
		local stunnedOrInbuild = Spring.GetUnitIsStunned(unitID)
		if #units == 1 and (not stunnedOrInbuild) then
			local gameFrame = spGetGameFrame()
			idleList[unitID] = {}
			idleList[unitID].gameFrame = gameFrame
			--local dims = Spring.GetUnitDefDimensions(unitDefID)
			--local uDef = UnitDefs[unitDefID]


			--idleList[unitID].radius = math.round( math.sqrt( (uDef.zsize or uDef.ysize)^2 + uDef.xsize^2 ) ) * 4
			--local factor = 4 * 1.2
			--factor = factor * (tonumber(uDef.customParams.selection_scale) or 1)

			--idleList[unitID].radius = dims.radius
			--idleList[unitID].radius = math.round( math.sqrt( uDef.zsize^2 + uDef.xsize^2 ) ) * factor
			--idleList[unitID].radius = math.sqrt( 2 * math.max( uDef.zsize, uDef.xsize ) ^ 2 ) * factor
		end
	end
end

--[[
local idleCancelCommands={
	[CMD.WAIT]=true, --in case one wants to mute widget
	[CMD.MOVE]=true,
	[CMD.ATTACK]=true,
	[CMD.RECLAIM]=true,
	[CMD.REPAIR]=true,
	[CMD.FIGHT]=true,
	[CMD.PATROL]=true,
	[CMD.AREA_ATTACK]=true,
	[CMD.GUARD]=true,
	[CMD.DGUN]=true,
	[CMD.RESURRECT]=true,
	[CMD_UNIT_SET_TARGET]=true,
	[CMD_BUILD]=true,
	[CMD_AREA_GUARD]=true,
	[CMD_AREA_MEX]=true,
	[CMD_MORPH]=true,
	[CMD_JUMP]=true,
	[CMD_ONECLICK_WEAPON]=true,
	--to be extended
}
]]--

local stateCommands = {
	[CMD.ONOFF] = true,
	[CMD.FIRE_STATE] = true,
	[CMD.MOVE_STATE] = true,
	[CMD.REPEAT] = true,
	[CMD.CLOAK] = true,
	[CMD.STOCKPILE] = true,
	[CMD.TRAJECTORY] = true,
	[CMD.IDLEMODE] = true,
	[CMD_GLOBAL_BUILD] = true,
	[CMD_STEALTH] = true,
	[CMD_CLOAK_SHIELD] = true,
	[CMD_UNIT_FLOAT_STATE] = true,
	[CMD_PRIORITY] = true,
	[CMD_MISC_PRIORITY] = true,
	[CMD_RETREAT] = true,
	[CMD_UNIT_BOMBER_DIVE_STATE] = true,
	[CMD_AP_FLY_STATE] = true,
	[CMD_AP_AUTOREPAIRLEVEL] = true,
	[CMD_UNIT_SET_TARGET] = true,
	[CMD_UNIT_CANCEL_TARGET] = true,
	[CMD_UNIT_SET_TARGET_CIRCLE] = true,
	[CMD_ABANDON_PW] = true,
	[CMD_RECALL_DRONES] = true,
	[CMD_UNIT_KILL_SUBORDINATES] = true,
	[CMD_UNIT_AI] = true,
	[CMD_WANT_CLOAK] = true,
	[CMD_DONT_FIRE_AT_RADAR] = true,
	[CMD_AIR_STRAFE] = true,
	[CMD_PREVENT_OVERKILL] = true,
	[CMD_SELECTION_RANK] = true,
}

local energyUnitDefs = {
	[UnitDefNames["energywind"].id] = true,
	[UnitDefNames["energysolar"].id] = true,
	[UnitDefNames["energygeo"].id] = true,
	[UnitDefNames["energyfusion"].id] = true,
}


local energyUnitsUnderConstruction = {}
local storageUnitsUnderConstruction = {}
local mexUnitsUnderConstruction = {}
local caretakerUnitsUnderConstruction = {}


function widget:UnitCommand(unitID, unitDefID, teamID, cmdID, cmdParams, cmdOptions)
	--if idleList[unitID] and	(cmdID<0 or idleCancelCommands[cmdID]) then
	if idleList[unitID] and	(cmdID < 0 or stateCommands[cmdID] == nil) then
		idleList[unitID] = nil
	end
end

function widget:UnitCmdDone(unitID, unitDefID, unitTeam, cmdID, cmdParams, cmdOpts, cmdTag)
	ToggleIdleOne(unitID)
end

function widget:UnitCreated(unitID, unitDefID, unitTeam)
	if (myTeamID == unitTeam) then
		if energyUnitDefs[unitDefID] then
			energyUnitsUnderConstruction[unitID] = Spring.GetUnitRulesParam(unitID, "buildpriority") or 1
		end
		if storageUnitDef == unitDefID then
			storageUnitsUnderConstruction[unitID] = Spring.GetUnitRulesParam(unitID, "buildpriority") or 1
		end
		if mexUnitDef == unitDefID then
			mexUnitsUnderConstruction[unitID] = Spring.GetUnitRulesParam(unitID, "buildpriority") or 1
		end
		if caretakerUnitDef == unitDefID then
			caretakerUnitsUnderConstruction[unitID] = Spring.GetUnitRulesParam(unitID, "buildpriority") or 1
		end
	end
	ToggleIdleOne(unitID)
end

function widget:UnitFinished(unitID, unitDefID, unitTeam)
	--Spring.Echo("UnitFinished", unitID)
	if (myTeamID == unitTeam) then
		if energyUnitDefs[unitDefID] then
			energyUnitsUnderConstruction[unitID] = nil
		end
		if storageUnitDef == unitDefID then
			storageUnitsUnderConstruction[unitID] = nil
		end
		if mexUnitDef == unitDefID then
			mexUnitsUnderConstruction[unitID] = nil
		end
		if caretakerUnitDef == unitDefID then
			caretakerUnitsUnderConstruction[unitID] = nil
		end
		-----
		if caretakerUnitDef == unitDefID then
			local x, y, z = Spring.GetUnitPosition(unitID)

			local nearbyFac = false
			local aroundUnits = Spring.GetUnitsInCylinder(x, z, caretakerBuildRange + 80)
			for i = 1, #aroundUnits do
				local unitID = aroundUnits[i]
				if factoriesAndHubs[Spring.GetUnitDefID(unitID)] then
					nearbyFac = true
				end
			end

			if not nearbyFac then
				local minZoneID = FindNearestHeavenZone(x, z)
				--Spring.Echo("minZoneID", minZoneID)
				if minZoneID == nil then
					--Spring.Echo("UnitFinished sethaven", unitID)
					Spring.SendLuaRulesMsg('sethaven|' .. x .. '|' .. y .. '|' .. z )
					local hash = z + x * mapSizeZ
					heavenZones[hash] = {
						thisWidget = true,
						unitID = unitID,
						x = x,
						z = z,
					}
				end
			end


		end
	end
	ToggleIdleOne(unitID)
end

function widget:UnitGiven(unitID, unitDefID, newTeam, oldTeam)
	if (myTeamID == newTeam) then
		local buildProg = select(5, Spring.GetUnitHealth(unitID))
		if buildProg == 1.0 then
			widget:UnitFinished(unitID, unitDefID, newTeam)
		else
			widget:UnitCreated(unitID, unitDefID, newTeam)
		end
	end
end

function widget:UnitTaken(unitID, unitDefID, oldTeam, newTeam)
	widget:UnitDestroyed(unitID, unitDefID, newTeam, nil, nil, nil)
end

function widget:UnitDestroyed(unitID, unitDefID, unitTeam, attackerID, attackerDefID, attackerTeam)
	--Spring.Echo("UnitDestroyed", unitID)
	if idleList[unitID] then
		idleList[unitID]=nil
	end
	if (myTeamID == unitTeam) then
		if energyUnitDefs[unitDefID] then
			energyUnitsUnderConstruction[unitID] = nil
		end
		if storageUnitDef == unitDefID then
			storageUnitsUnderConstruction[unitID] = nil
		end
		if mexUnitDef == unitDefID then
			mexUnitsUnderConstruction[unitID] = nil
		end
		---
		if caretakerUnitDef == unitDefID then
			caretakerUnitsUnderConstruction[unitID] = nil
			local x, y, z = Spring.GetUnitPosition(unitID)

			local thisZoneID = FindNearestHeavenZone(x, z)
			--Spring.Echo("thisZoneID", thisZoneID)
			if thisZoneID then
				local nearbyUnits = Spring.GetUnitsInCylinder(x, z, heavenRadius, unitTeam)
				--ePrintEx(nearbyUnits)
				local nearbyCaretaker = false
				for _, nearbyUnitID in ipairs(nearbyUnits) do
					local unitStatus = Spring.GetUnitIsDead(nearbyUnitID)
					--Spring.Echo("unitStatus", unitStatus)
					if unitStatus ~= nil and unitStatus == false then
						local nearbyUnitDefID = Spring.GetUnitDefID(nearbyUnitID)
						--Spring.Echo(UnitDefs[nearbyUnitDefID].humanName)
						if nearbyUnitDefID == caretakerUnitDef then
							nearbyCaretaker = true
							break
						end
					end
				end
				if not nearbyCaretaker then --kill HeavenZone
					--Spring.Echo("UnitDestroyed sethaven", unitID)
					Spring.SendLuaRulesMsg('sethaven|' .. x .. '|' .. y .. '|' .. z )
					heavenZones[thisZoneID] = nil
				end
			end
		end
	end
end

local flashIdleWorkers = false
local flashMetalExcess = false
local flashEnergyStall = false
local metalStall = false

local gracePeriod = 30 * 30 --first 30 seconds of the game
local magicNumber = 10000
local function CheckAndSetFlashMetalExcess(frame)
	if frame < gracePeriod then return end

	local mCurr, mStor, mPull, mInco, mExpe, mShar, mSent, mReci = spGetTeamResources(myTeamID, "metal")
	local eCurr, eStor, ePull, eInco, eExpe, eShar, eSent, eReci = spGetTeamResources(myTeamID, "energy")

	mStor, eStor  = mStor - magicNumber, eStor - magicNumber

	local mStorageLeft = mStor-mCurr
	if mStorageLeft < 0 then mStorageLeft = 0 end

	if eCurr < 0 then eCurr = 1 end
	if mCurr < 0 then mCurr = 1 end

	local mProfit=mInco - mExpe + mReci - mSent
	local eProfit=eInco - math.max(eExpe, ePull) + eReci - eSent

	--ePrintEx({eCurr=eCurr, eStor=eStor, ePull=ePull, eInco=eInco, eExpe=eExpe, eShar=eShar, eSent=eSent, eReci=eReci})
	--ePrintEx({eProfit=eProfit, mProfit=mProfit})


	flashEnergyStall = eStor/eCurr > 5
	metalStall = mStor/mCurr > 5
	--[[
	if eProfit < 0 and eProfit < mProfit then
		flashEnergyStall = eCurr / -eProfit <= 20
	else
		flashEnergyStall = false
	end
	]]--

	if mProfit < 0 then
		flashMetalExcess=false
	else
		flashMetalExcess=mStorageLeft / mProfit <= 10
	end
end

local highPrio = 2
local SHIFT_TABLE = {"shift"}

local function SetEcoHighPriority()
	for uID, prio in pairs(energyUnitsUnderConstruction) do
		if flashEnergyStall and prio and prio < highPrio then
			--Spring.Echo("energyUnitsUnderConstruction")
			Spring.GiveOrderToUnit(uID, CMD_PRIORITY, {highPrio}, SHIFT_TABLE)
			energyUnitsUnderConstruction[uID] = highPrio
		end
	end
	for uID, prio in pairs(storageUnitsUnderConstruction) do
		if flashMetalExcess and prio and prio < highPrio then
			--Spring.Echo("storageUnitsUnderConstruction")
			Spring.GiveOrderToUnit(uID, CMD_PRIORITY, {highPrio}, SHIFT_TABLE)
			storageUnitsUnderConstruction[uID] = highPrio
		end
	end
	for uID, prio in pairs(caretakerUnitsUnderConstruction) do
		if flashMetalExcess and prio and prio < highPrio then
			--Spring.Echo("caretakerUnitsUnderConstruction")
			Spring.GiveOrderToUnit(uID, CMD_PRIORITY, {highPrio}, SHIFT_TABLE)
			caretakerUnitsUnderConstruction[uID] = highPrio
		end
	end
	for uID, prio in pairs(mexUnitsUnderConstruction) do
		if metalStall and prio and prio < highPrio then
			--Spring.Echo("mexUnitsUnderConstruction")
			Spring.GiveOrderToUnit(uID, CMD_PRIORITY, {highPrio}, SHIFT_TABLE)
			mexUnitsUnderConstruction[uID] = highPrio
		end
	end
end

local color
local cameraScale

local drawFeatureConvexHullSolidList
local function DrawFeatureConvexHullSolid()
	gl.PolygonMode(GL.FRONT_AND_BACK, GL.FILL)
	for i = 1, #featureConvexHulls do
		gl.PushMatrix()

		gl.BeginEnd(GL.TRIANGLE_FAN, function()
									   for j = 1, #featureConvexHulls[i] do
										 gl.Vertex(featureConvexHulls[i][j].x, featureConvexHulls[i][j].y, featureConvexHulls[i][j].z)
									   end
									 end)

		gl.PopMatrix()
	end
end

local drawFeatureConvexHullEdgeList
local function DrawFeatureConvexHullEdge()
	gl.PolygonMode(GL.FRONT_AND_BACK, GL.LINE)
	for i = 1, #featureConvexHulls do
		gl.PushMatrix()

		gl.BeginEnd(GL.LINE_LOOP, function()
									   for j = 1, #featureConvexHulls[i] do
										 gl.Vertex(featureConvexHulls[i][j].x, featureConvexHulls[i][j].y, featureConvexHulls[i][j].z)
									   end
									 end)

		gl.PopMatrix()
	end
	gl.PolygonMode(GL.FRONT_AND_BACK, GL.FILL)
end

local fontSizeMin = 40 --font size for minDim sized convex Hull
local fontSizeMax = 250

local drawFeatureClusterTextList
local function DrawFeatureClusterText()
	for i = 1, #featureConvexHulls do
		gl.PushMatrix()

		local center = featureConvexHulls[i].center

		gl.Translate(center.x, center.y, center.z)
		gl.Rotate(-90, 1, 0, 0)

		local fontSize = 30
		local area = featureConvexHulls[i].area
		fontSize = math.sqrt(area) * fontSize / minDim
		fontSize = math.max(fontSize, fontSizeMin)
		fontSize = math.min(fontSize, fontSizeMax)


		local metal = featureClusters[i].metal
		--Spring.Echo(metal)
		local metalText
		if metal < 1000 then
			metalText = string.format("%.0f", metal) --exact number
		elseif metal < 10000 then
			metalText = string.format("%.1fK", math.floor(metal / 100) / 10) --4.5K
		else
			metalText = string.format("%.0fK", math.floor(metal / 1000)) --40K
		end

        local x100  = 100  / (100  + metal)
        local x1000 = 1000 / (1000 + metal)
        local r = 1 - x1000
        local g = x1000 - x100
        local b = x100

		gl.Color(r + 0.5, g - 0.5, b + 0.5, 1.0)
		--gl.Rect(-200, -200, 200, 200)
		gl.Text(metalText, 0, 0, fontSize, "cv")


		gl.PopMatrix()
	end
end

local checkFrequency = 30
local checkFrequencyBias = math.floor(checkFrequency / 2)

local cumDt = 0
function widget:Update(dt)
	cumDt = cumDt + dt
	local cx, cy, cz = Spring.GetCameraPosition()

	local desc, w = Spring.TraceScreenRay(screenx / 2, screeny / 2, true)
	if desc then
		local cameraDist = math.min( 8000, math.sqrt( (cx-w[1])^2 + (cy-w[2])^2 + (cz-w[3])^2 ) )
		cameraScale = math.sqrt((cameraDist / 600)) --number is an "optimal" view distance
	else
		cameraScale = 1.0
	end

	for uId, info in pairs(idleList) do
		if info and info.flash then
			local x, y, z = Spring.GetUnitPosition(uId)

			local isIconDraw = Spring.IsUnitIcon(uId) or Spring.GetUnitIsCloaked(uId)
			info.isIconDraw = isIconDraw

			if isIconDraw then
				local cameraDist = math.min( 8000, math.sqrt( (cx-x)^2 + (cy-y)^2 + (cz-z)^2 ) )

				local scale = math.sqrt((cameraDist / 600)) --number is an "optimal" view distance
				--scale = math.min(scale, 2.5) --stop keeping icon size unchanged if zoomed out farther than "optimal" view distance

				local udid = Spring.GetUnitDefID(uId)
				local iconInfo = iconTypes[UnitDefs[udid].iconType]

				if iconInfo.radiusadjust then
					scale = scale * Spring.GetUnitRadius(uId) / 30.0
				end

				info.iconSize = iconInfo.size
				info.scale = scale
			end

			info.x, info.y, info.z = x, y, z

			idleList[uId] = info
		end
	end

	local frame=spGetGameFrame()
	color = 0.5 + 0.5 * (frame % checkFrequency - checkFrequency)/(checkFrequency - 1)
	if color < 0 then color = 0 end
	if color > 1 then color = 1 end
end

local waitIdlePeriod= 2 * 30 --x times second(s)

function widget:GameFrame(frame)
	local frameMod = frame % checkFrequency
	if frameMod == checkFrequencyBias then
		flashIdleWorkers = false
		for uId, info in pairs(idleList) do
			if info and info.gameFrame and frame >= info.gameFrame + waitIdlePeriod then
				idleList[uId].flash = true
				flashIdleWorkers = true
			else
				idleList[uId].flash = false
			end
		end
		CheckAndSetFlashMetalExcess(frame)
	elseif frameMod == 0 then
		--Spring.Echo("SetEcoHighPriority")
		SetEcoHighPriority()

		benchmark:Enter("GameFrame UpdateFeatures")
		UpdateFeatures(frame)
		--Spring.Echo("featuresUpdated", featuresUpdated)
		if featuresUpdated then
			ClusterizeFeatures()
			ClustersToConvexHull()
			--Spring.Echo("LuaUI memsize before = ", collectgarbage("count"))
			--collectgarbage("collect")
			--Spring.Echo("LuaUI memsize after = ", collectgarbage("count"))
			--benchmark:PrintAllStat()
		end

		if featuresUpdated or drawFeatureConvexHullSolidList == nil then
			benchmark:Enter("featuresUpdated or drawFeatureConvexHullSolidList == nil")
			--Spring.Echo("featuresUpdated")
			if drawFeatureConvexHullSolidList then
				gl.DeleteList(drawFeatureConvexHullSolidList)
				drawFeatureConvexHullSolidList = nil
			end

			if drawFeatureConvexHullEdgeList then
				gl.DeleteList(drawFeatureConvexHullEdgeList)
				drawFeatureConvexHullEdgeList = nil
			end


			drawFeatureConvexHullSolidList = gl.CreateList(DrawFeatureConvexHullSolid)
			drawFeatureConvexHullEdgeList = gl.CreateList(DrawFeatureConvexHullEdge)
			benchmark:Leave("featuresUpdated or drawFeatureConvexHullSolidList == nil")
		end

		if featuresUpdated or clusterMetalUpdated or drawFeatureClusterTextList == nil then
			benchmark:Enter("featuresUpdated or clusterMetalUpdated or drawFeatureClusterTextList == nil")
			--Spring.Echo("clusterMetalUpdated")
			if drawFeatureClusterTextList then
				gl.DeleteList(drawFeatureClusterTextList)
				drawFeatureClusterTextList = nil
			end
			drawFeatureClusterTextList = gl.CreateList(DrawFeatureClusterText)
			benchmark:Leave("featuresUpdated or clusterMetalUpdated or drawFeatureClusterTextList == nil")
		end
		benchmark:Leave("GameFrame UpdateFeatures")
	end
end

function widget:ViewResize(viewSizeX, viewSizeY)
	screenx, screeny = widgetHandler:GetViewSizes()
end

local function DrawBigFlashingRect()
	gl.Translate(0, 0, 0)
	gl.PolygonMode(GL.FRONT_AND_BACK, GL.FILL)
	gl.Scale(1, 1, 1)
	gl.Rect(0, 0, screenx, screeny)
end

function widget:DrawScreen()
	if Spring.IsGUIHidden() or Spring.IsCheatingEnabled() then return end

	--rgba
	if flashMetalExcess or flashIdleWorkers or flashEnergyStall then
		--rgba
		gl.PushMatrix()
		gl.Color(ColorMul(color, flashColor))
		DrawBigFlashingRect()
		gl.PopMatrix()

		if flashMetalExcess then
			gl.PushMatrix()
			gl.Color(ColorMul(color, flashMetalTextColor))
			gl.Translate(screenx/2-250, 2*screeny/3+270, 0)
			gl.Scale(textScale[1], textScale[2], textScale[3])
			gl.Text("Metal Excess", 0, 0, 55, "cv")
			gl.PopMatrix()
		end

		if flashIdleWorkers then
			gl.PushMatrix()
			gl.Color(ColorMul(color, flashIdleTextColor))
			gl.Translate(screenx/2-250, 2*screeny/3+305, 0)
			gl.Scale(textScale[1], textScale[2], textScale[3])
			gl.Text("Idle Workers", 0, 0, 49, "cv")
			gl.PopMatrix()
		end

		if flashEnergyStall then
			gl.PushMatrix()
			gl.Color(ColorMul(color, flashEStallTextColor))
			gl.Translate(screenx/2-250, 2*screeny/3+340, 0)
			gl.Scale(textScale[1], textScale[2], textScale[3])
			gl.Text("Stalling Energy", 0, 0, 52, "cv")
			gl.PopMatrix()
		end
	end
end

function widget:DrawWorld()
	if Spring.IsGUIHidden() or Spring.IsCheatingEnabled() then return end
	for uId, info in pairs(idleList) do
		if info then
			if info.flash then
				gl.PushMatrix()
				if info.isIconDraw then
					gl.Blending(GL.SRC_ALPHA, GL.ONE_MINUS_SRC_ALPHA)
					gl.Translate(info.x, info.y, info.z)
					gl.Billboard()
					gl.Translate(0, 4 * info.iconSize * info.scale, 0)

					gl.Color(ColorMul(color, idleFillColor))
					local iconSideSize = info.iconSize * info.scale * 10
					gl.PolygonMode(GL.FRONT_AND_BACK, GL.FILL)
					gl.Rect(-iconSideSize, -iconSideSize, iconSideSize, iconSideSize)

					gl.Color(ColorMul(color, flashIdleTextColor))
					gl.LineWidth(9.0 / info.scale)
					gl.PolygonMode(GL.FRONT_AND_BACK, GL.LINE)
					gl.Rect(-iconSideSize, -iconSideSize, iconSideSize, iconSideSize)
					gl.PolygonMode(GL.FRONT_AND_BACK, GL.FILL)
					gl.LineWidth(1.0)
					--gl.Blending(false)
				else
					gl.Blending(GL.ONE, GL.ONE)
					gl.DepthTest(GL.LEQUAL)
					gl.PolygonOffset(-10, -10)
					gl.Culling(GL.BACK)
					gl.Color(ColorMul(color, idleModelColor))
					gl.Unit(uId, true)
					gl.Blending(GL.SRC_ALPHA, GL.ONE_MINUS_SRC_ALPHA)
					gl.Culling(false)
				end

				gl.PopMatrix()
			else
				----
			end

		end
	end

	gl.DepthTest(false)
	--gl.DepthTest(true)

	gl.Blending(GL.SRC_ALPHA, GL.ONE_MINUS_SRC_ALPHA)
	if drawFeatureConvexHullSolidList then
		gl.Color(ColorMul(color, reclaimColor))
		gl.CallList(drawFeatureConvexHullSolidList)
		--DrawFeatureConvexHullSolid()
	end

	if drawFeatureConvexHullEdgeList then
		gl.LineWidth(6.0 / cameraScale)
		gl.Color(ColorMul(color, reclaimEdgeColor))
		gl.CallList(drawFeatureConvexHullEdgeList)
		--DrawFeatureConvexHullEdge()
		gl.LineWidth(1.0)
	end


	if drawFeatureClusterTextList then
		gl.CallList(drawFeatureClusterTextList)
		--DrawFeatureClusterText()
	end

	gl.DepthTest(true)

end

function widget:Shutdown()
	for hash, heavenZone in pairs(heavenZones) do
		if heavenZone.thisWidget then
			Spring.SendLuaRulesMsg('sethaven|' .. heavenZone.x .. '|' .. 0 .. '|' .. heavenZone.z )
		end
	end
	if drawFeatureConvexHullSolidList then
		gl.DeleteList(drawFeatureConvexHullSolidList)
	end
	if drawFeatureConvexHullEdgeList then
		gl.DeleteList(drawFeatureConvexHullEdgeList)
	end
	if drawFeatureClusterTextList then
		gl.DeleteList(drawFeatureClusterTextList)
	end
	benchmark:PrintAllStat()
end
