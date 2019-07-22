local version = "v0.845"
function widget:GetInfo()
  return {
    name      = "Teleport AI (experimental) v2",
    desc      = version .. " Automatically scan any units around teleport beacon " ..
				"(up to 600elmo, HLT range) and teleport them when it shorten travel time. "..
				"This only apply to your unit & allied beacon.",
	author    = "Msafwan",
    date      = "1 September 2013",
    license   = "GNU GPL, v2 or later",
    layer     = 21,
    enabled   = false
  }
end

local detectionRange = 600

VFS.Include("LuaRules/Configs/customcmds.h.lua")
VFS.Include("LuaRules/Utilities/isTargetReachable.lua")
VFS.Include("LuaRules/Utilities/unitTypeChecker.lua")
local spGetUnitPosition = Spring.GetUnitPosition
local spGetUnitRulesParam = Spring.GetUnitRulesParam
local spValidUnitID = Spring.ValidUnitID
local spValidFeatureID = Spring.ValidFeatureID
local spGetCommandQueue = Spring.GetCommandQueue
local spGetUnitsInCylinder = Spring.GetUnitsInCylinder
local spGetUnitDefID = Spring.GetUnitDefID
local spGiveOrderArrayToUnitArray = Spring.GiveOrderArrayToUnitArray
local spGetFeaturePosition = Spring.GetFeaturePosition
local spRequestPath = Spring.RequestPath
local spGetUnitIsStunned = Spring.GetUnitIsStunned
local spGetUnitIsTransporting = Spring.GetUnitIsTransporting
local spGetGameSeconds = Spring.GetGameSeconds
------------------------------------------------------------
------------------------------------------------------------
local myTeamID
local ud
local listOfBeacon={}
local listOfMobile={}
local groupBeacon={} --beacon list in its group
local groupBeaconOfficial={} --most recent update to beacon list
local transportChargetime = {} --store dynamic (changing) charge time for transport
--Spread job stuff: (spread looping across 1 second)
local groupSpreadJobs={} 
local groupEffectedUnit={}
local groupLoopedUnit={}
local groupBeaconQueue={}
local groupBeaconFinish={}
--end spread job stuff
local IgnoreUnit = {} --list of uninteresting/irrelevant unit to be excluded until their command changes (an Optimization)
local teleportedUnit = {}
local beaconDefID = UnitDefNames["tele_beacon"].id
--Network lag hax stuff: (wait until unit receive command before processing 2nd time)
local waitForNetworkDelay = {}
local issuedOrderTo = {}
--end network lag stuff

