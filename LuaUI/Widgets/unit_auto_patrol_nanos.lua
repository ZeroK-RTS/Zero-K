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
-- 1. Idle caretakers will be set to area repair units, area assist build (which
--    includes repair units), area reclaim metal, area reclaim energy, or patrol,
--    depending on available resources.
-- 2. For each caretaker under this widget's control, re-evaluate the behavior based
--    on the economy every 10 seconds. (Controlled by checkInterval.)
-- 3. For each caretaker, never issue a command more than once every 2.5 seconds.
--    (Controlled by settleInterval.)
-- 4. When a user issues a stop command, this behavior is inhibited, until a
--    different command issued by the user completes. (Unless stop_disables option
--    is false.)
-- 5. When a user issues some other kind of command, the widget ignores the unit
--    until it becomes idle again.
--
-- Limitations:
-- 1. When the widget chooses repair only, there's a 0.5 second delay between
--    a unit becoming idle and being told to repair. This is to give the factory
--    that's being assisted time to start the next unit. It is not perfect, and the
--    factory will be assisted less than if a patrol was issued. This could be
--    improved by reducing the delay, and implementing a fancier incremental
--    back-off than the simple 0.5s - 5s that is currently implemented.
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

local CMD_PATROL        = CMD.PATROL		-- 15
local CMD_FIGHT         = CMD.FIGHT			-- 16
local CMD_RECLAIM       = CMD.RECLAIM		-- 90
local CMD_REPAIR        = CMD.REPAIR		-- 40
local CMD_STOP          = CMD.STOP
local CMD_OPT_ALT       = CMD.OPT_ALT		-- 128
local CMD_OPT_CTRL      = CMD.OPT_CTRL		-- 64
local CMD_OPT_SHIFT     = CMD.OPT_SHIFT		-- 32
local CMD_OPT_META      = CMD.OPT_META		-- 4
local CMD_OPT_INTERNAL  = CMD.OPT_INTERNAL	-- 8

local spGetMyTeamID     = Spring.GetMyTeamID
local spGetTeamUnits    = Spring.GetTeamUnits
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

local debug = true

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Constants

local FPS = Game.gameSpeed

local PATROL = 1
local RECLAIM_METAL = 2
local RECLAIM_ENERGY = 3
local REPAIR_UNITS = 4
local BUILD_ASSIST = 5

-- Check that a unit is still doing the right thing every `checkInterval`
-- frames.
local checkInterval = 4 * FPS

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
	return math.floor(interval + (math.random() * interval * 0.2 - 0.1))
end

local function Log(...)
	local msg = "[uapn] "
	for i = 1, select('#', ...) do
		msg = msg .. tostring(select(i, ...))
	end
	spEcho(msg)
end

local function IsImmobileBuilder(ud)
	return(ud and ud.isBuilder and not ud.canMove and not ud.isFactory)
end

