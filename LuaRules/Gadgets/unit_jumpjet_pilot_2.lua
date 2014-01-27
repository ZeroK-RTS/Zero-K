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
    date      = "January 27, 2014",
    license   = "GNU GPL, v2 or later",
    layer     = 0,
    enabled   = false  --  loaded by default?
  }
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

-- function print(...)
  -- Spring.SendMessage(...)
-- end

-- local aStar = VFS.Include "LuaRules/Gadgets/astar.lua"

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

include("LuaRules/Configs/customcmds.h.lua")
local spRequestPath = Spring.RequestPath

local leaperDefID = UnitDefNames.chicken_leaper.id
local gridSize = math.floor(350/2)

function Dist(x,y,z, x2, y2, z2) 
	local xd = x2-x
	local yd = y2-y
	local zd = z2-z
	return math.sqrt(xd*xd + yd*yd + zd*zd)
end

--This function process result of Spring.PathRequest() to say whether target is reachable or not
function IsTargetReachable (moveID, ox,oy,oz,tx,ty,tz,radius)
	local returnValue1,returnValue2, returnValue3
	local path = spRequestPath( moveID,ox,oy,oz,tx,ty,tz, radius)
	if path then
		local waypoint = path:GetPathWayPoints() --get crude waypoint (low chance to hit a 10x10 box). NOTE; if waypoint don't hit the 'dot' is make reachable build queue look like really far away to the GetWorkFor() function.
		local finalCoord = waypoint[#waypoint]
		if finalCoord then --unknown why sometimes NIL
			local dx, dz = finalCoord[1]-tx, finalCoord[3]-tz
			local dist = math.sqrt(dx*dx + dz*dz)
			if dist <= radius+10 then --is within radius?
				returnValue1 = "reach"
				returnValue2 = finalCoord
				returnValue3 = waypoint
			else
				returnValue1 = "outofreach"
				returnValue2 = finalCoord
				returnValue3 = waypoint
			end
		end
	else
		returnValue1 = "noreturn"
		returnValue2 = nil
		returnValue3 = nil
	end
	return returnValue1,returnValue2, returnValue3
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
  if unitDefID == leaperDefID and (cmdID == CMD.MOVE or cmdID == CMD.FIGHT) then
    local startX, startZ, startY
    if cmdOptions.shift then -- queue, use last queue position
      local queue = Spring.GetCommandQueue(unitID)
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
		result, lastwaypoint, waypoints = IsTargetReachable( moveID,startX,startY,startZ,cmdParams[1],cmdParams[2],cmdParams[3],minimumGoalDist)
	end
	if waypoints then --we have waypoint to destination?
		if not Spring.GetUnitIsDead(unitID) and not cmdOptions.shift then
			Spring.GiveOrderToUnit(unitID, CMD.STOP, {}, {})
		end
		local d = 0
		local way1,way2,way3 = startX,startY,startZ
		for i=1, #waypoints do --sum all distance in waypoints
			d = d + Dist(way1,way2,way3, waypoints[i][1],waypoints[i][2],waypoints[i][3])
			way1,way2,way3 = waypoints[i][1],waypoints[i][2],waypoints[i][3]
			if d >= gridSize then
				if not Spring.GetUnitIsDead(unitID) then Spring.GiveOrderToUnit(unitID, CMD_JUMP, {waypoints[i][1],waypoints[i][2],waypoints[i][3]}, {"shift"}) end
				d = 0
			end
		end
		if not Spring.GetUnitIsDead(unitID) then Spring.GiveOrderToUnit(unitID, CMD_JUMP, {way1, way2, way3}, {"shift"}) end
		if not Spring.GetUnitIsDead(unitID) then Spring.GiveOrderToUnit(unitID, CMD_JUMP, {cmdParams[1], cmdParams[2], cmdParams[3]}, {"shift"}) end
	else -- if the computed path shows "no path found" (false), abort
		Spring.GiveOrderToUnit(unitID, CMD.STOP, {}, cmdOptions.shift and {"shift"} or {})
		return false;
	end
    return false -- reject original command, we're handling it
  end
  
  return true -- other order
end
