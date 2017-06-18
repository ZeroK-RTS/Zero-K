function widget:GetInfo() return {
	name      = "Double-Click attack-move",
	desc      = "Binds right double-click to the attack-move command.",
	author    = "Sprung",
	date      = "2017-06-19",
	license   = "PD",
	layer     = -1, -- before `cmd_raw_move_issue.lua`
	enabled   = true,
} end

local function ToggleCallins(self)
	if self.value then
		widgetHandler:UpdateCallIn("CommandNotify")
	else
		widgetHandler:RemoveCallIn("CommandNotify")
	end
end

options_path = 'Settings/Unit Behaviour'
options = { 
	enabled = {
		name = 'Double right-click to attack-move', 
		type = 'bool',
		desc = 'Double right-click gives an Attack-Move order instead of Move.',
		value = false,
		noHotkey = true,
		OnChange = ToggleCallins,
	},
}

VFS.Include("LuaRules/Configs/customcmds.h.lua")

local spDiffTimers = Spring.DiffTimers
local spGetTimer = Spring.GetTimer
local spGiveOrder = Spring.GiveOrder
local CMD_FIGHT = CMD.FIGHT

local tolerance = Spring.GetConfigInt('DoubleClickTime', 300) * 0.001 -- no event to notify us if this changes but not really a big deal
local prev = spGetTimer()

function widget:CommandNotify(id, params, opts)
	if id ~= CMD_RAW_MOVE then
		return
	end

	local now = spGetTimer()
	local doubleClick = (spDiffTimers(now, prev) <= tolerance)
	prev = now

	if not doubleClick then
		return
	end

	spGiveOrder(CMD_FIGHT, params, opts)
	return true
end

function widget:Initialize()
	ToggleCallins(options.enabled)
end
