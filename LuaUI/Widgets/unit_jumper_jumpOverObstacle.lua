local version = "v0.507"
function widget:GetInfo()
  return {
    name      = "Auto Jump Over Terrain",
    desc      = version .. " Jumper automatically jump over terrain or buildings if it shorten walk time.",
	author    = "Msafwan",
    date      = "4 February 2014",
    license   = "GNU GPL, v2 or later",
    layer     = 21,
    enabled   = false
  }
end

VFS.Include("LuaRules/Configs/customcmds.h.lua")
VFS.Include("LuaRules/Utilities/isTargetReachable.lua")
local spGetUnitPosition = Spring.GetUnitPosition
local spGetUnitRulesParam = Spring.GetUnitRulesParam
local spValidUnitID = Spring.ValidUnitID
local spValidFeatureID = Spring.ValidFeatureID
local spGetCommandQueue = Spring.GetCommandQueue
local spGiveOrderArrayToUnitArray = Spring.GiveOrderArrayToUnitArray
local spGetFeaturePosition = Spring.GetFeaturePosition
local spGetUnitIsStunned = Spring.GetUnitIsStunned
local spGetGameSeconds = Spring.GetGameSeconds
------------------------------------------------------------
------------------------------------------------------------
local gaussUnitDefID = UnitDefNames["turretgauss"].id
local myTeamID
local jumperAddInfo={}
--Spread job stuff: (spread looping across 1 second)
local spreadJobs=nil;
local effectedUnit={};
local spreadPreviousIndex = nil;
--end spread job stuff
--Network lag hax stuff: (wait until unit receive command before processing 2nd time)
local waitForNetworkDelay = nil;
local issuedOrderTo = {}
--end network lag stuff
local jumpersToJump = {}
local jumpersToWatch = {}
local jumpersToJump_Count = 0
local jumpersUnitID = {}

local jumperDefs = VFS.Include("LuaRules/Configs/jump_defs.lua")

local exclusions = {
	UnitDefNames["jumpsumo"].id, -- has AoE damage on jump, could harm allies
	--UnitDefNames["jumpbomb"].id -- jump is precious
}

for i = 1, #exclusions do
	jumperDefs[exclusions[i]] = nil
end

function widget:Initialize()
	local _, _, spec, teamID = Spring.GetPlayerInfo(Spring.GetMyPlayerID(), false)
		if spec then
		widgetHandler:RemoveWidget()
		return false
	end
	myTeamID = teamID
end

