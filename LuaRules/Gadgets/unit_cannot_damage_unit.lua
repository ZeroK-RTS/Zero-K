--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
if not gadgetHandler:IsSyncedCode() then
	return
end
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
function gadget:GetInfo()
	return {
		name = "Cannot Damage Unit",
		desc = "Prevents units from taking damage from other units with specific UnitID",
		author = "Anarchid",
		date = "27.06.2016",
		license = "Public domain",
		layer = 21,
		enabled = true
	}
end

local spGetUnitRulesParam = Spring.GetUnitRulesParam
function gadget:UnitPreDamaged(unitID,unitDefID,_, damage,_, weaponDefID,attackerID,_,_, projectileID)
    if attackerID and spGetUnitRulesParam(attackerID,'cannot_damage_unit') == unitID then
        return 0;
    end
    return damage
end
