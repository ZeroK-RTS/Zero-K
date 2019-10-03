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
    name      = "MetalFeatures (old)",
    desc      = "Highlights features with reclaimable metal",
    author    = "trepan",
    date      = "Aug 05, 2007", --Apr 23, 2019
    license   = "GNU GPL, v2 or later",
    layer     = 0,
    enabled   = false,  --  loaded by default?
  }
end

--------------------------------------------------------------------------------
-- Speed Ups

local spGetMapDrawMode = Spring.GetMapDrawMode
local spGetActiveCommand = Spring.GetActiveCommand
local spGetActiveCmdDesc = Spring.GetActiveCmdDesc
local spGetGameFrame = Spring.GetGameFrame

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

options_path = 'Settings/Interface/Map/Reclaimables'
options_order = { 'showhighlight','pregamehighlight','intensity','minmetal'}
options = {
	showhighlight = {
		name = 'Show Reclaim',
		desc = "When to highlight reclaimable features",
		type = 'radioButton',
		value = 'constructors',
		items = {
			{key ='always', name='Always'},
			{key ='withecon', name='With the Economy Overlay'},
			{key ='constructors',  name='With Constructors Selected'},
			{key ='conorecon',  name='With Constructors or Overlay'},
			{key ='conandecon',  name='With Constructors and Overlay'},
			{key ='reclaiming',  name='When Reclaiming'},
		},
		noHotkey = true,
	},

	intensity = {
		name = 'Highlighted Reclaim Brightness',
		desc = "Increase or decrease visibility of effect",
		type = "number",
		value = 100,
		min = 20,
		max = 100,
		step = 20,
	},

	pregamehighlight = {
		name = "Show Reclaim Before Round Start",
		desc = "Enabled: Show reclaimable metal features before game begins \n Disabled: No highlights before game begins",
		type = 'bool',
		value = true,
		noHotkey = true,
	},

	minmetal = {
		name = 'Minimum Reclaim To Highlight',
		desc = "Metal below this amount will not be highlighted",
		type = "number",
		value = 1,
		min = 1,
		max = 200,
		step = 1,
	},
}

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local conSelected = false
local hilite = false
local pregame = true

local function DrawWorldFunc()

  pregame = (spGetGameFrame() < 1)

  if Spring.IsGUIHidden() then
    return false
  end

  -- Minimum Metal Setting should not interfere with reclaim and area reclaim
  if hilite then
    minMetalShown = 1
  else
    minMetalShown = options.minmetal.value
  end

  -- ways to bypass heavy resource load in economy overlay
  if (pregame and options.pregamehighlight.value) or hilite
    or (options.showhighlight.value == 'always')
    or (options.showhighlight.value == 'withecon' and WG.showeco)
    or (options.showhighlight.value == "constructors" and conSelected)
    or (options.showhighlight.value == 'conorecon' and (conSelected or WG.showeco))
    or (options.showhighlight.value == 'conandecon' and (conSelected and WG.showeco)) then

    gl.PolygonOffset(-2, -2)
    gl.Blending(GL.SRC_ALPHA, GL.ONE)
  
    local timer = widgetHandler:GetHourTimer()
    local intensity = options.intensity.value
    local alpha = (0.25*(intensity/100)) + (0.5 * (intensity/100) * math.abs(1 - (timer * 2) % 2))
  
    local myAllyTeam = Spring.GetMyAllyTeamID()
  
    local features = Spring.GetVisibleFeatures()
    for _, fID in pairs(features) do
      local metal = Spring.GetFeatureResources(fID)
      if (metal and (metal > minMetalShown)) then
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
  	
  end
end

function widget:DrawWorld()
  DrawWorldFunc()
end
function widget:DrawWorldRefraction()
  DrawWorldFunc()
end

function widget:SelectionChanged(units)
	if (WG.selectionEntirelyCons) then
		conSelected = true
	else
		conSelected = false
	end
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
