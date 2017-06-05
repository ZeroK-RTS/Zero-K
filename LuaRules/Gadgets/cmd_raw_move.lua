function gadget:GetInfo()
	return {
		name 	= "Command Raw Move",
		desc	= "Make unit move ahead at all cost!",
		author	= "xponen, GoogleFrog",
		date	= "June 12 2014",
		license	= "GNU GPL, v2 or later",
		layer	= 0,
		enabled = true,
	}
end
include("LuaRules/Configs/customcmds.h.lua")

if gadgetHandler:IsSyncedCode() then

----------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------
-- Speedups

local spGetUnitPosition   = Spring.GetUnitPosition
local spInsertUnitCmdDesc = Spring.InsertUnitCmdDesc
local spGetUnitCommands   = Spring.GetUnitCommands
local spGetUnitStates     = Spring.GetUnitStates
local spMoveCtrlGetTag    = Spring.MoveCtrl.GetTag

local CMD_STOP   = CMD.STOP
local CMD_INSERT = CMD.INSERT

local stopCommand = {
	[CMD.GUARD] = true,
	[CMD.REPAIR] = true,
	[CMD.RECLAIM] = true,
	[CMD.RESURRECT] = true,
	[CMD_JUMP] = true,
	[CMD.PATROL] = true,
	[CMD.FIGHT] = true,
	[CMD.MOVE] = true,
}

local queueFrontCommand = {
	[CMD.WAIT] = true,
	[CMD.TIMEWAIT] = true,
	[CMD.DEATHWAIT] = true,
	[CMD.SQUADWAIT] = true,
	[CMD.GATHERWAIT] = true,
}

local canMoveDefs = {}
local canFlyDefs = {}
local goalDist = {}
local turnDiameterSq = {}
local turnPeriods = {}
local stopDistSq = {}
local loneStopDistSq = {}
local stoppingRadiusIncrease = {}
local stuckTravelOverride = {}
local startMovingTime = {}

-- Check unit queues because perhaps CMD_RAW_MOVE is not the first command anymore
local unitQueueCheckRequired = false
local unitQueuesToCheck = {}

for i = 1, #UnitDefs do
	local ud = UnitDefs[i]
	if ud.canMove then
		canMoveDefs[i] = true
		local stopDist = ud.xsize*8
		local loneStopDist = 16
		local turningDiameter = 2*(ud.speed*2195/(ud.turnRate * 2 * math.pi))
		if turningDiameter > 20 then
			turnDiameterSq[i] = turningDiameter*turningDiameter
		end
		if ud.turnRate > 150 then
			turnPeriods[i] = math.ceil(1100/ud.turnRate)
		else
			turnPeriods[i] = 8
		end
		if (ud.moveDef.maxSlope or 0) > 0.8 and ud.speed < 60 then
			-- Slow spiders need a lot of leeway when climing cliffs.
			stuckTravelOverride[i] = 5
			startMovingTime[i] = 12 -- May take longer to start moving
			-- Lower stopping distance for more precise placement on terrain
			loneStopDist = 4
		end
		if ud.canFly then
			canFlyDefs[i] = true
			stopDist = ud.speed
			loneStopDist = ud.speed*0.66
			goalDist[i] = 8
		end
		if stopDist then
			stopDistSq[i] = stopDist*stopDist
		end
		loneStopDistSq[i] = (loneStopDist and loneStopDist*loneStopDist) or stopDistSq[i] or 256
		if stopDist and not goalDist[i] then
			goalDist[i] = loneStopDist
		end
		stoppingRadiusIncrease[i] = ud.xsize*250
	end
end

-- Debug
--local oldSetMoveGoal = Spring.SetUnitMoveGoal
--function Spring.SetUnitMoveGoal(unitID, x, y, z, radius, speed, raw)
--	oldSetMoveGoal(unitID, x, y, z, radius, speed, raw)
--	Spring.MarkerAddPoint(x, y, z, (raw and "r") or "")
--end

----------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------
-- Configuration

local moveRawCmdDesc = {
	id      = CMD_RAW_MOVE,
	type    = CMDTYPE.ICON_MAP,
	name    = 'Move',
	cursor  = 'Move', -- add with LuaUI?
	action  = 'rawmove',
	tooltip = 'Move: Order the unit to move to a position.',
}

