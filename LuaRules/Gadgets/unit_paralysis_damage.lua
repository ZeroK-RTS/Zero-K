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

local DECAY_SECONDS = 40 -- how long it takes to decay 100% para to 0

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

function gadget:UnitPreDamaged(unitID, unitDefID, unitTeam, damage, paralyzer,
                               weaponDefID, attackerID, attackerDefID, attackerTeam)
	if paralyzer then -- the weapon deals paralysis damage
		local health, maxHealth, paralyzeDamage = spGetUnitHealth(unitID)
		if health and maxHealth and health > 0 then -- taking no chances.
			local damage = GetStunDamage(weaponDefID, damage, health, maxHealth, paralyzeDamage)
			if overstunTime[weaponDefID] > 0 then
				-- Overstun allows units to stun for an addition time (usually 1 second) if the current stun time on the unit is within that range.
				local currentStunTime = (paralyzeDamage/maxHealth - 1) * DECAY_SECONDS
				local maxTime = math.max(paraTime[weaponDefID], math.min(paraTime[weaponDefID], currentStunTime) + overstunTime[weaponDefID])
				-- Solve the following for damage to limit damage by stun time:
				--   stun time = ((damage + paralyzeDamage)/maxHealth - 1) * DECAY_SECONDS
				damage = (maxTime/DECAY_SECONDS + 1)*maxHealth - paralyzeDamage
			end
			--Spring.Echo("damage", damage, ((damage + paralyzeDamage)/maxHealth - 1) * DECAY_SECONDS, paralyzeDamage, math.random())
			return damage
		end
	end
	
	return damage
end

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
