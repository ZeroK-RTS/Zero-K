

local _, _, GetAllyTeamOctant = VFS.Include("LuaUI/Headers/startbox_utilities.lua")

------------------------------------------------------------
-- Speedups
------------------------------------------------------------
local spGetActiveCommand    = Spring.GetActiveCommand
local spGetMouseState       = Spring.GetMouseState
local spTraceScreenRay      = Spring.TraceScreenRay
local spGetUnitDefID        = Spring.GetUnitDefID
local spGetUnitAllyTeam     = Spring.GetUnitAllyTeam
local spGetUnitHealth       = Spring.GetUnitHealth
local spGetSelectedUnits    = Spring.GetSelectedUnits
local spInsertUnitCmdDesc   = Spring.InsertUnitCmdDesc
local spGiveOrderToUnit     = Spring.GiveOrderToUnit
local spGetUnitPosition     = Spring.GetUnitPosition
local spGetTeamUnits        = Spring.GetTeamUnits
local spGetMyTeamID         = Spring.GetMyTeamID
local spTestBuildOrder      = Spring.TestBuildOrder
local spGetUnitsInRectangle = Spring.GetUnitsInRectangle
local spGiveOrder           = Spring.GiveOrder
local spGetGroundInfo       = Spring.GetGroundInfo
local spGetGroundHeight     = Spring.GetGroundHeight
local spGetMapDrawMode      = Spring.GetMapDrawMode
local spGetGameFrame        = Spring.GetGameFrame
local spGetAllUnits         = Spring.GetAllUnits
local spGetPositionLosState = Spring.GetPositionLosState
local spGetTeamResources    = Spring.GetTeamResources
local spGetUnitNearestEnemy = Spring.GetUnitNearestEnemy
local spGetTeamUnitsByDefs  = Spring.GetTeamUnitsByDefs
local spGetTeamUnitDefCount = Spring.GetTeamUnitDefCount
local spGetUnitHealth       = Spring.GetUnitHealth
local spGetUnitsInCylinder  = Spring.GetUnitsInCylinder
local spGetFactoryCommands  = Spring.GetFactoryCommands
local spTestBuildOrder      = Spring.TestBuildOrder

local abs   = math.abs
local floor = math.floor
local max   = math.max
local min   = math.min
local strFind = string.find
local strFormat = string.format

local CMD_OPT_SHIFT = CMD.OPT_SHIFT

local sqrt = math.sqrt
local tasort = table.sort
local taremove = table.remove


local mapX = Game.mapSizeX
local mapZ = Game.mapSizeZ

local METAL_MAP_SQUARE_SIZE = 16
local MEX_RADIUS = Game.extractorRadius
local MAP_SIZE_X = Game.mapSizeX
local MAP_SIZE_X_SCALED = MAP_SIZE_X / METAL_MAP_SQUARE_SIZE
local MAP_SIZE_Z = Game.mapSizeZ
local MAP_SIZE_Z_SCALED = MAP_SIZE_Z / METAL_MAP_SQUARE_SIZE

local MEX_WALL_SIZE = 8 * 6
local MEX_HOLE_SIZE = 3 * 6

--------------------------------------------------------------------------------
-- Variables
--------------------------------------------------------------------------------

local spotByID = {}
local spotData = {}
local spotHeights = {}

local wantDrawListUpdate = false

local metalSpotsNil = true

local metalmult = tonumber(Spring.GetModOptions().metalmult) or 1
local metalmultInv = metalmult > 0 and (1/metalmult) or 1

local myOctants = {}
local pregame = true

local placedMexSinceShiftPressed = false

------------------------------------------------------------
-- Debug
------------------------------------------------------------
local function printThing(theKey, theTable, indent)
    indent = indent or ""
    if (type(theTable) == "table") then
        Spring.Echo(indent .. theKey .. ":")
        for a, b in pairs(theTable) do
            printThing(tostring(a), b, indent .. "  ")
        end
    else
        Spring.Echo(indent .. theKey .. ": " .. tostring(theTable))
    end
end

------------------------------------------------------------
-- Config
------------------------------------------------------------

local TEXT_SIZE = 16
local TEXT_CORRECT_Y = 1.25

local PRESS_DRAG_THRESHOLD_SQR = 25^2
local MINIMAP_DRAW_SIZE = math.max(mapX,mapZ) * 0.0145

