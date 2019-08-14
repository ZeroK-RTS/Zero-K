--[[
 Handles all the information about force composition and
 position for both an allyTeam and enemies of that allyTeam.
--]]
local AssetTracker = VFS.Include("LuaRules/Gadgets/CAI/AssetTracker.lua")
local ScoutHeatmapHandler = VFS.Include("LuaRules/Gadgets/CAI/ScoutHeatmapHandler.lua")
local ScoutHandler = VFS.Include("LuaRules/Gadgets/CAI/ScoutHandler.lua")

local spGetUnitAllyTeam = Spring.GetUnitAllyTeam

local AllyTeamInfoHandler = {}

function AllyTeamInfoHandler.CreateAllyTeamInfoHandler(allyTeamID, teamID, pathfinder)
	
	local allyInfo = AssetTracker.CreateAssetTracker(allyTeamID, teamID)
	local enemyInfo = AssetTracker.CreateAssetTracker(allyTeamID, teamID)
	local scoutHeatmap = ScoutHeatmapHandler.CreateScoutHeatmap(allyTeamID)
	local scoutHandler = ScoutHandler.CreateScoutHandler(scoutHeatmap)

	local function AddUnit(unitID, unitDefID)
		if spGetUnitAllyTeam(unitID) == allyTeamID then
			allyInfo.AddUnit(unitID, unitDefID)
		else
			enemyInfo.AddUnit(unitID, unitDefID)
		end
	end
	
	local function RemoveUnit(unitID, unitDefID)
		if spGetUnitAllyTeam(unitID) == allyTeamID then
			allyInfo.RemoveUnit(unitID, unitDefID)
		else
			enemyInfo.RemoveUnit(unitID, unitDefID)
		end
	end
	
	local function UnitUpdate()
		allyInfo.UpdateHeatmaps()
		enemyInfo.UpdateHeatmaps()
	end
	
	local function AddScout(unitID)
		scoutHandler.AddUnit(unitID)
	end
	
	local function RemoveScout(unitID)
		scoutHandler.RemoveUnit(unitID)
	end
	
	local function UnitCreatedUpdate(unitID, unitDefID, unitTeam)
		AddUnit(unitID, unitDefID)
	end
	
	local function UnitDestroyedUpdate(unitID, unitDefID, unitTeam)
		RemoveUnit(unitID, unitDefID)
	end
	
	local function GameFrameUpdate(n)
		if n%60 == 14 then
			scoutHeatmap.UpdateHeatmap(n)
			scoutHandler.RunJobHandler()
		end
		if n%30 == 3 then
			enemyInfo.UpdateHeatmaps()
		end
	end
	
	local newAllyTeamInfoHandler = {
		AddUnit = AddUnit,
		RemoveUnit = RemoveUnit,
		UnitUpdate = UnitUpdate,
		
		AddScout = AddScout,
		RemoveScout = RemoveScout,
		
		GameFrameUpdate = GameFrameUpdate,
		UnitCreatedUpdate = UnitCreatedUpdate,
		UnitDestroyedUpdate = UnitDestroyedUpdate,
		
		pathfinder = pathfinder,
		scoutHeatmap = scoutHeatmap,
	}
	
	return newAllyTeamInfoHandler
end

return AllyTeamInfoHandler
