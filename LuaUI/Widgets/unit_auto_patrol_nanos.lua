-- $Id$
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
--  file:    unit_immobile_buider.lua
--  brief:   sets immobile builders to ROAMING, and gives them a PATROL order
--  author:  Dave Rodgers
--
--  Copyright (C) 2007.
--  Licensed under the terms of the GNU GPL, v2 or later.
--
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
VFS.Include("LuaRules/Configs/constants.lua")

local logfile

function widget:GetInfo()
  return {
    name      = "Auto Patrol Nanos",
    desc      = "Sets nano towers to ROAM, with a PATROL command",
    author    = "trepan",
    date      = "Jan 8, 2007",
    license   = "GNU GPL, v2 or later",
    layer     = -2,
    enabled   = true  --  loaded by default?
  }
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Speedups

local CMD_INSERT        = CMD.INSERT
local CMD_MOVE_STATE    = CMD.MOVE_STATE
local CMD_PATROL        = CMD.PATROL
local CMD_RECLAIM       = CMD.RECLAIM
local CMD_REPAIR        = CMD.REPAIR
local CMD_STOP          = CMD.STOP
local spGetGameFrame    = Spring.GetGameFrame
local spGetMyTeamID     = Spring.GetMyTeamID
local spGetTeamUnits    = Spring.GetTeamUnits
local spGetUnitCurrentCommand = Spring.GetUnitCurrentCommand
local spGetCommandQueue = Spring.GetCommandQueue
local spGetUnitDefID    = Spring.GetUnitDefID
local spGetUnitPosition = Spring.GetUnitPosition
local spGiveOrderToUnit = Spring.GiveOrderToUnit
local spGetGameRulesParam = Spring.GetGameRulesParam
local spEcho            = Spring.Echo
local spGetTeamResources = Spring.GetTeamResources

local abs = math.abs

local mapCenterX = Game.mapSizeX / 2
local mapCenterZ = Game.mapSizeZ / 2

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Constants

-- Check that a unit is still doing the right thing every `checkInterval`
-- seconds.
local checkInterval = 20
-- Don't issue a new command if less than `settleInterval` seconds have passed,
-- even if the unit became idle. This is a simple rate limiter on issuing
-- commands in case there are caretakers with nothing to do for their current
-- state.
local settleInterval = 5

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Variables

local stoppedUnit = {}
local enableIdleNanos = true
local stopHalts = true
-- Map from unitID -> { command, commandArgs, checkTime }
local trackedUnits = {}
-- The current time, in seconds (I think)
local time = 0
local nextCheck

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Functions

VFS.Include("LuaRules/Utilities/ClampPosition.lua")
local GiveClampedOrderToUnit = Spring.Utilities.GiveClampedOrderToUnit

local function Log(msg)
	spEcho("[uapn] " .. msg)
end

local function LogTable(table, prefix)
	prefix = prefix or ""
	for key, value in pairs(table) do
		if type(value) == "table" then
			Log(prefix .. tostring(key) .. ":")
			LogTable(value, prefix .. "  ")
		else
			Log(prefix .. tostring(key) .. ": " .. tostring(value))
		end
	end
end

local function UpdateNextCheck()
	nextCheck = nil
	for _, info in pairs(trackedUnits) do
		if nextCheck == nil or info.checkTime < nextCheck then
			nextCheck = info.checkTime
		end
	end
	Log("Update nextCheck to " .. tostring(nextCheck))
end

local function IsImmobileBuilder(ud)
	return(ud and ud.isBuilder and not ud.canMove and not ud.isFactory)
end

local function CommandPriorities(x, y, z, buildDistance)
	-- TODO: Cache for a few seconds
    local teamID = spGetMyTeamID()
	--local energy, energyStorage = spGetTeamResources(teamID, "energy")
	--energyStorage = energyStorage - HIDDEN_STORAGE
	local metal, metalStorage, metalPull, metalIncome = spGetTeamResources(teamID, "metal")
	metalStorage = metalStorage - HIDDEN_STORAGE
	Log("metal=" .. metal .. "; metalStorage=" .. metalStorage ..
		"; metalPull=" .. metalPull .. "; metalIncome=" .. metalIncome)
	if metal < 5 + metalIncome then
		Log("reclaim")
		return {{CMD_RECLAIM, {x, y, z, buildDistance}}}
	elseif metal > metalStorage - 5 then
		Log("repair")
		return {{CMD_REPAIR, {x, y, z, buildDistance}}}
	else
		Log("patrol")
		-- Patrolling doesn't do anything if you target the current location of
		-- the unit. Point patrol towards map center.
		vx = mapCenterX - x
		vz = mapCenterZ - z
		x = x + vx*25/abs(vx)
		z = z + vz*25/abs(vz)

		return {{CMD_PATROL, {x, y, z}}}
	end
end

local function SetupUnit(unitID)
	-- set immobile builders (nanotowers?) to the ROAM movestate,
	-- and give them a PATROL order (does not matter where, afaict)

	-- TODO: Don't override user commands.
	local commandQueue = Spring.GetCommandQueue(unitID, -1)
	Log(time .. "; cmd for " .. unitID .. ":" .. tostring(commandQueue) .. " ("
		.. type(commandQueue) .. ")")
	LogTable(commandQueue)
