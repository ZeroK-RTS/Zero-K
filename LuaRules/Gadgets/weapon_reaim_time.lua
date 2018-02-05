function gadget:GetInfo()
	return {
		name      = "Weapon Reaim Time",
		desc      = "Implement weapon reaim time tag",
		author    = "GoogleFrog",
		date      = "4 February 2018",
		license   = "GNU GPL, v2 or later",
		layer     = 0,
		enabled   = true,
	}
end

-------------------------------------------------------------
-------------------------------------------------------------
if not (gadgetHandler:IsSyncedCode()) then 
	return false
end
-------------------------------------------------------------
-------------------------------------------------------------
local unitDefsToModify = {}

for udID = 1, #UnitDefs do
	local weapons = UnitDefs[udID].weapons
	for i = 1, #weapons do
		local wd = WeaponDefs[weapons[i].weaponDef]
		if wd and wd.customParams.reaim_time then
			unitDefsToModify[udID] = unitDefsToModify[udID] or {}
			unitDefsToModify[udID][i] = wd.customParams.reaim_time
		end
	end
end

function gadget:UnitCreated(unitID, unitDefID, unitTeam)
	if unitDefsToModify[unitDefID] then
		for weaponNum, reaimTime in pairs(unitDefsToModify[unitDefID]) do
			Spring.SetUnitWeaponState(unitID, weaponNum, {reaimTime = 1})
		end
	end
end
