--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
--  file:    unit_immobile_buider.lua
--  brief:   sets immobile builders to ROAMING, and gives them a PATROL order
--  author:  Dave Rodgers
--  Copyright (C) 2007.
--  Licensed under the terms of the GNU GPL, v2 or later.
--
-- Features:
--   1. Idle caretakers will be set to area repair units, area assist build (which
--      includes repair units), area reclaim metal, area reclaim energy, or patrol,
--      depending on available resources.
--   2. For each caretaker under this widget's control, re-evaluate the behavior based
--		on the economy every 10 seconds. (Controlled by checkInterval.)
--   3. For each caretaker, never issue a command more than once every 2.5 seconds.
--      (Controlled by settleInterval.)
--   4. When a user issues a stop command, this behavior is inhibited, until a
--      different command issued by the user completes. (Unless stop_disables option
--      is false.)
--   5. When a user issues some other kind of command, the widget ignores the unit
--      until it becomes idle again.
--
-- Limitations:
--   1. When the widget chooses repair only, there's a 0.5 second delay between
--      a unit becoming idle and being told to repair. This is to give the factory
--      that's being assisted time to start the next unit. It is not perfect, and the
--      factory will be assisted less than if a patrol was issued. This could be
--      improved by reducing the delay, and implementing a fancier incremental
--      back-off than the simple 0.5s - 5s that is currently implemented.
--
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
VFS.Include("LuaRules/Configs/constants.lua")

local PriorityQueue = VFS.Include("LuaRules/Gadgets/Include/PriorityQueue.lua")

