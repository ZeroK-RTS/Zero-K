function widget:GetInfo() return {
	name = "One click weapon handler",
	layer = -1337, -- before cmd_commandinsert
	enabled = true,
} end

VFS.Include("LuaRules/Configs/customcmds.h.lua", customCmds, VFS.GAME)

local spGiveOrder = Spring.GiveOrder
local CMD_INSERT = CMD.INSERT
local CMD_OPT_ALT = CMD.OPT_ALT
local PARAMS = {0, CMD_ONECLICK_WEAPON, 0, 1}

function widget:CommandNotify(cmdID, cmdParams, cmdOptions)
	if cmdID ~= CMD_ONECLICK_WEAPON or cmdOptions.shift then
		return
	end

	PARAMS[3] = cmdOptions.coded
	PARAMS[4] = cmdParams[1] or 1
	spGiveOrder(CMD_INSERT, PARAMS, CMD_OPT_ALT)
	return true
end