options_path = 'Settings/Interface/Map/Metal Spots'
options_order = { 'drawicons', 'size', 'rounding', 'catlabel', 'area_point_command', 'catlabel_terra', 'wall_low', 'wall_high', 'burry_shallow', 'burry_deep'}
options = {
    drawicons = {
        name = 'Show Income as Icon',
        type = 'bool',
        value = true,
        noHotkey = true,
        desc = "Enabled: income is shown pictorially.\nDisabled: income is shown as a number."
    },
    size = {
        name = "Income Display Size",
        desc = "How large should the font or icon be?",
        type = "number",
        value = 40,
        min = 10,
        max = 150,
        step = 5,
        update_on_the_fly = true,
        advanced = true
    },
    rounding = {
        name = "Display decimal digits",
        desc = "How precise should the number be?\nNo effect on icons.",
        type = "number",
        value = 1,
        min = 1,
        max = 4,
        update_on_the_fly = true,
        advanced = true,
        tooltip_format = "%.0f" -- show 1 instead of 1.0 (confusion)
    },
    catlabel = {
        name = 'Area Mex',
        type = 'label',
        path = 'Settings/Interface/Building Placement',
    },
    area_point_command = {
        name = 'Point click queues mex',
        type = 'bool',
        value = true,
        desc = "Clicking on the map with Area Mex or Area Terra Mex snaps to the nearest spot, like placing a mex.",
        path = 'Settings/Interface/Building Placement',
    },
    catlabel_terra = {
        name = 'Area Terra Mex (Alt+W by default)',
        type = 'label',
        path = 'Settings/Interface/Building Placement',
    },
    wall_low = {
        name = "Low Wall height",
        desc = "How high should a default terraformed wall be?",
        type = "number",
        value = 40,
        min = 2,
        max = 120,
        step = 1,
        path = 'Settings/Interface/Building Placement',
    },
    wall_high = {
        name = "High Wall height",
        desc = "How high should a tall terraformed wall (hold Ctrl) be?",
        type = "number",
        value = 75,
        min = 2,
        max = 120,
        step = 1,
        path = 'Settings/Interface/Building Placement',
    },
    burry_shallow = {
        name = "Shallow burry depth",
        desc = "How deep should a burried mex (hold Alt) be?",
        type = "number",
        value = 55,
        min = 2,
        max = 120,
        step = 1,
        path = 'Settings/Interface/Building Placement',
    },
    burry_deep = {
        name = "Deep burry depth",
        desc = "How deep should a deeper burried mex (hold Alt+Ctrl) be?",
        type = "number",
        value = 90,
        min = 2,
        max = 120,
        step = 1,
        path = 'Settings/Interface/Building Placement',
    },
}

local centerX
local centerZ
local extraction = 0




------------------------------------------------------------
-- Metal spots
------------------------------------------------------------
local spGetGameRulesParam = Spring.GetGameRulesParam
local metalSpots = {}
local metalSpotsByPos = {}

local function GetSpotsByPos(spots)
    local spotPos = {}
    for i = 1, #spots do
        local spot = spots[i]
        local x = spot.x
        local z = spot.z
        --Spring.MarkerAddPoint(x,0,z,x .. ", " .. z)
        spotPos[x] = spotPos[x] or {}
        spotPos[x][z] = i
    end
    return spotPos
end

local function GetMexSpotsFromGameRules()
    local mexCount = spGetGameRulesParam("mex_count")
    Spring.Echo("mexcount: " .. mexCount)
    if (not mexCount) or mexCount == -1 then
        metalSpots = false
        metalSpotsByPos = false
        return
    end


    for i = 1, mexCount do
        metalSpots[i] = {
            x = spGetGameRulesParam("mex_x" .. i),
            y = spGetGameRulesParam("mex_y" .. i),
            z = spGetGameRulesParam("mex_z" .. i),
            metal = spGetGameRulesParam("mex_metal" .. i),
        }
    end

    metalSpotsByPos = GetSpotsByPos(metalSpots)
end





-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
-- Mexes and builders

local mexDefID = UnitDefNames["staticmex"].id
local lotusDefID = UnitDefNames["turretlaser"].id
local solarDefID = UnitDefNames["energysolar"].id
local windDefID = UnitDefNames["energywind"].id

local mexUnitDef = UnitDefNames["staticmex"]
local mexDefInfo = {
    extraction = 0.001,
    oddX = mexUnitDef.xsize % 4 == 2,
    oddZ = mexUnitDef.zsize % 4 == 2,
}

