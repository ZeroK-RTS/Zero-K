--[[ Handles force composition and position
 * Should be used both for the enemies of a CAI and its allyteam
 * Maintains heatmaps for static/mobile units which are anti land/AA.
--]]
local HeatmapUnitDefID, ListUnitDefID = VFS.Include("LuaRules/Configs/CAI/assetTrackerConfig.lua")

local UnitListHandler = VFS.Include("LuaRules/Gadgets/CAI/UnitListHandler.lua")
local HeatmapHandler = VFS.Include("LuaRules/Gadgets/CAI/HeatmapHandler.lua")

local spGetUnitPosition = Spring.GetUnitPosition

local assetTracker = {}

function assetTracker.CreateAssetTracker(teamID, allyTeamID)

	local totalCostAdded = 0
	local totalCostRemoved = 0

	-- These heatmaps are used for safe pathfinding. Values are weighted by danger
	-- They could be extended with blob detection for AoE attacks and artillery firing.
	-- Blob detection would also allow an economy heatmap.
	local unitHeatmaps = {
		mobileAntiAir = HeatmapHandler.CreateHeatmap(256, teamID),
		staticAntiAir = HeatmapHandler.CreateHeatmap(256, teamID),
		mobileLand = HeatmapHandler.CreateHeatmap(256, teamID),
		staticLand = HeatmapHandler.CreateHeatmap(256, teamID),
	}
	
	-- This list contains every unit exactly once. Values are cost.
	local completeUnitList = {
		antiAirTurret = UnitListHandler.CreateUnitList(true),
		turret = UnitListHandler.CreateUnitList(true),
		economy = UnitListHandler.CreateUnitList(true),
		largeStructure = UnitListHandler.CreateUnitList(true),
		miscStructure = UnitListHandler.CreateUnitList(true),
		constructor = UnitListHandler.CreateUnitList(false),
		raider = UnitListHandler.CreateUnitList(false),
		assault = UnitListHandler.CreateUnitList(false),
		skirm = UnitListHandler.CreateUnitList(false),
		antiSkirm = UnitListHandler.CreateUnitList(false),
		riot = UnitListHandler.CreateUnitList(false),
		arty = UnitListHandler.CreateUnitList(false),
		antiAir = UnitListHandler.CreateUnitList(false),
		fighter = UnitListHandler.CreateUnitList(false),
		bomber = UnitListHandler.CreateUnitList(false),
		gunship = UnitListHandler.CreateUnitList(false),
		transport = UnitListHandler.CreateUnitList(false),
		miscUnit = UnitListHandler.CreateUnitList(false),
	}
	
	function AddUnit(unitID, unitDefID)
		--local str = ""
		if HeatmapUnitDefID[unitDefID] then
			local data = HeatmapUnitDefID[unitDefID]
			local i = 1
			local x,_,z = spGetUnitPosition(unitID)
			while data[i] do
				local heatmapData = data[i]
				unitHeatmaps[heatmapData.name].AddUnitHeat(unitID, x, z, heatmapData.radius, heatmapData.amount)
				i = i + 1
				--str = str .. heatmapData.name .. ", "
			end
		end
		local listData = ListUnitDefID[unitDefID]
		completeUnitList[listData.name].AddUnit(unitID, false, listData.cost)
		totalCostRemoved = totalCostRemoved + listData.cost
		--str = str .. "List: " .. listData.name
		--GG.UnitEcho(unitID, str)
	end
	
	function RemoveUnit(unitID, unitDefID)
		if HeatmapUnitDefID[unitDefID] then
			local data = HeatmapUnitDefID[unitDefID]
			local i = 1
			local x,_,z = spGetUnitPosition(unitID)
			while data[i] do
				local heatmapData = data[i]
				unitHeatmaps[heatmapData.name].RemoveUnitHeat(unitID)
				i = i + 1
				--str = str .. heatmapData.name .. ", "
			end
		end
		local listData = ListUnitDefID[unitDefID]
		completeUnitList[listData.name].AddUnit(unitID)
		totalCostAdded = totalCostAdded + listData.cost
	end
	
	function UpdateHeatmaps()
		heatmaps.mobileAA.UpdateUnitPositions(true)
		heatmaps.mobileLand.UpdateUnitPositions(true)
	end
	
	local newAssetTracker = {
		AddUnit = AddUnit,
	
	}
	
	return newAssetTracker
end

return assetTracker