function widget:GameFrame(n)
	if n%30==14 then --every 30 frame period (1 second) at the 14th frame: 
		--check if we were waiting for lag for too long
		local currentSecond = spGetGameSeconds()
		if waitForNetworkDelay then
			if currentSecond - waitForNetworkDelay[1] > 4 then
				waitForNetworkDelay = nil
			end
		end
	end
	if ( n%15==0 and not waitForNetworkDelay) or spreadJobs then 
		local numberOfUnitToProcess = 29 --NUMBER OF UNIT PER SECOND. minimum: 29 unit per second
		local numberOfUnitToProcessPerFrame = math.ceil(numberOfUnitToProcess/29) --spread looping to entire 1 second
		spreadJobs = false
		local numberOfLoopToProcessPerFrame = math.ceil(jumpersToJump_Count/29)
		local currentLoopIndex = spreadPreviousIndex or 1
		local currentLoopCount = 0
		local currentUnitProcessed = 0
		local finishLoop = false
		if currentLoopIndex >= jumpersToJump_Count then
			finishLoop =true
		end
		local k = currentLoopIndex
		while (k<=jumpersToJump_Count) do
			local unitID = jumpersToJump[k][2]
			local validUnitID = spValidUnitID(unitID)
			if not validUnitID then
				DeleteEntryThenReIndex(k,unitID)
				k = k -1
			end
			if validUnitID then
				local unitDefID = jumpersToJump[k][1]
				if not jumperAddInfo[unitDefID] then
					local moveID = UnitDefs[unitDefID].moveDef.id
					local ud = UnitDefs[unitDefID]
					local halfJumprangeSq = (jumperDefs[unitDefID].range/2)^2
					local heightSq = jumperDefs[unitDefID].height^2
					local totalFlightDist = math.sqrt(halfJumprangeSq+heightSq)*2
					local jumpTime = (totalFlightDist/jumperDefs[unitDefID].speed + jumperDefs[unitDefID].delay)/30 -- is in second
					local unitSpeed = ud.speed --speed is in elmo-per-second
					local weaponRange = GetUnitFastestWeaponRange(ud)
					local unitSize = math.max(ud.xsize*4, ud.zsize*4)
					jumperAddInfo[unitDefID] = {moveID,jumpTime,unitSpeed,weaponRange, unitSize}
				end
				repeat --note: not looping, only for using "break" as method of escaping code
					local _,_,inBuild = spGetUnitIsStunned(unitID)
					if inBuild then
						break; --a.k.a: Continue
					end
					--IS NEW UNIT? initialize them--
					effectedUnit[unitID] = effectedUnit[unitID] or {cmdCount=0,cmdOne={id=nil,x=nil,y=nil,z=nil},cmdTwo={id=nil,x=nil,y=nil,z=nil}}
					--IS UNIT IDLE? skip--
					local cmd_queue = spGetCommandQueue(unitID, -1);
					if not (cmd_queue and cmd_queue[1]) then
						DeleteEntryThenReIndex(k,unitID)
						k = k -1
						break; --a.k.a: Continue
					end
					-- IS UNIT WAITING? skip--
					if (cmd_queue[1].id== CMD.WAIT) then
						break;
					end
					--IS UNIT CHARGING JUMP? skip--
					local jumpReload = spGetUnitRulesParam(unitID,"jumpReload")
					if jumpReload then
						if jumpReload < 0.95 then						
							break; --a.k.a: Continue
						end
					end
					--EXTRACT RELEVANT FIRST COMMAND --
					local cmd_queue2
					local unitIsAttacking
					for i=1, #cmd_queue do
						local cmd = cmd_queue[i]
						local equivalentMoveCMD = ConvertCMDToMOVE({cmd})
						if equivalentMoveCMD then
							unitIsAttacking = (cmd.id == CMD.ATTACK)
							cmd_queue2 = equivalentMoveCMD
							break
						end
					end
					if not cmd_queue2 then
						break
					end

					currentUnitProcessed = currentUnitProcessed + 1
					--CHECK POSITION OF PREVIOUS JUMP--
					local extraCmd1 = nil
					local extraCmd2 = nil
					local jumpCmdPos = 0
					if effectedUnit[unitID].cmdCount >0 then
						for i=1, #cmd_queue do
							local cmd = cmd_queue[i]
							if cmd.id == effectedUnit[unitID].cmdOne.id and
							cmd.params[1] == effectedUnit[unitID].cmdOne.x and
							cmd.params[2] == effectedUnit[unitID].cmdOne.y and
							cmd.params[3] == effectedUnit[unitID].cmdOne.z then
								extraCmd1 = {CMD.REMOVE, {cmd.tag}, CMD.OPT_SHIFT}
								jumpCmdPos = i
							end
							if cmd.id == effectedUnit[unitID].cmdTwo.id and
							cmd.params[1] == effectedUnit[unitID].cmdTwo.x and
							cmd.params[2] == effectedUnit[unitID].cmdTwo.y and
							cmd.params[3] == effectedUnit[unitID].cmdTwo.z then
								extraCmd2 = {CMD.REMOVE, {cmd.tag}, CMD.OPT_SHIFT}
								jumpCmdPos = jumpCmdPos or i
								break
							end
						end
					end
					--CHECK FOR OBSTACLE IN LINE--
					local tx,ty,tz = cmd_queue2.params[1],cmd_queue2.params[2],cmd_queue2.params[3]
					local px,py,pz = spGetUnitPosition(unitID)
					local  enterPoint_X,enterPoint_Y,enterPoint_Z,exitPoint_X,exitPoint_Y,exitPoint_Z = GetNearestObstacleEnterAndExitPoint(px,py,pz, tx,tz, unitDefID)
					if exitPoint_X and exitPoint_Z then
						local unitSpeed = jumperAddInfo[unitDefID][3]
						local moveID = jumperAddInfo[unitDefID][1]
						local weaponRange = jumperAddInfo[unitDefID][4]
						--MEASURE REGULAR DISTANCE--
						local distance = GetWaypointDistance(unitID,moveID,cmd_queue2,px,py,pz,unitIsAttacking,weaponRange)
						local normalTimeToDest = (distance/unitSpeed) --is in second
						
						--MEASURE DISTANCE WITH JUMP--
						cmd_queue2.params[1]=enterPoint_X
						cmd_queue2.params[2]=enterPoint_Y
						cmd_queue2.params[3]=enterPoint_Z
						distance = GetWaypointDistance(unitID,moveID,cmd_queue2,px,py,pz,false,0) --distance to jump-start point
						local timeToJump = (distance/unitSpeed) --is in second
						cmd_queue2.params[1]=tx --target coordinate
						cmd_queue2.params[2]=ty
						cmd_queue2.params[3]=tz

						local jumpTime = jumperAddInfo[unitDefID][2]
						distance = GetWaypointDistance(unitID,moveID,cmd_queue2,exitPoint_X,exitPoint_Y,exitPoint_Z,unitIsAttacking,weaponRange) --dist out of jump-landing point
						local timeFromExitToDestination = (distance/unitSpeed) --in second
						local totalTimeWithJump = timeToJump + timeFromExitToDestination + jumpTime

						--NOTE: time to destination is in second.
						local normalPathTime = normalTimeToDest - 2 --add 2 second benefit to regular walking (make walking more attractive choice unless jump can save more than 1 second travel time)
						if totalTimeWithJump < normalPathTime then	
							local commandArray = {[1]=nil,[2]=nil,[3]=nil,[4]=nil}
							if (math.abs(enterPoint_X-px)>50 or math.abs(enterPoint_Z-pz)>50) then
								commandArray[1]= {CMD.INSERT, {0, CMD_RAW_MOVE, CMD.OPT_INTERNAL, enterPoint_X,enterPoint_Y,enterPoint_Z}, CMD.OPT_ALT}
								commandArray[2]= {CMD.INSERT, {0, CMD_JUMP, CMD.OPT_INTERNAL, exitPoint_X,exitPoint_Y,exitPoint_Z}, CMD.OPT_ALT}
								commandArray[3]= extraCmd2
								commandArray[4]= extraCmd1
								effectedUnit[unitID].cmdCount = 2
								effectedUnit[unitID].cmdOne.id = CMD_RAW_MOVE
								effectedUnit[unitID].cmdOne.x = enterPoint_X
								effectedUnit[unitID].cmdOne.y = enterPoint_Y
								effectedUnit[unitID].cmdOne.z = enterPoint_Z
								effectedUnit[unitID].cmdTwo.id = CMD_JUMP
								effectedUnit[unitID].cmdTwo.x = exitPoint_X
								effectedUnit[unitID].cmdTwo.y = exitPoint_Y
								effectedUnit[unitID].cmdTwo.z = exitPoint_Z
								issuedOrderTo[unitID] = {CMD_RAW_MOVE,enterPoint_X,enterPoint_Y,enterPoint_Z}
							else
								commandArray[1]= {CMD.INSERT, {0, CMD_JUMP, CMD.OPT_INTERNAL, exitPoint_X,exitPoint_Y,exitPoint_Z}, CMD.OPT_ALT}
								commandArray[2]= extraCmd2
								commandArray[3]= extraCmd1
								effectedUnit[unitID].cmdCount = 1
								effectedUnit[unitID].cmdTwo.id = CMD_JUMP
								effectedUnit[unitID].cmdTwo.x = exitPoint_X
								effectedUnit[unitID].cmdTwo.y = exitPoint_Y
								effectedUnit[unitID].cmdTwo.z = exitPoint_Z
								issuedOrderTo[unitID] = {CMD_JUMP,exitPoint_X,exitPoint_Y,exitPoint_Z}
							end
							spGiveOrderArrayToUnitArray({unitID},commandArray)
							waitForNetworkDelay = waitForNetworkDelay or {spGetGameSeconds(),0}
							waitForNetworkDelay[2] = waitForNetworkDelay[2] + 1
						end
					elseif jumpCmdPos >= 2 then
						spGiveOrderArrayToUnitArray({unitID},{extraCmd2,extraCmd1}) --another command was sandwiched before the Jump command, making Jump possibly outdated/no-longer-optimal. Remove Jump
						effectedUnit[unitID].cmdCount = 0
					end
				until true
				currentLoopCount = currentLoopCount + 1
			end
			if k >= jumpersToJump_Count then
				finishLoop =true
				break
			elseif currentUnitProcessed >= numberOfUnitToProcessPerFrame or currentLoopCount>= numberOfLoopToProcessPerFrame then
				spreadJobs = true
				spreadPreviousIndex = k+1  --continue at next frame
				break
			end
			k = k + 1
		end
		if finishLoop then
			spreadPreviousIndex = nil
		end
	end
