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
--		on the economy every 20 seconds. (Controlled by checkInterval.)
--   3. For each caretaker, never issue a command more than once every 5 seconds.
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
local CMD_OPT_CTRL      = CMD.OPT_CTRL
local CMD_OPT_SHIFT     = CMD.OPT_SHIFT
local CMD_OPT_META      = CMD.OPT_META

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

local TableEcho = Spring.Utilities.TableEcho

local abs = math.abs
local min = math.min
local max = math.max

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
-- Map from unitID -> { checkTime, settleTime, command }
local trackedUnits = {}
-- The current time, in seconds (I think)
local time = 0
local nextCheck

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

local function TableEqual(a, b)
	for k, v in pairs(a) do
		if b[k] ~= v then
			return false
		end
	end

	for k, v in pairs(b) do
		if a[k] ~= v then
			return false
		end
	end

	return true
end

local function UpdateNextCheck()
	nextCheck = nil
	for _, info in pairs(trackedUnits) do
		if nextCheck == nil or info.checkTime < nextCheck then
			nextCheck = info.checkTime
		end
	end
	--Log("Update nextCheck to " .. tostring(nextCheck))
end

local function IsImmobileBuilder(ud)
	return(ud and ud.isBuilder and not ud.canMove and not ud.isFactory)
end

local resourceCacheInterval = 1
local resourceCache = { updated=nil }
local function DecideCommands(x, y, z, buildDistance)
	if resourceCache.updated == nil or
			resourceCache.updated + resourceCacheInterval < time then
		resourceCache.metal,
			resourceCache.metalStorage,
			resourceCache.metalPull,
			resourceCache.metalIncome = spGetTeamResources(spGetMyTeamID(), "metal")
		resourceCache.metalStorage = resourceCache.metalStorage - HIDDEN_STORAGE
		resourceCache.energy,
			resourceCache.energyStorage,
			resourceCache.energyPull,
			resourceCache.energyIncome = spGetTeamResources(spGetMyTeamID(), "energy")
		resourceCache.energyStorage = resourceCache.energyStorage - HIDDEN_STORAGE

		resourceCache.updated = time
	end

	local metalStorage = resourceCache.metalStorage
	local metalPull = resourceCache.metalPull
	local metalIncome = resourceCache.metalIncome
	local metal = resourceCache.metal + metalIncome - metalPull

	local energyStorage = resourceCache.energyStorage
	local energyPull = resourceCache.energyPull
	local energyIncome = resourceCache.energyIncome
	local energy = resourceCache.energy + energyIncome - energyPull

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

	local reclaim_metal = {CMD_RECLAIM, {x, y, z, buildDistance}, 0, "reclaim metal"}
	local reclaim_energy = {CMD_RECLAIM, {x, y, z, buildDistance}, CMD_OPT_CTRL, "reclaim energy"}
	local repair_units = {CMD_REPAIR, {x, y, z, buildDistance}, CMD_OPT_META, "repair units"}
	local build_assist = {CMD_REPAIR, {x, y, z, buildDistance}, 0, "build assist"}

	-- Patrolling doesn't do anything if you target the current location of
	-- the unit. Point patrol towards map center.
	local vx = mapCenterX - x
	local vz = mapCenterZ - z
	local patrol = {CMD_PATROL, {x + vx*25/abs(vx), y, z + vz*25/abs(vz)}, 0, "patrol"}

	local commands = {}

	if get_metal and use_metal and use_energy then
		table.insert(commands, patrol)
	else
		if use_metal and use_energy then
			table.insert(commands, build_assist)
		end
		if use_energy then
			table.insert(commands, repair_units)
		end
		if get_metal and get_energy then
			if metal > energy then
				table.insert(commands, reclaim_energy)
				table.insert(commands, reclaim_metal)
			else
				table.insert(commands, reclaim_metal)
				table.insert(commands, reclaim_energy)
			end
		elseif get_metal then
			table.insert(commands, reclaim_metal)
		elseif get_energy then
			table.insert(commands, reclaim_energy)
		end
	end

	return commands
end

local function AllTrue(table)
	for _, v in pairs(table) do
		if not v then
			return false
		end
	end
	return true
end

