function widget:GetInfo()
    return {
        name    = "Unit Team Names",
        desc    = "Tag one onscreen unit with the team name",
        author  = "fiendicus_prime",
        date    = "2023-11-29",
        license = "GNU GPL, v2 or later",
        layer   = -9,
        enabled = false
    }
end

--------------------------------------------------------------------------------
-- config
--------------------------------------------------------------------------------

local heightOffset        = 32
local teamCheckDelay      = 0.2

--------------------------------------------------------------------------------
-- speed-ups
--------------------------------------------------------------------------------

local log                 = math.log
local min                 = math.min
local sqrt                = math.sqrt

local Echo                = Spring.Echo
local GetAIInfo           = Spring.GetAIInfo
local GetAllUnits         = Spring.GetAllUnits
local GetAllyTeamList     = Spring.GetAllyTeamList
local GetCameraPosition   = Spring.GetCameraPosition
local GetGaiaTeamID       = Spring.GetGaiaTeamID
local GetMoveType         = Spring.Utilities.getMovetype
local GetPlayerInfo       = Spring.GetPlayerInfo
local GetScreenGeometry   = Spring.GetScreenGeometry
local GetTeamColor        = Spring.GetTeamColor
local GetTeamInfo         = Spring.GetTeamInfo
local GetTeamList         = Spring.GetTeamList
local GetUnitDefID        = Spring.GetUnitDefID
local GetUnitHeight       = Spring.Utilities.GetUnitHeight
local GetUnitPosition     = Spring.GetUnitPosition
local GetUnitTeam         = Spring.GetUnitTeam
local IsUnitInView        = Spring.IsUnitInView
local WorldToScreenCoords = Spring.WorldToScreenCoords

local glBillboard         = gl.Billboard
local glColor             = gl.Color
local glDrawFuncAtUnit    = gl.DrawFuncAtUnit
local glText              = gl.Text
local glTranslate         = gl.Translate

--------------------------------------------------------------------------------
-- callins
--------------------------------------------------------------------------------

local teamInfos           = {}
local unitsByTeam         = {}
local teamAvatars         = {}
local teamCheckDelays     = {}

function initTeams()
    local gaiaTeamID = GetGaiaTeamID()
    for _, allyTeam in pairs(GetAllyTeamList()) do
        for _, teamID in pairs(GetTeamList(allyTeam)) do
            local teamName
            if teamID == gaiaTeamID then
                teamName = "Gaia"
            else
                local _, teamLeader, _, isAI = GetTeamInfo(teamID)
                if isAI then
                    local _, name = GetAIInfo(teamID)
                    teamName = name
                else
                teamName = GetPlayerInfo(teamLeader)
                end
            end
            local r, g, b = GetTeamColor(teamID)

            teamInfos[teamID] = {
                color = r and g and b and { r, g, b, 1.0 } or { 1, 1, 1, 1.0 },
                name = teamName
            }
            unitsByTeam[teamID] = {}
            teamCheckDelays[teamID] = 0
        end
    end
end

local function length(x, y, z)
    return sqrt(x * x + y * y + (z and z * z or 0))
end

function _addUnit(unitTeam, unitID, unitDefID)
    unitDefID = unitDefID or GetUnitDefID(unitID)
    local unitDef = UnitDefs[unitDefID]
    if not unitDef then
        -- Why?
        return
    end
    local isStatic = not GetMoveType(unitDef)
    local height = GetUnitHeight(unitDef) + heightOffset
    unitsByTeam[unitTeam][unitID] = { isStatic, height }
end

local scx, scy, sDistanceMax

function widget:Initialize()
    scx, scy = GetScreenGeometry()
    scx, scy = scx / 2, scy / 2
    -- i.e. the radius of a circle that fills most of the smallest dimension
    local sDistanceFraction = 0.85
    sDistanceMax = min(scx * sDistanceFraction, scy * sDistanceFraction)

    initTeams()

    for _, unitID in pairs(GetAllUnits()) do
        _addUnit(GetUnitTeam(unitID), unitID, GetUnitDefID(unitID))
    end
