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
local checkInterval = 20 * 30
-- Don't issue a new command if less than `settleInterval` seconds have passed,
-- even if the unit became idle. This is a simple rate limiter on issuing
-- commands in case there are caretakers with nothing to do for their current
-- state.
local settleInterval = 5 * 30

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

local resourceCacheInterval = 1
local resourceCache = { updated=nil }
-- TODO:
-- We should return which commands we do and which we do not want issued,
-- so we will reissue if we have strictly fewer options than before.
local function DecideCommands(x, y, z, buildDistance)
	if resourceCache.updated == nil or
			resourceCache.updated + resourceCacheInterval < currentFrame then
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

		resourceCache.updated = currentFrame
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

	local function reclaim_metal() return {CMD_RECLAIM, {x, y, z, buildDistance}, 0, "reclaim metal"} end
	local function reclaim_energy() return {CMD_RECLAIM, {x, y, z, buildDistance}, CMD_OPT_CTRL, "reclaim energy"} end
	local function repair_units() return {CMD_REPAIR, {x, y, z, buildDistance}, CMD_OPT_META, "repair units"} end
	local function build_assist() return {CMD_REPAIR, {x, y, z, buildDistance}, 0, "build assist"} end

	-- Patrolling doesn't do anything if you target the current location of
	-- the unit. Point patrol towards map center.
	local vx = mapCenterX - x
	local vz = mapCenterZ - z
	local function patrol() return {CMD_PATROL, {x + vx*25/abs(vx), y, z + vz*25/abs(vz)}, 0, "patrol"} end

	local commands = {}

	if get_metal and use_metal and use_energy then
		commands[#commands + 1] = patrol()
	else
		if use_metal and use_energy then
			commands[#commands + 1] = build_assist()
		end
		if use_energy then
			commands[#commands + 1] = repair_units()
		end
		if get_metal and get_energy then
			if metal > energy then
				commands[#commands + 1] = reclaim_energy()
				commands[#commands + 1] = reclaim_metal()
			else
				commands[#commands + 1] = reclaim_metal()
				commands[#commands + 1] = reclaim_energy()
			end
		elseif get_metal then
			commands[#commands + 1] = reclaim_metal()
		elseif get_energy then
			commands[#commands + 1] = reclaim_energy()
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
		trackedUnits[unitID].checkFrame = currentFrame + RandomInterval(checkInterval)
		local cmds = DecideCommands(x, y, z, buildDistance)
		--TableEcho(cmds, "cmds: ")

		local commandQueue = spGetCommandQueue(unitID, -1)
		--Log(currentFrame .. "; cmd queue for " .. unitID .. ":")
		TableEcho(commandQueue, "commandQueue: ")

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
			--Log(tostring(ITableEqual(cmd[2], current.params)))

			-- A single command looks like:
			-- id = 15
			-- tag = 121
			-- options = {
			--     alt = false
			--     ctrl = false
			--     internal = false
			--     coded = 0
			--     right = false
			--     meta = false
			--     shift = false
			-- },
			-- params = {
			--     1 = 4624
			--     2 = 170.444534
			--     3 = 4436
			-- },


			if not current.options.internal then
				foundAnyCommand = true
				-- TODO: here and below also check cmd[3]
				for i, cmd in ipairs(cmds) do
					if current.id == cmd[1] and
							ITableEqual(cmd[2], current.params) then
						foundCommand[i] = true
					end
				end

				if trackedUnits[unitID].commands then
					for i, cmd in ipairs(trackedUnits[unitID].commands) do
						if current.id == cmd[1] and
								ITableEqual(current.params, cmd[2]) then
							foundIssuedCommand = true
						end
					end
				end
			end
		end

		if foundAnyCommand and not foundIssuedCommand then
			Log("Ignore unit " .. unitID .. " until it becomes idle.")
			trackedUnits[unitID] = nil
			return
		end

		queue:push({trackedUnits[unitID].checkFrame, unitID})
		if AllTrue(foundCommand) then
			--Log("All commands were already issued")
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
		trackedUnits[unitID].settleFrame = currentFrame + RandomInterval(settleInterval)
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

			Log("Process unit " .. unitID .. " because " .. frame .. " >= ".. entry[1])

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
