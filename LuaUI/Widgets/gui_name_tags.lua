function widget:GetInfo()
	return {
		name    = "Player Name Tags",
		desc    = "Tag one onscreen unit with the team name",
		author  = "fiendicus_prime",
		date    = "2023-11-29",
		license = "GNU GPL, v2 or later",
		layer   = -9,
		enabled = false
	}
end

--------------------------------------------------------------------------------
-- speed-ups
--------------------------------------------------------------------------------

local log                 = math.log
local min                 = math.min
local sqrt                = math.sqrt

local GetAIInfo           = Spring.GetAIInfo
local GetAllUnits         = Spring.GetAllUnits
local GetAllyTeamList     = Spring.GetAllyTeamList
local GetCameraPosition   = Spring.GetCameraPosition
local GetGaiaTeamID       = Spring.GetGaiaTeamID
local GetMoveType         = Spring.Utilities.getMovetype
local GetPlayerInfo       = Spring.GetPlayerInfo
local GetTeamColor        = Spring.GetTeamColor
local GetTeamInfo         = Spring.GetTeamInfo
local GetTeamList         = Spring.GetTeamList
local GetTeamRulesParam   = Spring.GetTeamRulesParam
local GetUnitDefID        = Spring.GetUnitDefID
local GetUnitHeight       = Spring.Utilities.GetUnitHeight
local GetUnitPosition     = Spring.GetUnitPosition
local GetUnitTeam         = Spring.GetUnitTeam
local GetViewSizes        = Spring.GetViewSizes
local IsUnitInView        = Spring.IsUnitInView
local WorldToScreenCoords = Spring.WorldToScreenCoords

local glBillboard         = gl.Billboard
local glCallList          = gl.CallList
local glColor             = gl.Color
local glCreateList        = gl.CreateList
local glDrawFuncAtUnit    = gl.DrawFuncAtUnit
local glScale             = gl.Scale
local glTranslate         = gl.Translate
local font                = gl.LoadFont('FreeSansBold.otf', 64, 8, 6)

--------------------------------------------------------------------------------
-- config
--------------------------------------------------------------------------------

local heightOffset        = 32
local teamCheckDelay      = 0.25
-- labels are sticky unless units stray into screen borders defined by this fraction
local borderFraction      = 0.15

local teams               = {}
local unitsByTeam         = {}
local teamAvatars         = {}
local teamCheckDelays     = {}

options_path              = "Settings/Interface/Player Name Tags"
options_order             = { "onlyComms" }
options                   = {
	onlyComms = {
		name = "Only tag Commanders",
		type = "bool",
		value = false,
		desc = "Name tags will only be shown on Commanders",
		OnChange = function(self)
			onlyComms = self.value
			teamAvatars = {}
		end,
	},
}

onlyComms                 = options.onlyComms.value

local function _length(x, y, z)
	return sqrt(x * x + y * y + (z and z * z or 0))
end


local nameTagsList = {}

local function _initTeam(teamID, name, color)
    teams[teamID] = true
    nameTagsList[teamID] = glCreateList(function()
        font:Begin()
        font:SetTextColor(color)
        font:SetOutlineColor(0, 0, 0, 1)
        font:Print(name, 0, 0, 5, "con")
        font:End()
    end)
end

local function _initTeams()
	local gaiaTeamID = GetGaiaTeamID()
	for _, allyTeam in pairs(GetAllyTeamList()) do
		for _, teamID in pairs(GetTeamList(allyTeam)) do
			local teamName
			if teamID == gaiaTeamID then
				teamName = "Gaia"
			else
				local _, teamLeader, _, isAI = GetTeamInfo(teamID)
				if teamLeader < 0 then
                    teamLeader = GetTeamRulesParam(teamID, "initLeaderID") or teamLeader
				end
				if isAI then
					local _, name = GetAIInfo(teamID)
					teamName = name
				else
					teamName = GetPlayerInfo(teamLeader)
				end
			end
			local r, g, b = GetTeamColor(teamID)

			unitsByTeam[teamID] = {}
			teamCheckDelays[teamID] = 0

            local name = teamName or ("Team " .. teamID)
            local color = r and g and b and { r, g, b, 1 } or { 1, 1, 1, 1 }
            _initTeam(teamID, name, color)
		end
	end
end

local function _addUnit(unitTeam, unitID, unitDefID)
	unitDefID = unitDefID or GetUnitDefID(unitID)
	local unitDef = UnitDefs[unitDefID]
	if not unitDef then
		-- Why?
		return
	end
	local isStatic = not GetMoveType(unitDef)
	local isComm = unitDef.customParams.level
	local height = GetUnitHeight(unitDef) + heightOffset
	unitsByTeam[unitTeam][unitID] = { isStatic, isComm, height }
