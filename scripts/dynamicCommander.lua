-- TODO: CACHE INCLUDE FILE
-- May not be worth it due to the rarity of comms, and the complexity of this file.
local INLOS = {inlos = true}

local dgunTable
local weapon1
local weapon2
local shield
local weaponNumMap = {}
local weaponsInitialized = false
local paceMult
local scaleMult
local weaponCegs = {}

local commWreckUnitRulesParam = {"comm_baseWreckID", "comm_baseHeapID"}
local moduleWreckNamePrefix = {"module_wreck_", "module_heap_"}

local isManual = {}

local shields = {}
local unitWeaponNames = {} -- Unit weapons by name
local wepTable = UnitDefs[unitDefID].weapons
for num = 1, #wepTable do
	local wd = WeaponDefs[wepTable[num].weaponDef]
	if wd.type == "Shield" then
		shields[#shields + 1] = num
	end
	local weaponName = string.sub(wd.name, (string.find(wd.name,"commweapon") or 0), 100)
	if weaponName then
		if unitWeaponNames[weaponName] then
			unitWeaponNames[weaponName].num2 = num
		else
			unitWeaponNames[weaponName] = {
				num = num,
				weaponDefID = wd.id,
				manualFire = (wd.customParams and wd.customParams.manualfire and true) or false
			}
		end
	end
end

local function IsManualFire(num)
	return isManual[num]
end

local levelScale = {
    [0] = 1,
    [1] = 1,
    [2] = 1.1,
    [3] = 1.2,
    [4] = 1.25,
    [5] = 1.3,
}
local levelToPace = {}
for key, value in pairs(levelScale) do
	levelToPace[key] = 1/value
end

local function GetLevel()
	local ud = UnitDefs[unitDefID]
	return Spring.GetUnitRulesParam(unitID, "comm_level") or tonumber(ud.customParams.level) or 0
end

local function CalculatePaceMult()
	paceMult = levelToPace[GetLevel()] or levelToPace[5]
	return paceMult
end

local function GetPace()
	return paceMult or CalculatePaceMult()
end

local function CalculateScaleMult()
	scaleMult = levelScale[GetLevel()] or levelScale[5]
	return scaleMult
end

local function GetScale()
	return scaleMult or CalculateScaleMult()
end

local function GetWeapon(num)
	local retNum = GG.Upgrades_WeaponNumMap(unitID, num) or weaponNumMap[num]
	if retNum then
		return retNum
	end
	if not weaponsInitialized then
		local tempWeapon1 = Spring.GetUnitRulesParam(unitID, "comm_weapon_num_1")
		local tempWeapon2 = Spring.GetUnitRulesParam(unitID, "comm_weapon_num_2")
		local tempShield = Spring.GetUnitRulesParam(unitID, "comm_shield_num")
		if num == tempWeapon1 then
			return 1
		elseif num == tempWeapon2 then
			return 2
		elseif num == tempShield then
			return 3
		end
	end
	return false
end

local function EmitWeaponFireSfx(pieceNum, num)
	local weaponNum = GetWeapon(num)
	if Spring.GetCEGID then
		if weaponCegs[weaponNum] and weaponCegs[weaponNum].misc then
			EmitSfx(pieceNum, weaponCegs[weaponNum].misc)
		end
	else
		if weaponNum == 1 then
			if weapon1 then
				EmitSfx(pieceNum, 1029 + weapon1*2)
			end
		elseif weaponNum == 2 then
			if weapon1 then
				EmitSfx(pieceNum, 1029 + weapon2*2)
			end
		end
	end
end

local function EmitWeaponShotSfx(pieceNum, num)
	local weaponNum = GetWeapon(num)
	if Spring.GetCEGID then
		if weaponCegs[weaponNum] and weaponCegs[weaponNum].muzzle then
			EmitSfx(pieceNum, weaponCegs[weaponNum].muzzle)
		end
	else
		if weaponNum == 1 then
			if weapon1 then
				EmitSfx(pieceNum, 1030 + weapon1*2)
			end
		elseif weaponNum == 2 then
			if weapon2 then
				EmitSfx(pieceNum, 1030 + weapon2*2)
			end
		end
	end
end

local function GetCegTable(wd)
	if not Spring.GetCEGID then
		return
	end
	local cp = wd.customParams
	if not (cp and (cp.muzzleeffectshot or cp.misceffectshot)) then
		return
	end
	local cegs = {
		muzzle = cp.muzzleeffectshot and (SFX.GLOBAL + Spring.GetCEGID(cp.muzzleeffectshot:gsub("custom:",""))),
		misc = cp.misceffectshot and (SFX.GLOBAL + Spring.GetCEGID(cp.misceffectshot:gsub("custom:",""))),
	}
	return cegs
end

local function UpdateWeaponProjectileSpeed(unitID, weaponNum, wd, range)
	-- It is important that this is called before updating the range of the weapon.
	if wd.type ~= "LaserCannon" then
		return
	end
	
	-- Laser cannon speed must be an integer multiple of range
	local elmosPerFrame = wd.projectilespeed
	local lifetime = range / elmosPerFrame
	local roundLifetime = math.floor(lifetime + 0.5)
	local wantedSpeed = range / roundLifetime - 0.00001 -- Underestimate speed because engine rounds range to the next-lowest Speed*Integer
	Spring.SetUnitWeaponState(unitID, weaponNum, "projectileSpeed", wantedSpeed)
end

local function UpdateWeapons(weaponName1, weaponName2, shieldName, rangeMult, damageMult)
	local weaponDef1 = weaponName1 and unitWeaponNames[weaponName1]
	local weaponDef2 = weaponName2 and unitWeaponNames[weaponName2]
	local shieldDef = shieldName and unitWeaponNames[shieldName]
	
	weapon1 = weaponDef1 and weaponDef1.num
	weapon2 = weaponDef2 and (weaponDef2.num2 or weaponDef2.num)
	shield  = shieldDef and shieldDef.num
	
	if weapon1 then
		Spring.SetUnitRulesParam(unitID, "comm_weapon_name_1", weaponName1, INLOS)
		Spring.SetUnitRulesParam(unitID, "comm_weapon_id_1", (weaponDef1 and weaponDef1.weaponDefID) or 0, INLOS)
		Spring.SetUnitRulesParam(unitID, "comm_weapon_num_1", weapon1, INLOS)
		Spring.SetUnitRulesParam(unitID, "comm_weapon_manual_1", (weaponDef1 and weaponDef1.manualFire and 1) or 0, INLOS)
		weaponCegs[1] = GetCegTable(WeaponDefs[weaponDef1.weaponDefID])
	end
	
	if weapon2 then
		Spring.SetUnitRulesParam(unitID, "comm_weapon_name_2", weaponName2, INLOS)
		Spring.SetUnitRulesParam(unitID, "comm_weapon_id_2", (weaponDef2 and weaponDef2.weaponDefID) or 0, INLOS)
		Spring.SetUnitRulesParam(unitID, "comm_weapon_num_2", weapon2, INLOS)
		Spring.SetUnitRulesParam(unitID, "comm_weapon_manual_2", (weaponDef2 and weaponDef2.manualFire and 1) or 0, INLOS)
		weaponCegs[2] = GetCegTable(WeaponDefs[weaponDef2.weaponDefID])
	end

	if shield then
		Spring.SetUnitRulesParam(unitID, "comm_shield_name", shieldName, INLOS)
		Spring.SetUnitRulesParam(unitID, "comm_shield_id", shieldDef.weaponDefID, INLOS)
		Spring.SetUnitRulesParam(unitID, "comm_shield_num", shield, INLOS)
		Spring.SetUnitRulesParam(unitID, "comm_shield_max", WeaponDefs[shieldDef.weaponDefID].shieldPower, INLOS)
	else
		Spring.SetUnitRulesParam(unitID, "comm_shield_max", 0, INLOS)
	end
	
	weaponNumMap = {}
	if weapon1 then
		weaponNumMap[weapon1] = 1
	end
	if weapon2 then
		weaponNumMap[weapon2] = 2
	end
	if shield then
		weaponNumMap[shield] = 3
	end
	
	local hasManualFire = (weaponDef1 and weaponDef1.manualFire) or (weaponDef2 and weaponDef2.manualFire)
	local cmdDesc = Spring.FindUnitCmdDesc(unitID, CMD.MANUALFIRE)
	if not hasManualFire and cmdDesc then
		Spring.RemoveUnitCmdDesc(unitID, cmdDesc)
	elseif hasManualFire and not cmdDesc then
		cmdDesc = Spring.FindUnitCmdDesc(unitID, CMD.ATTACK) + 1 -- insert after attack so that it appears in the correct spot in the menu
		Spring.InsertUnitCmdDesc(unitID, cmdDesc, dgunTable)
	end

	local maxRange = 0
	local otherRange = false
	if weapon1 then
		isManual[weapon1] = weaponDef1.manualFire
		local range = tonumber(WeaponDefs[weaponDef1.weaponDefID].range)*rangeMult
		if weaponDef1.manualFire then
			otherRange = range
		else
			maxRange = range
		end
		UpdateWeaponProjectileSpeed(unitID, weapon1, WeaponDefs[weaponDef1.weaponDefID], range)
		Spring.SetUnitWeaponState(unitID, weapon1, "range", range)
		Spring.SetUnitWeaponDamages(unitID, weapon1, "dynDamageRange", range)
		
		local damages = WeaponDefs[weaponDef1.weaponDefID].damages
		for k, v in pairs(damages) do
			if type(k) == "number" then
				Spring.SetUnitWeaponDamages(unitID, weapon1, k, v * damageMult)
			end
		end
	end
	
	if weapon2 then
		isManual[weapon2] = weaponDef2.manualFire
		local range = tonumber(WeaponDefs[weaponDef2.weaponDefID].range)*rangeMult
		if maxRange then
			if weaponDef2.manualFire then
				otherRange = range
			elseif range > maxRange then
				otherRange = maxRange
				maxRange = range
			elseif range < maxRange then
				otherRange = range
			end
		else
			maxRange = range
		end
		UpdateWeaponProjectileSpeed(unitID, weapon2, WeaponDefs[weaponDef2.weaponDefID], range)
		Spring.SetUnitWeaponState(unitID, weapon2, "range", range)
		Spring.SetUnitWeaponDamages(unitID, weapon2, "dynDamageRange", range)
		
		local damages = WeaponDefs[weaponDef2.weaponDefID].damages
		for k, v in pairs(damages) do
			if type(k) == "number" then
				Spring.SetUnitWeaponDamages(unitID, weapon2, k, v * damageMult)
			end
		end
	end
	
	if weapon1 then
		if weapon2 then
			local reload1 = Spring.GetUnitWeaponState(unitID, weapon1, 'reloadTime')
			local reload2 = Spring.GetUnitWeaponState(unitID, weapon2, 'reloadTime')
			if reload1 > reload2 then
				Spring.SetUnitRulesParam(unitID, "primary_weapon_override",  weapon1, INLOS)
			else
				Spring.SetUnitRulesParam(unitID, "primary_weapon_override",  weapon2, INLOS)
			end
			
			local range1 = Spring.GetUnitWeaponState(unitID, weapon1, 'range')
			local range2 = Spring.GetUnitWeaponState(unitID, weapon2, 'range')
			if range1 > range2 then
				Spring.SetUnitRulesParam(unitID, "primary_weapon_range",  weapon1, INLOS)
			else
				Spring.SetUnitRulesParam(unitID, "primary_weapon_range",  weapon2, INLOS)
			end
		else
			Spring.SetUnitRulesParam(unitID, "primary_weapon_override",  weapon1, INLOS)
			Spring.SetUnitRulesParam(unitID, "primary_weapon_range",  weapon1, INLOS)
		end
	end
	
	-- Set other ranges to 0 for leashing
	if weapon1 ~= 1 and weapon2 ~= 1 then
		Spring.SetUnitWeaponState(unitID, 1, "range", maxRange)
	end
	for i = 2, 32 do
		if i ~= weapon1 and i ~= weapon2 then
			Spring.SetUnitWeaponState(unitID, i, "range", 0)
		end
	end
	Spring.SetUnitMaxRange(unitID, maxRange)
	Spring.SetUnitRulesParam(unitID, "comm_max_range", maxRange, INLOS)
	
	Spring.SetUnitRulesParam(unitID, "sightRangeOverride", math.max(500, math.min(600, maxRange*1.1)), INLOS)
	
	if otherRange then
		Spring.SetUnitRulesParam(unitID, "secondary_range", otherRange, INLOS)
	end
	
	-- shields
	for i = 1, #shields do
		--Spring.SetUnitShieldState(unitID, shields[i], false)
	end
	
	if (shield) then
		Spring.SetUnitShieldState(unitID, shield, true)
	end
	
	weaponsInitialized = true
end

local function Create()
	-- copy the dgun command table because we sometimes need to reinsert it
	local cmdID = Spring.FindUnitCmdDesc(unitID, CMD.MANUALFIRE)
	dgunTable = Spring.GetUnitCmdDescs(unitID, cmdID)[1]
	
	if Spring.GetUnitRulesParam(unitID, "comm_weapon_id_1") then
		UpdateWeapons(
			Spring.GetUnitRulesParam(unitID, "comm_weapon_name_1"),
			Spring.GetUnitRulesParam(unitID, "comm_weapon_name_2"),
			Spring.GetUnitRulesParam(unitID, "comm_shield_name"),
			Spring.GetUnitRulesParam(unitID, "comm_range_mult") or 1,
			Spring.GetUnitRulesParam(unitID, "comm_damage_mult") or 1
		)
	end
end


local function SpawnModuleWreck(moduleDefID, wreckLevel, totalCount, teamID, x, y, z, vx, vy, vz)
	local featureDefID = FeatureDefNames[moduleWreckNamePrefix[wreckLevel] .. moduleDefID]
	if not featureDefID then
		Spring.Echo("Cannot find module wreck", moduleWreckNamePrefix[wreckLevel] .. moduleDefID)
		return
	end
	featureDefID = featureDefID.id
	
	local dir = math.random()*2*math.pi
	local pitch = ((math.random()*2)^2 - 1)*math.pi/2
	local heading = math.random(65536)
	local mag = 60 + math.random()*(30 + 5*math.min(totalCount, 15))
	local horScale = mag*math.cos(pitch)

	local dx = vx + math.cos(dir)*horScale
	local dz = vz + math.sin(dir)*horScale

	local featureID = Spring.CreateFeature(featureDefID, x + dx, y, z + dz, heading, teamID)
end

local function SpawnModuleWrecks(wreckLevel)
	local x, y, z, mx, my, mz = Spring.GetUnitPosition(unitID, true)
	local vx, vy, vz = Spring.GetUnitVelocity(unitID)
	local teamID	= Spring.GetUnitTeam(unitID)
	
	local moduleCount = Spring.GetUnitRulesParam(unitID, "comm_module_count") or 0;
	for i = 1, moduleCount do
		SpawnModuleWreck(Spring.GetUnitRulesParam(unitID, "comm_module_" .. i), wreckLevel, moduleCount, teamID, x, y, z, vx, vy, vz)
	end
end

local function SpawnWreck(wreckLevel)
	local makeRezzable = (wreckLevel == 1)
	local wreckDef = FeatureDefs[Spring.GetUnitRulesParam(unitID, commWreckUnitRulesParam[wreckLevel])]
	
	local x, y, z = Spring.GetUnitPosition(unitID)
	
	local vx, vy, vz = Spring.GetUnitVelocity(unitID)
	
	if (wreckDef) then
		local heading   = Spring.GetUnitHeading(unitID)
		local teamID	= Spring.GetUnitTeam(unitID)
		local featureID = Spring.CreateFeature(wreckDef.id, x, y, z, heading, teamID)
		Spring.SetFeatureVelocity(featureID, vx, vy, vz)
		if makeRezzable then
			local baseUnitDefID = Spring.GetUnitRulesParam(unitID, "comm_baseUnitDefID") or unitDefID
			Spring.SetFeatureResurrect(featureID, UnitDefs[baseUnitDefID].name)
		end
	end
end

return {
	GetPace           = GetPace,
	GetScale          = GetScale,
	GetWeapon         = GetWeapon,
	EmitWeaponFireSfx = EmitWeaponFireSfx,
	EmitWeaponShotSfx = EmitWeaponShotSfx,
	UpdateWeapons     = UpdateWeapons,
	IsManualFire      = IsManualFire,
	Create            = Create,
	SpawnModuleWrecks = SpawnModuleWrecks,
	SpawnWreck        = SpawnWreck,
}
