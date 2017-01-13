-- $Id: unit_terraform.lua 3299 2008-11-25 07:25:57Z google frog $
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function gadget:GetInfo()
	return {
		name     = "Nano Frame Rate Limit",
		desc     = "Limits the rate at which constructors (not factories or carriers) can make nanoframes.",
		author   = "GoogleFrog",
		date     = "January 10, 2017",
		license  = "GNU GPL, v2 or later",
		layer    = -10,
		enabled  = true
	}
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

if (not gadgetHandler:IsSyncedCode()) then
	return false -- no unsynced code
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local unitLastFrame = {}
local unitLastX = {}
local unitLastZ = {}
local FRAME_GAP = 1

function gadget:AllowUnitCreation(unitDefID, builderID, builderTeam, x, y, z, facing)
	if not builderID then
		return true
	end
	local frame = Spring.GetGameFrame()
	if (not unitLastFrame[builderID]) or frame >= unitLastFrame[builderID] + FRAME_GAP then
		unitLastFrame[builderID] = frame
		unitLastX[builderID] = x
		unitLastZ[builderID] = z
		return true
	end
	
	-- If you insert many build orders at the start of a construction queue, in range of the constructor,
	-- then AllowUnitCreation seems to call as if it were AllowCommand. However, all of these calls have the
	-- x,y,z,facing of the first structure in the queue so this check can be used to let them through.
	if x == unitLastX[builderID] and z == unitLastZ[builderID] then
		return true
	end
	return false
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
