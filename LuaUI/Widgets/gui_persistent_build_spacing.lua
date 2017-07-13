function widget:GetInfo()
  return {
    name      = "Persistent Build Spacing",
    desc      = "Recalls last build spacing set for each building and game [v2.0]",
    author    = "Niobium & DrHash",
    date      = "Sep 6, 2011",
    license   = "GNU GPL, v3 or later",
    layer     = 0,
    enabled   = true  --  loaded by default?
  }
end

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