local TEST_MOVE_SPACING = 16
local LAZY_TEST_MOVE_SPACING = 8
local LAZY_SEARCH_DISTANCE = 450
local STUCK_TRAVEL = 45
local STUCK_MOVE_RANGE = 140
local GIVE_UP_STUCK_DIST_SQ = 250^2
local STOP_STOPPING_RADIUS = 10000000
local RAW_CHECK_SPACING = 500
local MAX_COMM_STOP_RADIUS = 400^2
local COMMON_STOP_RADIUS_ACTIVE_DIST_SQ = 120^2 -- Commands shorter than this do not activate common stop radius.

----------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------
-- Variables

local rawMoveUnit = {}
local commonStopRadius = {}
local oldCommandStoppingRadius = {}
local commandCount = {}
local oldCommandCount = {}

----------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------
-- Utilities

local function IsPathFree(unitDefID, sX, sZ, gX, gZ, distance, testSpacing, distanceLimit)
	local vX = gX - sX
	local vZ = gZ - sZ
	-- distance had better be math.sqrt(vX*vX + vZ*vZ) or things will break
	if distance < testSpacing then
		return true
	end
	vX, vZ = vX/distance, vZ/distance
	if distanceLimit and (distance > distanceLimit) then
		distance = distanceLimit
	end
	for test = 0, distance, testSpacing do
		if not Spring.TestMoveOrder(unitDefID, sX + test*vX, 0, sZ + test*vZ) then
			return false
		end
	end
	return true
end

local function ResetUnitData(unitData)
	unitData.cx = nil
	unitData.cz = nil
	unitData.switchedFromRaw = nil
	unitData.nextTestTime = nil
	unitData.commandHandled = nil
	unitData.stuckCheckTimer = nil
	unitData.handlingWaitTime = nil
	unitData.nextRawCheckDistSq = nil
	unitData.doingRawMove = nil
	unitData.possiblyTurning = nil
end

----------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------
-- Unit and command handling

local function StopRawMoveUnit(unitID)
	if not rawMoveUnit[unitID] then
		return
	end
	if not rawMoveUnit[unitID].switchedFromRaw then
		local x, y, z = spGetUnitPosition(unitID)
		Spring.SetUnitMoveGoal(unitID, x, y, z, STOP_STOPPING_RADIUS)
	end
	rawMoveUnit[unitID] = nil
	--Spring.Echo("StopRawMoveUnit", math.random())
end

