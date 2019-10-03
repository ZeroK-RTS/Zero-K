function widget:GetInfo()
  return {
    name      = "Persistent Build Spacing",
    desc      = "Recalls last build spacing set for each building and game [v2.0]",
    author    = "Niobium & DrHash",
    date      = "Sep 6, 2011",
    license   = "GNU GPL, v3 or later",
    layer     = 1,
    enabled   = true  --  loaded by default?
  }
end

options_order = {'text_hotkey', 'hotkey_inc', 'hotkey_dec', 'hotkey_facing_inc', 'hotkey_facing_dec'}
options_path = 'Hotkeys/Construction'
options = {
	text_hotkey = {
		name = 'Placement Modifiers',
		type = 'text',
		value = "Hotkeys for adjusting structure placement.",
	},
	hotkey_inc = {
		name = 'Increase Build Spacing',
		desc = 'Increase the spacing between structures queued in a line or rectangle. Hold Shift to queue a line of structures. Add Alt to queue a rectangle. Add Ctrl to queue a hollow rectangle.',
		type = 'button',
		action = "buildspacing inc",
		bindWithAny = true,
	},
	hotkey_dec = {
		name = 'Decrease Build Spacing',
		desc = 'Decrease the spacing between structures queued in a line or rectangle. Hold Shift to queue a line of structures. Add Alt to queue a rectangle. Add Ctrl to queue a hollow rectangle.',
		type = 'button',
		action = "buildspacing dec",
		bindWithAny = true,
	},
	hotkey_facing_inc = {
		name = 'Rotate Counterclockwise',
		desc = 'Rotate the structure placement blueprint counterclockwise.',
		type = 'button',
		action = "buildfacing inc",
		bindWithAny = true,
	},
	hotkey_facing_dec = {
		name = 'Rotate Clockwise',
		desc = 'Rotate the structure placement blueprint clockwise.',
		type = 'button',
		action = "buildfacing dec",
		bindWithAny = true,
	},
}

-- Config
local defaultSpacing = 4 -- Big makes for more navigable bases for new players.

-- Globals
local lastCmdID = nil
local buildSpacing = {}

-- Speedups
local spGetActiveCommand = Spring.GetActiveCommand
local spGetBuildSpacing = Spring.GetBuildSpacing
local spSetBuildSpacing = Spring.SetBuildSpacing

-- Callins
function widget:Update()
    
    local _, cmdID = spGetActiveCommand()
    if cmdID and cmdID < 0 then
        local unitDefID = -cmdID
        if cmdID ~= lastCmdID then
            spSetBuildSpacing(buildSpacing[unitDefID] or tonumber(UnitDefs[unitDefID].customParams.default_spacing) or defaultSpacing)
            lastCmdID = cmdID
        end
        
        buildSpacing[unitDefID] = spGetBuildSpacing()
    end
end

function widget:GetConfigData()
    local spacingByName = {}
	for unitDefID, spacing in pairs(buildSpacing) do
		local name = UnitDefs[unitDefID] and UnitDefs[unitDefID].name
		if name then
			spacingByName[name] = spacing
		end
	end
	return { buildSpacing = spacingByName }
end

function widget:SetConfigData(data)
    local spacingByName = data.buildSpacing or {}
	for name, spacing in pairs(spacingByName) do
		local unitDefID = UnitDefNames[name] and UnitDefNames[name].id
		if unitDefID then
			buildSpacing[unitDefID] = spacing
		end
	end
end
