-- $Id: unit_noselfpwn.lua 3171 2008-11-06 09:06:29Z det $
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function gadget:GetInfo()
  return {
    name      = "No Self Pwn",
    desc      = "Prevents units from damaging themselves.",
    author    = "quantum",
    date      = "Feb 1, 2008",
    license   = "GNU GPL, v2 or later",
    layer     = 0,
    enabled   = true  --  loaded by default?
  }
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local exceptionList = {
  "corsilo",
  "firewalker",
}
  
if (not gadgetHandler:IsSyncedCode()) then
  return false  --  silent removal
end
 
local exceptionMap  = {}
for _, unitName in pairs(exceptionList) do
  exceptionMap[UnitDefNames[unitName].id] = true
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function gadget:UnitPreDamaged(unitID, unitDefID, unitTeam, damage, paralyzer, 
                            weaponID, attackerID, attackerDefID, attackerTeam)
  if (unitID == attackerID and not exceptionMap[unitDefID]) then
	return 0
  end
  return damage
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------