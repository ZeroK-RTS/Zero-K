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
	[UnitDefNames["spiderscout"].id] = 4,
}

-- Pregenerate HP ratio
local unitHealthRatio = {}
for i=1, #UnitDefs do
	local ud = UnitDefs[i]
	unitHealthRatio[i] = unitHealthRatioOverride[i] or ud.health/ud.buildTime
end

-- Don't shoot at fighters or drones, they are unimportant.
local unitIsFighterOrDrone = {
	[UnitDefNames["fighter"].id] = true,
	[UnitDefNames["corvamp"].id] = true,
	[UnitDefNames["dronelight"].id] = true,
	[UnitDefNames["droneheavyslow"].id] = true,
	[UnitDefNames["dronecarry"].id] = true,
}

--Wolverine mines are stupid targets.
local unitIsClaw = {
	[UnitDefNames["wolverine_mine"].id] = true,
}

-- swifts should prefer to target air over ground
local unitIsBadAgainstGround = {
	[UnitDefNames["fighter"].id] = true,
}

-- Prioritize bombers
local unitIsBomber = {
	[UnitDefNames["corshad"].id] = true,
	[UnitDefNames["corhurc2"].id] = true,
	[UnitDefNames["bomberheavy"].id] = true,
	[UnitDefNames["bomberdisarm"].id] = true,
}

-- Hardcode things which do high burst damage with a long cooldown
local unitIsHeavyHitter = {
	[UnitDefNames["turretantiheavy"].id] = true,
	[UnitDefNames["hoverarty"].id] = true,
	[UnitDefNames["cloaksnipe"].id] = true,
	[UnitDefNames["shieldarty"].id] = true,
	[UnitDefNames["nsaclash"].id] = true,
	[UnitDefNames["bantha"].id] = true,
	[UnitDefNames["bomberheavy"].id] = true,
}

local unitIsCheap = {
	[UnitDefNames["corrl"].id] = true,
	[UnitDefNames["corllt"].id] = true,
	[UnitDefNames["spiderscout"].id] = true,
	[UnitDefNames["cloakraid"].id] = true,
	[UnitDefNames["corfav"].id] = true,
	[UnitDefNames["corgator"].id] = true,
	[UnitDefNames["corsh"].id] = true,
	[UnitDefNames["corak"].id] = true,
	[UnitDefNames["puppy"].id] = true,
}

local unitIsHeavy = {
	[UnitDefNames["shieldfelon"].id] = true,
	[UnitDefNames["correap"].id] = true,
	[UnitDefNames["hoverarty"].id] = true,
	[UnitDefNames["cloaksnipe"].id] = true,
	[UnitDefNames["corgol"].id] = true,
	[UnitDefNames["tawf114"].id] = true,
	[UnitDefNames["amphassault"].id] = true,
	[UnitDefNames["spidercrabe"].id] = true,
	[UnitDefNames["corcrw"].id] = true,
	[UnitDefNames["corsumo"].id] = true,
	[UnitDefNames["dante"].id] = true,
	[UnitDefNames["scorpion"].id] = true,
	[UnitDefNames["funnelweb"].id] = true,
	[UnitDefNames["striderarty"].id] = true,
	[UnitDefNames["bantha"].id] = true,
	[UnitDefNames["detriment"].id] = true,
}

-- Hardcode weapons that are bad against fast moving stuff.
-- [weapondefid] = {Threshold for penalty to apply, base penalty, additional penantly per excess velocity}
local VEL_DEFAULT_BASE = 1
local VEL_DEFAULT_SCALE = 8

local velocityPenaltyDefs = {
	[WeaponDefNames["corthud_thud_weapon"].id]       = {2.5},
	[WeaponDefNames["corstorm_storm_rocket"].id]     = {2.0},
	[WeaponDefNames["corcrash_armkbot_missile"].id]  = {16.0},
	[WeaponDefNames["cloakskirm_bot_rocket"].id]        = {2.5},
	[WeaponDefNames["cloakarty_hammer_weapon"].id]      = {1.5},
	[WeaponDefNames["cloaksnipe_shockrifle"].id]       = {2.5},
	[WeaponDefNames["cormist_cortruck_missile"].id]  = {11.0},
	[WeaponDefNames["corraid_plasma"].id]            = {2.5},
	[WeaponDefNames["vehheavyarty_cortruck_rocket"].id]   = {0.5},
	[WeaponDefNames["vehaa_missile"].id]             = {14.0},
	[WeaponDefNames["gunshipheavyskirm_emg"].id]              = {3.0},
	[WeaponDefNames["gunshipaa_aa_missile"].id]      = {14.0},
	[WeaponDefNames["nsaclash_missile"].id]          = {4.5},
	[WeaponDefNames["hoverassault_dew"].id]          = {2.5},
	[WeaponDefNames["amphraider3_torpmissile"].id]   = {4.5},
	[WeaponDefNames["amphfloater_cannon"].id]        = {2.5},
	[WeaponDefNames["amphaa_missile"].id]            = {14.0},
	[WeaponDefNames["spiderassault_thud_weapon"].id] = {2.5},
	[WeaponDefNames["spiderskirm_adv_rocket"].id]        = {2.5},
	[WeaponDefNames["spidercrabe_arm_crabe_gauss"].id]  = {2.5},
	[WeaponDefNames["spideraa_aa"].id]               = {11.0},
	[WeaponDefNames["puppy_missile"].id]             = {8.0},
	[WeaponDefNames["correap_cor_reap"].id]          = {2.5},
	[WeaponDefNames["corgol_cor_gol"].id]            = {2.0},
	[WeaponDefNames["cormart_core_artillery"].id]    = {1.5},
	[WeaponDefNames["trem_plasma"].id]               = {0.5},
	[WeaponDefNames["striderantiheavy_disintegrator"].id]  = {2.8},
	[WeaponDefNames["dante_napalm_rockets"].id]      = {2.8},
	[WeaponDefNames["striderarty_rocket"].id]           = {0.5},
--	[WeaponDefNames["shipcarrier_armmship_rocket"].id]      = {0.5},
	[WeaponDefNames["shipheavyarty_plasma"].id]      = {2.5},
	[WeaponDefNames["shipskirm_rocket"].id]          = {2.8},
	[WeaponDefNames["shiparty_plasma"].id]           = {2.0},
	[WeaponDefNames["corrl_armrl_missile"].id]       = {14.0},
	[WeaponDefNames["turretriot_turretriot_weapon"].id]    = {5.0},
	[WeaponDefNames["corrazor_aagun"].id]            = {7.0, 0, 3},
	[WeaponDefNames["missiletower_missile"].id]      = {16.0},
	[WeaponDefNames["turretaafar_missile"].id]            = {14.0},
	[WeaponDefNames["staticarty_plasma"].id]           = {2.5},
	[WeaponDefNames["staticheavyarty_plasma"].id]           = {2.0},
}