end

local function _removeUnit(unitTeam, unitID)
	unitsByTeam[unitTeam][unitID] = nil
	if teamAvatars[unitTeam] and teamAvatars[unitTeam][1] == unitID then
		teamAvatars[unitTeam] = nil
		teamCheckDelays[unitTeam] = 0
	end
end

--------------------------------------------------------------------------------
-- callins
--------------------------------------------------------------------------------

function widget:Initialize()
	_initTeams()

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
    local teamID, _, height, scale = unpack(attributes)
    glTranslate(0, height, 0)
    glScale(scale, scale, scale)
	glBillboard()
    glCallList(nameTagsList[teamID])
end

local function _DrawTeamNames()
	local sx, sy = GetViewSizes()
	local scale = WG.uiScale or 1
	sx, sy = sx * scale, sy * scale
	local scx, scy = sx / 2, sy / 2
	local sxmin, sxmax, symin, symax = sx * borderFraction, sx * (1 - borderFraction), sy * borderFraction, sy * (1 - borderFraction)

    for teamID, _ in pairs(teams) do
		local teamAvatar = teamAvatars[teamID]

		-- Periodically check if avatar is near center of screen
		if teamAvatar and teamCheckDelays[teamID] <= 0 then
            local usx, usy = _GetScreenCoords(teamAvatar[2])
			if not usx or not usy or usx < sxmin or usx > sxmax or usy < symin or usy > symax then
				teamAvatar = nil
				teamAvatars[teamID] = nil
			end
		end

		-- Find avatar
        if (not teamAvatar and teamCheckDelays[teamID] <= 0) or (teamAvatar and not IsUnitInView(teamAvatar[2])) then
			teamAvatars[teamID] = nil
			teamCheckDelays[teamID] = teamCheckDelay

            local bestUnitID, bestDistance, bestIsStatic, bestHeight = nil, 999999999, true, nil
			for unitID, unitInfo in pairs(unitsByTeam[teamID]) do
				if IsUnitInView(unitID) and (not onlyComms or unitInfo[2]) then
					local isStatic = unitInfo[1]
					local usx, usy = _GetScreenCoords(unitID)
					local distance = _length(scx - usx, scy - usy)
					if (bestIsStatic and not isStatic) or ((bestIsStatic or not isStatic) and bestDistance > distance) then
						bestDistance = distance
						bestUnitID = unitID
                        bestHeight = unitInfo[3]
						bestIsStatic = isStatic
					end
				end
			end
            if bestUnitID ~= nil and bestHeight ~= nil then
                teamAvatars[teamID] = { teamID, bestUnitID, bestHeight }
			end
		end
	end

	local cx, cy, cz = GetCameraPosition()
	for _, attributes in pairs(teamAvatars) do
		-- Log scale the text so that it's readable over a wider range whilst still being world rendered
        local unitID = attributes[2]
        local ux, uy, uz = GetUnitPosition(unitID)
		local cDistance = _length(cx - ux, cy - uy, cz - uz)
        attributes[4] = log(cDistance / 32, 2)
        glDrawFuncAtUnit(unitID, false, _DrawTeamName, unitID, attributes)
	end

	glColor(1, 1, 1, 1)
end

function widget:DrawWorld()
	-- Disable for maximum performance. Could be a (shared?) setting like the outline shader.
	if Spring.IsGUIHidden() then return end

	_DrawTeamNames()
end

function widget:UnitFinished(unitID, unitDefID, unitTeam)
	_addUnit(unitTeam, unitID, unitDefID)
end

function widget:UnitDestroyed(unitID, unitDefID, unitTeam)
	_removeUnit(unitTeam, unitID)
end

function widget:UnitGiven(unitID, unitDefID, unitTeam, oldTeam)
	_removeUnit(oldTeam, unitID)
	_addUnit(unitTeam, unitID, unitDefID)
end

function widget:UnitTaken(unitID, unitDefID, unitTeam, newTeam)
	_removeUnit(unitTeam, unitID)
	_addUnit(newTeam, unitID, unitDefID)
end

function widget:UnitEnteredLos(unitID, unitTeam, allyTeam, unitDefID)
	_addUnit(unitTeam, unitID, unitDefID)
end

-- This seems to be called more frequently than UnitEnteredLos, at least during spec, so don't use it
-- function widget:UnitLeftLos(unitID, unitTeam, allyTeam, unitDefID)
--    _removeUnit(unitTeam, unitID)
-- end
