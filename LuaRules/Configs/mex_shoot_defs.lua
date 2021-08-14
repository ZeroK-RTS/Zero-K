local defs = {
	{
		name = "cloakriot",
		fireHeight = 0,
	},
	{
		name = "vehriot",
		searchRange = 180,
	},
	{
		name = "hoverdepthcharge",
		ignoreHeight = true,
		searchRange = 180,
	},
	{
		name = "amphimpulse",
		searchRange = 80,
	},
	{
		name = "jumpraid",
		ignoreHeight = true,
	},
	{
		name = "tankraid",
		fireHeight = 0,
	},
	{
		name = "tankriot",
		lowerHeight = -60,
		upperHeight = 200,
		searchRange = 180,
	},
	{
		name = "spidercrabe",
		lowerHeight = -80,
		upperHeight = 160,
		searchRange = 250,
	},
}

local realDefs = {}
for i = 1, #defs do
	local unitData = defs[i]
	local ud = UnitDefNames[unitData.name]
	
	local weaponRange
	if unitData.weaponNum and ud.weapons[unitData.weaponNum] then
		local weaponDefID = ud.weapons[unitData.weaponNum].weaponDef
		weaponRange = WeaponDefs[weaponDefID].range
	else
		weaponRange = ud.maxWeaponRange
	end
	
	unitData.searchRange = weaponRange + 60
	unitData.weaponRange = weaponRange
	unitData.fireHeight = unitData.fireHeight or 5
	unitData.lowerHeight = unitData.lowerHeight or -25
	unitData.upperHeight = unitData.upperHeight or 35
	
	realDefs[ud.id] = unitData
end

return realDefs
