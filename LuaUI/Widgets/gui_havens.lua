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
options_order = {'onlyShowMyZones', 'cancelRetreat'}

local RETREAT_OFF_TABLE = {0}

options = {
	onlyShowMyZones = {
		name = 'Only Show My Zones',
		desc = 'With this enabled you will only see your retreat zones.',
		type = 'bool',
		value = true,
		OnChange = function(self)
			GetHavens()
		end,
	},
	cancelRetreat = {
		name = 'Cancel Retreat',
		desc = 'Set your selected units to not retreat. It might be useful to assign it a hotkey.',
		type = 'button',
		OnChange = function(self)
			Spring.GiveOrder(CMD_RETREAT, RETREAT_OFF_TABLE, CMD.OPT_RIGHT)
		end,
	},
}

-- speed-ups

local echo = Spring.Echo

local spGetGameFrame = Spring.GetGameFrame

local glDepthTest      = gl.DepthTest
local glAlphaTest      = gl.AlphaTest
local glTexture        = gl.Texture
local glTexRect        = gl.TexRect
local glTranslate      = gl.Translate
local glBillboard      = gl.Billboard
local glColor          = gl.Color
local GL_GREATER       = GL.GREATER

local min	= math.min
local max = math.max
local floor = math.floor
local abs 	= math.abs

local havens = {}
local havenCount = 0
local RADIUS = 0

----------------------------------------------------------------------------------------
-- functions

function GetTeamHavens(teamID)
	local start = havenCount
	local teamHavenCount = Spring.GetTeamRulesParam(teamID, "haven_count")
	if teamHavenCount then
		havenCount = havenCount + teamHavenCount
		if havenCount then
			for i = 1, teamHavenCount do
				havens[start + i] = {
					x = Spring.GetTeamRulesParam(teamID, "haven_x" .. i),
					z = Spring.GetTeamRulesParam(teamID, "haven_z" .. i)
				}
				havens[start + i].y = Spring.GetGroundHeight(havens[start + i].x, havens[start + i].z)
			end
		end
	end
end

function GetHavens()
	havens = {}
	havenCount = 0
	if options.onlyShowMyZones.value then
		local spectating = Spring.GetSpectatingState()
		if not spectating then
			GetTeamHavens(Spring.GetLocalTeamID())
		end
	else
		local teams = Spring.GetTeamList()
		for i = 0, #teams-1 do
			GetTeamHavens(i)
		end
	end
end

function HavenUpdate(teamID, allyTeamID)
	local spectating = Spring.GetSpectatingState()
	if (not spectating and Spring.GetLocalTeamID() == teamID) or (not options.onlyShowMyZones.value) then 
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

	for i = 1, havenCount do
		local havenPosition = havens[i]
		local x, y, z = havenPosition.x, havenPosition.y, havenPosition.z

		gl.LineWidth(4)
		glColor(1, 1, 1, 0.5)
		gl.DrawGroundCircle(x, y, z, RADIUS, 32)

		gl.LineWidth(2)
		glColor(1, 0.1, 0.1, 0.8)
		gl.DrawGroundCircle(x, y, z, RADIUS, 32)

	end --for
	glAlphaTest(GL_GREATER, 0)
	glColor(1,fade,fade,fade+0.1)
	glTexture('LuaUI/Images/commands/Bold/retreat.png')
	
	for i = 1, havenCount do
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