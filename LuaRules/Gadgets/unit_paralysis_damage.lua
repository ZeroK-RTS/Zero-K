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
local spSetUnitHealth    = Spring.SetUnitHealth
local spGetUnitDefID     = Spring.GetUnitDefID
local spGetUnitIsStunned = Spring.GetUnitIsStunned
local spGetUnitArmored   = Spring.GetUnitArmored
local spAddUnitDamage    = Spring.AddUnitDamage

local normalDamageMult = {}
local wantedWeaponList = {}
local paraTime = {}

for wdid = 1, #WeaponDefs do
	local wd = WeaponDefs[wdid]
	if wd.paralyzer then
		wantedWeaponList[#wantedWeaponList + 1] = wdid
	else
		local rawDamage = tonumber(wd.customParams.raw_damage or 0)
		if wd.customParams and wd.customParams.extra_damage and rawDamage > 0 then
			normalDamageMult[wdid] = wd.customParams.extra_damage/rawDamage
			paraTime[wdid] = wd.customParams.extra_paratime
			wantedWeaponList[#wantedWeaponList + 1] = wdid
		end
	end
end

function gadget:UnitPreDamaged_GetWantedWeaponDef()
	return wantedWeaponList
end

function gadget:UnitDamaged_GetWantedWeaponDef()
	return wantedWeaponList
end

function gadget:UnitPreDamaged(unitID, unitDefID, unitTeam, damage, paralyzer,
                            weaponDefID, attackerID, attackerDefID, attackerTeam)
	if paralyzer then -- the weapon deals paralysis damage
		local health, maxHealth = spGetUnitHealth(unitID)
		if health and maxHealth and health ~= 0 then -- taking no chances.
			return damage*maxHealth/health
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

		spAddUnitDamage(unitID, mult*damage, paraTime[weaponDefID], attackerID, weaponDefID)
	end
end
