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