-- Assuming max HP/Cost is 50.
-- Max useful HP/Cost is 11, Only Dirtbag and Claw are higher at 32.5 and 40 respectively.

local DISARM_BASE = 0.3
local DISARM_ADD = 0.2
local DISARM_ADD_TIME = 10*30 -- frames

local weaponBadCats_fixedwing = {}
local weaponBadCats_gunship = {}
local weaponBadCats_ground = {}
local weaponBadCats_heavy = {}
local weaponIsAA = {}

local wdCount = #WeaponDefs
local udCount = #UnitDefs

--local lastTime = Spring.GetTimer()
--local function Time(name)
--	local timeDiff = Spring.DiffTimers(Spring.GetTimer(), lastTime)
--	Spring.Echo(name, timeDiff)
--	lastTime = Spring.GetTimer()
--end

--Time("START TARGET PRIORITY DEFS")

-- Find the weapon bad target cats
for i = 1, udCount do
	local ud = UnitDefs[i]
	local weapons = ud.weapons
	for j = 1, #weapons do
		local wd = weapons[j]
		local realWD = wd.weaponDef
		if wd.badTargets and realWD ~= 0 then
			weaponBadCats_fixedwing[realWD] = wd.badTargets["fixedwing"]
			weaponBadCats_gunship[realWD] = wd.badTargets["gunship"]
		end
		if wd.customParams and realWD ~= 0 and wd.customParams.isaa then
			weaponIsAA[realWD] = true
		end
	end
end

--Time("Find bad target cats")

-- Find the things which are fixedwing or gunship
local unitIsGunship = {}
local unitIsFixedwing = {}
local unitIsGround = {}
local getMovetype = Spring.Utilities.getMovetype
for i = 1, udCount do
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

--Time("Find fixedwing or gunship")

