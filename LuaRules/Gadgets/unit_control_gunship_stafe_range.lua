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
local unitDefsToModify = {}	-- [unitDefID] = {[1] = truerange, [2] = truerange, etc.}

-- NOTE: truerange is set in weapondefs_posts. Set range with combatrange in weapondefs.

for udID = 1, #UnitDefs do
	local weapons = UnitDefs[udID].weapons
	for i=1,#weapons do
		local wd = WeaponDefs[weapons[i].weaponDef]
		if wd and wd.customParams.truerange then
			unitDefsToModify[udID] = unitDefsToModify[udID] or {}
			unitDefsToModify[udID][i] = wd.customParams.truerange
		end
	end
end

function gadget:UnitCreated(unitID, unitDefID, unitTeam)
	if unitDefsToModify[unitDefID] then
		for weaponNum, truerange in pairs(unitDefsToModify[unitDefID]) do
			Spring.SetUnitWeaponState(unitID,weaponNum,{range = truerange})
		end
	end
end
