if not gadgetHandler:IsSyncedCode() then return end

function gadget:GetInfo()
	return {
		name    = "Fighter pull-up",
		desc    = "Sets attack safety distance for fighter/bomber aircraft",
		author  = "raaar",
		date    = "2015",
		license = "PD",
		layer   = 3,
		enabled = true
	}
end

local pullupDist = {}

for unitDefID, unitDef in pairs(UnitDefs) do
	local dist = unitDef.customParams.fighter_pullup_dist
	if dist then
		pullupDist[unitDefID] = dist
	end
end

local spMoveCtrlGetTag = Spring.MoveCtrl.GetTag
local spMoveCtrlSetAirMoveTypeData = Spring.MoveCtrl.SetAirMoveTypeData
local moveTypeDataTable = {attackSafetyDistance = 123}

function gadget:UnitCreated(unitID, unitDefID)
	local dist = pullupDist[unitDefID]
	if dist then
		if spMoveCtrlGetTag(unitID) == nil then
			moveTypeDataTable.attackSafetyDistance = dist
			spMoveCtrlSetAirMoveTypeData(unitID, moveTypeDataTable)
		else
			Spring.Echo("LUA_ERRRUN", "Fighter pullup with spMoveCtrlGetTag", (UnitDefs[unitDefID] and UnitDefs[unitDefID].name) or "noname")
		end
	end
end
