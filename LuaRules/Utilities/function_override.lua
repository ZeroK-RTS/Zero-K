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
