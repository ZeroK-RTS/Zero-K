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

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------


VFS.Include("LuaRules/Configs/customcmds.h.lua")

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
local floor = math.floor
local abs 	= math.abs


local havens = {}
local havenCount = 0
local RADIUS = 0

----------------------------------------------------------------------------------------
-- functions

local function GetHavens()
	havens = {}
	local myTeamID = Spring.GetLocalTeamID()
	havenCount = Spring.GetTeamRulesParam(myTeamID, "haven_count")
	if havenCount then
		for i = 1, havenCount do
			havens[i] = {
				x = Spring.GetTeamRulesParam(myTeamID, "haven_x" .. i),
				z = Spring.GetTeamRulesParam(myTeamID, "haven_z" .. i)
			}
			havens[i].y = Spring.GetGroundHeight(havens[i].x, havens[i].z)
		end
	end
end

function HavenUpdate(teamID)
	if (Spring.GetLocalTeamID() == teamID) then 
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

function widget:GameFrame(f)
	if f % 30 == 0 then
		--GetHavens()
	end
end
	
function widget:DrawWorld()
	local fade = abs((spGetGameFrame() % 40) - 20) / 20
	--Draw ambulance on havens.
	if #havens == 0 then return end
	
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
		local x, y, z = havenPosition.x, havenPosition.y, havenPosition.z
		gl.PushMatrix()
		glTranslate(x, y, z)
		glBillboard()
		glTexRect(-10, 0, 10, 20)
		gl.PopMatrix()
	end --for
	
	glTexture(false)
	glAlphaTest(false)
	glDepthTest(false)
	
	
end --DrawWorld