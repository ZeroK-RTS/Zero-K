local RET_FALSE  = function() return false end
local RET_NONE   = function() end
local RET_TABLE  = function() return {} end
local RET_ZERO   = function() return 0 end
local RET_STRING = function() return "" end

--[[ For some reason IsEngineMinVersion breaks on tags where the minor is not 0 (X.1.Y-...),
     though this can only happen for random people's forks since regular BAR & Spring build
     systems both hardcode the minor to 0. Assume we're on bleeding edge in that case. ]]
if not Script.IsEngineMinVersion(1, 0, 0) then
	Script.IsEngineMinVersion = function (major, minor, commit)
		return true
	end
end

if Script.IsEngineMinVersion(104, 0, 50) then
	local origGetGroundInfo = Spring.GetGroundInfo
	Spring.GetGroundInfo = function (x, z)
		local r1, r2, r3, r4, r5, r6, r7, r8, r9 = origGetGroundInfo(x, z)
		return r2, r3, r4, r5, r6, r7, r8, r9, r1
	end

	local origGetTerrainTypeData = Spring.GetTerrainTypeData
	Spring.GetTerrainTypeData = function (index)
		local r1, r2, r3, r4, r5, r6, r7, r8 = origGetTerrainTypeData(index)
		return r2, r3, r4, r5, r6, r7, r8, r1
	end
end

if not Script.IsEngineMinVersion(104, 0, 503) then
	local tableCache = {123}
	local function MakeWrappedSingleParamFunc(originalFunc)
		return function (unitID, cmdID, cmdParam, cmdOpts)
			-- unitID can actually be a table thereof, but we don't mind
			if type (cmdParam) ~= "table" then
				tableCache[1] = cmdParam
				return originalFunc(unitID, cmdID, tableCache, cmdOpts)
			else
				return originalFunc(unitID, cmdID, cmdParam, cmdOpts)
			end
		end
	end
	local function MakeWrappedArrayParamFunc(originalFunc)
		return function (units, orders)
			for i = 1, #orders do
				local order = orders[i]
				local param = order[2]
				if type(param) ~= "table" then
					order[2] = {param}
				end
			end
			return originalFunc(units, orders)
		end
	end

	local originalGiveOrder = Spring.GiveOrder
	Spring.GiveOrder = function(cmdID, cmdParam, cmdOpts)
		if type (cmdParam) ~= "table" then
			tableCache[1] = cmdParam
			return originalGiveOrder(cmdID, tableCache, cmdOpts)
		else
			return originalGiveOrder(cmdID, cmdParam, cmdOpts)
		end
	end

	Spring.GiveOrderToUnit      = MakeWrappedSingleParamFunc(Spring.GiveOrderToUnit     )
	Spring.GiveOrderToUnitMap   = MakeWrappedSingleParamFunc(Spring.GiveOrderToUnitMap  )
	Spring.GiveOrderToUnitArray = MakeWrappedSingleParamFunc(Spring.GiveOrderToUnitArray)

	Spring.GiveOrderArrayToUnitMap   = MakeWrappedArrayParamFunc(Spring.GiveOrderArrayToUnitMap  )
	Spring.GiveOrderArrayToUnitArray = MakeWrappedArrayParamFunc(Spring.GiveOrderArrayToUnitArray)
end

if Script.IsEngineMinVersion(104, 0, 536) then
	local origGetPlayerInfo = Spring.GetPlayerInfo
	Spring.GetPlayerInfo = function (playerID)
		if not playerID then
			return
		end
		local r1, r2, r3, r4, r5, r6, r7, r8, r9, r10, r11, r12 = origGetPlayerInfo(playerID)
		return r1, r2, r3, r4, r5, r6, r7, r8, r9, r11, r10, r12
	end
end

Game.speedModClasses = Game.speedModClasses or -- 104-756
	{ Tank  = 0
	, KBot  = 1
	, Hover = 2
	, Boat  = 3
	, Ship  = 3
}

if not Script.IsEngineMinVersion(104, 0, 1100) then
	Script.SetWatchProjectile  = Script.SetWatchWeapon
	Script.SetWatchExplosion   = Script.SetWatchWeapon
	Script.SetWatchAllowTarget = Script.SetWatchWeapon
end

if not Script.IsEngineMinVersion(104, 0, 1143) then
	local spGetCommandQueue = Spring.GetCommandQueue
	local unpacc = unpack
	Spring.GetUnitCurrentCommand = function (unitID, index)
		index = index or 1

		local queue = spGetCommandQueue(unitID, index)
		if not queue then
			return
		end

		local command = queue[index]
		if not command then
			return
		end

		return command.id, command.options.coded, command.tag, unpacc(command.params)
	end
end

if Script.IsEngineMinVersion(104, 0, 1166) then
	local origGetTeamInfo = Spring.GetTeamInfo
	Spring.GetTeamInfo = function (p1, p2)
		local r1, r2, r3, r4, r5, r6, r7, r8 = origGetTeamInfo(p1, p2)
		return r1, r2, r3, r4, r5, r6, r8, r7
	end
end

if not math.tau then -- 104-1421 AFAICT
	math.tau = 2 * math.pi
end

if not Spring.SetUnitBuildParams and Script.GetSynced() then -- BAR 105-552
	Spring.SetUnitBuildParams = RET_NONE
end
if not Spring.GetUnitBuildParams then -- BAR 105-552
	Spring.GetUnitBuildParams = RET_ZERO
end

if not Spring.GetUnitsInScreenRectangle and not Script.GetSynced() then -- BAR 105-637
	Spring.GetUnitsInScreenRectangle = RET_TABLE
end

if not Spring.SetUnitNoEngineDraw then -- BAR 105-653
	Spring.SetUnitNoEngineDraw    = RET_NONE
	Spring.SetFeatureNoEngineDraw = RET_NONE
end
if not Spring.GetUnitNoEngineDraw and not Script.GetSynced() then -- BAR 105-653
	Spring.GetUnitNoEngineDraw    = RET_FALSE
	Spring.GetFeatureNoEngineDraw = RET_FALSE
end

if not Spring.GetUnitInBuildStance then -- BAR 105-665
	Spring.GetUnitInBuildStance = RET_FALSE
end

if not Spring.ForceTesselationUpdate and not Script.GetSynced() then -- BAR 105-710
	--[[ This is just here so gadget code can avoid
	     a nil check. The workaround was to apply
	     ground detail changes to force an update,
	     but that requires a timed delay (since else
	     the change isn't noticed) which I am not
	     going to reimplement here. ]]
	Spring.ForceTesselationUpdate = RET_FALSE
end

if not Spring.SetWindowGeometry then -- BAR 105-733
	Spring.SetWindowGeometry = RET_NONE
end

if not Spring.UnitIconGetDraw and not Script.GetSynced() then -- BAR 105-800
	Spring.UnitIconGetDraw = RET_FALSE
end
if not Spring.UnitIconSetDraw then -- BAR 105-800
	Spring.UnitIconSetDraw = RET_NONE
end

if not Spring.GetTimerMicros and not Script.GetSynced() then -- BAR 105-916
	Spring.GetTimerMicros = RET_ZERO
end

if not Spring.LevelOriginalHeightMap and Script.GetSynced() then -- BAR 105-946
	-- NB: no Get here
	Spring.LevelOriginalHeightMap   = RET_NONE
	Spring.AdjustOriginalHeightMap  = RET_NONE
	Spring.RevertOriginalHeightMap  = RET_NONE
	Spring.AddOriginalHeightMap     = RET_ZERO
	Spring.SetOriginalHeightMap     = RET_ZERO
	Spring.SetOriginalHeightMapFunc = RET_ZERO
end

if not Spring.AddUnitExperience and Script.GetSynced() then -- BAR 105-961
	local spGetUnitExperience = Spring.GetUnitExperience
	local spSetUnitExperience = Spring.SetUnitExperience
	Spring.AddUnitExperience = function (unitID, deltaXP)
		spSetUnitExperience(unitID, spGetUnitExperience(unitID) + deltaXP)
	end
end

if not Spring.SetBoxSelectionByEngine and not Script.GetSynced() then -- BAR 105-980
	Spring.SetBoxSelectionByEngine = RET_NONE
	Spring.GetBoxSelectionByEngine = RET_FALSE
end

if not Spring.SetFactoryBuggerOff and Script.GetSynced() then -- BAR 105-1029
	Spring.SetFactoryBuggerOff = RET_FALSE
end

if not Spring.BuggerOff and Script.GetSynced() then -- BAR 105-1029
	Spring.BuggerOff = RET_NONE
end

if not Spring.GetFactoryBuggerOff then -- BAR 105-1029
	Spring.GetFactoryBuggerOff = function()
		return false, 0, 1, 0, false, false, false
	end
end

if not Spring.GetSyncedGCInfo and not Script.GetSynced() then -- BAR 105-1131
	Spring.GetSyncedGCInfo = RET_ZERO
end

if not Spring.GetKeyFromScanSymbol and not Script.GetSynced() then -- BAR 105-1169
	Spring.GetKeyFromScanSymbol = RET_STRING
end

if not Spring.GetSelectionBox and not Script.GetSynced() then -- BAR 105-1193
	Spring.GetSelectionBox = RET_NONE
end

if not Spring.GetPressedScans and not Script.GetSynced() then -- BAR 105-1199
	Spring.GetPressedScans = RET_TABLE
end

if not Spring.GetCameraRotation and not Script.GetSynced() then -- BAR 105-1242
	local spGetCameraDirection = Spring.GetCameraDirection
	local acos = math.acos
	local atan2 = math.atan2
	local sqrt = math.sqrt
	Spring.GetCameraRotation = function()
		local x, y, z = spGetCameraDirection()
		local len = sqrt(x^2 + y^2 + z^2)
		return acos(y / len), atan2(x / len, -z / len), 0
	end
end

if not Spring.GetMiniMapRotation and not Script.GetSynced() then -- BAR 105-1242
	Spring.GetMiniMapRotation = RET_ZERO
end

if not Spring.LoadModelTextures and not Script.GetSynced() then -- BAR 105-1244
	Spring.LoadModelTextures = RET_FALSE
end

if not Spring.SetWindowMinimized and not Script.GetSynced() then -- BAR 105-1245
	Spring.SetWindowMinimized = RET_FALSE
	Spring.SetWindowMaximized = RET_FALSE
end

if not Spring.GiveOrderArrayToUnit then -- BAR 105-1492
	local spGiveOrderArrayToUnitArray = Spring.GiveOrderArrayToUnitArray
	local staticTable = {123}
	Spring.GiveOrderArrayToUnit = function (unitID, orderArray)
		staticTable[1] = unitID
		return spGiveOrderArrayToUnitArray(staticTable, orderArray)
	end
end

Game.metalMapSquareSize = Game.metalMapSquareSize or 16 -- BAR 105-1505

if not Spring.SetUnitHeadingAndUpDir and Script.GetSynced() then -- BAR 105-1611
	Spring.SetUnitHeadingAndUpDir    = RET_NONE
	Spring.SetFeatureHeadingAndUpDir = RET_NONE
end

if not Script.GetSynced() and not Script.IsEngineMinVersion(105, 0, 1621) then
	local originalGetSelectedUnitsSorted = Spring.GetSelectedUnitsSorted
	Spring.GetSelectedUnitsSorted = function()
		local units = originalGetSelectedUnitsSorted()
		local n = units.n
		units.n = nil
		return units, n
	end

	local originalGetSelectedUnitsCounts = Spring.GetSelectedUnitsCounts
	Spring.GetSelectedUnitsCounts = function()
		local units = originalGetSelectedUnitsCounts()
		local n = units.n
		units.n = nil
		return units, n
	end
end

if not Spring.GetFeaturesInScreenRectangle and not Script.GetSynced() then -- BAR 105-1649
	Spring.GetFeaturesInScreenRectangle = RET_TABLE
end

if Script.GetSynced() and not Script.IsEngineMinVersion(105, 0, 1706) then
	local inTransfer = false
	local originalTransferUnit = Spring.TransferUnit
	Spring.TransferUnit = function(unitID, teamID, captured)
		if inTransfer then
			return
		end
		inTransfer = true
		originalTransferUnit(unitID, teamID, captured)
		inTransfer = false
	end
end

if not Script.GetSynced() and not Script.IsEngineMinVersion(105, 0, 1719) then
	local originalSetActiveCommand = Spring.SetActiveCommand
	Spring.SetActiveCommand = function(...)
		if not select(1, ...) then
			return originalSetActiveCommand(-1)
		else
			return originalSetActiveCommand(...)
		end
	end
end

Game.footprintScale  = Game.footprintScale  or  2 -- BAR 105-1725
Game.buildSquareSize = Game.buildSquareSize or 16 -- BAR 105-1725

if not Script.IsEngineMinVersion(105, 0, 1776) then
	local originalSetSunDirection = Spring.SetSunDirection
	Spring.SetSunDirection = function (x, y, z, a)
		local n = math.diag(x, y, z)
		return originalSetSunDirection(x / n, y / n, z / n, a)
	end
end

if not Spring.SetUnitSeismicSignature and Script.GetSynced() then -- BAR 105-1777
	Spring.SetUnitSeismicSignature = RET_NONE
end
if not Spring.GetUnitSeismicSignature then -- BAR 105-1777
	Spring.GetUnitSeismicSignature = RET_ZERO
end

if not Spring.SelectUnit and not Script.GetSynced() then -- BAR 105-1790
	local spSelectUnitArray = Spring.SelectUnitArray
	Spring.SelectUnit = function (unitID, append)
		return spSelectUnitArray({unitID}, append)
	end

	local spGetSelectedUnits = Spring.GetSelectedUnits
	Spring.DeselectUnit = function (unitID)
		local selected = spGetSelectedUnits()
		for i = 1, #selected do
			if selected[i] == unitID then
				selected[i] = selected[#selected]
				selected[#selected] = nil
				spSelectUnitArray(selected)
				return
			end
		end
	end
end

if not Spring.GetUnitWorkerTask then -- BAR 105-1793
	local spGetUnitCurrentCommand = Spring.GetUnitCurrentCommand
	Spring.GetUnitWorkerTask = function(unitID)
		local cmdID, _, _, targetID = spGetUnitCurrentCommand(unitID)
		return cmdID, targetID
	end
end

if not Spring.SetUnitShieldRechargeDelay and Script.GetSynced() then -- BAR 105-1799
	Spring.SetUnitShieldRechargeDelay = RET_NONE
end

if not Spring.SetPlayerRulesParam and Script.GetSynced() then -- BAR 105-1803
	local spSetGameRulesParam = Spring.SetGameRulesParam
	Spring.SetPlayerRulesParam = function (playerID, key, value)
		return spSetGameRulesParam("playerRulesParam_" .. playerID .. "_" .. key, value)
	end
end

if not Spring.GetPlayerRulesParam then -- BAR 105-1803
	local spGetGameRulesParam = Spring.GetGameRulesParam
	Spring.GetPlayerRulesParam = function (playerID, key)
		return spGetGameRulesParam("playerRulesParam_" .. playerID .. "_" .. key)
	end
end
