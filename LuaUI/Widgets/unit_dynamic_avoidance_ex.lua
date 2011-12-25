local versionName = "v1.68"
--------------------------------------------------------------------------------
--
--  file:    cmd_dynamic_Avoidance.lua
--  brief:   a collision avoidance system
--  original idea: "non-Linear Dynamic system approach to modelling behavior" -SiomeGoldenstein, Edward Large, DimitrisMetaxas
--	code:  Msafwan
--
--  Licensed under the terms of the GNU GPL, v2 or later.
--
--------------------------------------------------------------------------------
function widget:GetInfo()
  return {
    name      = "Dynamic Avoidance System",
    desc      = versionName .. "Dynamic Collision Avoidance behaviour for constructor and cloakies",
    author    = "msafwan (system coder)",
    date      = "Dec 19, 2011",
    license   = "GNU GPL, v2 or later",
    layer     = 20,
    enabled   = false  --  loaded by default?
  }
end

--------------------------------------------------------------------------------
-- Functions:
local spGetTeamUnits 	= Spring.GetTeamUnits
local spGetGroundHeight = Spring.GetGroundHeight
local spGiveOrderToUnit =Spring.GiveOrderToUnit
local spGetMyTeamID 	= Spring.GetMyTeamID
local spIsUnitAllied 	= Spring.IsUnitAllied
local spGetUnitPosition =Spring.GetUnitPosition
local spGetUnitDefID 	= Spring.GetUnitDefID
local spGetUnitSeparation	= Spring.GetUnitSeparation
local spGetUnitDirection	=Spring.GetUnitDirection
local spGetUnitsInRectangle =Spring.GetUnitsInRectangle
local spGetVisibleUnits = Spring.GetVisibleUnits
local spGetCommandQueue	= Spring.GetCommandQueue
local spGetUnitIsDead 	= Spring.GetUnitIsDead
local spGetGameSeconds	= Spring.GetGameSeconds
local spGetFeaturePosition = Spring.GetFeaturePosition
local spValidFeatureID = Spring.ValidFeatureID
local spGetPlayerInfo = Spring.GetPlayerInfo
local spGetUnitStates = Spring.GetUnitStates
local spGetUnitTeam = Spring.GetUnitTeam
local spSendLuaUIMsg = Spring.SendLuaUIMsg
local spGetUnitLastAttacker = Spring.GetUnitLastAttacker
local spGetUnitHealth = Spring.GetUnitHealth
local CMD_STOP			= CMD.STOP
local CMD_INSERT		= CMD.INSERT
local CMD_REMOVE		= CMD.REMOVE
local CMD_MOVE			= CMD.MOVE
local CMD_OPT_INTERNAL	= CMD.OPT_INTERNAL
local CMD_OPT_SHIFT		= CMD.OPT_SHIFT
--------------------------------------------------------------------------------
-- Constant:
-- Switches:
local turnOnEcho =0 --Echo out all numbers for debugging the system (default = 0)
local activateAutoReverseG=1 --set to auto-reverse when unit is about to collide with an enemy (default = 0)
local activateImpatienceG=0 --auto disable auto-reverse and half the distanceCONSTANT after 6 continuous auto-avoidance (3 second). In case the unit stuck (default = 0)

