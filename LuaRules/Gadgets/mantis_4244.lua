
function gadget:GetInfo()
  return {
    name      = "Mantis 4244",
    desc      = "Workaround for Mantis 4244",
    author    = "Google Frog",
    date      = "5 jan 2014",
    license   = "GNU GPL, v2 or later",
    layer     = 0,
    enabled   = (Game.version:find('91.0') == 1) and (Game.version:find('91.0.1') == nil)  --  loaded by default?
  }
end

if not gadgetHandler:IsSyncedCode() then
	return
end

local paraTimeWeapons = {}
local wantedWeaponList = {}
--Spring.Echo("Weapondefs")

for wdid = 1, #WeaponDefs do
	local wd = WeaponDefs[wdid]
	if wd.paralyzer and wd.damages.paralyzeDamageTime then 
		paraTimeWeapons[wdid] = (wd.damages.paralyzeDamageTime or 0)/40
		wantedWeaponList[#wantedWeaponList + 1] = wdid
	end
end 

local spGetUnitHealth = Spring.GetUnitHealth

function gadget:UnitPreDamaged_GetWantedWeaponDef()
	return wantedWeaponList
end

function gadget:UnitPreDamaged(unitID, unitDefID, unitTeam, damage, paralyzer, 
                            weaponDefID, attackerID, attackerDefID, attackerTeam)
	if paralyzer and unitID and paraTimeWeapons[weaponDefID] then -- the weapon deals paralysis damage
		
		local health, maxHealth, paralyzeDamage = spGetUnitHealth(unitID)
		if paralyzeDamage and maxHealth and paralyzeDamage > maxHealth then
			local stunTime = paralyzeDamage/maxHealth - 1
			if stunTime >= paraTimeWeapons[weaponDefID] then
				return 0
			end
		end
	end
	
	return damage
end