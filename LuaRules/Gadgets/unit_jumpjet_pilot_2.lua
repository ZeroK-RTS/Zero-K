--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

if (not gadgetHandler:IsSyncedCode()) then
  return false
end

function gadget:GetInfo()
  return {
    name      = "Jumpjet Pilot 2014",
    desc      = "Steers leapers 2014",
    author    = "xponen, quantum (code from Jumpjet Pilot but use Spring pathing)",
    date      = "January 28, 2014",
    license   = "GNU GPL, v2 or later",
    layer     = 0,
    enabled   = false  --  loaded by default?
  }
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

include("LuaRules/Configs/customcmds.h.lua")
VFS.Include("LuaRules/Utilities/isTargetReachable.lua")
local spRequestPath = Spring.RequestPath

local leaperDefID = UnitDefNames.chicken_leaper.id
local gridSize = math.floor(350/2)
local leapersCommand
local noRecursion = false

gridSize = tonumber(UnitDefNames["chicken_leaper"].customParams.jump_range)

function Dist(x,y,z, x2, y2, z2)
	local xd = x2-x
	local yd = y2-y
	local zd = z2-z
	return math.sqrt(xd*xd + yd*yd + zd*zd)
end

function gadget:AllowCommand_GetWantedCommand()
	return true
end

function gadget:AllowCommand_GetWantedUnitDefID()
	return {[leaperDefID] = true}
end

function gadget:AllowCommand(unitID, unitDefID, unitTeam, cmdID, cmdParams, cmdOptions, cmdTag, synced)
	if noRecursion then
		return true
	end
	
	if unitDefID == leaperDefID and (cmdID == CMD.MOVE or cmdID == CMD_RAW_MOVE or cmdID == CMD_RAW_BUILD or cmdID == CMD.FIGHT) then
		local startX, startZ, startY
		if cmdOptions.shift then -- queue, use last queue position
			local queue = Spring.GetCommandQueue(unitID, -1)
			for i=#queue, 1, -1 do
				if #(queue[i].params) == 3 then -- todo: be less lazy
					startX,startY, startZ = queue[i].params[1], queue[i].params[2], queue[i].params[3]
					break
				end
			end
		end
		if not startX or not startZ then
			startX, startY, startZ = Spring.GetUnitPosition(unitID)
		end

		if (Spring.GetUnitIsDead(unitID)) then
			return false;
		end
		
		local waypoints
		local moveID = UnitDefs[unitDefID].moveDef.id
		if moveID then --unit has compatible moveID?
			local minimumGoalDist = 8
			local result, lastwaypoint
			result, lastwaypoint, waypoints = Spring.Utilities.IsTargetReachable( moveID,startX,startY,startZ,cmdParams[1],cmdParams[2],cmdParams[3],minimumGoalDist)
		end
		if waypoints then --we have waypoint to destination?
			leapersCommand = leapersCommand or {}
			leapersCommand[unitID] = {}
			if not cmdOptions.shift then
				leapersCommand[unitID][1] = {CMD.STOP, {}, 0}
			end
			local d = 0
			local way1,way2,way3 = startX,startY,startZ
			local idx = #leapersCommand[unitID]+1
			for i=1, #waypoints do --sum all distance in waypoints
				d = d + Dist(way1,way2,way3, waypoints[i][1],waypoints[i][2],waypoints[i][3])
				way1,way2,way3 = waypoints[i][1],waypoints[i][2],waypoints[i][3]
				if d >= gridSize then
					leapersCommand[unitID][idx] = {CMD_JUMP, {waypoints[i][1],waypoints[i][2],waypoints[i][3]}, CMD.OPT_SHIFT}
					idx = idx + 1
					leapersCommand[unitID][idx] = {CMD.FIGHT, {waypoints[i][1],waypoints[i][2],waypoints[i][3]}, CMD.OPT_SHIFT}
					idx = idx + 1
					d = 0
				end
			end
			leapersCommand[unitID][idx] = {CMD_JUMP, {way1, way2, way3}, CMD.OPT_SHIFT}
			idx = idx + 1
			leapersCommand[unitID][idx] = {CMD.FIGHT, {way1, way2, way3}, CMD.OPT_SHIFT}
			idx = idx + 1
			leapersCommand[unitID][idx] = {CMD_JUMP, {cmdParams[1], cmdParams[2], cmdParams[3]}, CMD.OPT_SHIFT}
		else -- if the computed path shows "no path found" (false), abort
			leapersCommand = leapersCommand or {}
			leapersCommand[unitID] = {[1]={CMD.STOP, {}, cmdOptions.shift and CMD.OPT_SHIFT or 0}}
			return false;
		end
		return false -- reject original command, we're handling it
	end
  
  return true -- other order
end

function gadget:GameFrame(frame)
	if leapersCommand then
		noRecursion = true
		for unitID,ordersArray in pairs(leapersCommand) do
			if not Spring.GetUnitIsDead(unitID) then
				Spring.GiveOrderArrayToUnitArray({unitID},ordersArray)
			end
		end
		noRecursion = false
		leapersCommand = nil
	end
end