-- Graph constant:
local distanceCONSTANTunitG = 410 --increase obstacle awareness over distance. (default = 410 meter, ie: ZK's stardust range)
local safetyMarginCONSTANTunitG = 0.0 --obstacle graph offset (a "safety margin" constant). Offset the obstacle effect: to prefer avoid torward more left or right (default = 0.0 radian)
local smCONSTANTunitG		= 0.0  -- obstacle graph offset (a "safety margin" constant).  Offset the obstacle effect: to prefer avoid torward more left or right (default = 0.0 radian)
local aCONSTANTg			= math.pi/10 -- attractor graph; scale the attractor's strenght. Less equal to a lesser attraction(default = math.pi/10 radian, max math.pi/2)
local obsCONSTANTg			= math.pi/10 -- obstacle graph; scale the obstacle's strenght. Less equal to a lesser avoidance(default = math.pi/10 radian)
--aCONSTANTg Note: math.pi/4 is equal to about 45 degrees turning (left or right). aCONSTANTg is the maximum amount of turning toward target and the actual turning depend on unit's direction.
--an antagonist to aCONSTANg (obsCONSTANTg) Note: obstacle graph also use math.pi/4 (45 degree left or right) but actual maximum value varies depend on number of enemy.
local windowingFuncMultG = 1 --? (default = 1 multiplier)

-- Obstacle/Target competetive interaction constant:
local cCONSTANT1g 			= 1 --attractor constant; effect the behaviour. ie: the selection between 4 behaviour state. (default = 2 multiplier)
local cCONSTANT2g			= 1 --repulsor constant; effect behaviour. (default = 2 multiplier)
local gammaCONSTANT2and1g	= 0.05 -- balancing constant; effect behaviour. . (default = 0.05 multiplier)
local alphaCONSTANT1g		= 0.4 -- balancing constant; effect behaviour. (default = 0.4 multiplier)

-- Distance or velocity constant:
local timeToContactCONSTANTg=0.5 --the time scale; for time to collision calculation (default = 0.5 second). Will change based on user's Ping
local safetyDistanceCONSTANTg=205 --range toward an obstacle before unit auto-reverse (default = 205 meter, ie: half of ZK's stardust range) reference:80 is a size of BA's solar
local extraLOSRadiusCONSTANTg=205 --add additional distance for unit awareness over the default LOS. (default = +200 meter radius, ie: to 'see' radar blip)
local velocityScalingCONSTANTg=1 --decrease/increase command lenght. (default= 1 multiplier)
local velocityAddingCONSTANTg=10 --minimum speed. Add or remove minimum command lenght (default = 0 meter/second)

--Move Command constant:
local halfTargetBoxSize = {400, 50, 190} --the distance from a target which widget should de-activate (default: move = 400m ie:800x800m box (2x constructor range), reclaim/ressurect=50 (flee if not close enough), repair=190 (1x constructor's range -10))
local cMD_DummyG = 248 --a fake command ID to flag an idle unit for pure avoidance. (arbitrary value, change if conflict with existing command)
local dummyIDg = "248" --fake id for Lua Message to check lag (prevent processing of latest Command queue if server haven't process previous command yet; to avoid messy queue) (arbitrary value, change if conflict with other widget)

--Angle constant:
--http://en.wikipedia.org/wiki/File:Degree-Radian_Conversion.svg
local noiseAngleG =math.pi/36 --(default is pi/36 rad); add random angle (range from 0 to +-math.pi/36) to the new angle. To prevent a rare state that contribute to unit going straight toward enemy
local collisionAngleG=math.pi/12 --(default is pi/6 rad) a "field of vision" (range from 0 to +-math.pi/6) where auto-reverse will activate 
local fleeingAngleG=math.pi/4 --(default is pi/4 rad) angle of enemy (range from 0 to +-math.pi/4) where fleeing enemy is considered. Set to 0 to de-activate.
local maximumTurnAngleG = math.pi/2 --safety measure. Prevent overturn (eg: 360+xx degree turn)
--pi is 180 degrees

--Update constant:
local doCalculation_then_gps_delayG = 0.3 --elapsed second before gathering preliminary data for issuing new command (default: < gps_then_DoCalculation_delayG)
local gps_then_DoCalculation_delayG = 0.45 --elapsed second before issuing new command (default: < 0.5)

--Engine based correction constant:
local wreckageID_offset_multiplier = 0 --for 0.82 this is 1500
local wreckageID_offset_initial = 32000	--for 0.82 this is 4500
--curModID = upper(Game.modShortName)
--------------------------------------------------------------------------------
--Variables:
local unitInMotionG={} --store unitID
local skippingTimerG={0,0, echoTimestamp=0, networkDelay=0, sumOfAllNetworkDelay=0, sumCounter=0}
local commandIndexTableG= {} --store latest widget command for comparison
local myTeamID=-1
local myPlayerID=-1
local gaiaTeamID = Spring.GetGaiaTeamID()
local surroundingOfActiveUnitG={} --store value for transfer between function. Store obstacle separation, los, and ect.
local cycleG=1 --first execute "GetPreliminarySeparation()"
local wreckageID_offset=0
local roundTripComplete= true --variable for detecting network lag, prevent messy overlapping command queuing
local attackerG= {}
--------------------------------------------------------------------------------
--Methods:
---------------------------------Level 0
function widget:Initialize()
	skippingTimerG.echoTimestamp = spGetGameSeconds()
	myPlayerID=Spring.GetMyPlayerID()
	local _, _, spec = Spring.GetPlayerInfo(myPlayerID)
	if spec then widgetHandler:RemoveWidget() return false end
	myTeamID= spGetMyTeamID()
	
	--count players to offset the ID of wreckage
	local playerIDList= Spring.GetPlayerList()
	local numberOfPlayers=#playerIDList
	for i=1,numberOfPlayers do
		local _,_,spectator,_,_,_,_,_,_=spGetPlayerInfo(playerIDList[i])
		if spectator then numberOfPlayers=numberOfPlayers-1 end
	end
	wreckageID_offset=wreckageID_offset_initial+ (numberOfPlayers-2)*wreckageID_offset_multiplier
	if (turnOnEcho == 1) then Spring.Echo("myTeamID(Initialize)" .. myTeamID) end
end

function widget:PlayerChanged(playerID)
	if Spring.GetSpectatingState() then widgetHandler:RemoveWidget() end
	--count players to offset the ID of wreckage
	local playerIDList= Spring.GetPlayerList()
	local numberOfPlayers=#playerIDList
	for i=1,numberOfPlayers do
		local _,_,spectator,_,_,_,_,_,_=spGetPlayerInfo(playerIDList[i])
		if spectator then numberOfPlayers=numberOfPlayers-1 end
	end
	wreckageID_offset=wreckageID_offset_initial+ (numberOfPlayers-2)*wreckageID_offset_multiplier
end

--execute different function at different timescale
function widget:Update()
	-------retrieve global table, localize global table
	local commandIndexTable=commandIndexTableG
	local unitInMotion = unitInMotionG
	local surroundingOfActiveUnit=surroundingOfActiveUnitG
	local cycle = cycleG
	local skippingTimer = skippingTimerG
	local timeToContactCONSTANT=timeToContactCONSTANTg
	local attacker = attackerG
	-----
	local now=spGetGameSeconds()
	if (now >= skippingTimer[1]) then --if "now" is 1.1 second after last update then do "RefreshUnitList()"
		if (turnOnEcho == 1) then Spring.Echo("-----------------------RefreshUnitList") end
		unitInMotion, attacker=RefreshUnitList(attacker) --add relevant unit to unitlist/unitInMotion
		local projectedDelay=ReportedNetworkDelay(myPlayerID, 1.1) --set unit update based on ping or every 1.1 second
		skippingTimer[1]=now+projectedDelay
		if (turnOnEcho == 1) then Spring.Echo("-----------------------RefreshUnitList") end
	end
	
	if (now >=skippingTimer[2] and cycle==1) and roundTripComplete then --if now is 0.1 second after last update & already unlocked by echo from server then do "GetPreliminarySeparation()"
		if (turnOnEcho == 1) then Spring.Echo("-----------------------GetPreliminarySeparation") end
		surroundingOfActiveUnit,commandIndexTable=GetPreliminarySeparation(unitInMotion,commandIndexTable, attacker)
		cycle=2 --send next cycle to "DoCalculation()" function
		
		skippingTimer = ActualNetworkDelay(1, skippingTimer, nil, nil ,now) --measure network delay
		skippingTimer[2] = now+ gps_then_DoCalculation_delayG --delay next cycle by an additional 0.4 second. This allow reliable unit direction to be derived from unit's speed
		if (turnOnEcho == 1) then Spring.Echo("-----------------------GetPreliminarySeparation") end
	end
	if (now >=skippingTimer[2] and cycle==2) then --if now is 0.5 second after last update & already executed GetPreliminarySeparation() then do "DoCalculation()"
		if (turnOnEcho == 1) then Spring.Echo("-----------------------DoCalculation") end
		commandIndexTable=DoCalculation (surroundingOfActiveUnit,commandIndexTable, attacker) --initiate the avoidance
		cycle=1 --send next cycle back to "GetPreliminarySeparation()" function
		
		--local projectedDelay=ReportedNetworkDelay(myPlayerID, 0.5) --get the reported ping
		skippingTimer[2]=now+ doCalculation_then_gps_delayG ---set next execution 0.1 second later
		local networkDelay = ActualNetworkDelay(0, skippingTimer, doCalculation_then_gps_delayG, gps_then_DoCalculation_delayG, nil) --get network delay
		timeToContactCONSTANT= networkDelay --extend command lenght by as much as the network delay
		
		skippingTimer = ActualNetworkDelay(2, skippingTimer, nil, nil, now) --set timestamp
		spSendLuaUIMsg(dummyIDg) --send ping to server
		roundTripComplete = false --lock execution until receive echo from server
		if (turnOnEcho == 1) then Spring.Echo("-----------------------DoCalculation") end
	end

	if (turnOnEcho == 1) then
		Spring.Echo("unitInMotion(Update):")
		Spring.Echo(unitInMotion)
	end
	-------return global table
	commandIndexTableG=commandIndexTable
	unitInMotionG = unitInMotion
	surroundingOfActiveUnitG=surroundingOfActiveUnit
	cycleG = cycle
	skippingTimerG = skippingTimer
	timeToContactCONSTANTg=timeToContactCONSTANT
	attackerG = attacker
	-----
end
---------------------------------Level 0 Top level
---------------------------------Level1 Lower level
-- return a refreshed unit list, else return nil
function RefreshUnitList(attacker)
	local allMyUnits = spGetTeamUnits(myTeamID)
	local arrayIndex=1
	local relevantUnit={}
	
	local metaForVisibleUnits = {}
	local visibleUnits=spGetVisibleUnits(myTeamID)
	for _, unitID in ipairs(visibleUnits) do --memorize units that is in view of camera
		metaForVisibleUnits[unitID]="yes" --set "yes" for visible unit (in view) and by default set "nil" for non visible unit
	end
	for _, unitID in ipairs(allMyUnits) do
		if unitID~=nil then --skip end of the table
			-- refresh attacker's list
			attacker = RetrieveAttackerList (unitID, attacker)
			--
			local unitDefID = spGetUnitDefID(unitID)
			local unitDef = UnitDefs[unitDefID]
			local unitSpeed =unitDef["speed"]
			local unitInView = metaForVisibleUnits[unitID] --transfer "yes" or "nil" from meta table into a local variable
			if (unitSpeed>0) then 
				if (unitDef["builder"] or unitDef["canCloak"]) and not unitDef.customParams.commtype then --only include only cloakies and constructor, and not com (ZK)
					arrayIndex=arrayIndex+1
					relevantUnit[arrayIndex]={unitID, 1, unitSpeed, isVisible = unitInView}
				elseif not unitDef["canFly"] then --if enabled: include all ground unit
					arrayIndex=arrayIndex+1
					relevantUnit[arrayIndex]={unitID, 2, unitSpeed, isVisible = unitInView}
				end
			end
			if (turnOnEcho == 1) then --for debugging
				Spring.Echo("unitID(RefreshUnitList)" .. unitID)
				Spring.Echo("unitDef[humanName](RefreshUnitList)" .. unitDef["humanName"])
				Spring.Echo("((unitDef[builder] or unitDef[canCloak]) and unitDef[speed]>0)(RefreshUnitList):")
				Spring.Echo((unitDef["builder"] or unitDef["canCloak"]) and unitDef["speed"]>0)
			end
		end
	end
	if arrayIndex>1 then relevantUnit[1]=arrayIndex -- store the array's lenght in the first row of the array
	else relevantUnit[1] = nil end --send out nil if no unit is present
	if (turnOnEcho == 1) then
		Spring.Echo("allMyUnits(RefreshUnitList): ")
		Spring.Echo(allMyUnits)
		Spring.Echo("relevantUnit(RefreshUnitList): ")
		Spring.Echo(relevantUnit)
	end
	return relevantUnit, attacker
end

-- detect initial enemy separation to detect "fleeing enemy"  later
function GetPreliminarySeparation(unitInMotion,commandIndexTable, attacker)
	local surroundingOfActiveUnit={}
	if unitInMotion[1]~=nil then --don't execute if no unit present
		local arrayIndex=1
		for i=2, unitInMotion[1], 1 do --array index 1 contain the array's lenght, start from 2
			local unitID= unitInMotion[i][1] --get unitID for commandqueue
			if spGetUnitIsDead(unitID)==false then --prevent execution if unit died during transit
				local cQueue = spGetCommandQueue(unitID)
				if cQueue~=nil then --prevent ?. Forgot...
					if (unitInMotion[i].isVisible ~= "yes" and (cQueue[1] == nil or #cQueue == 1)) then --if unit is out of user's vision and is idle/with-singular-mono-command (eg: widget's move order)
						local state=spGetUnitStates(unitID)
						local movestate= state.movestate
						if movestate~= 0 then --if not "hold position"
							cQueue={{id = cMD_DummyG, params = {-1 ,-1,-1}, options = {}}, {id = CMD_STOP, params = {-1 ,-1,-1}, options = {}}, nil} --replace with a fake command. Will be used to initiate avoidance on idle unit & non-viewed unit
						end
					end
				if cQueue[1]~=nil then --prevent idle unit from executing the system
					if ((cQueue[1].id == 40 or cQueue[1].id < 0 or cQueue[1].id == 90 or cQueue[1].id == CMD_MOVE or cQueue[1].id == 125 or  cQueue[1].id == cMD_DummyG) and (unitInMotion[i][2] == 1 or unitInMotion[i].isVisible ~= "yes")) then  -- only command: repair (40), build (<0), reclaim (90), ressurect(125) or move(10), and ONLY for unitType=1 OR all units outside player's vision
					if #cQueue>=2 then --prevent STOP command from short circuiting the system
					if cQueue[2].id~=false then --prevent a spontaneous enemy engagement from short circuiting the system
						--local boxSizeTrigger= unitInMotion[i][2]
						local targetCoordinate, commandIndexTable, newCommand, boxSizeTrigger=IdentifyTargetOnCommandQueue(cQueue, unitID, commandIndexTable) --check old or new command
						local currentX,_,currentZ = spGetUnitPosition(unitID)
						local lastPosition = {currentX, currentZ} --record current position for use to determine unit direction later.
						local reachedTarget = TargetBoxReached(targetCoordinate, unitID, boxSizeTrigger, lastPosition) --check if widget should ignore command
						local losRadius	= GetUnitLOSRadius(unitID) --get LOS
						local surroundingUnits	= GetAllUnitsInRectangle(unitID, losRadius, attacker) --catalogue enemy
						if (cQueue[1].id == CMD_MOVE and unitInMotion[i].isVisible ~= "yes") then --if unit has move Command and is outside user's view
							reachedTarget = false --force unit to do avoidance despite close to target (try to circle over target until seen by user)
						end
						if reachedTarget then --if reached target
							commandIndexTable[unitID]=nil --empty the commandIndex (command history)
						end
						
						if surroundingUnits[1]~=nil and not reachedTarget then  --execute when enemy exist and target not reached yet
							local unitSSeparation=CatalogueMovingObject(surroundingUnits, unitID, lastPosition) --detect initial enemy separation
							arrayIndex=arrayIndex+1
							local unitSpeed = unitInMotion[i][3]
							local impatienceTrigger,commandIndexTable = GetImpatience(newCommand,unitID, commandIndexTable)
							surroundingOfActiveUnit[arrayIndex]={unitID, unitSSeparation, targetCoordinate, losRadius, cQueue, newCommand, unitSpeed,impatienceTrigger, lastPosition} --store result for next execution
							if (turnOnEcho == 1) then
								Spring.Echo("unitsSeparation(GetPreliminarySeparation):")
								Spring.Echo(unitsSeparation)
							end
						end
						
						if (turnOnEcho == 1) then --debugging
							Spring.Echo("i(GetPreliminarySeparation)" .. i)
							Spring.Echo("unitID(GetPreliminarySeparation)" .. unitID)
							Spring.Echo("losRadius(GetPreliminarySeparation)" .. losRadius)
							Spring.Echo("surroundingUnits(GetPreliminarySeparatione): ")
							Spring.Echo(surroundingUnits)
							Spring.Echo("reachedTarget(GetPreliminarySeparation):")
							Spring.Echo(reachedTarget)
							Spring.Echo("surroundingUnits~=nil and cQueue[1].id==CMD_MOVE and not reachedTarget(GetPreliminarySeparation):")
							Spring.Echo((surroundingUnits~=nil and cQueue[1].id==CMD_MOVE and not reachedTarget))
						end
					end --if cQueue[2].id~=false
						if (turnOnEcho == 1) then Spring.Echo(cQueue[2].id) end --for debugging
					end --if #cQueue>=2
					end --if ((cQueue[1].id==40 or cQueue[1].id<0 or cQueue[1].id==90 or cQueue[1].id==10 or cQueue[1].id==125) and (unitInMotion[i][2]==1 or unitInMotion[i].isVisible == nil)
				end --if cQueue[1]~=nil
				end --if cQueue~=nil
			end --if spGetUnitIsDead(unitID)==false
		end
		if arrayIndex>1 then surroundingOfActiveUnit[1]=arrayIndex 
		else surroundingOfActiveUnit[1]=nil end
	end --if unitInMotion[1]~=nil
	return surroundingOfActiveUnit, commandIndexTable --send separation result away
end

--perform the actual collision avoidance calculation and send the appropriate command to unit
function DoCalculation (surroundingOfActiveUnit,commandIndexTable, attacker)
	if surroundingOfActiveUnit[1]~=nil then --if flagged as nil then no stored content then this mean there's no relevant unit
		for i=2,surroundingOfActiveUnit[1], 1 do --index 1 is for array's lenght
			local unitID=surroundingOfActiveUnit[i][1]
			if spGetUnitIsDead(unitID)==false then --prevent unit death from short circuiting the system
				local unitSSeparation=surroundingOfActiveUnit[i][2]
				local targetCoordinate=surroundingOfActiveUnit[i][3]
				local losRadius=surroundingOfActiveUnit[i][4]
				local cQueue=surroundingOfActiveUnit[i][5]
				local newCommand=surroundingOfActiveUnit[i][6]
				
				--do sync test. Ensure stored command not changed during last delay
				local cQueueSyncTest = spGetCommandQueue(unitID)
				if #cQueueSyncTest>=2 then
					if #cQueueSyncTest~=#cQueue or --if command queue is not same as original, or
						(cQueueSyncTest[1].params[1]~=cQueue[1].params[1] or cQueueSyncTest[1].params[3]~=cQueue[1].params[3]) or --if first queue has different content, or
							cQueueSyncTest[1]==nil then --if unit has became idle
						--newCommand=true
						--cQueue=cQueueSyncTest
						commandIndexTable[unitID]=nil --empty commandIndex (command history) for this unit
						return commandIndexTable --skip
					end
				end
				
				local unitSpeed= surroundingOfActiveUnit[i][7]
				local impatienceTrigger= surroundingOfActiveUnit[i][8]
				local lastPosition = surroundingOfActiveUnit[i][9]
				local newSurroundingUnits	= GetAllUnitsInRectangle(unitID, losRadius, attacker) --get new unit separation for comparison
				local newX, newZ = AvoidanceCalculator(unitID, targetCoordinate,losRadius,newSurroundingUnits, unitSSeparation, unitSpeed, impatienceTrigger, lastPosition) --calculate move solution
				local newY=spGetGroundHeight(newX,newZ)
				commandIndexTable= InsertCommandQueue(cQueue, unitID, newX, newY, newZ, commandIndexTable, newCommand) --send move solution to unit
				if (turnOnEcho == 1) then
					Spring.Echo("newX(Update) " .. newX)
					Spring.Echo("newZ(Update) " .. newZ)
				end			
			end
		end
	end
	return commandIndexTable
end

function widget:RecvLuaMsg(msg, playerID) --receive echo from server
	if msg:sub(1,3) == dummyIDg and playerID == myPlayerID then
		roundTripComplete = true
	end
end

function ReportedNetworkDelay(playerIDa, defaultDelay)
	local _,_,_,_,_,totalDelay,_,_,_,_= Spring.GetPlayerInfo(playerIDa)
	if totalDelay==nil or totalDelay<=defaultDelay then return defaultDelay --if ping is too low: set the minimum delay
	else return totalDelay --take account for lag + wait a little bit for any command to properly update
	end
end

function ActualNetworkDelay(reportingIn, skippingTimer,doCalculation_then_gps_delay,gps_then_DoCalculation_delay, now)
	if reportingIn == 0 then
		local delay = 0
		local systemDelay = doCalculation_then_gps_delay+ gps_then_DoCalculation_delay --delay artificially imposed
		local instantaneousCommandDelay = skippingTimer.networkDelay+ systemDelay --delay at this instant
		local averageDelay = skippingTimer.sumOfAllNetworkDelay/skippingTimer.sumCounter + systemDelay --delay from previous history (an average)
		if instantaneousCommandDelay < averageDelay then --prevent random Network fluctuation from shortening command lenght too much
			delay = averageDelay 
		else
			delay = instantaneousCommandDelay
		end 
		return delay
	elseif reportingIn == 1 then
		skippingTimer.networkDelay = now - skippingTimer.echoTimestamp --get the delay between previous Command and latest unlock
		skippingTimer.sumOfAllNetworkDelay=skippingTimer.sumOfAllNetworkDelay + skippingTimer.networkDelay
		skippingTimer.sumCounter = skippingTimer.sumCounter + 1
		return skippingTimer
	elseif reportingIn == 2 then
		skippingTimer.echoTimestamp = now	--remember the current time of sending ping
		return skippingTimer
	end
end
---------------------------------Level1
---------------------------------Level2 (level 1's call-in)
function RetrieveAttackerList (unitID, attacker)
	local unitHealth,_,_,_,_ = spGetUnitHealth(unitID)
	if attacker[unitID] == nil then --if attacker table is empty then fill with default value
		attacker[unitID] = {id = nil, countDown = 0, myHealth = unitHealth}
	end
	if attacker[unitID].countDown >0 then attacker[unitID].countDown = attacker[unitID].countDown - 1 end --count-down until zero and stop
	if unitHealth< attacker[unitID].myHealth then --if underattack then find out the attackerID
		local attackerID = spGetUnitLastAttacker(unitID)
		if attackerID~=nil then --if attackerID is found then mark the attackerID for avoidance
			attacker[unitID].countDown = attacker[unitID].countDown + 3
			attacker[unitID].id = attackerID
		end
	end
	attacker[unitID].myHealth = unitHealth --refresh health data	
	return attacker
end

--check if widget's command or user's command
function IdentifyTargetOnCommandQueue(cQueue, unitID,commandIndexTable)
	local targetCoordinate = {}
	local boxSizeTrigger=0
	local newCommand=true -- immediately assume user's command
	if commandIndexTable[unitID]==nil then --memory was empty, so fill it with zeros
		commandIndexTable[unitID]={widgetX=0, widgetZ=0 ,backupTargetX=0, backupTargetY=0, backupTargetZ=0, patienceIndexA=0}
	else
		local a = math.modf(dNil(cQueue[1].params[1])) --using math.modf to remove trailing decimal (using only integer for matching). In case high resolution cause a fail matching with server's numbers... and use dNil incase wreckage suddenly disappear.
		local b = math.modf(commandIndexTable[unitID]["widgetX"])
		local c = math.modf(dNil(cQueue[1].params[3])) --dNil: if it is a reclaim or repair order (no z coordinate) then replace it with -1 (has similar effect to the "nil")
		local d = math.modf(commandIndexTable[unitID]["widgetZ"])
		newCommand= (a~= b and c~=d)--check current command with memory
		if (turnOnEcho == 1) then --debugging
			Spring.Echo("unitID(GetPreliminarySeparation)" .. unitID)
			Spring.Echo("commandIndexTable[unitID][widgetX](IdentifyTargetOnCommandQueue):" .. commandIndexTable[unitID]["widgetX"])
			Spring.Echo("commandIndexTable[unitID][widgetZ](IdentifyTargetOnCommandQueue):" .. commandIndexTable[unitID]["widgetZ"])
			Spring.Echo("newCommand(IdentifyTargetOnCommandQueue):")
			Spring.Echo(newCommand)
			Spring.Echo("cQueue[1].params[1](IdentifyTargetOnCommandQueue):" .. cQueue[1].params[1])
			Spring.Echo("cQueue[1].params[2](IdentifyTargetOnCommandQueue):" .. cQueue[1].params[2])
			Spring.Echo("cQueue[1].params[3](IdentifyTargetOnCommandQueue):" .. cQueue[1].params[3])
			if cQueue[2]~=nil then
				Spring.Echo("cQueue[2].params[1](IdentifyTargetOnCommandQueue):")
				Spring.Echo(cQueue[2].params[1])
				Spring.Echo("cQueue[2].params[3](IdentifyTargetOnCommandQueue):")
				Spring.Echo(cQueue[2].params[3])
			end
		end
	end
	if newCommand then	--if user's new command
		commandIndexTable, targetCoordinate, boxSizeTrigger = ExtractTarget (1, unitID,cQueue,commandIndexTable,targetCoordinate)
		commandIndexTable[unitID]["patienceIndexA"]=0
	else  --if widget's previous command
		commandIndexTable, targetCoordinate, boxSizeTrigger = ExtractTarget (2, unitID,cQueue,commandIndexTable,targetCoordinate)	
	end
	return targetCoordinate, commandIndexTable, newCommand, boxSizeTrigger --return target coordinate
end

--ignore command set on this box
function TargetBoxReached (targetCoordinate, unitID, boxSizeTrigger, lastPosition)
	local currentX, currentZ = lastPosition[1], lastPosition[2]
	local targetX = dNil(targetCoordinate[1]) -- use dNil in case target asynchronously/spontaneously disappear: which replace value with -1 
	local targetZ =targetCoordinate[3]
	if targetX==-1 then return false end --if target is invalid (-1) then assume target is not reached, return false (default value), and continue avoidance 
	local xDistanceToTarget = math.abs(currentX -targetX)
	local zDistanceToTarget = math.abs(currentZ -targetZ)
	if (turnOnEcho == 1) then
		Spring.Echo("unitID(TargetBoxReached)" .. unitID)
		Spring.Echo("currentX(TargetBoxReached)" .. currentX)
		Spring.Echo("currentZ(TargetBoxReached)" .. currentZ)
		Spring.Echo("cx(TargetBoxReached)" .. targetX)
		Spring.Echo("cz(TargetBoxReached)" .. targetZ)
		Spring.Echo("(xDistanceToTarget<=halfTargetBoxSize[boxSizeTrigger] and zDistanceToTarget<=halfTargetBoxSize[boxSizeTrigger])(TargetBoxReached):")
		Spring.Echo((xDistanceToTarget<=halfTargetBoxSize[boxSizeTrigger] and zDistanceToTarget<=halfTargetBoxSize[boxSizeTrigger]))
	end
	return (xDistanceToTarget<=halfTargetBoxSize[boxSizeTrigger] and zDistanceToTarget<=halfTargetBoxSize[boxSizeTrigger]) --only command greater than this box return false
end

-- get LOS
function GetUnitLOSRadius(unitID)
	local unitDefID= spGetUnitDefID(unitID)
	local unitDef= UnitDefs[unitDefID]
	local losRadius =550 --arbitrary (scout LOS)
	if unitDef~=nil then --if unitDef is not empty then use the following LOS
		losRadius= unitDef.losRadius*32 --for some reason it was times 32
	end
	return (losRadius + extraLOSRadiusCONSTANTg)
end

--return a table of surrounding enemy
function GetAllUnitsInRectangle(unitID, losRadius, attacker)
	local x,y,z = spGetUnitPosition(unitID)
	local unitDefID = spGetUnitDefID(unitID)
	local unitDef = UnitDefs[unitDefID]
	local iAmConstructor = unitDef["builder"]
	local unitState = spGetUnitStates(unitID)
	local iAmNotCloaked = not unitState["cloak"]
	
	if (turnOnEcho == 1) then
		Spring.Echo("spGetUnitIsDead(unitID)==false (GetAllUnitsInRectangle):")
		Spring.Echo(spGetUnitIsDead(unitID)==false)
	end
	local unitsInRectangle = spGetUnitsInRectangle(x-losRadius, z-losRadius, x+losRadius, z+losRadius)

	local relevantUnit={}
	local arrayIndex=1	
	--add attackerID into enemy list
	relevantUnit, arrayIndex = AddAttackerIDToEnemyList (unitID, losRadius, relevantUnit, arrayIndex, attacker)
	--
	for _, rectangleUnitID in ipairs(unitsInRectangle) do
		local isAlly= spIsUnitAllied(rectangleUnitID)
		if (rectangleUnitID ~= unitID) and not isAlly then--filter out ally units and self
			local rectangleUnitTeamID = spGetUnitTeam(rectangleUnitID)
			if (rectangleUnitTeamID ~= gaiaTeamID) then --filter out gaia (non aligned unit)
				local recUnitDefID = spGetUnitDefID(rectangleUnitID)
				if recUnitDefID~=nil and (iAmConstructor and iAmNotCloaked) then --if the enemy is in plain sight and I am not the cloakies that need to avoid everything: then do the following check before registering enemy
					local recUnitDef = UnitDefs[recUnitDefID]
					if recUnitDef["weapons"][1]~=nil then -- if enemy has weapons: then register enemy
						arrayIndex=arrayIndex+1
						relevantUnit[arrayIndex]=rectangleUnitID
					end
				else --if enemy is only unidentified radar blip: then register enemy
					arrayIndex=arrayIndex+1
					relevantUnit[arrayIndex]=rectangleUnitID
				end
			end
		end
	end
	if arrayIndex>1 then relevantUnit[1]=arrayIndex --fill index 1 with array lenght
	else relevantUnit[1]=nil end
	if (turnOnEcho == 1) then
		Spring.Echo("relevantUnit(GetAllUnitsInRectangle): ")
		Spring.Echo(relevantUnit)
	end
	return relevantUnit
end

--allow a unit to recognize fleeing enemy; so it doesn't need to avoid them
function CatalogueMovingObject(surroundingUnits, unitID, lastPosition)
	local unitsSeparation={}
	if (surroundingUnits[1]~=nil) then --don't catalogue anything if no enemy exist
		for i=2,surroundingUnits[1],1 do
			local unitRectangleID=surroundingUnits[i]
			if (unitRectangleID ~= nil) then
				local relativeAngle 	= GetUnitRelativeAngle (unitID, unitRectangleID)
				local unitDirection		= GetUnitDirection(unitID, lastPosition)
				local unitSeparation	= spGetUnitSeparation (unitID, unitRectangleID)
				if math.abs(unitDirection- relativeAngle)< (collisionAngleG) then --unit inside the collision angle is catalogued with correct value
					unitsSeparation[unitRectangleID]=unitSeparation
				else --unit outside the collision angle is set to arbitrary 999
					unitsSeparation[unitRectangleID]=999 --set to 999 for other unit so that any normal value will imply an approaching units
				end
			end
		end
	end
	if (turnOnEcho == 1) then
		Spring.Echo("unitSeparation(CatalogueMovingObject):")
		Spring.Echo(unitsSeparation)
	end
	return unitsSeparation
end

function GetImpatience(newCommand, unitID, commandIndexTable)
	local impatienceTrigger=1 --zero will de-activate auto reverse
	if commandIndexTable[unitID]["patienceIndexA"]>=6 then impatienceTrigger=0 end
	if not newCommand and activateImpatienceG==1 then
		commandIndexTable[unitID]["patienceIndexA"]=commandIndexTable[unitID]["patienceIndexA"]+1 --increase impatience index
	end
	if (turnOnEcho == 1) then Spring.Echo("commandIndexTable[unitID][patienceIndexA] (GetImpatienceLevel) " .. commandIndexTable[unitID]["patienceIndexA"]) end
	return impatienceTrigger, commandIndexTable
end

function AvoidanceCalculator(unitID, targetCoordinate, losRadius, surroundingUnits, unitsSeparation, unitSpeed, impatienceTrigger, lastPosition)
	if (unitID~=nil) and (targetCoordinate ~= nil) then --prevent idle/non-existent/ unit with invalid command from using collision avoidance
		local aCONSTANT 			= aCONSTANTg --attractor constant (amplitude multiplier)
		local unitDirection			= GetUnitDirection(unitID, lastPosition) --get unit direction
		local targetAngle = 0
		local fTarget = 0
		local fTargetSlope = 0
		if targetCoordinate[1]~=-1 then --if target coordinate contain -1 then disable target for pure avoidance
			targetAngle				= GetTargetAngleWithRespectToUnit(unitID, targetCoordinate) --get target angle
			fTarget					= GetFtarget (aCONSTANT, targetAngle, unitDirection)
			fTargetSlope			= GetFtargetSlope (aCONSTANT, targetAngle, unitDirection, fTarget)
			--local targetSubtendedAngle 	= GetTargetSubtendedAngle(unitID, targetCoordinate) --get target 'size' as viewed by the unit
		end

		local wTotal=0
		local fObstacleSum=0
		local dFobstacle=0
		local dSum=0
		local nearestFrontObstacleRange =999
		local normalizingFactor=0

		--count every enemy unit and sum its contribution to the obstacle/repulsor variable
		wTotal, dSum, fObstacleSum,dFobstacle,nearestFrontObstacleRange, normalizingFactor=SumAllUnitAroundUnitID (unitID, surroundingUnits, unitDirection, wTotal, dSum, fObstacleSum,dFobstacle,nearestFrontObstacleRange, unitsSeparation, impatienceTrigger)
		--calculate appropriate behaviour based on the constant and above summation value
		local wTarget, wObstacle = CheckWhichFixedPointIsStable (fTargetSlope, dFobstacle, dSum, fTarget, fObstacleSum, wTotal)
		--convert an angular command into a coordinate command
		local newX, newZ= SendCommand(unitID, wTarget, wObstacle, fTarget, fObstacleSum, unitDirection, nearestFrontObstacleRange, losRadius, unitSpeed, impatienceTrigger, normalizingFactor)
		if (turnOnEcho == 1) then
			Spring.Echo("unitID(AvoidanceCalculator)" .. unitID)
			Spring.Echo("targetAngle(AvoidanceCalculator) " .. targetAngle)
			Spring.Echo("unitDirection(AvoidanceCalculator) " .. unitDirection)
			Spring.Echo("fTarget(AvoidanceCalculator) " .. fTarget)
			Spring.Echo("fTargetSlope(AvoidanceCalculator) " .. fTargetSlope)
			--Spring.Echo("targetSubtendedAngle(AvoidanceCalculator) " .. targetSubtendedAngle)			
			Spring.Echo("wTotal(AvoidanceCalculator) " .. wTotal)
			Spring.Echo("dSum(AvoidanceCalculator) " .. dSum)
			Spring.Echo("fObstacleSum(AvoidanceCalculator) " .. fObstacleSum)
			Spring.Echo("dFobstacle(AvoidanceCalculator) " .. dFobstacle)
			Spring.Echo("nearestFrontObstacleRange(AvoidanceCalculator) " .. nearestFrontObstacleRange)
			Spring.Echo("wTarget(AvoidanceCalculator) " .. wTarget)
			Spring.Echo("wObstacle(AvoidanceCalculator) " .. wObstacle)
			Spring.Echo("newX(AvoidanceCalculator) " .. newX)
			Spring.Echo("newZ(AvoidanceCalculator) " .. newZ)
		end
		return newX, newZ --return move coordinate
	end
end

-- maintain the visibility of original command
-- reference: "unit_tactical_ai.lua" -ZeroK gadget by Google Frog
function InsertCommandQueue(cQueue, unitID,newX, newY, newZ, commandIndexTable, newCommand)
	--Method 1: doesn't work online
	--if not newCommand then spGiveOrderToUnit(unitID, CMD_REMOVE, {cQueue[1].tag}, {} ) end --delete old command
	-- spGiveOrderToUnit(unitID, CMD_INSERT, {0, CMD_MOVE, CMD_OPT_INTERNAL, newX, newY, newZ}, {"alt"} ) --insert new command
	----
	--Method 2: doesn't work online
	-- if not newCommand then spGiveOrderToUnit(unitID, CMD_MOVE, {cQueue[1].params[1],cQueue[1].params[2],cQueue[1].params[3]}, {"ctrl","shift"} ) end --delete old command
	-- spGiveOrderToUnit(unitID, CMD_INSERT, {0, CMD_MOVE, CMD_OPT_INTERNAL, newX, newY, newZ}, {"alt"} ) --insert new command
	----
	--Method 3.5: cause big movement noise
	-- newX = Round(newX)
	-- newY = Round(newY)
	-- newZ = Round(newZ)
	----
	--Method 3: work online, but under rare circumstances doesn't work
	-- spGiveOrderToUnit(unitID, CMD.STOP, {}, {})
	-- spGiveOrderToUnit(unitID, CMD_MOVE, {newX, newY, newZ}, {} )
	-- local arrayIndex=1
	-- if not newCommand then arrayIndex=2 end --skip old widget command
	-- if #cQueue>=2 then --try to identify unique signature of area reclaim/repair
		-- if (cQueue[1].id==40 or cQueue[1].id==90 or cQueue[1].id==125) then
			-- if cQueue[2].id==90 or cQueue[2].id==125 then 
				-- if (not Spring.ValidFeatureID(cQueue[2].params[1]-wreckageID_offset) or (not Spring.ValidFeatureID(cQueue[2].params[1]))) and not Spring.ValidUnitID(cQueue[2].params[1]) then --if it is an area command
					-- spGiveOrderToUnit(unitID, CMD_MOVE, cQueue[2].params, {} ) --divert unit to the center of reclaim/repair command
					-- arrayIndex=arrayIndex+1 --skip the target:wreck/units. Allow command reset
				-- end
			-- elseif cQueue[2].id==40 then
				-- if (not Spring.ValidFeatureID(cQueue[2].params[1]-wreckageID_offset) or (not Spring.ValidFeatureID(cQueue[2].params[1]))) and not Spring.ValidUnitID(cQueue[2].params[1]) then --if it is an area command
					-- arrayIndex=arrayIndex+1 --skip the target:units. Allow continuous command reset
				-- end
			-- end
		-- end
	-- end
	-- for b = arrayIndex, #cQueue,1 do --re-do user's optional command
		-- local options={"shift",nil,nil,nil}
		-- local optionsIndex=2
		-- if cQueue[b].options["alt"] then 
			-- options[optionsIndex]="alt"
		-- end
		-- if cQueue[b].options["ctrl"] then 
			-- optionsIndex=optionsIndex+1
			-- options[optionsIndex]="ctrl"
		-- end
		-- if cQueue[b].options["right"] then 
			-- optionsIndex=optionsIndex+1
			-- options[optionsIndex]="right"
		-- end
		-- spGiveOrderToUnit(unitID, cQueue[b].id, cQueue[b].params, options) --replace the rest of the command
	-- end
	--Method 4: with network delay detection won't do any problem
	local queueIndex=1
	if not newCommand then  --if widget's command then delete it
		spGiveOrderToUnit(unitID, CMD_REMOVE, {cQueue[1].tag}, {} ) --delete previous widget command
		queueIndex=2 --skip index 1 of stored command. Skip widget's command
	end
	if #cQueue>=queueIndex+2 then --reclaim 1,area reclaim 2,stop 3, or: move 1,reclaim 2, area reclaim 3,stop 4.
		if (cQueue[queueIndex].id==40 or cQueue[queueIndex].id==90 or cQueue[queueIndex].id==125) then --if first (1) queue is reclaim/ressurect/repair
			if cQueue[queueIndex+1].id==90 or cQueue[queueIndex+1].id==125 then --if second (2) queue is also reclaim/ressurect
				if (not Spring.ValidFeatureID(cQueue[queueIndex+1].params[1]-wreckageID_offset) or (not Spring.ValidFeatureID(cQueue[queueIndex+1].params[1]))) and not Spring.ValidUnitID(cQueue[queueIndex+1].params[1]) then --if it was an area command
					spGiveOrderToUnit(unitID, CMD_REMOVE, {cQueue[queueIndex].tag}, {} ) --delete old command, skip the target:wreck/units. Allow command reset
					spGiveOrderToUnit(unitID, CMD_INSERT, {0, CMD_MOVE, CMD_OPT_SHIFT, cQueue[queueIndex+1].params[1], cQueue[queueIndex+1].params[2], cQueue[queueIndex+1].params[3]}, {"alt"} ) --divert unit to the center of reclaim/repair command
				end
			elseif cQueue[queueIndex+1].id==40 then --if second (2) queue is also repair
				if (not Spring.ValidFeatureID(cQueue[queueIndex+1].params[1]-wreckageID_offset) or (not Spring.ValidFeatureID(cQueue[queueIndex+1].params[1]))) and not Spring.ValidUnitID(cQueue[queueIndex+1].params[1]) then --if it was an area command
					spGiveOrderToUnit(unitID, CMD_REMOVE, {cQueue[queueIndex].tag}, {} ) --delete old command, skip the target:units. Allow continuous command reset
				end
			end
		end
	end
	spGiveOrderToUnit(unitID, CMD_INSERT, {0, CMD_MOVE, CMD_OPT_SHIFT, newX, newY, newZ}, {"alt"} ) --insert new command
	----
	commandIndexTable[unitID]["widgetX"]=newX --update the memory table. So that next update can use to check if unit has new or old (widget's) command
	commandIndexTable[unitID]["widgetZ"]=newZ
	if (turnOnEcho == 1) then
		Spring.Echo("unitID(InsertCommandQueue)" .. unitID)
		Spring.Echo("commandIndexTable[unitID][widgetX](InsertCommandQueue):" .. commandIndexTable[unitID]["widgetX"])
		Spring.Echo("commandIndexTable[unitID][widgetZ](InsertCommandQueue):" .. commandIndexTable[unitID]["widgetZ"])
		Spring.Echo("newCommand(InsertCommandQueue):")
		Spring.Echo(newCommand)
		Spring.Echo("cQueue[1].params[1](InsertCommandQueue):" .. cQueue[1].params[1])
		Spring.Echo("cQueue[1].params[3](InsertCommandQueue):" .. cQueue[1].params[3])
		if cQueue[2]~=nil then
			Spring.Echo("cQueue[2].params[1](InsertCommandQueue):")
			Spring.Echo(cQueue[2].params[1])
			Spring.Echo("cQueue[2].params[3](InsertCommandQueue):")
			Spring.Echo(cQueue[2].params[3])
		end
	end
	return commandIndexTable --return updated memory table
end
---------------------------------Level2
---------------------------------Level3 (low-level function)
function ExtractTarget (queueIndex, unitID, cQueue, commandIndexTable, targetCoordinate)
	local boxSizeTrigger=0
	if (cQueue[queueIndex].id==CMD_MOVE or cQueue[queueIndex].id<0) then
		local targetPosX, targetPosY, targetPosZ = -1, -1, -1 -- (-1) is default value because -1 represent "no target"
		if cQueue[queueIndex].params[1]~= nil and cQueue[queueIndex].params[2]~=nil and cQueue[queueIndex].params[3]~=nil then
			targetPosX, targetPosY, targetPosZ = cQueue[queueIndex].params[1], cQueue[queueIndex].params[2],cQueue[queueIndex].params[3]
		else
			--Spring.Echo("Dynamic Avoidance targetting failure: fallback to no target")
		end
		targetCoordinate={targetPosX, targetPosY, targetPosZ } --use first queue as target
		commandIndexTable[unitID]["backupTargetX"]=cQueue[queueIndex].params[1] --backup the target
		commandIndexTable[unitID]["backupTargetY"]=cQueue[queueIndex].params[2]
		commandIndexTable[unitID]["backupTargetZ"]=cQueue[queueIndex].params[3]
		boxSizeTrigger=1
	elseif cQueue[queueIndex].id==90 or cQueue[queueIndex].id==125 then --reclaim or ressurect
		-- local a = Spring.GetUnitCmdDescs(unitID, Spring.FindUnitCmdDesc(unitID, 90), Spring.FindUnitCmdDesc(unitID, 90))
		-- Spring.Echo(a[queueIndex]["name"])
		local wreckPosX, wreckPosY, wreckPosZ = -1, -1, -1 -- -1 is default value because -1 represent "no target"
		local targetFeatureID=-1
		local iterativeTest=1
		local foundMatch=false
		if Spring.ValidUnitID(cQueue[queueIndex].params[1]) then --if reclaim own unit
			foundMatch=true
			wreckPosX, wreckPosY, wreckPosZ = spGetUnitPosition(cQueue[queueIndex].params[1])
		elseif Spring.ValidFeatureID(cQueue[queueIndex].params[1]) then --if reclaim trees and rock
			foundMatch=true
			wreckPosX, wreckPosY, wreckPosZ = spGetFeaturePosition(cQueue[queueIndex].params[1])
		else --if not own unit or trees or rock then
			targetFeatureID=cQueue[queueIndex].params[1]+wreckageID_offset_multiplier-wreckageID_offset --remove the inherent offset
			while iterativeTest<=3 and not foundMatch do --do test of reclaim wreckage (wreckage ID depend on number of players)
				if Spring.ValidFeatureID(targetFeatureID) then
					foundMatch=true
					wreckPosX, wreckPosY, wreckPosZ = spGetFeaturePosition(targetFeatureID)
				elseif Spring.ValidUnitID(targetFeatureID) then
					foundMatch=true
					wreckPosX, wreckPosY, wreckPosZ = spGetUnitPosition(targetFeatureID)
				end
				iterativeTest=iterativeTest+1
				targetFeatureID=targetFeatureID-wreckageID_offset_multiplier
			end
		end
		local isAreaMode = false
		if foundMatch==false then --if no wreckage, no trees, no rock, and no unitID then use coordinate
			if cQueue[queueIndex].params[1]~= nil and cQueue[queueIndex].params[2]~=nil and cQueue[queueIndex].params[3]~=nil then
				wreckPosX, wreckPosY,wreckPosZ = cQueue[queueIndex].params[1], cQueue[queueIndex].params[2],cQueue[queueIndex].params[3]
				isAreaMode = true
			else
				--Spring.Echo("Dynamic Avoidance targetting failure: fallback to no target")
			end
		end
		targetCoordinate={wreckPosX, wreckPosY,wreckPosZ} --use wreck as target
		commandIndexTable[unitID]["backupTargetX"]=wreckPosX --backup the target
		commandIndexTable[unitID]["backupTargetY"]=wreckPosY
		commandIndexTable[unitID]["backupTargetZ"]=wreckPosZ
		boxSizeTrigger=2
		if not isAreaMode and (cQueue[queueIndex+1].params[3]==nil or cQueue[queueIndex+1].id == CMD_STOP) then --signature for discrete reclaim/ressurect command
			boxSizeTrigger = 3 --change to boxsize similar to repair command
		end
	elseif cQueue[queueIndex].id==40 then --repair command
		local unitPosX, unitPosY, unitPosZ = -1, -1, -1 -- (-1) is default value because -1 represent "no target"
		local targetUnitID=cQueue[queueIndex].params[1]
	
		if Spring.ValidUnitID(targetUnitID) then --if has unit ID
			unitPosX, unitPosY, unitPosZ = spGetUnitPosition(targetUnitID)
		elseif cQueue[queueIndex].params[1]~= nil and cQueue[queueIndex].params[2]~=nil and cQueue[queueIndex].params[3]~=nil then --if no unit then use coordinate
			unitPosX, unitPosY,unitPosZ = cQueue[queueIndex].params[1], cQueue[queueIndex].params[2],cQueue[queueIndex].params[3]
		else
			--Spring.Echo("Dynamic Avoidance targetting failure: fallback to no target")
		end
		targetCoordinate={unitPosX, unitPosY,unitPosZ} --use ally unit as target
		commandIndexTable[unitID]["backupTargetX"]=unitPosX --backup the target
		commandIndexTable[unitID]["backupTargetY"]=unitPosY
		commandIndexTable[unitID]["backupTargetZ"]=unitPosZ
		boxSizeTrigger=3
	elseif cQueue[1].id == cMD_DummyG then
		targetCoordinate = {-1, -1,-1} --no target (only avoidance)
	else --if queue is empty: then use no-target. eg: A case where engine delete the next queues of command and widget expect it to still be there.
		targetCoordinate={-1, -1, -1}
		--if for some reason command queue[2] is already empty then use these backup value as target:
		--targetCoordinate={commandIndexTable[unitID]["backupTargetX"], commandIndexTable[unitID]["backupTargetY"],commandIndexTable[unitID]["backupTargetZ"]} --if the second queue isappear then use the backup
	end
	return commandIndexTable, targetCoordinate, boxSizeTrigger
end

function AddAttackerIDToEnemyList (unitID, losRadius, relevantUnit, arrayIndex, attacker)
	if attacker[unitID].countDown > 0 then
		local separation = spGetUnitSeparation (unitID,attacker[unitID].id)
		if separation ~=nil then --if attackerID is still a valid id (ie: enemy did not disappear) then:
			if separation> losRadius then
				arrayIndex=arrayIndex+1
				relevantUnit[arrayIndex]=rectangleUnitID
			end
		end
	end
	return relevantUnit, arrayIndex
end

function GetUnitRelativeAngle (unitIDmain, unitID2)
	local x,_,z = spGetUnitPosition(unitIDmain)
	local rX, _, rZ= spGetUnitPosition(unitID2)
	local cX, _, cZ = rX-x, _, rZ-z 
	local relativeAngle = math.atan2 (cZ, cX)
	return relativeAngle
end

function GetTargetAngleWithRespectToUnit(unitID, targetCoordinate)
	local x,_,z = spGetUnitPosition(unitID)
	local tx, tz = targetCoordinate[1], targetCoordinate[3]
	local dX, dZ = tx- x, tz-z 
	local targetAngle = math.atan2(dZ, dX)
	return targetAngle
end

function GetUnitDirection(unitID, lastPosition)
	local dx = 0
	local dz = 0
	local currentX, _,currentZ = spGetUnitPosition(unitID)
	dx = currentX-lastPosition[1]
	dz = currentZ-lastPosition[2]
	if (dx == 0 and dz == 0) then --use the reported unit direction if lastPosition didn't reveal direction
		dx,_,dz= spGetUnitDirection(unitID)
	end
	local unitDirection = math.atan2(dz, dx)
	return unitDirection
end

--attractor's sinusoidal wave function (target's sine wave function)
function GetFtarget (aCONSTANT, targetAngle, unitDirection)
	local fTarget = -1*aCONSTANT*math.sin(unitDirection - targetAngle)
	return fTarget
end

--attractor's graph slope at unit's direction
function GetFtargetSlope (aCONSTANT, targetAngle, unitDirection, fTarget)
	local unitDirectionPlus1 = unitDirection+0.05
	local fTargetPlus1 = -1*aCONSTANT*math.sin(unitDirectionPlus1 - targetAngle)
	local fTargetSlope=(fTargetPlus1-fTarget) / (unitDirectionPlus1 -unitDirection)
	return fTargetSlope
end

--target angular size
function GetTargetSubtendedAngle(unitID, targetCoordinate)
	local tx,tz = targetCoordinate[1],targetCoordinate[3]
	local x,_,z = spGetUnitPosition(unitID)
	local unitDefID= spGetUnitDefID(unitID)
	local unitDef= UnitDefs[unitDefID]
	local unitSize =32--arbitrary value, size of a com
	if(unitDef~=nil) then unitSize = unitDef.xsize*8 end --8 is the actual Distance per square, times the unit's square

	local targetDistance= distance (tx,tz,x,z)
	local targetSubtendedAngle = math.atan(unitSize*2/targetDistance) --target is same size as unit's
	return targetSubtendedAngle
end

--sum the contribution from all enemy unit
function SumAllUnitAroundUnitID (thisUnitID, surroundingUnits, unitDirection, wTotal, dSum, fObstacleSum,dFobstacle, nearestFrontObstacleRange, unitsSeparation, impatienceTrigger)
	local safetyMarginCONSTANT = safetyMarginCONSTANTunitG
	local smCONSTANT = smCONSTANTunitG --?
	local distanceCONSTANT = distanceCONSTANTunitG
	local obsCONSTANT =obsCONSTANTg
	local normalizingFactor = 0
	if (turnOnEcho == 1) then Spring.Echo("unitID(SumAllUnitAroundUnitID)" .. thisUnitID) end
	if (surroundingUnits[1]~=nil) then --don't execute if no enemy unit exist
		local graphSample={}
		for i=1, 360+1, 1 do
			graphSample[i]=0 --initialize content
		end
		for i=2,surroundingUnits[1], 1 do
			local unitRectangleID=surroundingUnits[i]
			if (unitRectangleID ~= nil)then --excluded any nil entry
				local unitSeparation	= spGetUnitSeparation (thisUnitID, unitRectangleID)
				--if enemy spontaneously appear then set the memorized separation distance to 999; maybe previous polling missed it and to prevent nil
				if unitsSeparation[unitRectangleID]==nil then unitsSeparation[unitRectangleID]=999 end
				if (turnOnEcho == 1) then
					Spring.Echo("unitSeparation <unitsSeparation[unitRectangleID](SumAllUnitAroundUnitID)")
					Spring.Echo(unitSeparation <unitsSeparation[unitRectangleID])
				end
				if unitSeparation <(unitsSeparation[unitRectangleID] or 999) then --see if the enemy is maintaining distance
					local relativeAngle 	= GetUnitRelativeAngle (thisUnitID, unitRectangleID)
					local subtendedAngle	= GetUnitSubtendedAngle (thisUnitID, unitRectangleID)

					--get obstacle/ enemy/repulsor wave function
					if impatienceTrigger==0 then --zero means that unit is impatient
						distanceCONSTANT=distanceCONSTANT/2
					end
					local ri, wi, di = GetRiWiDi (unitDirection, relativeAngle, subtendedAngle, unitSeparation, safetyMarginCONSTANT, smCONSTANT, distanceCONSTANT,obsCONSTANT)
					local fObstacle = ri*wi*di
					distanceCONSTANT=distanceCONSTANTunitG --reset distance constant

					--get second obstacle/enemy/repulsor wave function to calculate slope
					local ri2, wi2, di2 = GetRiWiDi (unitDirection+0.05, relativeAngle, subtendedAngle, unitSeparation, safetyMarginCONSTANT, smCONSTANT, distanceCONSTANT, obsCONSTANT)
					local fObstacle2 = ri2*wi2*di2
					
					--create a snapshot of the entire graph. Resolution: 360 datapoint
					local dI = math.exp(-1*unitSeparation/distanceCONSTANT) --distance multiplier
					local hI = windowingFuncMultG/ (math.cos(2*subtendedAngle) - math.cos(2*subtendedAngle+ safetyMarginCONSTANT))
					for i=-180, 180, 1 do --sample the entire graph
						local differenceInAngle = (unitDirection+math.pi/i)-relativeAngle
						local rI = (differenceInAngle/ subtendedAngle)*math.exp(1- math.abs(differenceInAngle/subtendedAngle))
						local wI = obsCONSTANT* (math.tanh(hI- (math.cos(differenceInAngle) -math.cos(2*subtendedAngle +smCONSTANT)))+1) --graph with limiting window
						graphSample[i+180+1]=graphSample[i+180+1]+ (rI*wI*dI*hI)
					end

					--get repulsor wavefunction's slope
					local fObstacleSlope = GetFObstacleSlope(fObstacle2, fObstacle, unitDirection+0.05, unitDirection)

					--sum all repulsor's wavefunction from every enemy/obstacle within this loop
					wTotal, dSum, fObstacleSum,dFobstacle, nearestFrontObstacleRange= DoAllSummation (wi, fObstacle, fObstacleSlope, di,wTotal, unitDirection, unitSeparation, relativeAngle, dSum, fObstacleSum,dFobstacle, nearestFrontObstacleRange)
				end
			end
		end
		local biggestValue=0
		for i=1, 360+1, 1 do --find maximum value from graph
			if biggestValue<graphSample[i] then
				biggestValue = graphSample[i]
			end
		end
		if biggestValue > obsCONSTANT then
			normalizingFactor = obsCONSTANT/biggestValue --normalize graph value to a determined maximum
		else 
			normalizingFactor = 1 --don't change the graph if the graph never exceed maximum value
		end
	end
	return wTotal, dSum, fObstacleSum,dFobstacle, nearestFrontObstacleRange, normalizingFactor --return obstacle's calculation result
end

--determine appropriate behaviour
function CheckWhichFixedPointIsStable (fTargetSlope, dFobstacle, dSum, fTarget, fObstacleSum, wTotal)
	local alphaCONSTANT1, alphaCONSTANT2, gammaCONSTANT1and2, gammaCONSTANT2and1 = ConstantInitialize(fTargetSlope, dFobstacle, dSum, fTarget, fObstacleSum, wTotal)
	local wTarget=0
	local wObstacle=1
	if (turnOnEcho == 1) then
		Spring.Echo("alphaCONSTANT1(CheckWhichFixedPointIsStable)" .. alphaCONSTANT1)
		Spring.Echo ("alphaCONSTANT2(CheckWhichFixedPointIsStable)" ..alphaCONSTANT2)
		Spring.Echo ("gammaCONSTANT1and2(CheckWhichFixedPointIsStable)" ..gammaCONSTANT1and2)
		Spring.Echo ("gammaCONSTANT2and1(CheckWhichFixedPointIsStable)" ..gammaCONSTANT2and1)
	end

	if (alphaCONSTANT1 < 0) and (alphaCONSTANT2 <0) then --state 0 is unstable, unit don't move
		wTarget = 0
		wObstacle =0
		if (turnOnEcho == 1) then Spring.Echo("state 0") end
	end

	if (gammaCONSTANT1and2 > alphaCONSTANT1) and (alphaCONSTANT2 >0) then 	--state 1: unit flee from obstacle and forget target
		wTarget =0
		wObstacle =-1
		if (turnOnEcho == 1) then Spring.Echo("state 1") end
	end

	if(gammaCONSTANT2and1 > alphaCONSTANT2) and (alphaCONSTANT1 >0) then --state 2: unit forget obstacle and go for the target
		wTarget= -1
		wObstacle =0
		if (turnOnEcho == 1) then  Spring.Echo("state 2") end
	end

	if (alphaCONSTANT1>0) and (alphaCONSTANT2>0) then --state 3: mixed contribution from target and obstacle
		if (alphaCONSTANT1> gammaCONSTANT1and2) and (alphaCONSTANT2>gammaCONSTANT2and1) then
			if (gammaCONSTANT1and2*gammaCONSTANT2and1 < 0.0) then
				--function from latest article. Set repulsor/attractor balance
				 wTarget= math.sqrt((alphaCONSTANT2*(alphaCONSTANT1-gammaCONSTANT1and2))/(alphaCONSTANT1*alphaCONSTANT2-gammaCONSTANT1and2*gammaCONSTANT2and1))
				 wObstacle= math.sqrt((alphaCONSTANT1*(alphaCONSTANT2-gammaCONSTANT2and1))/(alphaCONSTANT1*alphaCONSTANT2-gammaCONSTANT1and2*gammaCONSTANT2and1))

				-- wTarget= math.sqrt((alphaCONSTANT2*(alphaCONSTANT1-gammaCONSTANT2and1))/(alphaCONSTANT1*alphaCONSTANT2-gammaCONSTANT1and2*gammaCONSTANT2and1))
				-- wObstacle= math.sqrt((alphaCONSTANT1*(alphaCONSTANT2-gammaCONSTANT2and1))/(alphaCONSTANT1*alphaCONSTANT2-gammaCONSTANT1and2*gammaCONSTANT2and1))
						 if (turnOnEcho == 1) then  Spring.Echo("state 3") end
			end

			if (gammaCONSTANT1and2>0) and (gammaCONSTANT2and1>0) then
				--function from latest article. Set repulsor/attractor balance
				 wTarget= math.sqrt((alphaCONSTANT2*(alphaCONSTANT1-gammaCONSTANT1and2))/(alphaCONSTANT1*alphaCONSTANT2-gammaCONSTANT1and2*gammaCONSTANT2and1))
				 wObstacle= math.sqrt((alphaCONSTANT1*(alphaCONSTANT2-gammaCONSTANT2and1))/(alphaCONSTANT1*alphaCONSTANT2-gammaCONSTANT1and2*gammaCONSTANT2and1))

				-- wTarget= math.sqrt((alphaCONSTANT2*(alphaCONSTANT1-gammaCONSTANT2and1))/(alphaCONSTANT1*alphaCONSTANT2-gammaCONSTANT1and2*gammaCONSTANT2and1))
				-- wObstacle= math.sqrt((alphaCONSTANT1*(alphaCONSTANT2-gammaCONSTANT2and1))/(alphaCONSTANT1*alphaCONSTANT2-gammaCONSTANT1and2*gammaCONSTANT2and1))
				wTarget= wTarget*-1
					 if (turnOnEcho == 1) then Spring.Echo("state 4") end
			end
		end
	else if (turnOnEcho == 1) then Spring.Echo ("State not listed") end
	end
		if (turnOnEcho == 1) then  Spring.Echo ("wTarget (CheckWhichFixedPointIsStable)" ..wTarget) end
		if (turnOnEcho == 1) then Spring.Echo ("wObstacle(CheckWhichFixedPointIsStable)" ..wObstacle) end
	return wTarget, wObstacle --return attractor's and repulsor's multiplier
end

--convert angular command into coordinate, plus other function
function SendCommand(thisUnitID, wTarget, wObstacle, fTarget, fObstacleSum, unitDirection, nearestFrontObstacleRange, losRadius, unitSpeed, impatienceTrigger, normalizingFactor)
	local safetyDistanceCONSTANT=safetyDistanceCONSTANTg
	local timeToContactCONSTANT=timeToContactCONSTANTg
	local activateAutoReverse=activateAutoReverseG

	if (nearestFrontObstacleRange> losRadius) then nearestFrontObstacleRange = 999 end --if no obstacle infront of unit then set nearest obstacle as far as LOS to prevent infinite velocity.
	local newUnitAngleDerived= GetNewAngle(unitDirection, wTarget, fTarget, wObstacle, fObstacleSum, normalizingFactor) --derive a new angle from calculation for move solution

	local velocity=unitSpeed
	local maximumVelocity = (nearestFrontObstacleRange- safetyDistanceCONSTANT)/timeToContactCONSTANT --calculate minimum velocity for collision in the next "timeToContact" second.
	activateAutoReverse=activateAutoReverse*impatienceTrigger
	if (velocity >= maximumVelocity) and (activateAutoReverse==1) then velocity = -unitSpeed	end --set to reverse if impact is certain

	if (turnOnEcho == 1) then 
		Spring.Echo("maximumVelocity(SendCommand)" .. maximumVelocity) 
		Spring.Echo("activateAutoReverse(SendCommand)" .. activateAutoReverse)
	end
	
	local newX, newZ= ConvertToXZ(thisUnitID, newUnitAngleDerived,velocity) --convert angle into coordinate form
	return newX, newZ
end

function Round(num) --Reference: http://lua-users.org/wiki/SimpleRound
	under = math.floor(num)
	upper = math.floor(num) + 1
	underV = -(under - num)
	upperV = upper - num
	if (upperV > underV) then
		return under
	else
		return upper
	end
end
---------------------------------Level3
---------------------------------Level4 (low than low-level function)
-- debugging method, used to quickly remove nil
function dNil(x)
	if x==nil then
		x=-1
	end
	return x
end

function distance(x1,z1,x2,z2)
  local dis = math.sqrt((x1-x2)*(x1-x2)+(z1-z2)*(z1-z2))
  return dis
end

--get enemy angular size with respect to unit's perspective
function GetUnitSubtendedAngle (unitIDmain, unitID2)
	local unitSize2 =32 --a commander size for an unidentified enemy unit
	local unitDefID2= spGetUnitDefID(unitID2)
	local unitDef2= UnitDefs[unitDefID2]
	if (unitDef2~=nil) then	unitSize2 = unitDef2.xsize*8 --8 unitDistance per each square times unitDef's square, a correct size for an identified unit
	end

	local unitDefID= spGetUnitDefID(unitIDmain)
	local unitDef= UnitDefs[unitDefID]
	local unitSize = unitDef.xsize*8 --8 is the actual Distance per square
	local separationDistance = 0
	if (unitID2~=nil) then separationDistance = spGetUnitSeparation (unitIDmain, unitID2) --actual separation distance
	else separationDistance = GetUnitLOSRadius(unitIDmain) --as far as unit's reported LOSradius
	end

	local unit2SubtendedAngle = math.atan((unitSize + unitSize2)/separationDistance) --convert size and distance into radian (angle)
	return unit2SubtendedAngle --return angular size
end

--calculate enemy's wavefunction
function GetRiWiDi (unitDirection, relativeAngle, subtendedAngle, separationDistance, safetyMarginCONSTANT, smCONSTANT, distanceCONSTANT, obsCONSTANT)
	local differenceInAngle = unitDirection-relativeAngle
	local rI = (differenceInAngle/ subtendedAngle)*math.exp(1- math.abs(differenceInAngle/subtendedAngle))
	local hI = windowingFuncMultG/ (math.cos(2*subtendedAngle) - math.cos(2*subtendedAngle+ safetyMarginCONSTANT))
	local wI = obsCONSTANT* (math.tanh(hI- (math.cos(differenceInAngle) -math.cos(2*subtendedAngle +smCONSTANT)))+1) --graph with limiting window
	local dI = math.exp(-1*separationDistance/distanceCONSTANT) --distance multiplier
	return rI, wI, dI
end
--calculate wavefunction's slope
function GetFObstacleSlope (fObstacle2, fObstacle, unitDirection2, unitDirection)
	local fObstacleSlope= (fObstacle2 -fObstacle)/(unitDirection2-unitDirection)
	return fObstacleSlope
end
--sum the wavefunction from all enemy units
function DoAllSummation (wi, fObstacle, fObstacleSlope, di,wTotal, unitDirection, unitSeparation, relativeAngle, dSum, fObstacleSum, dFobstacle, nearestFrontObstacleRange)
	--sum all wavefunction variable, send and return summation variable
	wTotal, dSum, fObstacleSum, dFobstacle=SumRiWiDiCalculation (wi, fObstacle, fObstacleSlope, di,wTotal, dSum, fObstacleSum, dFobstacle)
	--detect any obstacle 60 degrees (pi/6) to the side of unit, set as nearest obstacle unit (prevent head on collision)
	if (unitSeparation< nearestFrontObstacleRange) and math.abs(unitDirection- relativeAngle)< (fleeingAngleG) then
		nearestFrontObstacleRange = unitSeparation end

	return wTotal, dSum, fObstacleSum, dFobstacle, nearestFrontObstacleRange --return summation variable
end
--receive global constant and distribute locally
function ConstantInitialize(fTargetSlope, dFobstacle, dSum, fTarget, fObstacleSum, wTotal)
	local cCONSTANT1 			=  cCONSTANT1g
	local cCONSTANT2			= cCONSTANT2g
	local gammaCONSTANT1and2
	local gammaCONSTANT2and1	= gammaCONSTANT2and1g
	local alphaCONSTANT1		= alphaCONSTANT1g
	local alphaCONSTANT2 --always between 1 and 0

	--calculate "gammaCONSTANT1and2, alphaCONSTANT2, and alphaCONSTANT1"
	local pTarget= Sgn(fTargetSlope)*math.exp(cCONSTANT1*math.abs(fTarget))
	local pObstacle = Sgn(dFobstacle)*math.exp(cCONSTANT1*math.abs(fObstacleSum))*wTotal
	gammaCONSTANT1and2 = math.exp(-1*cCONSTANT2*pTarget*pObstacle)/math.exp(cCONSTANT2)
	alphaCONSTANT2 = math.tanh(dSum)
	alphaCONSTANT1 = alphaCONSTANT1g*(1-alphaCONSTANT2)
	return alphaCONSTANT1, alphaCONSTANT2, gammaCONSTANT1and2, gammaCONSTANT2and1 --return constant for immediate use
end
--
function GetNewAngle (unitDirection, wTarget, fTarget, wObstacle, fObstacleSum, normalizingFactor)
	fObstacleSum = fObstacleSum*normalizingFactor --downscale value depend on the entire graph's maximum
	local unitAngleDerived= math.abs(wTarget)*fTarget + math.abs(wObstacle)*fObstacleSum + (noiseAngleG)*(GaussianNoise()*2-1) --add wavefunction 
	if math.abs(unitAngleDerived) > maximumTurnAngleG then --to prevent excess in avoidance causing overflow in angle changes (maximum angle should be pi, but useful angle should be pi/2 eg: 90 degree)
		--Spring.Echo("Dynamic Avoidance warning: total angle changes excess")
		unitAngleDerived = Sgn(unitAngleDerived)*maximumTurnAngleG end
	local newUnitAngleDerived= unitDirection +unitAngleDerived --add derived angle into current unit direction plus some noise
	if (turnOnEcho == 1) then 
		Spring.Echo("fTarget (getNewAngle)" .. fTarget)
		Spring.Echo("fObstacleSum (getNewAngle)" ..fObstacleSum)
		Spring.Echo("unitAngleDerived (getNewAngle)" ..unitAngleDerived)
		Spring.Echo("unitAngleDerived(GetNewAngle) " .. unitAngleDerived) 
		Spring.Echo("newUnitAngleDerived(GetNewAngle) " .. newUnitAngleDerived)
	end
	return newUnitAngleDerived --sent out derived angle
end

function ConvertToXZ(thisUnitID, newUnitAngleDerived, velocity)
	--localize global constant
	local velocityAddingCONSTANT=velocityAddingCONSTANTg
	local velocityScalingCONSTANT=velocityScalingCONSTANTg
	--
	local x,_,z = spGetUnitPosition(thisUnitID)
	local distanceToTravelInSecond=velocity*velocityScalingCONSTANT+velocityAddingCONSTANT --add multiplier
	local newX = distanceToTravelInSecond*math.cos(newUnitAngleDerived) + x
	local newZ = distanceToTravelInSecond*math.sin(newUnitAngleDerived) + z
	
	if (turnOnEcho == 1) then
		Spring.Echo("x(ConvertToXZ) " .. x)
		Spring.Echo("z(ConvertToXZ) " .. z)
	end
	return newX, newZ
end
---------------------------------Level4
---------------------------------Level5
function SumRiWiDiCalculation (wi, fObstacle, fObstacleSlope, di, wTotal, dSum, fObstacleSum, dFobstacle)
	wTotal = wTotal +wi
	fObstacleSum= fObstacleSum +fObstacle
	dFobstacle= dFobstacle + fObstacleSlope
	--Spring.Echo(dFobstacle)
	dSum= dSum +di
	return wTotal, dSum, fObstacleSum, dFobstacle
end

--Gaussian noise, Box-Muller method
--from http://www.dspguru.com/dsp/howtos/how-to-generate-white-gaussian-noise
--output value from -1 to +1 with bigger chance of getting 0
function GaussianNoise()
	local v1
	local v2
	local s = 0
	repeat
		local u1=math.random()   --U1=[0,1]
		local u2=math.random()  --U2=[0,1]
		v1= 2 * u1 -1   -- V1=[-1,1]
		v2=2 * u2 - 1  -- V2=[-1,1]
		s=v1 * v1 + v2 * v2
	until (s<1)

	local x=math.sqrt(-2 * math.log(s) / s) * v1
	return x
end

function Sgn(x)
	local y= x/(math.abs(x))
	return y
end
---------------------------------Level5

--REFERENCE:
--1
--Non-linear dynamical system approach to behavior modeling --Siome Goldenstein, Edward Large, Dimitris Metaxas
--Dynamic autonomous agents: game applications -- Siome Goldenstein, Edward Large, Dimitris Metaxas
--2
--"unit_tactical_ai.lua" -ZeroK gadget by Google Frog
--3
--"Initial Queue" widget, "Allows you to queue buildings before game start" (unit_initial_queue.lua), author = "Niobium",
--4
--"unit_smart_nanos.lua" widget, "Enables auto reclaim & repair for idle nano turrets , author = Owen Martindell
--5
--"Chili Crude Player List", "Player List",, author=CarRepairer      
--6
--Gaussian noise, Box-Muller method, http://www.dspguru.com/dsp/howtos/how-to-generate-white-gaussian-noise
--http://springrts.com/wiki/Lua_Scripting