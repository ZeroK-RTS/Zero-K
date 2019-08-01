
if not gadgetHandler:IsSyncedCode() then
    return
end

local gadgetName = "Unit removal from rezzed structures"

function gadget:GetInfo()
    return {
        name      = gadgetName,
        desc      = "Prevents units from getting stuck inside a resurrected structure " .. 
        "by moving them aside",
        author    = "Alcur",
        date      = "21.10.2017",
        license   = "GNU GPL, v2 or later", -- is that the correct license?
        layer     = 0, -- what should the layer be?
        enabled   = true,
    }
end


local spGetUnitRadius = Spring.GetUnitRadius
local spGetUnitPosition = Spring.GetUnitPosition
local spGetUnitDefID = Spring.GetUnitDefID
local spGetUnitDefDimensions = Spring.GetUnitDefDimensions
local spEcho = Spring.Echo
local spGetUnitsInRectangle = Spring.GetUnitsInRectangle
local spGetGroundHeight = Spring.GetGroundHeight
local spGetGroundNormal = Spring.GetGroundNormal
local spSetUnitPosition = Spring.SetUnitPosition
local spGetUnitCollisionVolumeData = Spring.GetUnitCollisionVolumeData
local spGetCommandQueue = Spring.GetCommandQueue
local spGetUnitHeight = Spring.GetUnitHeight
local gameSquareSize = Game.squareSize

local CMD_RESURRECT = CMD.RESURRECT

local Abs = math.abs
local Min = math.min
local Max = math.max
local SortTable = table.sort

local gapMin = 20

local maxUnitHeightAboveGround = 1
local maxUnitHeightAboveSea = 5
local extraMaxWaterDepth = 5

local extraGatherDistance = 125

local function Debug(message)
    spEcho(gadgetName .. ": " .. message)    
end

local function IsGroundSlopeTraversable(unitDef, x, z)
    local _, _, _, slope = spGetGroundNormal(x, z)
    local traversable = unitDef.moveDef.maxSlope >= slope
    --Spring.MarkerAddPoint(x, 0, z)
    --Debug("traversable = " .. tostring(traversable) .. " (for \"" .. unitDef.humanName .. "\")")
    return traversable
end

local function CanUnitSwim(unitDef)
    return unitDef.springCategories.sub or unitDef.springCategories.ship
end

local function IsUnitShip(unitDef)
    return unitDef.moveDef.type == "ship"
end


local function CanUnitMoveInWater(unitDef, waterDepth)
    return CanUnitSwim(unitDef) or (not IsUnitShip(unitDef) and unitDef.moveDef.depth >= waterDepth)
end

local function IsLocationSubmerged(x, z)
    local height = spGetGroundHeight(x, z)
    local depth = Max(-height, 0)
    return spGetGroundHeight(x, z) < 0, depth
end

-- only four possible directions (north, east, south and west) 
-- because currently more aren't needed
local function IsPathTraversable(unitDef, startX, startZ, goalX, goalZ)
    local stepX = gameSquareSize
    local stepZ = gameSquareSize
    if (goalX - startX) < 0 then
        stepX = -stepX
    end
    if (goalZ - startZ) < 0 then
        stepZ = -stepZ
    end

    -- Spring.MarkerAddPoint(goalX, 0, goalZ, "Possible goal")

    for x = startX, goalX, stepX do
        for z = startZ, goalZ, stepZ do
            local submerged, depth = IsLocationSubmerged(x, z)
            local canMoveInWater = CanUnitMoveInWater(unitDef, depth)
            if not IsGroundSlopeTraversable(unitDef, x, z) or (submerged and 
                not canMoveInWater) or (submerged and IsUnitShip(unitDef) and unitDef.moveDef.depth > depth) then
                --Spring.MarkerAddPoint(x, 0, z, "Slope not traversable")
                return false
            else
                --Spring.MarkerAddPoint(x, 0, z, "Slope traversable")
                --if x >= goalX and z >= goalZ then
                --Debug("Slope " .. x .. ", " .. z .. " is traversable")
                --Debug("submerged = " .. tostring(submerged))
                --Debug("depth = " .. tostring(depth))
                --Debug("canMoveInWater = " .. tostring(canMoveInWater))
                --end
            end
        end
    end
    return true
end

local function FindAccessibleSpot(diffs, unitDef, startX, startZ)

    --Debug("StartX = " .. startX)
    --Debug("StartZ = " .. startZ)
    --Spring.MarkerAddPoint(startX, 0, startZ, "startX = " .. startX .. ", startZ = " .. startZ)
    local failure = false
    for i = 1, #diffs do
        local offset = diffs[i].value

        local goalX = startX
        local goalZ = startZ
        if diffs[i].isX then
            goalX = startX - offset
        else
            goalZ = startZ - offset
        end

        --Spring.MarkerAddPoint(goalX, 0, goalZ, i .. " (" .. goalX .. ", " .. goalZ .. ")")
        local isFree = IsPathTraversable(unitDef, startX, startZ, goalX, goalZ)
        if isFree then
            --Debug("Path is free")
            return goalX, goalZ
        else
            --Debug("Path " .. i .. " is unknown or not free")
        end
    end
    --Debug("All spots checked; no free path found")
    return failure