end

function DeleteEntryThenReIndex(k,unitID)
	--last position to current position
	if k ~= jumpersToJump_Count then
		local lastUnitID = jumpersToJump[jumpersToJump_Count][2]
		jumpersToJump[k] = jumpersToJump[jumpersToJump_Count]
		jumpersUnitID[lastUnitID] = k
	end
	
	effectedUnit[unitID] = nil
	jumpersUnitID[unitID] = nil
	
	jumpersToJump[jumpersToJump_Count] = nil
	jumpersToJump_Count = jumpersToJump_Count - 1
end

function GetNearestObstacleEnterAndExitPoint(currPosX,currPosY, currPosZ, targetPosX,targetPosZ, unitDefID)
	local nearestEnterPoint_X,original_X = currPosX,currPosX
	local nearestEnterPoint_Z,original_Z = currPosZ,currPosZ
	local nearestEnterPoint_Y,original_Y = currPosY,currPosY
	local exitPoint_X, exitPoint_Z,exitPoint_Y
	local overobstacle = false
	local distFromObstacle = 0
	local distToTarget= 0
	local unitBoxDist
	local defaultJumprange = jumperDefs[unitDefID].range -20
	local addingFunction  = function() end
	local check_n_SavePosition = function(x,z,gradient,addValue)
		local endOfLine = (math.abs(x-targetPosX) < 20) and (math.abs(z-targetPosZ) < 20)
		if endOfLine then
			return x,z,true
		end
		local y = Spring.GetGroundHeight(x, z)
		local clear,_ = Spring.TestBuildOrder(gaussUnitDefID or unitDefID, x,y ,z, 1)
		-- Spring.MarkerAddPoint(x,y ,z, clear)
		if clear == 0 then
			overobstacle = true
			if distToTarget==0 then
				distToTarget = math.sqrt((targetPosX-x)^2 + (targetPosZ-z)^2)
				local backX,backZ = addingFunction(x,z,addValue*-5,gradient)
				local backY = Spring.GetGroundHeight(backX, backZ)
				distFromObstacle = math.sqrt((x-backX)^2 + (z-backZ)^2)
				local backDistToTarget = math.sqrt((targetPosX-backX)^2 + (targetPosZ-backZ)^2)
				local unitDistToTarget = math.sqrt((targetPosX-original_X)^2 + (targetPosZ-original_Z)^2)
				if unitDistToTarget > backDistToTarget then
					nearestEnterPoint_X = backX --always used 1 step behind current box, avoid too close to terrain
					nearestEnterPoint_Z = backZ
					nearestEnterPoint_Y = backY
				else
					nearestEnterPoint_X = original_X --always used 1 step behind current box, avoid too close to terrain
					nearestEnterPoint_Z = original_Z
					nearestEnterPoint_Y = original_Y
				end
				-- Spring.MarkerAddPoint(backX,backY,backZ, "enter")
			else
				distFromObstacle = distFromObstacle + unitBoxDist
				distToTarget = distToTarget - unitBoxDist
			end
		elseif overobstacle then
			distFromObstacle = distFromObstacle + unitBoxDist
			distToTarget = distToTarget - unitBoxDist
			if distFromObstacle < defaultJumprange and distToTarget>0 then
				exitPoint_X = x
				exitPoint_Z = z
				exitPoint_Y = y
				-- Spring.MarkerAddPoint(x,y,z, "exit")
			else
				return x,z,true
			end
		end
		x,z = addingFunction(x,z,addValue,gradient)
		return x,z,false
	end
	local x, z = currPosX,currPosZ
	local xDiff = targetPosX -currPosX
	local zDiff = targetPosZ -currPosZ
	local unitBoxSize = jumperAddInfo[unitDefID][5]
	local finish=false
	if math.abs(xDiff) > math.abs(zDiff) then
		local xSgn = xDiff/math.abs(xDiff)
		local gradient = zDiff/xDiff
		unitBoxDist = math.sqrt(unitBoxSize*unitBoxSize + unitBoxSize*gradient*unitBoxSize*gradient)
		local xadd = unitBoxSize*xSgn
		addingFunction = function(x,z,addValue,gradient)
			return x+addValue, z+addValue*gradient 
		end
		for i=1, 9999 do
			x,z,finish = check_n_SavePosition(x,z,gradient,xadd)
			if finish then
				break
			end
		end
	else
		local zSgn = zDiff/math.abs(zDiff)
		local gradient = xDiff/zDiff
		unitBoxDist = math.sqrt(unitBoxSize*unitBoxSize + unitBoxSize*gradient*unitBoxSize*gradient)
		local zadd = unitBoxSize*zSgn
		addingFunction = function(x,z,addValue,gradient) 
			return x+addValue*gradient, z + addValue 
		end
		for i=1, 9999 do
			x,z,finish = check_n_SavePosition(x,z,gradient,zadd)
			if finish then
				break
			end
		end
	end
	return nearestEnterPoint_X,nearestEnterPoint_Y,nearestEnterPoint_Z,exitPoint_X,exitPoint_Y,exitPoint_Z
