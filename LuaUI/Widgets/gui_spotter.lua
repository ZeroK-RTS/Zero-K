--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
--  file:    gui_spotter.lua
--  brief:   Draws smoothed polygons under units
--  author:  metuslucidium (Orig. Dave Rodgers (orig. TeamPlatter edited by TradeMark))
--
--  Copyright (C) 2012.
--  Licensed under the terms of the GNU GPL, v2 or later.
--
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
	return {
		name      = "Spotter",
		desc      = "Draws smoothed polys using fast glDrawListAtUnit",
		author    = "Orig. by 'TradeMark' - mod. by 'metuslucidium'", --updated with options for zk (CarRepairer)
		date      = "01.12.2012",
		license   = "GNU GPL, v2 or later",
		layer     = 5,
		enabled   = false  --  loaded by default?
	}
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local function UpdateDrawList() end

options_path = 'Settings/Graphics/Unit Visibility/Spotter'
options = {
	showEnemyCircle	= {
		name = 'Show Circle Around Enemies',
		desc = 'Show a hard circle rround enemy units',
		type = 'bool',
		value = true,
		noHotkey = true,
		OnChange = function(self)
			UpdateDrawList()
		end
	}
}


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

-- Automatically generated local definitions

local GL_LINE_LOOP           = GL.LINE_LOOP
local GL_TRIANGLE_FAN        = GL.TRIANGLE_FAN
local glBeginEnd             = gl.BeginEnd
local glColor                = gl.Color
local glCreateList           = gl.CreateList
local glDeleteList           = gl.DeleteList
local glDepthTest            = gl.DepthTest
local glDrawListAtUnit       = gl.DrawListAtUnit
local glLineWidth            = gl.LineWidth
local glPolygonOffset        = gl.PolygonOffset
local glVertex               = gl.Vertex
local spDiffTimers           = Spring.DiffTimers
local spGetAllUnits          = Spring.GetAllUnits
local spGetGroundNormal      = Spring.GetGroundNormal
local spGetSelectedUnits     = Spring.GetSelectedUnits
local spGetTeamColor         = Spring.GetTeamColor
local spGetTimer             = Spring.GetTimer
local spGetUnitDefDimensions = Spring.GetUnitDefDimensions
local spGetUnitDefID         = Spring.GetUnitDefID
local spGetUnitRadius        = Spring.GetUnitRadius
local spGetUnitTeam          = Spring.GetUnitTeam
local spGetUnitViewPosition  = Spring.GetUnitViewPosition
local spIsUnitSelected       = Spring.IsUnitSelected
local spIsUnitVisible        = Spring.IsUnitVisible
local spSendCommands         = Spring.SendCommands


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local myTeamID = Spring.GetLocalTeamID()
local realRadii = {}

local circleDivs = 65 -- how precise circle? octagon by default
local innersize = 0.7 -- circle scale compared to unit radius
local outersize = 1.4 -- outer fade size compared to circle scale (1 = no outer fade)

local circlePoly = {}

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

