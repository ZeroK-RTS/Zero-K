--[[ Handles the scouting unit job
 * Add units to this handler to have them controled by it.
 * Maintains a heatmap of locations to scout.
 * Requires perdiodic UpdateHeatmap and RunJobHandler.
 * Only one of these is needed per teamID.
--]]
local UnitListHandler = VFS.Include("LuaRules/Gadgets/CAI/UnitListHandler.lua")

local GiveClampedOrderToUnit = Spring.Utilities.GiveClampedOrderToUnit
local CMD_FIGHT = CMD.FIGHT

local combatHandler = {}

function combatHandler.CreateCombatHandler(allyTeamID)

	local unitList = UnitListHandler.CreateUnitList()

	local function RunJobHandler()
		if unscoutedCount > 0 then
			for unitID,_ in scoutList.Iterator() do
				local queueSize = spGetCommandQueue(unitID, 0)
				if queueSize then
					if queueSize == 0 then
						local randIndex = math.floor(math.random(1,unscoutedCount))
						GiveClampedOrderToUnit(unitID, CMD_FIGHT , unscoutedPoints[randIndex], {})
					end
				else
					scoutList.RemoveUnit(unitID)
				end
			end
		end
	end
	
	local newScoutHandler = {
		UpdateHeatmap = UpdateHeatmap,
		RunJobHandler = RunJobHandler,
		AddUnit = unitList.AddUnit,
		RemoveUnit = unitList.RemoveUnit,
		GetTotalCost = unitList.GetTotalCost,
	}
	
	return newScoutHandler
end

return combatHandler