end

function widget:Update(dt)
    for teamID, delay in pairs(teamCheckDelays) do
        teamCheckDelays[teamID] = delay - dt
    end
end

local function _GetScreenCoords(unitID)
    local ux, uy, uz = GetUnitPosition(unitID)
    if not ux or not uy or not uz then
        return
    end
    return WorldToScreenCoords(ux, uy, uz)
end

local function _DrawTeamName(unitID, attributes)
    glTranslate(0, attributes[3], 0)
    glBillboard()

    glColor(attributes[2].color)
    glText(attributes[2].name, 0, 0, attributes[4], 'co')
end

local function _DrawTeamNames()
    for teamID, _ in pairs(teamInfos) do
        local teamAvatar = teamAvatars[teamID]

        -- Periodically check if avatar is near center of screen
        if teamAvatar and teamCheckDelays[teamID] <= 0 then
            local usx, usy = _GetScreenCoords(teamAvatar[1])
            if not usx or not usy or length(scx - usx, scy - usy) > sDistanceMax then
                teamAvatar = nil
                teamAvatars[teamID] = nil
            end
        end

        -- Find avatar
        if (not teamAvatar and teamCheckDelays[teamID] <= 0) or (teamAvatar and not IsUnitInView(teamAvatar[1])) then
            teamAvatars[teamID] = nil
            teamCheckDelays[teamID] = teamCheckDelay

            local bestUnitID, bestUnitInfo, bestDistance, bestIsStatic = nil, nil, 999999999, true
            for unitID, unitInfo in pairs(unitsByTeam[teamID]) do
                if IsUnitInView(unitID) then
                    local isStatic = unitInfo[1]
                    local usx, usy = _GetScreenCoords(unitID)
                    local distance = length(scx - usx, scy - usy)
                    if (bestIsStatic and not isStatic) or ((bestIsStatic or not isStatic) and bestDistance > distance) then
                        bestDistance = distance
                        bestUnitID = unitID
                        bestUnitInfo = unitInfo
                        bestIsStatic = isStatic
                    end
                end
            end
            if bestUnitID ~= nil and bestUnitInfo ~= nil then
                teamAvatars[teamID] = { bestUnitID, teamInfos[teamID], bestUnitInfo[2] }
            end
        end
    end

    local cx, cy, cz = GetCameraPosition()
    for _, attributes in pairs(teamAvatars) do
        -- Log scale the text so that it's readable over a wider range whilst still being world rendered
        local ux, uy, uz = GetUnitPosition(attributes[1])
        local cDistance = length(cx - ux, cy - uy, cz - uz)
        local fontSize = 5 * log(cDistance / 32, 2)
        attributes[4] = fontSize
        glDrawFuncAtUnit(attributes[1], false, _DrawTeamName, attributes[1], attributes)
    end

    glColor(1, 1, 1, 1)
end

function widget:DrawWorld()
    _DrawTeamNames()
end

function widget:UnitFinished(unitID, unitDefID, unitTeam)
    _addUnit(unitTeam, unitID, unitDefID)
end

function widget:UnitDestroyed(unitID, unitDefID, unitTeam)
    unitsByTeam[unitTeam][unitID] = nil
end

function widget:UnitGiven(unitID, unitDefID, unitTeam, oldTeam)
    unitsByTeam[oldTeam][unitID] = nil
    _addUnit(unitTeam, unitID, unitDefID)
end

function widget:UnitTaken(unitID, unitDefID, unitTeam, newTeam)
    unitsByTeam[unitTeam][unitID] = nil
    _addUnit(newTeam, unitID, unitDefID)
end

function widget:UnitEnteredLos(unitID, unitTeam, allyTeam, unitDefID)
    _addUnit(unitTeam, unitID, unitDefID)
end

-- This seems to be called more frequently than UnitEnteredLos, at least during spec, so don't use it
-- function widget:UnitLeftLos(unitID, unitTeam, allyTeam, unitDefID)
--     unitsByTeam[unitTeam][unitID] = nil
-- end
