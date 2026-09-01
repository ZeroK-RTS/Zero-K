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
options_order = {'drawAllyZones', 'drawNames', 'customRetreatCircleColor', 'RetreatCircleColor', 'cancelRetreat'}

local RETREAT_OFF_TABLE = {0}
local PLAYER_HAVEN_COLOR = {1, 0.1, 0.1, 0.8}

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
	customRetreatCircleColor = {
		name = 'Use custom color',
		desc = 'Override player Retreat Circle color',
		type = 'bool',
		value = true,
	},
	RetreatCircleColor = {
		name = 'Retreat Circle',
		type = 'colors',
		value = {1, 0.1, 0.1, 0.8},
		OnChange = function (self)
			PLAYER_HAVEN_COLOR = self.value
		end,
		advanced = true
	},
}

-- speed-ups

local spGetGameFrame = Spring.GetGameFrame
local spGetLocalTeamID = Spring.GetLocalTeamID
local spGetTeamInfo = Spring.GetTeamInfo
local spGetPlayerInfo = Spring.GetPlayerInfo
local spGetTeamRulesParam = Spring.GetTeamRulesParam
local spGetTeamColor = Spring.GetTeamColor
local spGetGroundHeight = Spring.GetGroundHeight
local spGetTeamList = Spring.GetTeamList
local spGetMyPlayerID = Spring.GetMyPlayerID
local spIsGUIHidden = Spring.IsGUIHidden
local spGetSpectatingState = Spring.GetSpectatingState
local spGetGameRulesParam = Spring.GetGameRulesParam
local spSendLuaRulesMsg = Spring.SendLuaRulesMsg

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

----------------------------------------------------------------------------------------
-- functions
local function GetTeamName(teamID)
	local _, leaderID = spGetTeamInfo(teamID, false)
	local playerName = spGetPlayerInfo(leaderID, true)
	return playerName
end

local function GetTeamHavens(teamID)
	local teamHavenCount = spGetTeamRulesParam(teamID, "haven_count")
	if teamHavenCount then
		local teamLeaderName = GetTeamName(teamID) or "???"
		local teamcolor = {spGetTeamColor(teamID)}

		local start = #havens
		for i = 1, teamHavenCount do
			havens[start + i] = {
				x = spGetTeamRulesParam(teamID, "haven_x" .. i),
				z = spGetTeamRulesParam(teamID, "haven_z" .. i)
			}
			havens[start + i].y = spGetGroundHeight(havens[start + i].x, havens[start + i].z)
			havens[start + i].name = teamLeaderName
			havens[start + i].color = teamcolor
			havens[start + i].team = teamID
		end
	end
end

local function HavenUpdate()
	havens = {}
	local teams = spGetTeamList()
	for i = 0, #teams-1 do
		GetTeamHavens(i)
	end
end

----------------------------------------------------------------------------------------
--callins

function widget:PlayerChanged(playerID)
	if playerID == spGetMyPlayerID() then
		HavenUpdate()
	end
end

function widget:Initialize()
	RADIUS = spGetGameRulesParam('retreatZoneRadius') or 5
	widgetHandler:RegisterGlobal(widget, "HavenUpdate", HavenUpdate)
	HavenUpdate()
end

function widget:CommandNotify(cmdID, cmdParams, cmdOptions)
	if cmdID == CMD_SETHAVEN then
		local x,y,z = cmdParams[1], cmdParams[2], cmdParams[3]
		spSendLuaRulesMsg('sethaven|' .. x .. '|' .. y .. '|' .. z )
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
	if #havens == 0 or spIsGUIHidden() then
		return
	end
	local spectating = spGetSpectatingState()

	glDepthTest(true)
	gl.LineWidth(2)

	-- iterate over each haven and draw bounding circle and ?playername
	for i = 1, #havens do
		local havenPosition = havens[i]
		if options.drawAllyZones.value or havenPosition.team == spGetLocalTeamID() then
			local x, y, z = havenPosition.x, havenPosition.y, havenPosition.z

			gl.LineWidth(4)
			glColor(1, 1, 1, 0.5) --WHITE
			gl.DrawGroundCircle(x, y, z, RADIUS, 32)
			gl.LineWidth(2)
			if not spectating and havenPosition.team == spGetLocalTeamID() and options.customRetreatCircleColor.value then
				glColor(PLAYER_HAVEN_COLOR)
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

	--iterate over havens again but this time paint flashing retreat indicator
	glAlphaTest(GL_GREATER, 0)
	glColor(1,fade,fade,fade+0.1)
	glTexture('LuaUI/Images/commands/Bold/retreat.png')
	for i = 1, #havens do
		local havenPosition = havens[i]
		if options.drawAllyZones.value or havenPosition.team == spGetLocalTeamID() then
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