local mexBuilder = {}

local mexBuilderDefs = {}
for udid, ud in ipairs(UnitDefs) do
    for i, option in ipairs(ud.buildOptions) do
        if mexDefID == option then
            mexBuilderDefs[udid] = true
        end
    end
end

local addons = { -- coordinates of solars for the Ctrl Alt modifier key, indexed by allyTeam start position
    -- The first two solars are in front, this is partially to make use of solar tankiness,
    -- but also because cons typically approach from the back so would otherwise be standing
    -- on the buildspot and have to waste time moving away
    { -- North East East
        {-64, -16 },
        {-16,  64 },
        { 64,  16 },
        { 16, -64 },
    },
    { -- North North East
        { 16,  64 },
        {-64,  16 },
        {-16, -64 },
        { 64, -16 },
    },
    { -- North North West
        {-16,  64 },
        { 64,  16 },
        { 16, -64 },
        {-64, -16 },
    },
    { -- Nort West West
        { 64, -16 },
        { 16,  64 },
        {-64,  16 },
        {-16, -64 },
    },
    { -- South West West
        { 64,  16 },
        { 16, -64 },
        {-64, -16 },
        {-16,  64 },
    },
    { -- South South West
        {-16, -64 },
        { 64, -16 },
        { 16,  64 },
        {-64,  16 },
    },
    { -- South South East
        { 16, -64 },
        {-64, -16 },
        {-16,  64 },
        { 64,  16 },
    },
    { -- South East East
        {-64,  16 },
        {-16, -64 },
        { 64, -16 },
        { 16,  64 },
    },
}

------------------------------------------------------------
-- Functions
------------------------------------------------------------

local function sqDistance(x1,z1,x2,z2)
    local dis = (x1-x2)*(x1-x2)+(z1-z2)*(z1-z2)
    return dis
end

local function IsSpotBuildable(index, teamId)
    if not index then
        return true
    end
    local spot = spotData[index]
    if not spot then
        return true
    end

    local unitID = spot.unitID
    if unitID and spGetUnitAllyTeam(unitID) == teamId then
        local build = select(5, spGetUnitHealth(unitID))
        if build and build < 1 then
            return true
        end
    end
    return false
end

local function GetClosestBuildableMetalSpot(x, z, teamId) --is used by single mex placement, not used by areamex
    local bestSpot
    local bestDist = math.huge
    local bestIndex
    for i = 1, #metalSpots do
        local spot = metalSpots[i]
        local dx, dz = x - spot.x, z - spot.z
        local dist = dx*dx + dz*dz
        if dist < bestDist and IsSpotBuildable(i, teamId) then
            bestSpot = spot
            bestDist = dist
            bestIndex = i
        end
    end
    return bestSpot, sqrt(bestDist), bestIndex
end

-- TODO: Combine with above
local function GetClosestBuildableMetalSpots(x, z, teamId) --is used by single mex placement, not used by areamex
    local spotData = {}
    local index = 1
    for i = 1, #metalSpots do
        local spot = metalSpots[i]
        local dx, dz = x - spot.x, z - spot.z
        local dist = dx*dx + dz*dz
        if IsSpotBuildable(i, teamId) then
            spotData[index] = {
                bestSpot = spot,
                bestDist = dist,
                bestIndex = i
            }
            index = index + 1
        end
    end
    table.sort(spotData, function (k1, k2) return k1.bestDist < k2.bestDist end )
    return spotData
end

