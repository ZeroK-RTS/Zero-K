--[[ Handles the scouting unit job
 * Add units to this handler to have them controled by it.
 * Maintains a heatmap of locations to scout.
 * Requires perdiodic UpdateHeatmap and RunJobHandler.
 * Only one of these is needed per teamID.
--]]
local HeatmapHandler = VFS.Include("LuaRules/Gadgets/CAI/HeatmapHandler.lua")

local spIsPosInLos = Spring.IsPosInLos

local scoutHeatmapHandler = {}

function scoutHeatmapHandler.CreateScoutHeatmap(allyTeamID)

	local SCOUT_DECAY_TIME = 2000

	local scoutHeatmap = HeatmapHandler.CreateHeatmap(512, false, true, -SCOUT_DECAY_TIME)
	
	local HEAT_SIZE_X = scoutHeatmap.HEAT_SIZE_X
	local HEAT_SIZE_Z = scoutHeatmap.HEAT_SIZE_Z
	
	local TOTAL_HEAT_POINTS = HEAT_SIZE_X*HEAT_SIZE_Z
	
	local unscoutedPoints = {}
	local unscoutedCount = 0
	local unscoutedUnweightedCount = 0

	local function AddUnscoutedPoint(i,j, pos)
		unscoutedCount = unscoutedCount + 1
		unscoutedPoints[unscoutedCount] = pos
		if i <= 1 or HEAT_SIZE_X - i <= 2 then -- twice really weights towards the corners
			unscoutedCount = unscoutedCount + 1
			unscoutedPoints[unscoutedCount] = pos
		end
		if j <= 1 or HEAT_SIZE_Z - j <= 2 then -- weight scouting towards the edges
			unscoutedCount = unscoutedCount + 1
			unscoutedPoints[unscoutedCount] = pos
		end
	end
	
	local function UpdateHeatmap(GameFrameUpdate)
		unscoutedCount = 0
		unscoutedUnweightedCount = 0
		for i, j in scoutHeatmap.Iterator() do
			local x, y, z = scoutHeatmap.ArrayToWorld(i,j)
			if spIsPosInLos(x, 0, z, allyTeamID) then
				scoutHeatmap.SetHeatPointByIndex(i, j, GameFrameUpdate)
			else
				if scoutHeatmap.GetValueByIndex(i, j) + SCOUT_DECAY_TIME < GameFrameUpdate then
					unscoutedUnweightedCount = unscoutedUnweightedCount + 1
					AddUnscoutedPoint(i,j, {x, y, z})
				end
			end
		end
	end
	
	local function IsScoutingRequired()
		return unscoutedCount > 0
	end
	
	local function GetScoutedProportion()
		return 1 - unscoutedUnweightedCount/TOTAL_HEAT_POINTS
	end
	
	local function GetPositionToScount()
		if unscoutedCount == 0 then
			return false
		end
		local randIndex = math.floor(math.random(1,unscoutedCount))
		return unscoutedPoints[randIndex]
	end
	
	local newScoutHeatmap = {
		UpdateHeatmap = UpdateHeatmap,
		RunJobHandler = RunJobHandler,
		IsScoutingRequired = IsScoutingRequired,
		GetScoutedProportion = GetScoutedProportion,
		GetPositionToScount = GetPositionToScount,
	}
	
	return newScoutHeatmap
end

return scoutHeatmapHandler
