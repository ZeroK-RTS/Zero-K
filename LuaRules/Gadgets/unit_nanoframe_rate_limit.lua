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
local FRAME_GAP = 1

function gadget:AllowUnitCreation(udefID, builderID)
	Spring.Echo("AllowUnitCreation", builderID)
	if not builderID then
		return true
	end
	local frame = Spring.GetGameFrame()
	if (not unitLastFrame[builderID]) or frame >= unitLastFrame[builderID] + FRAME_GAP then
		unitLastFrame[builderID] = frame
		return true
	end
	return false
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
