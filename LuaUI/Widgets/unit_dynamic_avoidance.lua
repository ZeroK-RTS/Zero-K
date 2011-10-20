local versionName = "v1.13"
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
    name      = "Dynamic Avoidance System ",
    desc      = versionName .. "Dynamic Collision Avoidance behaviour for all ground units",
    author    = "msafwan (coding)",
    date      = "Oct 20, 2011",
    license   = "GNU GPL, v2 or later",
    layer     = 0,
    enabled   = true  --  loaded by default?
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
local spGetCommandQueue	= Spring.GetCommandQueue
local spGetUnitIsDead 	= Spring.GetUnitIsDead
local spGetGameSeconds	= Spring.GetGameSeconds
local CMD_STOP			= CMD.STOP
local CMD_INSERT		= CMD.INSERT
local CMD_REMOVE		= CMD.REMOVE
local CMD_MOVE			= CMD.MOVE
local CMD_OPT_INTERNAL	= CMD.OPT_INTERNAL
--------------------------------------------------------------------------------
-- Constant:
-- Switches:
local turnOnEcho =0 --Echo out all numbers for debugging the system
local activateAutoReverseG=1 --set to auto-reverse when unit is about to collide with an enemy
local activateImpatienceG=1 --auto disable auto-reverse after 6 continuous auto-avoidance (3 second). In case the unit stuck

