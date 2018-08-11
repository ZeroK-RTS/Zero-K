-----------------------------------------------------------------------------------
-----------------------------------------------------------------------------------
-- Overrides some inbuilt spring functions

VFS.Include("LuaRules/Utilities/versionCompare.lua")

-----------------------------------------------------------------------------------
-----------------------------------------------------------------------------------
local origValidUnitID = Spring.ValidUnitID

local function newValidUnitID(unitID)
	return unitID and origValidUnitID(unitID)
end

Spring.ValidUnitID = newValidUnitID

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
if Spring.Utilities.IsCurrentVersionNewerThan(100, 0) then
	Spring.MoveCtrl = Spring.MoveCtrl or {}
	local origMcSetUnitRotation = Spring.MoveCtrl.SetRotation
	local origMcSetUnitRotationVelocity = Spring.MoveCtrl.SetRotationVelocity

	local function newMcSetUnitRotation(unitID, x, y, z)
		return origMcSetUnitRotation(unitID, -x, -y, -z)
	end

	local function newMcSetUnitRotationVelocity(unitID, x, y, z)
		return origMcSetUnitRotationVelocity(unitID, -x, -y, -z)
	end
	
	Spring.MoveCtrl.SetRotation = newMcSetUnitRotation
	Spring.MoveCtrl.SetRotationVelocity = newMcSetUnitRotationVelocity
end

local origGetGroundInfo = Spring.GetGroundInfo
local function GetGroundInfo(x, z)
	local r1, r2, r3, r4, r5, r6, r7, r8, r9 = origGetGroundInfo(x, z)
	if type(r1) == "string" then
		return r1, r2, r3, r4, r5, r6, r7, r8
	else
		return r2, r3, r4, r5, r6, r7, r8, r9, r1
	end
end
Spring.GetGroundInfo = GetGroundInfo

local origGetTerrainTypeData = Spring.GetTerrainTypeData
local function GetTerrainTypeData(index)
	local r1, r2, r3, r4, r5, r6, r7, r8 = origGetTerrainTypeData(index)
	if type(r1) == "string" then
		return r1, r2, r3, r4, r5, r6, r7
	else
		return r2, r3, r4, r5, r6, r7, r8, r1
	end
end
Spring.GetTerrainTypeData = GetTerrainTypeData

local origGetPlayerInfo = Spring.GetPlayerInfo
local function GetPlayerInfo(playerID)
	local r1, r2, r3, r4, r5, r6, r7, r8, r9, r10, r11 = origGetPlayerInfo(playerID)
	if type(r10) == "table" then
		return r1, r2, r3, r4, r5, r6, r7, r8, r9, r10
	else
		return r1, r2, r3, r4, r5, r6, r7, r8, r9, r11, r10
	end
end
Spring.GetPlayerInfo = GetPlayerInfo