local function SetupUnit(unitID)
	local x, y, z = spGetUnitPosition(unitID)
	if (x) then
		local unitDefID = spGetUnitDefID(unitID)
		local buildDistance = UnitDefs[unitDefID].buildDistance
		trackedUnits[unitID] = trackedUnits[unitID] or {}
		trackedUnits[unitID].checkTime = time + RandomInterval(checkInterval)
		local cmds = DecideCommands(x, y, z, buildDistance)
		TableEcho(cmds, "cmds: ")

		local commandQueue = spGetCommandQueue(unitID, -1)
		--Log(time .. "; cmd queue for " .. unitID .. ":")
		--TableEcho(commandQueue, "commandQueue: ")

		local foundIssuedCommand = false
		local foundAnyCommand = false

		local foundCommand = {}
		for i, _ in ipairs(cmds) do
			foundCommand[i] = false
		end

		for _, current in pairs(commandQueue) do
			--TableEcho(current, "current:")
			--Log(tostring(current.options.internal))
			--Log(tostring(current.id == cmd[1]))
			--Log(tostring(TableEqual(cmd[2], current.params)))

			if not current.options.internal then
				foundAnyCommand = true
				for i, cmd in ipairs(cmds) do
					if current.id == cmd[1] and
							TableEqual(cmd[2], current.params) then
						foundCommand[i] = true
					end
				end

				if trackedUnits[unitID].commands then
					for i, cmd in ipairs(trackedUnits[unitID].commands) do
						if current.id == cmd[1] and
								TableEqual(current.params, cmd[2]) then
							foundIssuedCommand = true
						end
					end
				end
			end
		end

		if AllTrue(foundCommand) then
			--Log("All commands were already issued")
			return
		end

		if foundAnyCommand and not foundIssuedCommand then
			Log("Ignore unit " .. unitID .. " until it becomes idle.")
			trackedUnits[unitID] = nil
			return
		end

		for i, cmd in ipairs(cmds) do
			if i == 1 then
				spGiveOrderToUnit(unitID, cmd[1], cmd[2], cmd[3])
				Log("give order " .. cmd[4] .. " to " .. unitID ..
						" @ " .. x .. ", " .. y .. ", " .. z)
			else
				spGiveOrderToUnit(unitID, cmd[1], cmd[2], cmd[3] + CMD_OPT_SHIFT)
				Log("queue order " .. cmd[4] .. " to " .. unitID ..
						" @ " .. x .. ", " .. y .. ", " .. z)
			end
		end
		trackedUnits[unitID].settleTime = time + RandomInterval(settleInterval)
		trackedUnits[unitID].commands = cmds
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

-- Called whenever a unit gets a command from any source, including this script!
function widget:UnitCommand(unitID, unitDefID, unitTeam, cmdID, cmdParams, cmdOptions)
	if trackedUnits[unitID] == nil then
		return
	end

	--Log("UnitCommand(" .. unitID .. ", " .. unitDefID .. ", " .. unitTeam .. ", " .. cmdID .. ")")
	--TableEcho(cmdParams, "  params: ")
	--TableEcho(cmdOptions, "  options: ")

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

	--Log("UnitIdle:")
	--TableEcho(trackedUnits[unitID], "- ")

	-- Check soon, but not right away. This time has to be long enough that the
	-- factory we're assisting (while in repair mode) has started the next unit.
	local delta = 0.5
	trackedUnits[unitID] = trackedUnits[unitID] or
			{checkTime=time + delta, settleTime=time+delta}
	trackedUnits[unitID].checkTime =
		max(
			min(
				trackedUnits[unitID].checkTime,
				trackedUnits[unitID].settleTime),
			time + delta)
	if nextCheck == nil then
		nextCheck = time + delta
	else
		nextCheck = min(nextCheck, trackedUnits[unitID].checkTime)
	end
	--TableEcho(trackedUnits[unitID], "+ ")
end

function widget:Update(dt)
	time = time + dt
	if not enableIdleNanos then
		return
	end
	if nextCheck ~= nil and time > nextCheck then
		--Log("time to check (" .. time .. ")")
		for unitID, _ in pairs(trackedUnits) do
			if spValidUnitID(unitID) then
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