-- Creating polygons, this is run once widget starts, create quads for each team colour:
UpdateDrawList = function()
	for _,team in ipairs(Spring.GetTeamList()) do
		local r, g, b = spGetTeamColor(team)
		local alpha = 0.5
		local fadealpha = 0.2
		if (r == b) and (r == g) then  -- increased alphas for greys/b/w
			alpha = 0.7
			fadealpha = 0.4
		end

		--Spring.Echo("Team", team, "R G B", r, g, b, "Alphas", alpha, fadealpha)
		circlePoly[team] = glCreateList(function()
			-- inner:
			glBeginEnd(GL.TRIANGLES, function()
				local radstep = (2.0 * math.pi) / circleDivs
				for i = 1, circleDivs do
					local a1 = (i * radstep)
					local a2 = ((i+1) * radstep)
					glColor(r, g, b, alpha)
					glVertex(0, 0, 0)
					glColor(r, g, b, fadealpha)
					glVertex(math.sin(a1), 0, math.cos(a1))
					glVertex(math.sin(a2), 0, math.cos(a2))
				end
			end)
			-- outer edge:
			glBeginEnd(GL.QUADS, function()
				local radstep = (2.0 * math.pi) / circleDivs
				for i = 1, circleDivs do
					local a1 = (i * radstep)
					local a2 = ((i+1) * radstep)
					glColor(r, g, b, fadealpha)
					glVertex(math.sin(a1), 0, math.cos(a1))
					glVertex(math.sin(a2), 0, math.cos(a2))
					glColor(r, g, b, 0.0)
					glVertex(math.sin(a2) * outersize, 0, math.cos(a2) * outersize)
					glVertex(math.sin(a1) * outersize, 0, math.cos(a1) * outersize)
				end
			end)
			-- 'enemy spotter' red-yellow 'rainbow' part
			if options.showEnemyCircle.value and not ( Spring.AreTeamsAllied(myTeamID, team) ) then
				-- inner:
				glBeginEnd(GL.QUADS, function()
					local radstep = (2.0 * math.pi) / circleDivs
					for i = 1, circleDivs do
						local a1 = (i * radstep)
						local a2 = ((i+1) * radstep)
						glColor( 1, 1, 0, 0 )
						glVertex(math.sin(a1) * (outersize + 0.8), 0, math.cos(a1) * (outersize + 0.8))
						glVertex(math.sin(a2) * (outersize + 0.8), 0, math.cos(a2) * (outersize + 0.8))
						glColor( 1, 1, 0, 0.33 )
						glVertex(math.sin(a2) * (outersize + 0.9), 0, math.cos(a2) * (outersize + 0.9))
						glVertex(math.sin(a1) * (outersize + 0.9), 0, math.cos(a1) * (outersize + 0.9))
					end
				end)
				-- outer edge:
				glBeginEnd(GL.QUADS, function()
					local radstep = (2.0 * math.pi) / circleDivs
					for i = 1, circleDivs do
						local a1 = (i * radstep)
						local a2 = ((i+1) * radstep)
						glColor( 1, 1, 0, 0.33 )
						glVertex(math.sin(a1) * (outersize + 0.9), 0, math.cos(a1) * (outersize + 0.9))
						glVertex(math.sin(a2) * (outersize + 0.9), 0, math.cos(a2) * (outersize + 0.9))
						glColor( 1, 0, 0, 0.33 )
						glVertex(math.sin(a2) * (outersize + 1.0), 0, math.cos(a2) * (outersize + 1.0))
						glVertex(math.sin(a1) * (outersize + 1.0), 0, math.cos(a1) * (outersize + 1.0))
					end
				end)
				glBeginEnd(GL.QUADS, function()
					local radstep = (2.0 * math.pi) / circleDivs
					for i = 1, circleDivs do
						local a1 = (i * radstep)
						local a2 = ((i+1) * radstep)
						glColor( 1, 0, 0, 0.33 )
						glVertex(math.sin(a1) * (outersize + 1.0), 0, math.cos(a1) * (outersize + 1.0))
						glVertex(math.sin(a2) * (outersize + 1.0), 0, math.cos(a2) * (outersize + 1.0))
						glColor( 1, 0, 0, 0 )
						glVertex(math.sin(a2) * (outersize + 1.1), 0, math.cos(a2) * (outersize + 1.1))
						glVertex(math.sin(a1) * (outersize + 1.1), 0, math.cos(a1) * (outersize + 1.1))
					end
				end)
			end
		end)
	end
end

function widget:Shutdown()
	glDeleteList(circlePolysFoe)
end


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------


-- Retrieving radius:
local function GetUnitDefRealRadius(udid)
	local radius = realRadii[udid]
	if (radius) then return radius end
	local ud = UnitDefs[udid]
	if (ud == nil) then return nil end
	local dims = spGetUnitDefDimensions(udid)
	if (dims == nil) then return nil end
	local scale = ud.hitSphereScale -- missing in 0.76b1+
	scale = ((scale == nil) or (scale == 0.0)) and 1.0 or scale
	radius = dims.radius / scale
	realRadii[udid] = radius*innersize
	return radius
end


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:Initialize()
	UpdateDrawList()
end

				--[[if (spIsUnitSelected (unitID)) then -- for debuggin' sizes/colours
				Spring.Echo (radius)
				end]]
-- Drawing:
function widget:DrawWorldPreUnit()
	glDepthTest(true)
	glPolygonOffset(-10000, -2)  -- draw on top of water/map - sideeffect: will shine through terrain/mountains
	for _,unitID in ipairs(Spring.GetVisibleUnits()) do
		local team = spGetUnitTeam(unitID)
		if (team) then
			local radius = GetUnitDefRealRadius(spGetUnitDefID(unitID))
			if (radius) then
				if radius < 28 then
					radius = radius + 5
				end
				glDrawListAtUnit(unitID, circlePoly[team], false, radius, 1.0, radius)
			end
		end
	end
	glPolygonOffset(false)
	glColor(1,1,1,1)
end


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
