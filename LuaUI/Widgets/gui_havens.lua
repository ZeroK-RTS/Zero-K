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
local myTeamID = 0
local RADIUS = 0

----------------------------------------------------------------------------------------
-- functions

local function explode(div,str)
  if (div=='') then return false end
  local pos,arr = 0,{}
  -- for each divider found
  for st,sp in function() return string.find(str,div,pos,true) end do
    table.insert(arr,string.sub(str,pos,st-1)) -- Attach chars left of current divider
    pos = sp + 1 -- Jump past current divider
  end
  table.insert(arr,string.sub(str,pos)) -- Attach chars right of last divider
  return arr
end


function GetHavens()
	havens = {}
	local temp = Spring.GetTeamRulesParam(myTeamID, "havens")
	if not temp or temp == 0 then return end
	
	temp = explode('|', temp)
	for i, v in ipairs(temp) do
		havens[#havens+1] = explode(',', v)
	end
	
end


----------------------------------------------------------------------------------------
--callins



function widget:Initialize()
	RADIUS = Spring.GetGameRulesParam('retreatZoneRadius') or 5
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
		myTeamID = Spring.GetLocalTeamID()
		GetHavens()
	end
end
	
function widget:DrawWorld()
	local fade = abs((spGetGameFrame() % 40) - 20) / 20
	--Draw ambulance on havens.
	if #havens == 0 then return end
	
	glDepthTest(true)
	gl.LineWidth(2)

	for _, havenPosition in ipairs(havens) do
		local x, y, z = havenPosition[1], havenPosition[2], havenPosition[3]

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
	
	for unitID, havenPosition in pairs(havens) do
		local x, y, z = havenPosition[1], havenPosition[2], havenPosition[3]
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