end

function GetUnitFastestWeaponRange(unitDef)
	local fastestReloadTime, fastReloadRange = 999,-1
	for _, weapons in ipairs(unitDef.weapons) do --reference: gui_contextmenu.lua by CarRepairer
		local weaponsID = weapons.weaponDef
		local weaponsDef = WeaponDefs[weaponsID]
		if weaponsDef.name and not (weaponsDef.name:find('fake') or weaponsDef.name:find('noweapon')) then --reference: gui_contextmenu.lua by CarRepairer
			if not weaponsDef.isShield then --if not shield then this is conventional weapon
				local reloadTime = weaponsDef.reload
				if reloadTime < fastestReloadTime then --find the weapon with the smallest reload time
					fastestReloadTime = reloadTime
					fastReloadRange = weaponsDef.range
				end
			end
		end
	end
	return fastReloadRange
end

function ConvertCMDToMOVE(command)
	if (command == nil) then 
		return nil
	end
	command = command[1]
	if (command == nil) then 
		return nil
	end

	if command.id == CMD_RAW_MOVE 
	or command.id == CMD.PATROL 
	or command.id == CMD.FIGHT
	or command.id == CMD.JUMP
	or command.id == CMD.ATTACK then
		if not command.params[2] then
			local x,y,z = spGetUnitPosition(command.params[1])
			if not x then --outside LOS and radar
				return nil
			end
			command.id = CMD_RAW_MOVE
			command.params[1] = x
			command.params[2] = y
			command.params[3] = z
			return command
		else
			command.id = CMD_RAW_MOVE
			return command
		end
	end
	if command.id == CMD.RECLAIM
	or command.id == CMD.REPAIR
	or command.id == CMD.GUARD
	or command.id == CMD.RESURRECT then
		local isPossible2PartAreaCmd = command.params[5]
		if not command.params[4] or isPossible2PartAreaCmd then --if not area-command or the is the 2nd part of area-command (1st part have radius at 4th-param, 2nd part have unitID/featureID at 1st-param and radius at 5th-param)
			if not command.params[2] or isPossible2PartAreaCmd then
				local x,y,z
				if command.id == CMD.REPAIR or command.id == CMD.GUARD then
					x,y,z = GetUnitOrFeaturePosition(command.params[1])
				elseif command.id == CMD.RECLAIM or command.id == CMD.RESURRECT then
					x,y,z = GetUnitOrFeaturePosition(command.params[1])
				end
				if not x then
					return nil
				end
				command.id = CMD_RAW_MOVE
				command.params[1] = x
				command.params[2] = y
				command.params[3] = z
				return command
			else
				command.id = CMD_RAW_MOVE
				return command
			end
		else
			return nil --no area command allowed
		end
	end
	if command.id < 0 then
		if command.params[3]==nil then --is building unit in factory
			return nil
		end
		command.id = CMD_RAW_MOVE
		return command
	end
	if command.id == CMD_WAIT_AT_BEACON then
		return command
	end
	return nil
