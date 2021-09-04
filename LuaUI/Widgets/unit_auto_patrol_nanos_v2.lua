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
--    on the economy every 4 seconds. (Controlled by checkInterval.)
-- 3. When a caretaker becomes idle, quickly issue new commands. This is
--    essential to effectively assist factories.
-- 4. When a user issues a stop command, this behavior is inhibited, until a
--    different command issued by the user completes. (Unless stop_disables option
--    is false.)
-- 5. When a user issues some other kind of command, the widget ignores the unit
--    until it becomes idle again.
--
-- Limitations:
-- 1. When a unit is assisting a factory and there is sufficient available
--    metal/energy storage, then the unit will spend some time reclaiming
--    metal/energy after the factory has finished building something, before being
--    told to assist the factory again. This does not happen in a "normal" economy
--    where you are limited by metal and have an energy surplus.
--    As a workaround you can give a caretaker a patrol order.
--
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
VFS.Include("LuaRules/Configs/constants.lua")

local PriorityQueue = VFS.Include("LuaRules/Gadgets/Include/PriorityQueue.lua")

function widget:GetInfo()
  return {
    name      = "Auto Patrol Nanos v2",
    desc      = "Make caretakers patrol, reclaim, or repair, depending on metal storage.",
    author    = "trepan",
    date      = "Jan 8, 2007",
    license   = "GNU GPL, v2 or later",
    layer     = -2,
    enabled   = false  --  loaded by default?
  }
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Speedups

local CMD_PATROL        = CMD.PATROL        -- 15
local CMD_FIGHT         = CMD.FIGHT	        -- 16
local CMD_RECLAIM       = CMD.RECLAIM       -- 90
local CMD_REPAIR        = CMD.REPAIR        -- 40
local CMD_STOP          = CMD.STOP
local CMD_OPT_ALT       = CMD.OPT_ALT       -- 128
local CMD_OPT_CTRL      = CMD.OPT_CTRL      -- 64
local CMD_OPT_SHIFT     = CMD.OPT_SHIFT     -- 32
local CMD_OPT_META      = CMD.OPT_META      -- 4
local CMD_OPT_INTERNAL  = CMD.OPT_INTERNAL  -- 8

local spGetMyTeamID     = Spring.GetMyTeamID
local spGetTeamUnits    = Spring.GetTeamUnits
local spGetUnitDefID    = Spring.GetUnitDefID
local spGetUnitPosition = Spring.GetUnitPosition
local spGiveOrderToUnit = Spring.GiveOrderToUnit
local spGetGameRulesParam = Spring.GetGameRulesParam
local spEcho            = Spring.Echo
local spGetTeamResources = Spring.GetTeamResources
local spValidUnitID     = Spring.ValidUnitID
local spGetUnitCurrentCommand = Spring.GetUnitCurrentCommand
local spGetUnitResources = Spring.GetUnitResources
local spGetUnitHealth = Spring.GetUnitHealth

local TableEcho = Spring.Utilities.TableEcho

local abs = math.abs
local min = math.min
local max = math.max

local mapCenterX = Game.mapSizeX / 2
local mapCenterZ = Game.mapSizeZ / 2

local debug = false

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Constants

local FPS = Game.gameSpeed

local PATROL = 1
local RECLAIM_ALL = 2
local RECLAIM_METAL = 3
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

local function mapEcho(unitID, text)
	local x, y, z = spGetUnitPosition(unitID)
	Spring.MarkerAddPoint(x, y, z, text)
end

local function mapClear(unitID)
	local x, y, z = spGetUnitPosition(unitID)
	Spring.MarkerErasePosition(x, y, z)
