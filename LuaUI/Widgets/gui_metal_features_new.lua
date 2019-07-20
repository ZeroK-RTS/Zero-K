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
    name      = "MetalFeatures (new)",
    desc      = "Highlights features with reclaimable metal. Slow due to DrawFeature() overhead",
    author    = "ivand",
    date      = "2019",
    license   = "GNU GPL, v2 or later",
    layer     = 0,
    enabled   = true,  --  loaded by default?
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
options_order = { 'showhighlight', 'pregamehighlight', 'minmetal'}
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

local enableCondOld = false
local minMetalShownOld = -1
local highlight = false
local conSelected = false
local currCmd = spGetActiveCommand() --remember current command
function widget:Update()
	if Spring.IsGUIHidden() then
		Spring.SendCommands("luarules metal_highlight 0")
		return
	end

	local activeCurrentCmd = spGetActiveCommand()
	if currCmd ~= activeCurrentCmd then
		currCmd = activeCurrentCmd --update active command
		local activeCmdDesc = spGetActiveCmdDesc(currCmd)
		highlight = (activeCmdDesc and (activeCmdDesc.name == "Reclaim" or activeCmdDesc.name == "Resurrect"))
	end

	-- Minimum Metal Setting should not interfere with reclaim and area reclaim
	local minMetalShownNew
	if highlight then
		minMetalShownNew = 1
	else
		minMetalShownNew = options.minmetal.value
	end

	local pregame = (spGetGameFrame() < 1)

-- ways to bypass heavy resource load in economy overlay
	local enableCondNew =
		(pregame and options.pregamehighlight.value) or highlight
		or (options.showhighlight.value == 'always')
		or (options.showhighlight.value == 'withecon' and WG.showeco)
		or (options.showhighlight.value == "constructors" and conSelected)
		or (options.showhighlight.value == 'conorecon' and (conSelected or WG.showeco))
		or (options.showhighlight.value == 'conandecon' and (conSelected and WG.showeco))

	if enableCondNew and minMetalShownOld ~= minMetalShownNew then
		minMetalShownOld = minMetalShownNew
		if Script.LuaRules.SetWreckMetalThreshold then
			Script.LuaRules.SetWreckMetalThreshold(minMetalShownNew)
		end
	end

	if enableCondNew ~= enableCondOld then
		enableCondOld = enableCondNew
		Spring.SendCommands("luarules metal_highlight " .. tostring((enableCondNew and 1) or 0))
	end
end

function widget:Initialize()
	Spring.SendCommands("luarules metal_highlight 0")
end

function widget:Shutdown()
	Spring.SendCommands("luarules metal_highlight 0")
end

function widget:SelectionChanged(units)
	if (WG.selectionEntirelyCons) then
		conSelected = true
	else
		conSelected = false
	end
end