end

local function GeomMean(values)
    local product = values[1]

    for i = 2, #values do
        product = product * values[i]
    end

    return product ^ (1 / #values)
end

local function WithinBounds(value, min, max, inclusive)
    if inclusive then
        return value >= min and value <= max
    else
        return value > min and value < max
    end
end

local function EstimateRequiredStructureGap(unitID)
    local radius = spGetUnitRadius(unitID)
    local scaleX, scaleY, scaleZ, _, _, _, volumeType, testType, primaryAxis, disabled =
    spGetUnitCollisionVolumeData(unitID)
    local def = UnitDefs[spGetUnitDefID(unitID)]
    local volumeTypeInDef = def.collisionVolume.type

    --[[
    Debug("Unit size info: scaleX = " .. scaleX .. ", scaleY = " .. scaleY .. ", scaleZ = " .. scaleZ ..
        ", volumeType = " .. volumeTypeInDef .. ", testType = " .. testType .. ", primaryAxis = " .. primaryAxis ..
        ", radius = " .. radius)
    --]]

    --local gMeanScaleRadius = GeomMean{scaleX / 2, scaleY / 2, scaleZ / 2}
    --local gMeanHalfFootprint = GeomMean{def.xsize * gameSquareSize / 2, def.zsize * gameSquareSize / 2}

    --Debug("Unit size info: gMeanScaleRadius = " .. gMeanScaleRadius .. ", gMeanHalfFootprint = " .. gMeanHalfFootprint)

    local estimatedGap = Max(Max(GeomMean({scaleX / 2, scaleY / 2, scaleZ / 2}), radius, GeomMean({def.xsize * gameSquareSize / 2, 
                    def.zsize * gameSquareSize / 2})), gapMin)

    return estimatedGap

end

local function ShouldUnitBeMoved(targetUnitID, resUnitMinX, resUnitMinZ, resUnitMaxX, resUnitMaxZ)
    local unitDef = UnitDefs[spGetUnitDefID(targetUnitID)]
    local humanName = unitDef.humanName
    local unitX, unitY, unitZ = spGetUnitPosition(targetUnitID)
    local uHeight = spGetUnitHeight(targetUnitID)
    local unitGroundY = spGetGroundHeight(unitX, unitZ)

    --Debug("Rectangle unit height is " .. tostring(uHeight))
    --Debug(humanName .. " is inside the rectangle. Y = " .. unitY .. ", ground Y = " .. unitGroundY)
    --Debug("floatOnWater = " .. tostring(unitDef.floatOnWater))
    --Debug("floater = " .. tostring(unitDef.floater))
    --Debug("Rectangle unit maxSlope is " .. tostring(unitDef.moveDef.maxSlope))

    if not unitDef.isImmobile and unitDef.name ~= "terraunit" and not unitDef.isAirUnit and 
    ((unitY - unitGroundY <= maxUnitHeightAboveGround) or (CanUnitSwim(unitDef) and 
            WithinBounds(unitY, -unitDef.waterline - uHeight / 2 - extraMaxWaterDepth, maxUnitHeightAboveSea, true))) then
        -- per the Spring wiki unit height determines if a ship can go over something that is underwater

        local requiredGap = EstimateRequiredStructureGap(targetUnitID)
        --Debug("requiredGap is " .. requiredGap)

        if unitX < (resUnitMinX - requiredGap) or unitX > (resUnitMaxX + requiredGap) or
        unitZ < (resUnitMinZ - requiredGap) or unitZ > (resUnitMaxZ + requiredGap) then
            return false
        else
            return true, requiredGap
        end
    end
end

function gadget:UnitCreated(unitID, unitDefID, unitTeam, builderID)

    local uDef = UnitDefs[unitDefID]
    if builderID then
        if Spring.Utilities.GetUnitFirstCommand(builderID) == CMD_RESURRECT and uDef.isImmobile and
        uDef.name ~= "terraunit" then
            local ux1, uy1, uz1 = spGetUnitPosition(unitID)
            --local dimensions = spGetUnitDefDimensions(unitDefID)
            --Debug("Created unit height = " .. dimensions.height)
            --Debug("Created unit radius = " .. dimensions.radius)
            --Debug("Created unit xsize = " .. uDef.xsize)
            --Debug("Created unit zsize = " .. uDef.zsize)
            local footprintXElmos = uDef.xsize * gameSquareSize
            local footprintZElmos = uDef.zsize * gameSquareSize
            --local createdUnitGroundY = spGetGroundHeight(ux1, uz1)


            local createdUnitMinX =  ux1 - footprintXElmos / 2
            local createdUnitMinZ =  uz1 - footprintZElmos / 2
            local createdUnitMaxX =  ux1 + footprintXElmos / 2
            local createdUnitMaxZ =  uz1 + footprintZElmos / 2

            --Debug("createdUnitMinX = " .. createdUnitMinX .. ", createdUnitMaxX = " .. createdUnitMaxX)
            --Debug("createdUnitMinZ = " .. createdUnitMinZ .. ", createdUnitMaxZ = " .. createdUnitMaxZ)

            local units = spGetUnitsInRectangle(createdUnitMinX - extraGatherDistance, 
                createdUnitMinZ - extraGatherDistance, createdUnitMaxX + extraGatherDistance, 
                createdUnitMaxZ + extraGatherDistance)


            --Debug("Y of the created unit: " .. uy1)
            --Debug("Ground Y of the created unit: " .. createdUnitGroundY)
            for i = 1, #units do
                local shouldUnitBeMoved, requiredGap = ShouldUnitBeMoved(units[i], createdUnitMinX, 
                    createdUnitMinZ, createdUnitMaxX, createdUnitMaxZ)
                if units[i] ~= unitID and shouldUnitBeMoved then

                    local rectUX, rectUY, rectUZ = spGetUnitPosition(units[i])

                    local xDiff1 = rectUX - (createdUnitMinX - requiredGap)
                    local xDiff2 = rectUX - (createdUnitMaxX + requiredGap)
                    local zDiff1 = rectUZ - (createdUnitMinZ - requiredGap)
                    local zDiff2 = rectUZ - (createdUnitMaxZ + requiredGap)
                    
                    

                    local diffs = {{isX = true, value = xDiff1}, {isX = true, value = xDiff2},
                        {isX = false, value = zDiff1}, {isX = false, value = zDiff2}}

                    local comp = function(elem1, elem2)
                        return Abs(elem1.value) < Abs(elem2.value)
                    end

                    SortTable(diffs, comp)

                    local diffsCopy = {}
                    for j = 1, #diffs do
                        diffsCopy[j] = {}
                        diffsCopy[j].isX = diffs[j].isX
                        diffsCopy[j].value = diffs[j].value
                    end

                    local rectUDef = UnitDefs[spGetUnitDefID(units[i])]
                    local targetX, targetZ = FindAccessibleSpot(diffsCopy, rectUDef, rectUX, rectUZ)
                    if targetX then
                        spSetUnitPosition(units[i], targetX, targetZ)
                        -- Spring.MarkerAddPoint(targetX, 0, targetZ, "target")
                    else
                        --Debug("Failed to find an accessible spot")
                    end
                end
            end
        end
    end
end

-- The below code is for testing. It creates an athena and a cloakassault if they don't exist.
-- A hovercraft wreck is created too if the corresponding factory or its wreck are absent. 
-- The polling checks every 10th frame if the things exist. The things are placed roughly onto 
-- the centre of the map.
--[[
function gadget:GameFrame(f)
    if f % 10 ~= 0 then
        return
    end
    
    local testerTeamID = 0
    local units = Spring.GetTeamUnits(testerTeamID)
    local features = Spring.GetAllFeatures()
    local athenaFound = false
    local mapWidth = Game.mapSizeX
    local mapHeight = Game.mapSizeZ
    local center = {}
    center.x = mapWidth/2
    center.z = mapHeight/2
    center.y = spGetGroundHeight(center.x, center.z)
    local foundUnits = {}
    local resUnit = {}
    resUnit.name = "factoryhover"
    resUnit.found = false
    resUnit.wreckFound = false
    foundUnits["athena"] = false
    foundUnits["cloakassault"] = false
    local spacing = 200
    
    local spGetFeatureDefID = Spring.GetFeatureDefID
    
    for i = 1, #units do
        local uID = units[i]
        local uDef = UnitDefs[spGetUnitDefID(uID)]
        if uDef.name == resUnit.name then
            resUnit.found = true
        else
            for uName, uFound in pairs(foundUnits) do
                if uDef.name == uName then
                    foundUnits[uName] = true
                end
            end
        end
    end
    
    for i = 1, #features do
        if FeatureDefs[spGetFeatureDefID(features[i])].name == UnitDefNames[resUnit.name].wreckName then
            resUnit.wreckFound = true
        end
    end
    
    
    if not resUnit.found and not resUnit.wreckFound then
        local uID = Spring.CreateUnit(resUnit.name, center.x, center.y, center.z, "west", testerTeamID)
        Spring.DestroyUnit(uID)
    end
    
    local i = 1
    for uName, uFound in pairs(foundUnits) do
        if not uFound then
            local uID = Spring.CreateUnit(uName, center.x + spacing * i, center.y, center.z, "south", testerTeamID)
        end
        i = i + 1
    end
end
--]]