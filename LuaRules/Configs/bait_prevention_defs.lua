
local baitLevelDefaults = {
	[UnitDefNames["hoverarty"].id] = 1,
	[UnitDefNames["cloaksnipe"].id] = 1,
	[UnitDefNames["turretheavylaser"].id] = 1,
	[UnitDefNames["turretantiheavy"].id] = 1,
	[UnitDefNames["striderarty"].id] = 1,
	[UnitDefNames["bomberheavy"].id] = 1,
	[UnitDefNames["bomberprec"].id] = 1,
	[UnitDefNames["gunshipassault"].id] = 1,
	[UnitDefNames["staticheavyarty"].id] = 1,
	[UnitDefNames["turretaaheavy"].id] = 1,
	[UnitDefNames["starlight_satellite"].id] = 1,
	[UnitDefNames["raveparty"].id] = 1,
	[UnitDefNames["hoverskirm"].id] = 1,
	[UnitDefNames["shieldskirm"].id] = 1,
	[UnitDefNames["shipheavyarty"].id] = 1,
	[UnitDefNames["shiparty"].id] = 1,
	[UnitDefNames["vehcapture"].id] = 1,
	[UnitDefNames["jumpskirm"].id] = 1,
}

local targetBaitLevelDefs = {}
local targetBaitLevelArmorDefs = {}

local baitLevelCosts = {
	40,
	100,
	300,
	600,
}

for unitDefID = 1, #UnitDefs do
	local ud = UnitDefs[unitDefID]
	local unitCost = ud.buildTime
	if ud.customParams.bait_level_armor then
		targetBaitLevelArmorDefs[unitDefID] = tonumber(ud.customParams.bait_level_armor)
	end
	if ud.customParams.bait_level then
		targetBaitLevelDefs[unitDefID] = tonumber(ud.customParams.bait_level)
	elseif unitCost < baitLevelCosts[#baitLevelCosts] then
		-- Should we start thinking about caching this via precomputation at some point?
		for i = 1, #baitLevelCosts do
			if unitCost >= (baitLevelCosts[i - 1] or 0) and unitCost < baitLevelCosts[i] then
				targetBaitLevelDefs[unitDefID] = i
			end
		end
	end
end

return baitLevelDefaults, targetBaitLevelDefs, targetBaitLevelArmorDefs
