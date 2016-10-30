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

for wdid = 1, #WeaponDefs do
	local wd = WeaponDefs[wdid]
	if wd.paralyzer then
		local rawDamage = tonumber(wd.customParams.raw_damage or 0)
		if wd.customParams and wd.customParams.extra_damage and rawDamage > 0 then
			Spring.Echo("wd.customParams.raw_damage", wd.customParams.raw_damage)
			normalDamageMult[wdid] = wd.customParams.extra_damage/rawDamage
		end
		wantedWeaponList[#wantedWeaponList + 1] = wdid
	end
end

function gadget:UnitPreDamaged_GetWantedWeaponDef()
	return wantedWeaponList
end

function gadget:UnitDamaged_GetWantedWeaponDef()
	return wantedWeaponList
end

local already_stunned = false

function gadget:UnitPreDamaged(unitID, unitDefID, unitTeam, damage, paralyzer, 
                            weaponDefID, attackerID, attackerDefID, attackerTeam)
	if paralyzer then -- the weapon deals paralysis damage
		already_stunned = spGetUnitIsStunned(unitID)
		local health, maxHealth = spGetUnitHealth(unitID)
		if normalDamageMult[weaponDefID] then
			attackerID = attackerID or -1
			local damageMult = normalDamageMult[weaponDefID]
			
			-- Don't apply armour twice
			local armored, mult = spGetUnitArmored(unitID)
			if armored then
				damageMult = damageMult/mult
			end
			
			-- be careful; this line can cause recursion! don't make it do paralyzer damage
			spAddUnitDamage(unitID, damageMult*damage, 0, attackerID, weaponDefID)
		end
		if health and maxHealth and health ~= 0 then -- taking no chances.
			return damage*maxHealth/health
		end
	end
	
	return damage
end