function widget:GetInfo()
  return {
    name      = "Auto Patrol Nanos",
    desc      = "Make caretakers patrol, reclaim, or repair, depending on metal storage.",
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

local CMD_PATROL        = CMD.PATROL
local CMD_RECLAIM       = CMD.RECLAIM
local CMD_REPAIR        = CMD.REPAIR
local CMD_STOP          = CMD.STOP
local CMD_OPT_ALT       = CMD.OPT_ALT
local CMD_OPT_CTRL      = CMD.OPT_CTRL
local CMD_OPT_SHIFT     = CMD.OPT_SHIFT
local CMD_OPT_META      = CMD.OPT_META
local CMD_OPT_INTERNAL  = CMD.OPT_INTERNAL

local spGetMyTeamID     = Spring.GetMyTeamID
local spGetTeamUnits    = Spring.GetTeamUnits
local spGetCommandQueue = Spring.GetCommandQueue
local spGetUnitDefID    = Spring.GetUnitDefID
local spGetUnitPosition = Spring.GetUnitPosition
local spGiveOrderToUnit = Spring.GiveOrderToUnit
local spGetGameRulesParam = Spring.GetGameRulesParam
local spEcho            = Spring.Echo
local spGetTeamResources = Spring.GetTeamResources
local spValidUnitID		= Spring.ValidUnitID
local spGetUnitCurrentCommand = Spring.GetUnitCurrentCommand

local TableEcho = Spring.Utilities.TableEcho

local abs = math.abs
local min = math.min
local max = math.max

local mapCenterX = Game.mapSizeX / 2
local mapCenterZ = Game.mapSizeZ / 2

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Constants

local FPS = 30

local PATROL = 1
local RECLAIM_METAL = 2
local RECLAIM_ENERGY = 3
local REPAIR_UNITS = 4
local BUILD_ASSIST = 5

-- Check that a unit is still doing the right thing every `checkInterval`
-- frames.
local checkInterval = 10 * FPS
-- Don't issue a new command if less than `settleInterval` frames have passed,
-- even if the unit became idle. This is a simple rate limiter on issuing
-- commands in case there are caretakers with nothing to do for their current
-- state.
local settleInterval = 2.5 * FPS

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Variables

local stoppedUnit = {}
local enableIdleNanos = true
local stopHalts = true

-- Units that we track have an entry both in trackedUnits (so we can quickly
-- tell if a unit is being tracked) and in queue (so we can only iterate over
-- units that need it).
-- Map from unitID -> { checkFrame, settleFrame, command }
local trackedUnits = {}
-- The queue contains {checkFrame, unitID} pairs.
local queue = PriorityQueue.new(function(a, b) return a[1] < b[1] end)

local currentFrame = 0

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Functions

-- Slightly randomize intervals, to prevent all caretakers from getting synced
-- up and all of them deciding to reclaim now, while really what needs to happen
-- is just some of them reclaiming.
local function RandomInterval(interval)
	return interval / 2 + math.random() * interval
end

local function Log(msg)
	spEcho("[uapn] " .. msg)
end

local function ITableEqual(a, b)
	if #a ~= #b then
		return false
	end

	for i = 1, #a do
		if a[i] ~= b[i] then
			return false
		end
	end

	return true
end

local function IsImmobileBuilder(ud)
	return(ud and ud.isBuilder and not ud.canMove and not ud.isFactory)
end

local decisionCacheInterval = 9
local decisionCache = { updated=nil }
local function DecideCommands()
	if decisionCache.updated ~= nil and
			decisionCache.updated + decisionCacheInterval > currentFrame then
		return decisionCache.commands
	end

	decisionCache.updated = currentFrame

	local metal, metalStorage, metalPull, metalIncome =
			spGetTeamResources(spGetMyTeamID(), "metal")
	metal = metal + checkInterval * (metalIncome - metalPull) / FPS
	metalStorage = metalStorage - HIDDEN_STORAGE
	Log("metal=" .. metal .. "; storage=" .. metalStorage .. "; pull=" .. metalPull .. "; income=" .. metalIncome)
	local energy, energyStorage, energyPull, energyIncome =
			spGetTeamResources(spGetMyTeamID(), "energy")
	energy = energy + checkInterval * (energyIncome - energyPull) / FPS
	energyStorage = energyStorage - HIDDEN_STORAGE

	local slop = 5

	local get_metal, get_energy, use_metal, use_energy

	if metalStorage < 1 then
		get_metal = metalPull >= metalIncome
		use_metal = metalPull <= metalIncome
	else
		get_metal = metal < metalStorage - slop and
				metal < metalStorage * 0.9
		use_metal = metal > slop and metal > metalStorage * 0.1
	end

	if energyStorage < 1 then
		get_energy = energyPull >= energyIncome
		use_energy = energyPull <= energyIncome
	else
		get_energy = energy < energyStorage - slop and
				energy < energyStorage * 0.9
		use_energy = energy > slop and energy > energyStorage * 0.1
	end

	--Log("get_metal=" .. tostring(get_metal) .. ", " ..
	--	"use_metal=" .. tostring(use_metal) .. ", " ..
	--	"get_energy=" .. tostring(get_energy) .. ", " ..
	--	"use_energy=" .. tostring(use_energy))

	local commands = {}

	if get_metal and not get_energy and use_metal and use_energy then
		commands[#commands + 1] = PATROL
	else
		if use_metal and use_energy then
			commands[#commands + 1] = BUILD_ASSIST
		end
		if use_energy then
			commands[#commands + 1] = REPAIR_UNITS
		end
		if get_metal and get_energy then
			if metal > energy then
				commands[#commands + 1] = RECLAIM_ENERGY
				commands[#commands + 1] = RECLAIM_METAL
			else
				commands[#commands + 1] = RECLAIM_METAL
				commands[#commands + 1] = RECLAIM_ENERGY
			end
		elseif get_metal then
			commands[#commands + 1] = RECLAIM_METAL
		elseif get_energy then
			commands[#commands + 1] = RECLAIM_ENERGY
		end
	end

	decisionCache.commands = commands

	return commands
end

local function MakeCommands(decidedCommands, unitID)
	if trackedUnits[unitID].commandTables == nil then
		local x, y, z = spGetUnitPosition(unitID)
		if not x then
			return nil
		end

		trackedUnits[unitID].commandTables = {}

		local unitDefID = spGetUnitDefID(unitID)
		local buildDistance = UnitDefs[unitDefID].buildDistance

		-- Patrolling doesn't do anything if you target the current location
		-- of the unit. Point patrol towards map center.
		local vx = mapCenterX - x
		local vz = mapCenterZ - z
		trackedUnits[unitID].commandTables[PATROL] = {CMD_PATROL, {x + vx*25/abs(vx), y, z + vz*25/abs(vz)}, 0, "patrol"}

		local area = {x, y, z, buildDistance}
		trackedUnits[unitID].commandTables[RECLAIM_METAL] = {CMD_RECLAIM, area, 0, "reclaim metal"}
		trackedUnits[unitID].commandTables[RECLAIM_ENERGY] = {CMD_RECLAIM, area, CMD_OPT_CTRL, "reclaim energy"}
		trackedUnits[unitID].commandTables[REPAIR_UNITS] = {CMD_REPAIR, area, CMD_OPT_META, "repair units"}
		trackedUnits[unitID].commandTables[BUILD_ASSIST] = {CMD_REPAIR, area, 0, "build assist"}
	end

	local commands = {}

	for i, decided in ipairs(decidedCommands) do
		commands[i] = trackedUnits[unitID].commandTables[decided]
	end

	return commands
end

local function SetupUnit(unitID)
	trackedUnits[unitID] = trackedUnits[unitID] or {}
	trackedUnits[unitID].checkFrame = currentFrame + RandomInterval(checkInterval)
	local decisions = DecideCommands()
	local cmds = MakeCommands(decisions, unitID)
	if cmds == nil then
		return
	end

	queue:push({trackedUnits[unitID].checkFrame, unitID})

	--TableEcho(cmds, "want to issue cmds")
	--TableEcho(spGetCommandQueue(unitID, -1), "current command queue")

	if trackedUnits[unitID].commands and #cmds == #trackedUnits[unitID].commands then
		--Log("List lengths equal")

		local equal = true
		for i = 1, #cmds do
			if cmds[i][1] ~= trackedUnits[unitID].commands[i][1] then
				equal = false
				--Log("Command unequal")
				break
			end
		end
		--Log("Equal: " .. tostring(equal))

		if equal then
			-- We're going to issue the exact same commands we issued last time.
			-- Maybe the first one is still running and we don't need to reissue
			-- these commands.

			-- If the first command was a patrol, then it must still be
			-- running, since patrol never terminates.
			if cmds[1][1] == CMD_PATROL then
				--Log("Don't issue patrol again.")
				return
			end

			-- Area repair commands end up changed into some internal format
			-- when we issue them. Rather than relying on this internal format,
			-- just compare command IDs and call it good enough. This ignores
			-- the difference between reclaim metal/energy and build
			-- assist/repair units.

			local currentCmd, currentOpt = spGetUnitCurrentCommand(unitID)
			--Log("currentCmd: " .. tostring(currentCmd))

			if currentCmd == cmds[1][1] then
				--Log("Don't issue the same set of commands again.")
				return
			end
		end
	end

	for i, cmd in ipairs(cmds) do
		if i == 1 then
			spGiveOrderToUnit(unitID, cmd[1], cmd[2], cmd[3])
			Log("give order " .. cmd[4] .. " to " .. unitID)
		else
			spGiveOrderToUnit(unitID, cmd[1], cmd[2], cmd[3] + CMD_OPT_SHIFT)
			Log("queue order " .. cmd[4] .. " to " .. unitID)
		end
	end
	trackedUnits[unitID].settleFrame = currentFrame + RandomInterval(settleInterval)
	trackedUnits[unitID].commands = cmds
end

local function SetupAll()
	for _,unitID in ipairs(spGetTeamUnits(spGetMyTeamID())) do
		local unitDefID = spGetUnitDefID(unitID)
		if (IsImmobileBuilder(UnitDefs[unitDefID])) then
			SetupUnit(unitID)
		end
	end
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
	SetupAll()
end

function widget:UnitCreated(unitID, unitDefID, unitTeam)
	if not enableIdleNanos or unitTeam ~= spGetMyTeamID()
			or not IsImmobileBuilder(UnitDefs[unitDefID])
			or spGetGameRulesParam("loadPurge") == 1 then
		return
	end

	SetupUnit(unitID)
end

-- Convert a cmdOptions table to an int representing the value used to issue
-- that command.
function OptionValue(cmdOptions)
	local value = 0
	if cmdOptions.alt then
		value = value + CMD_OPT_ALT
	end
	if cmdOptions.ctrl then
		value = value + CMD_OPT_CTRL
	end
	if cmdOptions.shift then
		value = value + CMD_OPT_SHIFT
	end
	if cmdOptions.meta then
		value = value + CMD_OPT_META
	end
	return value
end

-- Called whenever a unit gets a command from any source, including this script!
function widget:UnitCommand(unitID, unitDefID, unitTeam, cmdID, cmdParams, cmdOptions)
	if not enableIdleNanos
			or cmdOptions.internal
			or unitTeam ~= spGetMyTeamID()
			or not IsImmobileBuilder(UnitDefs[unitDefID])
			or spGetGameRulesParam("loadPurge") == 1 then
		return
	end

	-- This is a command issued to a caretaker that we track. Check if it's a
	-- command that we issued, or one issued by the user.

	--Log("UnitCommand(" .. unitID .. ", " .. unitDefID .. ", " .. unitTeam .. ", " .. cmdID .. ")")
	--TableEcho(cmdParams, "  params: ")
	--TableEcho(cmdOptions, "  options: ")
	--Log("options: " .. OptionValue(cmdOptions))

	if trackedUnits[unitID] and trackedUnits[unitID].commands then
		for _, command in ipairs(trackedUnits[unitID].commands) do
			--Log("Compare against")
			--TableEcho(command)
			if command[1] == cmdID and ITableEqual(command[2], cmdParams) and
					command[3] == OptionValue(cmdOptions) then
				--Log("We issued this command. Ignore it.")
				return
			end
		end
	end
	-- TODO: Patrol seems to issue its own commands that are not flagged as
	-- internal. We don't want to consider them user commands, because they
	-- might take a long time complete (e.g. build/reclaim a detriment).

	--Log("Found a user issued command!")

	if stopHalts then
		if cmdID == CMD_STOP then
			if stoppedUnit[unitID] == nil then
				Log("Ignore unit " .. unitID .. " until it is given a command.")
			end
			stoppedUnit[unitID] = true
		elseif stoppedUnit[unitID] then
			if stoppedUnit[unitID] ~= nil then
				Log("Pay attention to unit " .. unitID .. " again.")
			end
			stoppedUnit[unitID] = nil
		end
	end

	if stoppedUnit[unitID] ~= nil then
		Log("Ignore unit " .. unitID .. " until it becomes idle.")
		trackedUnits[unitID] = nil
	end
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

	--Log("UnitIdle(" .. unitID .. "):")
	--TableEcho(trackedUnits[unitID], "- ")

	-- Check soon, but not right away. This delta has to be long enough that the
	-- factory we're assisting (while in repair mode) has started the next unit.
	local delta = 15
	trackedUnits[unitID] = trackedUnits[unitID] or
			{checkFrame=currentFrame + delta, settleFrame=currentFrame+delta}
	trackedUnits[unitID].checkFrame =
		max(
			min(
				trackedUnits[unitID].checkFrame,
				trackedUnits[unitID].settleFrame),
			currentFrame + delta)
	queue:push({trackedUnits[unitID].checkFrame, unitID})
	--TableEcho(trackedUnits[unitID], "+ ")
end

-- Called for every game simulation frame (30 per second).
function widget:GameFrame(frame)
	if not enableIdleNanos then
		return
	end

	currentFrame = frame

	while true do
		local entry = queue:peek()
		if entry and frame >= entry[1] then
			queue:pop()

			local unitID = entry[2]

			--Log("Process unit " .. unitID .. " because " .. frame .. " >= ".. entry[1])

			if trackedUnits[unitID] and entry[1] == trackedUnits[unitID].checkFrame then
				-- Otherwise, we queued this unit multiple times and this is not
				-- the "real" one so discard it. That's simpler than removing a
				-- stale entry from the queue.

				if spValidUnitID(unitID) then
					SetupUnit(unitID)
				else
					trackedUnits[unitID] = nil
				end
			end
		else
			break
		end
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
