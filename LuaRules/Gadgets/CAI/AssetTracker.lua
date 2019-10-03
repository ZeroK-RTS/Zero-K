--[[ Handles force composition and position
 * Should be used both for the enemies of a CAI and its allyTeam
 * Maintains heatmaps for static/mobile units which are anti land/AA.
--]]
local HeatmapUnitDefID, ListUnitDefID, CombatListUnitDefID, EconomyTargetUnitDefID = VFS.Include("LuaRules/Configs/CAI/assetTrackerConfig.lua")
local StaticUnits = VFS.Include("LuaRules/Configs/CAI/unitMovetype.lua")

local UnitListHandler = VFS.Include("LuaRules/Gadgets/CAI/UnitListHandler.lua")
local HeatmapHandler = VFS.Include("LuaRules/Gadgets/CAI/HeatmapHandler.lua")
local UnitClusterHandler = VFS.Include("LuaRules/Gadgets/CAI/UnitClusterHandler.lua")

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
		turretAA = UnitListHandler.CreateUnitList(losCheckAllyTeamID),
		turret = UnitListHandler.CreateUnitList(losCheckAllyTeamIDe),
		economy = UnitListHandler.CreateUnitList(losCheckAllyTeamID),
		miscStructure = UnitListHandler.CreateUnitList(losCheckAllyTeamID),
		constructor = UnitListHandler.CreateUnitList(losCheckAllyTeamID),
		commander = UnitListHandler.CreateUnitList(losCheckAllyTeamID),
		ground = UnitListHandler.CreateUnitList(losCheckAllyTeamID),
		antiAir = UnitListHandler.CreateUnitList(losCheckAllyTeamID),
		air = UnitListHandler.CreateUnitList(losCheckAllyTeamID),
		fighter = UnitListHandler.CreateUnitList(losCheckAllyTeamID),
		miscUnit = UnitListHandler.CreateUnitList(losCheckAllyTeamID),
	}
	
	-- Contains every combat unit exactly once
	local combatUnitList = {
		raider = UnitListHandler.CreateUnitList(losCheckAllyTeamID),
		assault = UnitListHandler.CreateUnitList(losCheckAllyTeamID),
		skirm = UnitListHandler.CreateUnitList(losCheckAllyTeamID),
		antiSkirm = UnitListHandler.CreateUnitList(losCheckAllyTeamID),
		riot = UnitListHandler.CreateUnitList(losCheckAllyTeamID),
		arty = UnitListHandler.CreateUnitList(losCheckAllyTeamID),
		antiAir = UnitListHandler.CreateUnitList(losCheckAllyTeamID),
		bomber = UnitListHandler.CreateUnitList(losCheckAllyTeamID),
		gunship = UnitListHandler.CreateUnitList(losCheckAllyTeamID),
		transport = UnitListHandler.CreateUnitList(losCheckAllyTeamID),
		fighter = UnitListHandler.CreateUnitList(losCheckAllyTeamID),
		commander = UnitListHandler.CreateUnitList(losCheckAllyTeamID),
	}
	
	local economyTargets = UnitClusterHandler.CreateUnitCluster(losCheckAllyTeamID, 800)
	
	local function AddUnit(unitID, unitDefID)
		local str = ""
		-- Heatmap
		if HeatmapUnitDefID[unitDefID] then
			local data = HeatmapUnitDefID[unitDefID]
			local i = 1
			local x,_,z = spGetUnitPosition(unitID)
			while data[i] do
				local heatmapData = data[i]
				unitHeatmaps[heatmapData.name].AddUnitHeat(unitID, x, z, heatmapData.radius, heatmapData.amount)
				i = i + 1
				str = str .. heatmapData.name .. ", "
			end
		end
		
		-- Complete unit list
		local listData = ListUnitDefID[unitDefID]
		completeUnitList[listData.name].AddUnit(unitID, listData.cost, StaticUnits[unitDefID])
		totalCostAdded = totalCostAdded + listData.cost
		str = str .. "List: " .. listData.name
		
		-- Combat unit list
		local combatListData = CombatListUnitDefID[unitDefID]
		if combatListData then
			combatUnitList[combatListData.name].AddUnit(unitID, combatListData.cost, StaticUnits[unitDefID])
			str = str .. ", Combat List: " .. combatListData.name
		end
		
		-- Economy tagets
		local economyTargetData = EconomyTargetUnitDefID[unitDefID]
		if economyTargetData then
			economyTargets.AddUnit(unitID, economyTargetData.amount, StaticUnits[unitDefID])
			str = str .. ", Economy Cluster Unit"
		end
		
		GG.UnitEcho(unitID, str)
	end
	
	local function RemoveUnit(unitID, unitDefID)
		-- Heatmap
		if HeatmapUnitDefID[unitDefID] then
			local data = HeatmapUnitDefID[unitDefID]
			local i = 1
			local x,_,z = spGetUnitPosition(unitID)
			while data[i] do
				local heatmapData = data[i]
				unitHeatmaps[heatmapData.name].RemoveUnitHeat(unitID)
				i = i + 1
			end
		end
		
		-- Complete unit list
		local listData = ListUnitDefID[unitDefID]
		completeUnitList[listData.name].RemoveUnit(unitID)
		totalCostRemoved = totalCostRemoved + listData.cost
		
		-- Combat unit list
		local combatListData = CombatListUnitDefID[unitDefID]
		if combatListData then
			combatUnitList[combatListData.name].RemoveUnit(unitID)
		end
		
		-- Economy tagets
		local economyTargetData = EconomyTargetUnitDefID[unitDefID]
		if economyTargetData then
			economyTargets.RemoveUnit(unitID)
		end
	end
	
	local function UpdateHeatmaps()
		unitHeatmaps.mobileAntiAir.UpdateUnitPositions(true)
		unitHeatmaps.mobileLand.UpdateUnitPositions(true)
	end
	
	local function GetUnitList(name)
		return completeUnitList[name]
	end
	
	local function GetCombatUnitList(name)
		return combatUnitList[name]
	end
	
	local function GetHeatmap(name)
		return unitHeatmaps[name]
	end
	
	local newAssetTracker = {
		AddUnit = AddUnit,
		RemoveUnit = RemoveUnit,
		UpdateHeatmaps = UpdateHeatmaps,
		GetUnitList = GetUnitList,
		GetCombatUnitList = GetCombatUnitList,
		GetHeatmap = GetHeatmap,
	}
	
	return newAssetTracker
end

return assetTracker