--	local cmdID = spGetUnitCurrentCommand(unitID)
--	Log("SetupUnit(" .. unitID ..") executing " .. tostring(cmdID), "\n")
--	if cmdID and cmdID ~= CMD_PATROL then
--		return
--	end
	
	local x, y, z = spGetUnitPosition(unitID)
	if (x) then
		local unitDefID = spGetUnitDefID(unitID)
		local buildDistance = UnitDefs[unitDefID].buildDistance
		trackedUnits[unitID] = trackedUnits[unitID] or {}
		trackedUnits[unitID].settleTime = time + settleInterval
		trackedUnits[unitID].checkTime = time + checkInterval
		local priorities = CommandPriorities(x, y, z, buildDistance)
		--Log("priorities: " .. tostring(priorities))
		--LogTable(priorities, "  ")
		local first = true
		for _, cmd in pairs(priorities) do
			Log("give order " .. cmd[1] .. " to " .. unitID)
			if first then
				spGiveOrderToUnit(unitID, cmd[1], cmd[2], {})
			else
				local params = {-1, cmd[1], 0}
				for _, v in pairs(cmd[2]) do
					table.insert(params, v)
				end
				spGiveOrderToUnit(unitID, CMD_INSERT, params, {})
			end
			first = false
		end
	end
end

local function SetupAll()
	for _,unitID in ipairs(spGetTeamUnits(spGetMyTeamID())) do
		local unitDefID = spGetUnitDefID(unitID)
		if (IsImmobileBuilder(UnitDefs[unitDefID])) then
			SetupUnit(unitID)
		end
	end
	UpdateNextCheck()
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Settings

options_path = 'Settings/Unit Behaviour'
options = {
	patrol_idle_nanos = {
		name = "Caretaker automation",
		type = 'bool',
		value = true,
		noHotkey = true,
		desc = 'Caretakers will automatically find tasks when idle. They may assist, repair or reclaim. Also applies to Strider Hub.',
		OnChange = function (self)
			enableIdleNanos = self.value
			if self.value then
				SetupAll()
			end
		end,
	},
	stop_disables = {
		name = "Disable caretakers with stop",
		type = 'bool',
		value = true,
		noHotkey = true,
		desc = 'Caretakers automation is put on hold with the Stop command. Automation resumes after any other command. Also applies to Strider Hub.',
		OnChange = function (self)
			stopHalts = self.value
			if not self.value then
				stoppedUnit = {}
				SetupAll()
			end
		end,
	}
}

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Callins

function widget:Initialize()
	logfile = io.open("/home/tnewsome/zerok.log", "w")
	SetupAll()
end

function widget:UnitCreated(unitID, unitDefID, unitTeam)
	if not enableIdleNanos or unitTeam ~= spGetMyTeamID()
			or not IsImmobileBuilder(UnitDefs[unitDefID])
			or spGetGameRulesParam("loadPurge") == 1 then
		return
	end

	SetupUnit(unitID)
	UpdateNextCheck()
end

function widget:UnitCommand(unitID, unitDefID, unitTeam, cmdID, cmdParams, cmdOptions)
	if not IsImmobileBuilder(UnitDefs[unitDefID]) then
		return
	end
	if cmdID == CMD_PATROL and (not cmdOptions.shift) then
		local x, y, z = spGetUnitPosition(unitID)
		if math.abs(x - cmdParams[1]) > 30 or math.abs(z - cmdParams[3]) > 30 then
			SetupUnit(unitID)
		end
	end
	if stopHalts then
		if cmdID == CMD_STOP then
			stoppedUnit[unitID] = true
		elseif stoppedUnit[unitID] then
			stoppedUnit[unitID] = nil
		end
	end
	UpdateNextCheck()
end

function widget:UnitGiven(unitID, unitDefID, unitTeam)
	widget:UnitCreated(unitID, unitDefID, unitTeam)
end

function widget:UnitIdle(unitID, unitDefID, unitTeam)
	if not enableIdleNanos or stoppedUnit[unitID]
			or unitTeam ~= spGetMyTeamID()
			or not IsImmobileBuilder(UnitDefs[unitDefID])
			or spGetGameRulesParam("loadPurge") == 1 then
		return
	end

	--[[ A unit can become "idle" in the process of receiving a command. Consider:

	  CommandNotify()
	    RemoveAllCommands() -- triggers idle here
	    return false -- not actually idle

	If the command was ordered with SHIFT it would get appended after the patrol. ]]

	Log("UnitIdle:")
	LogTable(trackedUnits[unitID], "- ")
	-- Check soon, but not right away. This time has to be long enough that the
	-- factory we're assisting (while in repair mode) has started the next unit.
	trackedUnits[unitID].checkTime =
		math.max(
			math.min(
				trackedUnits[unitID].checkTime,
				trackedUnits[unitID].settleTime),
			time + 0.5)
	nextCheck = math.min(nextCheck, trackedUnits[unitID].checkTime)
	LogTable(trackedUnits[unitID], "+ ")
end

function widget:Update(dt)
	time = time + dt
	if nextCheck ~= nil and time > nextCheck then
		Log("time to check (" .. time .. ")")
		for unitID, _ in pairs(trackedUnits) do
			if Spring.ValidUnitID(unitID) then
				SetupUnit(unitID)
			else
				trackedUnits[unitID] = nil
			end
		end
		UpdateNextCheck()
    end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