local function DecideCommands(unitID)
	-- For now, assume the unit is currently idle. We really ought to figure out
	-- if it is doing something because there's a big different between going
	-- from idle to repair and going from reclaiming metal to repair.

	local trackedUnit = trackedUnits[unitID]

	local metal, metalStorage, metalPull, metalIncome =
			spGetTeamResources(spGetMyTeamID(), "metal")
	metalStorage = metalStorage - HIDDEN_STORAGE
	if debug then
		Log("metal=", metal, "; storage=",
				metalStorage, "; pull=", metalPull, "; income=", metalIncome)
	end
	local energy, energyStorage, energyPull, energyIncome =
			spGetTeamResources(spGetMyTeamID(), "energy")
	energyStorage = energyStorage - HIDDEN_STORAGE

	local get_metal, get_energy, use_metal, use_energy

	if metalStorage < 1 then
		get_metal = metalPull >= metalIncome
		use_metal = metalPull <= metalIncome
	else
		local futureMetal = max(0, min(metalStorage, metal + checkInterval * (metalIncome - metalPull) / FPS))
		-- Only get metal if we won't waste any metal by doing so.
		local metalProduction = checkInterval * trackedUnit.reclaimSpeed / FPS
		get_metal = futureMetal + metalProduction <= metalStorage
		-- Only use metal if we won't waste any build power by doing so.
		local metalUse = checkInterval * trackedUnit.buildSpeed / FPS
		use_metal = futureMetal - metalUse >= 0
	end

	if energyStorage < 1 then
		get_energy = energyPull >= energyIncome
		use_energy = energyPull <= energyIncome
	else
		local futureEnergy = energy + checkInterval * (energyIncome - energyPull) / FPS
		-- Only get energy if we have storage for it.
		local energyProduction = checkInterval * trackedUnit.reclaimSpeed / FPS
		get_energy = futureEnergy + energyProduction <= energyStorage
		-- Only use energy if we won't waste any build power by doing so. It
		-- would go to overdrive, but it's better to keep reserves on the
		-- ground.
		local energyUse = checkInterval * trackedUnit.repairSpeed / FPS
		use_energy = futureEnergy - energyUse >= 0
	end

	if debug then
		Log("get_metal=", get_metal, ", ", "use_metal=", use_metal, ", ",
			"get_energy=", get_energy, ", ", "use_energy=", use_energy)
	end

	-- Reuse commands to avoid table allocation
	local commands = {}
	local i = 1

	if use_metal and use_energy then
		commands[i] = BUILD_ASSIST
		i = i + 1
	end
	if use_energy then
		commands[i] = REPAIR_UNITS
		i = i + 1
	end
	if get_metal and get_energy then
		if metal > energy then
			commands[i] = RECLAIM_ENERGY
			commands[i + 1] = RECLAIM_METAL
		else
			commands[i] = RECLAIM_METAL
			commands[i + 1] = RECLAIM_ENERGY
		end
		i = i + 2
	elseif get_metal then
		commands[i] = RECLAIM_METAL
		i = i + 1
	elseif get_energy then
		commands[i] = RECLAIM_ENERGY
		i = i + 1
	end

	-- Queue up commands that would waste build power at the end, because build
	-- power cannot be stored.
	if not use_metal or not use_energy then
		commands[i] = BUILD_ASSIST
		i = i + 1
	end
	if not use_energy then
		commands[i] = REPAIR_UNITS
		i = i + 1
	end

	-- Terminate the list with nil
	commands[i] = nil

	return commands
end

local function MakeCommands(decidedCommands, unitID)
	if not trackedUnits[unitID].commandTables then
		-- Cache commands inside trackedUnits. This saves a ton of table
		-- creation.
		local x, y, z = spGetUnitPosition(unitID)
		if not x then
			return nil
		end

		trackedUnits[unitID].commandTables = {}

		local buildDistance = trackedUnits[unitID].buildDistance

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
		if not decided then
			break
		end
		commands[i] = trackedUnits[unitID].commandTables[decided]
	end

	return commands
end

