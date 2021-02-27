
local baitLevelDefaults = {}
local targetBaitLevelDefs = {}
local targetBaitLevelArmorDefs = {}
local targetCostDefs = {}

local baitLevelCosts = {
	50,
	120,
	300,
	600,
}

for unitDefID = 1, #UnitDefs do
	local ud = UnitDefs[unitDefID]
	local unitCost = ud.buildTime
	targetCostDefs[unitDefID] = unitCost
	if ud.customParams.bait_level_default then
		baitLevelDefaults[unitDefID] = tonumber(ud.customParams.bait_level_default)
	end
	if ud.customParams.bait_level_target_armor then
		targetBaitLevelArmorDefs[unitDefID] = tonumber(ud.customParams.bait_level_target_armor)
	end
	if ud.customParams.bait_level_target then
		targetBaitLevelDefs[unitDefID] = tonumber(ud.customParams.bait_level_target)
	elseif unitCost < baitLevelCosts[#baitLevelCosts] then
		-- Should we start thinking about caching this via precomputation at some point?
		for i = 1, #baitLevelCosts do
			if unitCost >= (baitLevelCosts[i - 1] or 0) and unitCost < baitLevelCosts[i] then
				targetBaitLevelDefs[unitDefID] = i
			end
		end
	end
end

return baitLevelDefaults, targetBaitLevelDefs, targetBaitLevelArmorDefs, targetCostDefs, baitLevelCosts
