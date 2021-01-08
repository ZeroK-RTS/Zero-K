function widget:GetInfo()
	return {
		name      = "State Reverse and Latency",
		desc      = "Makes multinary states reverse toggleable and removes state update visual latency.",
		author    = "Google Frog",
		date      = "Oct 2, 2009 (20 November, 2020 for latency)",
		license   = "GNU GPL, v2 or later",
		layer     = 0,
		enabled   = true  --  loaded by default?
	}
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Speedup

local spGetSelectedUnits = Spring.GetSelectedUnits
local spGiveOrderToUnit = Spring.GiveOrderToUnit

local CMD_FIRE_STATE = CMD.FIRE_STATE
local CMD_MOVE_STATE = CMD.MOVE_STATE

local STANDARD_OPTS = {
	alt = false,
	ctrl = false,
	internal = false,
	coded = 0,
	right = false,
	meta = false,
	shift = false,
}

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Configuration

-- so that users' own commands can also have reversing
local stateTypes, gadgetReverse, specialHandling = VFS.Include(LUAUI_DIRNAME .. "Configs/stateTypes.lua", nil, VFS.RAW_FIRST)

local PING_UPDATE_RATE = 0.5
local PING_MEMORY = 4
local OVERRIDE_PADDING = 0.1

local removableStates = {
	[CMD_FIRE_STATE] = 1,
	[CMD_MOVE_STATE] = 2,
}

local multiStates = {
	[CMD_FIRE_STATE] = 3,
	[CMD_MOVE_STATE] = 3,
	[CMD.AUTOREPAIRLEVEL] = 4,
}

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Data

local overriddenStates = {}
local overriddenStateExpiry = {}
local currentTime = 0

local myPlayerID = Spring.GetMyPlayerID()

local currentOverrideTime = 0
local currentPing = 0
local pingIndex = 1
local pingTimeList = {}

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local function ReverseToggle(cmdID, state)
	local units = spGetSelectedUnits()
	
	state = state - 2 -- engine sent us one step forward instead of one step back, so we go two steps back
	if state < 0 then
		state = multiStates[cmdID] + state -- wrap
	end
	local paramTable = { state }
	for i = 1, #units do
		spGiveOrderToUnit(units[i], cmdID, paramTable, 0)
	end
	overriddenStates[cmdID] = state
end

local function GetOverriddenState(cmdID)
	if not overriddenStateExpiry[cmdID] then
		return
	end
	if overriddenStateExpiry[cmdID] < currentTime then
		overriddenStateExpiry[cmdID] = false
		return
	end
	return overriddenStates[cmdID]
end

local function HandleCommand(cmdID, params, options, nonToggle)
	if not (stateTypes[cmdID] and params and params[1]) then
		return
	end
	--Spring.Utilities.TableEcho(params, "params")
	--Spring.Utilities.TableEcho(options, "options")
	--Spring.Echo("overrideState", currentTime, overriddenStateExpiry[cmdID], currentOverrideTime, GetOverriddenState(cmdID))
	
	local overrideState = GetOverriddenState(cmdID)
	overriddenStateExpiry[cmdID] = currentTime + currentOverrideTime
	if not nonToggle then
		if not overrideState then
			-- Note that params[1] is the desired state
			if specialHandling[cmdID] then
				params[1] = specialHandling[cmdID]((params[1])%stateTypes[cmdID], options)
			elseif gadgetReverse[cmdID] and options.right then
				params[1] = (params[1] - 2)%stateTypes[cmdID]
				options.right = false
			end
		elseif specialHandling[cmdID] then
			params[1] = specialHandling[cmdID]((overriddenStates[cmdID] + 1)%stateTypes[cmdID], options)
		elseif gadgetReverse[cmdID] and options.right then
			params[1] = (overriddenStates[cmdID] - 1)%stateTypes[cmdID]
			options.right = false
		else
			params[1] = (overriddenStates[cmdID] + 1)%stateTypes[cmdID]
		end
	
		if (WG.RemoveReturnFireState and cmdID == CMD_FIRE_STATE) or (WG.RemoveRoamState and cmdID == CMD_MOVE_STATE) then
			local state = params[1]
			if state == removableStates[cmdID] then
				ReverseToggle(cmdID, state)
				return true
			end
		elseif multiStates[cmdID] then
			if options.right then
				ReverseToggle(cmdID, params[1])
				return true
			end
		end
	end
	
	overriddenStates[cmdID] = params[1]
	Spring.GiveOrder(cmdID, params, options)
	return true
end

local function SetStateToggle(cmdID, value)
	HandleCommand(cmdID, {value}, STANDARD_OPTS, true)
	if WG.IntegralMenu then
		WG.IntegralMenu.UpdateCommands()
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:CommandNotify(cmdID, params, options)
	return HandleCommand(cmdID, params, options)
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local function UpdatePing()
	local pingTime = select(6, Spring.GetPlayerInfo(myPlayerID, false))
	pingTimeList[pingIndex] = pingTime
	pingIndex = (pingIndex%PING_MEMORY) + 1
	
	currentPing = 0
	for i = 1, PING_MEMORY do
		if pingTimeList[i] and pingTimeList[i] > currentPing then
			currentPing = pingTimeList[i]
		end
	end
	currentOverrideTime = currentPing + OVERRIDE_PADDING
	--Spring.Echo("currentPing", pingTime, currentPing)
end

local pingUpdateTimer = 0
function widget:Update(dt)
	currentTime = currentTime + dt
	pingUpdateTimer = pingUpdateTimer + dt
	if pingUpdateTimer > PING_UPDATE_RATE then
		UpdatePing()
		pingUpdateTimer = pingUpdateTimer - PING_UPDATE_RATE
	end
end

function widget:SelectionChanged(selection, subselection)
	if subselection then
		return
	end
	-- Remove cache on new selection
	overriddenStateExpiry = {}
end

function widget:Initialize()
	WG.GetOverriddenState = GetOverriddenState
	WG.SetStateToggle = SetStateToggle
end

function widget:Shutdown()
	WG.GetOverriddenState = nil
	WG.SetStateToggle = nil
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
