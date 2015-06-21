-- Assuming max HP/Cost is 50.
-- Max useful HP/Cost is 11, Only Dirtbag and Claw are higher at 32.5 and 40 respectively.

local weaponBadCats = {}
local weaponIsAA = {}

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
		if wd.customParams and realWD ~= 0 and wd.customParams.isaa then
			weaponIsAA[realWD] = true
		end
	end
end

-- Find the things which are fixedwing or gunship
local unitIsGunship = {}
local unitIsFixedwing = {}
local getMovetype = Spring.Utilities.getMovetype
for i=1, #UnitDefs do
	local ud = UnitDefs[i]
	local unitType = getMovetype(ud) --1 gunship, 0 fixedplane, 2 ground/sea, false everything-else
	if unitType == 1 then
		unitIsGunship[i] = true
	elseif unitType == 0 then
		unitIsFixedwing[i] = true
	end
end

-- Find the things which are unarmed
local unitIsUnarmed = {}
for i=1, #UnitDefs do
	local ud = UnitDefs[i]
	local weapons = ud.weapons
	if (not weapons or #weapons == 0) and not ud.canKamikaze then
		unitIsUnarmed[i] = true
	end
end

local unitHealthRatioOverride = {
	[UnitDefNames["corfav"].id] = 4,
}

-- Pregenerate HP ratio
local unitHealthRatio = {}
for i=1, #UnitDefs do
	local ud = UnitDefs[i]
	unitHealthRatio[i] = unitHealthRatioOverride[i] or ud.health/ud.buildTime
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

-- Don't shoot at fighters or drones, they are unimportant.
local unitIsFighterOrDrone = {
	[UnitDefNames["fighter"].id] = true,
	[UnitDefNames["corvamp"].id] = true,
	[UnitDefNames["attackdrone"].id] = true,
	[UnitDefNames["battledrone"].id] = true,
	[UnitDefNames["carrydrone"].id] = true,
}

-- Prioritize bombers
local unitIsBomber = {
	[UnitDefNames["corshad"].id] = true,
	[UnitDefNames["corhurc2"].id] = true,
	[UnitDefNames["armcybr"].id] = true,
	[UnitDefNames["armstiletto_laser"].id] = true,
}

-- Hardcode things which should not fire at things too fast to hit
local unitIsBadAgainstFastStuff = {
	[UnitDefNames["correap"].id] = true,
	[UnitDefNames["armmanni"].id] = true,
	[UnitDefNames["armanni"].id] = true,
	[UnitDefNames["corstorm"].id] = true,
}

local captureWeaponDefs = {
	[WeaponDefNames["capturecar_captureray"].id] = true
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
-- Check to output expected priority values.
local baseUnitPriority = {}
for i=1, #UnitDefs do
	local ud = UnitDefs[i]
	baseUnitPriority[i] = {
		priority = unitHealthRatioOverride[i] or ud.health/ud.buildTime,
		name = ud.name,
	}
end

table.sort(baseUnitPriority, function(a,b) return (a.priority > b.priority) end)
for i=1, #baseUnitPriority do
	Spring.Echo(baseUnitPriority[i].name .. " = " .. baseUnitPriority[i].priority .. ",")
end
--]]

-- Generate full target table
local targetTable = {}

for uid = 1, #UnitDefs do
	targetTable[uid] = {}
	for wid = 1, #WeaponDefs do
		if unitIsUnarmed[uid] then
			targetTable[uid][wid] = unitHealthRatio[uid] + 35
		elseif (unitIsFighterOrDrone[uid]) or
			(weaponBadCats[wid].fastStuff and unitIsTooFastToHit[uid]) or
			(weaponBadCats[wid].fixedwing and unitIsFixedwing[uid]) or
			(weaponBadCats[wid].gunship and unitIsGunship[uid]) then
			
			targetTable[uid][wid] = unitHealthRatio[uid] + 15
		elseif unitIsBomber[uid] and weaponIsAA[wid] then
			targetTable[uid][wid] = unitHealthRatio[uid]*0.3
		else
			targetTable[uid][wid] = unitHealthRatio[uid]
		end
	end
end

return targetTable, captureWeaponDefs
