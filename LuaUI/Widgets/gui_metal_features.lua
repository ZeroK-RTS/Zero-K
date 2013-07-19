-- $Id: gui_metal_features.lua 3171 2008-11-06 09:06:29Z det $
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
--  file:    gui_metal_features.lua
--  brief:   highlights features with metal in metal-map viewmode
--  author:  Dave Rodgers
--
--  Copyright (C) 2007.
--  Licensed under the terms of the GNU GPL, v2 or later.
--
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
  return {
    name      = "MetalFeatures",
    desc      = "Highlights features with metal in the metal-map viewmode",
    author    = "trepan",
    date      = "Aug 05, 2007", --May 6, 2013
    license   = "GNU GPL, v2 or later",
    layer     = 0,
    enabled   = true,  --  loaded by default?
  }
end


local spGetMapDrawMode = Spring.GetMapDrawMode
local spGetActiveCommand = Spring.GetActiveCommand
local spGetActiveCmdDesc = Spring.GetActiveCmdDesc

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
local hilite = false
local showecoMode = WG.showeco

function widget:DrawWorld()
  if (not hilite) and (spGetMapDrawMode() ~= 'metal') and (not showecoMode) then
    return
  end

  gl.Fog(false)
  gl.DepthTest(true)
  gl.PolygonOffset(-2, -2)
  gl.Blending(GL.SRC_ALPHA, GL.ONE)

  local timer = widgetHandler:GetHourTimer()
  local alpha = 0.25 + (0.75 * math.abs(1 - (timer * 5) % 2))

  local myAllyTeam = Spring.GetMyAllyTeamID()

  local features = Spring.GetVisibleFeatures()
  for _, fID in pairs(features) do
    local metal = Spring.GetFeatureResources(fID)
    if (metal and (metal > 0)) then
      -- local aTeam = Spring.GetFeatureAllyTeam(fID)
      -- if (aTeam ~= myAllyTeam) then
        local x100  = 100  / (100  + metal)
        local x1000 = 1000 / (1000 + metal)
        local r = 1 - x1000
        local g = x1000 - x100
        local b = x100
        
        gl.Color(r, g, b, alpha)
        
        gl.Feature(fID, true)
      -- end
    end
  end

  gl.Blending(GL.SRC_ALPHA, GL.ONE_MINUS_SRC_ALPHA)
  gl.PolygonOffset(false)
  gl.DepthTest(false)
  gl.Fog(true)
end



local currCmd =  spGetActiveCommand() --remember current command
function widget:Update()
	if currCmd == spGetActiveCommand() then --if detect no change in command selection: --skip whole thing
		return
	end --else (command selection has change): perform check/automated-map-view-change
	currCmd = spGetActiveCommand() --update active command
	local activeCmd = spGetActiveCmdDesc(currCmd)
	hilite = (activeCmd and (activeCmd.name == "Reclaim" or activeCmd.name == "Resurrect"))
end