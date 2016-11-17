local version = "v1.003"
function widget:GetInfo()
  return {
    name      = "Showeco and Grid Drawer",
    desc      = "Register an action called Showeco & draw overdrive overlay.", --"acts like F4",
    author    = "xponen, ashdnazg (RTT)",
    date      = "July 19 2013",
    license   = "GNU GPL, v2 or later",
    layer     = 0, --only layer > -4 works because it seems to be blocked by something.
    enabled   = true,  --  loaded by default?
    handler   = true,
  }
end

local useRTT = gl.CreateFBO and gl.BlitFBO and true

local pylon ={}

local spGetMapDrawMode = Spring.GetMapDrawMode
local spSendCommands   = Spring.SendCommands

local function ToggleShoweco()
  WG.showeco = not WG.showeco

  if (not WG.metalSpots and (spGetMapDrawMode() == "metal") ~= WG.showeco) then
    spSendCommands("showmetalmap")
  end
end

WG.ToggleShoweco = ToggleShoweco

--------------------------------------------------------------------------------------
--Grid drawing. Copied and trimmed from unit_mex_overdrive.lua gadget (by licho & googlefrog)
VFS.Include("LuaRules/Configs/constants.lua", nil, VFS.ZIP_FIRST)
VFS.Include("LuaRules/Utilities/glVolumes.lua") --have to import this incase it fail to load before this widget

local spGetSelectedUnits   = Spring.GetSelectedUnits
local spGetUnitDefID       = Spring.GetUnitDefID
local spGetUnitPosition    = Spring.GetUnitPosition
local spGetActiveCommand   = Spring.GetActiveCommand
local spTraceScreenRay     = Spring.TraceScreenRay
local spGetMouseState      = Spring.GetMouseState
local spAreTeamsAllied     = Spring.AreTeamsAllied
local spGetMyTeamID        = Spring.GetMyTeamID
local spGetUnitPosition    = Spring.GetUnitPosition
local spValidUnitID        = Spring.ValidUnitID
local spGetUnitRulesParam  = Spring.GetUnitRulesParam
local spGetSpectatingState = Spring.GetSpectatingState
local spGetBuildFacing     = Spring.GetBuildFacing
local spPos2BuildPos       = Spring.Pos2BuildPos

local glVertex        = gl.Vertex
local glCallList      = gl.CallList
local glColor         = gl.Color
local glBeginEnd      = gl.BeginEnd
local glCreateList    = gl.CreateList

--// gl const

local GL_DEPTH24_STENCIL8 = 0x88F0

local GL_READ_FRAMEBUFFER_EXT = 0x8CA8
local GL_DRAW_FRAMEBUFFER_EXT = 0x8CA9

local pylons = {count = 0, data = {}}
local pylonByID = {}

local pylonDefs = {}

for i=1,#UnitDefs do
	local udef = UnitDefs[i]
	if (tonumber(udef.customParams.pylonrange) or 0 > 0) then
		pylonDefs[i] = {
			range = tonumber(udef.customParams.pylonrange)
		}
	end
end

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
-- local functions
local drawAlpha = 0.2
local colorAlpha = useRTT and 1 or drawAlpha
local disabledColor = { 0.6,0.7,0.5, colorAlpha}
local placementColor = { 0.6, 0.7, 0.5, drawAlpha} -- drawAlpha on purpose!

local function HSLtoRGB(ch,cs,cl)
	local cr, cg, cb
	if cs == 0 then
		cr = cl
		cg = cl
		cb = cl
	else
		local temp2
		if cl < 0.5 then
			temp2 = cl * (cl + cs)
		else
			temp2 = (cl + cs) - (cl * cs)
		end

		local temp1 = 2 * cl - temp2
		local tempr = ch + 1 / 3

		if tempr > 1 then
			tempr = tempr - 1
		end
		local tempg = ch
		local tempb = ch - 1 / 3
		if tempb < 0 then
			tempb = tempb + 1
		end

		if tempr < 1 / 6 then
			cr = temp1 + (temp2 - temp1) * 6 * tempr
		elseif tempr < 0.5 then
			cr = temp2
		elseif tempr < 2 / 3 then
			cr = temp1 + (temp2 - temp1) * ((2 / 3) - tempr) * 6
		else
			cr = temp1
		end

		if tempg < 1 / 6 then
			cg = temp1 + (temp2 - temp1) * 6 * tempg
		elseif tempg < 0.5 then
			cg = temp2
		elseif tempg < 2 / 3 then
			cg = temp1 + (temp2 - temp1) * ((2 / 3) - tempg) * 6
		else
			cg = temp1
		end

		if tempb < 1 / 6 then
			cb = temp1 + (temp2 - temp1) * 6 * tempb
		elseif tempb < 0.5 then
			cb = temp2
		elseif tempb < 2 / 3 then
			cb = temp1 + (temp2 - temp1) * ((2 / 3) - tempb) * 6
		else
			cb = temp1
		end

	end
	return {cr,cg,cb, colorAlpha}