end

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
	local trackedUnit = trackedUnits[unitID]

	local metalMake, metalUse, energyMake, energyUse = spGetUnitResources(unitID)

	-- One time, metalUse came back 0 and the script crashed.
	if metalMake == nil or metalUse == nil or energyMake == nil or energyUse == nil then
		return {trackedUnit.commandTables[REPAIR_UNITS]}
	end

	local metal, metalStorage, metalPull, metalIncome, metalExpense,
			metalShare, metalSent, metalReceived, metalExcess =
			spGetTeamResources(spGetMyTeamID(), "metal")
	metalStorage = metalStorage - HIDDEN_STORAGE
	if debug then
		Log("metal=", metal,
				"; storage=", metalStorage,
				"; pull=", metalPull,
				"; income=", metalIncome, " - ", metalMake,
				"; expense=", metalExpense, " - ", metalUse,
				"; share=", metalShare,
				"; sent=", metalSent,
				"; received=", metalReceived,
				"; excess=", metalExcess)
	end
	local energy, energyStorage, energyPull, energyIncome, energyExpense,
			energyShare, energySent, energyReceived, energyExcess =
			spGetTeamResources(spGetMyTeamID(), "energy")
	energyStorage = energyStorage - HIDDEN_STORAGE
	if debug then
		Log("energy=", energy,
				"; storage=", energyStorage,
				"; pull=", energyPull,
				"; income=", energyIncome, " - ", energyMake,
				"; expense=", energyExpense, " - ", energyUse,
				"; share=", energyShare,
				"; sent=", energySent,
				"; received=", energyReceived,
				"; excess=", energyExcess)
	end

	-- Subtract what the unit is currently doing from the overall metal/energy
	-- use/production.
	metalExpense = metalExpense - metalUse
	metalIncome = metalIncome - metalMake
	energyExpense = energyExpense - energyUse
	energyIncome = energyIncome - energyMake

	local get_metal, get_energy, use_metal, use_energy

	if metalStorage < 1 then
		get_metal = metalExpense >= metalIncome
		use_metal = metalExpense <= metalIncome
	else
		local future = max(0, min(metalStorage, metal + checkInterval * (metalIncome - metalExpense) / FPS))
		-- Only get metal if we won't waste any metal by doing so.
		local production = checkInterval * trackedUnit.reclaimSpeed / FPS
		get_metal = future + production <= metalStorage
		-- Only use metal if we won't waste any build power by doing so.
		use_metal = future >= checkInterval * trackedUnit.buildSpeed / FPS
	end

	if energyStorage < 1 then
		get_energy = energyExpense >= energyIncome
		use_energy = energyExpense <= energyIncome
	else
		local future = energy + checkInterval * (energyIncome - energyExpense) / FPS
		-- Because there is no reclaim energy command, (the command will also
		-- reclaim metal), only get energy if we won't exceed half of our storage.
		-- That way we'll avoid energy stalls, but also avoid reclaiming metal if
		-- we don't really need the energy right now.
		local production = checkInterval * trackedUnit.reclaimSpeed / FPS
		get_energy = future + production <= energyStorage / 2
		-- Only use energy if we won't waste any build power by doing so. It
		-- would go to overdrive, but it's better to keep reserves on the
		-- ground.
		use_energy = future >= checkInterval * trackedUnit.buildSpeed / FPS
	end

	if debug then
		Log("get_metal=", get_metal, ", ", "use_metal=", use_metal, ", ",
			"get_energy=", get_energy, ", ", "use_energy=", use_energy)
	end

	local commands = {}
	local commandTables = trackedUnit.commandTables

	if use_metal and use_energy then
		commands[#commands + 1] = commandTables[BUILD_ASSIST]
	end
	if use_energy then
		commands[#commands + 1] = commandTables[REPAIR_UNITS]
	end
	if get_metal and get_energy then
		commands[#commands + 1] = commandTables[RECLAIM_ALL]
	elseif get_metal then
		commands[#commands + 1] = commandTables[RECLAIM_METAL]
	elseif get_energy then
		-- There is no RECLAIM_ENERGY, unfortunately.
		commands[#commands + 1] = commandTables[RECLAIM_ALL]
	end

	-- Queue up commands that would waste build power at the end, because build
	-- power cannot be stored.
	if not use_metal or not use_energy then
		commands[#commands + 1] = trackedUnit.commandTables[BUILD_ASSIST]
	end
	if not use_energy then
		commands[#commands + 1] = trackedUnit.commandTables[REPAIR_UNITS]
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
local remove_control = math.bit_inv(CMD_OPT_CTRL)
local function IssuedCausesCurrent(issued, currentID, currentOpt,
		currentParam1, currentParam2, currentParam3, currentParam4, currentParam5)
	Log("compare")
	Log(" issued : ", issued[1], "(", issued[2][1], ", ", issued[2][2], ", ",
		issued[2][3], ", ", issued[2][4], ", ", issued[2][5], ") ",
		issued[3], " (", issued[4], ")")
	Log(" current: ", currentID, "(", currentParam1, ", ", currentParam2,
		", ", currentParam3, ", ", currentParam4, ", ", currentParam5, ") ",
		currentOpt)

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
			issued[3] == math.bit_and(currentOpt, remove_shift_internal) then
		Log("    -> equal")
		return true
	end

	-- Area repair/reclaim commands. The spring engine puts the unit being
	-- repaired/reclaimed as the first parameter, and moves the issued
	-- parameters down one. (See CBuilderCAI::FindReclaimTargetAndReclaim() and
	-- CBuilderCAI::FindRepairTargetAndRepair().)
	-- We explicitly ignore the options. The logic is hard to follow, and if the
	-- command is a result of reclaim/repair with the exact area that we issued,
	-- then that must be issued by our widget and not a user.

	if issued[1] == CMD_RECLAIM then
		if currentID == CMD_RECLAIM and
				#issued[2] == 4 and
				issued[2][1] == currentParam2 and
				issued[2][2] == currentParam3 and
				issued[2][3] == currentParam4 and
				issued[2][4] == currentParam5 then
			Log("    -> reclaim")
			return true
		end
	elseif issued[1] == CMD_REPAIR then
		if currentID == CMD_REPAIR and
				#issued[2] == 4 and
				issued[2][1] == currentParam2 and
				issued[2][2] == currentParam3 and
				issued[2][3] == currentParam4 and
				issued[2][4] == currentParam5 then
			Log("    -> repair")
			return true
		end
	end

	Log("    -> false")
	return false
end

local function unitNew(unitID)
	local unitDefID = spGetUnitDefID(unitID)

	-- Precompute commands. This saves a ton of table creation.
	local x, y, z = spGetUnitPosition(unitID)

	local commandTables = {}

	-- Patrolling doesn't do anything if you target the current location
	-- of the unit. Point patrol towards map center.
	local vx = mapCenterX - x
	local vz = mapCenterZ - z
	commandTables[PATROL] = {CMD_PATROL, {x + vx*25/abs(vx), y, z + vz*25/abs(vz)}, 0, "patrol"}

	-- Instead of using a range of UnitDefs[unitDefID].buildDistance, we make
	-- the range giant so that when you hold down shift you don't see circles
	-- around every caretaker.
	local area = {x, y, z, 50000}
	commandTables[RECLAIM_ALL] = {CMD_RECLAIM, area, CMD_OPT_CTRL, "reclaim all"}
	commandTables[RECLAIM_METAL] = {CMD_RECLAIM, area, 0, "reclaim metal"}
	commandTables[REPAIR_UNITS] = {CMD_REPAIR, area, CMD_OPT_META, "repair units"}
	commandTables[BUILD_ASSIST] = {CMD_REPAIR, area, 0, "build assist"}

	return {
		unitID=unitID,
		idleWait=1,
		checkFrame=currentFrame + checkInterval,
		resetIdle=0,
		idleAt=0,
		buildDistance=UnitDefs[unitDefID].buildDistance,
		buildSpeed=UnitDefs[unitDefID].buildSpeed,
		repairSpeed=UnitDefs[unitDefID].repairSpeed,
		reclaimSpeed=UnitDefs[unitDefID].reclaimSpeed,
		commandTables=commandTables
	}
end

local function unitString(unit)
	return unit.unitID .. " (iW=" .. unit.idleWait ..
			", cF=" .. unit.checkFrame .. ", rI=" .. unit.resetIdle .. ")"
end

local function UpdateUnit(unitID)
	local trackedUnit = trackedUnits[unitID]

	trackedUnit.checkFrame = currentFrame + RandomInterval(checkInterval)
	queue:push({trackedUnit.checkFrame, unitID})
	if debug then
		Log(unitID, "; push for ", trackedUnit.checkFrame)
	end

	local cmds = DecideCommands(unitID)

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
			if debug then
				Log(unitID, "; Unit is doing good work. Don't touch it.")
			end
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
			if debug then
				Log(unitID, "; was commanded ", currentID, "(",
					currentParam1, ", ",
					currentParam2, ", ",
					currentParam3, ", ",
					currentParam4, ", ",
					currentParam5, ") ", currentOpt)
				Log(unitID, "; Ignore until it becomes idle (commanded).")
				mapEcho(unitID, "Ignore until idle")
			end
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

local function SetupUnit(unitID)
	trackedUnits[unitID] = trackedUnits[unitID] or unitNew(unitID)

	-- health, maxHealth, paralyzeDamage, captureProress, buildProgress
	local _, _, _, _, buildProgress = spGetUnitHealth(unitID)
	if buildProgress >= 1 then
		UpdateUnit(unitID)
	end
	-- If the unit isn't done building, we'll hear about it when it becomes idle
	-- in UnitIdle().
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
	if (Spring.GetSpectatingState() or Spring.IsReplay()) and (not Spring.IsCheatingEnabled()) then
		Spring.Echo("uapn2 disabled for spectators")
		widgetHandler:RemoveWidget()
	end

	SetupAll()
end

function widget:UnitCreated(unitID, unitDefID, unitTeam)
	if not enableIdleNanos or unitTeam ~= spGetMyTeamID()
			or not IsImmobileBuilder(UnitDefs[unitDefID])
			or spGetGameRulesParam("loadPurge") == 1 then
		return
	end

	if debug then
		Log(unitID, "; created")
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
	if debug and
			unitTeam == spGetMyTeamID() and
			not spGetGameRulesParam("loadPurge") and
			IsImmobileBuilder(UnitDefs[unitDefID]) then
		Log("UnitCommand ", unitID, ": ", cmdID, " (", cmdParams[1], ", ",
				cmdParams[2], ", ", cmdParams[3], ", ", cmdParams[4],
				", ", cmdParams[5], ") ", OptionValue(cmdOptions))
	end

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
				mapEcho(unitID, "Ignore until idle (stopped).")
			end
			stoppedUnit[unitID] = true
		elseif stoppedUnit[unitID] then
			if stoppedUnit[unitID] ~= nil then
				Log("Pay attention to unit ", unitID, " again.")
				mapClear(unitID)
			end
			stoppedUnit[unitID] = nil
		end
	end
end

function widget:UnitGiven(unitID, unitDefID, unitTeam)
	if debug then
		Log(unitID, "; given")
	end
	widget:UnitCreated(unitID, unitDefID, unitTeam)
end

function widget:UnitFinished(unitID, unitDefID, unitTeam)
	if not enableIdleNanos or stoppedUnit[unitID]
			or unitTeam ~= spGetMyTeamID()
			or not IsImmobileBuilder(UnitDefs[unitDefID])
			or spGetGameRulesParam("loadPurge") == 1 then
		return
	end

	if trackedUnits[unitID] then
		if debug then
			Log(unitID, "; finished")
		end
		UpdateUnit(unitID)
	end
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
		trackedUnits[unitID] = unitNew(unitID)
		Log("Pay attention to unit ", unitID, " again.")
		mapClear(unitID)
	end
	local trackedUnit = trackedUnits[unitID]

	if currentFrame <= trackedUnit.idleAt then
		-- UnitIdle can get called multiple times per frame. If that happens, we
		-- don't want to bump idleWait every time, so exit early.
		return
	end
	trackedUnit.idleAt = currentFrame

	if debug then
		Log(unitID, "; UnitIdle(", unitString(trackedUnit), ")")
	end
	--TableEcho(trackedUnits[unitID], "- ")

	if currentFrame > trackedUnit.resetIdle then
		trackedUnit.idleWait = 1
	end
	trackedUnit.checkFrame = currentFrame + RandomInterval(trackedUnit.idleWait)
	trackedUnit.idleWait = min(trackedUnit.idleWait * 2, checkInterval)
	-- If we're not idle at that point, we must have found some work to do.
	trackedUnit.resetIdle = trackedUnit.checkFrame + 1
	queue:push({trackedUnit.checkFrame, unitID})
	if debug then
		Log(unitID, "; push for ", trackedUnit.checkFrame)
	end
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
						UpdateUnit(unitID)
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
