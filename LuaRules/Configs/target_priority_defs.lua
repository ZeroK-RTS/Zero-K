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
local unitIsGround = {}
local getMovetype = Spring.Utilities.getMovetype
for i=1, #UnitDefs do
	local ud = UnitDefs[i]
	local unitType = getMovetype(ud) --1 gunship, 0 fixedplane, 2 ground/sea, false everything-else
	if unitType == 1 then
		unitIsGunship[i] = true
	elseif unitType == 0 then
		unitIsFixedwing[i] = true
	else
		unitIsGround[i] = true
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
	[UnitDefNames["armflea"].id] = 4,
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

local unitIsRaider = {
	[UnitDefNames["armflea"].id] = true,
	[UnitDefNames["armpw"].id] = true,
	[UnitDefNames["corfav"].id] = true,
	[UnitDefNames["corgator"].id] = true,
	[UnitDefNames["corak"].id] = true,
	[UnitDefNames["puppy"].id] = true,
	[UnitDefNames["armkam"].id] = true,
	[UnitDefNames["corpyro"].id] = true,
	[UnitDefNames["logkoda"].id] = true,
	[UnitDefNames["panther"].id] = true,
	[UnitDefNames["fighter"].id] = true,
	[UnitDefNames["spherepole"].id] = true,
}

-- Don't shoot at fighters or drones, they are unimportant.
local unitIsFighterOrDrone = {
	[UnitDefNames["fighter"].id] = true,
	[UnitDefNames["corvamp"].id] = true,
	[UnitDefNames["attackdrone"].id] = true,
	[UnitDefNames["battledrone"].id] = true,
	[UnitDefNames["carrydrone"].id] = true,
}

-- swifts should prefer to target air over ground
local unitIsBadAgainstGround = {
	[UnitDefNames["fighter"].id] = true,
}

-- raider target primier
local unitIsMex = {
	[UnitDefNames["cormex"].id] = true,
}

-- universal bad target
local unitIsSolar = {
	[UnitDefNames["armsolar"].id] = true,
}

-- Prioritize bombers
local unitIsBomber = {
	[UnitDefNames["corshad"].id] = true,
	[UnitDefNames["corhurc2"].id] = true,
	[UnitDefNames["armcybr"].id] = true,
	[UnitDefNames["armstiletto_laser"].id] = true,
}

-- Hardcode that racketeer does disarm damage
local unitIsDisarmer = {
	[UnitDefNames["shieldarty"].id] = true,
}

-- Hardcode things which do high burst damage with a long cooldown
local unitIsHeavyHitter = {
	[UnitDefNames["armmanni"].id] = true,
	[UnitDefNames["armsnipe"].id] = true,
	[UnitDefNames["shieldarty"].id] = true,
}

local unitIsCheap = {
	[UnitDefNames["corrl"].id] = true,
	[UnitDefNames["corllt"].id] = true,
}

-- Hardcode things which should not fire at things too fast to hit
local unitIsBadAgainstFastStuff = {
	[UnitDefNames["correap"].id] = true,
	[UnitDefNames["armmanni"].id] = true,
	[UnitDefNames["armanni"].id] = true,
	[UnitDefNames["corstorm"].id] = true,
	[UnitDefNames["armham"].id] = true,
	[UnitDefNames["armsnipe"].id] = true,
	[UnitDefNames["armmerl"].id] = true,
	[UnitDefNames["shieldarty"].id] = true,
	[UnitDefNames["shiparty"].id] = true,
	[UnitDefNames["cormart"].id] = true,
	[UnitDefNames["trem"].id] = true,
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
	elseif unitIsRaider[i] then
		local weapons = ud.weapons
		for j = 1, #weapons do
			local wd = weapons[j]
			local realWD = wd.weaponDef
			weaponBadCats[realWD].raider = true -- technically used as a "good" category here.
		end
	elseif unitIsBadAgainstGround[i] then
		local weapons = ud.weapons
		for j = 1, #weapons do
			local wd = weapons[j]
			local realWD = wd.weaponDef
			weaponBadCats[realWD].ground = true
		end
	elseif unitIsDisarmer[i] then
		local weapons = ud.weapons
		for j = 1, #weapons do
			local wd = weapons[j]
			local realWD = wd.weaponDef
			weaponBadCats[realWD].unarmed = true
		end
	elseif unitIsHeavyHitter[i] then
		local weapons = ud.weapons
		for j = 1, #weapons do
			local wd = weapons[j]
			local realWD = wd.weaponDef
			weaponBadCats[realWD].cheap = true
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

-- Generate transport unit table
local transportMult = {}

for uid = 1, #UnitDefs do
	local ud = UnitDefs[uid]
	if ud.isTransport then
		transportMult[uid] = 0.98 -- Priority multiplier for transported unit.
	end
end

-- Generate full target table
local targetTable = {}

for uid = 1, #UnitDefs do
	targetTable[uid] = {}
	for wid = 1, #WeaponDefs do
		if unitIsUnarmed[uid] then
			if weaponBadCats[wid].unarmed or unitIsSolar[uid] then
				targetTable[uid][wid] = unitHealthRatio[uid] + 1000
			else
				targetTable[uid][wid] = unitHealthRatio[uid] + 35
			end
		elseif (unitIsFighterOrDrone[uid])
			or (weaponBadCats[wid].fastStuff and unitIsTooFastToHit[uid])
			or (weaponBadCats[wid].fixedwing and unitIsFixedwing[uid])
			or (weaponBadCats[wid].gunship and unitIsGunship[uid])
			or (weaponBadCats[wid].ground and unitIsGround[uid])
			or (weaponBadCats[wid].cheap and unitIsCheap[uid])then
				targetTable[uid][wid] = unitHealthRatio[uid] + 500
		elseif unitIsBomber[uid] and weaponIsAA[wid] then
			targetTable[uid][wid] = unitHealthRatio[uid]*0.3
		elseif (weaponBadCats[wid].raider and unitIsMex[uid]) then
			targetTable[uid][wid] = 1 -- mexes get max priority for raiders
		else
			targetTable[uid][wid] = unitHealthRatio[uid]
		end
	end
end

return targetTable, captureWeaponDefs, transportMult
