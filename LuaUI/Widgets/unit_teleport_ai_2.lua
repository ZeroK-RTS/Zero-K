local version = "v0.825"
function widget:GetInfo()
  return {
    name      = "Teleport AI (experimental) v2",
    desc      = version .. " Automatically scan any units around teleport beacon " ..
				"(up to 500elmo, LLT range) and teleport them when it shorten travel time. "..
				"This only apply to your unit & allied beacon.",
	author    = "Msafwan",
    date      = "10 July 2013",
    license   = "GNU GPL, v2 or later",
    layer     = 21,
    enabled   = false
  }
end

local detectionRange = 500

VFS.Include("LuaRules/Configs/customcmds.h.lua")
local spGetUnitPosition = Spring.GetUnitPosition
local spGetUnitRulesParam = Spring.GetUnitRulesParam
local spValidUnitID = Spring.ValidUnitID
local spGetCommandQueue = Spring.GetCommandQueue
local spGetUnitsInCylinder = Spring.GetUnitsInCylinder
local spGetUnitDefID = Spring.GetUnitDefID
local spGiveOrderArrayToUnitArray = Spring.GiveOrderArrayToUnitArray
local spValidFeatureID = Spring.ValidFeatureID
local spGetFeaturePosition = Spring.GetFeaturePosition
local spRequestPath = Spring.RequestPath
local spGetUnitIsStunned = Spring.GetUnitIsStunned
------------------------------------------------------------
------------------------------------------------------------
local myTeamID
local ud
local listOfBeacon={}
local listOfMobile={}
local groupBeacon={} --beacon list in its group
local groupBeaconOfficial={} --most recent update to beacon list
--Spread job stuff: (spread looping across 1 second)
local groupSpreadJobs={} 
local groupEffectedUnit={}
local groupLoopedUnit={}
local groupBeaconQueue={}
local groupBeaconFinish={}
--end spread job stuff
local fiveSecondExcludedUnit = {}
local beaconDefID = UnitDefNames["tele_beacon"].id
local diggDeeperExclusion = {}