end --HSLtoRGB


local function GetGridColor(efficiency)
 	local n = efficiency
	-- mex has no esource/esource has no mex
	if n==0 then
		return {1, .25, 1, colorAlpha}
	else
		if n < 3.5 then
			h = 5760/(3.5+2)^2
		else
			h=5760/(n+2)^2
		end
		return HSLtoRGB(h/255,1,0.5)
	end
end

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
-- Unit Handling

local function InitializeUnits()
	pylons = {count = 0, data = {}}
	pylonByID = {}
	local allUnits = Spring.GetAllUnits()
	for i=1, #allUnits do
		local unitID = allUnits[i]
		local unitDefID = spGetUnitDefID(unitID)
		local unitTeam = Spring.GetUnitTeam(unitID)
		widget:UnitCreated(unitID, unitDefID, unitTeam)
	end
end

local function addUnit(unitID, unitDefID, unitTeam)
	if pylonDefs[unitDefID] and not pylonByID[unitID] then
		local spec, fullview = spGetSpectatingState()
		spec = spec or fullview
		if spec or spAreTeamsAllied(unitTeam, spGetMyTeamID()) then
			local x,y,z = spGetUnitPosition(unitID)
			pylons.count = pylons.count + 1
			pylons.data[pylons.count] = {unitID = unitID, x = x, y = y, z = z, range = pylonDefs[unitDefID].range}
			pylonByID[unitID] = pylons.count
		end
	end
end

local function removeUnit(unitID, unitDefID, unitTeam)
	pylons.data[pylonByID[unitID]] = pylons.data[pylons.count]
	pylonByID[pylons.data[pylons.count].unitID] = pylonByID[unitID]
	pylons.data[pylons.count] = nil
	pylons.count = pylons.count - 1
	pylonByID[unitID] = nil
end

function widget:UnitCreated(unitID, unitDefID, unitTeam)
	addUnit(unitID, unitDefID, unitTeam)
end

function widget:UnitDestroyed(unitID, unitDefID, unitTeam)
	if pylonByID[unitID] then
		removeUnit(unitID, unitDefID, unitTeam)
	end
end

function widget:UnitGiven(unitID, unitDefID, unitTeam, oldTeam)
	addUnit(unitID, unitDefID, unitTeam)
end

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------

local prevFullView = false
local prevTeamID = -1

function widget:Update(dt)
	local teamID = Spring.GetMyTeamID()
	local _, fullView = Spring.GetSpectatingState()
	if (fullView ~= prevFullView) or (teamID ~= prevTeamID) then
		InitializeUnits()
	end
	prevFullView = fullView
	prevTeamID = teamID
end

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------


-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
-- Drawing

local drawList = 0
local disabledDrawList = 0
local fbo
local offscreentex
local texStencil
local vsx, vsy
local lastDrawnFrame = 0
local lastFrame = 2

function widget:Initialize()
	if useRTT then
		fbo = gl.CreateFBO()
	end
	self:ViewResize(widgetHandler:GetViewSizes())
	InitializeUnits()
end

function widget:Shutdown(f)
	if useRTT then
		gl.DeleteTexture(offscreentex or 0)
		gl.DeleteRBO(texStencil or 0)
		gl.DeleteFBO(fbo or 0)
	end
	gl.DeleteList(drawList or 0)
	gl.DeleteList(disabledDrawList or 0)
end

function widget:ViewResize(viewSizeX, viewSizeY)
	vsx = viewSizeX
	vsy = viewSizeY
	if useRTT then
		fbo.color0 = nil
		fbo.stencil = nil
		fbo.depth = nil
		gl.DeleteRBO(texStencil)
		gl.DeleteTexture(offscreentex or 0)

		offscreentex = gl.CreateTexture(vsx,vsy, {
			border = false,
			min_filter = GL.LINEAR,
			mag_filter = GL.LINEAR,
		})

		texStencil = gl.CreateRBO(vsx, vsy, {
			format = GL_DEPTH24_STENCIL8,
		})

		fbo.depth  = texStencil
		fbo.color0 = offscreentex
		fbo.stencil = texStencil
	end
end


function widget:GameFrame(f)
	if f%32 == 2 then
		lastFrame = f
	end
end


