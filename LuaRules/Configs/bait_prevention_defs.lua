
local baitLevelDefaults = {}
local targetBaitLevelDefs = {}
local targetBaitLevelArmorDefs = {}
local targetCostDefs = {}

local baitLevelCosts = {
	10,
	90 - 0.1,
	240 - 0.1,
	420 - 0.1,
}

-- Bait level one stops nanobaiting to a cost of 60.
-- Higher bait levels try to kill their low-threshold targets before completion.
local nanoframeBaitLevelCosts = {
	50,
	60,
	110,
	240,
}

for unitDefID = 1, #UnitDefs do
	local ud = UnitDefs[unitDefID]
	local unitCost = ud.buildTime -- Use build time for chickens.
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
			if unitCost > (baitLevelCosts[i - 1] or 0) and unitCost <= baitLevelCosts[i] then
				targetBaitLevelDefs[unitDefID] = i
			end
		end
	end
end

return baitLevelDefaults, targetBaitLevelDefs, targetBaitLevelArmorDefs, targetCostDefs, nanoframeBaitLevelCosts
