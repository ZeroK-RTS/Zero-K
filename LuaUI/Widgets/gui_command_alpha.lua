
function widget:GetInfo()
	return {
		name      = "Command Alpha",
		desc      = "Sets custom command draw parameters.",
		author    = "GoogleFrog",
		date      = "5 April, 2020",
		license   = "GNU GPL, v2 or later",
		layer     = 0,
		enabled   = true,
	}
end

----------------------------------------------------
----------------------------------------------------

VFS.Include("LuaRules/Configs/customcmds.h.lua")

local cmdAlpha = (tonumber(Spring.GetConfigString("CmdAlpha") or "0.7") or 0.7)
local terraformColor = {0.7, 0.75, 0, cmdAlpha}

function widget:Initialize()
	Spring.SetCustomCommandDrawData(CMD_ORBIT_DRAW, "Guard", {0.3, 0.3, 1.0, cmdAlpha})
	Spring.SetCustomCommandDrawData(CMD_RAW_MOVE, "RawMove", {0.5, 1.0, 0.5, cmdAlpha}) -- "" mean there's no MOVE cursor if the command is drawn.
	Spring.SetCustomCommandDrawData(CMD_REARM, "Repair", {0, 1, 1, cmdAlpha})
	Spring.SetCustomCommandDrawData(CMD_FIND_PAD, "Guard", {0, 1, 1, cmdAlpha})
	Spring.SetCustomCommandDrawData(CMD_JUMP, "Jump", {0, 1, 0, cmdAlpha})
	Spring.SetCustomCommandDrawData(CMD_JUMP, "Jump", {0, 1, 0, cmdAlpha})
	Spring.SetCustomCommandDrawData(CMD_ONECLICK_WEAPON, "dgun", {1, 1, 1, cmdAlpha})
	Spring.SetCustomCommandDrawData(CMD_UNIT_SET_TARGET, "SetTarget", {1.0, cmdAlpha, 0.0, cmdAlpha}, true)
	Spring.SetCustomCommandDrawData(CMD_UNIT_SET_TARGET_CIRCLE, "SetTarget", {1.0, cmdAlpha, 0.0, cmdAlpha}, true)
	Spring.SetCustomCommandDrawData(CMD_PLACE_BEACON, "Beacon", {0.2, 0.8, 0, cmdAlpha})
	Spring.SetCustomCommandDrawData(CMD_WAIT_AT_BEACON, "Beacon Queue", {0.1, 0.1, 1, cmdAlpha})
	Spring.SetCustomCommandDrawData(CMD_RAMP, "Ramp", terraformColor, false)
	Spring.SetCustomCommandDrawData(CMD_LEVEL, "Level", terraformColor, false)
	Spring.SetCustomCommandDrawData(CMD_RAISE, "Raise", terraformColor, false)
	Spring.SetCustomCommandDrawData(CMD_SMOOTH, "Smooth", terraformColor, false)
	Spring.SetCustomCommandDrawData(CMD_RESTORE, "Restore2", terraformColor, false)
	Spring.SetCustomCommandDrawData(CMD_PLATE, "plate", terraformColor, false)
	Spring.SetCustomCommandDrawData(CMD_EXTENDED_LOAD, CMD.LOAD_UNITS, {0,0.6,0.6,cmdAlpha},true)
	Spring.SetCustomCommandDrawData(CMD_EXTENDED_UNLOAD, CMD.UNLOAD_UNITS, {0.6,0.6,0,cmdAlpha})
	Spring.SetCustomCommandDrawData(CMD_TURN, "Patrol", {0,1,0,cmdAlpha})
end
