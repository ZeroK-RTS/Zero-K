--[[ Handles unit listed used by the AI for its own team
 * Contains all the units that the AI can control and none that it cannot control.
 * Maintains cluster maps for defensible structures
--]]
local DefenseRequirementUnitDefID, ListUnitDefID = VFS.Include("LuaRules/Configs/CAI/teamUnitTrackerConfig.lua")
local StaticUnits, MovetypeDefID, Movetypes = VFS.Include("LuaRules/Configs/CAI/unitMovetype.lua")

local UnitListHandler = VFS.Include("LuaRules/Gadgets/CAI/UnitListHandler.lua")
local UnitClusterHandler = VFS.Include("LuaRules/Gadgets/CAI/UnitClusterHandler.lua")

local ScoutHandler = VFS.Include("LuaRules/Gadgets/CAI/ScoutHandler.lua")
local CombatHandler = VFS.Include("LuaRules/Gadgets/CAI/CombatHandler.lua")

local teamUnitTracker = {}

function teamUnitTracker.CreateTeamUnitTracker(teamID, allyTeamID)

	local totalCostAdded = 0
	local totalCostRemoved = 0
	
	-- This list contains every unit exactly once. Values are cost.
	local completeUnitList = {
		turretAA = UnitListHandler.CreateUnitList(),
		turret = UnitListHandler.CreateUnitList(),
		economy = UnitListHandler.CreateUnitList(),
		miscStructure = UnitListHandler.CreateUnitList(),
		constructor = UnitListHandler.CreateUnitList(),
		ground = UnitListHandler.CreateUnitList(),
		antiAir = UnitListHandler.CreateUnitList(),
		air = UnitListHandler.CreateUnitList(),
		fighter = UnitListHandler.CreateUnitList(),
		miscUnit = UnitListHandler.CreateUnitList(),
	}
	
	-- Contains every mobile unit exactly once
	local unitHandlers = {
		scout = CreateScoutHandler(allyTeamID),
		combat = CreateCombatHandler(allyTeamID),
		--artilley
		--constructor
		--bomber
		--fighter
	}
	
	local defenseRequire = UnitClusterHandler.CreateUnitCluster(losCheckAllyTeamID, 300)
	
	local function AddUnit(unitID, unitDefID)
		totalCostAdded = totalCostAdded + listData.cost
		local str = ""
		
		-- Complete unit list
		local listData = ListUnitDefID[unitDefID]
		completeUnitList[listData.name].AddUnit(unitID, listData.cost, StaticUnits[unitDefID])
		str = str .. "List: " .. listData.name
		
		-- Combat unit list
		local combatListData = CombatListUnitDefID[unitDefID]
		if combatListData then
			combatUnitList[combatListData.name].AddUnit(unitID, combatListData.cost, StaticUnits[unitDefID])
			str = str .. ", Combat List: " .. combatListData.name
		end
		
		-- Defense require
		local desenseRequireData = DefenseRequirementUnitDefID[unitDefID]
		if desenseRequireData then
			defenseRequire.AddUnit(unitID, desenseRequireData.amount, StaticUnits[unitDefID])
			str = str .. ", Defense Require Unit"
		end
		
		GG.UnitEcho(unitID, str)
	end
	
	local function RemoveUnit(unitID, unitDefID)
		totalCostRemoved = totalCostRemoved + listData.cost
		
		-- Complete unit list
		local listData = ListUnitDefID[unitDefID]
		completeUnitList[listData.name].RemoveUnit(unitID)
		
		-- Defense require
		local desenseRequireData = DefenseRequirementUnitDefID[unitDefID]
		if desenseRequireData then
			defenseRequire.RemoveUnit(unitID)
		end
	end
	
	
	local function GetUnitList(name)
		return completeUnitList[name]
	end
	
	local function GetCombatUnitList(name)
		return combatUnitList[name]
	end
	
	local newAssetTracker = {
		AddUnit = AddUnit,
		GetUnitList = GetUnitList,
		GetCombatUnitList = GetCombatUnitList,
	}
	
	return newAssetTracker
end

return assetTracker
