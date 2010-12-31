--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function gadget:GetInfo()
  return {
    name      = "Para for damage weapons",
    desc      = "Adds para damage to some weapons",
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

local spGetUnitHealth = Spring.GetUnitHealth
local spSetUnitHealth = Spring.SetUnitHealth
local spGetUnitDefID  = Spring.GetUnitDefID


local paralysisList = {}

for i=1,#WeaponDefs do
	if WeaponDefs[i].customParams and WeaponDefs[i].customParams.extra_damage then 
		paralysisList[i] = WeaponDefs[i].customParams.extra_damage
	end
end  
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function gadget:UnitPreDamaged(unitID, unitDefID, unitTeam, damage, paralyzer, 
                            weaponID, attackerID, attackerDefID, attackerTeam)
	if paralysisList[weaponID] then
		attackerID = attackerID or -1
		Spring.AddUnitDamage(unitID, paralysisList[weaponID], 0, attackerID)
	end
	return damage
end