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
    date      = "Aug 05, 2007", --Feb 17, 2013
    license   = "GNU GPL, v2 or later",
    layer     = 0,
    enabled   = true,  --  loaded by default?
  }
end

--options for epicmenu:
options_path = 'Settings/Interface/Metal Feature Highlight'
options_order = {'autometalview',}
options={
	autometalview ={
		name = 'Auto Metalmap Toggling',
		desc = 'Automatically toggle metalmap view if you select RECLAIM command. This increase wreckage visibility',
		type = 'bool',
		value = false,
	},
}

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:DrawWorld()
  if (Spring.GetMapDrawMode() ~= 'metal') then
    return
  end

  gl.Fog(false)
  gl.DepthTest(true)
  gl.PolygonOffset(-2, -2)
  gl.Blending(GL.SRC_ALPHA, GL.ONE)

  local timer = widgetHandler:GetHourTimer()
  local alpha = 0.25 + (0.75 * math.abs(1 - (timer * 5) % 2))

  local myAllyTeam = Spring.GetMyAllyTeamID()

  local features = Spring.GetAllFeatures()
  for _, fID in ipairs(features) do
    local metal = Spring.GetFeatureResources(fID)
    if (metal and (metal > 0)) then
      local aTeam = Spring.GetFeatureAllyTeam(fID)
      if (aTeam ~= myAllyTeam) then
        local x100  = 100  / (100  + metal)
        local x1000 = 1000 / (1000 + metal)
        local r = 1 - x1000
        local g = x1000 - x100
        local b = x100
        
        gl.Color(r, g, b, alpha)
        
        gl.Feature(fID, true)
      end
    end
  end

  gl.Blending(GL.SRC_ALPHA, GL.ONE_MINUS_SRC_ALPHA)
  gl.PolygonOffset(false)
  gl.DepthTest(false)
  gl.Fog(true)
end

----The following code auto-change any map-view into metalview when ordering RECLAIM, then return them to original (by msafwan):---
local memPrevMapView = nil --remember any map-view prior to changes
local currCmd =  Spring.GetActiveCommand() --remember current command
function widget:Update()
	if not options.autometalview.value then --Options
		return
	end
	if currCmd == Spring.GetActiveCommand() then --if detect no change in command selection: --skip whole thing
		return
	end --else (command selection has change): perform check/automated-map-view-change
	currCmd = Spring.GetActiveCommand() --update active command
	if (not memPrevMapView) and (Spring.GetMapDrawMode() ~= 'metal') then --if not yet in metalview and not yet change to metalview: check for RECLAIM command
		local activeCmd = Spring.GetActiveCmdDesc(currCmd) 
		if activeCmd and activeCmd.name == "Reclaim" then --if current command is RECLAIM: remember present map-view & toggle metalview
			memPrevMapView = Spring.GetMapDrawMode()
			Spring.SendCommands("showmetalmap")
		end
	elseif memPrevMapView then --if have a memory of previous map-view: return to previous map-view
		if (Spring.GetMapDrawMode() == 'metal') then --if still in metalview: exit metal view
			if memPrevMapView == 'normal' then
				Spring.SendCommands("showstandard")
			elseif memPrevMapView == 'height' then
				Spring.SendCommands("showelevation")
			elseif memPrevMapView == 'pathTraversability' then
				Spring.SendCommands("showpathtraversability")
			elseif memPrevMapView == 'los' then
				Spring.SendCommands("togglelos")
			end
		end
		memPrevMapView = nil --forget about previous map-view
	end
end
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