function gadget:CommandFallback(unitID, unitDefID, teamID, cmdID, cmdParams, cmdOptions) -- Only calls for custom commands
	if (cmdID ~= CMD_RAW_MOVE) then
		return false
	end
	if spMoveCtrlGetTag(unitID) then
		return true, false
	end
	if not rawMoveUnit[unitID] then
		rawMoveUnit[unitID] = {}
	end
	local unitData = rawMoveUnit[unitID]
	if not (unitData.cx == cmdParams[1] and unitData.cz == cmdParams[3]) then
		ResetUnitData(unitData)
	end
	if unitData.handlingWaitTime then
		unitData.handlingWaitTime = unitData.handlingWaitTime - 1
		if unitData.handlingWaitTime <= 0 then
			unitData.handlingWaitTime = nil
		end
		return true, false
	end
	
	local x, y, z = spGetUnitPosition(unitID)
	local distSq = (x - cmdParams[1])*(x - cmdParams[1]) + (z - cmdParams[3])*(z - cmdParams[3])
	
	if not unitData.cx then
		unitData.cx, unitData.cz = cmdParams[1], cmdParams[3]
		unitData.commandString = cmdParams[1] .. "_" .. cmdParams[3]
		commandCount[unitData.commandString] = (commandCount[unitData.commandString] or 0) + 1
		unitData.preventGoalClumping = (distSq > COMMON_STOP_RADIUS_ACTIVE_DIST_SQ) and not (spGetUnitStates(unitID) or {})["repeat"]
	end
	if unitData.preventGoalClumping and unitData.commandString and not commonStopRadius[unitData.commandString] then
		commonStopRadius[unitData.commandString] = oldCommandStoppingRadius[unitData.commandString] or 0
	end
	if unitData.commandString and not commandCount[unitData.commandString] then
		commandCount[unitData.commandString] = oldCommandCount[unitData.commandString] or 1
	end
	
	local alone = (commandCount[unitData.commandString] <= 1)
	local myStopDistSq = (alone and loneStopDistSq[unitDefID]) or stopDistSq[unitDefID] or 256
	if unitData.preventGoalClumping then
		myStopDistSq = myStopDistSq + commonStopRadius[unitData.commandString]
	end
	
	if distSq < myStopDistSq then
		Spring.SetUnitMoveGoal(unitID, x, y, z, STOP_STOPPING_RADIUS)
		if unitData.preventGoalClumping then
			commonStopRadius[unitData.commandString] = (commonStopRadius[unitData.commandString] or 0) + stoppingRadiusIncrease[unitDefID]
			if commonStopRadius[unitData.commandString] > MAX_COMM_STOP_RADIUS then
				commonStopRadius[unitData.commandString] = MAX_COMM_STOP_RADIUS
			end
		end
		rawMoveUnit[unitID] = nil
		return true, true
	end
	
	if canFlyDefs[unitDefID] then
		if unitData.commandHandled then
			return true, false
		end
		unitData.switchedFromRaw = true
		unitData.commandHandled = true
		Spring.SetUnitMoveGoal(unitID, cmdParams[1],cmdParams[2],cmdParams[3], goalDist[unitDefID] or 16, nil, false)
		return true, false
	end
	
	if not unitData.stuckCheckTimer then
		unitData.ux, unitData.uz = x, z
		unitData.stuckCheckTimer = math.floor(math.random()*10) + (startMovingTime[unitDefID] or 6)
	end
	unitData.stuckCheckTimer = unitData.stuckCheckTimer - 1
	
	if unitData.stuckCheckTimer <= 0 then
		local oldX, oldZ = unitData.ux, unitData.uz
		local travelled = math.abs(oldX - x) + math.abs(oldZ - z)
		unitData.ux, unitData.uz = x, z
		if travelled < (stuckTravelOverride[unitDefID] or STUCK_TRAVEL) then
			unitData.stuckCheckTimer = math.floor(math.random()*2) + 1
			if distSq < GIVE_UP_STUCK_DIST_SQ then
				Spring.SetUnitMoveGoal(unitID, x, y, z, STOP_STOPPING_RADIUS)
				rawMoveUnit[unitID] = nil
				return true, true
			else
				local vx = math.random()*2*STUCK_MOVE_RANGE - STUCK_MOVE_RANGE
				local vz = math.random()*2*STUCK_MOVE_RANGE - STUCK_MOVE_RANGE
				Spring.SetUnitMoveGoal(unitID, x + vx, y, z + vz, goalDist[unitDefID] or 16, nil, false)
				unitData.commandHandled = nil
				unitData.switchedFromRaw = nil
				unitData.nextTestTime = nil
				unitData.doingRawMove = nil
				unitData.handlingWaitTime = math.floor(math.random()*4) + 2
				return true, false
			end
		else
			unitData.stuckCheckTimer = math.floor(math.random()*10) + 6
		end
	end
	
	if unitData and unitData.switchedFromRaw then
		if unitData.nextRawCheckDistSq and (unitData.nextRawCheckDistSq > distSq) then
			unitData.switchedFromRaw = nil
			unitData.nextTestTime = nil
		else
			return true, false
		end
	end
	
	unitData.nextTestTime = (unitData.nextTestTime or 0) - 1
	if unitData.nextTestTime <= 0 then
		local lazy = unitData.doingRawMove
		local freePath
		if (turnDiameterSq[unitDefID] or 0) > distSq then
			freePath = false
		else
			local distance = math.sqrt(distSq)
			freePath = IsPathFree(unitDefID, x, z, cmdParams[1], cmdParams[3], distance, TEST_MOVE_SPACING, lazy and LAZY_SEARCH_DISTANCE)
			if (not freePath) then
				unitData.nextRawCheckDistSq = (distance - RAW_CHECK_SPACING)*(distance - RAW_CHECK_SPACING)
			end
		end
		if (not unitData.commandHandled) or unitData.doingRawMove ~= freePath then
			Spring.SetUnitMoveGoal(unitID, cmdParams[1], cmdParams[2], cmdParams[3], goalDist[unitDefID] or 16, nil, freePath)
			unitData.nextTestTime = math.floor(math.random()*2) + turnPeriods[unitDefID]
			unitData.possiblyTurning = true
		elseif unitData.possiblyTurning then
			unitData.nextTestTime = math.floor(math.random()*2) + turnPeriods[unitDefID]
			unitData.possiblyTurning = false
		else
			unitData.nextTestTime = math.floor(math.random()*5) + 6
		end
		
		unitData.doingRawMove = freePath
		unitData.switchedFromRaw = not freePath
	end
	
	if not unitData.commandHandled then
		unitData.commandHandled = true
	end
	return true, false
