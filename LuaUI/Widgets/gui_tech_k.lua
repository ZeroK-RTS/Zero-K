
local modoption = Spring.GetModOptions().techk
if not (modoption == "1") then
	return
end

function widget:GetInfo()
	return {
		name      = "Tech-K Helper",
		desc      = "Adds UI element support for Tech-K.",
		author    = "GoogleFrog",
		date      = "26 September, 2024",
		license   = "GNU GPL, v2 or later",
		layer     = 0,
		enabled   = true --  loaded by default?
	}
end

WG.SelectedTechLevel = 1

local isTechBuilder = {}
local function IsTechBuilder(unitDefID)
	if not isTechBuilder[unitDefID] then
		local ud = UnitDefs[unitDefID]
		isTechBuilder[unitDefID] = (ud.canRepair or ud.isFactory) and 1 or 0
	end
	return isTechBuilder[unitDefID] == 1
end

function widget:SelectionChanged(selection, subselection)
	if subselection then
		return
	end
	local maxLevel = 1
	for i = 1, #selection do
		local unitID = selection[i]
		if Spring.ValidUnitID(unitID) then
			local unitDefID = Spring.GetUnitDefID(unitID)
			if unitDefID and IsTechBuilder(unitDefID) then
				local level = Spring.GetUnitRulesParam(unitID, "tech_level")
				if level and level > maxLevel then
					maxLevel = level
				end
			end
		end
	end
	WG.SelectedTechLevel = maxLevel
end