-- Return true iff the issued command could cause the current command. This
-- includes internal commands, because some area commands replace the command
-- with an internal to track of their state, instead of inserting new commands
-- into the queue. If we ignore all internal commands, then we cannot determine
-- whether such commands are still running or not.
-- This code relies on implementation details of the spring engine, but I don't
-- see any way around that.
local remove_shift_internal = math.bit_inv(CMD_OPT_SHIFT + CMD_OPT_INTERNAL)
local function IssuedCausesCurrent(issued, currentID, currentOpt,
		currentParam1, currentParam2, currentParam3, currentParam4, currentParam5)
	--Log("compare")
	--Log(" issued : ", issued[1], "(", issued[2][1], ", ", issued[2][2], ", ",
	--	issued[2][3], ", ", issued[2][4], ", ", issued[2][5], ") ",
	--	issued[3], " (", issued[4], ")")
	--Log(" current: ", currentID, "(", currentParam1, ", ", currentParam2,
	--	", ", currentParam3, ", ", currentParam4, ", ", currentParam5, ") ",
	--	currentOpt)

	if not currentID or not issued then
		return false
	end

	-- Commands that were exactly what we issued.
	if currentID == issued[1] and
			issued[2][1] == currentParam1 and
			issued[2][2] == currentParam2 and
			issued[2][3] == currentParam3 and
			issued[2][4] == currentParam4 and
			issued[2][5] == currentParam5 and
			issued[3] == currentOpt then
		--Log("    -> equal")
		return true
	end

	-- Area repair/reclaim command. The spring engine puts the unit being
	-- repaired/reclaimed(?) as the first parameter, and moves the issued
	-- parameters down one.
	if currentID == issued[1] and
			(currentID == CMD_RECLAIM or currentID == CMD_REPAIR) and
			#issued[2] == 4 and
			issued[2][1] == currentParam2 and
			issued[2][2] == currentParam3 and
			issued[2][3] == currentParam4 and
			issued[2][4] == currentParam5 and
			issued[3] == math.bit_and(currentOpt, remove_shift_internal) then
		--Log("    -> repair/reclaim")
		return true
	end

	if issued[1] == CMD_PATROL then
		-- Patrol commands are issued with a location, but that locations is
		-- changed so we can't rely on it. Maybe it's getting changed because we
		-- issue a location out of range or something. That might be fixable.
		if (currentID == CMD_REPAIR or currentID == CMD_RECLAIM) and
				currentOpt == CMD_OPT_INTERNAL and
				currentParam5 ~= nil then
			--Log("    -> patrol, repair")
			return true
		elseif currentID == CMD_PATROL then
			--Log("    -> patrol")
			return true
		elseif currentID == CMD_FIGHT and
				currentOpt == CMD_OPT_INTERNAL then
			--Log("    -> patrol, fight")
			return true
		end
	end

	--Log("    -> false")
	return false
end

local function unit_new(unitID)
	local unitDefID = spGetUnitDefID(unitID)

	return {
		unitID=unitID,
		idleWait=1,
		checkFrame=currentFrame + checkInterval,
		resetIdle=0,
		idleAt=0,
		buildDistance=UnitDefs[unitDefID].buildDistance,
		buildSpeed=UnitDefs[unitDefID].buildSpeed,
		repairSpeed=UnitDefs[unitDefID].repairSpeed,
		reclaimSpeed=UnitDefs[unitDefID].reclaimSpeed
	}
end

local function caretaker_string(caretaker)
	return caretaker.unitID .. " (iW=" .. caretaker.idleWait ..
			", cF=" .. caretaker.checkFrame .. ", rI=" .. caretaker.resetIdle .. ")"
end

local function SetupUnit(unitID)
	trackedUnits[unitID] = trackedUnits[unitID] or unit_new(unitID)

	local trackedUnit = trackedUnits[unitID]

	trackedUnit.checkFrame = currentFrame + RandomInterval(checkInterval)
	queue:push({trackedUnit.checkFrame, unitID})

	local decisions = DecideCommands(unitID)
	local cmds = MakeCommands(decisions, unitID)

	--TableEcho(cmds, "want to issue cmds")

	if not cmds then
		return
	end

	local currentID, currentOpt, _, currentParam1,
			currentParam2, currentParam3, currentParam4, currentParam5 =
			spGetUnitCurrentCommand(unitID)
	--Log(unitID, "; currently executing ", currentID, "(", currentParam1,
	--	", ", currentParam2, ", ", currentParam3, ", ", currentParam4, ", ",
	--	currentParam5, ") ", currentOpt)

	if currentID then
		if IssuedCausesCurrent(cmds[1], currentID, currentOpt,
				currentParam1, currentParam2, currentParam3,
				currentParam4, currentParam5) then
			-- The unit is doing something that could be caused by the top command
			-- we were going to issue. That's good enough.
			--Log("Unit is doing good work. Don't touch it.")
			return
		end

		local isIssued = false
		if trackedUnit.commands then
			for i = 1, #trackedUnit.commands do
				if IssuedCausesCurrent(trackedUnit.commands[i], currentID,
						currentOpt, currentParam1, currentParam2, currentParam3,
						currentParam4, currentParam5) then
					isIssued = true
					break
				end
			end
		end

		if not isIssued then
			-- Unit is doing something we never asked for. Must have been commanded
			-- by a user.
			--Log(unitID, " was commanded ", currentID, "(",
			--	currentParam1, ", ",
			--	currentParam2, ", ",
			--	currentParam3, ", ",
			--	currentParam4, ", ",
			--	currentParam5, ") ", currentOpt)
			--Log("Ignore unit ", unitID, " until it becomes idle.")
			trackedUnits[unitID] = nil
			return
		end
	end

	for i, cmd in ipairs(cmds) do
		if i == 1 then
			spGiveOrderToUnit(unitID, cmd[1], cmd[2], cmd[3])
			if debug then
				Log(unitID, "; give order ", cmd[1], "(", cmd[2][1], ", ",
						cmd[2][2], ", ", cmd[2][3], ", ", cmd[2][4], ", ",
						cmd[2][5], ") ", cmd[3], " (", cmd[4], ")")
			end
		else
			spGiveOrderToUnit(unitID, cmd[1], cmd[2], cmd[3] + CMD_OPT_SHIFT)
			if debug then
				Log(unitID, "; queue order ", cmd[1], "(", cmd[2][1], ", ",
						cmd[2][2], ", ", cmd[2][3], ", ", cmd[2][4], ", ",
						cmd[2][5], ") ", cmd[3], " (", cmd[4], ")")
			end
		end
	end
	trackedUnit.commands = cmds
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

