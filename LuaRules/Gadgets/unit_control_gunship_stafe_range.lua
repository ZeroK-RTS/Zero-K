--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
if not gadgetHandler:IsSyncedCode() then
	return
end
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function gadget:GetInfo()
  return {
    name      = "Control gunship strafe range",
    desc      = "Clean but rediculus Hax, check this because engine may 'fix' it. Ticket relevant http://springrts.com/mantis/view.php?id=2955",
    author    = "Google Frog",
    date      = "14 Feb 2012",
    license   = "GNU GPL, v2 or later",
    layer     = 0,
    enabled   = true  --  loaded by default?
  }
end

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
local unitDefsToModify = {}	-- [unitDefID] = combatrange

for udID = 1, #UnitDefs do
	local weapons = UnitDefs[udID].weapons
	for i=1,#weapons do
		local wd = WeaponDefs[weapons[i].weaponDef]
		if wd and wd.customParams.combatrange then
			unitDefsToModify[udID] = tonumber(wd.customParams.combatrange)
		end
	end
end

function gadget:UnitCreated(unitID, unitDefID, unitTeam)
	if unitDefsToModify[unitDefID] then
		Spring.SetUnitMaxRange(unitID, unitDefsToModify[unitDefID])
	end
end