end

function GetWaypointDistance(unitID,moveID,queue,px,py,pz,isAttackCmd,weaponRange) --Note: source is from unit_transport_ai.lua (by Licho)
	local d = 0
	if (queue == nil) then 
		return 99999
	end
	local v = queue
	if (v.id == CMD.MOVE or v.id == CMD_RAW_MOVE) then 
		local reachable = true --always assume target reachable
		local waypoints
		if moveID then --unit has compatible moveID?
			local minimumGoalDist = (isAttackCmd and weaponRange-20) or 128
			local result, lastwaypoint
			result, lastwaypoint, waypoints = Spring.Utilities.IsTargetReachable(moveID,px,py,pz,v.params[1],v.params[2],v.params[3],minimumGoalDist)
			if result == "outofreach" then --abit out of reach?
				reachable=false --target is unreachable!
			end
		end
		if reachable then
			local distOffset = (isAttackCmd and weaponRange-20) or 0
			if waypoints then --we have waypoint to destination?
				local way1,way2,way3 = px,py,pz
				for i=1, #waypoints do --sum all distance in waypoints
					d = d + Dist(way1,way2,way3, waypoints[i][1],waypoints[i][2],waypoints[i][3])
					way1,way2,way3 = waypoints[i][1],waypoints[i][2],waypoints[i][3]
				end
				d = d + math.max(0,Dist(way1,way2,way3, v.params[1], v.params[2], v.params[3])-distOffset) --connect endpoint of waypoint to destination
			else --so we don't have waypoint?
				d = d + math.max(0,Dist(px,py, pz, v.params[1], v.params[2], v.params[3])-distOffset) --we don't have waypoint then measure straight line
			end
		else --pathing says target unreachable?!
			d = d + Dist(px,py, pz, v.params[1], v.params[2], v.params[3])*10 +9999 --target unreachable!
		end
	end
	return d
