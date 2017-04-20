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

local spGetUnitPosition = Spring.GetUnitPosition
local spInsertUnitCmdDesc = Spring.InsertUnitCmdDesc

local canMoveDefs = {}
local canFlyDefs = {}
local stopDist = {}
local goalDist = {}
local turnRadiusSq = {}
local stopDistSq = {}
local stoppingRadiusIncrease = {}

for i = 1, #UnitDefs do
	local ud = UnitDefs[i]
	if ud.canMove then
		canMoveDefs[i] = true
		stopDist[i] = 16
		local turningRadius = ud.speed*2195/(ud.turnRate * 2 * math.pi)
		if turningRadius > 40 then
			turnRadiusSq[i] = turningRadius*turningRadius
		end
		if ud.canFly then
			canFlyDefs[i] = true
			stopDist[i] = ud.speed*0.66
			goalDist[i] = 8
		end
		if stopDist[i] then
			stopDistSq[i] = stopDist[i]*stopDist[i]
		end
		if stopDist[i] and not goalDist[i] then
			goalDist[i] = stopDist[i]
		end
		stoppingRadiusIncrease[i] = ud.xsize*250
	end
end

-- Debug
--local oldSetMoveGoal = Spring.SetUnitMoveGoal
--function Spring.SetUnitMoveGoal(unitID, x, y, z, radius, speed, raw)
--	oldSetMoveGoal(unitID, x, y, z, radius, speed, raw)
--	Spring.MarkerAddPoint(x, y, z, "")
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

local TEST_MOVE_DISTANCE = 16
local LAZY_SEARCH_DISTANCE = 800
local STUCK_TRAVEL = 32
local STUCK_MOVE_RANGE = 120
local GIVE_UP_STUCK_DIST_SQ = 250^2
local STOP_STOPPING_RADIUS = 10000000
local MAX_COMM_STOP_RADIUS = 400^2
local COMMON_STOP_RADIUS_ACTIVE_DIST_SQ = 180^2 -- Commanders shorter than this do not activate common stop radius.

----------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------
-- Variables

local rawMoveUnit = {}
local commonStopRadius = {}
local oldCommandStoppingRadius = {}

----------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------
-- Utilities

function GetDistSqr(a, b)
	local x,z = (a[1] - b[1]), (a[3] - b[3])
	return (x*x + z*z)
end

local function IsPathFree(unitDefID, sX, sZ, gX, gZ, distSq, distanceLimit)
	local vX = gX - sX
	local vZ = gZ - sZ
	local distance = math.sqrt(distSq)
	if distance < TEST_MOVE_DISTANCE then
		return true
	end
	vX, vZ = vX/distance, vZ/distance
	if distanceLimit and (distance > distanceLimit) then
		distance = distanceLimit
	end
	for test = 0, distance, TEST_MOVE_DISTANCE do
		if not Spring.TestMoveOrder(unitDefID, sX + test*vX, 0, sZ + test*vZ) then
			return false
		end
	end
	return true
end

local function ResetUnitData(unitData)
	unitData.switchedFromRaw = nil
	unitData.nextTestTime = nil
	unitData.commandHandled = nil
	unitData.stuckCheckTimer = nil
	unitData.handlingWaitTime = nil
end

----------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------
-- Unit and command handling

function gadget:CommandFallback(unitID, unitDefID, teamID, cmdID, cmdParams, cmdOptions) -- Only calls for custom commands
	if (cmdID ~= CMD_RAW_MOVE) then
		return false
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
	local distSq = GetDistSqr({x, y, z}, cmdParams)
	
	if not unitData.cx then
		unitData.cx, unitData.cz = cmdParams[1], cmdParams[3]
		if distSq > COMMON_STOP_RADIUS_ACTIVE_DIST_SQ then
			unitData.commandString = cmdParams[1] .. "_" .. cmdParams[3]
		end
	end
	if unitData.commandString and not commonStopRadius[unitData.commandString] then
		commonStopRadius[unitData.commandString] = oldCommandStoppingRadius[unitData.commandString] or 0
	end
	
	local myStopDistSq = stopDistSq[unitDefID] or 256
	if unitData.commandString then
		myStopDistSq = myStopDistSq + commonStopRadius[unitData.commandString]
	end
	
	if distSq < myStopDistSq then
		Spring.SetUnitMoveGoal(unitID, x, y, z, STOP_STOPPING_RADIUS)
		if unitData.commandString then
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
		unitData.stuckCheckTimer = math.floor(math.random()*3) + 4
	end
	unitData.stuckCheckTimer = unitData.stuckCheckTimer - 1
	if unitData.stuckCheckTimer <= 0 then
		local oldX, oldZ = unitData.ux, unitData.uz
		local travelled = math.abs(oldX - x) + math.abs(oldZ - z)
		unitData.ux, unitData.uz = x, z
		unitData.stuckCheckTimer = math.floor(math.random()*3) + 4
		if travelled < STUCK_TRAVEL then
			if distSq < GIVE_UP_STUCK_DIST_SQ then
				Spring.SetUnitMoveGoal(unitID, x, y, z, STOP_STOPPING_RADIUS)
				rawMoveUnit[unitID] = nil
				return true, true
			else
				local vx = math.random()*2*STUCK_MOVE_RANGE - STUCK_MOVE_RANGE
				local vz = math.random()*2*STUCK_MOVE_RANGE - STUCK_MOVE_RANGE
				Spring.SetUnitMoveGoal(unitID, x + vx, y, z + vz, goalDist[unitDefID] or 16, nil, false)
				ResetUnitData(unitData)
				unitData.handlingWaitTime = 3
				return true, false
			end
		end
	end
	
	if unitData and unitData.switchedFromRaw then
		return true, false
	end
	
	local lazy = unitData.commandHandled
	unitData.nextTestTime = (unitData.nextTestTime or 0) - 1
	if unitData.nextTestTime <= 0 then
		local freePath = ((turnRadiusSq[unitDefID] or 0) < distSq) and IsPathFree(unitDefID, x, z, cmdParams[1], cmdParams[3], distSq, lazy and LAZY_SEARCH_DISTANCE)
		if (not unitData.commandHandled) or (not freePath) then
			Spring.SetUnitMoveGoal(unitID, cmdParams[1],cmdParams[2],cmdParams[3], goalDist[unitDefID] or 16, nil, freePath)
		end
		unitData.switchedFromRaw = not freePath
		unitData.nextTestTime = math.floor(math.random()*5) + 6
	end
	
	if not unitData.commandHandled then
		unitData.commandHandled = true
	end
	return true, false
end

function gadget:AllowCommand_GetWantedCommand()	
	return {[CMD.STOP] = true}
end

function gadget:AllowCommand_GetWantedUnitDefID()	
	return true
end

function gadget:AllowCommand(unitID, unitDefID, unitTeam, cmdID, cmdParams, cmdOptions)
	if cmdID == CMD.STOP and rawMoveUnit[unitID] then
		if not rawMoveUnit[unitID].switchedFromRaw then
			local x, y, z = spGetUnitPosition(unitID)
			Spring.SetUnitMoveGoal(unitID, x, y, z, stopDist[unitDefID] or 16)
		end
		rawMoveUnit[unitID] = nil
	end
	return true
end

function gadget:Initialize()
	gadgetHandler:RegisterCMDID(CMD_RAW_MOVE)
	for _, unitID in pairs(Spring.GetAllUnits()) do
		gadget:UnitCreated(unitID, Spring.GetUnitDefID(unitID))
	end
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