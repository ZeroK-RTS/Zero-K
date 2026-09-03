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
options_order = {'drawNames', 'playerZonesRadio', 'customRetreatCircleColor', 'retreatCircleColor', 'cancelRetreat'}

local RETREAT_OFF_TABLE = {0}
local PLAYER_HAVEN_COLOR = {1, 0.1, 0.1, 0.8}
local HavenUpdate

options = {
	playerZonesRadio = {
		name = "Display Zone options",
		type = 'radioButton',
		value = 'player_only_spectator_los',
		items = {
			{
				key = "player_only",
				name = "Player Only",
				desc = "Only show player's own Retreat Zones",
			},
			{
				key = "los",
				name = "Team",
				desc = "Show player's and ally's Retreat Zones",
			},
			{
				key = "player_only_spectator",
				name = "Player Only (Spectator)",
				desc = "Only show spectated player's Retreat Zones",
			},
			{
				key = "los_spectator",
				name = "Team (Spectator)",
				desc = "Show all Retreat Zones as Spectator",
			},
			{
				key = "player_only_spectator_los",
				name = "Player Only/ Spectator All",
				desc = "Only show player's zones when playing, but all zones as spectator",
			},
		},
		OnChange = function(self)
			HavenUpdate()
		end,
		noHotkey = true,
	},
	drawNames = {
		name = 'Label Player Names',
		desc = "Draws the name of other players' retreat zones",
		type = 'bool',
		value = false,
		noHotkey = true,
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
		noHotkey = true,
		OnChange = function(self)
			HavenUpdate()
		end,
	},
	retreatCircleColor = {
		name = 'Retreat Circle',
		type = 'colors',
		value = {1, 0.1, 0.1, 0.8},
		OnChange = function (self)
			PLAYER_HAVEN_COLOR = self.value
			HavenUpdate()
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

HavenUpdate = function () -- local function
	havens = {}
	local spectating = spGetSpectatingState()
	local teams
	-- how many states can we be in?
	-- we can be spectating
	-- we can be playing
	-- options.drawSpectatorZones.value
	-- options.drawAllyZones.value
	local opt = options.playerZonesRadio.value
	if spectating and (opt == "player_only" or opt == "los") then
		-- do not populate havens if option is not spectator option
		teams = havens -- empty table
	else
		if opt == "los" or opt == "los_spectator" or (spectating and opt == "player_only_spectator_los") then
			teams = spGetTeamList() -- all teams LOS visible
		else -- opt is "player_only" or "player_only_spectator"
			teams = {spGetLocalTeamID()} -- just my team
		end
	end
	for x = 1, #teams do
		local teamID = teams[x]
		local teamHavenCount = spGetTeamRulesParam(teamID, "haven_count")
		if teamHavenCount then
			local teamLeaderName = GetTeamName(teamID) or "???"
			local teamcolor = {spGetTeamColor(teamID)}
			if teamID == spGetLocalTeamID() and options.customRetreatCircleColor.value then
				teamcolor = PLAYER_HAVEN_COLOR
			end

			local start = #havens
			for i = 1, teamHavenCount do
				local px, pz = spGetTeamRulesParam(teamID, "haven_x" .. i), spGetTeamRulesParam(teamID, "haven_z" .. i)
				havens[start + i] = {
					x = px,
					z = pz,
					y = spGetGroundHeight(px, pz), -- strange when height at xz changes
					name = teamLeaderName,
					color = teamcolor,
					team = teamID,
				}
			end
		end
	end
end

----------------------------------------------------------------------------------------
--callins

function widget:PlayerChanged(playerID)
	if playerID == spGetMyPlayerID() or spGetSpectatingState() then
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
	if #havens == 0 or spIsGUIHidden() then
		return
	end

	local drawNames = options.drawNames.value

	glDepthTest(true)
	gl.LineWidth(2)

	-- iterate over each haven and draw bounding circle and ?playername
	for i = 1, #havens do
		local havenPosition = havens[i]
		local x, y, z = havenPosition.x, havenPosition.y, havenPosition.z
		-- rather not make spring call for height here, but height can do strange things.

		gl.LineWidth(4)
		glColor(1, 1, 1, 0.5) --WHITE
		gl.DrawGroundCircle(x, y, z, RADIUS, 32)
		gl.LineWidth(2)
		glColor(havenPosition.color)
		gl.DrawGroundCircle(x, y, z, RADIUS, 32)

		if drawNames then
			gl.PushMatrix()
			glTranslate(x, y, z)
			glBillboard()
			glColor(havenPosition.color)
			gl.Text(havenPosition.name, 0, -10, 15, 'noc')
			gl.PopMatrix()
		end
	end --for

	--iterate over havens again but this time paint ambulance indicator
	local fade = abs((spGetGameFrame() % 40) - 20) / 20
	glAlphaTest(GL_GREATER, 0)
	glColor(1,fade,fade,fade+0.1)
	glTexture('LuaUI/Images/commands/Bold/retreat.png')
	for i = 1, #havens do
		local havenPosition = havens[i]
		local x, y, z = havenPosition.x, max(havenPosition.y, 0.0), havenPosition.z

		gl.PushMatrix()
		glTranslate(x, y, z)
		glBillboard()
		glTexRect(-10, 0, 10, 20)
		gl.PopMatrix()
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