end

local function CheckUnitQueues()
	for unitID,_ in pairs(unitQueuesToCheck) do
		local queue = spGetUnitCommands(unitID, 1)
		if (not queue) or (not queue[1]) or (queue[1].id ~= CMD_RAW_MOVE) then
			StopRawMoveUnit(unitID)
		end
		unitQueuesToCheck[unitID] = nil
	end
end

function gadget:UnitCmdDone(unitID, unitDefID, unitTeam, cmdID, cmdParams, cmdOptions, cmdTag)
	if cmdID == CMD_STOP then
		-- Handling for shift clicking on commands to remove.
		StopRawMoveUnit(unitID)
	end
end

function gadget:AllowCommand(unitID, unitDefID, unitTeam, cmdID, cmdParams, cmdOptions)
	if canMoveDefs[unitDefID] then
		if cmdID == CMD_STOP or ((not cmdOptions.shift) and (cmdID < 0 or stopCommand[cmdID])) then
			StopRawMoveUnit(unitID)
		elseif cmdID == CMD_INSERT and (cmdParams[1] == 0 or not cmdOptions.alt) then
			StopRawMoveUnit(unitID)
		elseif queueFrontCommand[cmdID] then
			unitQueueCheckRequired = true
			unitQueuesToCheck[unitID] = true
		end
	else
		if cmdID == CMD_INSERT then
			cmdID = cmdParams[2]
		end
		if cmdID == CMD_RAW_MOVE then
			return false
		end
	end
	return true
end

local function AddRawMoveUnit(unitID)
	rawMoveUnit[unitID] = true
end

local function RawMove_IsPathFree(unitDefID, sX, sZ, gX, gZ)
	local vX = gX - sX
	local vZ = gZ - sZ
	return IsPathFree(unitDefID, sX, sZ, gX, gZ, math.sqrt(vX*vX + vZ*vZ), TEST_MOVE_SPACING)
end

function gadget:Initialize()
	gadgetHandler:RegisterCMDID(CMD_RAW_MOVE)
	for _, unitID in pairs(Spring.GetAllUnits()) do
		gadget:UnitCreated(unitID, Spring.GetUnitDefID(unitID))
	end
	
	GG.AddRawMoveUnit = AddRawMoveUnit
	GG.StopRawMoveUnit = StopRawMoveUnit
	GG.RawMove_IsPathFree = RawMove_IsPathFree
end

function gadget:UnitCreated(unitID, unitDefID, teamID)
	if (canMoveDefs[unitDefID]) then 
		spInsertUnitCmdDesc(unitID, moveRawCmdDesc)
	end
end

function gadget:UnitDestroyed(unitID, unitDefID, teamID)
	rawMoveUnit[unitID] = nil
end

function gadget:GameFrame(n)
	if n%247 == 4 then
		oldCommandStoppingRadius = commonStopRadius
		commonStopRadius = {}
		
		oldCommandCount = commandCount
		commandCount = {}
	end
	if unitQueueCheckRequired then
		CheckUnitQueues()
		unitQueueCheckRequired = false
	end
end

----------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------
else --UNSYNCED--
----------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------


function gadget:DefaultCommand(targetType, targetID)
	if not targetID then
		return CMD_RAW_MOVE
	end
end

function gadget:Initialize()
	--Note: IMO we must *allow* LUAUI to draw this command. We already used to seeing skirm command, and it is informative to players. 
	--Also, its informative to widget coder and allow player to decide when to manually micro units (like seeing unit stuck on cliff with jink command)
	gadgetHandler:RegisterCMDID(CMD_RAW_MOVE)
	Spring.SetCustomCommandDrawData(CMD_RAW_MOVE, "RawMove", {0.5, 1.0, 0.5, 0.7}) -- "" mean there's no MOVE cursor if the command is drawn.
	Spring.AssignMouseCursor("RawMove", "cursormove", true, true)
end

end