function widget:Initialize()
	local _, _, spec, teamID = Spring.GetPlayerInfo(Spring.GetMyPlayerID())
		if spec then
		widgetHandler:RemoveWidget()
		return false
	end
	myTeamID = teamID

	local units = Spring.GetAllUnits()
	for i=1,#units do  -- init existing transports
		local unitID = units[i]
		if Spring.IsUnitAllied(unitID) then
			local unitDefID = Spring.GetUnitDefID(unitID)
			if beaconDefID == unitDefID then
				local x,y,z = spGetUnitPosition(unitID)
				listOfBeacon[unitID] = {x,y,z,nil,nil,nil,djin=nil,prevIndex=nil,prevList=nil,vicntyBecn=nil,becnQeuu=0,deployed=1}
			end
		end
	end
	local cluster, nonClustered = WG.OPTICS_cluster(listOfBeacon, detectionRange,1, myTeamID,detectionRange) --//find clusters with atleast 1 unit per cluster and with at least within 500-elmo from each other 
	groupBeaconOfficial = cluster
	for i=1, #nonClustered do
		groupBeaconOfficial[#groupBeaconOfficial+1] = {nonClustered[i]}
	end
end

function widget:UnitCreated(unitID, unitDefID, unitTeam, builderID)
	if beaconDefID == unitDefID then
		local x,y,z = spGetUnitPosition(unitID)
		listOfBeacon[unitID] = {x,y,z,nil,nil,nil,djin=nil,prevIndex=nil,prevList=nil,vicntyBecn=nil,becnQeuu=0,deployed=1}
		local cluster, nonClustered = WG.OPTICS_cluster(listOfBeacon, detectionRange,1, myTeamID,detectionRange) --//find clusters with atleast 1 unit per cluster and with at least within 500-elmo from each other (this function is located in api_shared_function.lua)
		groupBeaconOfficial = cluster
		for i=1, #nonClustered do
			groupBeaconOfficial[#groupBeaconOfficial+1] = {nonClustered[i]}
		end
	end
end

function widget:UnitDestroyed(unitID, unitDefID)
	listOfBeacon[unitID] = nil
	fiveSecondExcludedUnit[unitID] = nil
end

function widget:UnitGiven(unitID, unitDefID, newTeamID, teamID)
	widget:UnitDestroyed(unitID, unitDefID)
	fiveSecondExcludedUnit[unitID] = nil
end

function widget:UnitTaken(unitID, unitDefID, newTeamID, teamID)
	widget:UnitCreated(unitID, unitDefID, newTeamID)
end

------------------------------------------------------------
------------------------------------------------------------
--SOME NOTE:
--"DiggDeeper()" use a straightforward recursive horizontal/sideway-search. 
--But if we can find out if there's better way to do it would be more fun. Some Googling found stuff like "Minimum Spanning Tree" & "Spanning Tree" (might be interesting!)
function DiggDeeper(beaconIDList, unitSpeed_CNSTNT,targetCoord_CNSTNT,chargeTime_CNSTNT, lowestTime_VAR, previousOverheadTime, level)
	level = level + 1
	if level > 5 then
		return nil,nil,nil,nil
	end
	local parentUnitID_return, unitIDToProcess_return, totalOverhead_return
	for i=1, #beaconIDList,1 do
		local beaconID = beaconIDList[i]
		if not diggDeeperExclusion[beaconID] and listOfBeacon[beaconID] then
			if not listOfBeacon[beaconID][4] then --if haven't update the djinnID yet
				local djinnID = (spGetUnitRulesParam(beaconID,"connectto"))
				local ex,ey,ez = spGetUnitPosition(djinnID)
				listOfBeacon[beaconID][4] = ex
				listOfBeacon[beaconID][5] = ey
				listOfBeacon[beaconID][6] = ez
			end
			local distance = Dist(listOfBeacon[beaconID][4],listOfBeacon[beaconID][5], listOfBeacon[beaconID][6], targetCoord_CNSTNT[1], targetCoord_CNSTNT[2], targetCoord_CNSTNT[3])
			local estTimeFromExitToDest = (distance/unitSpeed_CNSTNT)*30
			local totalTime = previousOverheadTime + estTimeFromExitToDest
			if totalTime<lowestTime_VAR then
				parentUnitID_return =beaconID
				unitIDToProcess_return =beaconID
				totalOverhead_return =previousOverheadTime
				lowestTime_VAR=totalTime
			end
		end
	end
	for i=1, #beaconIDList,1 do
		local beaconID = beaconIDList[i]
		if not diggDeeperExclusion[beaconID] and listOfBeacon[beaconID] then
			--diggDeeperExclusion[beaconID]= true 
			--The line above ensure all path is traversed only once (increase efficiency!), 
			--but the issue is: if there's many parallel path that lead to a same point then there's no guarantee this unique path is the best one.
			if not listOfBeacon[beaconID]["vicntyBecn"] then
				local ex,ez = listOfBeacon[beaconID][4],listOfBeacon[beaconID][6]
				local listOfUnits = spGetUnitsInCylinder(ex,ez,detectionRange,myTeamID)
				local listOfBeaconInVicinity = {}
				for i=1, #listOfUnits,1 do
					local unitID = listOfUnits[i]
					if listOfBeacon[unitID] then
						local index = #listOfBeaconInVicinity+1
						listOfBeaconInVicinity[index] = unitID
					end
				end
				listOfBeacon[beaconID]["vicntyBecn"]=listOfBeaconInVicinity
			end
			local vicinityList = listOfBeacon[beaconID]["vicntyBecn"]
			local totalOverheadTime = previousOverheadTime + chargeTime_CNSTNT + listOfBeacon[beaconID]["becnQeuu"] --plus congestion information from enterance beacon
			local parentUnitID, unitIDToProcess, totalOverhead,lowestTime = DiggDeeper(vicinityList, unitSpeed_CNSTNT,targetCoord_CNSTNT,chargeTime_CNSTNT, lowestTime_VAR, totalOverheadTime, level)
			if parentUnitID then
				parentUnitID_return =beaconID
				unitIDToProcess_return =unitIDToProcess
				totalOverhead_return =totalOverhead
				lowestTime_VAR=lowestTime
			end
		end
	end
	return parentUnitID_return, unitIDToProcess_return, totalOverhead_return, lowestTime_VAR
end

function widget:GameFrame(n)
	if n%150==15 then --every 150 frame period (5 second) at the 15th frame
		for beaconID,_ in pairs(listOfBeacon)do
			local djinnID = (spGetUnitRulesParam(beaconID,"connectto"))
			local ex,ey,ez = spGetUnitPosition(djinnID)
			listOfBeacon[beaconID][4] = ex
			listOfBeacon[beaconID][5] = ey
			listOfBeacon[beaconID][6] = ez
			listOfBeacon[beaconID]["djin"] = djinnID
			local listOfUnits = spGetUnitsInCylinder(ex,ez,detectionRange,myTeamID)
			local listOfBeaconInVicinity = {}
			for i=1, #listOfUnits,1 do
				local unitID = listOfUnits[i]
				if listOfBeacon[unitID] then
					local index = #listOfBeaconInVicinity+1
					listOfBeaconInVicinity[index] = unitID
				end
			end
			listOfBeacon[beaconID]["vicntyBecn"]=listOfBeaconInVicinity
		end
	end
	if n%30==14 then --every 30 frame period (1 second) at the 14th frame: update deploy state
		for beaconID,tblContent in pairs(listOfBeacon) do
			local djinnID = listOfBeacon[beaconID]["djin"]
			local djinnDeployed = djinnID and (spGetUnitRulesParam(djinnID,"deploy")) or 1
			if djinnID and djinnDeployed == 1 then
				djinnDeployed = (spGetUnitIsStunned(beaconID) and 0) or 1
			end
			listOfBeacon[beaconID]["deployed"] = djinnDeployed
		end
	end
	for i=1, #groupBeacon,1 do
		if n%30==0 or groupSpreadJobs[i] then --every 30 frame period (1 second)
			--Spring.Echo("-----GROUP:" .. i)
			local numberOfUnitToProcess = 5 --NUMBER OF UNIT PER BEACON PER SECOND
			local numberOfUnitToProcessPerFrame = math.ceil(numberOfUnitToProcess/29)
			local beaconCurrentQueue = groupBeaconQueue[i] or {}
			local unitToEffect = groupEffectedUnit[i] or {}
			local loopedUnits = groupLoopedUnit[i] or {}
			local beaconFinishLoop = groupBeaconFinish[i] or {}
			groupSpreadJobs[i] = false
			for j=1, #groupBeacon[i],1 do
				local beaconID = groupBeacon[i][j]
				beaconCurrentQueue[beaconID] =beaconCurrentQueue[beaconID] or 0
				--Spring.Echo("BEACON:" .. beaconID)
				if listOfBeacon[beaconID] and (not beaconFinishLoop[beaconID]) and listOfBeacon[beaconID]["deployed"]==1 then --beacon is alive & not finish looping? & deployed?
					local bX,bY,bZ = listOfBeacon[beaconID][1],listOfBeacon[beaconID][2],listOfBeacon[beaconID][3]
					local vicinityUnit = listOfBeacon[beaconID]["prevList"] or spGetUnitsInCylinder(bX,bZ,detectionRange,myTeamID)
					local numberOfLoop = #vicinityUnit
					--Spring.Echo("LOOP:" .. numberOfLoop)
					local numberOfLoopToProcessPerFrame = math.ceil(numberOfLoop/29)
					local currentLoopIndex = listOfBeacon[beaconID]["prevIndex"] or 1
					local currentLoopCount = 0
					local currentUnitProcessed = 0
					local finishLoop = false
					if currentLoopIndex >= numberOfLoop then
						finishLoop =true
					end
					for k=currentLoopIndex, numberOfLoop,1 do
						local unitID = vicinityUnit[k]
						local validUnitID = spValidUnitID(unitID)
						if not validUnitID then
							unitToEffect[unitID] = nil
						end
						local excludedUnit = fiveSecondExcludedUnit[unitID] and fiveSecondExcludedUnit[unitID][beaconID]
						if not loopedUnits[unitID] and validUnitID and not listOfBeacon[unitID] and not excludedUnit then
							local unitDefID = spGetUnitDefID(unitID)
							if not listOfMobile[unitDefID] then
								local moveID = UnitDefs[unitDefID].moveData.id
								local chargeTime = math.floor(UnitDefs[unitDefID].mass*0.25) --Note: see cost calculation in unit_teleporter.lua (by googlefrog)
								local unitSpeed = UnitDefs[unitDefID].speed
								local isBomber = UnitDefs[unitDefID].isBomber
								local isFighter = UnitDefs[unitDefID].isFighter
								local isStatic = (unitSpeed == 0)
								listOfMobile[unitDefID] = {moveID,chargeTime,unitSpeed,isBomber,isFighter,isStatic}
							end
							local isBomber = listOfMobile[unitDefID][4]
							local isFighter = listOfMobile[unitDefID][5]
							local isStatic = listOfMobile[unitDefID][6]
							repeat
								local _,_,inBuild = spGetUnitIsStunned(unitID)
								if isStatic or isBomber or isFighter or inBuild then
									loopedUnits[unitID]=true
									break; --a.k.a: Continue
								end
								
								unitToEffect[unitID] = unitToEffect[unitID] or {norm=nil,becn={nil},pos=nil,cmd=nil,defID=unitDefID}
								if not unitToEffect[unitID]["cmd"] then
									local px,py,pz= spGetUnitPosition(unitID)
									local cmd_queue = spGetCommandQueue(unitID,1);
									cmd_queue = ConvertCMDToMOVE(cmd_queue)
									unitToEffect[unitID]["pos"] = {px,py,pz}
									unitToEffect[unitID]["cmd"] = cmd_queue
								end

								if not unitToEffect[unitID]["cmd"] then
									loopedUnits[unitID]=true
									break; --a.k.a: Continue
								end
								if unitToEffect[unitID]["cmd"].id==CMD_WAIT_AT_BEACON then --DEFINED in include("LuaRules/Configs/customcmds.h.lua")
									local guardedUnit = unitToEffect[unitID]["cmd"].params[4] --DEFINED in unit_teleporter.lua
									if listOfBeacon[guardedUnit] then --if beacon exist
										local chargeTime = listOfMobile[unitDefID][2]
										beaconCurrentQueue[guardedUnit] = beaconCurrentQueue[guardedUnit] or 0
										beaconCurrentQueue[guardedUnit] = beaconCurrentQueue[guardedUnit] + chargeTime
										loopedUnits[unitID]=true
										break; --a.k.a: Continue
									else
										local cmd_queue = spGetCommandQueue(unitID,3);
										if cmd_queue[2] and cmd_queue[3] then --in case previous teleport AI teleport order make unit stuck to non-existent beacon
											spGiveOrderArrayToUnitArray({unitID},{{CMD.REMOVE, {cmd_queue[1].tag}, {}},{CMD.REMOVE, {cmd_queue[2].tag}, {}}})
											cmd_queue = ConvertCMDToMOVE({cmd_queue[3]})
											unitToEffect[unitID]["cmd"] = cmd_queue
											if not cmd_queue then --invalid command
												loopedUnits[unitID]=true
												break; --a.k.a: Continue
											end
										end
									end
								end
								if currentUnitProcessed >= numberOfUnitToProcessPerFrame then
									break;
								end
								if #unitToEffect >= numberOfUnitToProcess then
									break;
								end
								currentUnitProcessed = currentUnitProcessed + 1
								
								local px,py,pz = unitToEffect[unitID]["pos"][1],unitToEffect[unitID]["pos"][2],unitToEffect[unitID]["pos"][3]
								local cmd_queue = {id=0,params={0,0,0}}
								local unitSpeed = listOfMobile[unitDefID][3]
								local moveID = listOfMobile[unitDefID][1]
								if not unitToEffect[unitID]["norm"] then
									cmd_queue.id = unitToEffect[unitID]["cmd"].id
									cmd_queue.params[1]=unitToEffect[unitID]["cmd"].params[1] --target coordinate
									cmd_queue.params[2]=unitToEffect[unitID]["cmd"].params[2]
									cmd_queue.params[3]=unitToEffect[unitID]["cmd"].params[3]
									local distance = GetWaypointDistance(unitID,moveID,cmd_queue,px,py,pz)
									unitToEffect[unitID]["norm"] = (distance/unitSpeed)*30
								end
								cmd_queue.id =CMD.MOVE
								for l=1, #groupBeacon[i],1 do
									local beaconID2 = groupBeacon[i][l]
									if listOfBeacon[beaconID2] and listOfBeacon[beaconID2]["deployed"] == 1 then --beacon is alive?
										cmd_queue.params[1]=listOfBeacon[beaconID2][1] --beacon coordinate
										cmd_queue.params[2]=listOfBeacon[beaconID2][2]
										cmd_queue.params[3]=listOfBeacon[beaconID2][3]
										local distance = GetWaypointDistance(unitID,moveID,cmd_queue,px,py,pz)
										local timeToBeacon = (distance/unitSpeed)*30
										cmd_queue.params[1]=unitToEffect[unitID]["cmd"].params[1] --target coordinate
										cmd_queue.params[2]=unitToEffect[unitID]["cmd"].params[2]
										cmd_queue.params[3]=unitToEffect[unitID]["cmd"].params[3]
										-- if not listOfBeacon[beaconID2][4] then --if haven't update the djinnID yet
											-- local djinnID = (spGetUnitRulesParam(beaconID2,"connectto"))
											-- local ex,ey,ez = spGetUnitPosition(djinnID)
											-- listOfBeacon[beaconID2][4] = ex
											-- listOfBeacon[beaconID2][5] = ey
											-- listOfBeacon[beaconID2][6] = ez
										-- end
										local chargeTime = listOfMobile[unitDefID][2]
										local _, beaconIDToProcess, totalOverheadTime = DiggDeeper({beaconID2}, unitSpeed,cmd_queue.params,chargeTime, unitToEffect[unitID]["norm"], chargeTime,0)
										diggDeeperExclusion={}
										if beaconIDToProcess then
											distance = GetWaypointDistance(unitID,moveID,cmd_queue,listOfBeacon[beaconIDToProcess][4],listOfBeacon[beaconIDToProcess][5],listOfBeacon[beaconIDToProcess][6])
											local timeFromExitToDestination = (distance/unitSpeed)*30
											unitToEffect[unitID]["becn"][beaconID2] = timeToBeacon + timeFromExitToDestination + totalOverheadTime
										else
											unitToEffect[unitID]["becn"][beaconID2] = 99999
										end
									end
								end
							until true
							currentLoopCount = currentLoopCount + 1
						end
						--Spring.Echo("K:"..k)
						if k == numberOfLoop then
							finishLoop =true
							--Spring.Echo("FINISH")
						elseif currentLoopCount>= numberOfLoopToProcessPerFrame then
							groupSpreadJobs[i] = true
							listOfBeacon[beaconID]["prevIndex"] = k+1  --continue at next frame
							listOfBeacon[beaconID]["prevList"] = vicinityUnit  --continue at next frame
							--Spring.Echo("PAUSE,LOOP SO FAR:"..currentLoopCount)
							--Spring.Echo("PAUSE")
							break
						end
					end
					if finishLoop then
						beaconFinishLoop[beaconID] = true
						listOfBeacon[beaconID]["prevIndex"] = nil
						listOfBeacon[beaconID]["prevList"] = nil
					end
				end --// end check for case if listOfBeacon[beaconID]==nil
			end
			if groupSpreadJobs[i] then
				groupEffectedUnit[i]=unitToEffect
				groupLoopedUnit[i] = loopedUnits
				groupBeaconQueue[i] = beaconCurrentQueue
				groupBeaconFinish[i]= beaconFinishLoop
			elseif not groupSpreadJobs[i] then
				groupEffectedUnit[i]=nil
				groupLoopedUnit[i]=nil
				groupBeaconQueue[i]=nil
				groupBeaconFinish[i]=nil
				--!spawn mod=Zero-K test-10559
				--!setengine 94.1.1-645-g34c768b
				for unitID, tblContent in pairs(unitToEffect)do
					if tblContent["norm"] then
						local pathToFollow
						local lowestPathTime = tblContent["norm"]
						-- Spring.Echo("TEST:".. unitID)
						for beaconID, timeToDest in pairs(tblContent["becn"]) do
							if listOfBeacon[beaconID] then --beacon is alive
								local transitTime = timeToDest+beaconCurrentQueue[beaconID]
								if transitTime < lowestPathTime then
									pathToFollow = beaconID
									lowestPathTime = transitTime
								end
								if (timeToDest > tblContent["norm"]) then --beacon travel simply not a viable option
									fiveSecondExcludedUnit[unitID] = fiveSecondExcludedUnit[unitID] or {}
									fiveSecondExcludedUnit[unitID][beaconID] = true --exclude processing this unit for at least 5 sec or less
								end
							end
							-- if timeToDest<30000 then
								-- Spring.Echo("A:".. timeToDest .. " B:" .. beaconCurrentQueue[beaconID])
							-- end
						end
						-- Spring.Echo("Selected:"..lowestPathTime)
						if pathToFollow then
							local ex,ey,ez = listOfBeacon[pathToFollow][4],listOfBeacon[pathToFollow][5],listOfBeacon[pathToFollow][6]
							local dix,diz=unitToEffect[unitID]["cmd"].params[1],unitToEffect[unitID]["cmd"].params[3] --target coordinate
							local dx,dz = (dix-ex),(diz-ez)
							dx,dz = math.abs(dx)/dx,math.abs(dz)/dz
							spGiveOrderArrayToUnitArray({unitID},{{CMD.INSERT, {0, CMD.GUARD, CMD.OPT_SHIFT, pathToFollow}, {"alt"}},{CMD.INSERT, {1, CMD.MOVE, CMD.OPT_SHIFT, dx*50+ex,ey,dz*50+ez}, {"alt"}}})
							--local bx,by,bz = listOfBeacon[pathToFollow][1],listOfBeacon[pathToFollow][2],listOfBeacon[pathToFollow][3]
							-- local params = {bx, by, bz, pathToFollow, Spring.GetGameFrame()}
							-- Spring.GiveOrderArrayToUnitArray({unitID},{{CMD.INSERT,{0,CMD_WAIT_AT_BEACON,CMD.OPT_SHIFT, unpack(params)}, {"alt"}},{CMD.INSERT, {1, CMD.MOVE, CMD.OPT_SHIFT, dx*50+ex,ey,dz*50+ez}, {"alt"}}})
							local defID = tblContent["defID"]
							local chargeTime = listOfMobile[defID][2]
							beaconCurrentQueue[pathToFollow] = beaconCurrentQueue[pathToFollow] + chargeTime
						end
					end
				end
				for j=1, #groupBeacon[i],1 do --update beacon congestion status
					local beaconID = groupBeacon[i][j]
					if listOfBeacon[beaconID] then 
						listOfBeacon[beaconID]["becnQeuu"]= beaconCurrentQueue[beaconID]
					end
				end
			end
		end
	end
	if n%30==28 then
		for i=1 ,#groupBeaconOfficial,1 do
			groupBeacon[i] = {}
			for j=1, #groupBeaconOfficial[i],1 do
				groupBeacon[i][j]=groupBeaconOfficial[i][j]
			end
			groupBeacon[i+1] =nil
		end
	end
end

function ConvertCMDToMOVE(command)
	if (command == nil) then 
		return nil
	end
	command = command[1]
	if (command == nil) then 
		return nil
	end

	if command.id == CMD.MOVE 
	or command.id == CMD.PATROL 
	or command.id == CMD.FIGHT
	or command.id == CMD.JUMP
	or command.id == CMD.ATTACK then
		if not command.params[2] then
			local x,y,z = spGetUnitPosition(command.params[1])
			if not x then --outside LOS and radar
				return nil
			end
			command.id = CMD.MOVE
			command.params[1] = x
			command.params[2] = y
			command.params[3] = z
			return command
		else
			command.id = CMD.MOVE
			return command
		end
	end
	if command.id == CMD.RECLAIM
	or command.id == CMD.REPAIR
	or command.id == CMD.GUARD
	or command.id == CMD.RESSURECT then
		if not command.params[4] then
			if not command.params[2] then
				local x,y,z
				if command.id == CMD.REPAIR or command.id == CMD.GUARD then
					if spValidUnitID(command.params[1]) then
						x,y,z = spGetUnitPosition(command.params[1])
					elseif spValidFeatureID(command.params[1]) then
						x,y,z = spGetFeaturePosition(command.params[1])
					end
				elseif command.id == CMD.RECLAIM or command.id == CMD.RESSURECT then
					if spValidFeatureID(command.params[1]) then
						x,y,z = spGetFeaturePosition(command.params[1])
					elseif spValidUnitID(command.params[1]) then
						x,y,z = spGetUnitPosition(command.params[1])
					end
				end
				if not x then
					return nil
				end
				command.id = CMD.MOVE
				command.params[1] = x
				command.params[2] = y
				command.params[3] = z
				return command
			else
				command.id = CMD.MOVE
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
		command.id = CMD.MOVE
		return command
	end
	if command.id == CMD_WAIT_AT_BEACON then
		return command
	end
	return nil
end

function GetWaypointDistance(unitID,moveID,queue,px,py,pz) --Note: source is from unit_transport_ai.lua (by Licho)
	local d = 0
	if (queue == nil) then 
		return 99999
	end
	local v = queue
	if (v.id == CMD.MOVE) then 
		local reachable = true --always assume target reachable
		local waypoints
		if moveID then --unit has compatible moveID?
			local path = spRequestPath( moveID,px,py,pz,v.params[1],v.params[2],v.params[3],128)
			local result, lastwaypoint
			result, lastwaypoint, waypoints = IsTargetReachable(moveID,px,py,pz,v.params[1],v.params[2],v.params[3],128)
			if result == "outofreach" then --abit out of reach?
				result = IsTargetReachable(moveID,lastwaypoint[1],lastwaypoint[2],lastwaypoint[3],v.params[1],v.params[2],v.params[3],8) --refine pathing
				if result ~= "reach" then --still not reachable?
					reachable=false --target is unreachable!
				end
			end
		end
		if reachable then 
			if waypoints then --we have waypoint to destination?
				local way1,way2,way3 = px,py,pz
				for i=1, #waypoints do --sum all distance in waypoints
					d = d + Dist(way1,way2,way3, waypoints[i][1],waypoints[i][2],waypoints[i][3])
					way1,way2,way3 = waypoints[i][1],waypoints[i][2],waypoints[i][3]
				end
			else --so we don't have waypoint?
				d = d + Dist(px,py, pz, v.params[1], v.params[2], v.params[3]) --we don't have waypoint then measure straight line
			end
		else --pathing says target unreachable?!
			d = d + Dist(px,py, pz, v.params[1], v.params[2], v.params[3]) + 99999 --target unreachable!
		end
	end
	return d
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

function Dist(x,y,z, x2, y2, z2) 
	local xd = x2-x
	local yd = y2-y
	local zd = z2-z
	return math.sqrt(xd*xd + yd*yd + zd*zd)
end

------------------------------------------------------------
------------------------------------------------------------

function widget:UnitUnloaded(unitID, unitDefID, teamID, transportID) 
	 fiveSecondExcludedUnit[unitID]=nil
end

function widget:UnitCmdDone(unitID, unitDefID, unitTeam, cmdID, cmdTag) 
	fiveSecondExcludedUnit[unitID]=nil
end

function widget:UnitCommand(unitID, unitDefID, unitTeam, cmdID, cmdOpts, cmdParams)
	fiveSecondExcludedUnit[unitID]=nil
end