local function makePylonListVolume(onlyActive, onlyDisabled)
	local drawGroundCircle = gl.Utilities.DrawGroundCircle
	local i = 1
	while i <= pylons.count do
		local data = pylons.data[i]
		local unitID = data.unitID
		if spValidUnitID(unitID) then
			local efficiency = spGetUnitRulesParam(unitID, "gridefficiency") or -1
			if efficiency == -1 and not onlyActive then
				glColor(disabledColor)
				drawGroundCircle(data.x, data.z, data.range)
			elseif efficiency ~= -1 and not onlyDisabled then
				local color = GetGridColor(efficiency)
				glColor(color)
				drawGroundCircle(data.x, data.z, data.range)
			end
			i = i + 1
		else
			pylons.data[i] = pylons.data[pylons.count]
			pylonByID[pylons.data[i].unitID] = i
			pylons.data[pylons.count] = nil
			pylons.count = pylons.count - 1
		end
	end
end

local function RenderTex(dList)
	gl.Clear(GL.STENCIL_BUFFER_BIT, 0)
	gl.Clear(GL.COLOR_BUFFER_BIT,0,0,0,0)
	gl.CallList(dList)
end

local function HighlightPylons()
	if lastDrawnFrame < lastFrame then
		lastDrawnFrame = lastFrame
		if useRTT then
			gl.DeleteList(disabledDrawList or 0)
			disabledDrawList = gl.CreateList(makePylonListVolume, false, true)
			gl.DeleteList(drawList or 0)
			drawList = gl.CreateList(makePylonListVolume, true, false)
		else
			gl.DeleteList(drawList or 0)
			drawList = gl.CreateList(makePylonListVolume)
		end
	end
	if useRTT then
		gl.UnsafeSetFBO(nil, GL_READ_FRAMEBUFFER_EXT) -- default FBO
		gl.UnsafeSetFBO(fbo, GL_DRAW_FRAMEBUFFER_EXT)
		gl.BlitFBO(0,0,vsx,vsy,0,0,vsx,vsy,GL.DEPTH_BUFFER_BIT)
		gl.UnsafeSetFBO(nil, GL_DRAW_FRAMEBUFFER_EXT)

		gl.ActiveFBO(fbo,RenderTex, drawList)
		gl.MatrixMode(GL.PROJECTION); gl.PushMatrix(); gl.LoadIdentity()
		gl.MatrixMode(GL.MODELVIEW);  gl.PushMatrix(); gl.LoadIdentity()
		gl.Texture(offscreentex)
		glColor(1,1,1,drawAlpha)
		gl.TexRect(-1-0.5/vsx,1+0.5/vsy,1+0.5/vsx,-1-0.5/vsy)
		glColor(1,1,1,1)
		gl.Texture(false)
		gl.MatrixMode(GL.PROJECTION); gl.PopMatrix()
		gl.MatrixMode(GL.MODELVIEW);  gl.PopMatrix()

		gl.ActiveFBO(fbo,RenderTex, disabledDrawList)
		gl.MatrixMode(GL.PROJECTION); gl.PushMatrix(); gl.LoadIdentity()
		gl.MatrixMode(GL.MODELVIEW);  gl.PushMatrix(); gl.LoadIdentity()
		gl.Texture(offscreentex)
		glColor(1,1,1,drawAlpha)
		gl.TexRect(-1-0.5/vsx,1+0.5/vsy,1+0.5/vsx,-1-0.5/vsy)
		glColor(1,1,1,1)
		gl.Texture(false)
		gl.MatrixMode(GL.PROJECTION); gl.PopMatrix()
		gl.MatrixMode(GL.MODELVIEW);  gl.PopMatrix()
	else
		gl.CallList(drawList)
	end
end

local function HighlightPlacement(unitDefID)
	local mx, my = spGetMouseState()
	local _, coords = spTraceScreenRay(mx, my, true, true, false, true)
	if coords then
		local radius = pylonDefs[unitDefID].range
		if (radius ~= 0) then
			local x, _, z = spPos2BuildPos( unitDefID, coords[1], 0, coords[3], spGetBuildFacing())
			glColor(placementColor)
			gl.Utilities.DrawGroundCircle(x,z, radius)
		end
	end
end


function widget:DrawWorldPreUnit()
	if Spring.IsGUIHidden() then return end

	local _, cmd_id = spGetActiveCommand()  -- show pylons if pylon is about to be placed
	if (cmd_id) then
		if pylonDefs[-cmd_id] then
			HighlightPylons()
			HighlightPlacement(-cmd_id)
			glColor(1,1,1,1)
			return
		end
	end

	local selUnits = spGetSelectedUnits()  -- or show it if its selected
	if selUnits then
		for i=1,#selUnits do
			local ud = spGetUnitDefID(selUnits[i])
			if (pylonDefs[ud]) then
				HighlightPylons()
				glColor(1,1,1,1)
				return
			end
		end
	end

	local showecoMode = WG.showeco
	if showecoMode then
		HighlightPylons()
		glColor(1,1,1,1)
		return
	end
end