local function IntegrateMetal(x, z, forceUpdate)
    local newCenterX, newCenterZ

    if (mexDefInfo.oddX) then
        newCenterX = (floor( x / METAL_MAP_SQUARE_SIZE) + 0.5) * METAL_MAP_SQUARE_SIZE
    else
        newCenterX = floor( x / METAL_MAP_SQUARE_SIZE + 0.5) * METAL_MAP_SQUARE_SIZE
    end

    if (mexDefInfo.oddZ) then
        newCenterZ = (floor( z / METAL_MAP_SQUARE_SIZE) + 0.5) * METAL_MAP_SQUARE_SIZE
    else
        newCenterZ = floor( z / METAL_MAP_SQUARE_SIZE + 0.5) * METAL_MAP_SQUARE_SIZE
    end

    if (centerX == newCenterX and centerZ == newCenterZ and not forceUpdate) then
        return
    end

    centerX = newCenterX
    centerZ = newCenterZ

    local startX = floor((centerX - MEX_RADIUS) / METAL_MAP_SQUARE_SIZE)
    local startZ = floor((centerZ - MEX_RADIUS) / METAL_MAP_SQUARE_SIZE)
    local endX = floor((centerX + MEX_RADIUS) / METAL_MAP_SQUARE_SIZE)
    local endZ = floor((centerZ + MEX_RADIUS) / METAL_MAP_SQUARE_SIZE)
    startX, startZ = max(startX, 0), max(startZ, 0)
    endX, endZ = min(endX, MAP_SIZE_X_SCALED - 1), min(endZ, MAP_SIZE_Z_SCALED - 1)

    local mult = mexDefInfo.extraction
    local result = 0

    for i = startX, endX do
        for j = startZ, endZ do
            local cx, cz = (i + 0.5) * METAL_MAP_SQUARE_SIZE, (j + 0.5) * METAL_MAP_SQUARE_SIZE
            local dx, dz = cx - centerX, cz - centerZ
            local dist = sqrt(dx * dx + dz * dz)

            if (dist < MEX_RADIUS) then
                local _, metal = spGetGroundInfo(cx, cz)
                result = result + metal
            end
        end
    end

    extraction = result * mult
end

------------------------------------------------------------
-- Command Handling
------------------------------------------------------------

local function MakeOptions()
    local a, c, m, s = Spring.GetModKeyState()
    local coded = (a and CMD.OPT_ALT or 0) +
            (c and CMD.OPT_CTRL or 0) +
            (m and CMD.OPT_META or 0) +
            (s and CMD.OPT_SHIFT or 0)

    return {
        alt   = a and true or false,
        ctrl  = c and true or false,
        meta  = m and true or false,
        shift = s and true or false,
        coded = coded,
        internal = false,
        right = false,
    }
end

