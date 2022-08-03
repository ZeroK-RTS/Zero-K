-----------------------------------------------------------------------------------
-----------------------------------------------------------------------------------
-- Overrides some inbuilt spring functions

VFS.Include("LuaRules/Utilities/versionCompare.lua", nil, VFS.GAME)

-----------------------------------------------------------------------------------
-----------------------------------------------------------------------------------

local function SetPlayerRulesParam(playerID, key, value)
	return Spring.SetGameRulesParam("playerRulesParam_" .. playerID .. "_" .. key, value)
end
local function GetPlayerRulesParam(playerID, key)
	return Spring.GetGameRulesParam("playerRulesParam_" .. playerID .. "_" .. key)
end
if not Spring.SetPlayerRulesParam then
	Spring.SetPlayerRulesParam = SetPlayerRulesParam
end
if not Spring.GetPlayerRulesParam then
	Spring.GetPlayerRulesParam = GetPlayerRulesParam
end

-----------------------------------------------------------------------------------
-----------------------------------------------------------------------------------
-- Scaling
-- hack window geometry

-- gl.GetViewSizes intentionally not overridden
Spring.Orig = Spring.Orig or {}
Spring.Orig.GetWindowGeometry = Spring.GetWindowGeometry
Spring.Orig.GetViewGeometry = Spring.GetViewGeometry
Spring.Orig.GetViewSizes = gl and gl.GetViewSizes

Spring.GetWindowGeometry = function()
	local vsx, vsy, vx, vy = Spring.Orig.GetWindowGeometry()
	return vsx/((WG and WG.uiScale) or 1), vsy/((WG and WG.uiScale) or 1), vx, vy
end

Spring.GetViewGeometry = function()
	local vsx, vsy, vx, vy = Spring.Orig.GetViewGeometry()
	return vsx/((WG and WG.uiScale) or 1), vsy/((WG and WG.uiScale) or 1), vx, vy
end

Spring.GetViewSizes = function()
	local vsx, vsy = Spring.Orig.GetViewSizes()
	return vsx/(WG.uiScale or 1), vsy/(WG.uiScale or 1), vx, vy
end

Spring.ScaledGetMouseState = function()
	local mx, my, left, right, mid, offscreen = Spring.GetMouseState()
	return mx/((WG and WG.uiScale) or 1), my/((WG and WG.uiScale) or 1), left, right, mid, offscreen
end
-----------------------------------------------------------------------------------
-----------------------------------------------------------------------------------

local oldGetGroundExtremes = Spring.GetGroundExtremes

Spring.GetGroundExtremes = function()
	local minOverride = Spring.GetGameRulesParam("ground_min_override")
	if minOverride then
		return minOverride, Spring.GetGameRulesParam("ground_max_override")
	end
	return oldGetGroundExtremes()
end

-----------------------------------------------------------------------------------
-----------------------------------------------------------------------------------
-- Inspect callout behavour

if false and Spring.SetUnitPosition then -- only in gadget space
	Spring.Echo("FUNCTION_OVERRIDE_LOADING")
	local funcList = {
		--"SetUnitPosition",
		--"SetUnitVelocity",
		--"AddUnitImpulse",
		--"SetUnitPhysics",
		--"SetUnitRulesParam",
		"GiveOrderToUnit",
	}
	
	local unitWhitelist = {
		[18399] = true,
		--[26879] = true,
	}
	
	for i = 1, #funcList do
		local funcName = funcList[i]
		local origFunc = Spring[funcName]
		Spring[funcName] = function (unitID, ...)
			if unitID and unitWhitelist[unitID] and Spring.GetGameFrame() > 27630 then
				Spring.Echo(funcName, unitID)
				Spring.Utilities.TableEcho({...}, "table")
				Spring.Utilities.UnitEcho(unitID)
			end
			origFunc(unitID, ...)
		end
	end
	
	local moveBlackist = {
		["GetTag"] = true,
	}
	
	for funcName, origFunc in pairs(Spring.MoveCtrl) do
		if not moveBlackist[funcName] then
			Spring.Echo("FUNCTION_OVERRIDE_LOADING", funcName)
			Spring.MoveCtrl[funcName] = function (unitID, ...)
				if unitID and unitWhitelist[unitID] and Spring.GetGameFrame() > 27630 then
					Spring.Echo(funcName, unitID)
					Spring.Utilities.TableEcho({...}, "table")
					Spring.Utilities.UnitEcho(unitID)
				end
				origFunc(unitID, ...)
			end
		end
	end
end

-----------------------------------------------------------------------------------
-----------------------------------------------------------------------------------

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

if Script.IsEngineMinVersion(104, 0, 536) then
	local origGetPlayerInfo = Spring.GetPlayerInfo
	Spring.GetPlayerInfo = function (playerID)
		if not playerID then
			return
		end
		local r1, r2, r3, r4, r5, r6, r7, r8, r9, r10, r11 = origGetPlayerInfo(playerID)
		return r1, r2, r3, r4, r5, r6, r7, r8, r9, r11, r10
	end
end

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

if not Spring.ForceTesselationUpdate and not Script.GetSynced() then -- BAR 105-710
	Spring.ForceTesselationUpdate = function ()
		--[[ This is just here so gadget code can avoid
		     a nil check. The workaround was to apply
		     ground detail changes to force an update,
		     but that requires a timed delay (since else
		     the change isn't noticed) which I am not
		     going to reimplement here. ]]
		return false
	end
end

if not Spring.AddUnitExperience and Script.GetSynced() then -- BAR 105-961
	local spGetUnitExperience = Spring.GetUnitExperience
	local spSetUnitExperience = Spring.SetUnitExperience
	Spring.AddUnitExperience = function (unitID, deltaXP)
		spSetUnitExperience(unitID, spGetUnitExperience(unitID) + deltaXP)
	end
end
