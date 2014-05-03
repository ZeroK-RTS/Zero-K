--[[ Handles force composition and position
 * Should be used both for the enemies of a CAI and its allyteam
 * Maintains heatmaps for static/mobile units which are anti land/AA.
--]]
local HeatmapUnitDefID, ListUnitDefID = VFS.Include("LuaRules/Configs/CAI/assetTrackerConfig.lua")

local UnitListHandler = VFS.Include("LuaRules/Gadgets/CAI/UnitListHandler.lua")
local HeatmapHandler = VFS.Include("LuaRules/Gadgets/CAI/HeatmapHandler.lua")

local spGetUnitPosition = Spring.GetUnitPosition

local assetTracker = {}

function assetTracker.CreateAssetTracker(losCheckAllyTeamID, teamID)

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
		antiAirTurret = UnitListHandler.CreateUnitList(losCheckAllyTeamID, true),
		turret = UnitListHandler.CreateUnitList(losCheckAllyTeamID, true),
		economy = UnitListHandler.CreateUnitList(losCheckAllyTeamID, true),
		largeStructure = UnitListHandler.CreateUnitList(losCheckAllyTeamID, true),
		miscStructure = UnitListHandler.CreateUnitList(losCheckAllyTeamID, true),
		constructor = UnitListHandler.CreateUnitList(losCheckAllyTeamID, false),
		raider = UnitListHandler.CreateUnitList(losCheckAllyTeamID, false),
		assault = UnitListHandler.CreateUnitList(losCheckAllyTeamID, false),
		skirm = UnitListHandler.CreateUnitList(losCheckAllyTeamID, false),
		antiSkirm = UnitListHandler.CreateUnitList(losCheckAllyTeamID, false),
		riot = UnitListHandler.CreateUnitList(losCheckAllyTeamID, false),
		arty = UnitListHandler.CreateUnitList(losCheckAllyTeamID, false),
		antiAir = UnitListHandler.CreateUnitList(losCheckAllyTeamID, false),
		fighter = UnitListHandler.CreateUnitList(losCheckAllyTeamID, false),
		bomber = UnitListHandler.CreateUnitList(losCheckAllyTeamID, false),
		gunship = UnitListHandler.CreateUnitList(losCheckAllyTeamID, false),
		transport = UnitListHandler.CreateUnitList(losCheckAllyTeamID, false),
		miscUnit = UnitListHandler.CreateUnitList(losCheckAllyTeamID, false),
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
		completeUnitList[listData.name].AddUnit(unitID, listData.cost)
		totalCostAdded = totalCostAdded + listData.cost
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
		completeUnitList[listData.name].RemoveUnit(unitID)
		totalCostRemoved = totalCostRemoved + listData.cost
	end
	
	function UpdateHeatmaps()
		heatmaps.mobileAA.UpdateUnitPositions(true)
		heatmaps.mobileLand.UpdateUnitPositions(true)
	end
	
	function GetUnitList(name)
		return completeUnitList[name]
	end
	
	function GetHeatmap(name)
		return unitHeatmaps[name]
	end
	
	local newAssetTracker = {
		AddUnit = AddUnit,
		UpdateHeatmaps = UpdateHeatmaps,
		GetUnitList = GetUnitList, 
		GetHeatmap = GetHeatmap,
	}
	
	return newAssetTracker
end

return assetTracker