end

function Dist(x,y,z, x2, y2, z2) 
	local xd = x2-x
	local yd = y2-y
	local zd = z2-z
	return math.sqrt(xd*xd + yd*yd + zd*zd)
end

function GetUnitOrFeaturePosition(id) --copied from cmd_commandinsert.lua widget (by dizekat)
	if id<=Game.maxUnits and spValidUnitID(id) then
		return spGetUnitPosition(id)
	elseif spValidFeatureID(id-Game.maxUnits) then
		return spGetFeaturePosition(id-Game.maxUnits) --featureID is always offset by maxunit count
	end
	return nil
end

------------------------------------------------------------
------------------------------------------------------------
function widget:UnitFinished(unitID,unitDefID,unitTeam)
	if myTeamID==unitTeam and jumperDefs[unitDefID] and not jumpersUnitID[unitID] then
		jumpersToJump_Count = jumpersToJump_Count + 1
		jumpersToJump[jumpersToJump_Count] = {unitDefID,unitID}
		jumpersUnitID[unitID] = jumpersToJump_Count
	end
end

function widget:UnitCommand(unitID, unitDefID, unitTeam, cmdID, cmdParams, cmdOptions)
	if myTeamID==unitTeam and jumperDefs[unitDefID] then
		if (cmdID ~= CMD.INSERT) then
			if not jumpersUnitID[unitID] then
				jumpersToJump_Count = jumpersToJump_Count + 1
				jumpersToJump[jumpersToJump_Count] = {unitDefID,unitID}
				jumpersUnitID[unitID] = jumpersToJump_Count
			end
		end
		if (cmdID == CMD.INSERT) then --detected our own command (indicate network delay have passed)
			local issuedOrderContent = issuedOrderTo[unitID]
			if issuedOrderContent and 
			(cmdParams[4] == issuedOrderContent[2] and
			cmdParams[5] == issuedOrderContent[3] and
			cmdParams[6] == issuedOrderContent[4]) then
				issuedOrderTo[unitID] = nil 
				if waitForNetworkDelay then
					waitForNetworkDelay[2] = waitForNetworkDelay[2] - 1 
					if waitForNetworkDelay[2]==0 then 
						waitForNetworkDelay = nil 
					end
				end
			end
		end
	end
end