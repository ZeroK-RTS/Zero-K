-- $Id: unit_nofriendlyfire.lua 3171 2008-11-06 09:06:29Z det $
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function gadget:GetInfo()
  return {
    name      = "No Friendly Fire",
    desc      = "Adds the nofriendlyfire custom param",
    author    = "quantum",
    date      = "June 24, 2008",
    license   = "GNU GPL, v2 or later",
    layer     = -999,
    enabled   = true  --  loaded by default?
  }
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

if (not gadgetHandler:IsSyncedCode()) then
  return false  --  silent removal
end

local bomberWeaponDefs = {
	[WeaponDefNames["corshad_shield_check"].id] = true,
}

local HitByWeaponUnits = {
	[UnitDefNames["armsolar"].id] = true,
}

local noFFWeaponDefs = {}
for i=1,#WeaponDefs do
  local wd = WeaponDefs[i]
  if wd.customParams and wd.customParams.nofriendlyfire then
    noFFWeaponDefs[i] = true
  end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

-- Automatically generated local definitions

local spAreTeamsAllied = Spring.AreTeamsAllied
local spGetUnitHealth  = Spring.GetUnitHealth
local spSetUnitHealth  = Spring.SetUnitHealth

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------


function gadget:UnitPreDamaged(unitID, unitDefID, unitTeam, damage, paralyzer, 
                            weaponID, attackerID, attackerDefID, attackerTeam)
	if (weaponID and
		noFFWeaponDefs[weaponID] and
		attackerID ~= unitID and
		((not attackerTeam) or spAreTeamsAllied(unitTeam, attackerTeam))) then
		return 0
	end
  
	if HitByWeaponUnits[unitDefID] and not bomberWeaponDefs[weaponID] then
		local func = Spring.UnitScript.GetScriptEnv(unitID).HitByWeaponGadget
		Spring.UnitScript.CallAsUnit(unitID,func)
	end
  
	return damage
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