local stunWeaponDefs = {
	[WeaponDefNames["shieldarty_emp_rocket"].id] = true,
	[WeaponDefNames["shipscout_missile"].id] = true,
	--[WeaponDefNames["turretemp_arm_det_weapon"].id] = true,
	--[WeaponDefNames["arm_venom_spider"].id] = true,
}

local captureWeaponDefs = {
	[WeaponDefNames["vehcapture_captureray"].id] = true
}

local gravityWeaponDefs = {
	[WeaponDefNames["corgrav_gravity_neg"].id] = true,
	[WeaponDefNames["corgrav_gravity_pos"].id] = true,
	[WeaponDefNames["corsumo_gravity_neg"].id] = true,
	[WeaponDefNames["corsumo_gravity_pos"].id] = true,
}

-- for heatrays
local proximityWeaponDefs = {}
for wdid = 1, #WeaponDefs do
	if WeaponDefs[wdid].customParams.dyndamageexp then
		proximityWeaponDefs[wdid] = true
	end
end

local radarWobblePenalty = {
	[WeaponDefNames["vehheavyarty_cortruck_rocket"].id] = 5,
--	[WeaponDefNames["shipcarrier_armmship_rocket"].id] = 5,
	[WeaponDefNames["cloaksnipe_shockrifle"].id] = 5,
	[WeaponDefNames["turretantiheavy_ata"].id] = 5,
	[WeaponDefNames["hoverarty_ata"].id] = 5,
	[WeaponDefNames["cloakarty_hammer_weapon"].id] = 5,
}

for i = 1, #UnitDefs do
	local ud = UnitDefs[i]
	if unitIsBadAgainstGround[i] then
		local weapons = ud.weapons
		for j = 1, #weapons do
			local wd = weapons[j]
			local realWD = wd.weaponDef
			weaponBadCats[realWD].ground = true
		end
	elseif unitIsHeavyHitter[i] then
		local weapons = ud.weapons
		for j = 1, #weapons do
			local wd = weapons[j]
			local realWD = wd.weaponDef
			weaponBadCats[realWD].cheap = true
			weaponBadCats[realWD].heavy = true
		end
	end
end

-- Uncomment to output expected base priority values.
--[[
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
			targetTable[uid][wid] = unitHealthRatio[uid] + 35
		elseif unitIsClaw[uid] then
			targetTable[uid][wid] = unitHealthRatio[uid] + 1000
		elseif (unitIsFighterOrDrone[uid])
			or (weaponBadCats[wid].fixedwing and unitIsFixedwing[uid])
			or (weaponBadCats[wid].gunship and unitIsGunship[uid])
			or (weaponBadCats[wid].ground and unitIsGround[uid])
			or (weaponBadCats[wid].cheap and unitIsCheap[uid])then
				targetTable[uid][wid] = unitHealthRatio[uid] + 15
		elseif (unitIsBomber[uid] and weaponIsAA[wid])
			or (weaponBadCats[wid].heavy and unitIsHeavy[uid]) then
			targetTable[uid][wid] = unitHealthRatio[uid]*0.3
		else
			targetTable[uid][wid] = unitHealthRatio[uid]
		end
		
		-- Autogenerate some wobble penalties.
		if not radarWobblePenalty[wid] then
			local wd = WeaponDefs[wid]
			local weaponType = wd.type
			if weaponType == "BeamLaser" or weaponType == "LaserCannon" or weaponType == "LightningCannon" then
				radarWobblePenalty[wid] = 5
			end
		end
	end
end

-- Modify the velocity penalty defs to implement 'additional penantly per excess velocity'
for weaponDefID, data in pairs(velocityPenaltyDefs) do
	data[2] = data[2] or VEL_DEFAULT_BASE
	data[3] = data[3] or VEL_DEFAULT_SCALE
	
	data[2] = data[2] - data[1]*data[3]
end

return targetTable, stunWeaponDefs, captureWeaponDefs, gravityWeaponDefs, proximityWeaponDefs, velocityPenaltyDefs, radarWobblePenalty, transportMult
