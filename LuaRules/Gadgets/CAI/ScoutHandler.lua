--[[ Handles the scouting unit job
 * Add units to this handler to have them controled by it.
 * Maintains a heatmap of locations to scout.
 * Requires perdiodic UpdateHeatmap and RunJobHandler.
 * Only one of these is needed per teamID.
--]]
local UnitListHandler = VFS.Include("LuaRules/Gadgets/CAI/UnitListHandler.lua")

local spIsPosInLos = Spring.IsPosInLos
local spGetCommandQueue = Spring.GetCommandQueue
local GiveClampedOrderToUnit = Spring.Utilities.GiveClampedOrderToUnit
local CMD_FIGHT = CMD.FIGHT

local scoutHandler = {}

function scoutHandler.CreateScoutHandler(scoutHeatmap)

	local scoutList = UnitListHandler.CreateUnitList()

	local function RunJobHandler()
		if scoutHeatmap.IsScoutingRequired() then
			for unitID,_ in scoutList.Iterator() do
				local queueSize = spGetCommandQueue(unitID, 0)
				if queueSize then
					if queueSize == 0 then
						GiveClampedOrderToUnit(unitID, CMD_FIGHT, scoutHeatmap.GetPositionToScount(), {})
					end
				else
					scoutList.RemoveUnit(unitID)
				end
			end
		end
	end	
	
	local newScoutHandler = {
		AddUnit = scoutList.AddUnit,
		RemoveUnit = scoutList.RemoveUnit,
		GetTotalCost = scoutList.GetTotalCost,
		RunJobHandler = RunJobHandler,
	}
	
	return newScoutHandler
end

return scoutHandler