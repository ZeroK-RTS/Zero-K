local versionName = "v2.8"
--------------------------------------------------------------------------------
--
--  file:    cmd_dynamic_Avoidance.lua
--  brief:   a collision avoidance system
--  using: "non-Linear Dynamic system approach to modelling behavior" -SiomeGoldenstein, Edward Large, DimitrisMetaxas
--	code:  Msafwan
--
--  Licensed under the terms of the GNU GPL, v2 or later.
--
--------------------------------------------------------------------------------
function widget:GetInfo()
  return {
    name      = "Dynamic Avoidance System",
    desc      = versionName .. " Avoidance AI behaviour for constructor, cloakies, ground-combat unit and gunships.\n\nNote: Customize the settings by Space+Click on unit-state icons.",
    author    = "msafwan",
    date      = "Jan 30, 2013",
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
local spGiveOrderArrayToUnitArray = Spring.GiveOrderArrayToUnitArray
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
local spGetSelectedUnits = Spring.GetSelectedUnits
local CMD_STOP			= CMD.STOP
local CMD_ATTACK 		= CMD.ATTACK
local CMD_GUARD			= CMD.GUARD
local CMD_INSERT		= CMD.INSERT
local CMD_REMOVE		= CMD.REMOVE
local CMD_MOVE			= CMD.MOVE
local CMD_OPT_INTERNAL	= CMD.OPT_INTERNAL
local CMD_OPT_SHIFT		= CMD.OPT_SHIFT
--local spRequestPath = Spring.RequestPath
local mathRandom = math.random
--local spGetUnitSensorRadius  = Spring.GetUnitSensorRadius
--------------------------------------------------------------------------------
-- Constant:
-- Switches:
local turnOnEcho =0 --1:Echo out all numbers for debugging the system, 2:Echo out alert when fail. (default = 0)
local activateAutoReverseG=1 --integer:[0,1], activate a one-time-reverse-command when unit is about to collide with an enemy (default = 0)
local activateImpatienceG=0 --integer:[0,1], auto disable auto-reverse & half the 'distanceCONSTANT' after 6 continuous auto-avoidance (3 second). In case the unit stuck (default = 0)

-- Graph constant:
local distanceCONSTANTunitG = 410 --increase obstacle awareness over distance. (default = 410 meter, ie: ZK's stardust range)
local safetyMarginCONSTANTunitG = 0.175 --obstacle graph windower (a "safety margin" constant). Shape the obstacle graph so that its fatter and more sloppier at extremities: ie: probably causing unit to prefer to turn more left or right (default = 0.175 radian)
local smCONSTANTunitG		= 0.175  -- obstacle graph offset (a "safety margin" constant).  Offset the obstacle effect: to prefer avoid torward more left or right??? (default = 0.175 radian)
local aCONSTANTg			= {math.pi/4 , math.pi/4} -- attractor graph; scale the attractor's strenght. Less equal to a lesser turning toward attraction(default = math.pi/10 radian (MOVE),math.pi/4 (GUARD & ATTACK)) (max value: math.pi/2 (because both contribution from obstacle & target will sum to math.pi)).
local obsCONSTANTg			= {math.pi/4, math.pi/4} -- obstacle graph; scale the obstacle's strenght. Less equal to a lesser turning away from avoidance(default = math.pi/10 radian (MOVE), math.pi/4 (GUARD & ATTACK)). 
--aCONSTANTg Note: math.pi/4 is equal to about 45 degrees turning (left or right). aCONSTANTg is the maximum amount of turning toward target and the actual turning depend on unit's direction. Activated by 'graphCONSTANTtrigger[1]'
--an antagonist to aCONSTANg (obsCONSTANTg or obstacle graph) also use math.pi/4 (45 degree left or right) but actual maximum value varies depend on number of enemy, but already normalized. Activated by 'graphCONSTANTtrigger[2]'
local windowingFuncMultG = 1 --? (default = 1 multiplier)
local normalizeObsGraphG = true --// if 'true': normalize turn angle to a maximum of "obsCONSTANTg", if 'false': allow turn angle to grow as big as it can (depend on number of enemy, limited by "maximumTurnAngleG").
local stdDecloakDist_fG = 75 --//a decloak distance size for Scythe is put as standard. If other unit has bigger decloak distance then it will be scalled based on this

-- Obstacle/Target competetive interaction constant:
local cCONSTANT1g 			= {0.01,1,2} --attractor constant; effect the behaviour. ie: selection between 4 behaviour state. (default = 0.01x (All), 1x (Cloakies)) (behaviour:(MAINTAIN USER's COMMAND)|(IGNORE USER's COMMAND))
local cCONSTANT2g			= {0.01,1,2} --repulsor constant; effect behaviour. (default = 0.01x (All), 1x (Cloakies)) (behaviour:(MAINTAIN USER's COMMAND)|(IGNORE USER's COMMAND))
local gammaCONSTANT2and1g	= {0.05,0.05,0.05} -- balancing constant; effect behaviour. . (default = 0.05x (All), 0.05x (Cloakies))
local alphaCONSTANT1g		= {500,0.4,0.4} -- balancing constant; effect behaviour. (default = 500x (All), 0.4x (Cloakies)) (behaviour:(MAINTAIN USER's COMMAND)|(IGNORE USER's COMMAND))

--Move Command constant:
local halfTargetBoxSize_g = {400, 0, 185, 50} --aka targetReachBoxSizeTrigger, set the distance from a target which widget should de-activate (default: MOVE = 400m (ie:800x800m box/2x constructor range), RECLAIM/RESSURECT=0 (always flee), REPAIR=185 (1x constructor's range), GUARD = 50 (arbitrary))
local cMD_DummyG = 248 --a fake command ID to flag an idle unit for pure avoidance. (arbitrary value, change if it overlap with existing command)
local dummyIDg = "[]" --fake ping id for Lua Message to check lag (prevent processing of latest Command queue if server haven't process previous command yet; to avoid messy queue) (arbitrary value, change if conflict with other widget)

--Angle constant:
--http://en.wikipedia.org/wiki/File:Degree-Radian_Conversion.svg
local noiseAngleG =0.1 --(default is pi/36 rad); add random angle (range from 0 to +-math.pi/36) to the new angle. To prevent a rare state that contribute to unit going straight toward enemy
local collisionAngleG= 0.1 --(default is pi/6 rad) a "field of vision" (range from 0 to +-math.pi/366) where auto-reverse will activate 
local fleeingAngleG= 0.7 --(default is pi/4 rad) angle of enemy (range from 0 to +-math.pi/4) where fleeing enemy is considered as fleeing(to de-activate avoidance to perform chase). Set to 0 to de-activate.
local maximumTurnAngleG = math.pi --(default is pi rad) safety measure. Prevent overturn (eg: 360+xx degree turn)
--pi is 180 degrees

--Update constant:
local doCalculation_then_gps_delayG = 0.25  --elapsed second (Wait) before gathering preliminary data for issuing command (default: 0.25 second)
local gps_then_DoCalculation_delayG = 0.25  --elapsed second (Wait) before issuing new command (default: 0.25 second)

-- Distance or velocity constant:
local timeToContactCONSTANTg= doCalculation_then_gps_delayG + gps_then_DoCalculation_delayG --time scale for move command; to calculate collision calculation & command lenght (default = 0.5 second). Will change based on user's Ping
local safetyDistanceCONSTANT_fG=205 --range toward an obstacle before unit auto-reverse (default = 205 meter, ie: half of ZK's stardust range) reference:80 is a size of BA's solar
local extraLOSRadiusCONSTANTg=205 --add additional distance for unit awareness over the default LOS. (default = +205 meter radius, ie: to 'see' radar blip).. Larger value measn unit detect enemy sooner, else it will rely on its own LOS.
local velocityScalingCONSTANTg=1 --scale command lenght. (default= 1 multiplier) *Small value cause avoidance to jitter & stop prematurely*
local velocityAddingCONSTANTg=50 --add or remove command lenght (default = 50 elmo/second) *Small value cause avoidance to jitter & stop prematurely*

--Engine based wreckID correction constant: *Update: replaced with Game.maxUnit
--local wreckageID_offset_multiplier = 0 --for Spring 0.82 this is 1500. *Update: replaced with Game.maxUnit. Original function is to offset game's maxUnit based on ingame player count.
--local wreckageID_offset_initial = 32000	--for Spring 0.82 this is 4500 *Update: replaced with Game.maxUnit. Original function is to offset game's initial gameStart's maxUnit.
--curModID = upper(Game.modShortName)

--Weapon Reload and Shield constant:
local reloadableWeaponCriteriaG = 0.5 --second at which reload time is considered high enough to be a "reload-able". ie: 0.5second
local criticalShieldLevelG = 0.5 --percent at which shield is considered low and should activate avoidance. ie: 50%
local minimumRemainingReloadTimeG = 0.9 --seconds before actual reloading finish which avoidance should de-activate. ie: 0.9 second before finish
local secondPerGameFrameG = 0.5/15 --engine depended second-per-frame (for calculating remaining reload time). ie: 0.0333 second-per-frame or 0.5sec/15frame

--Command Timeout constants:
local commandTimeoutG = 2
local consRetreatTimeoutG = 15

--NOTE:
--angle measurement and direction setting is based on right-hand coordinate system, but Spring uses left-hand coordinate system.
--So, math.sin is for x, and math.cos is for z, and math.atan2 input is x,z (is swapped with respect to the usual x y convention).
--those swap conveniently translate left-hand coordinate system into right-hand coordinate system.

--------------------------------------------------------------------------------
--Variables:
local unitInMotionG={} --store unitID
local skippingTimerG={0,0, echoTimestamp=0, networkDelay=0, averageDelay = 0.3, storedDelay = {}, index = 1, sumOfAllNetworkDelay=0, sumCounter=0} --variable: store the timing for next update, and store values for calculating average network delay.
local commandIndexTableG= {} --store latest widget command for comparison
local myTeamID_gbl=-1
local myPlayerID=-1
local gaiaTeamID = Spring.GetGaiaTeamID()
local surroundingOfActiveUnitG={} --store value for transfer between function. Store obstacle separation, los, and ect.
local cycleG=1 --first execute "GetPreliminarySeparation()"
local wreckageID_offset=0
local roundTripComplete= true --variable for detecting network lag, prevent messy overlapping command queuing
local attackerG= {} --for recording last attacker
local commandTTL_G = {} --for recording command's age. To check for expiration
local iNotLagging_gbl = true --//variable: indicate if player(me) is lagging in current game. If lagging then do not process anything.
local selectedCons_Meta_gbl = {} --//variable: remember which Constructor is selected by player.
--------------------------------------------------------------------------------
--Methods:
---------------------------------Level 0
options_path = 'Game/Unit AI/Dynamic Avoidance' --//for use 'with gui_epicmenu.lua'
options_order = {'enableCons','enableCloaky','enableGround','enableGunship','enableReturnToBase','consRetreatTimeoutOption', 'dbg_RemoveAvoidanceSplitSecond', 'dbg_IgnoreSelectedCons'}
options = {
	enableCons = {
		name = 'Enable for constructors',
		type = 'bool',
		value = true,
		desc = 'Enable constructor\'s avoidance feature. Constructor will return to base when given area-reclaim/area-ressurect, and partial avoidance while having build/repair/reclaim queue.\n\nTips: order area-reclaim to the whole map, work best for cloaked constructor, but buggy for flying constructor. Default:On',
	},
	enableCloaky = {
		name = 'Enable for cloakies',
		type = 'bool',
		value = true,
		desc = 'Enable cloakies\' avoidance feature. Cloakable bots will avoid enemy when given move order, but units with hold-position state is excluded.\n\nTips: is optimized for Sycthe- your Sycthe will less likely to be detected. Default:On',
	},
	enableGround = {
		name = 'Enable for ground units',
		type = 'bool',
		value = true,
		desc = 'Enable for ground units. All ground unit will avoid enemy while outside camera view OR when reloading, but units with hold position state is excluded.\n\nTips:\n1) is optimized for masses of thug or shielded unit.\n2) Use Guard to make your unit cover other unit in presence of enemy.\nDefault:On',
	},
	enableGunship = {
		name = 'Enable for gunships',
		type = 'bool',
		value = false,
		desc = 'Enable gunship\'s avoidance behaviour. Gunship avoid enemy while outside camera view OR when reloading, but units with hold-position state is excluded.\n\nTips: to optimize the hit-&-run behaviour- set the fire-state options to hold-fire. Default:Off',
	},
	-- enableAmphibious = {
		-- name = 'Enable for amphibious',
		-- type = 'bool',
		-- value = true,
		-- desc = 'Enable amphibious unit\'s avoidance feature (including Commander, and submarine). Unit avoid enemy while outside camera view OR when reloading, but units with hold position state is excluded..',
	-- },
	enableReturnToBase = {
		name = "Find base",
		type = 'bool',
		value = true,
		desc = "Allow constructor to return to base when having area-reclaim/area-ressurect command, else it will return to center of the circle when retreating. Enabling this function will also enable the \'Receive Indicator\' widget. \n\nTips: build 3 new buildings at new location to identify as base, unit will automatically select nearest base. Default:On",
		OnChange = function(self) 
			if self.value==true then
				spSendCommands("luaui enablewidget Receive Units Indicator")
			end
		end,
	},
	consRetreatTimeoutOption = {
		name = 'Constructor retreat auto-expire:',
		type = 'number',
		value = 15,
		desc = "Amount in second before constructor retreat command auto-expire (is deleted), and then contructor will return to its previous area-reclaim command.\n\nTips: small value is better.",
		min=3,max=15,step=1,
		OnChange = function(self) 
					consRetreatTimeoutG = self.value
					Spring.Echo(string.format ("%.1f", 1.1*consRetreatTimeoutG) .. " second")
				end,
	},
	dbg_RemoveAvoidanceSplitSecond = {
		name = 'Debug: Constructor instant retreat',
		type = 'bool',
		value = true,
		desc = "Widget to issue a retreat order first before issuing an avoidance (to reduce chance of avoidance putting constructor into more danger).\n\nDefault:On.",
		advanced = true,
	},
	dbg_IgnoreSelectedCons ={
		name = 'Debug: Ignore current selection',
		type = 'bool',
		value = false,
		desc = "Selected constructor(s) will be ignored by widget.\nNote: there's a second delay before unit is ignored/re-acquire after selection/de-selection.\n\nDefault:Off",
		--advanced = true,
	},
}

function widget:Initialize()
	skippingTimerG.echoTimestamp = spGetGameSeconds()
	myPlayerID=Spring.GetMyPlayerID()
	local _, _, spec = Spring.GetPlayerInfo(myPlayerID)
	if spec then widgetHandler:RemoveWidget() return false end
	myTeamID_gbl= spGetMyTeamID()
	
	--find maxUnits 
	--offset the ID of wreckage
	wreckageID_offset = Game.maxUnits
	--
	
	if (turnOnEcho == 1) then Spring.Echo("myTeamID_gbl(Initialize)" .. myTeamID_gbl) end
end

function widget:PlayerChanged(playerID)
	if Spring.GetSpectatingState() then widgetHandler:RemoveWidget() end
	
	--find maxUnits
	--offset the ID of wreckage
	wreckageID_offset = Game.maxUnits
	--
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
	local commandTTL = commandTTL_G
	local selectedCons_Meta = selectedCons_Meta_gbl
	local doCalculation_then_gps_delay = doCalculation_then_gps_delayG
	local gps_then_DoCalculation_delay = gps_then_DoCalculation_delayG
	-----
	if iNotLagging_gbl then
		local now=spGetGameSeconds()
		--REFRESH UNIT LIST-- *not synced with avoidance*
		if (now >= skippingTimer[1]) then --wait until 'skippingTimer[1] second', then do "RefreshUnitList()"
			if (turnOnEcho == 1) then Spring.Echo("-----------------------RefreshUnitList") end
			unitInMotion, attacker, commandTTL, selectedCons_Meta =RefreshUnitList(attacker, commandTTL) --create unit list
			
			local projectedDelay=ReportedNetworkDelay(myPlayerID, 1.1) --create list every 1.1 second OR every (0+latency) second, depending on which is greater.
			skippingTimer[1]=now+projectedDelay --wait until next 'skippingTimer[1] second'
			if (turnOnEcho == 1) then Spring.Echo("-----------------------RefreshUnitList") end
		end
		--GATHER SOME INFORMATION ON UNITS-- *part 1, start*
		if (now >=skippingTimer[2] and cycle==1) and roundTripComplete then --wait until 'skippingTimer[2] second', and wait for 'LUA message received', and wait for 'cycle==1', then do "GetPreliminarySeparation()"
			if (turnOnEcho == 1) then Spring.Echo("-----------------------GetPreliminarySeparation") end
			surroundingOfActiveUnit,commandIndexTable=GetPreliminarySeparation(unitInMotion,commandIndexTable, attacker, selectedCons_Meta)
			cycle=2 --set to 'cycle==2'
			
			skippingTimer[2] = now + gps_then_DoCalculation_delay --wait until 'gps_then_DoCalculation_delayG'. The longer the better. The delay allow reliable unit direction to be derived from unit's motion
			if (turnOnEcho == 1) then Spring.Echo("-----------------------GetPreliminarySeparation") end
		end
		--PERFORM AVOIDANCE/ACTION-- *part 2, end*
		if (now >=skippingTimer[2] and cycle==2) then --wait until 'skippingTimer[2] second', and wait for 'cycle==2', then do "DoCalculation()"
			if (turnOnEcho == 1) then Spring.Echo("-----------------------DoCalculation") end
			local isAvoiding = nil
			commandIndexTable, commandTTL,isAvoiding =DoCalculation (surroundingOfActiveUnit,commandIndexTable, attacker, skippingTimer, now, commandTTL) --initiate avoidance system
			cycle=1 --set to 'cycle==1'
			
			if isAvoiding then  
				skippingTimer.echoTimestamp = now -- --prepare delay statistic to measure new delay (aka: reset stopwatch), --same as "CalculateNetworkDelay("restart", , )"^/
				spSendLuaUIMsg(dummyIDg) --send ping to server. Wait for answer
				roundTripComplete = false --Wait for 'LUA message Receive'.
			else
				roundTripComplete = true --do not need to send LUA message for next update.
			end
			skippingTimer[2]=now + doCalculation_then_gps_delay --wait until 'doCalculation_then_gps_delayG'. Is arbitrarily set. Save CPU by setting longer wait.
			if (turnOnEcho == 1) then Spring.Echo("-----------------------DoCalculation") end
		end

		if (turnOnEcho == 1) then
			Spring.Echo("unitInMotion(Update):")
			Spring.Echo(unitInMotion)
		end
	end
	-------return global table
	commandIndexTableG=commandIndexTable
	unitInMotionG = unitInMotion
	surroundingOfActiveUnitG=surroundingOfActiveUnit
	cycleG = cycle
	skippingTimerG = skippingTimer
	attackerG = attacker
	commandTTL_G = commandTTL
	selectedCons_Meta_gbl = selectedCons_Meta
	-----
end

function widget:GameProgress(serverFrameNum) --//see if player are lagging behind the server in the current game. If player is lagging then trigger a switch, (this switch will tell the widget to stop processing units).
	local myFrameNum = spGetGameFrame()
	local frameNumDiff = serverFrameNum - myFrameNum
	if frameNumDiff > 120 then --// 120 frame means: a 4 second lag. Consider me is lagging if my frame differ from server by more than 4 second.
		iNotLagging_gbl = false
	else  --// consider me not lagging if my frame differ from server's frame for less than 4 second.
		iNotLagging_gbl = true
	end
end

---------------------------------Level 0 Top level
---------------------------------Level1 Lower level
-- return a refreshed unit list, else return nil
function RefreshUnitList(attacker, commandTTL)
	local stdDecloakDist = stdDecloakDist_fG
	----------------------------------------------------------
	local allMyUnits = spGetTeamUnits(myTeamID_gbl)
	local arrayIndex=1
	local relevantUnit={}
	local selectedUnits	= (spGetSelectedUnits()) or {}
	local selectedUnits_Meta = {}
	local selectedCons_Meta = {}
	for i = 1, #selectedUnits, 1 do
		local unitID = selectedUnits[i]
		selectedUnits_Meta[unitID]=true
	end
	local metaForVisibleUnits = {}
	local visibleUnits=spGetVisibleUnits(myTeamID_gbl)
	for _, unitID in ipairs(visibleUnits) do --memorize units that is in view of camera
		metaForVisibleUnits[unitID]="yes" --flag "yes" for visible unit (in view) and by default flag "nil" for out of view unit
	end
	for _, unitID in ipairs(allMyUnits) do
		if unitID~=nil then --skip end of the table
			-- additional hitchiking function: refresh attacker's list
			attacker = RetrieveAttackerList (unitID, attacker)
			-- additional hitchiking function: refresh WATCHDOG's list
			commandTTL = RefreshWatchdogList (unitID, commandTTL)
			--
			local unitDefID = spGetUnitDefID(unitID)
			local unitDef = UnitDefs[unitDefID]
			local unitSpeed =unitDef["speed"]
			local decloakScaling = math.max((unitDef["decloakDistance"] or 0),stdDecloakDist)/stdDecloakDist
			local unitInView = metaForVisibleUnits[unitID] --transfer "yes" or "nil" from meta table into a local variable
			if (unitSpeed>0) then
				local unitType = 0 --// category that control WHEN avoidance is activated for each unit. eg: Category 2 only enabled when not in view & when guarding units. Used by 'GateKeeperOrCommandFilter()'
				local fixedPointType = 1 --//category that control WHICH avoidance behaviour to use. eg: Category 2 priotize avoidance and prefer to ignore user's command when enemy is close. Used by 'CheckWhichFixedPointIsStable()'
				if (unitDef["builder"] or unitDef["canCloak"]) and not unitDef.customParams.commtype then --include only constructor and cloakies, and not com
					unitType =1 --//this unit-type will do avoidance even in camera view
					
					local isBuilder_ignoreTrue = false
					if unitDef["builder"] then
						isBuilder_ignoreTrue = (options.dbg_IgnoreSelectedCons.value == true and selectedUnits_Meta[unitID] == true) --is (epicMenu force-selection-ignore is true? AND unit is a constructor?)
						if selectedUnits_Meta[unitID] then
							selectedCons_Meta[unitID] = true --remember selected Constructor
						end
					end
					if (unitDef["builder"] and options.enableCons.value==false) or (isBuilder_ignoreTrue) then --//if ((Cons epicmenu option is false) OR (epicMenu force-selection-ignore is true)) AND it is a constructor, then... exclude (this) Cons
						unitType = 0 --//this unit-type excluded from avoidance
					end
					if unitDef["canCloak"] then --only cloakies + constructor that is cloakies
						fixedPointType=2 --//use aggressive behaviour (avoid more & more likely to ignore the users)
						if options.enableCloaky.value==false or (isBuilder_ignoreTrue) then --//if (Cloaky option is false) OR (epicMenu force-selection-ignore is true AND unit is a constructor) then exclude Cloaky
							unitType = 0
						end
					end
				--elseif not unitDef["canFly"] and not unitDef["canSubmerge"] then --include all ground unit, but excluding com & amphibious
				elseif not unitDef["canFly"] then --include all ground unit, including com
					unitType =2 --//this unit type only have avoidance outside camera view & while reloading (in camera view)
					if options.enableGround.value==false then --//if Ground unit epicmenu option is false then exclude Ground unit
						unitType = 0
					end
				elseif (unitDef.hoverAttack== true) then --include gunships
					unitType =3 --//this unit-type only have avoidance outside camera view & while reloading (in camera view)
					if options.enableGunship.value==false then --//if Gunship epicmenu option is false then exclude Gunship
						unitType = 0
					end
				-- elseif not unitDef["canFly"] and unitDef["canSubmerge"] then --include all amphibious unit & com
					-- unitType =4 --//this unit type only have avoidance outside camera view
					-- if options.enableAmphibious.value==false then --//if Gunship epicmenu option is false then exclude Gunship
						-- unitType = 0
					-- end
				end
				if (unitType>0) then
					local unitShieldPower, reloadableWeaponIndex= -1, -1
					unitShieldPower, reloadableWeaponIndex = CheckWeaponsAndShield(unitDef)
					arrayIndex=arrayIndex+1
					relevantUnit[arrayIndex]={unitID, unitType, unitSpeed, fixedPointType, decloakScaling, isVisible = unitInView, unitShieldPower = unitShieldPower, reloadableWeaponIndex = reloadableWeaponIndex}
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
	if arrayIndex>1 then 
		relevantUnit[1]=arrayIndex -- store the array's lenght in the first row of the array
	else 
		relevantUnit[1] = nil 
	end --send out nil if no unit is present
	if (turnOnEcho == 1) then
		Spring.Echo("allMyUnits(RefreshUnitList): ")
		Spring.Echo(allMyUnits)
		Spring.Echo("relevantUnit(RefreshUnitList): ")
		Spring.Echo(relevantUnit)
	end
	return relevantUnit, attacker, commandTTL, selectedCons_Meta
end

-- detect initial enemy separation to detect "fleeing enemy"  later
function GetPreliminarySeparation(unitInMotion,commandIndexTable, attacker, selectedCons_Meta)
	local surroundingOfActiveUnit={}
	if unitInMotion[1]~=nil then --don't execute if no unit present
		local arrayIndex=1
		for i=2, unitInMotion[1], 1 do --array index 1 contain the array's lenght, start from 2
			local unitID= unitInMotion[i][1] --get unitID for commandqueue
			if spGetUnitIsDead(unitID)==false then --prevent execution if unit died during transit
				local cQueue = spGetCommandQueue(unitID)
				local executionAllow, cQueueTemp, isReloadAvoidance = GateKeeperOrCommandFilter(unitID, cQueue, unitInMotion[i]) --filter/alter unwanted unit state by reading the command queue
				if executionAllow then
					cQueue = cQueueTemp --cQueueTemp has been altered for identification, copy it to cQueue for use (actual command is not yet issued)
					--local boxSizeTrigger= unitInMotion[i][2]
					local fixedPointCONSTANTtrigger = unitInMotion[i][4] --//using fixedPointType to trigger different fixed point constant for each unit type
					local unitVisible = (unitInMotion[i].isVisible == "yes")
					local targetCoordinate, commandIndexTable, newCommand, boxSizeTrigger, graphCONSTANTtrigger, fixedPointCONSTANTtrigger=IdentifyTargetOnCommandQueue(cQueue, unitID, commandIndexTable,fixedPointCONSTANTtrigger,unitVisible,isReloadAvoidance) --check old or new command
					local currentX,_,currentZ = spGetUnitPosition(unitID)
					local lastPosition = {currentX, currentZ} --record current position for use to determine unit direction later.
					if selectedCons_Meta[unitID] and boxSizeTrigger~= 4 then --if unitIsSelected and NOT using GUARD 'halfboxsize' (ie: is not guarding) then:
						boxSizeTrigger = 1 -- override all reclaim/ressurect/repair's deactivation 'halfboxsize' with the one for MOVE command (give more tolerance when unit is selected)
					end
					local reachedTarget = TargetBoxReached(targetCoordinate, unitID, boxSizeTrigger, lastPosition) --check if widget should ignore command
					local losRadius	= GetUnitLOSRadius(unitID) --get LOS
					local surroundingUnits	= GetAllUnitsInRectangle(unitID, losRadius, attacker) --catalogue enemy
					if (cQueue[1].id == CMD_MOVE and not unitVisible) then --if unit has move Command and is outside user's view
						reachedTarget = false --force unit to continue avoidance despite close to target (try to circle over target until seen by user)
					end
					if reachedTarget then --if reached target
						commandIndexTable[unitID]=nil --empty the commandIndex (command history)
					end
					
					if surroundingUnits[1]~=nil and not reachedTarget then  --execute when enemy exist and target not reached yet
						--local unitType =unitInMotion[i][2]
						--local unitSSeparation, losRadius = CatalogueMovingObject(surroundingUnits, unitID, lastPosition, unitType, losRadius) --detect initial enemy separation & alter losRadius when unit submerged
						local unitSSeparation, losRadius = CatalogueMovingObject(surroundingUnits, unitID, lastPosition, losRadius) --detect initial enemy separation & alter losRadius when unit submerged
						arrayIndex=arrayIndex+1 --// increment table index by 1, start at index 2; table lenght is stored at row 1
						local unitSpeed = unitInMotion[i][3]
						local decloakScaling = unitInMotion[i][5]
						local impatienceTrigger,commandIndexTable = GetImpatience(newCommand,unitID, commandIndexTable)
						surroundingOfActiveUnit[arrayIndex]={unitID, unitSSeparation, targetCoordinate, losRadius, cQueue, newCommand, unitSpeed,impatienceTrigger, lastPosition, graphCONSTANTtrigger, fixedPointCONSTANTtrigger, decloakScaling} --store result for next execution
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
function DoCalculation (surroundingOfActiveUnit,commandIndexTable, attacker, skippingTimer, now, commandTTL)
	local isAvoiding = nil
	if surroundingOfActiveUnit[1]~=nil then --if flagged as nil then no stored content then this mean there's no relevant unit
		for i=2,surroundingOfActiveUnit[1], 1 do --index 1 is for array's lenght
			local unitID=surroundingOfActiveUnit[i][1]
			if spGetUnitIsDead(unitID)==false then --prevent unit death from short circuiting the system
				local unitSSeparation=surroundingOfActiveUnit[i][2]
				local targetCoordinate=surroundingOfActiveUnit[i][3]
				local losRadius=surroundingOfActiveUnit[i][4]
				local cQueue=surroundingOfActiveUnit[i][5]
				local newCommand=surroundingOfActiveUnit[i][6]
				
				--do sync test. Ensure stored command not changed during last delay. eg: it change if user issued new command
				local cQueueSyncTest = spGetCommandQueue(unitID)
				local needToCancelOrder = false
				if cQueueSyncTest ~= nil then
					if #cQueueSyncTest>=2 then --if new command is longer than or equal to 2 (eg: 1st = any command, 2nd = stop command) then it is indicative of user's NEW command (command like auto-attack or idle has only 1 queue and should be ignored as an overriding force).
						--if #cQueueSyncTest~=#cQueue or --if command queue lenght is not same as original (is indicative of user's NEW command, but may just mean that user queued new command on top of old one) 
						if (cQueueSyncTest[1].params[1]~=cQueue[1].params[1] or cQueueSyncTest[1].params[3]~=cQueue[1].params[3]) or -- if first queue has different content (is definitive of user's NEW command)
						(cQueueSyncTest[1]==nil) then --or, if somehow the unit queued an idle state (not sure...)
							--newCommand=true
							--cQueue=cQueueSyncTest
							commandIndexTable[unitID]=nil --empty commandIndex (command history) for this unit. CommandIndex store widget's previous command, which become irrelevant when user override the widget.
							if (not newCommand) then --if the last command was made by this widget:
								commandTTL[unitID][#commandTTL[unitID]]=nil --delete the last watchdog's entry for this unit. That last entry contain a timeout-info on unit's last command, but user has overriden that unit's last command.
							end
							needToCancelOrder = true --skip widget's command
						end
					end
				else Spring.Echo("Dynamic Avoidance: cQueueSyncTest == nil!") --//under an unknown circumstances the unit's commandQueue became nil (??).
				end
				if not needToCancelOrder then --//if unit receive new command then widget need to stop issuing command based on old information. This prevent user from being annoyed by widget overriding their command.
					local unitSpeed= surroundingOfActiveUnit[i][7]
					local impatienceTrigger= surroundingOfActiveUnit[i][8]
					local lastPosition = surroundingOfActiveUnit[i][9]
					local newSurroundingUnits	= GetAllUnitsInRectangle(unitID, losRadius, attacker) --get the latest unit list (rather than using the preliminary list) to ensure reliable avoidance
					local graphCONSTANTtrigger = surroundingOfActiveUnit[i][10] --//fetch information on which aCONSTANT and obsCONSTANT to use
					local fixedPointCONSTANTtrigger = surroundingOfActiveUnit[i][11] --//fetch information on which fixedPoint constant to use
					local decloakScaling = surroundingOfActiveUnit[i][12]
					if (newSurroundingUnits[1] ~=nil) then --//check again if there's still any enemy to avoid. Submerged unit might return empty list if their enemy has no Sonar (their 'losRadius' became half the original value so that they don't detect/avoid unnecessarily). 
						local avoidanceCommand = true
						local orderArray = {nil}
						commandTTL, avoidanceCommand,orderArray= InsertCommandQueue(cQueue, unitID, newCommand, now, commandTTL)--delete old widget command, update commandTTL, and send constructor to base for retreat
						if avoidanceCommand or (not options.dbg_RemoveAvoidanceSplitSecond.value) then 
							local newX, newZ = AvoidanceCalculator(unitID, targetCoordinate,losRadius,newSurroundingUnits, unitSSeparation, unitSpeed, impatienceTrigger, lastPosition, graphCONSTANTtrigger, skippingTimer, fixedPointCONSTANTtrigger, newCommand,decloakScaling) --calculate move solution
							local newY=spGetGroundHeight(newX,newZ)
							--Inserting command queue:--
							orderArray[#orderArray+1]={CMD_INSERT, {0, CMD_MOVE, CMD_OPT_INTERNAL, newX, newY, newZ}, {"alt"}} --spGiveOrderToUnit(unitID, CMD_INSERT, {0, CMD_MOVE, CMD_OPT_INTERNAL, newX, newY, newZ}, {"alt"} ) --insert new command
							commandTTL[unitID][#commandTTL[unitID]+1] = {countDown = commandTimeoutG, widgetCommand= {newX, newZ}} --//remember this command on watchdog's commandTTL table. It has 4x*RefreshUnitUpdateRate* to expire
							commandIndexTable[unitID]["widgetX"]=newX --update the memory table. So that next update can use to check if unit has new or old (widget's) command
							commandIndexTable[unitID]["widgetZ"]=newZ
							--end--
							if (turnOnEcho == 1) then
								Spring.Echo("newX(Update) " .. newX)
								Spring.Echo("newZ(Update) " .. newZ)
							end
						end
						if #orderArray >0 then
							spGiveOrderArrayToUnitArray ({unitID},orderArray)
							isAvoiding = true
						end
					end
				end
			end
		end
	end
	return commandIndexTable, commandTTL, isAvoiding
end

function widget:RecvLuaMsg(msg, playerID) --receive echo from server ('LUA message Receive')
	if msg:sub(1,3) == dummyIDg and playerID == myPlayerID then
		local skippingTimer = skippingTimerG
		-----
		
		--Spring.Echo(dummyIDg)
		skippingTimer.networkDelay = spGetGameSeconds() - skippingTimer.echoTimestamp --get the delay between previous Command and the latest 'LUA message Receive'
		--Method 1: use simple average [[
		--skippingTimer.sumOfAllNetworkDelay=skippingTimer.sumOfAllNetworkDelay + skippingTimer.networkDelay --sum all the delay ever recorded
		--skippingTimer.sumCounter = skippingTimer.sumCounter + 1 --count all the delay ever recorded
		--]]
		
		--Method 2: use rolling average [[
		skippingTimer.storedDelay[skippingTimer.index] = skippingTimer.networkDelay --store network delay value in a rolling table
		skippingTimer.index = skippingTimer.index+1 --table index ++
		if skippingTimer.index >= 12 then --roll the table/wrap around, so that the index circle the table. The 11-th sequence is for storing the oldest value, 1-st to 10-th sequence is for the average
			skippingTimer.index = 1
		end
		skippingTimer.averageDelay = skippingTimer.averageDelay + skippingTimer.networkDelay/10 - (skippingTimer.storedDelay[skippingTimer.index] or 0.3)/10 --add new delay and minus old delay, also use 0.3sec as the old delay if nothing is stored yet.
		--]]
		roundTripComplete = true --unlock system
		
		-----
		skippingTimerG = skippingTimer
	end
end

function ReportedNetworkDelay(playerIDa, defaultDelay)
	local _,_,_,_,_,totalDelay,_,_,_,_= Spring.GetPlayerInfo(playerIDa)
	if totalDelay==nil or totalDelay<=defaultDelay then return defaultDelay --if ping is too low: set the minimum delay
	else return totalDelay --take account for lag + wait a little bit for any command to properly update
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
			attacker[unitID].countDown = attacker[unitID].countDown + 3 --//add 3xUnitRefresh-rate (~3.3second) to attacker's TTL
			attacker[unitID].id = attackerID
		end
	end
	attacker[unitID].myHealth = unitHealth --refresh health data	
	return attacker
end

function RefreshWatchdogList (unitID, commandTTL)
	if commandTTL[unitID] == nil then --if commandTTL table is empty then insert an empty table
		commandTTL[unitID] = {}
	else --//if commandTTL is not empty then perform check and update its content appropriately. Its not empty when widget has issued a new command

		--//Method1: the following function do work offline but not online because widget's command appears delayed (latency) and this cause missmatch with what commandTTL expect to see: it doesn't see the command thus it assume the command already been deleted.
		--[[
		local cQueue = spGetCommandQueue(unitID, 1)
		for i=#commandTTL[unitID], 1, -1 do
			local firstParam, secondParam = 0, 0
			if cQueue[1]~=nil then
				firstParam, secondParam = cQueue[1].params[1], cQueue[1].params[3]
			end
			if (firstParam == commandTTL[unitID][i].widgetCommand[1]) and (secondParam == commandTTL[unitID][i].widgetCommand[2]) then --//if current command is similar to the one once issued by widget then countdown its TTL
				if commandTTL[unitID][i].countDown >0 then 
					commandTTL[unitID][i].countDown = commandTTL[unitID][i].countDown - 1 --count-down until zero and stop
				elseif commandTTL[unitID][i].countDown ==0 then --if commandTTL is found to reach ZERO then remove the command, assume a 'TIMEOUT', then remove *this* watchdog entry
					spGiveOrderToUnit(unitID, CMD_REMOVE, {cQueue[1].tag}, {} )
					commandTTL[unitID][i] = nil
				end
				break --//exit the iteration, save the rest of the commandTTL for checking on next update/next cQueue. Since later commandTTL is for cQueue[2](next qeueu) then it is more appropriate to compare it later (currently we only check cQueue[1] for timeout/expiration).
			else --//if current command is a NEW command (not similar to the one catalogued in commandTTL as widget-issued), then delete this watchdog entry. LUA Operator "#" will automatically register the 'nil' as 'end of table' for future updates
				commandTTL[unitID][i] = nil
				--commandTTL[unitID][i].miss = commandTTL[unitID][i].miss +1 --//when unit's command doesn't match the one on watchdog-list then mark the entry as "miss"+1 .  
			end
		end
		--]]
		
		--//Method2: work by checking for cQueue after the command has expired. No latency could be as long as command's expiration time so it solve Method1's issue.
		local returnToReclaimOffset = 1 --
		for i=#commandTTL[unitID], 1, -1 do --iterate over commandTTL
			if commandTTL[unitID][i] ~= nil then
				if commandTTL[unitID][i].countDown >0 then 
					commandTTL[unitID][i].countDown = commandTTL[unitID][i].countDown - (1*returnToReclaimOffset) --count-down until zero and stop
					break --//exit the iteration, do not go to next iteration until this entry expire first... 
				elseif commandTTL[unitID][i].countDown ==0 then --if commandTTL is found to reach ZERO then remove the command, assume a 'TIMEOUT', then remove *this* watchdog entry
					local cQueue = spGetCommandQueue(unitID, 1) --// get unit's immediate command
					local firstParam, secondParam = 0, 0
					if cQueue[1]~=nil then
						firstParam, secondParam = cQueue[1].params[1], cQueue[1].params[3] --if cQueue not empty then use it... x, z,
					end
					if (firstParam == commandTTL[unitID][i].widgetCommand[1]) and (secondParam == commandTTL[unitID][i].widgetCommand[2]) then --//if current command is similar to the one once issued by widget then delete it
						spGiveOrderToUnit(unitID, CMD_REMOVE, {cQueue[1].tag}, {} )
					end
					commandTTL[unitID][i] = nil --empty watchdog entry
					returnToReclaimOffset = 2 --when the loop iterate back to a reclaim command: remove 2 second from its countdown (accelerate expiration by 2 second). This is for aesthetic reason and didn't effect system's mechanic.  Since constructor always retreat with 2 command (avoidance+return to base), remove the countdown from the avoidance. 
				end
			end
		end		
	end
	return commandTTL
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
	local returnReload = false -- indicate to way way downstream processes whether avoidance is based on weapon reload/shieldstate 
	if cQueue~=nil then --prevent ?. Forgot...
		local isReloading = CheckIfUnitIsReloading(unitInMotionSingleUnit) --check if unit is reloading/shieldCritical
		local state=spGetUnitStates(unitID)
		local holdPosition= (state.movestate == 0)
		if ((unitInMotionSingleUnit.isVisible ~= "yes") or isReloading) then --if unit is out of user's vision OR is reloading, and: 
			if (cQueue[1] == nil or #cQueue == 1) then --if unit is currently idle OR with-singular-mono-command (eg: automated move order or auto-attack), and:
				if (holdPosition== false) then --if unit is not "hold position", then:
					cQueue={{id = cMD_DummyG, params = {-1 ,-1,-1}, options = {}}, {id = CMD_STOP, params = {-1 ,-1,-1}, options = {}}, nil} --flag unit with a FAKE COMMAND. Will be used to initiate avoidance on idle unit & non-viewed unit. Note: this is not real command, its here just to trigger avoidance.
				end
			end
		end
		if cQueue[1]~=nil then --prevent idle unit from executing the system (prevent crash), but idle unit with FAKE COMMAND (cMD_DummyG) is allowed.
			local isValidCommand = (cQueue[1].id == 40 or cQueue[1].id < 0 or cQueue[1].id == 90 or cQueue[1].id == CMD_MOVE or cQueue[1].id == 125 or  cQueue[1].id == cMD_DummyG) -- ALLOW unit with command: repair (40), build (<0), reclaim (90), ressurect(125), move(10), or FAKE COMMAND
			--local isValidUnitTypeOrIsNotVisible = (unitInMotionSingleUnit[2] == 1) or (unitInMotionSingleUnit.isVisible ~= "yes" and unitInMotionSingleUnit[2]~= 3)--ALLOW only unit of unitType=1 OR (all unitTypes that is outside player's vision except gunship)
			local isValidUnitTypeOrIsNotVisible = (unitInMotionSingleUnit[2] == 1) or (unitInMotionSingleUnit.isVisible ~= "yes")--ALLOW unit of unitType=1 (cloaky, constructor) OR all unitTypes that is outside player's vision
			local _2ndAttackSignature = false --attack command signature
			local _2ndGuardSignature = false --guard command signature
			if #cQueue >=2 then --check if the command-queue is masked by widget's previous command, but the actual originality check will be performed by TargetBoxReached() later.
				_2ndAttackSignature = (cQueue[1].id == CMD_MOVE and cQueue[2].id == CMD_ATTACK)
				_2ndGuardSignature = (cQueue[1].id == CMD_MOVE and cQueue[2].id == CMD_GUARD)
			end
			local isReloadingAttack = (isReloading and (cQueue[1].id == CMD_ATTACK or cQueue[1].id == cMD_DummyG or _2ndAttackSignature)) --any unit with attack command or was idle that is Reloading
			local isGuardState = (cQueue[1].id == CMD_GUARD or _2ndGuardSignature)
			if (isValidCommand and isValidUnitTypeOrIsNotVisible) or (isReloadingAttack and not holdPosition) or (isGuardState) then --execute on: repair (40), build (<0), reclaim (90), ressurect(125), move(10), or FAKE idle COMMAND for: UnitType==1 or for: any unit outside visibility... or on any unit with any command which is reloading.
				local isReloadAvoidance = (isReloadingAttack and not holdPosition)
				if isReloadAvoidance or #cQueue>=2 then --check cQueue for lenght to prevent STOP command from short circuiting the system 
					if isReloadAvoidance or cQueue[2].id~=false then --prevent a spontaneous enemy engagement from short circuiting the system
						allowExecution = true --allow execution
						returnReload = isReloadAvoidance
					end --if cQueue[2].id~=false
					if (turnOnEcho == 1) then Spring.Echo(cQueue[2].id) end --for debugging
				end --if #cQueue>=2
			end --if ((cQueue[1].id==40 or cQueue[1].id<0 or cQueue[1].id==90 or cQueue[1].id==10 or cQueue[1].id==125) and (unitInMotion[i][2]==1 or unitInMotion[i].isVisible == nil)
		end --if cQueue[1]~=nil
	end --if cQueue~=nil	
	return allowExecution, cQueue,returnReload --disallow/allow execution
end

--check if widget's command or user's command
function IdentifyTargetOnCommandQueue(cQueue, unitID,commandIndexTable, fixedPointCONSTANTtrigger,unitVisible,isReloadAvoidance) --//used by GetPreliminarySeparation()
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
		commandIndexTable, targetCoordinate, boxSizeTrigger, graphCONSTANTtrigger,fixedPointCONSTANTtrigger = ExtractTarget (1, unitID,cQueue,commandIndexTable,targetCoordinate,fixedPointCONSTANTtrigger,unitVisible,isReloadAvoidance)
		commandIndexTable[unitID]["patienceIndexA"]=0 --//reset impatience counter
	else  --if widget's previous command
		commandIndexTable, targetCoordinate, boxSizeTrigger, graphCONSTANTtrigger,fixedPointCONSTANTtrigger = ExtractTarget (2, unitID,cQueue,commandIndexTable,targetCoordinate,fixedPointCONSTANTtrigger,unitVisible,isReloadAvoidance)	
	end
	return targetCoordinate, commandIndexTable, newCommand, boxSizeTrigger, graphCONSTANTtrigger, fixedPointCONSTANTtrigger --return target coordinate
end

--ignore command set on this box
function TargetBoxReached (targetCoordinate, unitID, boxSizeTrigger, lastPosition)
	----Global Cpnstant----
	local halfTargetBoxSize = halfTargetBoxSize_g
	-----------------------
	local currentX, currentZ = lastPosition[1], lastPosition[2]
	local targetX = dNil(targetCoordinate[1]) -- use dNil if target asynchronously/spontaneously disappear: in that case it will replace "nil" with -1 
	local targetZ =targetCoordinate[3]
	if targetX==-1 then 
		return false 
	end --if target is invalid (-1) then assume target not-yet-reached, return false (default state), and continue avoidance 
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
	local withinTargetBox = (xDistanceToTarget<=halfTargetBoxSize[boxSizeTrigger] and zDistanceToTarget<=halfTargetBoxSize[boxSizeTrigger])
	return withinTargetBox --command outside this box return false
end

-- get LOS
function GetUnitLOSRadius(unitID)
	local unitDefID= spGetUnitDefID(unitID)
	local unitDef= UnitDefs[unitDefID]
	local losRadius =550 --arbitrary (scout LOS)
	if unitDef~=nil then --if unitDef is not empty then use the following LOS
		losRadius= unitDef.losRadius*32 --for some reason it was times 32
		if unitDef["builder"] then losRadius = losRadius + extraLOSRadiusCONSTANTg end --add additional detection range for constructors
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
		if (rectangleUnitID ~= unitID) and not isAlly then --filter out ally units and self
			local rectangleUnitTeamID = spGetUnitTeam(rectangleUnitID)
			if (rectangleUnitTeamID ~= gaiaTeamID) then --filter out gaia (non aligned unit)
				local recUnitDefID = spGetUnitDefID(rectangleUnitID)
				local registerEnemy = false
				if recUnitDefID~=nil and (iAmConstructor and iAmNotCloaked) then --if enemy is in LOS & I am a visible constructor: then
					local recUnitDef = UnitDefs[recUnitDefID] --retrieve enemy definition
					local enemyParalyzed,_,_ = spGetUnitIsStunned (rectangleUnitID)
					if recUnitDef["weapons"][1]~=nil and not enemyParalyzed then -- check enemy for weapons and paralyze effect
						registerEnemy = true --register the enemy only if it armed & wasn't paralyzed
					end
				else --if enemy is detected (in LOS or RADAR), and iAm a generic units OR any cloaked constructor then:
					if iAmNotCloaked then --if I am not cloaked
						local enemyParalyzed,_,_ = Spring.GetUnitIsStunned (rectangleUnitID)
						if not enemyParalyzed then -- check for paralyze effect
							registerEnemy = true --register enemy if it's not paralyzed
						end
					else --if I am cloaked (constructor or cloakies), then:
						registerEnemy = true --register all enemy (avoid all unit)
					end
				end
				if registerEnemy then
					arrayIndex=arrayIndex+1
					relevantUnit[arrayIndex]=rectangleUnitID --register enemy
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
function CatalogueMovingObject(surroundingUnits, unitID, lastPosition, losRadius)
	local unitsSeparation={}
	if (surroundingUnits[1]~=nil) then --don't catalogue anything if no enemy exist
		local unitDepth = 99
		local sonarDetected = false
		local halfLosRadius = losRadius/2
		--if unitType == 4 then --//if unit is amphibious, then:
			_,unitDepth,_ = spGetUnitPosition(unitID) --//get unit's y-axis. Less than 0 mean submerged.
		--end
		for i=2,surroundingUnits[1],1 do --//iterate over all enemy list.
			local unitRectangleID=surroundingUnits[i]
			if (unitRectangleID ~= nil) then
				local relativeAngle 	= GetUnitRelativeAngle (unitID, unitRectangleID)
				local unitDirection,_,_	= GetUnitDirection(unitID, lastPosition)
				local unitSeparation	= spGetUnitSeparation (unitID, unitRectangleID, true)
				if math.abs(unitDirection- relativeAngle)< (collisionAngleG) then --unit inside the collision angle is catalogued with a value that is useful for comparision later
					unitsSeparation[unitRectangleID]=unitSeparation
				else --unit outside the collision angle is set to an arbitrary 999 which is not useful for comparision later
					unitsSeparation[unitRectangleID]=999 --set saperation distance to 999 such that later comparison (which is always smaller than this) imply an approaching units
				end
				if unitDepth <0 then --//if unit is submerged, then:
					--local enemySonarRadius = (spGetUnitSensorRadius(unitRectangleID,"sonar") or 0)
					local enemyDefID = spGetUnitDefID(unitRectangleID)
					local unitDefsSonarContent = 999 --//set to very large so that any un-identified contact is assumed as having sonar (as threat). 
					if UnitDefs[enemyDefID]~=nil then
						unitDefsSonarContent = UnitDefs[enemyDefID].sonarRadius
					end
					local enemySonarRadius = (unitDefsSonarContent or 0)
					if enemySonarRadius > halfLosRadius then --//check enemy for sonar
						sonarDetected = true
					end
				end
			end
		end
		if (not sonarDetected) and (unitDepth < 0) then --//if enemy doesn't have sonar but Iam still submerged, then:
			losRadius = halfLosRadius --// halven the unit's 'avoidance' range. Don't need to avoid enemy if enemy are blind.
		end
	end
	if (turnOnEcho == 1) then
		Spring.Echo("unitSeparation(CatalogueMovingObject):")
		Spring.Echo(unitsSeparation)
	end
	return unitsSeparation, losRadius
end

function GetImpatience(newCommand, unitID, commandIndexTable)
	local impatienceTrigger=1 --zero will de-activate auto reverse
	if commandIndexTable[unitID]["patienceIndexA"]>=6 then impatienceTrigger=0 end --//if impatience index level 6 (after 6 time avoidance) then trigger impatience. Impatience will deactivate/change some values downstream
	if not newCommand and activateImpatienceG==1 then
		commandIndexTable[unitID]["patienceIndexA"]=commandIndexTable[unitID]["patienceIndexA"]+1 --increase impatience index if impatience system is activate
	end
	if (turnOnEcho == 1) then Spring.Echo("commandIndexTable[unitID][patienceIndexA] (GetImpatienceLevel) " .. commandIndexTable[unitID]["patienceIndexA"]) end
	return impatienceTrigger, commandIndexTable
end

function AvoidanceCalculator(unitID, targetCoordinate, losRadius, surroundingUnits, unitsSeparation, unitSpeed, impatienceTrigger, lastPosition, graphCONSTANTtrigger, skippingTimer, fixedPointCONSTANTtrigger, newCommand, decloakScaling)
	if (unitID~=nil) and (targetCoordinate ~= nil) then --prevent idle/non-existent/ unit with invalid command from using collision avoidance
		local aCONSTANT 								= aCONSTANTg --attractor constant (amplitude multiplier)
		local obsCONSTANT 								=obsCONSTANTg --repulsor constant (amplitude multiplier)
		local unitDirection, _, usingLastPosition		= GetUnitDirection(unitID, lastPosition) --get unit direction
		local targetAngle = 0
		local fTarget = 0
		local fTargetSlope = 0
		----
		aCONSTANT = aCONSTANT[graphCONSTANTtrigger[1]] --//select which 'aCONSTANT' value
		obsCONSTANT = obsCONSTANT[graphCONSTANTtrigger[2]]*decloakScaling --//select which 'obsCONSTANT' value to use & increase obsCONSTANT value when unit has larger decloakDistance than reference unit (Scythe).
		
		fTarget = aCONSTANT --//maximum value is aCONSTANT
		fTargetSlope = 1 --//slope is negative or positive
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
		wTotal, dSum, fObstacleSum,dFobstacle,nearestFrontObstacleRange, normalizingFactor=SumAllUnitAroundUnitID (unitID, surroundingUnits, unitDirection, wTotal, dSum, fObstacleSum,dFobstacle,nearestFrontObstacleRange, unitsSeparation, impatienceTrigger, graphCONSTANTtrigger, losRadius,obsCONSTANT)
		--calculate appropriate behaviour based on the constant and above summation value
		local wTarget, wObstacle = CheckWhichFixedPointIsStable (fTargetSlope, dFobstacle, dSum, fTarget, fObstacleSum, wTotal, fixedPointCONSTANTtrigger)
		--convert an angular command into a coordinate command
		local newX, newZ= SendCommand(unitID, wTarget, wObstacle, fTarget, fObstacleSum, unitDirection, nearestFrontObstacleRange, losRadius, unitSpeed, impatienceTrigger, normalizingFactor, skippingTimer, usingLastPosition, newCommand)
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
function InsertCommandQueue(cQueue, unitID, newCommand, now, commandTTL)
	------- localize global constant:
	local consRetreatTimeout = consRetreatTimeoutG
	local commandTimeout = commandTimeoutG
	------- end global constant
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
	local orderArray={nil,nil,nil,nil,nil,nil}
	local queueIndex=1
	local avoidanceCommand = true
	if not newCommand then  --if widget's command then delete it
		orderArray[1] = {CMD_REMOVE, {cQueue[1].tag}, {}} --spGiveOrderToUnit(unitID, CMD_REMOVE, {cQueue[1].tag}, {} ) --delete previous widget command
		queueIndex=2 --skip index 1 of stored command. Skip widget's command
		commandTTL[unitID][#commandTTL[unitID]] = nil --//delete the last watchdog entry (the "not newCommand" means that previous widget's command haven't changed yet (nothing has interrupted this unit, same is with commandTTL), and so if command is to delete then it is good opportunity to also delete its timeout info at *commandTTL* too). Deleting this entry mean that this particular command will no longer be checked for timeout.
	end
	if #cQueue>=queueIndex+1 then --reclaim,area reclaim,stop, or: move,reclaim, area reclaim,stop, or: area reclaim, stop, or:move, area reclaim, stop.
		if (cQueue[queueIndex].id==40 or cQueue[queueIndex].id==90 or cQueue[queueIndex].id==125) then --if first (1) queue is reclaim/ressurect/repair
			if cQueue[queueIndex+1].id==90 or cQueue[queueIndex+1].id==125 then --if second (2) queue is also reclaim/ressurect
				--if (not Spring.ValidFeatureID(cQueue[queueIndex+1].params[1]-wreckageID_offset) or (not Spring.ValidFeatureID(cQueue[queueIndex+1].params[1]))) and not Spring.ValidUnitID(cQueue[queueIndex+1].params[1]) then --if it was an area command
				if (cQueue[queueIndex+1].params[3]~=nil) then  --second (2) queue is area reclaim. area command should has no "nil" on params 1,2,3, & 4
					orderArray[#orderArray+1] = {CMD_REMOVE, {cQueue[queueIndex].tag}, {}} -- spGiveOrderToUnit(unitID, CMD_REMOVE, {cQueue[queueIndex].tag}, {} ) --delete latest reclaiming/ressurecting command (skip the target:wreck/units). Allow command reset
					local coordinate = (FindSafeHavenForCons(unitID, now)) or  (cQueue[queueIndex+1])
					orderArray[#orderArray+1] = {CMD_INSERT, {0, CMD_MOVE, CMD_OPT_INTERNAL, coordinate.params[1], coordinate.params[2], coordinate.params[3]}, {"alt"}} --spGiveOrderToUnit(unitID, CMD_INSERT, {0, CMD_MOVE, CMD_OPT_INTERNAL, coordinate.params[1], coordinate.params[2], coordinate.params[3]}, {"alt"} ) --divert unit to the center of reclaim/repair command OR to any heavy concentration of ally (haven)
					commandTTL[unitID][#commandTTL[unitID] +1] = {countDown = consRetreatTimeout, widgetCommand= {coordinate.params[1], coordinate.params[3]}} --//remember this command on watchdog's commandTTL table. It has 15x*RefreshUnitUpdateRate* to expire
					avoidanceCommand = false
				end
			elseif cQueue[queueIndex+1].id==40 then --if second (2) queue is also repair
				--if (not Spring.ValidFeatureID(cQueue[queueIndex+1].params[1]-wreckageID_offset) or (not Spring.ValidFeatureID(cQueue[queueIndex+1].params[1]))) and not Spring.ValidUnitID(cQueue[queueIndex+1].params[1]) then --if it was an area command
				if (cQueue[queueIndex+1].params[3]~=nil) then  --area command should has no "nil" on params 1,2,3, & 4
					orderArray[#orderArray+1] = {CMD_REMOVE, {cQueue[queueIndex].tag}, {}} --spGiveOrderToUnit(unitID, CMD_REMOVE, {cQueue[queueIndex].tag}, {} ) --delete current repair command, (skip the target:units). Reset the repair command
				end
			elseif (cQueue[queueIndex].params[3]~=nil) then  --if first (1) queue is area reclaim (an area reclaim without any wreckage to reclaim). area command should has no "nil" on params 1,2,3, & 4
				local coordinate = (FindSafeHavenForCons(unitID, now)) or  (cQueue[queueIndex])
				orderArray[#orderArray+1] = {CMD_INSERT, {0, CMD_MOVE, CMD_OPT_INTERNAL, coordinate.params[1], coordinate.params[2], coordinate.params[3]}, {"alt"}} --spGiveOrderToUnit(unitID, CMD_INSERT, {0, CMD_MOVE, CMD_OPT_INTERNAL, coordinate.params[1], coordinate.params[2], coordinate.params[3]}, {"alt"} ) --divert unit to the center of reclaim/repair command
				commandTTL[unitID][#commandTTL[unitID]+1] = {countDown = commandTimeout, widgetCommand= {coordinate.params[1], coordinate.params[3]}} --//remember this command on watchdog's commandTTL table. It has 2x*RefreshUnitUpdateRate* to expire
				avoidanceCommand = false
			end
		end
	end
	if (turnOnEcho == 1) then
		Spring.Echo("unitID(InsertCommandQueue)" .. unitID)
		--Spring.Echo("commandIndexTable[unitID][widgetX](InsertCommandQueue):" .. commandIndexTable[unitID]["widgetX"])
		--Spring.Echo("commandIndexTable[unitID][widgetZ](InsertCommandQueue):" .. commandIndexTable[unitID]["widgetZ"])
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
	return commandTTL, avoidanceCommand, orderArray --return updated memory tables. One for checking if new command is issued and another is to check for command's expiration age.
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

function ExtractTarget (queueIndex, unitID, cQueue, commandIndexTable, targetCoordinate, fixedPointCONSTANTtrigger,unitVisible,isReloadAvoidance) --//used by IdentifyTargetOnCommandQueue()
	local boxSizeTrigger=0 --an arbitrary constant/variable, which trigger some other action/choice way way downstream. The purpose is to control when avoidance must be cut-off using custom value (ie: 1,2,3,4) for specific cases.
	local graphCONSTANTtrigger = {}
	if (cQueue[queueIndex].id==CMD_MOVE or cQueue[queueIndex].id<0) then --move or building stuff
		local targetPosX, targetPosY, targetPosZ = -1, -1, -1 -- (-1) is default value because -1 represent "no target"
		if cQueue[queueIndex].params[1]~= nil and cQueue[queueIndex].params[2]~=nil and cQueue[queueIndex].params[3]~=nil then --confirm that the coordinate exist
			targetPosX, targetPosY, targetPosZ = cQueue[queueIndex].params[1], cQueue[queueIndex].params[2],cQueue[queueIndex].params[3]
		-- elseif cQueue[queueIndex].params[1]~= nil then --check whether its refering to a nanoframe
			-- local nanoframeID = cQueue[queueIndex].params[1]
			-- targetPosX, targetPosY, targetPosZ = spGetUnitPosition(nanoframeID)
			-- if (turnOnEcho == 2)then Spring.Echo("ExtractTarget, MoveCommand: is using nanoframeID") end
		else
			if (turnOnEcho == 2)then Spring.Echo("Dynamic Avoidance move target is nil: fallback to no target") end
		end
		boxSizeTrigger=1 --//avoidance deactivation 'halfboxsize' for MOVE command
		graphCONSTANTtrigger[1] = 1 --use standard angle scale (take ~10 cycle to do 180 flip, but more predictable)
		graphCONSTANTtrigger[2] = 1
		if #cQueue >= queueIndex+1 then
			if cQueue[queueIndex+1].id==90 or cQueue[queueIndex+1].id==125 then --//reclaim command has 2 stage: 1 is move back to base, 2 is going reclaim. If detected reclaim or ressurect at 2nd queue then identify as area reclaim
				if cQueue[queueIndex].params[1]==cQueue[queueIndex+1].params[1]
					and cQueue[queueIndex].params[2]==cQueue[queueIndex+1].params[2]
					and cQueue[queueIndex].params[3]==cQueue[queueIndex+1].params[3] then --area reclaim will have no "nil", and will equal to retreat coordinate when retreating to center of area reclaim.
					targetPosX, targetPosY, targetPosZ = -1, -1, -1 --//if area reclaim under the above condition, then avoid forever in presence of enemy, ELSE if no enemy (no avoidance): it reach retreat point and resume reclaiming
					boxSizeTrigger=1 --//avoidance deactivation 'halfboxsize' for MOVE command
				end
			end
		end
		targetCoordinate={targetPosX, targetPosY, targetPosZ } --send away the target for move command
		commandIndexTable[unitID]["backupTargetX"]=targetPosX --backup the target
		commandIndexTable[unitID]["backupTargetY"]=targetPosY
		commandIndexTable[unitID]["backupTargetZ"]=targetPosZ
	elseif cQueue[queueIndex].id==90 or cQueue[queueIndex].id==125 then --reclaim or ressurect
		-- local a = Spring.GetUnitCmdDescs(unitID, Spring.FindUnitCmdDesc(unitID, 90), Spring.FindUnitCmdDesc(unitID, 90))
		-- Spring.Echo(a[queueIndex]["name"])
		local wreckPosX, wreckPosY, wreckPosZ = -1, -1, -1 -- -1 is default value because -1 represent "no target"
		local notAreaMode = true
		local foundMatch = false
		--Method 1: set target to individual wreckage, else (if failed) revert to center of current area-command or to no target. *This method was used initially when constructor do not yet have retreat to base*
		--[[
		local targetFeatureID=-1
		local iterativeTest=1
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
		if foundMatch==false then --if no wreckage, no trees, no rock, and no unitID then use coordinate
			if cQueue[queueIndex].params[3] ~= nil then --area reclaim should has no "nil" on params 1,2,3, & 4
				wreckPosX, wreckPosY,wreckPosZ = cQueue[queueIndex].params[1], cQueue[queueIndex].params[2],cQueue[queueIndex].params[3]
				areaMode = true
			else
				Spring.Echo("Dynamic Avoidance reclaim targetting failure: fallback to no target")
			end
		end
		--]]
		
		--Method 2: set target to center of area command (also check for area command in next queue), else set target to wreckage or to no target. *This method assume retreat to base is a norm*
		-- [[
		if (cQueue[queueIndex].params[3] ~= nil) then --area reclaim should has no "nil" on params 1,2,3, & 4
			wreckPosX, wreckPosY,wreckPosZ = cQueue[queueIndex].params[1], cQueue[queueIndex].params[2],cQueue[queueIndex].params[3]
			notAreaMode = false
			foundMatch = true
		elseif (cQueue[queueIndex+1].params[3] ~= nil and (cQueue[queueIndex+1].id==90 or cQueue[queueIndex+1].id==125)) then --if next queue is an area-reclaim
			wreckPosX, wreckPosY,wreckPosZ = cQueue[queueIndex+1].params[1], cQueue[queueIndex+1].params[2],cQueue[queueIndex+1].params[3]
			notAreaMode = false
			foundMatch = true
		end
		if notAreaMode then
			if Spring.ValidUnitID(cQueue[queueIndex].params[1]) then --reclaim own unit?
				wreckPosX, wreckPosY, wreckPosZ = spGetUnitPosition(cQueue[queueIndex].params[1])
				foundMatch = true
			elseif Spring.ValidFeatureID(cQueue[queueIndex].params[1]) then --reclaim trees and rock?
				wreckPosX, wreckPosY, wreckPosZ = spGetFeaturePosition(cQueue[queueIndex].params[1])
				foundMatch = true
			else --if not own unit or trees or rock then:
				local targetFeatureID=cQueue[queueIndex].params[1]-wreckageID_offset --remove the game's offset. Reclaim wreck?
				if Spring.ValidFeatureID(targetFeatureID) then --reclaim wreck?
					wreckPosX, wreckPosY, wreckPosZ = spGetFeaturePosition(targetFeatureID)
					foundMatch = true
				elseif Spring.ValidUnitID(targetFeatureID) then --reclaim enemy?
					wreckPosX, wreckPosY, wreckPosZ = spGetUnitPosition(targetFeatureID)
					foundMatch = true
				end
			end		
		end
		if not foundMatch then --if no area-command, no wreckage, no trees, no rock, and no unitID then return error
			if (turnOnEcho == 2)then Spring.Echo("Dynamic Avoidance reclaim targetting failure: fallback to no target") end
		end
		--]]
		
		targetCoordinate={wreckPosX, wreckPosY,wreckPosZ} --use wreck/center-of-area-command as target
		commandIndexTable[unitID]["backupTargetX"]=wreckPosX --backup the target
		commandIndexTable[unitID]["backupTargetY"]=wreckPosY
		commandIndexTable[unitID]["backupTargetZ"]=wreckPosZ
		--graphCONSTANTtrigger[1] = 2 --use bigger angle scale for initial avoidance: after that is a MOVE command to the center or area-command which uses standard angle scale (take ~4 cycle to do 180 flip, but more chaotic) 
		--graphCONSTANTtrigger[2] = 2
		graphCONSTANTtrigger[1] = 1 --use standard angle scale (take ~10 cycle to do 180 flip, but more predictable)
		graphCONSTANTtrigger[2] = 1
		boxSizeTrigger=2 --use deactivation 'halfboxsize' for RECLAIM/RESSURECT command
		
		--if not areaMode and (cQueue[queueIndex+1].params[3]==nil or cQueue[queueIndex+1].id == CMD_STOP) then --*used by Method 1* signature for discrete RECLAIM/RESSURECT command.
		if notAreaMode then --*used by Method 2*
			boxSizeTrigger = 1 --change to deactivation 'halfboxsize' similar to MOVE command if user queued a discrete reclaim/ressurect command
			--graphCONSTANTtrigger[1] = 1 --override: use standard angle scale (take ~10 cycle to do 180 flip, but more predictable)
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
			if (turnOnEcho == 2)then Spring.Echo("Dynamic Avoidance repair targetting failure: fallback to no target") end
		end
		targetCoordinate={unitPosX, unitPosY,unitPosZ} --use ally unit as target
		commandIndexTable[unitID]["backupTargetX"]=unitPosX --backup the target
		commandIndexTable[unitID]["backupTargetY"]=unitPosY
		commandIndexTable[unitID]["backupTargetZ"]=unitPosZ
		boxSizeTrigger=3 --change to deactivation 'halfboxsize' similar to REPAIR command
		graphCONSTANTtrigger[1] = 1
		graphCONSTANTtrigger[2] = 1
	elseif cQueue[1].id == cMD_DummyG then
		targetCoordinate = {-1, -1,-1} --no target (only avoidance)
		boxSizeTrigger = nil --//value not needed; because 'halfboxsize' for a "-1" target always return "not reached" (infinite avoidance), calculation is skipped (no nil error)
		graphCONSTANTtrigger[1] = 1 --//this value doesn't matter because 'cMD_DummyG' don't use attractor (-1 disabled the attractor calculation, and 'fixedPointCONSTANTtrigger' behaviour ignore attractor). Needed because "fTarget" is tied to this variable in "AvoidanceCalculator()". 
		graphCONSTANTtrigger[2] = 1
		fixedPointCONSTANTtrigger = 3 --//use behaviour that promote avoidance/ignore attractor
	elseif cQueue[queueIndex].id == CMD_GUARD then
		local unitPosX, unitPosY, unitPosZ = -1, -1, -1 -- (-1) is default value because -1 represent "no target"
		local targetUnitID = cQueue[queueIndex].params[1]
		if Spring.ValidUnitID(targetUnitID) then --if valid unit ID, not fake (if fake then will use "no target" for pure avoidance)
			local unitDirection = 0
			unitDirection, unitPosY,_ = GetUnitDirection(targetUnitID, {nil,nil}) --get target's direction in radian
			unitPosX, unitPosZ = ConvertToXZ(targetUnitID, unitDirection, 200) --project a target at 200m in front of guarded unit
		else
			if (turnOnEcho == 2)then Spring.Echo("Dynamic Avoidance guard targetting failure: fallback to no target") end
		end
		targetCoordinate={unitPosX, unitPosY,unitPosZ} --use ally unit as target
		commandIndexTable[unitID]["backupTargetX"]=unitPosX --backup the target
		commandIndexTable[unitID]["backupTargetY"]=unitPosY
		commandIndexTable[unitID]["backupTargetZ"]=unitPosZ
		boxSizeTrigger = 4 --//deactivation 'halfboxsize' for GUARD command
		graphCONSTANTtrigger[1] = 2 --//use more aggressive attraction because it GUARD units. It need big result.
		graphCONSTANTtrigger[2] = 1	--//use less aggressive avoidance because need to stay close to units. It need not stray.
	elseif cQueue[queueIndex].id == CMD_ATTACK then
		local targetPosX, targetPosY, targetPosZ = -1, -1, -1 -- (-1) is default value because -1 represent "no target"
		boxSizeTrigger = nil --//value not needed when target is "-1" which always return "not reached" (a case where boxSizeTrigger is not used)
		if unitVisible and not isReloadAvoidance then --*Note: this is needed if "GateKeeperOrCommandFilter" miss filtering out attack command* if unit is visible & not reloadAvoidance (ie: is cloaked and is issued direct attack), then set enemy as target and check for "target reached" properly.
			local enemyID = cQueue[queueIndex].params[1]
			local x,y,z = spGetUnitPosition(enemyID)
			if x then
				targetPosX, targetPosY, targetPosZ = x,y,z --set target to enemy
				boxSizeTrigger = 1 --if user initiate an attack and unit is not reloading, then set deactivation 'halfboxsize' for MOVE command (ie: 400m range)
			end
		end
		targetCoordinate={targetPosX, targetPosY, targetPosZ} --set target to enemy unit or none
		commandIndexTable[unitID]["backupTargetX"]=targetPosX --backup the target
		commandIndexTable[unitID]["backupTargetY"]=targetPosY
		commandIndexTable[unitID]["backupTargetZ"]=targetPosZ
		graphCONSTANTtrigger[1] = 1 --//this value doesn't matter because 'CMD_ATTACK' don't use attractor (-1 already disabled the attractor calculation, and 'fixedPointCONSTANTtrigger' ignore attractor). Needed because "fTarget" is tied to this variable in "AvoidanceCalculator()".
		graphCONSTANTtrigger[2] = 2	--//use more aggressive avoidance because it often run just once or twice. It need big result.
		fixedPointCONSTANTtrigger = 3 --//use behaviour that promote avoidance/ignore attractor (incase -1 is not enough)
	else --if queue has no match/ is empty: then use no-target. eg: A case where undefined command is allowed into the system, or when engine delete the next queues of a valid command and widget expect it to still be there.
		targetCoordinate={-1, -1, -1}
		--if for some reason command queue[2] is already empty then use these backup value as target:
		--targetCoordinate={commandIndexTable[unitID]["backupTargetX"], commandIndexTable[unitID]["backupTargetY"],commandIndexTable[unitID]["backupTargetZ"]} --if the second queue isappear then use the backup
		boxSizeTrigger = nil --//value not needed when target is "-1" which always return "not reached" (a case where boxSizeTrigger is not used)
		commandIndexTable[unitID]["backupTargetX"]=-1 --backup the target
		commandIndexTable[unitID]["backupTargetY"]=-1
		commandIndexTable[unitID]["backupTargetZ"]=-1
		graphCONSTANTtrigger[1] = 1  --//needed because "fTarget" is tied to this variable in "AvoidanceCalculator()". This value doesn't matter because -1 already skip attractor calculation & 'fixedPointCONSTANTtrigger' already ignore attractor values.
		graphCONSTANTtrigger[2] = 1
		fixedPointCONSTANTtrigger = 3
	end
	return commandIndexTable, targetCoordinate, boxSizeTrigger, graphCONSTANTtrigger, fixedPointCONSTANTtrigger
end

function AddAttackerIDToEnemyList (unitID, losRadius, relevantUnit, arrayIndex, attacker)
	if attacker[unitID].countDown > 0 then
		local separation = spGetUnitSeparation (unitID,attacker[unitID].id, true)
		if separation ~=nil then --if attackerID is still a valid id (ie: enemy did not disappear) then:
			if separation> losRadius then --only include attacker that is outside LosRadius because anything inside LosRadius is automatically included later anyway
				arrayIndex=arrayIndex+1
				relevantUnit[arrayIndex]= attacker[unitID].id --//add attacker as a threat
			end
		end
	end
	return relevantUnit, arrayIndex
end

function GetUnitRelativeAngle (unitIDmain, unitID2)
	local x,_,z = spGetUnitPosition(unitIDmain)
	local rX, _, rZ= spGetUnitPosition(unitID2)
	local cX, _, cZ = rX-x, _, rZ-z 
	local cXcZ = math.sqrt(cX*cX + cZ*cZ) --hypothenus for xz direction
	local relativeAngle = math.atan2 (cX/cXcZ, cZ/cXcZ) --math.atan2 accept trigonometric ratio (ie: ratio that has same value as: cos(angle) & sin(angle). Cos is ratio between x and hypothenus, and Sin is ratio between z and hypothenus)
	return relativeAngle
end

function GetTargetAngleWithRespectToUnit(unitID, targetCoordinate)
	local x,_,z = spGetUnitPosition(unitID)
	local tx, tz = targetCoordinate[1], targetCoordinate[3]
	local dX, dZ = tx- x, tz-z 
	local dXdZ = math.sqrt(dX*dX + dZ*dZ) --hypothenus for xz direction
	local targetAngle = math.atan2(dX/dXdZ, dZ/dXdZ) --math.atan2 accept trigonometric ratio (ie: ratio that has same value as: cos(angle) & sin(angle))
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
	local targetSubtendedAngle = math.atan(unitSize*2/targetDistance) --target is same size as unit's. Usually target do not has size at all, because they are simply move command on ground
	return targetSubtendedAngle
end

--sum the contribution from all enemy unit
function SumAllUnitAroundUnitID (thisUnitID, surroundingUnits, unitDirection, wTotal, dSum, fObstacleSum,dFobstacle, nearestFrontObstacleRange, unitsSeparation, impatienceTrigger, graphCONSTANTtrigger, losRadius, obsCONSTANT)
	local safetyMarginCONSTANT = safetyMarginCONSTANTunitG -- make the slopes in the extremeties of obstacle graph more sloppy (refer to "non-Linear Dynamic system approach to modelling behavior" -SiomeGoldenstein, Edward Large, DimitrisMetaxas)
	local smCONSTANT = smCONSTANTunitG --?
	local distanceCONSTANT = distanceCONSTANTunitG
	local normalizeObsGraph = normalizeObsGraphG
	----
	local normalizingFactor = 1
	
	if (turnOnEcho == 1) then Spring.Echo("unitID(SumAllUnitAroundUnitID)" .. thisUnitID) end
	if (surroundingUnits[1]~=nil) then --don't execute if no enemy unit exist
		local graphSample={}
		if normalizeObsGraph then --an option (default OFF) allow the obstacle graph to be normalized for experimenting purposes 
			for i=1, 180+1, 1 do
				graphSample[i]=0 --initialize content 360 points
			end
		end
		for i=2,surroundingUnits[1], 1 do
			local unitRectangleID=surroundingUnits[i]
			if (unitRectangleID ~= nil)then --excluded any nil entry
				local unitSeparation	= spGetUnitSeparation (thisUnitID, unitRectangleID, true) --get 2D distance
				--if enemy spontaneously appear then set the memorized separation distance to 999; maybe previous polling missed it and to prevent nil
				if unitsSeparation[unitRectangleID]==nil then unitsSeparation[unitRectangleID]=999 end
				if (turnOnEcho == 1) then
					Spring.Echo("unitSeparation <unitsSeparation[unitRectangleID](SumAllUnitAroundUnitID)")
					Spring.Echo(unitSeparation <unitsSeparation[unitRectangleID])
				end
				if unitSeparation <(unitsSeparation[unitRectangleID] or 999) then --see if the enemy is maintaining distance
					local relativeAngle 	= GetUnitRelativeAngle (thisUnitID, unitRectangleID) -- obstacle's angular position with respect to our coordinate
					local subtendedAngle	= GetUnitSubtendedAngle (thisUnitID, unitRectangleID, losRadius) -- obstacle & our unit's angular size 

					--get obstacle/ enemy/repulsor wave function
					if impatienceTrigger==0 then --impatienceTrigger reach zero means that unit is impatient
						distanceCONSTANT=distanceCONSTANT/2
					end
					local ri, wi, di,diff1 = GetRiWiDi (unitDirection, relativeAngle, subtendedAngle, unitSeparation, safetyMarginCONSTANT, smCONSTANT, distanceCONSTANT,obsCONSTANT)
					local fObstacle = ri*wi*di
					distanceCONSTANT=distanceCONSTANTunitG --reset distance constant

					--get second obstacle/enemy/repulsor wave function to calculate slope
					local ri2, wi2, di2, diff2= GetRiWiDi (unitDirection, relativeAngle, subtendedAngle, unitSeparation, safetyMarginCONSTANT, smCONSTANT, distanceCONSTANT, obsCONSTANT, true)
					local fObstacle2 = ri2*wi2*di2
					
					--create a snapshot of the entire graph. Resolution: 360 datapoint
					local dI = math.exp(-1*unitSeparation/distanceCONSTANT) --distance multiplier
					local hI = windowingFuncMultG/ (math.cos(2*subtendedAngle) - math.cos(2*subtendedAngle+ safetyMarginCONSTANT))
					if normalizeObsGraph then
						for i=-90, 90, 1 do --sample the entire 360 degree graph
							local differenceInAngle = (unitDirection-relativeAngle)+i*math.pi/180
							local rI = (differenceInAngle/ subtendedAngle)*math.exp(1- math.abs(differenceInAngle/subtendedAngle))
							local wI = obsCONSTANT* (math.tanh(hI- (math.cos(differenceInAngle) -math.cos(2*subtendedAngle +smCONSTANT)))+1) --graph with limiting window
							graphSample[i+90+1]=graphSample[i+90+1]+ (rI*wI*dI)
							--[[ <<--can uncomment this and comment the 2 "normalizeObsGraph" switch above for debug info
							Spring.Echo((rI*wI*dI) .. " (rI*wI*dI) (SumAllUnitAroundUnitID)")
							if i==0 then
								Spring.Echo("CENTER")
							end
							--]]
						end
					end

					--get repulsor wavefunction's slope
					local fObstacleSlope = GetFObstacleSlope(fObstacle2, fObstacle, diff2, diff1)

					--sum all repulsor's wavefunction from every enemy/obstacle within this loop
					wTotal, dSum, fObstacleSum,dFobstacle, nearestFrontObstacleRange= DoAllSummation (wi, fObstacle, fObstacleSlope, di,wTotal, unitDirection, unitSeparation, relativeAngle, dSum, fObstacleSum,dFobstacle, nearestFrontObstacleRange)
				end
			end
		end
		if normalizeObsGraph then
			local biggestValue=0
			for i=1, 180+1, 1 do --find maximum value from graph
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
function SendCommand(thisUnitID, wTarget, wObstacle, fTarget, fObstacleSum, unitDirection, nearestFrontObstacleRange, losRadius, unitSpeed, impatienceTrigger, normalizingFactor, skippingTimer, usingLastPosition, newCommand)
	local safetyDistanceCONSTANT=safetyDistanceCONSTANT_fG
	local timeToContactCONSTANT=timeToContactCONSTANTg
	local activateAutoReverse=activateAutoReverseG
	--local doCalculation_then_gps_delay = doCalculation_then_gps_delayG
	local gps_then_DoCalculation_delay = gps_then_DoCalculation_delayG
	------
	if (nearestFrontObstacleRange> losRadius) then nearestFrontObstacleRange = 999 end --if no obstacle infront of unit then set nearest obstacle as far as LOS to prevent infinite velocity.
	local newUnitAngleDerived= GetNewAngle(unitDirection, wTarget, fTarget, wObstacle, fObstacleSum, normalizingFactor) --derive a new angle from calculation for move solution

	local velocity=unitSpeed*(math.max(timeToContactCONSTANT, skippingTimer.averageDelay/2 + gps_then_DoCalculation_delay)) --scale-down/scale-up command lenght based on system delay (because short command will make unit move in jittery way & avoidance stop prematurely). *NOTE: select either preset velocity (timeToContactCONSTANT==gps_then_DoCalculation_delayG + doCalculation_then_gps_delayG) or the one taking account delay measurement (skippingTimer.networkDelay + gps_then_DoCalculation_delay), which one is highest, times unitSpeed as defined by UnitDefs.
	local networkDelayDrift = 0
	if usingLastPosition then  --unit drift contributed by network lag/2 (divide-by-2 because averageDelay is a roundtrip delay and we just want the delay of stuff measured on screen), only calculated when unit is known to be moving (eg: is using lastPosition to determine direction), but network lag value is not accurate enough to yield an accurate drift prediction.
		networkDelayDrift = unitSpeed*(skippingTimer.averageDelay/2)
	else --if not using-last-position (eg: initially stationary) then add this backward motion (as 'hax' against unit move toward enemy because of avoidance due to firing/reloading weapon)
		networkDelayDrift = -1*unitSpeed/2
	end
	local maximumVelocity = (nearestFrontObstacleRange- safetyDistanceCONSTANT)/timeToContactCONSTANT --calculate the velocity that will cause a collision within the next "timeToContactCONSTANT" second.
	activateAutoReverse=activateAutoReverse*impatienceTrigger --activate/deactivate 'autoReverse' if impatience system is used
	if (velocity >= maximumVelocity) and (activateAutoReverse==1) and (not newCommand) then 
		velocity = -unitSpeed	--set to reverse if impact is imminent & when autoReverse is active & when isn't a newCommand. NewCommand is TRUE if its on initial avoidance. We don't want auto-reverse on initial avoidance (we rely on normal avoidance first, then auto-reverse if it about to collide with enemy).
	end 
	
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
	--Spring.Echo((now - safeHavenLastUpdate))
	if (now - safeHavenLastUpdate) > 4 then --//only update NO MORE than once every 4 second:
		safeHavenCoordinates = {} --//reset old content
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
				elseif unitDef.customParams.commtype then --if COMMANDER,
					unorderedUnitList[unitID_list] = {x,y,z} --//store
				elseif not unitDef["canFly"] then --if all ground unit, amphibious, and ships (except commander)
					--unorderedUnitList[unitID_list] = {x,y,z} --//store
				elseif (unitDef.hoverAttack== true) then --if gunships
					--intentionally empty. Not include gunships.
				end
			else --if buildings
				unorderedUnitList[unitID_list] = {x,y,z} --//store
			end
		end
		local cluster, _ = WG.recvIndicator.OPTICS_cluster(unorderedUnitList, 600,3, myTeamID,300) --//find clusters with atleast 3 unit per cluster and with at least within 300-meter from each other 
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
	local currentSafeHaven = {params={}} --// initialize table using 'params' to be consistent with 'cQueue' content
	local nearestSafeHaven = {params={}} --// initialize table using 'params' to be consistent with 'cQueue' content
	local nearestSafeHavenDistance = 999999 
	nearestSafeHaven, currentSafeHaven = NearestSafeCoordinate (unitID, safeHavenCoordinates, nearestSafeHavenDistance, nearestSafeHaven, currentSafeHaven)

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
	local dx, dz = 0,0
	local usingLastPosition = true
	local currentX, currentY, currentZ = spGetUnitPosition(unitID)
	if (lastPosition[1] ~= nil) then --calculate unit's vector using difference-in-location when lastPosition contain coordinates
		dx = currentX-lastPosition[1]
		dz = currentZ-lastPosition[2]
		if (dx == 0 and dz == 0) then --use the reported vector if lastPosition failed to reveal any vector
			dx,_,dz= spGetUnitDirection(unitID)
			usingLastPosition = false
		end
	else --use the reported vector if lastPosition contain "nil"
		dx,_,dz= spGetUnitDirection(unitID)
		usingLastPosition = false
	end
	local dxdz = math.sqrt(dx*dx + dz*dz) --hypothenus for xz direction
	local unitDirection = math.atan2(dx/dxdz, dz/dxdz)
	if (turnOnEcho == 1) then
		Spring.Echo("direction(GetUnitDirection) " .. unitDirection*180/math.pi)
	end
	return unitDirection, currentY, usingLastPosition
end

function ConvertToXZ(thisUnitID, newUnitAngleDerived, velocity, unitDirection, networkDelayDrift)
	--localize global constant
	local velocityAddingCONSTANT=velocityAddingCONSTANTg
	local velocityScalingCONSTANT=velocityScalingCONSTANTg
	--
	local x,_,z = spGetUnitPosition(thisUnitID)
	local distanceToTravelInSecond=velocity*velocityScalingCONSTANT+velocityAddingCONSTANT*Sgn(velocity) --add multiplier & adder. note: we multiply "velocityAddingCONSTANT" with velocity Sign ("Sgn") because we might have reverse speed (due to auto-reverse)
	local newX = distanceToTravelInSecond*math.sin(newUnitAngleDerived) + x -- issue a command on the ground to achieve a desired angular turn
	local newZ = distanceToTravelInSecond*math.cos(newUnitAngleDerived) + z
	
	if (unitDirection ~= nil) and (networkDelayDrift~=0) then --need this check because argument #4 & #5 can be empty (for other usage). Also used in ExtractTarget for GUARD command.
		local distanceTraveledDueToNetworkDelay = networkDelayDrift 
		newX = distanceTraveledDueToNetworkDelay*math.sin(unitDirection) + newX -- translate move command abit further forward; to account for lag. Network Lag makes move command lags behind the unit. 
		newZ = distanceTraveledDueToNetworkDelay*math.cos(unitDirection) + newZ
	end
	
	if (turnOnEcho == 1) then
		Spring.Echo("x(ConvertToXZ) " .. x)
		Spring.Echo("z(ConvertToXZ) " .. z)
	end
	return newX, newZ
end

--get enemy angular size with respect to unit's perspective
function GetUnitSubtendedAngle (unitIDmain, unitID2, losRadius)
	local unitSize2 =32 --a commander size for an unidentified enemy unit
	local unitDefID2= spGetUnitDefID(unitID2)
	local unitDef2= UnitDefs[unitDefID2]
	if (unitDef2~=nil) then	unitSize2 = unitDef2.xsize*8 --8 unitDistance per each square times unitDef's square, a correct size for an identified unit
	end

	local unitDefID= spGetUnitDefID(unitIDmain)
	local unitDef= UnitDefs[unitDefID]
	local unitSize = unitDef.xsize*8 --8 is the actual Distance per square
	local separationDistance = 0
	if (unitID2~=nil) then separationDistance = spGetUnitSeparation (unitIDmain, unitID2, true) --actual separation distance
	else separationDistance = losRadius -- GetUnitLOSRadius(unitIDmain) --as far as unit's reported LOSradius
	end

	local unit2SubtendedAngle = math.atan((unitSize + unitSize2)/separationDistance) --convert size and distance into radian (angle)
	return unit2SubtendedAngle --return angular size
end

--calculate enemy's wavefunction
function GetRiWiDi (unitDirection, relativeAngle, subtendedAngle, separationDistance, safetyMarginCONSTANT, smCONSTANT, distanceCONSTANT, obsCONSTANT, isForSlope)
	unitDirection = unitDirection + math.pi --temporarily add a half of a circle to remove the negative part which could skew with circle-arithmetic
	relativeAngle = relativeAngle + math.pi
	local differenceInAngle = relativeAngle - unitDirection --relative difference
	if differenceInAngle > math.pi then --select difference that is smaller than half a circle
		differenceInAngle = differenceInAngle - 2*math.pi
	elseif differenceInAngle < -1*math.pi then
		differenceInAngle = 2*math.pi + differenceInAngle
	end
	if isForSlope then
		differenceInAngle = differenceInAngle + 0.05
	end
	--Spring.Echo("differenceInAngle(GetRiWiDi) "..  differenceInAngle*180/math.pi)
	local rI = (differenceInAngle/ subtendedAngle)*math.exp(1- math.abs(differenceInAngle/subtendedAngle)) -- ratio of enemy-direction over the size-of-the-enemy
	local hI = windowingFuncMultG/ (math.cos(2*subtendedAngle) - math.cos(2*subtendedAngle+ safetyMarginCONSTANT))
	local wI = obsCONSTANT* (math.tanh(hI- (math.cos(differenceInAngle) -math.cos(2*subtendedAngle +smCONSTANT)))+1) --graph with limiting window. Tanh graph multiplied by obsCONSTANT
	local dI = math.exp(-1*separationDistance/distanceCONSTANT) --distance multiplier
	return rI, wI, dI, differenceInAngle
end
--calculate wavefunction's slope
function GetFObstacleSlope (fObstacle2, fObstacle, diff2, diff1)
	--local fObstacleSlope= (fObstacle2 -fObstacle)/((unitDirection+0.05)-unitDirection)
	local fObstacleSlope= (fObstacle2 -fObstacle)/(diff2-diff1)
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
	fObstacleSum = fObstacleSum*normalizingFactor --downscale value depend on the entire graph's maximum (if normalization is used)
	local angleFromTarget = math.abs(wTarget)*fTarget
	local angleFromObstacle = math.abs(wObstacle)*fObstacleSum
	--Spring.Echo(math.modf(angleFromObstacle))
	local angleFromNoise = (-1)*Sgn(angleFromObstacle)*(noiseAngleG)*GaussianNoise() --(noiseAngleG)*(GaussianNoise()*2-1) --for random in negative & positive direction
	local unitAngleDerived= angleFromTarget + (-1)*angleFromObstacle + angleFromNoise --add attractor amplitude, add repulsive amplitude, and add noise between -ve & +ve noiseAngle. NOTE: somehow "angleFromObstacle" have incorrect sign (telling unit to turn in opposite direction)
	if math.abs(unitAngleDerived) > maximumTurnAngleG then --to prevent excess in avoidance causing overflow in angle changes (maximum angle should be pi, but useful angle should be pi/2 eg: 90 degree)
		--Spring.Echo("Dynamic Avoidance warning: total angle changes excess")
		unitAngleDerived = Sgn(unitAngleDerived)*maximumTurnAngleG 
	end
	unitDirection = unitDirection+math.pi --temporarily remove negative hemisphere so that arithmetic with negative angle won't skew the result
	local newUnitAngleDerived= unitDirection +unitAngleDerived --add derived angle into current unit direction plus some noise
	newUnitAngleDerived = newUnitAngleDerived - math.pi --readd negative hemisphere
	if newUnitAngleDerived > math.pi then --add residual angle (angle > 2 circle) to respective negative or positive hemisphere
		newUnitAngleDerived = newUnitAngleDerived - 2*math.pi
	elseif newUnitAngleDerived < -1*math.pi then
		newUnitAngleDerived = newUnitAngleDerived + 2*math.pi
	end
	if (turnOnEcho == 1) then
		Spring.Echo("unitAngleDerived (getNewAngle)" ..unitAngleDerived*180/math.pi)
		Spring.Echo("newUnitAngleDerived (getNewAngle)" .. newUnitAngleDerived*180/math.pi)
		--Spring.Echo("fTarget (getNewAngle)" .. fTarget)
		--Spring.Echo("fObstacleSum (getNewAngle)" ..fObstacleSum)
		--Spring.Echo("unitAngleDerived(GetNewAngle) " .. unitAngleDerived) 
		--Spring.Echo("newUnitAngleDerived(GetNewAngle) " .. newUnitAngleDerived)
	end
	return newUnitAngleDerived --sent out derived angle
end

function NearestSafeCoordinate (unitID, safeHavenCoordinates, nearestSafeHavenDistance, nearestSafeHaven, currentSafeHaven)
	local x,_,z = spGetUnitPosition(unitID)
	local unitDefID = spGetUnitDefID(unitID)
	local unitDef = UnitDefs[unitDefID]
	--local movementType = unitDef.moveData.name
	for j=1, #safeHavenCoordinates, 1 do --//iterate over all possible retreat point (bases with at least 3 units in a cluster)
		local distance = Distance(safeHavenCoordinates[j][1], safeHavenCoordinates[j][3] , x, z)
		local pathOpen = false
		local validX = 0
		local validZ = 0
		local positionToCheck = {{0,0},{1,1},{-1,-1},{1,-1},{-1,1},{0,1},{0,-1},{1,0},{-1,0}}
		for i=1, 9, 1 do --//randomly select position around 100-meter from the center for 5 times before giving up, if given up: it imply that this position is too congested for retreating.
			--local xDirection = mathRandom(-1,1)
			--local zDirection = mathRandom(-1,1)
			local xDirection = positionToCheck[i][1]
			local zDirection = positionToCheck[i][2]
			validX = safeHavenCoordinates[j][1] + (xDirection*100 + xDirection*mathRandom(0,100))
			validZ = safeHavenCoordinates[j][3] + (zDirection*100 + zDirection*mathRandom(0,100))
			local units = spGetUnitsInRectangle( validX-40, validZ-40, validX+40, validZ+40 )
			if units == nil or #units == 0 then --//if this box is empty then return this area as accessible.
				pathOpen = true
				break
			end
		end
		
		--local pathOpen = spRequestPath(movementType, x,y,z, safeHavenCoordinates[j][1], safeHavenCoordinates[j][2], safeHavenCoordinates[j][3])
		-- if pathOpen == nil then
			-- pathOpen = spRequestPath(movementType, x,y,z, safeHavenCoordinates[j][1]-80, safeHavenCoordinates[j][2], safeHavenCoordinates[j][3])
			-- validX = safeHavenCoordinates[j][1]-80
			-- validZ = safeHavenCoordinates[j][3]
			-- if not pathOpen then
				-- pathOpen = spRequestPath(movementType, x,y,z, safeHavenCoordinates[j][1], safeHavenCoordinates[j][2], safeHavenCoordinates[j][3]-80)
				-- validX = safeHavenCoordinates[j][1]
				-- validZ = safeHavenCoordinates[j][3]-80
				-- if not pathOpen then
					-- pathOpen = spRequestPath(movementType, x,y,z, safeHavenCoordinates[j][1], safeHavenCoordinates[j][2], safeHavenCoordinates[j][3]+80)
					-- validX = safeHavenCoordinates[j][1]
					-- validZ = safeHavenCoordinates[j][3]+80
					-- if not pathOpen then
						-- pathOpen = spRequestPath(movementType, x,y,z, safeHavenCoordinates[j][1]+80, safeHavenCoordinates[j][2], safeHavenCoordinates[j][3])
						-- validX = safeHavenCoordinates[j][1]+80
						-- validZ = safeHavenCoordinates[j][3]
					-- end
				-- end
			-- end
		--end
		--Spring.MarkerAddPoint(validX, safeHavenCoordinates[j][2] , validZ, "here")
			
		if distance > 300 and distance < nearestSafeHavenDistance and pathOpen then
			nearestSafeHavenDistance = distance
			nearestSafeHaven.params[1] = validX
			nearestSafeHaven.params[2] = safeHavenCoordinates[j][2]
			nearestSafeHaven.params[3] = validZ
		elseif distance < 300 then --//theoretically this will run once because units can only be at 1 cluster at 1 time or not at any cluster at all
			currentSafeHaven.params[1] = validX
			currentSafeHaven.params[2] = safeHavenCoordinates[j][2]
			currentSafeHaven.params[3] = validZ
		end
	end
	return nearestSafeHaven, currentSafeHaven
end
---------------------------------Level4
---------------------------------Level5
function SumRiWiDiCalculation (wi, fObstacle, fObstacleSlope, di, wTotal, dSum, fObstacleSum, dFobstacle)
	wTotal = wTotal +wi
	fObstacleSum= fObstacleSum +(fObstacle)
	dFobstacle= dFobstacle + (fObstacleSlope)
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
	if x == 0 then
		return 0
	end
	local y= x/(math.abs(x))
	return y
end

function Distance(x1,z1,x2,z2)
  local dis = math.sqrt((x1-x2)*(x1-x2)+(z1-z2)*(z1-z2))
  return dis
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
--10
--Thanks to versus666 for his endless playtesting and creating idea for improvement & bug report (eg: messy command queue case, widget overriding user's command case, "avoidance may be bad for gunship" case, avoidance depending on detected enemy sonar, constructor's retreat timeout, selection effect avoidance, ect)
--11
-- Ref: http://en.wikipedia.org/wiki/Moving_average#Simple_moving_average (rolling average)
--------------------------------------------------------------------------------
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
-- ???