function widget:Initialize()
	local _, _, spec, teamID = Spring.GetPlayerInfo(Spring.GetMyPlayerID(), false)
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
				listOfBeacon[unitID] = {x,y,z,nil,nil,nil,djinID=nil,prevIndex=nil,prevList=nil,nearbyBeacon=nil,becnQeuu=0,deployed=1}
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
		listOfBeacon[unitID] = {x,y,z,nil,nil,nil,djinID=nil,prevIndex=nil,prevList=nil,nearbyBeacon=nil,becnQeuu=0,deployed=1}
		local cluster, nonClustered = WG.OPTICS_cluster(listOfBeacon, detectionRange,1, myTeamID,detectionRange) --//find clusters with atleast 1 unit per cluster and with at least within 500-elmo from each other (this function is located in api_shared_function.lua)
		groupBeaconOfficial = cluster
		for i=1, #nonClustered do
			groupBeaconOfficial[#groupBeaconOfficial+1] = {nonClustered[i]}
		end
	end
end

function widget:UnitDestroyed(unitID, unitDefID)
	listOfBeacon[unitID] = nil
	IgnoreUnit[unitID] = nil
	teleportedUnit[unitID] = nil
	if issuedOrderTo[unitID] then 
		local group = issuedOrderTo[unitID]
		issuedOrderTo[unitID] = nil 
		if waitForNetworkDelay[group] then
			waitForNetworkDelay[group][2] = waitForNetworkDelay[group][2] - 1 
			if waitForNetworkDelay[group][2]==0 then 
				waitForNetworkDelay[group] = nil 
			end
		end
	end 
end

function widget:UnitGiven(unitID, unitDefID, newTeamID, teamID)
	widget:UnitDestroyed(unitID, unitDefID)
	IgnoreUnit[unitID] = nil
end

function widget:UnitTaken(unitID, unitDefID, newTeamID, teamID)
	widget:UnitCreated(unitID, unitDefID, newTeamID)
end

------------------------------------------------------------
------------------------------------------------------------
local function GetNearbyBeacon(ex,ez,beaconData)
	local nearbyUnits = spGetUnitsInCylinder(ex,ez,detectionRange,myTeamID)
	local nearbyBeacon = {}
	for i=1, #nearbyUnits do
		local unitID = nearbyUnits[i]
		if listOfBeacon[unitID] then --is unit a beacon? (note: center unit is a Djinn, not a beacon)
			nearbyBeacon[#nearbyBeacon+1] = unitID
		end
	end
	beaconData["nearbyBeacon"]=nearbyBeacon
end

--SOME NOTE:
--"DiggDeeper()" use a straightforward recursive horizontal/sideway-search. 
function DiggDeeper(beaconIDList, unitSpeed_CNSTNT,targetCoord_CNSTNT,chargeTime_CNSTNT, lowestTime_VAR, previousOverheadTime, level, history_VAR, djinExitPos_CNSTNT)
	level = level + 1
	if level > 5 then
		return nil,nil,nil,nil
	end
	local parentUnitID_return, unitIDToProcess_return, totalOverhead_return
	local history_return = history_VAR
	--//CHECK DJIN EXIT TO DESTINATION
	for i=1, #beaconIDList do
		local beaconID = beaconIDList[i]
		local beaconData = listOfBeacon[beaconID]
		if beaconData and not history_VAR[beaconID] then --beacon exist, and not traversed by this branch yet
			if not beaconData[4] then --if haven't update the djinnID yet
				local djinnID = (spGetUnitRulesParam(beaconID,"connectto"))
				local ex,ey,ez = spGetUnitPosition(djinnID)
				beaconData[4] = ex --Djinn coordinate
				beaconData[5] = ey
				beaconData[6] = ez
			end
			local distance = Dist(beaconData[4],beaconData[5], beaconData[6], targetCoord_CNSTNT[1], targetCoord_CNSTNT[2], targetCoord_CNSTNT[3]) --Djin exit to destination
			local estTimeFromExitToDest = (distance/unitSpeed_CNSTNT)*30
			local totalTime = previousOverheadTime + chargeTime_CNSTNT + estTimeFromExitToDest + beaconData["becnQeuu"] --plus congestion information to exit beacon
				-- Spring.MarkerAddPoint(beaconData[1],beaconData[2], beaconData[3], totalTime - estTimeFromExitToDest)
			if totalTime<lowestTime_VAR then
				parentUnitID_return =beaconID
				unitIDToProcess_return =beaconID
				totalOverhead_return = totalTime - estTimeFromExitToDest --note: overhead time is: chargeTime + congestion time + time distance between an exit-to-another-enterance
				lowestTime_VAR=totalTime
			end
		end
	end
	--//DIGG DEEPER
	for i=1, #beaconIDList do
		local beaconID = beaconIDList[i]
		local beaconData = listOfBeacon[beaconID]
		if beaconData then --beacon exist
			repeat --for emulating "continue" function
				if not beaconData["nearbyBeacon"] then
					local ex,ez = beaconData[4],beaconData[6]
					GetNearbyBeacon(ex,ez,beaconData)
				end
				
				local loopDetected = false
				local newHistoryBranch = {}
				for pastBID,_ in pairs(history_VAR) do
					newHistoryBranch[pastBID] = true --copy value to new branch
					if pastBID == beaconID then --we returned to previous beacon!
						loopDetected = true
						break
					end
				end
				if loopDetected then break; end --"continue"
				newHistoryBranch[beaconID] = true

				local estTimeFromExitToAnotherBeacon = 0
				if djinExitPos_CNSTNT then --if exit position was defined (at djin)
					local distance = Dist(djinExitPos_CNSTNT[1],djinExitPos_CNSTNT[2], djinExitPos_CNSTNT[3], beaconData[1], beaconData[2], beaconData[3]) --Djin exit to beacon position
					estTimeFromExitToAnotherBeacon = (distance/unitSpeed_CNSTNT)*30
				end

				local djinExitPos = {beaconData[4],beaconData[5],beaconData[6]}
				local nearbyBeacon = beaconData["nearbyBeacon"]
				if #nearbyBeacon>0 then
					local totalOverheadTime = previousOverheadTime + chargeTime_CNSTNT + estTimeFromExitToAnotherBeacon + beaconData["becnQeuu"] --plus congestion information from enterance beacon
					local parentUnitID, unitIDToProcess, totalOverhead,lowestTime,history = DiggDeeper(nearbyBeacon, unitSpeed_CNSTNT,targetCoord_CNSTNT,chargeTime_CNSTNT, lowestTime_VAR, totalOverheadTime, level, newHistoryBranch,djinExitPos)
					if parentUnitID then --Note: only got a value if any of the children have lower totalTime than lowestTime_VAR
						parentUnitID_return =beaconID
						unitIDToProcess_return =unitIDToProcess
						totalOverhead_return =totalOverhead
						lowestTime_VAR=lowestTime
						history_return=history
					end
				end
			until true
		end
	end
	return parentUnitID_return, unitIDToProcess_return, totalOverhead_return, lowestTime_VAR,history_return
end

function widget:GameFrame(n)
	if n%150==15 then --every 150 frame period (5 second) at the 15th frame update Djinn coordinate
		for beaconID,beaconData in pairs(listOfBeacon)do
			local djinnID = (spGetUnitRulesParam(beaconID,"connectto"))
			local ex,ey,ez = spGetUnitPosition(djinnID)
			beaconData[4] = ex --4,5,6 is Djinn coordinate, 1,2,3 is beacon coordinate
			beaconData[5] = ey
			beaconData[6] = ez
			beaconData["djinID"] = djinnID
			GetNearbyBeacon(ex,ez,beaconData)
		end
		IgnoreUnit = {} --recheck ignored unit in case "CmdDone()" do not work as expected
	end
	if n%30==14 then --every 30 frame period (1 second) at the 14th frame: 
		--update deploy state
		for beaconID,beaconData in pairs(listOfBeacon) do
			local djinnID = beaconData["djinID"]
			local djinnDeployed = djinnID and (spGetUnitRulesParam(djinnID,"deploy")) or 1
			if djinnID and djinnDeployed == 1 then
				djinnDeployed = (spGetUnitIsStunned(beaconID) and 0) or 1
			end
			beaconData["deployed"] = djinnDeployed
		end
		--check if any beacon-groups under lockdown for overextended time
		local currentSecond = spGetGameSeconds()
		for groupNum, content in pairs(waitForNetworkDelay) do
			if currentSecond - content[1] > 4 then
				waitForNetworkDelay[groupNum] = nil
			end
		end
	end
	for i=1, #groupBeacon,1 do
		if ( n%15==0 and not waitForNetworkDelay[i]) or groupSpreadJobs[i] then  --every 15 frame (0.5 second) if empty. 29 frame (1 second) if full. 5 second if disconnected
			--GROUP: i
			local numberOfUnitToProcess = 29 --NUMBER OF UNIT PER BEACON PER SECOND. minimum: 29 per second
			local numberOfUnitToProcessPerFrame = math.ceil(numberOfUnitToProcess/29) --spread looping to entire 1 second
			local beaconCurrentQueue = groupBeaconQueue[i] or {}
			local unitToEffect = groupEffectedUnit[i] or {} --Note: is refreshed (empty) every second
			local loopedUnits = groupLoopedUnit[i] or {}
			local beaconFinishLoop = groupBeaconFinish[i] or {}
			groupSpreadJobs[i] = false
			for j=1, #groupBeacon[i],1 do
				--BEACON: j
				local beaconID = groupBeacon[i][j]
				beaconCurrentQueue[beaconID] =beaconCurrentQueue[beaconID] or 0
				if listOfBeacon[beaconID] and (not beaconFinishLoop[beaconID]) and listOfBeacon[beaconID]["deployed"]==1 then --beacon is alive & not finish looping? & deployed?
					local bX,bY,bZ = listOfBeacon[beaconID][1],listOfBeacon[beaconID][2],listOfBeacon[beaconID][3]
					local vicinityUnit = listOfBeacon[beaconID]["prevList"] or spGetUnitsInCylinder(bX,bZ,detectionRange,myTeamID)
					local numberOfLoop = #vicinityUnit
					local numberOfLoopToProcessPerFrame = math.ceil(numberOfLoop/29)
					local currentLoopIndex = listOfBeacon[beaconID]["prevIndex"] or 1
					local currentLoopCount = 0
					local currentUnitProcessed = 0
					local finishLoop = false
					if currentLoopIndex >= numberOfLoop then
						finishLoop =true
					end
					for k=currentLoopIndex, numberOfLoop,1 do
						--UNIT: k
						local unitID = vicinityUnit[k]
						local validUnitID = spValidUnitID(unitID)
						if not validUnitID then
							unitToEffect[unitID] = nil
						end
						local excludedUnit = IgnoreUnit[unitID] and IgnoreUnit[unitID][beaconID]
						if not loopedUnits[unitID] and validUnitID and not listOfBeacon[unitID] and not excludedUnit then
							local unitDefID = spGetUnitDefID(unitID)
							if not listOfMobile[unitDefID] then
								local moveID = UnitDefs[unitDefID].moveDef.id
								local ud = UnitDefs[unitDefID]
								local chargeTime = math.floor(ud.mass*0.25) --Note: see cost calculation in unit_teleporter.lua (by googlefrog). Charge time is in frame (number of frame)
								local unitSpeed = ud.speed --speed is in elmo-per-second
								local movetype = Spring.Utilities.getMovetype(ud)
								local isFixedWing = (movetype == 0)
								local weaponRange = GetUnitFastestWeaponRange(ud)
								local isStatic = (unitSpeed == 0)
								local isTransport = ud.transportCapacity >= 1
								listOfMobile[unitDefID] = {moveID,chargeTime,unitSpeed,isFixedWing,weaponRange,isStatic,isTransport}
							end
							local isFixedWing = listOfMobile[unitDefID][4]
							local isStatic = listOfMobile[unitDefID][6]
							repeat --note: "repeat" is to be used with "break" as method of escaping code, not looping
								--IS IMMOBILE/AIRPLANE/INBUILD UNIT? skip--
								local _,_,inBuild = spGetUnitIsStunned(unitID)
								if isStatic or isFixedWing or inBuild then
									loopedUnits[unitID]=true
									break; --a.k.a: Continue
								end
								--IS NEW UNIT? initialize them--
								unitToEffect[unitID] = unitToEffect[unitID] or {norm=nil,attckng=nil,becn={nil},pos=nil,cmd=nil,defID=unitDefID}
								local unitInfo = unitToEffect[unitID] --note: copy table reference (this mean changes to unitInfo saves into unitToEffect)
								if not unitInfo["cmd"] then
									local px,py,pz= spGetUnitPosition(unitID)
									local cmd_queue = spGetCommandQueue(unitID,2); --note: unitToEffect[] (or unitInfo[]) is emptied every second, this mean new command is read every second
									unitInfo["attckng"] = (cmd_queue and cmd_queue[1] and cmd_queue[1].id == CMD.ATTACK)
									unitInfo["cmd"] = ConvertCMDToMOVE(cmd_queue[1])
									unitInfo["pos"] = {px,py,pz}
								--IS UNIT IDLE? skip--
									if not unitInfo["cmd"] then
										loopedUnits[unitID]=true
										break; --a.k.a: Continue
									end
								--IS UNIT EXITING TELEPORT? redirect--
									if (teleportedUnit[unitID] and teleportedUnit[unitID]["x"] == unitInfo["cmd"].params[1] and teleportedUnit[unitID]["z"] == unitInfo["cmd"].params[3]) then --just teleported!
										--set next move goal, remove exit point added from previous teleporting
										spGiveOrderArrayToUnitArray({unitID},{{CMD.REMOVE, {cmd_queue[1].tag}, {}}})
										unitInfo["attckng"] = (cmd_queue and cmd_queue[2] and cmd_queue[2].id == CMD.ATTACK)
										unitInfo["cmd"] = ConvertCMDToMOVE(cmd_queue[2])
										if not unitInfo["cmd"] then --invalid command
											loopedUnits[unitID]=true
											break; --a.k.a: Continue
										end
									end
								end
								--MODIFY CHARGETIME & SPEED FOR TRANSPORT--
								local transportSpeedMod = 1
								local isTransport = listOfMobile[unitDefID][7]
								if isTransport then
									local newMass = spGetUnitRulesParam(unitID,"massOverride")
									transportChargetime[unitID] = (newMass and math.floor(newMass*0.25)) or nil --Note: see cost calculation in unit_teleporter.lua (by googlefrog). Charge time is in frame (number of frame)
									transportSpeedMod = spGetUnitRulesParam(unitID,"selfMoveSpeedChange") or 1 --see unit_transport_speed.lua
								end
								--IS UNIT WAITING AT BEACON? count them--
								if unitInfo["cmd"].id==CMD_WAIT_AT_BEACON then --DEFINED in include("LuaRules/Configs/customcmds.h.lua")
									local guardedUnit = unitInfo["cmd"].params[4] --DEFINED in unit_teleporter.lua
									if listOfBeacon[guardedUnit] then --if beacon exist
										local chargeTime = transportChargetime[unitID] or listOfMobile[unitDefID][2]
										beaconCurrentQueue[guardedUnit] = beaconCurrentQueue[guardedUnit] or 0
										beaconCurrentQueue[guardedUnit] = beaconCurrentQueue[guardedUnit] + chargeTime
										loopedUnits[unitID]=true
										break; --a.k.a: Continue
									else -- beacon removed
										local cmd_queue = spGetCommandQueue(unitID,3);
										if cmd_queue[2] and cmd_queue[3] then --in case previous teleport AI teleport order make unit stuck to non-existent beacon
											spGiveOrderArrayToUnitArray({unitID},{{CMD.REMOVE, {cmd_queue[1].tag}, {}},{CMD.REMOVE, {cmd_queue[2].tag}, {}}})
											unitInfo["attckng"] = (cmd_queue[3].id == CMD.ATTACK)
											unitInfo["cmd"] = ConvertCMDToMOVE(cmd_queue[3])
											if not unitInfo["cmd"] then --invalid command
												loopedUnits[unitID]=true
												break; --a.k.a: Continue
											end
										end
									end
								end
								currentUnitProcessed = currentUnitProcessed + 1
								local weaponRange = listOfMobile[unitDefID][5]
								--MEASURE REGULAR DISTANCE--
								local px,py,pz = unitInfo["pos"][1],unitInfo["pos"][2],unitInfo["pos"][3]
								local cmd_queue = {id=0,params={0,0,0}}
								local unitSpeed = listOfMobile[unitDefID][3] * transportSpeedMod
								local moveID = listOfMobile[unitDefID][1]
								if not unitInfo["norm"] then
									cmd_queue.id = unitInfo["cmd"].id
									cmd_queue.params[1]=unitInfo["cmd"].params[1] --target coordinate
									cmd_queue.params[2]=unitInfo["cmd"].params[2]
									cmd_queue.params[3]=unitInfo["cmd"].params[3]
									local distance = GetWaypointDistance(unitID,moveID,cmd_queue,px,py,pz,unitInfo["attckng"],weaponRange)
									unitInfo["norm"] = (distance/unitSpeed)*30
								end
								--MEASURE DISTANCE WITH TELEPORTER--
								cmd_queue.id =CMD_RAW_MOVE
								for l=1, #groupBeacon[i],1 do --iterate over all beacon in vicinity
									local beaconID2 = groupBeacon[i][l]
									if listOfBeacon[beaconID2] and listOfBeacon[beaconID2]["deployed"] == 1 then --beacon is alive?
										cmd_queue.params[1]=listOfBeacon[beaconID2][1] --beacon coordinate
										cmd_queue.params[2]=listOfBeacon[beaconID2][2]
										cmd_queue.params[3]=listOfBeacon[beaconID2][3]
										local distance = GetWaypointDistance(unitID,moveID,cmd_queue,px,py,pz,false,0) --distance to beacon
										local timeToBeacon = (distance/unitSpeed)*30 --timeToBeacon is in frame
										cmd_queue.params[1]=unitInfo["cmd"].params[1] --target coordinate
										cmd_queue.params[2]=unitInfo["cmd"].params[2]
										cmd_queue.params[3]=unitInfo["cmd"].params[3]
										local chargeTime = transportChargetime[unitID] or listOfMobile[unitDefID][2]
										local _, beaconIDToProcess, totalOverheadTime,_,history = DiggDeeper({beaconID2}, unitSpeed,cmd_queue.params,chargeTime, 99999, 0,0, {})
										if beaconIDToProcess then
											history[beaconIDToProcess] = true --add the LAST BEACON in the history list
											distance = GetWaypointDistance(unitID,moveID,cmd_queue,listOfBeacon[beaconIDToProcess][4],listOfBeacon[beaconIDToProcess][5],listOfBeacon[beaconIDToProcess][6],unitInfo["attckng"],weaponRange) --dist out of beacon
											local timeFromExitToDestination = (distance/unitSpeed)*30
											local totalTime = timeToBeacon + timeFromExitToDestination + totalOverheadTime
											unitInfo["becn"][beaconID2] = {totalTime, history}
											--Note: all unitInfo table have reference to unitToEffect[unitID], so all value already saved there.
										end
									end
								end
								loopedUnits[unitID] = true
							until true
							currentLoopCount = currentLoopCount + 1
						end
						if k >= numberOfLoop then
							finishLoop =true
						elseif currentUnitProcessed >= numberOfUnitToProcessPerFrame or currentLoopCount>= numberOfLoopToProcessPerFrame then
							groupSpreadJobs[i] = true
							listOfBeacon[beaconID]["prevIndex"] = k+1  --continue at next frame
							listOfBeacon[beaconID]["prevList"] = vicinityUnit  --continue at next frame
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
				for unitID, unitInfo in pairs(unitToEffect)do
					if unitInfo["norm"] then
						local pathToFollow
						--NOTE: time to destination is in frame (number of frame).
						local lowestPathTime = unitInfo["norm"] - 30 --add 1 second benefit to regular walking (make walking more attractive choice unless teleport can save more than 1 second travel time)
						for beaconID, beaconResult in pairs(unitInfo["becn"]) do
							if listOfBeacon[beaconID] then --beacon is alive
								local pathCurrentQueue = 0
								for traversedBID,_ in pairs(beaconResult[2]) do --check beacon(s) traversed in beacon network and sum newest congestion delay info for each beacon traversed. Note: beaconCurrentQueue[beaconID] is latest congestion delay and listOfBeacon[beaconID]["becnQeuu"] is the "last-time/ previous check's" congestion delay (included in beaconResult[1])
									pathCurrentQueue = pathCurrentQueue + (beaconCurrentQueue[traversedBID] or 0) --Note: beaconCurrentQueue[pastBID] can be NIL if other group haven't been updated yet
								end
								local timeToDest = beaconResult[1]
								local transitTime = timeToDest + pathCurrentQueue
								if transitTime < lowestPathTime then
									pathToFollow = beaconID
									lowestPathTime = transitTime
								end
								if (timeToDest > unitInfo["norm"]) then --beacon travel simply not a viable option
									IgnoreUnit[unitID] = IgnoreUnit[unitID] or {}
									IgnoreUnit[unitID][beaconID] = true --exclude processing this unit forever until its command changed
								end
							end
						end
						if pathToFollow then
							local ex,ey,ez = listOfBeacon[pathToFollow][4],listOfBeacon[pathToFollow][5],listOfBeacon[pathToFollow][6]
							local dix,diz=unitToEffect[unitID]["cmd"].params[1],unitToEffect[unitID]["cmd"].params[3] --target coordinate
							local dx,dz = (dix-ex),(diz-ez)
							dx,dz = math.abs(dx)/dx,math.abs(dz)/dz
							--wait for network delay:--
							issuedOrderTo[unitID] = i
							waitForNetworkDelay[i] = waitForNetworkDelay[i] or {spGetGameSeconds(),0}
							waitForNetworkDelay[i][2] = waitForNetworkDelay[i][2] + 1
							--end network delay
							--save exit coordinate:--
							teleportedUnit[unitID] = { x = dx*50+ex ,y = ey, z = dz*50+ez } --(a coordinate of a command that we going to give)
							--end fix
							--method A: give GUARD order--
							spGiveOrderArrayToUnitArray({unitID},{{CMD.INSERT, {0, CMD.GUARD, CMD.OPT_SHIFT, pathToFollow}, CMD.OPT_ALT},{CMD.INSERT, {1, CMD_RAW_MOVE, CMD.OPT_INTERNAL, dx*50+ex,ey,dz*50+ez}, CMD.OPT_ALT}})
							local defID = unitInfo["defID"]
							local chargeTime = transportChargetime[unitID] or listOfMobile[defID][2]
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
	if (v.id == CMD_RAW_MOVE) then 
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
			d = d + Dist(px,py, pz, v.params[1], v.params[2], v.params[3]) + 99999 --target unreachable!
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

function widget:UnitUnloaded(unitID, unitDefID, teamID, transportID) 
	IgnoreUnit[unitID]=nil
end

function widget:UnitCmdDone(unitID, unitDefID, unitTeam, cmdID, cmdTag) 
	IgnoreUnit[unitID]=nil
end

function widget:UnitCommand(unitID, unitDefID, unitTeam, cmdID, cmdParams, cmdOptions)
	IgnoreUnit[unitID]=nil
	if issuedOrderTo[unitID] and (CMD.INSERT == cmdID and cmdParams[2] == CMD_WAIT_AT_BEACON) then 
		local group = issuedOrderTo[unitID]
		issuedOrderTo[unitID] = nil 
		if waitForNetworkDelay[group] then
			waitForNetworkDelay[group][2] = waitForNetworkDelay[group][2] - 1 
			if waitForNetworkDelay[group][2]==0 then 
				waitForNetworkDelay[group] = nil 
			end
		end
	end
end