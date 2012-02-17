local versionName = "v2.00"
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
    desc      = versionName .. " Avoidance AI behaviour for constructor, cloakies, ground combat unit and gunships",
    author    = "msafwan",
    date      = "Feb 18, 2012",
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
local spGetUnitWeaponState = Spring.GetUnitWeaponState
local spGetUnitShieldState = Spring.GetUnitShieldState
local spGetUnitIsStunned = Spring.GetUnitIsStunned
local spGetGameFrame = Spring.GetGameFrame
local spSendCommands = Spring.SendCommands
local CMD_STOP			= CMD.STOP
local CMD_ATTACK 		= CMD.ATTACK
local CMD_GUARD			= CMD.GUARD
local CMD_INSERT		= CMD.INSERT
local CMD_REMOVE		= CMD.REMOVE
local CMD_MOVE			= CMD.MOVE
local CMD_OPT_INTERNAL	= CMD.OPT_INTERNAL
local CMD_OPT_SHIFT		= CMD.OPT_SHIFT
--------------------------------------------------------------------------------
-- Constant:
-- Switches:
local turnOnEcho =0 --Echo out all numbers for debugging the system (default = 0)
local activateAutoReverseG=1 --activate a one-time-reverse-command when unit is about to collide with an enemy (default = 0)
local activateImpatienceG=0 --auto disable auto-reverse & half the 'distanceCONSTANT' after 6 continuous auto-avoidance (3 second). In case the unit stuck (default = 0)

