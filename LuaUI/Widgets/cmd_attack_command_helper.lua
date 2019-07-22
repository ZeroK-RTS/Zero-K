function widget:GetInfo()
	return {
		name      = "Attack Command Helper",
		desc      = "Makes it easier to issue attack commands on moving units. Removes right click area attack.",
		author    = "GoogleFrog",
		date      = "24 January 2018",
		license   = "GNU GPL, v2 or later",
		layer     = -52,
		enabled   = true,
		handler   = true,
	}
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

VFS.Include("LuaRules/Configs/customcmds.h.lua")

local TRACE_UNIT = "unit"
local CLICK_LEEWAY = 5

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

local clickX, clickY = false, false
local clickUnitID = false
local clickCommandID = false
local clickActiveCmdID = false
local clickRight = false

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local function Reset()
	clickX = false
	clickY = false
	clickUnitID = false
	clickCommandID = false
	clickActiveCmdID = false
	clickRight = false
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
	
	local cmdID = GetActionCommand(right)
	if not (cmdID and attackishCommandDefs[cmdID]) then
		return
	end
	
	local traceType, targetID = Spring.TraceScreenRay(x, y)
	if not (targetID and traceType == TRACE_UNIT) then
		return
	end
	
	clickX = x
	clickY = y
	clickUnitID = targetID
	clickCommandID = cmdID
	clickActiveCmdID = select(2, Spring.GetActiveCommand())
	clickRight = right
end

local function MouseRelease(x, y)
	local alt, ctrl, meta, shift = Spring.GetModKeyState()
	
	if clickRight then
		if clickActiveCmdID then
			Reset()
			return
		end
		
		if not shift then
			Spring.SetActiveCommand(-1)
		end
	end
	
	if not (clickUnitID and clickCommandID) then
		Reset()
		return
	end
	
	if not (clickX and clickY and clickUnitID) or (math.abs(clickX - x) > CLICK_LEEWAY) or (math.abs(clickY - y) > CLICK_LEEWAY) then
		return
	end
	
	if Spring.GetSelectedUnitsCount() == 0 then
		Reset()
		return
	end
	
	local traceType, targetID = Spring.TraceScreenRay(x, y)
	if (traceType == TRACE_UNIT) then
		return
	end
	
	GiveNotifyingOrder(clickCommandID, {clickUnitID}, GetCmdOpts(alt, ctrl, meta, shift, clickRight))
	if (not shift) and (not clickRight) then
		Spring.SetActiveCommand(-1)
	end
	Reset()
	return true
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:CommandNotify(id, params, opts)
	if not (attackishCommandDefs[id] and id == clickCommandID) then
		return false
	end
	if #params < 3 or (#params >= 4 and #params < 6 and params[4] > 10) then
		return false
	end
	
	local x, y = Spring.WorldToScreenCoords(params[1], params[2], params[3])
	if not (x and y) then
		return false
	end
	
	return MouseRelease(x, y)
end

local mousePressed = false
function widget:Update()
	local x, y, left, middle, right, offscreen = Spring.GetMouseState()
	if (left or right) and not mousePressed then
		MousePress(x, y, right)
		mousePressed = true
	end
	if not (left or right) and mousePressed then
		MouseRelease(x, y)
		mousePressed = false
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:Initialize()
	if Spring.Utilities.IsCurrentVersionNewerThan(104, 1000) then
		widgetHandler:RemoveWidget(widget)
		return
	end
end