-- Find the things which are unarmed
local unitIsUnarmed = {}
for i = 1, udCount do
	local ud = UnitDefs[i]
	local weapons = ud.weapons
	if (not weapons or #weapons == 0) and not ud.canKamikaze then
		unitIsUnarmed[i] = true
	end
end

--Time("Find unitIsUnarmed")

-- Don't shoot at fighters or drones, they are unimportant.
local unitIsFighterOrDrone = {
	[UnitDefNames["planefighter"].id] = true,
	[UnitDefNames["planeheavyfighter"].id] = true,
	[UnitDefNames["dronelight"].id] = true,
	[UnitDefNames["droneheavyslow"].id] = true,
	[UnitDefNames["dronecarry"].id] = true,
}

--Badger mines are stupid targets.
local unitIsClaw = {
	[UnitDefNames["wolverine_mine"].id] = true,
}

-- swifts should prefer to target air over ground
local unitIsBadAgainstGround = {
	[UnitDefNames["planefighter"].id] = true,
}

-- Prioritize bombers
local unitIsBomber = {
	[UnitDefNames["bomberprec"].id] = true,
	[UnitDefNames["bomberriot"].id] = true,
	[UnitDefNames["bomberheavy"].id] = true,
	[UnitDefNames["bomberdisarm"].id] = true,
	[UnitDefNames["bomberstrike"].id] = true,
}

-- Hardcode things which do high burst damage with a long cooldown
local unitIsHeavyHitter = {
	[UnitDefNames["turretantiheavy"].id] = true,
	[UnitDefNames["hoverarty"].id] = true,
	[UnitDefNames["cloaksnipe"].id] = true,
	[UnitDefNames["shieldarty"].id] = true,
	[UnitDefNames["hoverskirm"].id] = true,
	[UnitDefNames["striderbantha"].id] = true,
	[UnitDefNames["bomberheavy"].id] = true,
}

local unitIsCheap = {
	[UnitDefNames["turretmissile"].id] = true,
	[UnitDefNames["turretlaser"].id] = true,
	[UnitDefNames["spiderscout"].id] = true,
	[UnitDefNames["cloakraid"].id] = true,
	[UnitDefNames["vehscout"].id] = true,
	[UnitDefNames["vehraid"].id] = true,
	[UnitDefNames["hoverraid"].id] = true,
	[UnitDefNames["shieldraid"].id] = true,
	[UnitDefNames["jumpscout"].id] = true,
}

local unitIsHeavy = {
	[UnitDefNames["shieldfelon"].id] = true,
	[UnitDefNames["tankassault"].id] = true,
	[UnitDefNames["hoverarty"].id] = true,
	[UnitDefNames["cloaksnipe"].id] = true,
	[UnitDefNames["tankheavyassault"].id] = true,
	[UnitDefNames["tankriot"].id] = true,
	[UnitDefNames["amphassault"].id] = true,
	[UnitDefNames["spidercrabe"].id] = true,
	[UnitDefNames["gunshipkrow"].id] = true,
	[UnitDefNames["jumpsumo"].id] = true,
	[UnitDefNames["striderdante"].id] = true,
	[UnitDefNames["striderscorpion"].id] = true,
	[UnitDefNames["striderfunnelweb"].id] = true,
	[UnitDefNames["striderarty"].id] = true,
	[UnitDefNames["striderbantha"].id] = true,
	[UnitDefNames["striderdetriment"].id] = true,
}

local unitPriorityModifier = {
	[UnitDefNames["gunshipemp"].id] = -0.8,
	[UnitDefNames["striderantiheavy"].id] = -0.8,
}

-- Hardcode weapons that are bad against fast moving stuff.
-- [weapondefid] = {Threshold for penalty to apply, base penalty, additional penantly per excess velocity}
local VEL_DEFAULT_BASE = 1
local VEL_DEFAULT_SCALE = 5

local velocityPenaltyDefs = {
	[WeaponDefNames["shieldassault_thud_weapon"].id]      = {2.5},
	[WeaponDefNames["shieldskirm_storm_rocket"].id]       = {2.0},
	[WeaponDefNames["shieldaa_armkbot_missile"].id]       = {16.0},
	[WeaponDefNames["cloakskirm_bot_rocket"].id]          = {2.5},
	[WeaponDefNames["cloakarty_hammer_weapon"].id]        = {1.5},
	[WeaponDefNames["cloaksnipe_shockrifle"].id]          = {2.5},
	[WeaponDefNames["vehsupport_cortruck_missile"].id]    = {11.0},
	[WeaponDefNames["vehassault_plasma"].id]              = {2.5},
	[WeaponDefNames["vehheavyarty_cortruck_rocket"].id]   = {0.5},
	[WeaponDefNames["vehaa_missile"].id]                  = {14.0},
	[WeaponDefNames["gunshipheavyskirm_emg"].id]          = {3.0},
	[WeaponDefNames["gunshipaa_aa_missile"].id]           = {14.0},
	[WeaponDefNames["hoverskirm_missile"].id]             = {4.5},
	[WeaponDefNames["hoverassault_dew"].id]               = {2.5},
	[WeaponDefNames["amphraid_torpmissile"].id]           = {4.5},
	[WeaponDefNames["amphfloater_cannon"].id]             = {2.5},
	[WeaponDefNames["amphaa_missile"].id]                 = {14.0},
	[WeaponDefNames["spiderassault_thud_weapon"].id]      = {2.5},
	[WeaponDefNames["spiderskirm_adv_rocket"].id]         = {2.5},
	[WeaponDefNames["spidercrabe_arm_crabe_gauss"].id]    = {2.5},
	[WeaponDefNames["spideraa_aa"].id]                    = {11.0},
	[WeaponDefNames["jumpscout_missile"].id]              = {8.0},
	[WeaponDefNames["tankassault_cor_reap"].id]           = {2.5},
	[WeaponDefNames["tankheavyassault_cor_gol"].id]       = {2.0},
	[WeaponDefNames["tankarty_core_artillery"].id]        = {1.5},
	[WeaponDefNames["tankheavyarty_plasma"].id]           = {0.5},
	[WeaponDefNames["striderantiheavy_disintegrator"].id] = {2.8},
	[WeaponDefNames["striderdante_napalm_rockets"].id]    = {2.8},
	[WeaponDefNames["striderarty_rocket"].id]             = {0.5},
--	[WeaponDefNames["shipcarrier_armmship_rocket"].id]    = {0.5},
	[WeaponDefNames["shipheavyarty_plasma"].id]           = {2.5},
	[WeaponDefNames["shipskirm_rocket"].id]               = {2.8},
	[WeaponDefNames["shiparty_plasma"].id]                = {2.0},
	[WeaponDefNames["turretmissile_armrl_missile"].id]    = {14.0},
	[WeaponDefNames["turretriot_turretriot_weapon"].id]   = {5.0},
	[WeaponDefNames["turretaalaser_aagun"].id]            = {7.0, 0, 3},
	[WeaponDefNames["turretaaclose_missile"].id]          = {16.0},
	[WeaponDefNames["turretaafar_missile"].id]            = {14.0},
	[WeaponDefNames["staticarty_plasma"].id]              = {2.5},
	[WeaponDefNames["staticheavyarty_plasma"].id]         = {2.0},
}

-- Do not apply the large already disarmed target penalty if it has disarm less than the times below.
-- If a unit is disarmed OKP says that it is expected to be disarmed then the large penalty is applied regardless.
local disarmWeaponTimeDefs = {
	[WeaponDefNames["shieldarty_emp_rocket"].id] = 5,
	[WeaponDefNames["shipscout_missile"].id] = 1.5,
}

-- Penalty for shooting at disarmed/disabled units
local disarmPenaltyDefs = {
	[WeaponDefNames["shieldarty_emp_rocket"].id] = 200,
	[WeaponDefNames["shipscout_missile"].id] = 10,
}

for key, value in pairs(disarmWeaponTimeDefs) do
	disarmWeaponTimeDefs[key] = DISARM_BASE + DISARM_ADD*(value*30)/DISARM_ADD_TIME
end

local captureWeaponDefs = {
	[WeaponDefNames["vehcapture_captureray"].id] = true
}

local gravityWeaponDefs = {
	[WeaponDefNames["turretimpulse_gravity_neg"].id] = true,
	[WeaponDefNames["turretimpulse_gravity_pos"].id] = true,
	[WeaponDefNames["jumpsumo_gravity_neg"].id] = true,
	[WeaponDefNames["jumpsumo_gravity_pos"].id] = true,
}

--Time("Load tables")

-- for heatrays
local proximityWeaponDefs = {}
for wdid = 1, #WeaponDefs do
	local cp = WeaponDefs[wdid].customParams
	if cp.proximity_priority then
		proximityWeaponDefs[wdid] = tonumber(cp.proximity_priority)
	elseif cp.dyndamageexp then
		proximityWeaponDefs[wdid] = 20
	end
end

--Time("Find heatrays")

local radarWobblePenalty = {
	[WeaponDefNames["vehheavyarty_cortruck_rocket"].id] = 5,
--	[WeaponDefNames["shipcarrier_armmship_rocket"].id] = 5,
	[WeaponDefNames["cloaksnipe_shockrifle"].id] = 5,
	[WeaponDefNames["turretantiheavy_ata"].id] = 5,
	[WeaponDefNames["hoverarty_ata"].id] = 5,
	[WeaponDefNames["cloakarty_hammer_weapon"].id] = 5,
}

local radarDotPenalty = {
	[WeaponDefNames["shieldarty_emp_rocket"].id] = 100,
}

--Time("Load more tables")

for i = 1, udCount do
	local ud = UnitDefs[i]
	if unitIsBadAgainstGround[i] then
		local weapons = ud.weapons
		for j = 1, #weapons do
			local wd = weapons[j]
			local realWD = wd.weaponDef
			weaponBadCats_ground[realWD] = true
		end
	elseif unitIsHeavyHitter[i] then
		local weapons = ud.weapons
		for j = 1, #weapons do
			local wd = weapons[j]
			local realWD = wd.weaponDef
			weaponBadCats_heavy[realWD] = true
		end
	end
end

--Time("Load more weaponBadCats")

-- Generate transport unit table
local transportMult = {}

for uid = 1, udCount do
	local ud = UnitDefs[uid]
	if ud.isTransport then
		transportMult[uid] = 0.98 -- Priority multiplier for transported unit.
	end
end

--Time("Generate transport")

-- Reduce WeaponDefs access from #UnitDefs*#WeaponDefs to #WeaponDefs
local weaponDamage = {}
for wid = 1, wdCount do
	local wd = WeaponDefs[wid]
	weaponDamage[wid] = wd.damages
end

--Time("Reduce WeaponDefs access")

-- Generate full target table
local targetTable = {}

local priority, damage
for uid = 1, udCount do
	local ud = UnitDefs[uid]
	local unitHealth = ud.health
	local inverseUnitCost = 1 / ud.buildTime
	local armorType = ud.armorType
	targetTable[uid] = {}
	for wid = 1, wdCount do
		damage = weaponDamage[wid][armorType]
		if damage > unitHealth then
			priority = damage * inverseUnitCost
		else
			priority = unitHealth * inverseUnitCost
		end
		if priority > 12 then
			priority = 12 + 0.1*priority
		end
		priority = priority + (unitPriorityModifier[uid] or 0)
		if unitIsUnarmed[uid] then
			targetTable[uid][wid] = priority + 35
		elseif unitIsClaw[uid] then
			targetTable[uid][wid] = priority + 1000
		elseif (weaponBadCats_fixedwing[wid] and unitIsFixedwing[uid]) or (weaponBadCats_gunship[wid] and unitIsGunship[uid]) or (weaponBadCats_ground[wid] and unitIsGround[uid]) then
			targetTable[uid][wid] = priority + 15
		elseif (unitIsFighterOrDrone[uid]) then
			targetTable[uid][wid] = priority + 10
		elseif (unitIsBomber[uid] and weaponIsAA[wid]) or (weaponBadCats_heavy[wid] and unitIsHeavy[uid]) then
			targetTable[uid][wid] = priority*0.3
		else
			targetTable[uid][wid] = priority
		end
	end
end

--Time("Generate full target table")

-- Autogenerate some wobble penalties.
for wid = 1, wdCount do
	if not radarWobblePenalty[wid] then
		local wd = WeaponDefs[wid]
		local wType = wd.type
		if wType == "BeamLaser" or wType == "LaserCannon" or wType == "LightningCannon" then
			radarWobblePenalty[wid] = 5
		end
	end
end

--Time("Autogenerate some wobble penalties")

-- Modify the velocity penalty defs to implement 'additional penantly per excess velocity'
for weaponDefID, data in pairs(velocityPenaltyDefs) do
	data[2] = data[2] or VEL_DEFAULT_BASE
	data[3] = data[3] or VEL_DEFAULT_SCALE
	
	data[2] = data[2] - data[1]*data[3]
end

--Time("Modify the velocity penalty")

local reloadTimeAlpha = 1.8 --seconds, matches Ripper's reload time
local highAlphaWeaponDamages = {}
for wid = 1, wdCount do
	local wd = WeaponDefs[wid]
	local shotDamage = wd.customParams and wd.customParams.shot_damage
	if shotDamage and wd.reload >= reloadTimeAlpha then
		highAlphaWeaponDamages[wid] = tonumber(shotDamage)
	end
end

--Time("highAlphaWeaponDamages")

return targetTable, disarmWeaponTimeDefs, disarmPenaltyDefs, captureWeaponDefs, gravityWeaponDefs, proximityWeaponDefs, velocityPenaltyDefs, radarWobblePenalty, radarDotPenalty, transportMult, highAlphaWeaponDamages, DISARM_BASE, DISARM_ADD, DISARM_ADD_TIME
