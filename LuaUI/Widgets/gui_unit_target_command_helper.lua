function widget:GetInfo()
	return {
		name      = "Unit Target Command Helper",
		desc      = "Makes it easier to issue single unit commands on moving units.",
		author    = "GoogleFrog",
		date      = "20 February 2019",
		license   = "GNU GPL, v2 or later",
		layer     = -52,
		enabled   = true,
		handler   = true,
	}
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local SIZE_FACTOR = ((select(1, Spring.GetWindowGeometry()) > 3000) and 2) or 1

local function SetCircleDragThreshold(value)
	value = value*SIZE_FACTOR
	Spring.SetConfigInt("MouseDragCircleCommandThreshold", value)
	WG.CircleDragThreshold = value
end

options_path = 'Settings/Interface/Area Commands'
options_order = { 'circleDragThreshold', 'unitTargetHelper' }
options = {
	circleDragThreshold = {
		name = "Area command drag threshold",
		desc = "Distance that the mouse must move to issue an area command.",
		type = 'number',
		value = 25,
		min = 2, max = 300, step = 1,
		noHotkey = true,
		OnChange = function (self)
			SetCircleDragThreshold(self.value)
		end
	},
	unitTargetHelper = {
		name = "Use unit target helper",
		desc = "When enabled, targets the unit under mouse press if nothing is under the mouse on release.",
		type = "bool",
		value = true,
		noHotkey = true,
	},
}

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

VFS.Include("LuaRules/Configs/customcmds.h.lua")

local screen0

local TRACE_UNIT = "unit"
local TRACE_FEATURE = "feature"
local MAX_UNITS = Game.maxUnits

local handledCommand = {
	[CMD.ATTACK] = true,
	[CMD.REPAIR] = true,
	[CMD.LOAD_UNITS] = true,
	[CMD.LOAD_ONTO] = true,
	[CMD.UNLOAD_UNITS] = true,
	[CMD.CAPTURE] = true,
	[CMD.MANUALFIRE] = true,

	[CMD_UNIT_SET_TARGET] = true,
	[CMD_UNIT_SET_TARGET_CIRCLE] = true,
	
	-- Features
	[CMD.RECLAIM] = true,
	[CMD.RESURRECT] = true,
}

local featureCommand = {
	[CMD.RECLAIM] = true,
	[CMD.RESURRECT] = true,
}

local CMD_OPT_ALT = CMD.OPT_ALT
local CMD_OPT_CTRL = CMD.OPT_CTRL
local CMD_OPT_META = CMD.OPT_META
local CMD_OPT_SHIFT = CMD.OPT_SHIFT
local CMD_OPT_RIGHT = CMD.OPT_RIGHT

local clickTargetID = false
local clickCommandID = false
local clickActiveCmdID = false
local clickRight = false
local totalDist = 0

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local function Reset()
	clickTargetID = false
	clickCommandID = false
	clickActiveCmdID = false
	clickRight = false
	totalDist = 0
end

local function GetActionCommand(right)
	local _, activeCmdID = Spring.GetActiveCommand()
	if activeCmdID and not right then
		return activeCmdID
	else
		if right then
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

local function MousePress(x, y, right)
	Reset()
	
	if Spring.GetSelectedUnitsCount() == 0 then
		return
	end
	
	if screen0 and screen0.currentTooltip then
		return
	end
	
	local cmdID = GetActionCommand(right)
	if not (cmdID and handledCommand[cmdID]) then
		return
	end
	
	local traceType, targetID = Spring.TraceScreenRay(x, y)
	if not (traceType == TRACE_UNIT) then
		if (featureCommand[cmdID] and traceType == TRACE_FEATURE) then
			targetID = targetID + MAX_UNITS
		else
			return
		end
	end
	
	clickTargetID = targetID
	clickCommandID = cmdID
	clickActiveCmdID = select(2, Spring.GetActiveCommand())
	clickRight = right
end

local function MouseRelease(x, y)
	if not clickTargetID then
		return false
	end
	
	local alt, ctrl, meta, shift = Spring.GetModKeyState()
	if alt then
		Reset()
		return false
	end
	
	if (not shift) or clickRight then
		Spring.SetActiveCommand(-1)
	end
	
	GiveNotifyingOrder(clickCommandID, {clickTargetID}, GetCmdOpts(alt, ctrl, meta, shift, clickRight))
	
	Reset()
	return true
end

local function MouseMove(dx, dy)
	if clickTargetID then
		totalDist = totalDist + math.sqrt(dx*dx + dy*dy)
		if totalDist > (WG.CircleDragThreshold or 5) + 2 then
			Reset()
		end
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:CommandNotify(id, params, opts)
	-- Right click commands only occur if they are area commands.
	-- Left click commands that miss a unit may turn into ground commands.
	if clickRight or (not clickTargetID) or (#params ~= 3 and #params ~= 4) then
		Reset()
		return false
	end
	
	return MouseRelease(x, y)
end

local mousePressed = false
local lastX, lastY = 0, 0
function widget:Update()
	local x, y, left, middle, right, offscreen = Spring.GetMouseState()
	if (left or right) and not mousePressed then
		lastX, lastY = x, y
		MousePress(x, y, right)
		mousePressed = true
		return
	end
	
	if not (left or right) and mousePressed then
		MouseRelease(x, y)
		mousePressed = false
		return
	end
	
	if mousePressed then
		MouseMove(x - lastX, y - lastY)
		lastX, lastY = x, y
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:Initialize()
	if not Spring.Utilities.IsCurrentVersionNewerThan(104, 1000) then
		widgetHandler:RemoveWidget(widget)
		return
	end
	screen0 = WG.Chili and WG.Chili.Screen0
	SetCircleDragThreshold(options.circleDragThreshold.value)
end
