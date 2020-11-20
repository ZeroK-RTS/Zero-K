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

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Configuration

local stateTypes, specialHandling = VFS.Include(LUAUI_DIRNAME .. "Configs/stateTypes.lua")

local PING_UPDATE_RATE = 0.5
local PING_MEMORY = 4
local OVERRIDE_PADDING = 0.07

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
		overriddenStateExpiry[cmdID] = nil
		return
	end
	return overriddenStates[cmdID]
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:CommandNotify(cmdID, params, options)
	if not stateTypes[cmdID] then
		return
	end
	overriddenStateExpiry[cmdID] = currentTime + currentOverrideTime
	
	local overrideState = GetOverriddenState(cmdID)
	if not overrideState then
		overriddenStates[cmdID] = params[1]
	end
	if specialHandling[cmdID] then
		params[1] = specialHandling[cmdID]((overriddenStates[cmdID] + 1)%stateTypes[cmdID], options)
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
	
	Spring.GiveOrder(cmdID, params, options)
	overriddenStates[cmdID] = params[1]
	return true
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

function widget:Initialize()
	WG.GetOverriddenState = GetOverriddenState
end

function widget:Shutdown()
	WG.GetOverriddenState = nil
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
