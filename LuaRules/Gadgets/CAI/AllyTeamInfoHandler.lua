--[[ 
 Handles all the information about force composition and 
 position for both an allyTeam and enemies of that allyTeam.
--]]
local AssetTracker = VFS.Include("LuaRules/Gadgets/CAI/AssetTracker.lua")
local ScoutHeatmapHandler = VFS.Include("LuaRules/Gadgets/CAI/ScoutHeatmapHandler.lua")

local spGetUnitAllyTeam = Spring.GetUnitAllyTeam


local AllyTeamInfoHandler = {}


function AllyTeamInfoHandler.CreateAllyTeamInfoHandler(allyTeamID, teamID)
	
	local allyInfo = assetTracker.CreateAssetTracker(allyTeamID, teamID)
	local enemyInfo = assetTracker.CreateAssetTracker(allyTeamID, teamID)
	local scoutHeatmap = ScoutHeatmapHandler.CreateScoutHeatmap(allyTeamID)

	function AddUnit(unitID, unitDefID)
		if spGetUnitAllyTeam(unitID) == allyTeamID then
			allyInfo.AddUnit(unitID, unitDefID)
		else
			enemyInfo.AddUnit(unitID, unitDefID)
		end
	end
	
	function RemoveUnit(unitID, unitDefID)
		if spGetUnitAllyTeam(unitID) == allyTeamID then
			allyInfo.RemoveUnit(unitID, unitDefID)
		else
			enemyInfo.RemoveUnit(unitID, unitDefID)
		end
	end
	
	function UnitUpdate()
		allyInfo.UpdateHeatmaps()
		enemyInfo.UpdateHeatmaps()
	end
	
	function ScoutUpdate(gameFrame)
		scoutHeatmap.UpdateHeatmap(gameFrame)
	end
	
	local newAllyTeamInfoHandler = {
		AddUnit = AddUnit,
		RemoveUnit = RemoveUnit,
		UnitUpdate = UnitUpdate,
		ScoutUpdate = ScoutUpdate,
		
		scoutHeatmap = scoutHeatmap,
	}
	
	return newAllyTeamInfoHandler
end

return AllyTeamInfoHandler