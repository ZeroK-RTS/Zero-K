--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
--  file:    gui_fancy_teamplatter.lua
--  brief:   Draws transparant smoothed donuts under enemy units
--  author:  Dave Rodgers (orig. TeamPlatter edited by TradeMark)
--
--  Copyright (C) 2007.
--  Licensed under the terms of the GNU GPL, v2 or later.
--
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
   return {
      name      = "Fancy Teamplatter",
      desc      = "Draws transparant smoothed donuts under friendly and enemy units (using teamcolor)",
      author    = "TradeMark  (Floris: added multiple ally color support) (Forboding Angel: removed extra FX stuff) (zoggop: made it use only team colors)",
      date      = "7.02.2014",
      license   = "GNU GPL, v2 or later",
      layer     = 5,
      enabled   = false  --  loaded by default?
   }
end



--------------------------------------------------------------------------------
-- Config
--------------------------------------------------------------------------------

local drawWithHiddenGUI                 = false   -- keep widget enabled when graphical user interface is hidden (when pressing F5)

local circleSize                        = 2.7
local circleDivs                        = 12      -- how precise circle? octagon by default
local circleOpacity                     = 0.5
local innerSize                         = 1.35    -- circle scale compared to unit radius
local outerSize                         = 1.5    -- outer fade size compared to circle scale (1 = no outer fade)
                                        
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

-- Automatically generated local definitions

local GL_ONE                  = GL.ONE
local GL_ONE_MINUS_SRC_ALPHA  = GL.ONE_MINUS_SRC_ALPHA
local GL_SRC_ALPHA            = GL.SRC_ALPHA
local glBlending              = gl.Blending
local glBeginEnd              = gl.BeginEnd
local glColor                 = gl.Color
local glCreateList            = gl.CreateList
local glDeleteList            = gl.DeleteList
local glDepthTest             = gl.DepthTest
local glDrawListAtUnit        = gl.DrawListAtUnit
local glPolygonOffset         = gl.PolygonOffset
local glVertex                = gl.Vertex
local spGetTeamColor          = Spring.GetTeamColor
local spGetUnitDefDimensions  = Spring.GetUnitDefDimensions
local spGetUnitDefID          = Spring.GetUnitDefID
local spIsUnitSelected        = Spring.IsUnitSelected
local spGetTeamList           = Spring.GetTeamList
local spGetVisibleUnits       = Spring.GetVisibleUnits
local spIsGUIHidden           = Spring.IsGUIHidden
local spGetUnitTeam           = Spring.GetUnitTeam
                              
local myTeamID                = Spring.GetLocalTeamID()

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local realRadii               = {}
local circlePolys             = {}

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------


-- Creating polygons:
function widget:Initialize()

   local teamList = spGetTeamList()
   local numberOfTeams = #teamList

   for teamListIndex = 1, #teamList do
      local teamID = teamList[teamListIndex]
      local r,g,b,a       = spGetTeamColor(teamID)

      circlePolys[teamID] = glCreateList(function()
        glBlending(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA)      -- disable layer blending
         
         -- colored inner circle:
         glBeginEnd(GL.TRIANGLES, function()
            local radstep = (2.0 * math.pi) / circleDivs
            for i = 1, circleDivs do
               local a1 = (i * radstep)
               local a2 = ((i+1) * radstep)
               --(fadefrom)
               glColor(r, g, b, 0)
               glVertex(0, 0, 0)
               --(colorSet)
               glColor(r, g, b, circleOpacity)
               glVertex(math.sin(a1), 0, math.cos(a1))
               glVertex(math.sin(a2), 0, math.cos(a2))
            end
         end)
         
         if (outerSize ~= 1) then
            -- colored outer circle:
            glBeginEnd(GL.QUADS, function()
               local radstep = (2.0 * math.pi) / circleDivs
               for i = 1, circleDivs do
                  local a1 = (i * radstep)
                  local a2 = ((i+1) * radstep)
                  --(colorSet)
                  glColor(r, g, b, circleOpacity)
                  glVertex(math.sin(a1), 0, math.cos(a1))
                  glVertex(math.sin(a2), 0, math.cos(a2))
                  --(fadeto)
                  glColor(r, g, b, 0)
                  glVertex(math.sin(a2)*outerSize, 0, math.cos(a2)*outerSize)
                  glVertex(math.sin(a1)*outerSize, 0, math.cos(a1)*outerSize)
               end
            end)
         end
      end)

   end

end

function widget:Shutdown()
   --glDeleteList(circlePolys)
end


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------


-- Retrieving radius:
local function GetUnitDefRealRadius(udid)
	local radius = realRadii[udid]
	if (radius) then return radius end
	local ud = UnitDefs[udid]
	if (ud == nil) then return nil end
	--local dims = spGetUnitDefDimensions(udid)
	--if (dims == nil) then return nil end
	--local scale = ud.hitSphereScale -- missing in 0.76b1+
	--scale = ((scale == nil) or (scale == 0.0)) and 1.0 or scale
	--radius = dims.radius / scale
	realRadii[udid] = circleSize*(ud.xsize^2 + ud.zsize^2)^0.5
	return realRadii[udid]
end


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------


-- Drawing:
function widget:DrawWorldPreUnit()
   if not drawWithHiddenGUI then
      if spIsGUIHidden() then return end
   end
   glDepthTest(false)
   glPolygonOffset(-100, -2)
   local visibleUnits = spGetVisibleUnits()
   if #visibleUnits then
      for i=1, #visibleUnits do
         local unitID = visibleUnits[i]
         local teamID = spGetUnitTeam(unitID)
         if circlePolys[teamID] ~= nil then
            local unitDefIDValue = spGetUnitDefID(unitID)
            if (unitDefIDValue) then
               local radius = GetUnitDefRealRadius(unitDefIDValue)
               if (radius) then
                  glDrawListAtUnit(unitID, circlePolys[teamID], false, radius, 1.0, radius)
               end
            end
         end
      end
   end
   glPolygonOffset(false)
end
             

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
