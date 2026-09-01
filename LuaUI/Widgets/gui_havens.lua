-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------

function widget:GetInfo()
  return {
    name      = "Haven Handler",
    desc      = "Haven Handler for Retreat Gadget",
    author    = "CarRepairer",
    date      = "2014-04-10",
    license   = "GNU GPL, v2 or later",
	handler   = true,
    layer     = 0,
    enabled   = true,
  }
end

VFS.Include("LuaRules/Configs/customcmds.h.lua")

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------

options_path = 'Settings/Interface/Retreat Zones'
options_order = {'drawAllyZones', 'drawNames', 'cancelRetreat'}

local RETREAT_OFF_TABLE = {0}

options = {
	drawAllyZones = {
		name = 'Show All Player Retreat Zones',
		desc = 'Displays retreat zones of other players',
		type = 'bool',
		value = true,
	},
	drawNames = {
		name = 'Label Player Names',
		desc = "Draws the name of other players' retreat zones",
		type = 'bool',
		value = false,
	},
	cancelRetreat = {
		name = 'Cancel Retreat',
		desc = 'Set your selected units to not retreat. It might be useful to assign it a hotkey.',
		type = 'button',
		action  = 'cancelretreat',
		hidden = true,
		OnChange = function(self)
			Spring.GiveOrder(CMD_RETREAT, RETREAT_OFF_TABLE, CMD.OPT_RIGHT)
		end,
	},
}

-- speed-ups

local spGetGameFrame = Spring.GetGameFrame
local spGetLocalPlayerID = Spring.GetLocalPlayerID

local glDepthTest      = gl.DepthTest
local glAlphaTest      = gl.AlphaTest
local glTexture        = gl.Texture
local glTexRect        = gl.TexRect
local glTranslate      = gl.Translate
local glBillboard      = gl.Billboard
local glColor          = gl.Color
local GL_GREATER       = GL.GREATER

local max = math.max
local abs 	= math.abs

local havens = {}
local RADIUS = 0
local DEFAULT_HAVEN_COLOR = {1, 0.1, 0.1, 0.8}

----------------------------------------------------------------------------------------
-- functions
function GetTeamName(teamID)
	local _, leaderID = Spring.GetTeamInfo(teamID, false)
    local playerName = Spring.GetPlayerInfo(leaderID, true)
	return playerName
end

function GetTeamHavens(teamID)
	local teamHavenCount = Spring.GetTeamRulesParam(teamID, "haven_count")
	if teamHavenCount then
		local teamLeaderName = GetTeamName(teamID) or "???"
		local teamcolor = {Spring.GetTeamColor(teamID)} or DEFAULT_HAVEN_COLOR

		local start = #havens
		for i = 1, teamHavenCount do
			havens[start + i] = {
				x = Spring.GetTeamRulesParam(teamID, "haven_x" .. i),
				z = Spring.GetTeamRulesParam(teamID, "haven_z" .. i)
			}
			havens[start + i].y = Spring.GetGroundHeight(havens[start + i].x, havens[start + i].z)
			havens[start + i].name = teamLeaderName
			havens[start + i].color = teamcolor
			havens[start + i].team = teamID
		end
	end
end

function GetHavens()
	havens = {}
	local teams = Spring.GetTeamList()
	for i = 0, #teams-1 do
		GetTeamHavens(i)
	end
end

function HavenUpdate(teamID, allyTeamID)
	local spectating = Spring.GetSpectatingState()
	if (not spectating and Spring.GetLocalTeamID() == teamID) or options.drawAllyZones.value then
		GetHavens()
	end
end

----------------------------------------------------------------------------------------
--callins

function widget:PlayerChanged(playerID)
	if playerID == Spring.GetMyPlayerID() then
		GetHavens()
	end
end

function widget:Initialize()
	RADIUS = Spring.GetGameRulesParam('retreatZoneRadius') or 5
	widgetHandler:RegisterGlobal(widget, "HavenUpdate", HavenUpdate)
	GetHavens()
end

function widget:CommandNotify(cmdID, cmdParams, cmdOptions)
	if cmdID == CMD_SETHAVEN then
		local x,y,z = cmdParams[1], cmdParams[2], cmdParams[3]
		Spring.SendLuaRulesMsg('sethaven|' .. x .. '|' .. y .. '|' .. z )
		return true
	end
end

function widget:CommandsChanged()
	local customCommands = widgetHandler.customCommands

	--Add retreat-area button
	table.insert(customCommands, {
		id      = CMD_SETHAVEN,
		type    = CMDTYPE.ICON_MAP,
		tooltip = 'Place a retreat zone. Units will retreat there.',
		cursor  = 'Repair',
		action  = 'sethaven',
		params  = { },
		texture = 'LuaUI/Images/commands/Bold/retreat.png',

		pos = {123},
	})
end

local function DrawWorldFunc()
	local fade = abs((spGetGameFrame() % 40) - 20) / 20
	--Draw ambulance on havens.
	if #havens == 0 or Spring.IsGUIHidden() then
		return
	end

	glDepthTest(true)
	gl.LineWidth(2)

	for i = 1, #havens do
		local havenPosition = havens[i]
		-- TODO spGetLocalPLayerID interacts poorly when local player is cheating between teams and spectator.
		-- Change comparison logic to work better in this edge case.
		if options.drawAllyZones.value or havenPosition.team == spGetLocalPlayerID() then
			local x, y, z = havenPosition.x, havenPosition.y, havenPosition.z

			gl.LineWidth(4)
			glColor(1, 1, 1, 0.5) --WHITE
			gl.DrawGroundCircle(x, y, z, RADIUS, 32)
			gl.LineWidth(2)
			if havenPosition.team == spGetLocalPlayerID() then
				glColor(DEFAULT_HAVEN_COLOR)
			else
				glColor(havenPosition.color)
			end
			gl.DrawGroundCircle(x, y, z, RADIUS, 32)

			gl.PushMatrix()
			glTranslate(x, y, z)
			glBillboard()
			if options.drawNames.value then
				glColor(havenPosition.color)
				gl.Text(havenPosition.name, 0, -10, 15, 'noc')
			end
			gl.PopMatrix()
		end
	end --for

	glAlphaTest(GL_GREATER, 0)
	glColor(1,fade,fade,fade+0.1)
	glTexture('LuaUI/Images/commands/Bold/retreat.png')
	for i = 1, #havens do
		local havenPosition = havens[i]
		if options.drawAllyZones.value or havenPosition.team == spGetLocalPlayerID() then
			local x, y, z = havenPosition.x, max(havenPosition.y, 0.0), havenPosition.z

			gl.PushMatrix()
			glTranslate(x, y, z)
			glBillboard()
			glTexRect(-10, 0, 10, 20)
			gl.PopMatrix()
		end
	end --for

	glTexture(false)
	glAlphaTest(false)
	glDepthTest(false)
end
	
function widget:DrawWorld()
	DrawWorldFunc()
end --DrawWorld

function widget:DrawWorldRefraction()
	DrawWorldFunc()
end