-- Graph constant:
local distanceCONSTANTunitG = 410 --increase obstacle awareness over distance. (default = 410 meter, ie: ZK's stardust range)
local safetyMarginCONSTANTunitG = 0.8 --obstacle graph offset (a "safety margin" constant). Add/substract obstacle effect (default = 0.8 radian)
local smCONSTANTunitG		= 0.8  -- obstacle graph offset (a "safety margin" constant).  Add/substract obstacle effect (default = not stated, perhaps 0.8 radian)
local aCONSTANTg			= 0.01 -- attractor graph; scale the attractor's strenght. Less equal to additional avoidance (default = 0.2 amplitude)

-- Obstacle/Target competetive interaction constant:
local cCONSTANT1g 			= 2 --attractor constant; effect the behaviour. ie: the selection between 4 behaviour state. (default = 2 multiplier)
local cCONSTANT2g			= 2 --repulsor constant; effect behaviour. (default = 2 multiplier)
local gammaCONSTANT2and1g	= 0.05 -- balancing constant; effect behaviour. . (default = 0.05 multiplier)
local alphaCONSTANT1g		= 0.4 -- balancing constant; effect behaviour. (default = 0.4 multiplier)

-- Distance or velocity constant:
local timeToContactCONSTANTg=0.5 --the time scale; for time to collision calculation (default = 0.5 second).
local safetyDistanceCONSTANTg=205 --range toward an obstacle before unit reverse (default = 205 meter, ie: half of ZK's stardust range) eg:80 is a size of BA's solar
local extraLOSRadiusCONSTANTg=200 --add additional distance for unit awareness over the default LOS. (default = +200 meter radius, ie: radar blip)
local velocityScalingCONSTANTg=1 --decrease/increase command lenght. (default= 1 multiplier)
local velocityAddingCONSTANTg=10 --minimum speed. Add or remove minimum command lenght (default = 0 meter/second)

--Move Command constant:
local halfTargetBoxSize = {400, 800} --the distance from a target or move-order where widget should ignore (default: cloak and consc = 400 ie:800x800 box, ground unit =800)

--Angle constant:
local noiseAngleG =math.pi/16 --(default is pie/16)
local collisionAngleG=math.pi/8
local fleeingAngleG=math.pi/6

--------------------------------------------------------------------------------
--Variables:
local unitInMotionG={} --store unitID
local skippingTimerG={0,0}
local commandIndexTableG= {} --store latest widget command for comparison
local myTeamID=-1
local surroundingOfActiveUnitG={} --store value for transfer between function. Store obstacle separation, los, and ect.
local cycleG=1 --first execute "GetPreliminarySeparation()"
--------------------------------------------------------------------------------
--Methods:
---------------------------------Level 0
function widget:Initialize()
	local _, _, spec = Spring.GetPlayerInfo(Spring.GetMyPlayerID())
	if spec then widgetHandler:RemoveWidget() return false end
	myTeamID= spGetMyTeamID()
	if (turnOnEcho == 1) then Spring.Echo("myTeamID(Initialize)" .. myTeamID) end
end

function widget:TeamDied(teamID)
	if teamID==myTeamID then widgetHandler:RemoveWidget() end
end

--execute different function at different timescale
function widget:Update()
	-------retrieve global table, localize global table
	commandIndexTable=commandIndexTableG
	unitInMotion = unitInMotionG
	surroundingOfActiveUnit=surroundingOfActiveUnitG
	cycle = cycleG
	skippingTimer = skippingTimerG
	-----
	local now=spGetGameSeconds()
	if (now >=1.0+skippingTimer[1]) then --if now is 1 second after last update then do "RefreshUnitList()"
		if (turnOnEcho == 1) then Spring.Echo("-----------------------RefreshUnitList") end
		unitInMotion=RefreshUnitList() --add relevant unit to unitlist/unitInMotion
		skippingTimer[1]=spGetGameSeconds()
		if (turnOnEcho == 1) then Spring.Echo("-----------------------RefreshUnitList") end
	end
	
	if (now >=0.37+skippingTimer[2] and cycle==1) then --if now is 0.37 second after last update then do "GetPreliminarySeparation()"
		if (turnOnEcho == 1) then Spring.Echo("-----------------------GetPreliminarySeparation") end
		surroundingOfActiveUnit,commandIndexTable=GetPreliminarySeparation(unitInMotion,commandIndexTable)
		cycle=2 --send next cycle to "DoCalculation()" function
		if (turnOnEcho == 1) then Spring.Echo("-----------------------GetPreliminarySeparation") end
	end
	if (now >=0.45+skippingTimer[2] and cycle==2) then --if now is 0.45 second after last update then do "DoCalculation()"
		if (turnOnEcho == 1) then Spring.Echo("-----------------------DoCalculation") end
		commandIndexTable=DoCalculation (surroundingOfActiveUnit,commandIndexTable)
		cycle=1 --send next cycle back to "GetPreliminarySeparation()" function
		skippingTimer[2]=spGetGameSeconds()
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
	-----
end
---------------------------------Level 0 Top level
---------------------------------Level1 Lower level
-- return a refreshed unit list, else return nil
function RefreshUnitList()
	local allMyUnits = spGetTeamUnits(myTeamID)
	local arrayIndex=1
	local relevantUnit={}
	for _, unitID in ipairs(allMyUnits) do
		if unitID~=nil then --skip end of the table
			local unitDefID = spGetUnitDefID(unitID)
			local unitDef = UnitDefs[unitDefID]
			if (turnOnEcho == 1) then --for debugging
				Spring.Echo("unitID(RefreshUnitList)" .. unitID)
				Spring.Echo("unitDef[humanName](RefreshUnitList)" .. unitDef["humanName"])
				Spring.Echo("((unitDef[builder] or unitDef[canCloak]) and unitDef[speed]>0)(RefreshUnitList):")
				Spring.Echo((unitDef["builder"] or unitDef["canCloak"]) and unitDef["speed"]>0)
			end
			local unitSpeed =unitDef["speed"]
			if (unitSpeed>0) then 
				if (unitDef["builder"] or unitDef["canCloak"]) then --include only cloakies and constructor
					arrayIndex=arrayIndex+1
					relevantUnit[arrayIndex]={unitID, 1, unitSpeed}
				elseif not unitDef["canFly"] then
					arrayIndex=arrayIndex+1
					relevantUnit[arrayIndex]={unitID, 2, unitSpeed}
				end
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
	return relevantUnit
end

-- detect initial enemy separation to detect "fleeing enemy"  later
function GetPreliminarySeparation(unitMotion,commandIndexTable)
	local surroundingOfActiveUnit={}
	if unitInMotion[1]~=nil then --don't execute if no unit present
		local arrayIndex=1
		for i=2,unitInMotion[1], 1 do --array index 1 contain the array's lenght, start from 2
			local unitID= unitInMotion[i][1] --get unitID for commandqueue
			if spGetUnitIsDead(unitID)==false then --prevent execution if unit died during transit
				local cQueue = spGetCommandQueue(unitID)
				if cQueue~=nil then --prevent
				if cQueue[1]~=nil then --prevent idle unit from executing the system
					if cQueue[1].id==CMD_MOVE and #cQueue>=2 then  --prevent STOP command from short circuiting the system
					if (turnOnEcho == 1) then Spring.Echo(cQueue[2].id) end --for debugging
					if cQueue[2].id~=false then --prevent a spontaneous enemy engagement from short circuiting the system
						local targetCoordinate, commandIndexTable, newCommand=IdentifyTargetOnCommandQueue(cQueue, unitID, commandIndexTable) --check old or new command
						local boxSizeTrigger= unitInMotion[i][2]
						local reachedTarget = TargetBoxReached(targetCoordinate, unitID, boxSizeTrigger) --check if widget should ignore command
						local losRadius	= GetUnitLOSRadius(unitID) --get LOS
						local surroundingUnits	= GetAllUnitsInRectangle(unitID, losRadius) --catalogue enemy
						
						if reachedTarget then commandIndexTable[unitID]=nil end --reclaim commandIndex memory
						
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
						
						if surroundingUnits[1]~=nil and not reachedTarget then  --execute when enemy exist and target not reached yet
							local unitSSeparation=CatalogueMovingObject(surroundingUnits, unitID) --detect initial enemy separation
							arrayIndex=arrayIndex+1
							local unitSpeed = unitInMotion[i][3]
							local impatienceTrigger,commandIndexTable = GetImpatience(newCommand,unitID, commandIndexTable)
							surroundingOfActiveUnit[arrayIndex]={unitID, unitSSeparation, targetCoordinate, losRadius, cQueue, newCommand, unitSpeed,impatienceTrigger} --store result for next execution
							if (turnOnEcho == 1) then
								Spring.Echo("unitsSeparation(GetPreliminarySeparation):")
								Spring.Echo(unitsSeparation)
							end
						end
					end
					end
				end
				end
			end
		end
		if arrayIndex>1 then surroundingOfActiveUnit[1]=arrayIndex 
		else surroundingOfActiveUnit[1]=nil end
	end
	return surroundingOfActiveUnit, commandIndexTable --send separation result away
end

--perform the actual collision avoidance calculation and send the appropriate command to unit
function DoCalculation (surroundingOfActiveUnit,commandIndexTable)
	if surroundingOfActiveUnit[1]~=nil then --if no stored content then this mean there's no relevant unit
		for i=2,surroundingOfActiveUnit[1], 1 do --index 1 is for array's lenght
			local unitID=surroundingOfActiveUnit[i][1]
			if spGetUnitIsDead(unitID)==false then --prevent unit death from short circuiting the system
				local unitSSeparation=surroundingOfActiveUnit[i][2]
				local targetCoordinate=surroundingOfActiveUnit[i][3]
				local losRadius=surroundingOfActiveUnit[i][4]
				local cQueue=surroundingOfActiveUnit[i][5]
				local newCommand=surroundingOfActiveUnit[i][6]
				
				--do sync test. Ensure command not changed during last delay
				local cQueueSyncTest = spGetCommandQueue(unitID)
				if cQueue[1].params[1]~=cQueueSyncTest[1].params[1] and cQueue[1].params[3]~=cQueueSyncTest[1].params[3] then 
					newCommand=true
					cQueue=cQueueSyncTest
				end
				
				local unitSpeed= surroundingOfActiveUnit[i][7]
				local impatienceTrigger= surroundingOfActiveUnit[i][8]
				local newSurroundingUnits	= GetAllUnitsInRectangle(unitID, losRadius) --get new unit separation for comparison
				local newX, newZ = AvoidanceCalculator(unitID, targetCoordinate,losRadius,newSurroundingUnits, unitSSeparation, unitSpeed, impatienceTrigger) --calculate move solution
				local newY=spGetGroundHeight(newX,newZ)
				if (turnOnEcho == 1) then
					Spring.Echo("newX(Update) " .. newX)
					Spring.Echo("newZ(Update) " .. newZ)
				end
				commandIndexTable= InsertCommandQueue(cQueue, unitID, newX, newY, newZ, commandIndexTable, newCommand) --send move solution to unit
			end
		end
	end
	return commandIndexTable
end
---------------------------------Level1
---------------------------------Level2 (level 1's call-in)
--check if widget's command or user's command
function IdentifyTargetOnCommandQueue(cQueue, unitID,commandIndexTable)
	local targetCoordinate = {}
	local newCommand=true -- immediately assume user's command
	if commandIndexTable[unitID]==nil then --memory was empty, so fill it with zeros
		commandIndexTable[unitID]={widgetX=0, widgetZ=0 ,backupTargetX=0, backupTargetY=0, backupTargetZ=0, patienceIndexA=0}
	else
		newCommand= (cQueue[1].params[1]~= commandIndexTable[unitID]["widgetX"] and cQueue[1].params[3]~=commandIndexTable[unitID]["widgetZ"])--check current command with memory
		if (turnOnEcho == 1) then --debugging
			Spring.Echo("unitID(GetPreliminarySeparation)" .. unitID)
			Spring.Echo("commandIndexTable[unitID][widgetX](IdentifyTargetOnCommandQueue):" .. commandIndexTable[unitID]["widgetX"])
			Spring.Echo("commandIndexTable[unitID][widgetZ](IdentifyTargetOnCommandQueue):" .. commandIndexTable[unitID]["widgetZ"])
			Spring.Echo("newCommand(IdentifyTargetOnCommandQueue):")
			Spring.Echo(newCommand)
			Spring.Echo("cQueue[1].params[1](IdentifyTargetOnCommandQueue):" .. cQueue[1].params[1])
			Spring.Echo("cQueue[1].params[3](IdentifyTargetOnCommandQueue):" .. cQueue[1].params[3])
			if cQueue[2]~=nil then
				Spring.Echo("cQueue[2].params[1](IdentifyTargetOnCommandQueue):")
				Spring.Echo(cQueue[2].params[1])
				Spring.Echo("cQueue[2].params[3](IdentifyTargetOnCommandQueue):")
				Spring.Echo(cQueue[2].params[3])
			end
		end
	end
	if newCommand then	--user or widget command?
		targetCoordinate={cQueue[1].params[1], cQueue[1].params[2],cQueue[1].params[3]} --use first queue as target
		commandIndexTable[unitID]["backupTargetX"]=cQueue[1].params[1] --backup the target
		commandIndexTable[unitID]["backupTargetY"]=cQueue[1].params[2]
		commandIndexTable[unitID]["backupTargetZ"]=cQueue[1].params[3]
		commandIndexTable[unitID]["patienceIndexA"]=0
	elseif cQueue[2].params[1]~=nil and cQueue[2].params[3]~=nil then
		targetCoordinate={cQueue[2].params[1], cQueue[2].params[2],cQueue[2].params[3]} --or use second queue for target
	else
		--if for some reason cQueue has no content then use these backup value:
		targetCoordinate={commandIndexTable[unitID]["backupTargetX"], commandIndexTable[unitID]["backupTargetY"],commandIndexTable[unitID]["backupTargetZ"]} --if the second queue isappear then use the backup
	end
	return targetCoordinate, commandIndexTable, newCommand --return target coordinate
end

--ignore command set on this box
function TargetBoxReached (targetCoordinate, unitID, boxSizeTrigger)
	local currentX,_,currentZ = spGetUnitPosition(unitID)
	local targetX = targetCoordinate[1]
	local targetZ =targetCoordinate[3]
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
	if unitDef~=nil then
		losRadius= unitDef.losRadius*32 --for some reason it was times 32
	end
	return (losRadius + extraLOSRadiusCONSTANTg)
end

--return a table of surrounding enemy
function GetAllUnitsInRectangle(unitID, losRadius)
	local x,y,z = spGetUnitPosition(unitID)
	if (turnOnEcho == 1) then
		Spring.Echo("spGetUnitIsDead(unitID)==false (GetAllUnitsInRectangle):")
		Spring.Echo(spGetUnitIsDead(unitID)==false)
	end
	local unitsInRectangle = spGetUnitsInRectangle(x-losRadius, z-losRadius, x+losRadius, z+losRadius)

	local relevantUnit={}
	local arrayIndex=1
	for _, rectangleUnitID in ipairs(unitsInRectangle) do
		local isAlly= spIsUnitAllied(rectangleUnitID)
		if (rectangleUnitID ~= unitID) and not isAlly then--filter out ally units and self
			arrayIndex=arrayIndex+1
			relevantUnit[arrayIndex]=rectangleUnitID
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
function CatalogueMovingObject(surroundingUnits, unitID)
	local unitsSeparation={}
	if (surroundingUnits[1]~=nil) then --don't catalogue anything if no enemy exist
		for i=2,surroundingUnits[1],1 do
			local unitRectangleID=surroundingUnits[i]
			if (unitRectangleID ~= nil) then
				local relativeAngle 	= GetUnitRelativeAngle (unitID, unitRectangleID)
				local unitDirection		= GetUnitDirection(unitID)
				local unitSeparation	= spGetUnitSeparation (unitID, unitRectangleID)
				if math.abs(unitDirection- relativeAngle)< (collisionAngleG) then --only units within 45 degree to the side is catalogued with exact value
					unitsSeparation[unitRectangleID]=unitSeparation
				else
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

function AvoidanceCalculator(unitID, targetCoordinate, losRadius, surroundingUnits, unitsSeparation, unitSpeed, impatienceTrigger)
	if (targetCoordinate ~= nil) and (unitID~=nil) then --prevent idle/non-existent/ unit with invalid command from using collision avoidance
		local aCONSTANT 			= aCONSTANTg --attractor constant (amplitude multiplier)
		local targetAngle			= GetTargetAngleWithRespectToUnit(unitID, targetCoordinate) --get target angle
		local unitDirection			= GetUnitDirection(unitID) --get unit direction
		local fTarget				= GetFtarget (aCONSTANT, targetAngle, unitDirection)
		local fTargetSlope			= GetFtargetSlope (aCONSTANT, targetAngle, unitDirection, fTarget)
		local targetSubtendedAngle 	= GetTargetSubtendedAngle(unitID, targetCoordinate) --get target 'size' as viewed by the unit
		if (turnOnEcho == 1) then
			Spring.Echo("unitID(AvoidanceCalculator)" .. unitID)
			Spring.Echo("targetAngle(AvoidanceCalculator) " .. targetAngle)
			Spring.Echo("unitDirection(AvoidanceCalculator) " .. unitDirection)
			Spring.Echo("fTarget(AvoidanceCalculator) " .. fTarget)
			Spring.Echo("fTargetSlope(AvoidanceCalculator) " .. fTargetSlope)
			Spring.Echo("targetSubtendedAngle(AvoidanceCalculator) " .. targetSubtendedAngle)
		end
		local wTotal=0
		local fObstacleSum=0
		local dFobstacle=0
		local dSum=0
		local nearestFrontObstacleRange =999

		--count every enemy unit and sum its contribution to the obstacle/repulsor variable
		wTotal, dSum, fObstacleSum,dFobstacle,nearestFrontObstacleRange=SumAllUnitAroundUnitID (unitID, surroundingUnits, unitDirection, wTotal, dSum, fObstacleSum,dFobstacle,nearestFrontObstacleRange, unitsSeparation, impatienceTrigger)
		--calculate appropriate behaviour based on the constant and above summation value
		local wTarget, wObstacle = CheckWhichFixedPointIsStable (fTargetSlope, dFobstacle, dSum, fTarget, fObstacleSum, wTotal)
		--convert an angular command into a coordinate command
		local newX, newZ= SendCommand(unitID, wTarget, wObstacle, fTarget, fObstacleSum, unitDirection, nearestFrontObstacleRange, losRadius, unitSpeed, impatienceTrigger)
		if (turnOnEcho == 1) then
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
	--if not newCommand then spGiveOrderToUnit(unitID, CMD_REMOVE, {cQueue[1].tag}, {} ) end --delete old command
	-- if not newCommand then spGiveOrderToUnit(unitID, CMD_MOVE, {cQueue[1].params[1],cQueue[1].params[2],cQueue[1].params[3]}, {"ctrl","shift"} ) end --delete old command
	-- spGiveOrderToUnit(unitID, CMD_INSERT, {0, CMD_MOVE, CMD_OPT_INTERNAL, newX, newY, newZ}, {"alt"} ) --insert new command
	
	spGiveOrderToUnit(unitID, CMD_MOVE, {newX, newY, newZ}, {} )
	local arrayIndex=1
	if not newCommand then arrayIndex=2 end
	for b = arrayIndex, #cQueue,1 do
		spGiveOrderToUnit(unitID, cQueue[b].id, cQueue[b].params, {"shift"})
	end
	
	commandIndexTable[unitID]["widgetX"]=newX --update the memory table
	commandIndexTable[unitID]["widgetZ"]=newZ
	if (turnOnEcho == 1) then
		Spring.Echo("unitID(AvoidanceCalculator)" .. unitID)
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

function GetUnitRelativeAngle (unitIDmain, unitID2)
	local x,y,z = spGetUnitPosition(unitIDmain)
	local rX, rY, rZ= spGetUnitPosition(unitID2)
	local cX, cY, cZ = rX-x, rY-y, rZ-z --in case unit destroyed
	local relativeAngle = math.atan2 (cZ, cX)
	return relativeAngle
end

function GetTargetAngleWithRespectToUnit(unitID, targetCoordinate)
	local x,y,z = spGetUnitPosition(unitID)
	local tx,ty,tz = targetCoordinate[1],targetCoordinate[2],targetCoordinate[3]
	local dX, dY, dZ = tx- x, ty-y, tz-z 
	local targetAngle = math.atan2(dZ, dX)
	return targetAngle
end

function GetUnitDirection(unitID)
	local dx,dy,dz= spGetUnitDirection(unitID)
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
	local tx,ty,tz = targetCoordinate[1],targetCoordinate[2],targetCoordinate[3]
	local x,y,z = spGetUnitPosition(unitID)
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
	if (turnOnEcho == 1) then Spring.Echo("unitID(SumAllUnitAroundUnitID)" .. thisUnitID) end
	if (surroundingUnits[1]~=nil) then --don't execute if no enemy unit exist
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
				if unitSeparation <unitsSeparation[unitRectangleID] then --see if the enemy is maintaining distance
					local relativeAngle 	= GetUnitRelativeAngle (thisUnitID, unitRectangleID)
					local subtendedAngle	= GetUnitSubtendedAngle (thisUnitID, unitRectangleID)
					local unitDirection		= GetUnitDirection(thisUnitID)

					--get obstacle/ enemy/repulsor wave function
					if impatienceTrigger==0 then --zero means that unit is impatient
						distanceCONSTANT=distanceCONSTANT/2
					end
					local ri, wi, di = GetRiWiDi (unitDirection, relativeAngle, subtendedAngle, unitSeparation, safetyMarginCONSTANT, smCONSTANT, distanceCONSTANT)
					local fObstacle = ri*wi*di
					distanceCONSTANT=distanceCONSTANTunitG

					--get second obstacle/enemy/repulsor wave function to calculate slope
					local ri2, wi2, di2 = GetRiWiDi (unitDirection+0.05, relativeAngle, subtendedAngle, unitSeparation, safetyMarginCONSTANT, smCONSTANT, distanceCONSTANT)
					local fObstacle2 = ri2*wi2*di2

					--get repulsor wavefunction's slope
					local fObstacleSlope = GetFObstacleSlope(fObstacle2, fObstacle, unitDirection+0.05, unitDirection)

					--sum all repulsor's wavefunction from every enemy/obstacle within this loop
					wTotal, dSum, fObstacleSum,dFobstacle, nearestFrontObstacleRange= DoAllSummation (wi, fObstacle, fObstacleSlope, di,wTotal, unitDirection, unitSeparation, relativeAngle, dSum, fObstacleSum,dFobstacle, nearestFrontObstacleRange)
				end
			end
		end
	end
	return wTotal, dSum, fObstacleSum,dFobstacle, nearestFrontObstacleRange --return obstacle's calculation result
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

				--wTarget= math.sqrt((alphaCONSTANT2*(alphaCONSTANT1-gammaCONSTANT2and1))/(alphaCONSTANT1*alphaCONSTANT2-gammaCONSTANT1and2*gammaCONSTANT2and1))
				--wObstacle= math.sqrt((alphaCONSTANT1*(alphaCONSTANT2-gammaCONSTANT2and1))/(alphaCONSTANT1*alphaCONSTANT2-gammaCONSTANT1and2*gammaCONSTANT2and1))
						 if (turnOnEcho == 1) then  Spring.Echo("state 3") end
			end

			if (gammaCONSTANT1and2>0) and (gammaCONSTANT2and1>0) then
				--function from latest article. Set repulsor/attractor balance
				 wTarget= math.sqrt((alphaCONSTANT2*(alphaCONSTANT1-gammaCONSTANT1and2))/(alphaCONSTANT1*alphaCONSTANT2-gammaCONSTANT1and2*gammaCONSTANT2and1))
				 wObstacle= math.sqrt((alphaCONSTANT1*(alphaCONSTANT2-gammaCONSTANT2and1))/(alphaCONSTANT1*alphaCONSTANT2-gammaCONSTANT1and2*gammaCONSTANT2and1))

				--wTarget= math.sqrt((alphaCONSTANT2*(alphaCONSTANT1-gammaCONSTANT2and1))/(alphaCONSTANT1*alphaCONSTANT2-gammaCONSTANT1and2*gammaCONSTANT2and1))
				--wObstacle= math.sqrt((alphaCONSTANT1*(alphaCONSTANT2-gammaCONSTANT2and1))/(alphaCONSTANT1*alphaCONSTANT2-gammaCONSTANT1and2*gammaCONSTANT2and1))
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
function SendCommand(thisUnitID, wTarget, wObstacle, fTarget, fObstacleSum, unitDirection, nearestFrontObstacleRange, losRadius, unitSpeed, impatienceTrigger)
	local safetyDistanceCONSTANT=safetyDistanceCONSTANTg
	local timeToContactCONSTANT=timeToContactCONSTANTg
	local activateAutoReverse=activateAutoReverseG

	if (nearestFrontObstacleRange> losRadius) then nearestFrontObstacleRange = 999 end --if no obstacle infront of unit then set nearest obstacle as far as LOS to prevent infinite velocity.
	local newUnitAngleDerived= GetNewAngle(unitDirection, wTarget, fTarget, wObstacle, fObstacleSum) --derive a new angle from calculation for move solution

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
---------------------------------Level3
---------------------------------Level4 (low than low-level function)
-- debugging method, used to quickly remove nil
-- function dNil(x)
	-- if x==nil then
		-- x=0
	-- end
	-- return x
-- end

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
function GetRiWiDi (unitDirection, relativeAngle, subtendedAngle, separationDistance, safetyMarginCONSTANT, smCONSTANT, distanceCONSTANT)
	local differenceInAngle = unitDirection-relativeAngle
	local rI = (differenceInAngle/ subtendedAngle)*math.exp(1- math.abs(differenceInAngle/subtendedAngle))
	local hI = 4/ (math.cos(2*subtendedAngle) - math.cos(2*subtendedAngle+ safetyMarginCONSTANT))
	local wI = 0.5* (math.tanh(hI- (math.cos(differenceInAngle) -math.cos(2*subtendedAngle +smCONSTANT)))+1)
	local dI = math.exp(-1*separationDistance/distanceCONSTANT)
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
function GetNewAngle (unitDirection, wTarget, fTarget, wObstacle, fObstacleSum)
	local unitAngleDerived= math.abs(wTarget)*fTarget + math.abs(wObstacle)*fObstacleSum + (noiseAngleG)*GaussianNoise() --add both wavefunction plus some noise
	local newUnitAngleDerived= unitDirection +unitAngleDerived --add derived angle into current unit direction
	if (turnOnEcho == 1) then Spring.Echo("unitAngleDerived(GetNewAngle) " .. newUnitAngleDerived) end
	return newUnitAngleDerived --sent out derived angle
end

function ConvertToXZ(thisUnitID, newUnitAngleDerived, velocity)
	local velocityAddingCONSTANT=velocityAddingCONSTANTg --localize global constant
	local velocityScalingCONSTANT=velocityScalingCONSTANTg
	
	local x,_,z = spGetUnitPosition(thisUnitID)
	if (turnOnEcho == 1) then
		Spring.Echo("x(ConvertToXZ) " .. x)
		Spring.Echo("z(ConvertToXZ) " .. z)
	end
	local distanceToTravelInSecond=velocity*velocityScalingCONSTANT+velocityAddingCONSTANT --add multiplier
	local newX = distanceToTravelInSecond*math.cos(newUnitAngleDerived) + x
	local newZ = distanceToTravelInSecond*math.sin(newUnitAngleDerived) + z

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
function GaussianNoise()
	local v1
	local s = 0
	repeat
		local u1=math.random()   --U1=[0,1]
		local u2=math.random()  --U2=[0,1]
		v1= 2 * u1 -1   -- V1=[-1,1]
		local v2=2 * u2 - 1  -- V2=[-1,1]
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
--Gaussian noise, Box-Muller method, http://www.dspguru.com/dsp/howtos/how-to-generate-white-gaussian-noise
--http://springrts.com/wiki/Lua_Scripting