-- Graph constant:
local distanceCONSTANTunitG = 410 --increase obstacle awareness over distance. (default = 410 meter, ie: ZK's stardust range)
local safetyMarginCONSTANTunitG = 0.0 --obstacle graph offset (a "safety margin" constant). Offset the obstacle effect: to prefer avoid torward more left or right (default = 0.0 radian)
local smCONSTANTunitG		= 0.0  -- obstacle graph offset (a "safety margin" constant).  Offset the obstacle effect: to prefer avoid torward more left or right (default = 0.0 radian)
local aCONSTANTg			= {math.pi/10 , math.pi/4} -- attractor graph; scale the attractor's strenght. Less equal to a lesser turning toward attraction(default = math.pi/10 radian (MOVE),math.pi/4 (GUARD & ATTACK)) (max value: math.pi/2).
local obsCONSTANTg			= {math.pi/10, math.pi/4} -- obstacle graph; scale the obstacle's strenght. Less equal to a lesser turning away from avoidance(default = math.pi/10 radian (MOVE), math.pi/4 (GUARD & ATTACK)). 
--aCONSTANTg Note: math.pi/4 is equal to about 45 degrees turning (left or right). aCONSTANTg is the maximum amount of turning toward target and the actual turning depend on unit's direction. Activated by 'graphCONSTANTtrigger[1]'
--an antagonist to aCONSTANg (obsCONSTANTg or obstacle graph) also use math.pi/4 (45 degree left or right) but actual maximum value varies depend on number of enemy, but already normalized. Activated by 'graphCONSTANTtrigger[2]'
local windowingFuncMultG = 1 --? (default = 1 multiplier)
local normalizeObsGraphG = false --// if 'true': normalize turn angle to a maximum of "obsCONSTANTg", if 'false': allow turn angle to grow as big as it can (depend on number of enemy, limited by "maximumTurnAngleG").

-- Obstacle/Target competetive interaction constant:
local cCONSTANT1g 			= {0.01,1} --attractor constant; effect the behaviour. ie: selection between 4 behaviour state. (default = 0.01x (All), 1x (Cloakies)) (behaviour:(MAINTAIN USER's COMMAND)|(IGNORE USER's COMMAND))
local cCONSTANT2g			= {0.01,1} --repulsor constant; effect behaviour. (default = 0.01x (All), 1x (Cloakies)) (behaviour:(MAINTAIN USER's COMMAND)|(IGNORE USER's COMMAND))
local gammaCONSTANT2and1g	= {0.05,0.05} -- balancing constant; effect behaviour. . (default = 0.05x (All), 0.05x (Cloakies))
local alphaCONSTANT1g		= {500,0.4} -- balancing constant; effect behaviour. (default = 500x (All), 0.4x (Cloakies)) (behaviour:(MAINTAIN USER's COMMAND)|(IGNORE USER's COMMAND))

--Move Command constant:
local halfTargetBoxSize = {400, 0, 185, 50} --the distance from a target which widget should de-activate (default: MOVE = 400m (ie:800x800m box/2x constructor range), RECLAIM/RESSURECT=0 (always flee), REPAIR=185 (1x constructor's range), GUARD = 50 (arbitrary))
local cMD_DummyG = 248 --a fake command ID to flag an idle unit for pure avoidance. (arbitrary value, change if conflict with existing command)
local dummyIDg = "248" --fake id for Lua Message to check lag (prevent processing of latest Command queue if server haven't process previous command yet; to avoid messy queue) (arbitrary value, change if conflict with other widget)

--Angle constant:
--http://en.wikipedia.org/wiki/File:Degree-Radian_Conversion.svg
local noiseAngleG =math.pi/36 --(default is pi/36 rad); add random angle (range from 0 to +-math.pi/36) to the new angle. To prevent a rare state that contribute to unit going straight toward enemy
local collisionAngleG=math.pi/12 --(default is pi/6 rad) a "field of vision" (range from 0 to +-math.pi/6) where auto-reverse will activate 
local fleeingAngleG=math.pi/4 --(default is pi/4 rad) angle of enemy (range from 0 to +-math.pi/4) where fleeing enemy is considered (to de-activate avoidance to perform chase). Set to 0 to de-activate.
local maximumTurnAngleG = math.pi --safety measure. Prevent overturn (eg: 360+xx degree turn)
--pi is 180 degrees

--Update constant:
local doCalculation_then_gps_delayG = 0.25 --elapsed second (Wait) before gathering preliminary data for issuing command (default: 0.25 second)
local gps_then_DoCalculation_delayG = 0.25 --elapsed second (Wait) before issuing new command (default: 0.25 second)

-- Distance or velocity constant:
local timeToContactCONSTANTg= doCalculation_then_gps_delayG + gps_then_DoCalculation_delayG --time scale for move command; to calculate collision calculation & command lenght (default = 0.5 second). Will change based on user's Ping
local safetyDistanceCONSTANTg=205 --range toward an obstacle before unit auto-reverse (default = 205 meter, ie: half of ZK's stardust range) reference:80 is a size of BA's solar
local extraLOSRadiusCONSTANTg=205 --add additional distance for unit awareness over the default LOS. (default = +200 meter radius, ie: to 'see' radar blip)
local velocityScalingCONSTANTg=1 --scale command lenght. (default= 1 multiplier)
local velocityAddingCONSTANTg=10 --add or remove command lenght (default = 0 meter/second)

--Engine based wreckID correction constant:
local wreckageID_offset_multiplier = 0 --for Spring 0.82 this is 1500
local wreckageID_offset_initial = 32000	--for Spring 0.82 this is 4500
--curModID = upper(Game.modShortName)

--Weapon Reload and Shield constant:
local reloadableWeaponCriteriaG = 0.5 --second at which reload time is considered high enough to be a "reload-able". ie: 0.5second
local criticalShieldLevelG = 0.5 --percent at which shield is considered low and should activate avoidance. ie: 50%
local minimumRemainingReloadTimeG = 0.9 --seconds before actual reloading finish which avoidance should de-activate. ie: 0.9 second before finish
local secondPerGameFrameG = 0.5/15 --engine depended second-per-frame (for calculating remaining reload time). ie: 0.0333 second-per-frame or 0.5sec/15frame
--------------------------------------------------------------------------------
--Variables:
local unitInMotionG={} --store unitID
local skippingTimerG={0,0, echoTimestamp=0, networkDelay=0, sumOfAllNetworkDelay=0, sumCounter=0}
local commandIndexTableG= {} --store latest widget command for comparison
local myTeamID_gbl=-1
local myPlayerID=-1
local gaiaTeamID = Spring.GetGaiaTeamID()
local surroundingOfActiveUnitG={} --store value for transfer between function. Store obstacle separation, los, and ect.
local cycleG=1 --first execute "GetPreliminarySeparation()"
local wreckageID_offset=0
local roundTripComplete= true --variable for detecting network lag, prevent messy overlapping command queuing
local attackerG= {} --for recording last attacker
--------------------------------------------------------------------------------
--Methods:
---------------------------------Level 0
options_path = 'Game/Unit AI/Dynamic Avoidance' --//for use 'with gui_epicmenu.lua'
options_order = {'enableCons','enableCloaky','enableGround','enableGunship','enableReturnToBase'}
options = {
	enableCons = {
		name = 'Enable for constructors',
		type = 'bool',
		value = true,
		desc = 'Enable constructor\'s avoidance feature. Constructor will return to base when given area-reclaim/area-ressurect, and partial avoidance while having build/repair/reclaim queue',
	},
	enableCloaky = {
		name = 'Enable for cloakies',
		type = 'bool',
		value = true,
		desc = 'Enable cloakies\' avoidance feature. Cloakable bots will avoid enemy when given move order',
	},
	enableGround = {
		name = 'Enable for ground units',
		type = 'bool',
		value = true,
		desc = 'Enable for ground units. All ground unit will avoid enemy while outside camera view, but units with hold position state is excluded',
	},
	enableGunship = {
		name = 'Enable for gunships',
		type = 'bool',
		value = true,
		desc = 'Enable gunship\'s avoidance feature. Gunship avoid enemy while outside camera view.',
	},
	enableReturnToBase = {
		name = "Find base",
		type = 'bool',
		value = true,
		desc = "Allow constructor to return to base when having area-reclaim/area-ressurect command, else it will return to center of the circle when retreating. This function enabled and used \'Receive Indicator\' widget",
		OnChange = function(self) 
			spSendCommands("luaui enablewidget Receive Indicator")
		end,
	},
}

function widget:Initialize()
	skippingTimerG.echoTimestamp = spGetGameSeconds()
	myPlayerID=Spring.GetMyPlayerID()
	local _, _, spec = Spring.GetPlayerInfo(myPlayerID)
	if spec then widgetHandler:RemoveWidget() return false end
	myTeamID_gbl= spGetMyTeamID()
	
	--count players to offset the ID of wreckage
	local playerIDList= Spring.GetPlayerList()
	local numberOfPlayers=#playerIDList
	for i=1,numberOfPlayers do
		local _,_,spectator,_,_,_,_,_,_=spGetPlayerInfo(playerIDList[i])
		if spectator then numberOfPlayers=numberOfPlayers-1 end
	end
	wreckageID_offset=wreckageID_offset_initial+ (numberOfPlayers-2)*wreckageID_offset_multiplier
	if (turnOnEcho == 1) then Spring.Echo("myTeamID_gbl(Initialize)" .. myTeamID_gbl) end
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
	local attacker = attackerG
	-----
	local now=spGetGameSeconds()
	if (now >= skippingTimer[1]) then --wait until 'skippingTimer[1] second', then do "RefreshUnitList()"
		if (turnOnEcho == 1) then Spring.Echo("-----------------------RefreshUnitList") end
		unitInMotion, attacker=RefreshUnitList(attacker) --create unit list
		
		local projectedDelay=ReportedNetworkDelay(myPlayerID, 1.1) --create list every 1.1 second, or every each second of lag.
		skippingTimer[1]=now+projectedDelay --wait until next 'skippingTimer[1] second'
		if (turnOnEcho == 1) then Spring.Echo("-----------------------RefreshUnitList") end
	end
	
	if (now >=skippingTimer[2] and cycle==1) and roundTripComplete then --wait until 'skippingTimer[2] second', and wait for 'LUA message received', and wait for 'cycle==1', then do "GetPreliminarySeparation()"
		if (turnOnEcho == 1) then Spring.Echo("-----------------------GetPreliminarySeparation") end
		surroundingOfActiveUnit,commandIndexTable=GetPreliminarySeparation(unitInMotion,commandIndexTable, attacker)
		cycle=2 --set to 'cycle==2'
		
		skippingTimer = CalculateNetworkDelay(1, skippingTimer, now) --update delay statistic. Record 'roundTripComplete'.
		skippingTimer[2] = now+ gps_then_DoCalculation_delayG --wait until 'gps_then_DoCalculation_delayG'. The longer the better. The delay allow reliable unit direction to be derived from unit's motion
		if (turnOnEcho == 1) then Spring.Echo("-----------------------GetPreliminarySeparation") end
	end
	if (now >=skippingTimer[2] and cycle==2) then --wait until 'skippingTimer[2] second', and wait for 'cycle==2', then do "DoCalculation()"
		if (turnOnEcho == 1) then Spring.Echo("-----------------------DoCalculation") end
		local networkDelay = CalculateNetworkDelay(0, skippingTimer, nil) --retrieve delay statistic
		commandIndexTable=DoCalculation (surroundingOfActiveUnit,commandIndexTable, attacker, networkDelay, now) --initiate avoidance system
		cycle=1 --set to 'cycle==1'
		
		skippingTimer[2]=now+ doCalculation_then_gps_delayG --wait until 'doCalculation_then_gps_delayG'. Is arbitrarily set. Save CPU by setting longer wait.
		skippingTimer = CalculateNetworkDelay(2, skippingTimer, now) --prepare delay statistic for new measurement
		spSendLuaUIMsg(dummyIDg) --send ping to server. Wait for answer
		roundTripComplete = false --Wait for 'LUA message Receive'.
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
	attackerG = attacker
	-----
end
---------------------------------Level 0 Top level
---------------------------------Level1 Lower level
-- return a refreshed unit list, else return nil
function RefreshUnitList(attacker)
	local allMyUnits = spGetTeamUnits(myTeamID_gbl)
	local arrayIndex=1
	local relevantUnit={}
	
	local metaForVisibleUnits = {}
	local visibleUnits=spGetVisibleUnits(myTeamID_gbl)
	for _, unitID in ipairs(visibleUnits) do --memorize units that is in view of camera
		metaForVisibleUnits[unitID]="yes" --flag "yes" for visible unit (in view) and by default flag "nil" for out of view unit
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
				local unitType = 0 --// category that control WHEN avoidance is activated for each unit. eg: Category 2 only enabled when not in view & when guarding units. Used by 'GateKeeperOrCommandFilter()'
				local fixedPointType = 1 --//category that control WHICH avoidance behaviour to use. eg: Category 2 priotize avoidance and prefer to ignore user's command when enemy is close. Used by 'CheckWhichFixedPointIsStable()'
				if (unitDef["builder"] or unitDef["canCloak"]) and not unitDef.customParams.commtype then --only include only cloakies and constructor, and not com (ZK)
					unitType =1
					if options.enableCons.value==false then --//if Cons epicmenu option is false then exclude Cons
						unitType = 0
					end
					if unitDef["canCloak"] then 
						fixedPointType=2
						if options.enableCloaky.value==false then --//if Cloaky epicmenu option is false then exclude Cloaky
							unitType = 0
						end
					end
				elseif not unitDef["canFly"] then --if enabled: include all ground unit
					unitType =2
					if options.enableGround.value==false then --//if Ground unit epicmenu option is false then exclude Ground unit
						unitType = 0
					end
				elseif (unitDef.hoverAttack== true) then --if enabled: include gunship
					unitType =3
					if options.enableGunship.value==false then --//if Gunship epicmenu option is false then exclude Gunship
						unitType = 0
					end
				end
				if (unitType>0) then
					local unitShieldPower, reloadableWeaponIndex= -1, -1
					unitShieldPower, reloadableWeaponIndex = CheckWeaponsAndShield(unitDef)
					arrayIndex=arrayIndex+1
					relevantUnit[arrayIndex]={unitID, unitType, unitSpeed, fixedPointType, isVisible = unitInView, unitShieldPower = unitShieldPower, reloadableWeaponIndex = reloadableWeaponIndex}
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
				local executionAllow, cQueueTemp = GateKeeperOrCommandFilter(unitID, cQueue, unitInMotion[i]) --filter/alter unwanted unit state by reading the command queue
				if executionAllow then
					cQueue = cQueueTemp --cQueueTemp has been altered for identification, copy it to cQueue for use (actual command is not yet issued)
					--local boxSizeTrigger= unitInMotion[i][2]
					local targetCoordinate, commandIndexTable, newCommand, boxSizeTrigger, graphCONSTANTtrigger=IdentifyTargetOnCommandQueue(cQueue, unitID, commandIndexTable) --check old or new command
					local currentX,_,currentZ = spGetUnitPosition(unitID)
					local lastPosition = {currentX, currentZ} --record current position for use to determine unit direction later.
					local reachedTarget = TargetBoxReached(targetCoordinate, unitID, boxSizeTrigger, lastPosition) --check if widget should ignore command
					local losRadius	= GetUnitLOSRadius(unitID) --get LOS
					local surroundingUnits	= GetAllUnitsInRectangle(unitID, losRadius, attacker) --catalogue enemy
					if (cQueue[1].id == CMD_MOVE and unitInMotion[i].isVisible ~= "yes") then --if unit has move Command and is outside user's view
						reachedTarget = false --force unit to continue avoidance despite close to target (try to circle over target until seen by user)
					end
					if reachedTarget then --if reached target
						commandIndexTable[unitID]=nil --empty the commandIndex (command history)
					end
					
					if surroundingUnits[1]~=nil and not reachedTarget then  --execute when enemy exist and target not reached yet
						local fixedPointCONSTANTtrigger = unitInMotion[i][4] --//using fixedPointType to trigger different fixed point constant for each unit type
						local unitSSeparation=CatalogueMovingObject(surroundingUnits, unitID, lastPosition) --detect initial enemy separation
						arrayIndex=arrayIndex+1 --// increment table index by 1, start at index 2; table lenght is stored at row 1
						local unitSpeed = unitInMotion[i][3]
						local impatienceTrigger,commandIndexTable = GetImpatience(newCommand,unitID, commandIndexTable)
						surroundingOfActiveUnit[arrayIndex]={unitID, unitSSeparation, targetCoordinate, losRadius, cQueue, newCommand, unitSpeed,impatienceTrigger, lastPosition, graphCONSTANTtrigger, fixedPointCONSTANTtrigger} --store result for next execution
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
				end --GateKeeperOrCommandFilter(cQueue, unitInMotion[i]) ==true
			end --if spGetUnitIsDead(unitID)==false
		end
		if arrayIndex>1 then surroundingOfActiveUnit[1]=arrayIndex 
		else surroundingOfActiveUnit[1]=nil end
	end --if unitInMotion[1]~=nil
	return surroundingOfActiveUnit, commandIndexTable --send separation result away
end

--perform the actual collision avoidance calculation and send the appropriate command to unit
function DoCalculation (surroundingOfActiveUnit,commandIndexTable, attacker, networkDelay, now)
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
				if #cQueueSyncTest>=2 then --if new command is longer than or equal to 2 (1 any command + 1 stop command)
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
				local graphCONSTANTtrigger = surroundingOfActiveUnit[i][10] --//fetch information on which aCONSTANT and obsCONSTANT to use
				local fixedPointCONSTANTtrigger = surroundingOfActiveUnit[i][11] --//fetch information on which fixedPoint constant to use
				local newX, newZ = AvoidanceCalculator(unitID, targetCoordinate,losRadius,newSurroundingUnits, unitSSeparation, unitSpeed, impatienceTrigger, lastPosition, graphCONSTANTtrigger, networkDelay, fixedPointCONSTANTtrigger) --calculate move solution
				local newY=spGetGroundHeight(newX,newZ)
				commandIndexTable= InsertCommandQueue(cQueue, unitID, newX, newY, newZ, commandIndexTable, newCommand, now) --send move solution to unit
				if (turnOnEcho == 1) then
					Spring.Echo("newX(Update) " .. newX)
					Spring.Echo("newZ(Update) " .. newZ)
				end			
			end
		end
	end
	return commandIndexTable
end

function widget:RecvLuaMsg(msg, playerID) --receive echo from server ('LUA message Receive')
	if msg:sub(1,3) == dummyIDg and playerID == myPlayerID then
		roundTripComplete = true --unlock system
	end
end

function ReportedNetworkDelay(playerIDa, defaultDelay)
	local _,_,_,_,_,totalDelay,_,_,_,_= Spring.GetPlayerInfo(playerIDa)
	if totalDelay==nil or totalDelay<=defaultDelay then return defaultDelay --if ping is too low: set the minimum delay
	else return totalDelay --take account for lag + wait a little bit for any command to properly update
	end
end

function CalculateNetworkDelay(reportingIn, skippingTimer, now)
	if reportingIn == 0 then --report known delay statistic
		local delay = 0
		local instantaneousDelay = skippingTimer.networkDelay --delay current lag
		local averageDelay = skippingTimer.sumOfAllNetworkDelay/skippingTimer.sumCounter --average delay
		if instantaneousDelay < averageDelay then --bound all delay to be > than average delay
			delay = averageDelay 
		else
			delay = instantaneousDelay
		end 
		return delay
	elseif reportingIn == 1 then --update delay statistic
		skippingTimer.networkDelay = now - skippingTimer.echoTimestamp --get the delay between previous Command and the latest 'LUA message Receive'
		skippingTimer.sumOfAllNetworkDelay=skippingTimer.sumOfAllNetworkDelay + skippingTimer.networkDelay --sum all the delay ever recorded
		skippingTimer.sumCounter = skippingTimer.sumCounter + 1 --count all the delay ever recorded
		return skippingTimer
	elseif reportingIn == 2 then --update delay statistic
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

function CheckWeaponsAndShield (unitDef)
	--global variable
	local reloadableWeaponCriteria = reloadableWeaponCriteriaG
	----
	local unitShieldPower, reloadableWeaponIndex =-1, -1 --assume unit has no shield and no reloadable/slow-loading weapons
	local fastestReloadTime, fastWeaponIndex = 999, -1 --temporary variables
	for currentWeaponIndex, weapons in ipairs(unitDef.weapons) do --reference: gui_contextmenu.lua by CarRepairer
		local weaponsID = weapons.weaponDef
		local weaponsDef = WeaponDefs[weaponsID]
		if weaponsDef.name and not weaponsDef.name:find('fake') and not weaponsDef.name:find('noweapon') then --reference: gui_contextmenu.lua by CarRepairer
			if weaponsDef.isShield then 
				unitShieldPower = weaponsDef.shieldPower --remember the shield power of this unit
			else --if not shield then this is conventional weapon
				local reloadTime = weaponsDef.reload
				if reloadTime < fastestReloadTime then --find the weapon with the smallest reload time
					fastestReloadTime = reloadTime
					fastWeaponIndex = currentWeaponIndex-1 --remember the index of the fastest weapon. Somehow the weapon table actually start at "0", so minus 1 from actual value (ZK)
				end
			end
		end
	end
	if fastestReloadTime > reloadableWeaponCriteria then --if the fastest reload cycle is greater than widget's update cycle, then:
		reloadableWeaponIndex = fastWeaponIndex --remember the index of that fastest loading weapon
		if (turnOnEcho == 1) then --debugging
			Spring.Echo("reloadableWeaponIndex(CheckWeaponsAndShield):")
			Spring.Echo(reloadableWeaponIndex)
			Spring.Echo("fastestReloadTime(CheckWeaponsAndShield):")
			Spring.Echo(fastestReloadTime)
		end
	end
	return unitShieldPower, reloadableWeaponIndex
end

function GateKeeperOrCommandFilter (unitID, cQueue, unitInMotionSingleUnit)
	local allowExecution = false
	if cQueue~=nil then --prevent ?. Forgot...
		local isReloading = CheckIfUnitIsReloading(unitInMotionSingleUnit) --check if unit is reloading/shieldCritical
		local state=spGetUnitStates(unitID)
		local holdPosition= (state.movestate == 0)
		if ((unitInMotionSingleUnit.isVisible ~= "yes" or isReloading) and (cQueue[1] == nil or #cQueue == 1)) then --if unit is out of user's vision and currently idle/with-singular-mono-command (eg: widget's move order), or is reloading and currently idle/with-singular-mono-command (eg: auto-attack) then:
			if movestate~= 0 then --if not "hold position"
				cQueue={{id = cMD_DummyG, params = {-1 ,-1,-1}, options = {}}, {id = CMD_STOP, params = {-1 ,-1,-1}, options = {}}, nil} --replace with a FAKE COMMAND. Will be used to initiate avoidance on idle unit & non-viewed unit
			end
		end
		if cQueue[1]~=nil then --prevent idle unit from executing the system (prevent crash), but idle unit with FAKE COMMAND (cMD_DummyG) is allowed.
			local isValidCommand = (cQueue[1].id == 40 or cQueue[1].id < 0 or cQueue[1].id == 90 or cQueue[1].id == CMD_MOVE or cQueue[1].id == 125 or  cQueue[1].id == cMD_DummyG) -- ALLOW unit with command: repair (40), build (<0), reclaim (90), ressurect(125), move(10), or FAKE COMMAND
			local isValidUnitTypeOrIsNotVisible = (unitInMotionSingleUnit[2] == 1) or (unitInMotionSingleUnit.isVisible ~= "yes")--ALLOW only unit of unitType=1 OR (all unitTypes that is outside player's vision)
			local _2ndAttackSignature = false --attack command signature
			local _2ndGuardSignature = false --guard command signature
			if #cQueue >=2 then --check if the command-queue is masked by widget's previous command, but the actual originality check will be performed by TargetBoxReached() later.
				_2ndAttackSignature = (cQueue[1].id == CMD_MOVE and cQueue[2].id == CMD_ATTACK)
				_2ndGuardSignature = (cQueue[1].id == CMD_MOVE and cQueue[2].id == CMD_GUARD)
			end
			local isReloadingState = (isReloading and (cQueue[1].id == CMD_ATTACK or cQueue[1].id == cMD_DummyG or _2ndAttackSignature)) --any unit with attack command or was idle that is Reloading
			local isGuardState = (cQueue[1].id == CMD_GUARD or _2ndGuardSignature)
			if (isValidCommand and isValidUnitTypeOrIsNotVisible) or (isReloadingState and not holdPosition) or (isGuardState) then --execute on: repair (40), build (<0), reclaim (90), ressurect(125), move(10), or FAKE idle COMMAND for: UnitType==1 or for: any unit outside visibility... or on any unit with any command which is reloading.
				if isReloadingState or #cQueue>=2 then --prevent STOP command from short circuiting the system
					if isReloadingState or cQueue[2].id~=false then --prevent a spontaneous enemy engagement from short circuiting the system
						allowExecution = true --allow execution
					end --if cQueue[2].id~=false
						if (turnOnEcho == 1) then Spring.Echo(cQueue[2].id) end --for debugging
				end --if #cQueue>=2
			end --if ((cQueue[1].id==40 or cQueue[1].id<0 or cQueue[1].id==90 or cQueue[1].id==10 or cQueue[1].id==125) and (unitInMotion[i][2]==1 or unitInMotion[i].isVisible == nil)
		end --if cQueue[1]~=nil
	end --if cQueue~=nil	
	return allowExecution, cQueue --disallow execution
end

--check if widget's command or user's command
function IdentifyTargetOnCommandQueue(cQueue, unitID,commandIndexTable) --//used by GetPreliminarySeparation()
	local targetCoordinate = {nil,nil,nil}
	local boxSizeTrigger=0
	local graphCONSTANTtrigger = {}
	local newCommand=true -- immediately assume user's command
	if commandIndexTable[unitID]==nil then --memory was empty, so fill it with zeros
		commandIndexTable[unitID]={widgetX=0, widgetZ=0 ,backupTargetX=0, backupTargetY=0, backupTargetZ=0, patienceIndexA=0}
	else
		local a = math.modf(dNil(cQueue[1].params[1])) --using math.modf to remove trailing decimal (only integer for matching). In case high resolution cause a fail matching with server's numbers... and use dNil incase wreckage suddenly disappear.
		local c = math.modf(dNil(cQueue[1].params[3])) --dNil: if it is a reclaim or repair order (no z coordinate) then replace it with -1 (has similar effect to the "nil")
		local b = math.modf(commandIndexTable[unitID]["widgetX"])
		local d = math.modf(commandIndexTable[unitID]["widgetZ"])
		newCommand= (a~= b and c~=d)--compare current command with in memory
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
		commandIndexTable, targetCoordinate, boxSizeTrigger, graphCONSTANTtrigger = ExtractTarget (1, unitID,cQueue,commandIndexTable,targetCoordinate)
		commandIndexTable[unitID]["patienceIndexA"]=0 --//reset impatience counter
	else  --if widget's previous command
		commandIndexTable, targetCoordinate, boxSizeTrigger, graphCONSTANTtrigger = ExtractTarget (2, unitID,cQueue,commandIndexTable,targetCoordinate)	
	end
	return targetCoordinate, commandIndexTable, newCommand, boxSizeTrigger, graphCONSTANTtrigger --return target coordinate
end

--ignore command set on this box
function TargetBoxReached (targetCoordinate, unitID, boxSizeTrigger, lastPosition)
	local currentX, currentZ = lastPosition[1], lastPosition[2]
	local targetX = dNil(targetCoordinate[1]) -- use dNil if target asynchronously/spontaneously disappear: in that case it will replace "nil" with -1 
	local targetZ =targetCoordinate[3]
	if targetX==-1 then return false end --if target is invalid (-1) then assume target not-yet-reached, return false (default state), and continue avoidance 
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
				if recUnitDefID~=nil and (iAmConstructor and iAmNotCloaked) then --if enemy is in plain sight & I am a normal visible constructor: then do the following check before registering enemy
					local recUnitDef = UnitDefs[recUnitDefID] --retrieve enemy definition
					local enemyParalyzed,_,_ = spGetUnitIsStunned (rectangleUnitID)
					if recUnitDef["weapons"][1]~=nil and not enemyParalyzed then -- check enemy for weapons and paralyze effect
						arrayIndex=arrayIndex+1
						relevantUnit[arrayIndex]=rectangleUnitID --register the enemy only if it has weapons & wasn't paralyzed
					end
				else --if enemy is in plain sight & iAm a generic units, then:
					if iAmNotCloaked then --if I am not cloaked
						local enemyParalyzed,_,_ = Spring.GetUnitIsStunned (rectangleUnitID)
						if not enemyParalyzed then -- check for paralyze effect
							arrayIndex=arrayIndex+1
							relevantUnit[arrayIndex]=rectangleUnitID --register all enemy only if it's not paralyzed
						end
					else --if I am cloaked
						arrayIndex=arrayIndex+1
						relevantUnit[arrayIndex]=rectangleUnitID --register all enemy (avoid all unit)
					end
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
				local unitDirection, _	= GetUnitDirection(unitID, lastPosition)
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

function AvoidanceCalculator(unitID, targetCoordinate, losRadius, surroundingUnits, unitsSeparation, unitSpeed, impatienceTrigger, lastPosition, graphCONSTANTtrigger, networkDelay, fixedPointCONSTANTtrigger)
	if (unitID~=nil) and (targetCoordinate ~= nil) then --prevent idle/non-existent/ unit with invalid command from using collision avoidance
		local aCONSTANT 			= aCONSTANTg --attractor constant (amplitude multiplier)
		local unitDirection, _		= GetUnitDirection(unitID, lastPosition) --get unit direction
		local targetAngle = 0
		local fTarget = 0
		local fTargetSlope = 0
		----
		aCONSTANT = aCONSTANT[graphCONSTANTtrigger[1]] --//select which 'aCONSTANT' value
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
		wTotal, dSum, fObstacleSum,dFobstacle,nearestFrontObstacleRange, normalizingFactor=SumAllUnitAroundUnitID (unitID, surroundingUnits, unitDirection, wTotal, dSum, fObstacleSum,dFobstacle,nearestFrontObstacleRange, unitsSeparation, impatienceTrigger, graphCONSTANTtrigger)
		--calculate appropriate behaviour based on the constant and above summation value
		local wTarget, wObstacle = CheckWhichFixedPointIsStable (fTargetSlope, dFobstacle, dSum, fTarget, fObstacleSum, wTotal, fixedPointCONSTANTtrigger)
		--convert an angular command into a coordinate command
		local newX, newZ= SendCommand(unitID, wTarget, wObstacle, fTarget, fObstacleSum, unitDirection, nearestFrontObstacleRange, losRadius, unitSpeed, impatienceTrigger, normalizingFactor, networkDelay)
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
function InsertCommandQueue(cQueue, unitID,newX, newY, newZ, commandIndexTable, newCommand, now)
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
				--if (not Spring.ValidFeatureID(cQueue[queueIndex+1].params[1]-wreckageID_offset) or (not Spring.ValidFeatureID(cQueue[queueIndex+1].params[1]))) and not Spring.ValidUnitID(cQueue[queueIndex+1].params[1]) then --if it was an area command
				if (cQueue[queueIndex+1].params[3]~=nil) then  --area command should has no "nil" on params 1,2,3, & 4
					spGiveOrderToUnit(unitID, CMD_REMOVE, {cQueue[queueIndex].tag}, {} ) --delete old command, skip the target:wreck/units. Allow command reset
					local coordinate = (FindSafeHavenForCons(unitID, now)) or  (cQueue[queueIndex+1])
					spGiveOrderToUnit(unitID, CMD_INSERT, {0, CMD_MOVE, CMD_OPT_INTERNAL, coordinate.params[1], coordinate.params[2], coordinate.params[3]}, {"alt"} ) --divert unit to the center of reclaim/repair command
				end
			elseif cQueue[queueIndex+1].id==40 then --if second (2) queue is also repair
				--if (not Spring.ValidFeatureID(cQueue[queueIndex+1].params[1]-wreckageID_offset) or (not Spring.ValidFeatureID(cQueue[queueIndex+1].params[1]))) and not Spring.ValidUnitID(cQueue[queueIndex+1].params[1]) then --if it was an area command
				if (cQueue[queueIndex+1].params[3]~=nil) then  --area command should has no "nil" on params 1,2,3, & 4
					spGiveOrderToUnit(unitID, CMD_REMOVE, {cQueue[queueIndex].tag}, {} ) --delete old command, skip the target:units. Allow continuous command reset
				end
			end
		end
	end
	spGiveOrderToUnit(unitID, CMD_INSERT, {0, CMD_MOVE, CMD_OPT_INTERNAL, newX, newY, newZ}, {"alt"} ) --insert new command
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
--check if unit is vulnerable/reloading
function CheckIfUnitIsReloading(unitInMotionSingleUnitTable)
	------
	local criticalShieldLevel =criticalShieldLevelG --global constant
	local minimumRemainingReloadTime =minimumRemainingReloadTimeG
	local secondPerGameFrame =secondPerGameFrameG
	------
	--local unitType = unitInMotionSingleUnitTable[2] --retrieve stored unittype
	local shieldIsCritical =false
	local weaponIsEmpty = false
	--if unitType ==2 or unitType == 1 then
		local unitID = unitInMotionSingleUnitTable[1] --retrieve stored unitID
		local unitShieldPower = unitInMotionSingleUnitTable.unitShieldPower --retrieve registered full shield power
		if unitShieldPower ~= -1 then
			local _, currentPower = spGetUnitShieldState(unitID)
			if currentPower~=nil then
				if currentPower/unitShieldPower <criticalShieldLevel then
					shieldIsCritical = true
				end
			end
		end
		local unitFastestReloadableWeapon = unitInMotionSingleUnitTable.reloadableWeaponIndex --retrieve the quickest reloadable weapon index
		if unitFastestReloadableWeapon ~= -1 then
			local _, _, weaponReloadFrame, _, _ = spGetUnitWeaponState(unitID, unitFastestReloadableWeapon)
			local currentFrame, _ = spGetGameFrame() 
			local remainingTime = (weaponReloadFrame - currentFrame)*secondPerGameFrame
			weaponIsEmpty = (remainingTime> minimumRemainingReloadTime)
			if (turnOnEcho == 1) then --debugging
				Spring.Echo(unitFastestReloadableWeapon)
				Spring.Echo(spGetUnitWeaponState(unitID, unitFastestReloadableWeapon, "range"))
			end
		end			
	--end
	return (weaponIsEmpty or shieldIsCritical)
end

-- debugging method, used to quickly remove nil
function dNil(x)
	if x==nil then
		x=-1
	end
	return x
end

function ExtractTarget (queueIndex, unitID, cQueue, commandIndexTable, targetCoordinate) --//used by IdentifyTargetOnCommandQueue()
	local boxSizeTrigger=0
	local graphCONSTANTtrigger = {}
	if (cQueue[queueIndex].id==CMD_MOVE or cQueue[queueIndex].id<0) then
		local targetPosX, targetPosY, targetPosZ = -1, -1, -1 -- (-1) is default value because -1 represent "no target"
		if cQueue[queueIndex].params[1]~= nil and cQueue[queueIndex].params[2]~=nil and cQueue[queueIndex].params[3]~=nil then --confirm that the coordinate exist
			targetPosX, targetPosY, targetPosZ = cQueue[queueIndex].params[1], cQueue[queueIndex].params[2],cQueue[queueIndex].params[3]
		else
			Spring.Echo("Dynamic Avoidance move targetting failure: fallback to no target")
		end
		boxSizeTrigger=1 --//avoidance deactivation 'halfboxsize' for MOVE command
		graphCONSTANTtrigger[1] = 1 --use standard angle scale (take ~10 cycle to do 180 flip, but more predictable)
		graphCONSTANTtrigger[2] = 1
		if #cQueue >= queueIndex+1 then
			if cQueue[queueIndex+1].id==90 or cQueue[queueIndex+1].id==125 then --//if reclaim or ressurect then identify area reclaim
				if cQueue[queueIndex].params[1]==cQueue[queueIndex+1].params[1]
					and cQueue[queueIndex].params[2]==cQueue[queueIndex+1].params[2]
					and cQueue[queueIndex].params[3]==cQueue[queueIndex+1].params[3] then --area reclaim should have no "nil", and will equal to retreat coordinate when retreating to center of area reclaim.
					targetPosX, targetPosY, targetPosZ = -1, -1, -1 --//if area reclaim under the above condition, then avoid forever in presence of enemy
					boxSizeTrigger=1 --//avoidance deactivation 'halfboxsize' for RECLAIM command
				end
			end
		end
		targetCoordinate={targetPosX, targetPosY, targetPosZ } --use first queue as target
		commandIndexTable[unitID]["backupTargetX"]=cQueue[queueIndex].params[1] --backup the target
		commandIndexTable[unitID]["backupTargetY"]=cQueue[queueIndex].params[2]
		commandIndexTable[unitID]["backupTargetZ"]=cQueue[queueIndex].params[3]
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
			if cQueue[queueIndex].params[3] ~= nil then --area reclaim should has no "nil" on params 1,2,3, & 4
				wreckPosX, wreckPosY,wreckPosZ = cQueue[queueIndex].params[1], cQueue[queueIndex].params[2],cQueue[queueIndex].params[3]
				isAreaMode = true
			else
				Spring.Echo("Dynamic Avoidance reclaim targetting failure: fallback to no target")
			end
		end
		targetCoordinate={wreckPosX, wreckPosY,wreckPosZ} --use wreck as target
		commandIndexTable[unitID]["backupTargetX"]=wreckPosX --backup the target
		commandIndexTable[unitID]["backupTargetY"]=wreckPosY
		commandIndexTable[unitID]["backupTargetZ"]=wreckPosZ
		--graphCONSTANTtrigger[1] = 2 --use bigger angle scale for initial avoidance: after that is a MOVE command to the center or area-command which uses standard angle scale (take ~4 cycle to do 180 flip, but more chaotic) 
		--graphCONSTANTtrigger[2] = 2
		graphCONSTANTtrigger[1] = 1 --use standard angle scale (take ~10 cycle to do 180 flip, but more predictable)
		graphCONSTANTtrigger[2] = 1
		boxSizeTrigger=2 --use deactivation 'halfboxsize' for RECLAIM/RESSURECT command
		if not isAreaMode and (cQueue[queueIndex+1].params[3]==nil or cQueue[queueIndex+1].id == CMD_STOP) then --signature for discrete RECLAIM/RESSURECT command
			boxSizeTrigger = 3 --change to deactivation 'halfboxsize' similar to REPAIR command
			--graphCONSTANTtrigger[1] = 1 --use standard angle scale (take ~10 cycle to do 180 flip, but more predictable)
			--graphCONSTANTtrigger[2] = 1
		end
	elseif cQueue[queueIndex].id==40 then --repair command
		local unitPosX, unitPosY, unitPosZ = -1, -1, -1 -- (-1) is default value because -1 represent "no target"
		local targetUnitID=cQueue[queueIndex].params[1]
	
		if Spring.ValidUnitID(targetUnitID) then --if has unit ID
			unitPosX, unitPosY, unitPosZ = spGetUnitPosition(targetUnitID)
		elseif cQueue[queueIndex].params[1]~= nil and cQueue[queueIndex].params[2]~=nil and cQueue[queueIndex].params[3]~=nil then --if no unit then use coordinate
			unitPosX, unitPosY,unitPosZ = cQueue[queueIndex].params[1], cQueue[queueIndex].params[2],cQueue[queueIndex].params[3]
		else
			Spring.Echo("Dynamic Avoidance repair targetting failure: fallback to no target")
		end
		targetCoordinate={unitPosX, unitPosY,unitPosZ} --use ally unit as target
		commandIndexTable[unitID]["backupTargetX"]=unitPosX --backup the target
		commandIndexTable[unitID]["backupTargetY"]=unitPosY
		commandIndexTable[unitID]["backupTargetZ"]=unitPosZ
		boxSizeTrigger=3
		graphCONSTANTtrigger[1] = 1
		graphCONSTANTtrigger[2] = 1
	elseif cQueue[1].id == cMD_DummyG then
		targetCoordinate = {-1, -1,-1} --no target (only avoidance)
		boxSizeTrigger = nil --//value not needed; because 'halfboxsize' for a "-1" target always return "not reached"
		graphCONSTANTtrigger[1] = nil --//value not needed; because avoidance of 'cMD_DummyG' don't use attractor 
		graphCONSTANTtrigger[2] = 1
	elseif cQueue[queueIndex].id == CMD_GUARD then
		local unitPosX, unitPosY, unitPosZ = -1, -1, -1 -- (-1) is default value because -1 represent "no target"
		local targetUnitID = cQueue[queueIndex].params[1]
		if Spring.ValidUnitID(targetUnitID) then --if valid unit ID, not fake (if fake then will use "no target" for pure avoidance)
			local unitDirection = 0
			unitDirection, unitPosY = GetUnitDirection(targetUnitID, {nil,nil}) --get target's direction in radian
			unitPosX, unitPosZ = ConvertToXZ(targetUnitID, unitDirection, 200) --project a target at 200m in front of guarded unit
		else
			Spring.Echo("Dynamic Avoidance guard targetting failure: fallback to no target")
		end
		targetCoordinate={unitPosX, unitPosY,unitPosZ} --use ally unit as target
		commandIndexTable[unitID]["backupTargetX"]=unitPosX --backup the target
		commandIndexTable[unitID]["backupTargetY"]=unitPosY
		commandIndexTable[unitID]["backupTargetZ"]=unitPosZ
		boxSizeTrigger = 4 --//deactivation 'halfboxsize' for GUARD command
		graphCONSTANTtrigger[1] = 2 --//use more aggressive attraction because it GUARD units. It need big result.
		graphCONSTANTtrigger[2] = 1	--//use less aggressive avoidance because need to stay close to units. It need not stray.
	elseif cQueue[queueIndex].id == CMD_ATTACK then
		targetCoordinate={-1, -1, -1}
		boxSizeTrigger = nil --//value not needed; because boxsize for a "-1" target always return "not reached"
		graphCONSTANTtrigger[1] = nil --//value not needed; because CMD_ATTACK don't use attractor 
		graphCONSTANTtrigger[2] = 2	--//use more aggressive avoidance because it often run just once or twice. It need big result.
	else --if queue has no match/ is empty: then use no-target. eg: A case where undefined command is allowed into the system, or when engine delete the next queues of a valid command and widget expect it to still be there.
		targetCoordinate={-1, -1, -1}
		--if for some reason command queue[2] is already empty then use these backup value as target:
		--targetCoordinate={commandIndexTable[unitID]["backupTargetX"], commandIndexTable[unitID]["backupTargetY"],commandIndexTable[unitID]["backupTargetZ"]} --if the second queue isappear then use the backup
		boxSizeTrigger = nil --//value not needed; because boxsize for a "-1" target always return "not reached"
		graphCONSTANTtrigger[1] = nil
		graphCONSTANTtrigger[2] = 1
	end
	return commandIndexTable, targetCoordinate, boxSizeTrigger, graphCONSTANTtrigger
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

	local targetDistance= Distance(tx,tz,x,z)
	local targetSubtendedAngle = math.atan(unitSize*2/targetDistance) --target is same size as unit's
	return targetSubtendedAngle
end

--sum the contribution from all enemy unit
function SumAllUnitAroundUnitID (thisUnitID, surroundingUnits, unitDirection, wTotal, dSum, fObstacleSum,dFobstacle, nearestFrontObstacleRange, unitsSeparation, impatienceTrigger, graphCONSTANTtrigger)
	local safetyMarginCONSTANT = safetyMarginCONSTANTunitG
	local smCONSTANT = smCONSTANTunitG --?
	local distanceCONSTANT = distanceCONSTANTunitG
	local obsCONSTANT =obsCONSTANTg
	local normalizeObsGraph = normalizeObsGraphG
	----
	obsCONSTANT = obsCONSTANT[graphCONSTANTtrigger[2]] --//select which 'obsCONSTANT' value to use
	local normalizingFactor = 1
	
	if (turnOnEcho == 1) then Spring.Echo("unitID(SumAllUnitAroundUnitID)" .. thisUnitID) end
	if (surroundingUnits[1]~=nil) then --don't execute if no enemy unit exist
		local graphSample={}
		if normalizeObsGraph then
			for i=1, 360+1, 1 do
				graphSample[i]=0 --initialize content 360 points
			end
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
					if normalizeObsGraph then
						for i=-180, 180, 1 do --sample the entire 360 degree graph
							local differenceInAngle = (unitDirection+math.pi/i)-relativeAngle
							local rI = (differenceInAngle/ subtendedAngle)*math.exp(1- math.abs(differenceInAngle/subtendedAngle))
							local wI = obsCONSTANT* (math.tanh(hI- (math.cos(differenceInAngle) -math.cos(2*subtendedAngle +smCONSTANT)))+1) --graph with limiting window
							graphSample[i+180+1]=graphSample[i+180+1]+ (rI*wI*dI*hI)
						end
					end

					--get repulsor wavefunction's slope
					local fObstacleSlope = GetFObstacleSlope(fObstacle2, fObstacle, unitDirection+0.05, unitDirection)

					--sum all repulsor's wavefunction from every enemy/obstacle within this loop
					wTotal, dSum, fObstacleSum,dFobstacle, nearestFrontObstacleRange= DoAllSummation (wi, fObstacle, fObstacleSlope, di,wTotal, unitDirection, unitSeparation, relativeAngle, dSum, fObstacleSum,dFobstacle, nearestFrontObstacleRange)
				end
			end
		end
		if normalizeObsGraph then
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
	end
	return wTotal, dSum, fObstacleSum,dFobstacle, nearestFrontObstacleRange, normalizingFactor --return obstacle's calculation result
end

--determine appropriate behaviour
function CheckWhichFixedPointIsStable (fTargetSlope, dFobstacle, dSum, fTarget, fObstacleSum, wTotal, fixedPointCONSTANTtrigger)
	--local alphaCONSTANT1, alphaCONSTANT2, gammaCONSTANT1and2, gammaCONSTANT2and1 = ConstantInitialize(fTargetSlope, dFobstacle, dSum, fTarget, fObstacleSum, wTotal, fixedPointCONSTANTtrigger)
	local cCONSTANT1 			=  cCONSTANT1g
	local cCONSTANT2			= cCONSTANT2g
	local gammaCONSTANT1and2
	local gammaCONSTANT2and1	= gammaCONSTANT2and1g
	local alphaCONSTANT1		= alphaCONSTANT1g
	local alphaCONSTANT2 --always between 1 and 0
	--------
	cCONSTANT1 			= cCONSTANT1[fixedPointCONSTANTtrigger]
	cCONSTANT2			= cCONSTANT2[fixedPointCONSTANTtrigger]
	gammaCONSTANT2and1	= gammaCONSTANT2and1[fixedPointCONSTANTtrigger]
	alphaCONSTANT1		= alphaCONSTANT1[fixedPointCONSTANTtrigger]
	
	--calculate "gammaCONSTANT1and2, alphaCONSTANT2, and alphaCONSTANT1"
	local pTarget= Sgn(fTargetSlope)*math.exp(cCONSTANT1*math.abs(fTarget))
	local pObstacle = Sgn(dFobstacle)*math.exp(cCONSTANT1*math.abs(fObstacleSum))*wTotal
	gammaCONSTANT1and2 = math.exp(-1*cCONSTANT2*pTarget*pObstacle)/math.exp(cCONSTANT2)
	alphaCONSTANT2 = math.tanh(dSum)
	alphaCONSTANT1 = alphaCONSTANT1*(1-alphaCONSTANT2)
	--
	
	local wTarget=0
	local wObstacle=1
	if (turnOnEcho == 1) then
		Spring.Echo("fixedPointCONSTANTtrigger(CheckWhichFixedPointIsStable)" .. fixedPointCONSTANTtrigger)
		Spring.Echo("alphaCONSTANT1(CheckWhichFixedPointIsStable)" .. alphaCONSTANT1)
		Spring.Echo ("alphaCONSTANT2(CheckWhichFixedPointIsStable)" ..alphaCONSTANT2)
		Spring.Echo ("gammaCONSTANT1and2(CheckWhichFixedPointIsStable)" ..gammaCONSTANT1and2)
		Spring.Echo ("gammaCONSTANT2and1(CheckWhichFixedPointIsStable)" ..gammaCONSTANT2and1)
	end

	if (alphaCONSTANT1 < 0) and (alphaCONSTANT2 <0) then --state 0 is unstable, unit don't move
		wTarget = 0
		wObstacle =0
		if (turnOnEcho == 1) then 
			Spring.Echo("state 0") 
			Spring.Echo ("(alphaCONSTANT1 < 0) and (alphaCONSTANT2 <0)")
		end
	end

	if (gammaCONSTANT1and2 > alphaCONSTANT1) and (alphaCONSTANT2 >0) then 	--state 1: unit flee from obstacle and forget target
		wTarget =0
		wObstacle =-1
		if (turnOnEcho == 1) then 
			Spring.Echo("state 1")
			Spring.Echo ("(gammaCONSTANT1and2 > alphaCONSTANT1) and (alphaCONSTANT2 >0)")			
		end
	end

	if(gammaCONSTANT2and1 > alphaCONSTANT2) and (alphaCONSTANT1 >0) then --state 2: unit forget obstacle and go for the target
		wTarget= -1
		wObstacle =0
		if (turnOnEcho == 1) then  
			Spring.Echo("state 2") 
			Spring.Echo ("(gammaCONSTANT2and1 > alphaCONSTANT2) and (alphaCONSTANT1 >0)")
		end
	end

	if (alphaCONSTANT1>0) and (alphaCONSTANT2>0) then --state 3: mixed contribution from target and obstacle
		if (alphaCONSTANT1> gammaCONSTANT1and2) and (alphaCONSTANT2>gammaCONSTANT2and1) then
			if (gammaCONSTANT1and2*gammaCONSTANT2and1 < 0.0) then
				--function from latest article. Set repulsor/attractor balance
				 wTarget= math.sqrt((alphaCONSTANT2*(alphaCONSTANT1-gammaCONSTANT1and2))/(alphaCONSTANT1*alphaCONSTANT2-gammaCONSTANT1and2*gammaCONSTANT2and1))
				 wObstacle= math.sqrt((alphaCONSTANT1*(alphaCONSTANT2-gammaCONSTANT2and1))/(alphaCONSTANT1*alphaCONSTANT2-gammaCONSTANT1and2*gammaCONSTANT2and1))

				-- wTarget= math.sqrt((alphaCONSTANT2*(alphaCONSTANT1-gammaCONSTANT2and1))/(alphaCONSTANT1*alphaCONSTANT2-gammaCONSTANT1and2*gammaCONSTANT2and1))
				-- wObstacle= math.sqrt((alphaCONSTANT1*(alphaCONSTANT2-gammaCONSTANT2and1))/(alphaCONSTANT1*alphaCONSTANT2-gammaCONSTANT1and2*gammaCONSTANT2and1))
						if (turnOnEcho == 1) then  
							Spring.Echo("state 3")
							Spring.Echo ("(gammaCONSTANT1and2*gammaCONSTANT2and1 < 0.0)")
						end
			end

			if (gammaCONSTANT1and2>0) and (gammaCONSTANT2and1>0) then
				--function from latest article. Set repulsor/attractor balance
				 wTarget= math.sqrt((alphaCONSTANT2*(alphaCONSTANT1-gammaCONSTANT1and2))/(alphaCONSTANT1*alphaCONSTANT2-gammaCONSTANT1and2*gammaCONSTANT2and1))
				 wObstacle= math.sqrt((alphaCONSTANT1*(alphaCONSTANT2-gammaCONSTANT2and1))/(alphaCONSTANT1*alphaCONSTANT2-gammaCONSTANT1and2*gammaCONSTANT2and1))

				-- wTarget= math.sqrt((alphaCONSTANT2*(alphaCONSTANT1-gammaCONSTANT2and1))/(alphaCONSTANT1*alphaCONSTANT2-gammaCONSTANT1and2*gammaCONSTANT2and1))
				-- wObstacle= math.sqrt((alphaCONSTANT1*(alphaCONSTANT2-gammaCONSTANT2and1))/(alphaCONSTANT1*alphaCONSTANT2-gammaCONSTANT1and2*gammaCONSTANT2and1))
				wTarget= wTarget*-1
					if (turnOnEcho == 1) then 
						Spring.Echo("state 4") 
						Spring.Echo ("(gammaCONSTANT1and2>0) and (gammaCONSTANT2and1>0)")
					end
			end
		end
	else 
		if (turnOnEcho == 1) then
			Spring.Echo ("State not listed") 
		end
	end
		if (turnOnEcho == 1) then  
			Spring.Echo ("wTarget (CheckWhichFixedPointIsStable)" ..wTarget)
			Spring.Echo ("wObstacle(CheckWhichFixedPointIsStable)" ..wObstacle)
		end
	return wTarget, wObstacle --return attractor's and repulsor's multiplier
end

--convert angular command into coordinate, plus other function
function SendCommand(thisUnitID, wTarget, wObstacle, fTarget, fObstacleSum, unitDirection, nearestFrontObstacleRange, losRadius, unitSpeed, impatienceTrigger, normalizingFactor, networkDelay)
	local safetyDistanceCONSTANT=safetyDistanceCONSTANTg
	local timeToContactCONSTANT=timeToContactCONSTANTg
	local activateAutoReverse=activateAutoReverseG
	------
	if (nearestFrontObstacleRange> losRadius) then nearestFrontObstacleRange = 999 end --if no obstacle infront of unit then set nearest obstacle as far as LOS to prevent infinite velocity.
	local newUnitAngleDerived= GetNewAngle(unitDirection, wTarget, fTarget, wObstacle, fObstacleSum, normalizingFactor) --derive a new angle from calculation for move solution

	local velocity=unitSpeed*(timeToContactCONSTANT+ networkDelay) --scale-down/scale-up command lenght based on system delay.
	local networkDelayDrift = unitSpeed*networkDelay --unit drift contributed by network lag
	local maximumVelocity = (nearestFrontObstacleRange- safetyDistanceCONSTANT)/timeToContactCONSTANT --calculate the velocity that will cause a collision within the next "timeToContactCONSTANT" second.
	activateAutoReverse=activateAutoReverse*impatienceTrigger --activate/deactivate 'autoReverse' if impatience system is used
	if (velocity >= maximumVelocity) and (activateAutoReverse==1) then velocity = -unitSpeed	end --set to reverse if impact is imminent

	if (turnOnEcho == 1) then 
		Spring.Echo("maximumVelocity(SendCommand)" .. maximumVelocity) 
		Spring.Echo("activateAutoReverse(SendCommand)" .. activateAutoReverse)
		Spring.Echo("unitDirection(SendCommand)" .. unitDirection)
	end
	
	local newX, newZ= ConvertToXZ(thisUnitID, newUnitAngleDerived,velocity, unitDirection, networkDelayDrift) --convert angle into coordinate form
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

local safeHavenLastUpdate = 0
local safeHavenCoordinates = {}
function FindSafeHavenForCons(unitID, now)
	local myTeamID = myTeamID_gbl
	----
	if options.enableReturnToBase.value==false or WG.recvIndicator == nil then --//if epicmenu option 'Return To Base' is false then return nil
		return nil
	end
	if (now - safeHavenLastUpdate) > 4 then --//only update NO MORE than once every 4 second:
		local allMyUnits = spGetTeamUnits(myTeamID)
		local unorderedUnitList = {}
		for i=1, #allMyUnits, 1 do --//convert unit list into a compatible format for the Clustering function below
			local unitID_list = allMyUnits[i]
			local x,y,z = spGetUnitPosition(unitID_list)
			local unitDefID_list = spGetUnitDefID(unitID_list)
			local unitDef = UnitDefs[unitDefID_list]
			local unitSpeed =unitDef["speed"]
			if (unitSpeed>0) then --//if moving units
				if (unitDef["builder"] or unitDef["canCloak"]) and not unitDef.customParams.commtype then --if cloakies and constructor, and not com (ZK)
					--intentionally empty. Not include cloakies and builder.
				elseif not unitDef["canFly"] then --if all ground unit
					unorderedUnitList[unitID_list] = {x,y,z} --//store
				elseif (unitDef.hoverAttack== true) then --if gunships
					unorderedUnitList[unitID_list] = {x,y,z} --//store
				end
			else --if buildings
				unorderedUnitList[unitID_list] = {x,y,z} --//store
			end
		end
		local cluster, _ = WG.recvIndicator.OPTICS_cluster(unorderedUnitList, 600,3, myTeamID,300) --//find clusters
		for index=1 , #cluster do
			local sumX, sumY,sumZ, unitCount,meanX, meanY, meanZ = 0,0 ,0 ,0 ,0,0,0
			for unitIndex=1, #cluster[index] do
				local unitID_list = cluster[index][unitIndex]
				local x,y,z= unorderedUnitList[unitID_list][1],unorderedUnitList[unitID_list][2],unorderedUnitList[unitID_list][3] --// get stored unit position
				sumX= sumX+x
				sumY = sumY+y
				sumZ = sumZ+z
				unitCount=unitCount+1
			end
			meanX = sumX/unitCount --//calculate center of cluster
			meanY = sumY/unitCount
			meanZ = sumZ/unitCount
			safeHavenCoordinates[(#safeHavenCoordinates or 0)+1] = {meanX, meanY, meanZ} --//record cluster position
		end
		safeHavenLastUpdate = now
	end --//end cluster detection
	local currentSafeHaven, nearestSafeHaven, nearestSafeHavenDistance = {params={}},{params={}}, 999999 --// initialize table using 'params' to be consistent with 'cQueue' content
	local x,_,z = spGetUnitPosition(unitID)
	for j=1, #safeHavenCoordinates, 1 do
		local distance = Distance(safeHavenCoordinates[j][1], safeHavenCoordinates[j][3] , x, z)
		if distance > 300 and distance < nearestSafeHavenDistance then
			nearestSafeHaveDistance = distance
			nearestSafeHaven.params[1] = safeHavenCoordinates[j][1]
			nearestSafeHaven.params[2] = safeHavenCoordinates[j][2]
			nearestSafeHaven.params[3] = safeHavenCoordinates[j][3]
		elseif distance < 300 then
			currentSafeHaven.params[1] = safeHavenCoordinates[j][1]
			currentSafeHaven.params[2] = safeHavenCoordinates[j][2]
			currentSafeHaven.params[3] = safeHavenCoordinates[j][3]
		end
	end
	if nearestSafeHaven.params[1]~=nil then --//if nearest safe haven found then go there
		return nearestSafeHaven
	elseif currentSafeHaven.params[1]~=nil then --//elseif only current safe haven is available then go here
		return currentSafeHaven
	else --//elseif no safe haven detected then return nil
		return nil
	end
end
---------------------------------Level3
---------------------------------Level4 (lower than low-level function)

function GetUnitDirection(unitID, lastPosition) --give unit direction in radian, 2D
	local dx = 0
	local dz = 0
	local currentX, currentY, currentZ = spGetUnitPosition(unitID)
	if (lastPosition[1] ~= nil) then --calculate unit's vector using difference-in-location when lastPosition contain coordinates
		dx = currentX-lastPosition[1]
		dz = currentZ-lastPosition[2]
		if (dx == 0 and dz == 0) then --use the reported vector if lastPosition failed to reveal any vector
			dx,_,dz= spGetUnitDirection(unitID)
		end
	else --use the reported vector if lastPosition contain "nil"
		dx,_,dz= spGetUnitDirection(unitID)
	end
	local unitDirection = math.atan2(dz, dx)
	return unitDirection, currentY
end

function ConvertToXZ(thisUnitID, newUnitAngleDerived, velocity, unitDirection, networkDelayDrift)
	--localize global constant
	local velocityAddingCONSTANT=velocityAddingCONSTANTg
	local velocityScalingCONSTANT=velocityScalingCONSTANTg
	--
	local x,_,z = spGetUnitPosition(thisUnitID)
	local distanceToTravelInSecond=velocity*velocityScalingCONSTANT+velocityAddingCONSTANT --add multiplier
	local newX = distanceToTravelInSecond*math.cos(newUnitAngleDerived) + x -- issue a command on the ground to achieve a desired angular turn
	local newZ = distanceToTravelInSecond*math.sin(newUnitAngleDerived) + z
	
	if unitDirection ~= nil then --argument #4 & #5 can be empty (for other usage). Also used in ExtractTarget for GUARD command.
		local distanceTraveledDueToNetworkDelay = networkDelayDrift 
		newX = distanceTraveledDueToNetworkDelay*math.cos(unitDirection) + newX -- translate move command abit further forward; to account for lag. Network Lag makes move command lags behind the unit. 
		newZ = distanceTraveledDueToNetworkDelay*math.sin(unitDirection) + newZ
	end
	
	if (turnOnEcho == 1) then
		Spring.Echo("x(ConvertToXZ) " .. x)
		Spring.Echo("z(ConvertToXZ) " .. z)
	end
	return newX, newZ
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

--
function GetNewAngle (unitDirection, wTarget, fTarget, wObstacle, fObstacleSum, normalizingFactor)
	fObstacleSum = fObstacleSum*normalizingFactor --downscale value depend on the entire graph's maximum
	local unitAngleDerived= math.abs(wTarget)*fTarget + math.abs(wObstacle)*fObstacleSum + (noiseAngleG)*(GaussianNoise()*2-1) --add wave-amplitude, and add noise between -ve & +ve noiseAngle
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

function Distance(x1,z1,x2,z2)
  local dis = math.sqrt((x1-x2)*(x1-x2)+(z1-z2)*(z1-z2))
  return dis
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
--7
--"gui_contextmenu.lua" -unit stat widget, by CarRepairer/WagonRepairer
--8
--"unit_AA_micro.lua" -widget that micromanage AA, weaponsState example, by Jseah
--9
--"cmd_retreat.lua" -Place 'retreat zones' on the map and order units to retreat to them at desired HP percentages, by CarRepairer (OPT_INTERNAL function)      
--"gui_epicmenu.lua" --"Extremely Powerful Ingame Chili Menu.", by Carrepairer
--"gui_chili_integral_menu.lua" --Chili Integral Menu, by Licho, KingRaptor, Google Frog
--------------------------------------------------------------------------------
--Method Index:
--  widget:Initialize()
--  widget:PlayerChanged(playerID)
--  widget:Update()
--  RefreshUnitList(attacker)
--  GetPreliminarySeparation(unitInMotion,commandIndexTable, attacker)
--  DoCalculation (surroundingOfActiveUnit,commandIndexTable, attacker)
--  widget:RecvLuaMsg(msg, playerID)
--  ReportedNetworkDelay(playerIDa, defaultDelay)
--  CalculateNetworkDelay(reportingIn, skippingTimer,doCalculation_then_gps_delay,gps_then_DoCalculation_delay, now)
--  RetrieveAttackerList (unitID, attacker)
--  CheckWeaponsAndShield (unitDef)
--  GateKeeperOrCommandFilter (unitID, cQueue, unitInMotionSingleUnit)
--  IdentifyTargetOnCommandQueue(cQueue, unitID,commandIndexTable)
--  TargetBoxReached (targetCoordinate, unitID, boxSizeTrigger, lastPosition)
--  GetUnitLOSRadius(unitID)
--  GetAllUnitsInRectangle(unitID, losRadius, attacker)
--  ...
--  CatalogueMovingObject(surroundingUnits, unitID, lastPosition)
--  ...
--  Round(num) --Reference: http://lua-users.org/wiki/SimpleRound
--  dNil(x)
--  Distance(x1,z1,x2,z2)
--  GetUnitSubtendedAngle (unitIDmain, unitID2)
--  GetRiWiDi (unitDirection, relativeAngle, subtendedAngle, separationDistance, safetyMarginCONSTANT, smCONSTANT, distanceCONSTANT, obsCONSTANT)
--  GetFObstacleSlope (fObstacle2, fObstacle, unitDirection2, unitDirection)
--  DoAllSummation (wi, fObstacle, fObstacleSlope, di,wTotal, unitDirection, unitSeparation, relativeAngle, dSum, fObstacleSum, dFobstacle, nearestFrontObstacleRange)
--  ConstantInitialize(fTargetSlope, dFobstacle, dSum, fTarget, fObstacleSum, wTotal)
--  GetNewAngle (unitDirection, wTarget, fTarget, wObstacle, fObstacleSum, normalizingFactor)
--  ConvertToXZ(thisUnitID, newUnitAngleDerived, velocity)
--  SumRiWiDiCalculation (wi, fObstacle, fObstacleSlope, di, wTotal, dSum, fObstacleSum, dFobstacle)
--  GaussianNoise()
--  Sgn(x)
--------------------------------------------------------------------------------
--Feature Tracking:
-- Constructor under area reclaim will return to center of area command when sighting an enemy
-- Attacked will mark last attacker and avoid them even when outside LOS for 3 second
-- Unit outside user view will universally auto-avoidance, but remain still when seen
-- Hold position prevent universal auto-avoidance when not seen, also prevent auto-retreat when unit perform auto-attack
-- Unit under attack command will perform auto-retreat when reloading or shield < 50% regardless of hold-position state
-- Cloakable unit will universally auto-avoid when moving...
-- Area repair will cause unit auto-avoid from point to point (unit to repair); this is contrast to area reclaim.
-- Area Reclaim/ressurect tolerance < area repair tolerance < move tolerance (unit within certain radius of target will ignore enemy/not avoid)
-- Individual repair/reclaim command queue has same tolerance as area repair tolerance
-- 