Spring.Echo("loading local mex placer")
local function HandleAreaMex(cmdID, cx, cy, cz, cr, cmdOpts, units, makeLotus)
    --Spring.Echo("Handling area mex")
    local xmin = cx-cr
    local xmax = cx+cr
    local zmin = cz-cr
    local zmax = cz+cr

    local commands = {}
    local orderedCommands = {}
    local dis = {}

    local ux = 0
    local uz = 0
    local us = 0

    local aveX = 0
    local aveZ = 0

    local teamId = spGetUnitAllyTeam(units[1])

    for i = 1, #units do
        local unitID = units[i]
        if mexBuilder[unitID] then
            local x,_,z = spGetUnitPosition(unitID)
            ux = ux+x
            uz = uz+z
            us = us+1
        end
    end

    if (us == 0) then
        return
    else
        aveX = ux/us
        aveZ = uz/us
    end

    local terraMode = (cmdID == CMD_AREA_TERRA_MEX)
    local energyToMake = 0
    local burryMode = false
    local wallHeight = options.wall_low.value
    if cmdOpts.ctrl then
        if cmdOpts.alt then
            energyToMake = 4
            burryMode = true
            wallHeight = options.burry_deep.value
        else
            energyToMake = 1
            wallHeight = options.wall_high.value
        end
    elseif cmdOpts.alt then
        energyToMake = 2
        burryMode = true
        wallHeight = options.burry_shallow.value
    end
    local makeMexEnergy = (not terraMode) and (energyToMake > 0)

    for i = 1, #metalSpots do
        local mex = metalSpots[i]
        --if (mex.x > xmin) and (mex.x < xmax) and (mex.z > zmin) and (mex.z < zmax) then -- square area, should be faster
        if (sqDistance(cx, cz, mex.x, mex.z) < cr*cr) and (makeMexEnergy or (terraMode and not burryMode) or IsSpotBuildable(i, teamId)) then -- circle area, slower
            commands[#commands+1] = {x = mex.x, z = mex.z, d = sqDistance(aveX,aveZ,mex.x,mex.z)}
        end
    end

    local noCommands = #commands
    while noCommands > 0 do
        tasort(commands, function(a,b) return a.d < b.d end)
        orderedCommands[#orderedCommands+1] = commands[1]
        aveX = commands[1].x
        aveZ = commands[1].z
        taremove(commands, 1)
        for k, com in pairs(commands) do
            com.d = sqDistance(aveX,aveZ,com.x,com.z)
        end
        noCommands = noCommands-1
    end

    local shift = cmdOpts.shift

    do --issue ordered order to unit(s)
        local commandArrayToIssue={}
        local unitArrayToReceive ={}
        for i = 1, #units do --prepare unit list
            local unitID = units[i]
            if mexBuilder[unitID] then
                unitArrayToReceive[#unitArrayToReceive+1] = unitID
            end
        end

        -- If ctrl or alt is held and the first metal spot is blocked by a mex, then the mex command is blocked
        -- and the remaining commands are issused with shift. This causes the area mex command to act as if shift
        -- where hold even when it is not. I do not know why this issue is absent when no modkey are held.
        if makeMexEnergy and not (cmdOpts.shift or cmdOpts.meta) then
            commandArrayToIssue[#commandArrayToIssue+1] = {CMD.STOP, {} }
        end

        --prepare command list
        for i, command in ipairs(orderedCommands) do
            local x = command.x
            local z = command.z
            local y = math.max(0, Spring.GetGroundHeight(x, z))

            commandArrayToIssue[#commandArrayToIssue + 1] = {-mexDefID, {x,y,z,0}}

            if makeMexEnergy then
                for i = 1, energyToMake do
                    local addon = addons[myOctants[teamId]][i]
                    local xx = x+addon[1]
                    local zz = z+addon[2]
                    local yy = math.max(0, Spring.GetGroundHeight(xx, zz))
                    local buildDefID = (Spring.TestBuildOrder(solarDefID, xx, yy, zz, 0) == 0 and windDefID) or solarDefID

                    -- check if some other widget wants to handle the command before sending it to units.
                    commandArrayToIssue[#commandArrayToIssue+1] = {-buildDefID, {xx,yy,zz,0} }
                end
                local xx = x + addons[myOctants[teamId]][1][1] * 2
                local zz = z + addons[myOctants[teamId]][1][2] * 2
                local yy = math.max(0, Spring.GetGroundHeight(xx, zz))
                if not (Spring.TestBuildOrder(lotusDefID, xx, yy, zz, 0) == 0) and makeLotus then
                    commandArrayToIssue[#commandArrayToIssue+1] = {-lotusDefID, {xx,yy,zz,0} }
                end
            end
        end

        for i = 1, #commandArrayToIssue do
            local command = commandArrayToIssue[i]
            --WG.CommandInsert(command[1], command[2], cmdOpts, i - 1, true)
            for _, unitId in ipairs(unitArrayToReceive) do
                spGiveOrderToUnit(unitId, command[1], command[2], {alt=true, shift=true})
            end
        end
        --printThing("unitArrayToReceive", unitArrayToReceive)
        --printThing("commandArrayToIssue", commandArrayToIssue)
    end

    return true
end

function gadget:UnitEnteredLos(unitID, teamID)

    local unitDefID = Spring.GetUnitDefID(unitID)
    if unitDefID ~= mexDefID or not metalSpots then
        return
    end

    local x,_,z = Spring.GetUnitPosition(unitID)
    local spotID = metalSpotsByPos[x] and metalSpotsByPos[x][z]
    if not spotID then
        return
    end

    spotByID[unitID] = spotID
    spotData[spotID] = {unitID = unitID, team = teamID, enemy = true}
end

local function DidMexDie(unitID, expectedSpotID) --> dead, idReusedForAnotherMex
    local unitDefID = Spring.GetUnitDefID(unitID)
    if unitDefID ~= mexDefID then -- not just a nil check, the unitID could have gotten recycled for another unit
        return true, false
    end

    local spotID = spotByID[unitID]
    if spotID ~= expectedSpotID then
        return true, true -- the original died, unitID was recycled to another mex
    end

    return false
end

local function CheckEnemyMexes(spotID)
    local spotD = spotData[spotID]
    if not spotD or not spotD.enemy then
        return
    end

    local spotM = metalSpots[spotID]
    local x = spotM.x
    local z = spotM.z
    local los = Spring.GetPositionLosState(x, 0, z)
    if not los then
        return
    end

    local unitID = spotD.unitID
    local dead, idReusedForAnotherMex = DidMexDie(unitID, spotID)
    if not dead then
        return
    end

    if not idReusedForAnotherMex then
        spotByID[unitID] = nil
    end

    spotData[spotID] = nil
    wantDrawListUpdate = true
end

local function CheckTerrainChange(spotID)
    local spot = metalSpots[spotID]
    local x = spot.x
    local z = spot.z

    local y = max(0, spGetGroundHeight(x, z))

    -- some leeway to avoid too much draw list recreation
    -- since a lot of weapons have small but nonzero cratering
    if abs(y - spotHeights[spotID]) > 1 then
        spotHeights[spotID] = y
        wantDrawListUpdate = true
    end
end

local function CheckAllTerrainChanges()
    for i = 1, #metalSpots do
        CheckEnemyMexes(i)
        CheckTerrainChange(i)
    end
end

------------------------------------------------------------
-- Callins
------------------------------------------------------------

local function ai_lib_GameFrame(n)
    pregame = false
    if not metalSpots or (n % 5) ~= 0 then
        return
    end
    theUpdate()

    CheckAllTerrainChanges()
end

local function ai_lib_UnitCreated(unitID, unitDefID, teamID)
    if mexBuilderDefs[unitDefID] then
        mexBuilder[unitID] = true
        return
    end

    if unitDefID ~= mexDefID or not metalSpots then
        return
    end

    local x,_,z = Spring.GetUnitPosition(unitID)
    local spotID = metalSpotsByPos[x] and metalSpotsByPos[x][z]
    if not spotID then
        return
    end

    spotByID[unitID] = spotID
    spotData[spotID] = {unitID = unitID, team = teamID}
end

local function ai_lib_UnitDestroyed(unitID, unitDefID)
    if mexBuilder[unitID] then
        mexBuilder[unitID] = nil
    end
    if unitDefID == mexDefID and spotByID[unitID] then
        spotData[spotByID[unitID]] = nil
        spotByID[unitID] = nil
    end
end

local function ai_lib_UnitGiven(unitID, unitDefID, newTeamID, teamID)
    if mexBuilderDefs[unitDefID] then
        mexBuilder[unitID] = true
    end
    if unitDefID == mexDefID then
        ai_lib_UnitCreated(unitID, unitDefID, newTeamID)
    end
end

local function Initialize()
    if metalSpots then
        Spring.Echo("Mex Placement Initialised with " .. #metalSpots .. " spots.")
        for i = 1, #metalSpots do
            spotHeights[i] = metalSpots[i].y
        end
    else
        Spring.Echo("Mex Placement Initialised with metal map mode.")
    end

    local units = spGetAllUnits()
    for i, unitID in ipairs(units) do
        local unitDefID = spGetUnitDefID(unitID)
        local teamID = Spring.GetUnitTeam(unitID)
        ai_lib_UnitCreated(unitID, unitDefID, teamID)
    end

    pregame = (Spring.GetGameFrame() < 1)
end

local mexSpotToDraw = false
local drawMexSpots = false

local function UpdateOctant()
    for _,teamId in ipairs(Spring.GetTeamList()) do
        myOctants[teamId] = GetAllyTeamOctant(teamId) or 1
    end
end

local function ai_lib_Initialize()
    if metalSpotsNil and metalSpots ~= nil then
        Initialize()
        UpdateOctant()
        metalSpotsNil = false
    end
end

local wasFullView

local function CheckNeedsRecalculating()
    if not metalSpots then
        return false
    end

    return false
end

local firstUpdate = true
local camDir
local debounceCamUpdate
local incomeLabelList
local DrawIncomeLabels
function theUpdate() -- global so that it can be referenced above
    ai_lib_Initialize()

    if firstUpdate then
        if Spring.GetGameRulesParam("waterLevelModifier") or Spring.GetGameRulesParam("mapgen_enabled") then
            Initialize()
            CheckAllTerrainChanges()
        end
        firstUpdate = false
    end

    if CheckNeedsRecalculating() then
        spotByID = {}
        spotData = {}
        local units = spGetAllUnits()
        for i, unitID in ipairs(units) do
            local unitDefID = spGetUnitDefID(unitID)
            local teamID = Spring.GetUnitTeam(unitID)
            if unitDefID == mexDefID then
                ai_lib_UnitCreated(unitID, unitDefID, teamID)
            end
        end
    end
end

return ai_lib_UnitDestroyed, ai_lib_UnitCreated, ai_lib_UnitGiven, ai_lib_Initialize, ai_lib_GameFrame, sqDistance, HandleAreaMex, GetMexSpotsFromGameRules, GetClosestBuildableMetalSpot, GetClosestBuildableMetalSpots