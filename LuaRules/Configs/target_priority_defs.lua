-- Assuming max HP/Cost is 50.
-- Max useful HP/Cost is 11, Only Dirtbag and Claw are higher at 32.5 and 40 respectively.

local weaponBadCats = {}

for wid = 1, #WeaponDefs do
	weaponBadCats[wid] = {}
end

-- Find the weapon bad target cats
for i=1, #UnitDefs do
	local ud = UnitDefs[i]
	local weapons = ud.weapons
	for j = 1, #weapons do
		local wd = weapons[j]
		local realWD = wd.weaponDef
		if wd.badTargets and realWD ~= 0 then
			weaponBadCats[realWD].fixedwing = wd.badTargets["fixedwing"]
			weaponBadCats[realWD].gunship = wd.badTargets["gunship"]
		end
	end
end

-- Find the things which are fixedwing or gunship
local unitIsGunship = {}
local unitIsFixedwing = {}

for i=1, #UnitDefs do
	local ud = UnitDefs[i]
	if ud.canFly then
		if (ud.isFighter or ud.isBomber) then
			unitIsFixedwing[i] = true
		else
			unitIsGunship[i] = true
		end
	end
end

-- Find the things which are unarmed
local unitIsUnarmed = {}
for i=1, #UnitDefs do
	local ud = UnitDefs[i]
	local weapons = ud.weapons
	if not weapons or #weapons == 0 then
		unitIsUnarmed[i] = true
	end
end

-- Pregenerate HP ratio
local unitHealthRatio = {}
for i=1, #UnitDefs do
	local ud = UnitDefs[i]
	unitHealthRatio[i] = ud.health/ud.buildTime
end

-- Harcode the things which are too fast to hit
local unitIsTooFastToHit = {
	[UnitDefNames["armflea"].id] = true,
	[UnitDefNames["armpw"].id] = true,
	[UnitDefNames["corfav"].id] = true,
	[UnitDefNames["corgator"].id] = true,
	[UnitDefNames["corak"].id] = true,
	[UnitDefNames["armtick"].id] = true,
	[UnitDefNames["puppy"].id] = true,
	[UnitDefNames["corroach"].id] = true,
}

-- Hardcode things which should not fire at things too fast to hit
local unitIsBadAgainstFastStuff = {
	[UnitDefNames["correap"].id] = true,
	[UnitDefNames["armmanni"].id] = true,
	[UnitDefNames["armanni"].id] = true,
	[UnitDefNames["corstorm"].id] = true,
}

for i=1, #UnitDefs do
	local ud = UnitDefs[i]
	if unitIsBadAgainstFastStuff[i] then
		local weapons = ud.weapons
		for j = 1, #weapons do
			local wd = weapons[j]
			local realWD = wd.weaponDef
			weaponBadCats[realWD].fastStuff = true
		end
	end
end

--[[
-- Sorting here makes the gadget fail, it is just good for looking at the priorities
table.sort(baseUnitPriority, function(a,b) return (a.priority > b.priority) end)
for i=1, #baseUnitPriority do
	Spring.Echo(" UnitDefNames[\"" .. baseUnitPriority[i].name .. "\"] = " .. baseUnitPriority[i].priority .. ",")
end
--]]


-- Generate full target table
local targetTable = {}

for uid = 1, #UnitDefs do
	targetTable[uid] = {}
	for wid = 1, #WeaponDefs do
		if (weaponBadCats[wid].fastStuff and unitIsTooFastToHit[uid]) or
			(weaponBadCats[wid].fixedwing and unitIsFixedwing[uid]) or
			(weaponBadCats[wid].gunship and unitIsGunship[uid]) or
			unitIsUnarmed[uid] then
			
			targetTable[uid][wid] = unitHealthRatio[uid] + 15
		else
			targetTable[uid][wid] = unitHealthRatio[uid]
		end
	end
end

return targetTable