-- Called whenever a unit gets a command from any source, including this widget!
-- But does not get called when patrol or area reclaim/repair commands modify
-- the command queue.
function widget:UnitCommand(unitID, unitDefID, unitTeam, cmdID, cmdParams, cmdOptions)
	if not enableIdleNanos
			or cmdOptions.internal
			or unitTeam ~= spGetMyTeamID()
			or not IsImmobileBuilder(UnitDefs[unitDefID])
			or spGetGameRulesParam("loadPurge") == 1 then
		return
	end

	if stopHalts then
		if cmdID == CMD_STOP then
			if not stoppedUnit[unitID] then
				Log("Ignore unit ", unitID, " until it is given a command.")
			end
			stoppedUnit[unitID] = true
		elseif stoppedUnit[unitID] then
			if stoppedUnit[unitID] ~= nil then
				Log("Pay attention to unit ", unitID, " again.")
			end
			stoppedUnit[unitID] = nil
		end
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

	if not trackedUnits[unitID] then
		trackedUnits[unitID] = unit_new(unitID)
	end
	local trackedUnit = trackedUnits[unitID]

	if currentFrame <= trackedUnit.idleAt then
		-- UnitIdle can get called multiple times per frame. If that happens, we
		-- don't want to bump idleWait every time, so exit early.
		return
	end
	trackedUnit.idleAt = currentFrame

	if debug then
		Log("UnitIdle(", caretaker_string(trackedUnit), ")")
	end
	--TableEcho(trackedUnits[unitID], "- ")

	if currentFrame > trackedUnit.resetIdle then
		trackedUnit.idleWait = 1
	end
	trackedUnit.checkFrame = currentFrame + RandomInterval(trackedUnit.idleWait)
	trackedUnit.idleWait = min(trackedUnit.idleWait * 2, checkInterval)
	-- If we're not idle at that point, we must have found some work to do.
	trackedUnit.resetIdle = trackedUnit.checkFrame + 1
	queue:push({trackedUnits[unitID].checkFrame, unitID})
	--Log("  set checkFrame to ", trackedUnits[unitID].checkFrame)
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

			if trackedUnits[unitID] then
				--Log(unitID, "; ", frame, " >= ".. entry[1],
				--		"; checkFrame=", trackedUnits[unitID].checkFrame)

				if entry[1] == trackedUnits[unitID].checkFrame then
					-- Otherwise, we queued this unit multiple times and this is not
					-- the "real" one so discard it. That's simpler than removing a
					-- stale entry from the queue.

					if spValidUnitID(unitID) then
						SetupUnit(unitID)
					else
						trackedUnits[unitID] = nil
					end
				end
			end
		else
			break
		end
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
