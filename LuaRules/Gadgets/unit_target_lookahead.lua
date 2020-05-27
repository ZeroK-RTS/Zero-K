if not gadgetHandler:IsSyncedCode() then
	return
end
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function gadget:GetInfo()
  return {
    name      = "Auto-Target Lookahead",
    desc      = "Has units with slow moving/high AoE attacks look outside of their immediate range for automatic targeting.\n"..
    "This obsoletes the aspect of PreFire that predicts when enemies will be in range by the time a projectile would hit them.",
    author    = "esainane",
    date      = "2020-05-03",
    license   = "GNU GPL, v2 or later",
    layer     = -1,
    enabled   = true,
  }
end

local lookaheadUnitDefs = {}
local weaponCounts = {}
for i=1, #UnitDefs do
	local unitDef = UnitDefs[i]
	lookaheadUnitDefs[i] = unitDef.customParams.lookahead
	weaponCounts[i] = #unitDef.weapons -- even for non-lookaheads, this keeps the internal representation an array
end

function gadget:UnitCreated(unitID, unitDefID)
	local lookahead = lookaheadUnitDefs[unitDefID]
	if not lookahead then
		return
	end
	for weaponIdx=1, weaponCounts[unitDefID] do
		Spring.SetUnitWeaponState(unitID, weaponIdx, "autoTargetRangeBoost", lookahead)
	end
end
