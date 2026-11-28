--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function gadget:GetInfo()
  return {
    name      = "Paralysis",
    desc      = "Handels paralysis system and adds extra_damage to lightning weapons",
    author    = "Google Frog",
    date      = "Apr, 2010",
    license   = "GNU GPL, v2 or later",
    layer     = 0,
    enabled   = true  --  loaded by default?
  }
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
if (not gadgetHandler:IsSyncedCode()) then
  return false  --  no unsynced code
end

local spGetUnitHealth    = Spring.GetUnitHealth
local spGetUnitArmored   = Spring.GetUnitArmored
local spAddUnitDamage    = Spring.AddUnitDamage
local GetUnitCost        = Spring.Utilities.GetUnitCost

local DECAY_SECONDS = 40 -- how long it takes to decay 100% para to 0
local paraTable = {paralyze = 0}

local normalDamageMult = {}
local wantedWeaponList = {}
local paraTime = {}
local overstunDamageMult = {}
local overstunTime = {}
-- Note that having EMP damage decay N times faster when above 100% is mathematically
-- equivalent multiplying all incoming EMP damage above 100% by of 1/N.

for wdid = 1, #WeaponDefs do
	local wd = WeaponDefs[wdid]
	if wd.paralyzer then
		wantedWeaponList[#wantedWeaponList + 1] = wdid
		paraTime[wdid] = math.max(1, wd.customParams.emp_paratime)
	else
		local rawDamage = tonumber(wd.customParams.raw_damage or 0)
		if wd.customParams and wd.customParams.extra_damage and rawDamage > 0 then
			normalDamageMult[wdid] = wd.customParams.extra_damage/rawDamage
			-- engine rounds down, but paratime 0 means real damage
			paraTime[wdid] = math.max(1, wd.customParams.extra_paratime)
			wantedWeaponList[#wantedWeaponList + 1] = wdid
		end
	end
	if wd.customParams and wd.customParams.overstun_time then
		overstunTime[wdid] = tonumber(wd.customParams.overstun_time)
	end
	if wd.customParams and wd.customParams.overstun_damage_mult then
		overstunDamageMult[wdid] = tonumber(wd.customParams.overstun_damage_mult)
	end
end

function gadget:UnitPreDamaged_GetWantedWeaponDef()
	return wantedWeaponList
end

function gadget:UnitDamaged_GetWantedWeaponDef()
	return wantedWeaponList
end

local function GetStunDamage(weaponDefID, damage, health, maxHealth, paralyzeDamage)
	if not (weaponDefID and overstunDamageMult[weaponDefID]) then
		return damage*maxHealth/health
	end
	
	local rawDamage = damage*maxHealth/health
	if maxHealth <= paralyzeDamage then
		--Spring.Echo("Above", rawDamage*overstunDamageMult[weaponDefID])
		return rawDamage*overstunDamageMult[weaponDefID]
	end
	local damageGap = (maxHealth - paralyzeDamage)
	if rawDamage <= damageGap then
		--Spring.Echo("damageGap", maxHealth, paralyzeDamage, damageGap, rawDamage)
		return rawDamage
	end
	--Spring.Echo("Partial", maxHealth, paralyzeDamage, damageGap, rawDamage, damageGap + (rawDamage - damageGap)*overstunDamageMult[weaponDefID])
	return damageGap + (rawDamage - damageGap)*overstunDamageMult[weaponDefID]
end

function gadget:UnitPreDamaged(unitID, unitDefID, unitTeam, rawDamage, paralyzer,
                               weaponDefID, attackerID, attackerDefID, attackerTeam)
	if paralyzer then -- the weapon deals paralysis damage
		local health, maxHealth, paralyzeDamage = spGetUnitHealth(unitID)
		if health and maxHealth and health > 0 then -- taking no chances.
			if GG.Awards and GG.Awards.AddAwardPoints then
				local maxStunFraction = paraTime[weaponDefID] / DECAY_SECONDS
				local maxParaHealth = maxHealth * (1 + maxStunFraction)
				local remainingParaHealth = maxParaHealth - paralyzeDamage

				-- in theory overstun mult can modify things further,
				-- but we don't care for similar reasons why the
				-- mult from low health is ignored as well

				if remainingParaHealth > 0 then -- smaller than 0 if already stunned by a stronger weapon
					local cappedDamage = math.min(rawDamage, remainingParaHealth)
					local cost_emped = (cappedDamage / maxHealth) * GetUnitCost(unitID)
					GG.Awards.AddAwardPoints('emp', attackerTeam, cost_emped)
				end
			end
			local damage = GetStunDamage(weaponDefID, rawDamage, health, maxHealth, paralyzeDamage)
			if overstunTime[weaponDefID] > 0 then
				-- Overstun allows units to extend the stun near their stun threshold, usally by 1 second.
				local currentStunTime = (paralyzeDamage/maxHealth - 1) * DECAY_SECONDS
				local maxTime = math.max(paraTime[weaponDefID], math.min(paraTime[weaponDefID], currentStunTime) + overstunTime[weaponDefID])
				-- Solve the following for damage to limit damage by stun time:
				--   stun time = ((damage + paralyzeDamage)/maxHealth - 1) * DECAY_SECONDS
				damage = math.max(0, math.min(damage, (maxTime/DECAY_SECONDS + 1)*maxHealth - paralyzeDamage))
			end
			--Spring.Echo("damage", damage, ((damage + paralyzeDamage)/maxHealth - 1) * DECAY_SECONDS, paralyzeDamage, WeaponDefs[weaponDefID].damages.paralyzeDamageTime, math.random())
			if damage > 0 and damage + paralyzeDamage > maxHealth then
				-- Engine seems to discard all paralysis damage that puts the target above the next-lowest multiple of maxHealth/DECAY_SECONDS.
				-- So we're just going to give up on the engine and set the damage ourselves.
				local quanta = maxHealth/DECAY_SECONDS
				if damage > quanta then
					paraTable.paralyze = paralyzeDamage + damage - quanta
					Spring.SetUnitHealth(unitID, paraTable)
					return quanta -- Returning 0 might do something weird to the unit behaviour hardcoded in the engine
				end
				paraTable.paralyze = paralyzeDamage + damage
				Spring.SetUnitHealth(unitID, paraTable)
				return 0
			end
			return damage
		end
	end
	
	return damage
end

--function gadget:GameFrame(f)
--	local allUnits = Spring.GetAllUnits()
--	for i = 1, #allUnits do
--		local unitID = allUnits[i]
--		local health, maxHealth, paralyzeDamage = spGetUnitHealth(unitID)
--		if paralyzeDamage > 0 then
--			Spring.Echo(unitID, paralyzeDamage, f)
--		end
--	end
--end

function gadget:UnitDamaged(unitID, unitDefID, unitTeam, damage, paralyzer, weaponDefID, attackerID)
	local mult = normalDamageMult[weaponDefID]
	if mult and not paralyzer then
		-- Don't apply armour twice.
		local armored, armorMult = spGetUnitArmored(unitID)
		if armored then
			mult = mult/armorMult
		end
		spAddUnitDamage(unitID, mult*damage, paraTime[weaponDefID] + overstunTime[weaponDefID], attackerID, weaponDefID)
	end
end
