function widget:GetInfo()
	return {
		name      = "Attack Command Helper",
		desc      = "Makes it easier to issue attack commands on moving units. Removes right click area attack.",
		author    = "Google Frog",
		date      = "11 August 2015",
		license   = "GNU GPL, v2 or later",
		layer     = -52,
		enabled   = true,
		handler   = true,
	}
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

VFS.Include("LuaRules/Configs/customcmds.h.lua")

local LEFT_CLICK = 1
local RIGHT_CLICK = 3
local TRACE_UNIT = "unit"
local attackishCommandDefs = {
	[CMD.ATTACK] = true,
	[CMD_UNIT_SET_TARGET] = true,
	[CMD_UNIT_SET_TARGET_CIRCLE] = true,
}

local CMD_OPT_ALT = CMD.OPT_ALT
local CMD_OPT_CTRL = CMD.OPT_CTRL
local CMD_OPT_META = CMD.OPT_META
local CMD_OPT_SHIFT = CMD.OPT_SHIFT
local CMD_OPT_RIGHT = CMD.OPT_RIGHT

local clickUnitID = false
local clickCommandID = false

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

options_path = 'Settings/Unit Behaviour'
options_order = {'useAreaAttack', 'attackOnClick',}
options = {
	useAreaAttack = {
		name = "Right click area attack",
		type = "bool",
		value = true,
		noHotkey = true,
		desc = "Right click and drag on enemy units to issue area attack.",
	},
	attackOnClick = {
		name = "Attack on mouse press",
		type = "bool",
		value = false,
		noHotkey = true,
		desc = "Issue attack command on clicking, only work when right click area attack is disabled.",
	},
}

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local function Reset()
	clickUnitID = false
	clickCommandID = false
end

local function GetActionCommand(button)
	local _, activeCmdID = Spring.GetActiveCommand()
	if activeCmdID and button == LEFT_CLICK then
		return activeCmdID
	else
		if button == RIGHT_CLICK then
			local _, defaultCmdID = Spring.GetDefaultCommand()
			return defaultCmdID
		end
	end
	return false
end

local function GetOpts()
	local opts = {}
	if alt then
		opts[#opts + 1] = "alt"
	end
	if ctrl then
		opts[#opts + 1] = "ctrl"
	end
	if meta then
		opts[#opts + 1] = "meta"
	end
	if shift then
		opts[#opts + 1] = "shift"
	end
	return opts
end

local function GetCmdOpts(alt, ctrl, meta, shift, right)
	local opts = {alt = alt, ctrl = ctrl, meta = meta, shift = shift, right = right}
	local coded = 0
	
	if alt   then coded = coded + CMD_OPT_ALT   end
	if ctrl  then coded = coded + CMD_OPT_CTRL  end
	if meta  then coded = coded + CMD_OPT_META  end
	if shift then coded = coded + CMD_OPT_SHIFT end
	if right then coded = coded + CMD_OPT_RIGHT end
	
	opts.coded = coded
	return opts
end

local function GiveNotifyingOrder(cmdID, cmdParams, cmdOpts)
	if widgetHandler:CommandNotify(cmdID, cmdParams, cmdOpts) then
		return
	end
	Spring.GiveOrder(cmdID, cmdParams, cmdOpts.coded)
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:MousePress(x, y, button)
	if options.useAreaAttack.value then
		return false
	end
	Reset()
	
	if Spring.GetSelectedUnitsCount() == 0 then
		return false
	end
	
	local cmdID = GetActionCommand(button)
	if not (cmdID and attackishCommandDefs[cmdID]) then
		return false
	end
	
	local traceType, targetID = Spring.TraceScreenRay(x, y)
	if not (targetID and traceType == TRACE_UNIT) then
		return false
	end
	
	local myAllyTeamID = Spring.GetMyAllyTeamID()
	local targetAllyTeamID = Spring.GetUnitAllyTeam(targetID)
	if not (myAllyTeamID and targetAllyTeamID and myAllyTeamID ~= targetAllyTeamID) then
		return false
	end
	
	if options.attackOnClick.value then
		local alt, ctrl, meta, shift = Spring.GetModKeyState()
		GiveNotifyingOrder(cmdID, {targetID}, GetCmdOpts(alt, ctrl, meta, shift, button == RIGHT_CLICK))
	else
		clickUnitID = targetID
		clickCommandID = cmdID
	end
	return true
end

function widget:MouseRelease(x, y, button)
	if options.useAreaAttack.value then
		return false
	end
	
	if not (clickUnitID and clickCommandID) then
		Reset()
		return -1
	end
	
	if Spring.GetSelectedUnitsCount() == 0 then
		Reset()
		return -1
	end
	
	local traceType, targetID = Spring.TraceScreenRay(x, y)
	if not (targetID == clickUnitID and traceType == TRACE_UNIT) then
		Reset()
		return -1
	end
	
	local alt, ctrl, meta, shift = Spring.GetModKeyState()
	GiveNotifyingOrder(clickCommandID, {clickUnitID}, GetCmdOpts(alt, ctrl, meta, shift, button == RIGHT_CLICK))
	Reset()
end
