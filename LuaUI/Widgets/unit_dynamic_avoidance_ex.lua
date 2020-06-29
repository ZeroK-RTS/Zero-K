local versionName = "v2.879"
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
    date      = "March 8, 2014", --clean up June 25, 2013
    license   = "GNU GPL, v2 or later",
    layer     = 20,
    enabled   = false  --  loaded by default?
  }
end

--------------------------------------------------------------------------------
-- Functions:
local spGetTeamUnits 	= Spring.GetTeamUnits
local spGetAllUnits		= Spring.GetAllUnits
local spGetTeamResources = Spring.GetTeamResources
local spGetGroundHeight = Spring.GetGroundHeight
local spGiveOrderToUnit =Spring.GiveOrderToUnit
local spGiveOrderArrayToUnitArray = Spring.GiveOrderArrayToUnitArray
local spGetMyTeamID 	= Spring.GetMyTeamID
local spIsUnitAllied 	= Spring.IsUnitAllied
local spGetUnitPosition =Spring.GetUnitPosition
local spGetUnitVelocity = Spring.GetUnitVelocity
local spGetUnitDefID 	= Spring.GetUnitDefID
local spGetUnitSeparation	= Spring.GetUnitSeparation
local spGetUnitDirection	=Spring.GetUnitDirection
local spGetUnitsInRectangle =Spring.GetUnitsInRectangle
local spGetVisibleUnits = Spring.GetVisibleUnits
local spGetCommandQueue	= Spring.GetCommandQueue
local spGetGameSeconds	= Spring.GetGameSeconds
local spGetFeaturePosition = Spring.GetFeaturePosition
local spGetPlayerInfo = Spring.GetPlayerInfo
local spGetUnitIsCloaked = Spring.GetUnitIsCloaked
local spGetUnitTeam = Spring.GetUnitTeam
local spGetUnitLastAttacker = Spring.GetUnitLastAttacker
local spGetUnitHealth = Spring.GetUnitHealth
local spGetUnitWeaponState = Spring.GetUnitWeaponState
local spGetUnitShieldState = Spring.GetUnitShieldState
local spGetUnitIsStunned = Spring.GetUnitIsStunned
local spGetGameFrame = Spring.GetGameFrame
local spSendCommands = Spring.SendCommands
local spGetSelectedUnits = Spring.GetSelectedUnits
local spGetUnitIsDead 	= Spring.GetUnitIsDead
local spValidUnitID = Spring.ValidUnitID
local spValidFeatureID = Spring.ValidFeatureID
local spGetUnitRulesParam = Spring.GetUnitRulesParam
local CMD_STOP			= CMD.STOP
local CMD_ATTACK 		= CMD.ATTACK
local CMD_GUARD			= CMD.GUARD
local CMD_INSERT		= CMD.INSERT
local CMD_REMOVE		= CMD.REMOVE
local CMD_OPT_INTERNAL	= CMD.OPT_INTERNAL
local CMD_OPT_SHIFT		= CMD.OPT_SHIFT
local CMD_RECLAIM		= CMD.RECLAIM
local CMD_RESURRECT		= CMD.RESURRECT
local CMD_REPAIR		= CMD.REPAIR

--local spRequestPath = Spring.RequestPath
local mathRandom = math.random
--local spGetUnitSensorRadius  = Spring.GetUnitSensorRadius
--------------------------------------------------------------------------------
-- Constant:
-- Switches:
local turnOnEcho =0 --1:Echo out all numbers for debugging the system, 2:Echo out alert when fail. (default = 0)
local activateAutoReverseG=1 --integer:[0,1], activate a one-time-reverse-command when unit is about to collide with an enemy (default = 1)
local activateImpatienceG=0 --integer:[0,1], auto disable auto-reverse & half the 'distanceCONSTANT' after 6 continuous auto-avoidance (3 second). In case the unit stuck (default = 0)

-- Graph constant:
local distanceCONSTANTunitG = 410 --increase obstacle awareness over distance. (default = 410 meter, ie: ZK's stardust range)
local useLOS_distanceCONSTANTunit_G = true --this replace  "distanceCONSTANTunitG" obstacle awareness (push) strenght with unit's LOS, ie: unit with different range suit better. (default = true, for tuning: use false)
local safetyMarginCONSTANTunitG = 0.175 --obstacle graph windower (a "safety margin" constant). Shape the obstacle graph so that its fatter and more sloppier at extremities: ie: probably causing unit to prefer to turn more left or right (default = 0.175 radian)
local smCONSTANTunitG		= 0.175  -- obstacle graph offset (a "safety margin" constant).  Offset the obstacle effect: to prefer avoid torward more left or right??? (default = 0.175 radian)
local aCONSTANTg			= {math.pi/4 , math.pi/2} -- attractor graph; scale the attractor's strenght. Less equal to a lesser turning toward attraction(default = math.pi/10 radian (MOVE),math.pi/4 (GUARD & ATTACK)) (max value: math.pi/2 (because both contribution from obstacle & target will sum to math.pi)).
local obsCONSTANTg			= {math.pi/4, math.pi/2} -- obstacle graph; scale the obstacle's strenght. Less equal to a lesser turning away from avoidance(default = math.pi/10 radian (MOVE), math.pi/4 (GUARD & ATTACK)).
--aCONSTANTg Note: math.pi/4 is equal to about 45 degrees turning (left or right). aCONSTANTg is the maximum amount of turning toward target and the actual turning depend on unit's direction. Activated by 'graphCONSTANTtrigger[1]'
--an antagonist to aCONSTANg (obsCONSTANTg or obstacle graph) also use math.pi/4 (45 degree left or right) but actual maximum value varies depend on number of enemy, but already normalized. Activated by 'graphCONSTANTtrigger[2]'
local windowingFuncMultG = 1 --? (default = 1 multiplier)
local normalizeObsGraphG = true --// if 'true': normalize turn angle to a maximum of "obsCONSTANTg", if 'false': allow turn angle to grow as big as it can (depend on number of enemy, limited by "maximumTurnAngleG").
local stdDecloakDist_fG = 75 --//a decloak distance size for Scythe is put as standard. If other unit has bigger decloak distance then it will be scalled based on this

-- Obstacle/Target competetive interaction constant:
local cCONSTANT1g 			= {0.01,1,2} --attractor constant; effect the behaviour. ie: selection between 4 behaviour state. (default = 0.01x (All), 1x (Cloakies),2x (alwaysAvoid)) (behaviour:(MAINTAIN USER's COMMAND)|(IGNORE USER's COMMAND|(IGNORE USER's COMMAND))
local cCONSTANT2g			= {0.01,1,2} --repulsor constant; effect behaviour. (default = 0.01x (All), 1x (Cloakies),2x (alwaysAvoid)) (behaviour:(MAINTAIN USER's COMMAND)|(IGNORE USER's COMMAND|(IGNORE USER's COMMAND))
local gammaCONSTANT2and1g	= {0.05,0.05,0.05} -- balancing constant; effect behaviour. . (default = 0.05x (All), 0.05x (Cloakies))
local alphaCONSTANT1g		= {500,0.4,0.4} -- balancing constant; effect behaviour. (default = 500x (All), 0.4x (Cloakies)) (behaviour:(MAINTAIN USER's COMMAND)|(IGNORE USER's COMMAND))

--Move Command constant:
local halfTargetBoxSize_g = {400, 0, 185, 50} --aka targetReachBoxSizeTrigger, set the distance from a target which widget should de-activate (default: MOVE = 400m (ie:800x800m box/2x constructor range), RECLAIM/RESURRECT=0 (always flee), REPAIR=185 (1x constructor's range), GUARD = 50 (arbitrary))
local cMD_DummyG = 248 --a fake command ID to flag an idle unit for pure avoidance. (arbitrary value, change if it overlap with existing command)
local cMD_Dummy_atkG = 249 --same as cMD_DummyG except to differenciate between idle & attacking

--Angle constant:
--http://en.wikipedia.org/wiki/File:Degree-Radian_Conversion.svg
local noiseAngleG =0.1 --(default is pi/36 rad); add random angle (range from 0 to +-math.pi/36) to the new angle. To prevent a rare state that contribute to unit going straight toward enemy
local collisionAngleG= 0.1 --(default is pi/6 rad) a "field of vision" (range from 0 to +-math.pi/366) where auto-reverse will activate
local fleeingAngleG= 0.7 --(default is pi/4 rad) angle of enemy with respect to unit (range from 0 to +-math.pi/4) where unit is considered as facing a fleeing enemy (to de-activate avoidance to perform chase). Set to 0 to de-activate.
local maximumTurnAngleG = math.pi --(default is pi rad) safety measure. Prevent overturn (eg: 360+xx degree turn)
--pi is 180 degrees

--Update constant:
local cmd_then_DoCalculation_delayG = 0.25  --elapsed second (Wait) before issuing new command (default: 0.25 second)

-- Distance or velocity constant:
local timeToContactCONSTANTg= cmd_then_DoCalculation_delayG --time scale for move command; to calculate collision calculation & command lenght (default = 0.5 second). Will change based on user's Ping
local safetyDistanceCONSTANT_fG=205 --range toward an obstacle before unit auto-reverse (default = 205 meter, ie: half of ZK's stardust range) reference:80 is a size of BA's solar
local extraLOSRadiusCONSTANTg=205 --add additional distance for unit awareness over the default LOS. (default = +205 meter radius, ie: to 'see' radar blip).. Larger value measn unit detect enemy sooner, else it will rely on its own LOS.
local velocityScalingCONSTANTg=1.1 --scale command lenght. (default= 1 multiplier) *Small value cause avoidance to jitter & stop prematurely*
local velocityAddingCONSTANTg=50 --add or remove command lenght (default = 50 elmo/second) *Small value cause avoidance to jitter & stop prematurely*

--Weapon Reload and Shield constant:
local reloadableWeaponCriteriaG = 0.5 --second at which reload time is considered high enough to be a "reload-able". eg: 0.5second
local criticalShieldLevelG = 0.5 --percent at which shield is considered low and should activate avoidance. eg: 50%
local minimumRemainingReloadTimeG = 0.9 --seconds before actual reloading finish which avoidance should de-activate (note: overriden by 1/4 of weapon's reload time if its bigger). eg: 0.9 second before finish (or 7 second for spiderantiheavy)
local thresholdForArtyG = 459 --elmo (weapon range) before unit is considered an arty. Arty will never set enemy as target and will always avoid. default: 459elmo (1 elmo smaller than Rocko range)
local maximumMeleeRangeG = 101 --elmo (weapon range) before unit is considered a melee. Melee will target enemy and do not avoid at halfTargetBoxSize_g[1]. default: 101elmo (1 elmo bigger than Sycthe range)
local secondPerGameFrameG = 1/30 --engine depended second-per-frame (for calculating remaining reload time). eg: 0.0333 second-per-frame or 0.5sec/15frame

--Command Timeout constants:
local commandTimeoutG = 2 --multiply by 1.1 second
local consRetreatTimeoutG = 15 --multiply by 1.1 second, is overriden by epicmenu option

--NOTE:
--angle measurement and direction setting is based on right-hand coordinate system, but Spring uses left-hand coordinate system.
--So, math.sin is for x, and math.cos is for z, and math.atan2 input is x,z (is swapped with respect to the usual x y convention).
--those swap conveniently translate left-hand coordinate system into right-hand coordinate system.

--------------------------------------------------------------------------------
--Variables:
local unitInMotionG={} --store unitID
local skippingTimerG={0,0,echoTimestamp=0, networkDelay=0, averageDelay = 0.3, storedDelay = {}, index = 1, sumOfAllNetworkDelay=0, sumCounter=0} --variable: store the timing for next update, and store values for calculating average network delay.
local commandIndexTableG= {} --store latest widget command for comparison
local myTeamID_gbl=-1
local myPlayerID=-1
local gaiaTeamID = Spring.GetGaiaTeamID()
local attackerG= {} --for recording last attacker
local commandTTL_G = {} --for recording command's age. To check for expiration. Note: Each table entry is indexed by unitID
local iNotLagging_gbl = true --//variable: indicate if player(me) is lagging in current game. If lagging then do not process anything.
local selectedCons_Meta_gbl = {} --//variable: remember which Constructor is selected by player.
local waitForNetworkDelay_gbl = nil
local issuedOrderTo_G = {}
local allyClusterInfo_gbl = {coords={},age=0}

--------------------------------------------------------------------------------
--Methods:
---------------------------------Level 0
options_path = 'Settings/Unit Behaviour/Dynamic Avoidance' --//for use 'with gui_epicmenu.lua'
options_order = {'enableCons','enableCloaky','enableGround','enableGunship','enableReturnToBase','consRetreatTimeoutOption', 'cloakyAlwaysFlee','enableReloadAvoidance','retreatAvoidance','dbg_RemoveAvoidanceSplitSecond', 'dbg_IgnoreSelectedCons'}
options = {
	enableCons = {
		name = 'Enable for constructors',
		type = 'bool',
		value = true,
		desc = 'Enable constructor\'s avoidance feature (WILL NOT include Commander).\n\nConstructors will avoid enemy while having move order. Constructor also return to base when encountering enemy during area-reclaim or area-ressurect command, and will try to avoid enemy while having build or repair or reclaim queue except when hold-position is issued.\n\nTips: order area-reclaim to the whole map, work best for cloaked constructor, but buggy for flying constructor. Default:On',
	},
	enableCloaky = {
		name = 'Enable for cloakies',
		type = 'bool',
		value = true,
		desc = 'Enable cloakies\' avoidance feature.\n\nCloakable bots will avoid enemy while having move order. Cloakable will also flee from enemy when idle except when hold-position state is used.\n\nTips: is optimized for Sycthe- your Sycthe will less likely to accidentally bump into enemy unit. Default:On',
	},
	enableGround = {
		name = 'Enable for ground units',
		type = 'bool',
		value = true,
		desc = 'Enable for ground units (INCLUDE Commander).\n\nAll ground unit will avoid enemy while being outside camera view and/or while reloading except when hold-position state is used.\n\nTips:\n1) is optimized for masses of Thug or Knight.\n2) You can use Guard to make your unit swarm the guarded unit in presence of enemy.\nDefault:On',
	},
	enableGunship = {
		name = 'Enable for gunships',
		type = 'bool',
		value = false,
		desc = 'Enable gunship\'s avoidance behaviour .\n\nGunship will avoid enemy while outside camera view and/or while reloading except when hold-position state is used.\n\nTips: to create a hit-&-run behaviour- set the fire-state options to hold-fire (can be buggy). Default:Off',
	},
	-- enableAmphibious = {
		-- name = 'Enable for amphibious',
		-- type = 'bool',
		-- value = true,
		-- desc = 'Enable amphibious unit\'s avoidance feature (including Commander, and submarine). Unit avoid enemy while outside camera view OR when reloading, but units with hold position state is excluded..',
	-- },
	enableReloadAvoidance = {
		name = "Jink during attack",
		type = 'bool',
		value = true,
		desc = "Unit with slow reload will randomly jink to random direction when attacking. NOTE: This have no benefit and bad versus fast attacker or fast weapon but have high chance of dodging versus slow ballistic weapon. Default:On",
	},
	enableReturnToBase = {
		name = "Find base",
		type = 'bool',
		value = true,
		desc = "Allow constructor to return to base when having area-reclaim or area-ressurect command, else it will return to center of the circle when retreating. \n\nTips: build 3 new buildings at new location to identify as base, unit will automatically select nearest base. Default:On",
	},
	consRetreatTimeoutOption = {
		name = 'Constructor retreat auto-expire:',
		type = 'number',
		value = 3,
		desc = "Amount in second before constructor retreat command auto-expire (is deleted), and then constructor will return to its previous area-reclaim command.\n\nTips: small value is better.",
		min=3,max=15,step=1,
		OnChange = function(self)
					consRetreatTimeoutG = self.value
					Spring.Echo(string.format ("%.1f", 1.1*consRetreatTimeoutG) .. " second")
				end,
	},
	cloakyAlwaysFlee = {
		name = 'Cloakies always flee',
		type = 'bool',
		value = false,
		desc = 'Force cloakies & constructor to always flee from enemy when idle except if they are under hold-position state. \n\nNote: Unit can wander around and could put themselves in danger. Default:Off',
	},
	retreatAvoidance = {
		name = 'Retreating unit always flee',
		type = 'bool',
		value = true,
		desc = 'Force retreating unit to always avoid the enemy (Note: this require the use of RETREAT functionality provided by cmd_retreat.lua widget a.k.a unit retreat widget). Default:On',
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
	local _, _, spec = Spring.GetPlayerInfo(myPlayerID, false)
	if spec then widgetHandler:RemoveWidget() return false end
	myTeamID_gbl= spGetMyTeamID()
	
	if (turnOnEcho == 1) then Spring.Echo("myTeamID_gbl(Initialize)" .. myTeamID_gbl) end
end

function widget:PlayerChanged(playerID)
	if Spring.GetSpectatingState() then widgetHandler:RemoveWidget() end
end

--execute different function at different timescale
function widget:Update()
	-------retrieve global table, localize global table
	local commandIndexTable=commandIndexTableG
	local unitInMotion = unitInMotionG
	local skippingTimer = skippingTimerG
	local attacker = attackerG
	local commandTTL = commandTTL_G
	local selectedCons_Meta = selectedCons_Meta_gbl
	local cmd_then_DoCalculation_delay = cmd_then_DoCalculation_delayG
	local myTeamID = myTeamID_gbl
	local waitForNetworkDelay = waitForNetworkDelay_gbl
	local allyClusterInfo = allyClusterInfo_gbl
	-----
	if iNotLagging_gbl then
		local now=spGetGameSeconds()
		--REFRESH UNIT LIST-- *not synced with avoidance*
		if (now >= skippingTimer[1]) then --wait until 'skippingTimer[1] second', then do "RefreshUnitList()"
			if (turnOnEcho == 1) then Spring.Echo("-----------------------RefreshUnitList") end
			unitInMotion, attacker, commandTTL, selectedCons_Meta =RefreshUnitList(attacker, commandTTL) --create unit list
			allyClusterInfo["age"]=allyClusterInfo["age"]+1 --indicate that allyClusterInfo is 1 cycle older
			
			local projectedDelay=ReportedNetworkDelay(myPlayerID, 1.1) --create list every 1.1 second OR every (0+latency) second, depending on which is greater.
			skippingTimer[1]=now+projectedDelay --wait until next 'skippingTimer[1] second'
			
			--check if under lockdown for overextended time
			if waitForNetworkDelay then
				if now - waitForNetworkDelay[1] > 4 then
					for unitID,_ in pairs(issuedOrderTo_G) do
						issuedOrderTo_G[unitID] = nil
					end
					waitForNetworkDelay = nil
				end
			end
			if (turnOnEcho == 1) then Spring.Echo("-----------------------RefreshUnitList") end
		end
		--GATHER SOME INFORMATION ON UNITS-- *part 1, start*
		if (now >=skippingTimer[2]) and (not waitForNetworkDelay) then --wait until 'skippingTimer[2] second', and wait for 'LUA message received', and wait for 'cycle==1', then do "DoCalculation()"
			if (turnOnEcho == 1) then Spring.Echo("-----------------------DoCalculation") end
			local infoForDoCalculation = { unitInMotion,commandIndexTable, attacker,
						selectedCons_Meta,myTeamID,
						skippingTimer, now, commandTTL,
						waitForNetworkDelay,allyClusterInfo
					}
			local outputTable,isAvoiding =DoCalculation(infoForDoCalculation)
			commandIndexTable = outputTable["commandIndexTable"]
			commandTTL = outputTable["commandTTL"]
			waitForNetworkDelay = outputTable["waitForNetworkDelay"]
			allyClusterInfo = outputTable["allyClusterInfo"]
			
			if isAvoiding then
				skippingTimer.echoTimestamp = now -- --prepare delay statistic to measure new delay (aka: reset stopwatch), --same as "CalculateNetworkDelay("restart", , )"^/
			else
				skippingTimer[2] = now + cmd_then_DoCalculation_delay --wait until 'cmd_then_DoCalculation_delayG'. The longer the better. The delay allow reliable unit direction to be derived from unit's motion
			end
			if (turnOnEcho == 1) then Spring.Echo("-----------------------DoCalculation") end
		end

		if (turnOnEcho == 1) then
			Spring.Echo("unitInMotion(Update):")
			Spring.Echo(unitInMotion)
		end
	end
	-------return global table
	allyClusterInfo_gbl = allyClusterInfo
	commandIndexTableG=commandIndexTable
	unitInMotionG = unitInMotion
	skippingTimerG = skippingTimer
	attackerG = attacker
	commandTTL_G = commandTTL
	selectedCons_Meta_gbl = selectedCons_Meta
	waitForNetworkDelay_gbl = waitForNetworkDelay
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

function widget:UnitDestroyed(unitID, unitDefID, unitTeam)
	if commandTTL_G[unitID] then --empty watch list for this unit when unit die
		commandTTL_G[unitID] = nil
	end
	if commandIndexTableG[unitID] then
		commandIndexTableG[unitID] = nil
	end
	if myTeamID_gbl==unitTeam and issuedOrderTo_G[unitID] then
		CountdownNetworkDelayWait(unitID)
	end
end

function widget:UnitGiven(unitID, unitDefID, newTeam,oldTeam)
	if oldTeam == myTeamID_gbl then
		if commandTTL_G[unitID] then --empty watch list for this unit is shared away
			commandTTL_G[unitID] = nil
		end
		if commandIndexTableG[unitID] then
			commandIndexTableG[unitID] = nil
		end
	end
	if myTeamID_gbl==oldTeam and issuedOrderTo_G[unitID] then
		CountdownNetworkDelayWait(unitID)
	end
end

function widget:UnitCommand(unitID, unitDefID, unitTeam, cmdID, cmdParams, cmdOptions)
	if myTeamID_gbl==unitTeam and issuedOrderTo_G[unitID] then
		if (CMD.INSERT == cmdID and cmdParams[2] == CMD_RAW_MOVE) and
		cmdParams[4] == issuedOrderTo_G[unitID][1] and
		cmdParams[5] == issuedOrderTo_G[unitID][2] and
		cmdParams[6] == issuedOrderTo_G[unitID][3] then
			CountdownNetworkDelayWait(unitID)
		end
	end
end

---------------------------------Level 0 Top level
---------------------------------Level1 Lower level
-- return a refreshed unit list, else return a table containing NIL
function RefreshUnitList(attacker, commandTTL)
	local stdDecloakDist = stdDecloakDist_fG
	local thresholdForArty = thresholdForArtyG
	local maximumMeleeRange = maximumMeleeRangeG
	----------------------------------------------------------
	local allMyUnits = spGetTeamUnits(myTeamID_gbl)
	local arrayIndex=0
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
			local _,_,inbuild = spGetUnitIsStunned(unitID)
			if (unitSpeed>0) and (not inbuild) then
				local unitType = 0 --// category that control WHEN avoidance is activated for each unit. eg: Category 2 only enabled when not in view & when guarding units. Used by 'GateKeeperOrCommandFilter()'
				local fixedPointType = 1 --//category that control WHICH avoidance behaviour to use. eg: Category 2 priotize avoidance and prefer to ignore user's command when enemy is close. Used by 'CheckWhichFixedPointIsStable()'
				if (unitDef.isBuilder or unitDef["canCloak"]) and not unitDef.customParams.commtype then --include only constructor and cloakies, and not com
					unitType =1 --//this unit-type will do avoidance even in camera view
					
					local isBuilder_ignoreTrue = false
					if unitDef.isBuilder then
						isBuilder_ignoreTrue = (options.dbg_IgnoreSelectedCons.value == true and selectedUnits_Meta[unitID] == true) --is (epicMenu force-selection-ignore is true? AND unit is a constructor?)
						if selectedUnits_Meta[unitID] then
							selectedCons_Meta[unitID] = true --remember selected Constructor
						end
					end
					if (unitDef.isBuilder and options.enableCons.value==false) or (isBuilder_ignoreTrue) then --//if ((Cons epicmenu option is false) OR (epicMenu force-selection-ignore is true)) AND it is a constructor, then... exclude (this) Cons
						unitType = 0 --//this unit-type excluded from avoidance
					end
					if unitDef["canCloak"] then --only cloakies + constructor that is cloakies
						fixedPointType=2 --//use aggressive behaviour (avoid more & more likely to ignore the users)
						if options.enableCloaky.value==false or (isBuilder_ignoreTrue) then --//if (Cloaky option is false) OR (epicMenu force-selection-ignore is true AND unit is a constructor) then exclude Cloaky
							unitType = 0
						end
					end
				--elseif not (unitDef["canFly"] or unitDef["isAirUnit"]) and not unitDef["canSubmerge"] then --include all ground unit, but excluding com & amphibious
				elseif not (unitDef["canFly"] or unitDef["isAirUnit"]) then --include all ground unit, including com
					unitType =2 --//this unit type only have avoidance outside camera view & while reloading (in camera view)
					if options.enableGround.value==false then --//if Ground unit epicmenu option is false then exclude Ground unit
						unitType = 0
					end
				elseif (unitDef.hoverAttack== true) then --include gunships
					unitType =3 --//this unit-type only have avoidance outside camera view & while reloading (in camera view)
					if options.enableGunship.value==false then --//if Gunship epicmenu option is false then exclude Gunship
						unitType = 0
					end
				-- elseif not (unitDef["canFly"] or unitDef["isAirUnit"]) and unitDef["canSubmerge"] then --include all amphibious unit & com
					-- unitType =4 --//this unit type only have avoidance outside camera view
					-- if options.enableAmphibious.value==false then --//if Gunship epicmenu option is false then exclude Gunship
						-- unitType = 0
					-- end
				end
				if (unitType>0) then
					local unitShieldPower, reloadableWeaponIndex,reloadTime,range,weaponType= -1, -1,-1,-1,-1
					unitShieldPower, reloadableWeaponIndex,reloadTime,range = CheckWeaponsAndShield(unitDef)
					arrayIndex=arrayIndex+1
					if range < maximumMeleeRange then
						weaponType = 0
					elseif range< thresholdForArty then
						weaponType = 1
					else
						weaponType = 2
					end
					relevantUnit[arrayIndex]={unitID = unitID, unitType = unitType, unitSpeed = unitSpeed, fixedPointType = fixedPointType, decloakScaling = decloakScaling,weaponInfo = {unitShieldPower = unitShieldPower, reloadableWeaponIndex = reloadableWeaponIndex,reloadTime = reloadTime,range=range}, isVisible = unitInView, weaponType = weaponType}
				end
			end
			if (turnOnEcho == 1) then --for debugging
				Spring.Echo("unitID(RefreshUnitList)" .. unitID)
				Spring.Echo("unitDef[humanName](RefreshUnitList)" .. unitDef["humanName"])
				Spring.Echo("((unitDef[builder] or unitDef[canCloak]) and unitDef[speed]>0)(RefreshUnitList):")
				Spring.Echo((unitDef.isBuilder or unitDef["canCloak"]) and unitDef["speed"]>0)
			end
		end
	end
	relevantUnit["count"]=arrayIndex -- store the array's lenght
	if (turnOnEcho == 1) then
		Spring.Echo("allMyUnits(RefreshUnitList): ")
		Spring.Echo(allMyUnits)
		Spring.Echo("relevantUnit(RefreshUnitList): ")
		Spring.Echo(relevantUnit)
	end
	return relevantUnit, attacker, commandTTL, selectedCons_Meta
end

-- detect initial enemy separation to detect "fleeing enemy"  later
function DoCalculation(passedInfo)
	local unitInMotion = passedInfo[1]
	local attacker = passedInfo[3]
	local selectedCons_Meta = passedInfo[4]
	-----
	local isAvoiding = nil
	local persistentData = {
		commandIndexTable= passedInfo[2],
		myTeamID= passedInfo[5],
		skippingTimer = passedInfo[6],
		now = passedInfo[7],
		commandTTL=passedInfo[8],
		waitForNetworkDelay=passedInfo[9],
		allyClusterInfo= passedInfo[10],
	}
	local gateKeeperOutput = {
		cQueueTemp=nil,
		allowExecution=nil,
		reloadAvoidance=nil,
	}
	local idTargetOutput = {
		targetCoordinate = nil,
		newCommand = nil,
		boxSizeTrigger = nil,
		graphCONSTANTtrigger = nil,
		fixedPointCONSTANTtrigger = nil,
		case = nil,
		targetID = nil,
	}
	if unitInMotion["count"] and unitInMotion["count"]>0 then --don't execute if no unit present
		for i=1, unitInMotion["count"], 1 do
			local unitID= unitInMotion[i]["unitID"] --get unitID for commandqueue
			if not spGetUnitIsDead(unitID) and (spGetUnitTeam(unitID)==persistentData["myTeamID"]) then --prevent execution if unit died during transit
				local cQueue = spGetCommandQueue(unitID,-1)
				gateKeeperOutput = GateKeeperOrCommandFilter(cQueue,persistentData, unitInMotion[i]) --filter/alter unwanted unit state by reading the command queue
				if gateKeeperOutput["allowExecution"] then
					--cQueue = cQueueTemp --cQueueTemp has been altered for identification, copy it to cQueue for use in DoCalculation() phase (note: command is not yet issued)
					--local boxSizeTrigger= unitInMotion[i][2]
					idTargetOutput=IdentifyTargetOnCommandQueue(cQueue,persistentData,gateKeeperOutput,unitInMotion[i]) --check old or new command
					if selectedCons_Meta[unitID] and idTargetOutput["boxSizeTrigger"]~= 4 then --if unitIsSelected and NOT using GUARD 'halfboxsize' (ie: is not guarding) then:
						idTargetOutput["boxSizeTrigger"] = 1 -- override all reclaim/ressurect/repair's deactivation 'halfboxsize' with the one for MOVE command (give more tolerance when unit is selected)
					end
					local reachedTarget = TargetBoxReached(unitID, idTargetOutput) --check if widget should ignore command
					if ((idTargetOutput["newCommand"] and gateKeeperOutput["cQueueTemp"][1].id==CMD_RAW_MOVE) or gateKeeperOutput["cQueueTemp"][2].id==CMD_RAW_MOVE) and (unitInMotion[i]["isVisible"]~= "yes") then --if unit is issued a move Command and is outside user's view. Note: is using cQueueTemp because cQueue can be NIL
						reachedTarget = false --force unit to continue avoidance despite close to target (try to circle over target until seen by user)
					elseif (idTargetOutput["case"] == "none") then
						reachedTarget = true --do not process unhandled command. This fix a case of unwanted behaviour when ZK's SmartAI issued a fight command on top of Avoidance's order and cause conflicting behaviour.
					elseif (not gateKeeperOutput["reloadAvoidance"] and idTargetOutput["case"] == 'attack') then
						reachedTarget = true --do not process direct attack command. Avoidance is not good enough for melee unit
					end
					if reachedTarget then --if reached target
						if not idTargetOutput["newCommand"] then
							spGiveOrderToUnit(unitID,CMD_REMOVE,{cQueue[1].tag,},0) --remove previously given (avoidance) command if reached target
						end
						persistentData["commandIndexTable"][unitID]=nil --empty the commandIndex (command history)
					else --execute when target not reached yet
					
						local losRadius = GetUnitLOSRadius(idTargetOutput["case"],unitInMotion[i]) --get LOS. also custom LOS for case=="attack" & weapon range >0
						local isMeleeAttacks = (idTargetOutput["case"] == 'attack' and unitInMotion[i]["weaponType"] == 0)
						local excludedEnemyID = (isMeleeAttacks) and idTargetOutput["targetID"]
						local surroundingUnits = GetAllUnitsInRectangle(unitID, losRadius, attacker,excludedEnemyID) --catalogue enemy
						if surroundingUnits["count"]~=0 then  --execute when enemy exist
							--local unitType =unitInMotion[i]["unitType"]
							--local unitSSeparation, losRadius = CatalogueMovingObject(surroundingUnits, unitID, lastPosition, unitType, losRadius) --detect initial enemy separation & alter losRadius when unit submerged
							local unitSSeparation, losRadius = CatalogueMovingObject(surroundingUnits, unitID, losRadius) --detect initial enemy separation & alter losRadius when unit submerged
							local impatienceTrigger = GetImpatience(idTargetOutput,unitID, persistentData)
							if (turnOnEcho == 1) then
								Spring.Echo("unitsSeparation(DoCalculation):")
								Spring.Echo(unitsSeparation)
							end
							local avoidanceCommand,orderArray= InsertCommandQueue(unitID,cQueue,gateKeeperOutput["cQueueTemp"],idTargetOutput["newCommand"],persistentData)--delete old widget command, update commandTTL, and send constructor to base for retreat
							if avoidanceCommand or (not options.dbg_RemoveAvoidanceSplitSecond.value) then
								if idTargetOutput["targetCoordinate"][1] == -1 then --no target
									idTargetOutput["targetCoordinate"] = UseNearbyAllyAsTarget(unitID,persistentData) --eg: when retreating to nearby ally
								end
								local newX, newZ = AvoidanceCalculator(losRadius,surroundingUnits,unitSSeparation,impatienceTrigger,persistentData,idTargetOutput,unitInMotion[i]) --calculate move solution
								local newY=spGetGroundHeight(newX,newZ)
								--Inserting command queue:--
								if (cQueue==nil or #cQueue<2) and gateKeeperOutput["cQueueTemp"][1].id == cMD_DummyG then --if #cQueueSyncTest is less than 2 mean unit has widget's mono-command, and cMD_DummyG mean its idle & out of view:
									orderArray[#orderArray+1]={CMD_INSERT, {0, CMD_RAW_MOVE, CMD.OPT_SHIFT, newX, newY, newZ}, {"alt"}} -- using SHIFT prevent unit from returning to old position. NOTE: we NEED to use insert here (rather than use direct move command) because in high-ping situation (where user's command do not register until last minute) user's command will get overriden if both widget's and user's command arrive at same time.
								else
									orderArray[#orderArray+1]={CMD_INSERT, {0, CMD_RAW_MOVE, CMD_OPT_INTERNAL, newX, newY, newZ}, {"alt"}} --spGiveOrderToUnit(unitID, CMD_INSERT, {0, CMD_RAW_MOVE, CMD_OPT_INTERNAL, newX, newY, newZ}, {"alt"}),  insert new command (Note: CMD_OPT_INTERNAL is used to mark that this command is widget issued and need not special treatment. ie: It won't get repeated if Repeat state is used.)
								end
								local lastIndx = persistentData["commandTTL"][unitID][1] --commandTTL[unitID]'s table lenght
								persistentData["commandTTL"][unitID][lastIndx+1] = {countDown = commandTimeoutG, widgetCommand= {newX, newZ}} --//remember this command on watchdog's commandTTL table. It has 4x*RefreshUnitUpdateRate* to expire
								persistentData["commandTTL"][unitID][1] = lastIndx+1 --refresh commandTTL[unitID]'s table lenght
								persistentData["commandIndexTable"][unitID]["widgetX"]=newX --update the memory table. So that next update can use to check if unit has new or old (widget's) command
								persistentData["commandIndexTable"][unitID]["widgetZ"]=newZ
								--end--
							end
							local orderCount = #orderArray
							if orderCount >0 then
								spGiveOrderArrayToUnitArray ({unitID},orderArray)
								isAvoiding = true
								
								if persistentData["waitForNetworkDelay"] then
									persistentData["waitForNetworkDelay"][2] = persistentData["waitForNetworkDelay"][2] + 1
								else
									persistentData["waitForNetworkDelay"] = {spGetGameSeconds(),1}
								end
								local moveOrderParams =  orderArray[orderCount][2]
								issuedOrderTo_G[unitID] = {moveOrderParams[4], moveOrderParams[5], moveOrderParams[6]}
							end
						end
					end --reachedTarget
				end --GateKeeperOrCommandFilter(cQueue, unitInMotion[i]) ==true
			end --if spGetUnitIsDead(unitID)==false
		end
	end --if unitInMotion[1]~=nil
	return persistentData,isAvoiding --send separation result away
end

function CountdownNetworkDelayWait(unitID)
	issuedOrderTo_G[unitID] = nil
	if waitForNetworkDelay_gbl then
		waitForNetworkDelay_gbl[2] = waitForNetworkDelay_gbl[2] - 1
		if waitForNetworkDelay_gbl[2]==0 then
			waitForNetworkDelay_gbl = nil
			-----------------
			local skippingTimer = skippingTimerG --is global table
			local cmd_then_DoCalculation_delay = cmd_then_DoCalculation_delayG
			local now =spGetGameSeconds()
			skippingTimer.networkDelay = now - skippingTimer.echoTimestamp --get the delay between previous Command and the latest 'LUA message Receive'
			--Method 2: use rolling average
			skippingTimer.storedDelay[skippingTimer.index] = skippingTimer.networkDelay --store network delay value in a rolling table
			skippingTimer.index = skippingTimer.index+1 --table index ++
			if skippingTimer.index > 11 then --roll the table/wrap around, so that the index circle the table. The 11-th sequence is for storing the oldest value, 1-st to 10-th sequence is for the average
				skippingTimer.index = 1
			end
			skippingTimer.averageDelay = skippingTimer.averageDelay + skippingTimer.networkDelay/10 - (skippingTimer.storedDelay[skippingTimer.index] or 0.3)/10 --add new delay and minus old delay, also use 0.3sec as the old delay if nothing is stored yet.
			--
			skippingTimer[2] = now + cmd_then_DoCalculation_delay --wait until 'cmd_then_DoCalculation_delayG'. The longer the better. The delay allow reliable unit direction to be derived from unit's motion
			
			skippingTimerG = skippingTimer
		end
	end
end

function ReportedNetworkDelay(playerIDa, defaultDelay)
	local _,_,_,_,_,totalDelay = Spring.GetPlayerInfo(playerIDa, false)
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
		commandTTL[unitID] = {1,} --Note: first entry is table lenght
	else --//if commandTTL is not empty then perform check and update its content appropriately. Its not empty when widget has issued a new command

		--//Method2: work by checking for cQueue after the command has expired. No latency could be as long as command's expiration time so it solve Method1's issue.
		local returnToReclaimOffset = 1 --
		for i=commandTTL[unitID][1], 2, -1 do --iterate downward over commandTTL, empty last entry when possible. Note: first table entry is the table's lenght, so we iterate down to only index 2
			if commandTTL[unitID][i] ~= nil then
				if commandTTL[unitID][i].countDown >0 then
					commandTTL[unitID][i].countDown = commandTTL[unitID][i].countDown - (1*returnToReclaimOffset) --count-down until zero and stop. Each iteration is minus 1 and then exit loop after 1 enty, or when countDown==0 remove command and then go to next entry and minus 2 and exit loop.
					break --//exit the iteration, do not go to next iteration until this entry expire first...
				elseif commandTTL[unitID][i].countDown <=0 then --if commandTTL is found to reach ZERO then remove the command, assume a 'TIMEOUT', then remove *this* watchdog entry
					local cQueue = spGetCommandQueue(unitID, 1) --// get unit's immediate command
					local cmdID, _, cmdTag, firstParam, _, secondParam = Spring.GetUnitCurrentCommand(unitID)
					if cmdID and
					( firstParam == commandTTL[unitID][i].widgetCommand[1]) and
					(secondParam == commandTTL[unitID][i].widgetCommand[2]) then --//if current command is similar to the one once issued by widget then delete it
						spGiveOrderToUnit(unitID, CMD_REMOVE, {cmdTag}, 0)
					end
					commandTTL[unitID][i] = nil --empty watchdog entry
					commandTTL[unitID][1] = i-1 --refresh table lenght
					returnToReclaimOffset = 2 --when the loop iterate back to a reclaim command: remove 2 second from its countdown (accelerate expiration by 2 second). This is for aesthetic reason and didn't effect system's mechanic.  Since constructor always retreat with 2 command (avoidance+return to base), remove the countdown from the avoidance.
				end
			end
		end
	end
	return commandTTL
end

function CheckWeaponsAndShield (unitDef)
	--global variable
	local reloadableWeaponCriteria = reloadableWeaponCriteriaG --minimum reload time for reloadable weapon
	----
	local unitShieldPower, reloadableWeaponIndex =-1, -1 --assume unit has no shield and no reloadable/slow-loading weapons
	local fastWeaponIndex =  -1 --temporary variables
	local fastestReloadTime, fastReloadRange = 999,-1
	for currentWeaponIndex, weapons in ipairs(unitDef.weapons) do --reference: gui_contextmenu.lua by CarRepairer
		local weaponsID = weapons.weaponDef
		local weaponsDef = WeaponDefs[weaponsID]
		if weaponsDef.name and not (weaponsDef.name:find('fake') or weaponsDef.name:find('noweapon')) then --reference: gui_contextmenu.lua by CarRepairer
			if weaponsDef.isShield then
				unitShieldPower = weaponsDef.shieldPower --remember the shield power of this unit
			else --if not shield then this is conventional weapon
				local reloadTime = weaponsDef.reload
				if reloadTime < fastestReloadTime then --find the weapon with the smallest reload time
					fastestReloadTime = reloadTime
					fastReloadRange = weaponsDef.range
					fastWeaponIndex = currentWeaponIndex --remember the index of the fastest weapon.
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
	return unitShieldPower, reloadableWeaponIndex,fastestReloadTime,fastReloadRange
end

function GateKeeperOrCommandFilter (cQueue,persistentData, unitInMotionSingleUnit)
	local allowExecution = false
	local reloadAvoidance = false -- indicate to way way downstream processes whether avoidance is based on weapon reload/shieldstate
	if cQueue~=nil then --prevent ?. Forgot...
		local isReloading = CheckIfUnitIsReloading(unitInMotionSingleUnit) --check if unit is reloading/shieldCritical
		local unitID = unitInMotionSingleUnit["unitID"]
		local holdPosition= (Spring.Utilities.GetUnitMoveState(unitID) == 0)
		local unitType = unitInMotionSingleUnit["unitType"]
		local unitInView = unitInMotionSingleUnit["isVisible"]
		local retreating = false
		if options.retreatAvoidance.value and WG.retreatingUnits then
			retreating = (WG.retreatingUnits[unitID]~=nil or spGetUnitRulesParam(unitID,"isRetreating")==1)
		end
		--if ((unitInView ~= "yes") or isReloading or (unitType == 1 and options.cloakyAlwaysFlee.value)) then --if unit is out of user's vision OR is reloading OR is cloaky, and:
			if (cQueue[1] == nil or #cQueue == 1) then --if unit is currently idle OR with-singular-mono-command (eg: automated move order or auto-attack), then:
				--if (not holdPosition) then --if unit is not "hold position", then:
					local idleOrIsDodging = (cQueue[1] == nil) or (#cQueue == 1 and cQueue[1].id == CMD_RAW_MOVE and (not cQueue[2] or cQueue[2].id~=false)) --is idle completely, or is given widget's CMD_RAW_MOVE and not spontaneous engagement signature (note: CMD_RAW_MOVE or any other command will not end with CMD_STOP when issued by widget)
					local dummyCmd
					if idleOrIsDodging then
						cQueue={{id = cMD_DummyG, params = {-1 ,-1,-1}, options = {}}, {id = CMD_STOP, params = {-1 ,-1,-1}, options = {}}, nil} --select cMD_DummyG if unit is to flee without need to return to old position,
					elseif cQueue[1].id < 0 then
						cQueue[2] = {id = CMD_STOP, params = {-1 ,-1,-1}, options = {}} --automated build (mono command issued by CentralBuildAI widget). We append CMD_STOP so it look like normal build command.
					else
						cQueue={{id = cMD_Dummy_atkG, params = {-1 ,-1,-1}, options = {}}, {id = CMD_STOP, params = {-1 ,-1,-1}, options = {}}, nil} --select cMD_Dummy_atkG if unit is auto-attack & reloading (as in: isReloading + (no command or mono command)) and doesn't mind being bound to old position
					end
					--flag unit with a FAKE COMMAND. Will be used to initiate avoidance on idle unit & non-viewed unit. Note: this is not real command, its here just to trigger avoidance.
					--Note2: negative target only deactivate attraction function, but avoidance function is still active & output new coordinate if enemy is around
				--end
			end
		--end
		if cQueue[1]~=nil then --prevent idle unit from executing the system (prevent crash), but idle unit with FAKE COMMAND (cMD_DummyG) is allowed.
			local isStealthOrConsUnit = (unitType == 1)
			local isNotViewed = (unitInView ~= "yes")
			local isCommonConstructorCmd = (cQueue[1].id == CMD_REPAIR or cQueue[1].id < 0 or cQueue[1].id == CMD_RESURRECT)
			local isReclaimCmd = (cQueue[1].id == CMD_RECLAIM)
			local isMoveCommand = (cQueue[1].id == CMD_RAW_MOVE)
			local isNormCommand = (isCommonConstructorCmd or isMoveCommand) -- ALLOW unit with command: repair (40), build (<0), reclaim (90), ressurect(125), move(10),
			--local isStealthOrConsUnitTypeOrIsNotViewed = isStealthOrConsUnit or (unitInView ~= "yes" and unitType~= 3)--ALLOW only unit of unitType=1 OR (all unitTypes that is outside player's vision except gunship)
			local isStealthOrConsUnitTypeOrIsNotViewed = isStealthOrConsUnit or isNotViewed--ALLOW unit of unitType=1 (cloaky, constructor) OR all unitTypes that is outside player's vision
			local _1stAttackSignature = (cQueue[1].id == CMD_ATTACK)
			local _1stGuardSignature = (cQueue[1].id == CMD_GUARD)
			local _2ndAttackSignature = false --attack command signature
			local _2ndGuardSignature = false --guard command signature
			if #cQueue >=2 then --check if the command-queue is masked by widget's previous command, but the actual originality check will be performed by TargetBoxReached() later.
				_2ndAttackSignature = (cQueue[1].id == CMD_RAW_MOVE and cQueue[2].id == CMD_ATTACK)
				_2ndGuardSignature = (cQueue[1].id == CMD_RAW_MOVE and cQueue[2].id == CMD_GUARD)
			end
			local isAbundanceResource = (spGetTeamResources(persistentData["myTeamID"], "metal") > 10)
			local isReloadingAttack = (isReloading and (((_1stAttackSignature or _2ndAttackSignature) and options.enableReloadAvoidance.value) or (cQueue[1].id == cMD_DummyG or cQueue[1].id == cMD_Dummy_atkG))) --any unit with attack command or was idle that is Reloading
			local isGuardState = (_1stGuardSignature or _2ndGuardSignature)
			local isAttackingState = (_1stAttackSignature or _2ndAttackSignature)
			local isForceCloaked = spGetUnitIsCloaked(unitID) and (unitType==2 or unitType==3) --any unit with type 3 (gunship) or type 2 (ground units except cloaky) that is cloaked.
			local isRealIdle = cQueue[1].id == cMD_DummyG --FAKE (IDLE) COMMAND
			local isStealthOrConsUnitAlwaysFlee = isStealthOrConsUnit and options.cloakyAlwaysFlee.value
			if ((isNormCommand or (isReclaimCmd and isAbundanceResource)) and isStealthOrConsUnitTypeOrIsNotViewed and not holdPosition) or --execute on: unit with generic mobility command (or reclaiming during abundance resource): for UnitType==1 unit (cloaky, constructor) OR for any unit outside player view... & which is not holding position
			(isRealIdle and (isNotViewed or isStealthOrConsUnitAlwaysFlee) and not holdPosition) or --execute on: any unit that is really idle and out of view... & is not hold position
			(isReloadingAttack and not holdPosition) or --execute on: any unit which is reloading... & is not holding position
			-- (isAttackingState and isStealthOrConsUnitAlwaysFlee and not holdPosition) or --execute on: always-fleeing cloaky unit that about to attack... & is not holding position
			(isGuardState and not holdPosition) or --execute on: any unit which is guarding another unit...  & is not hold position
			(isForceCloaked and isMoveCommand and not holdPosition) or --execute on: any normal unit being cloaked and is moving... & is not hold position.
			(retreating and not holdPosition) --execute on: any retreating unit
			then
				local isReloadAvoidance = (isReloadingAttack and not holdPosition)
				if isReloadAvoidance or #cQueue>=2 then --check cQueue for lenght to prevent STOP command from short circuiting the system (code downstream expect cQueue of length>=2)
					if isReloadAvoidance or cQueue[2].id~=false then --prevent a spontaneous enemy engagement from short circuiting the system
						allowExecution = true --allow execution
						reloadAvoidance = isReloadAvoidance
					end --if cQueue[2].id~=false
					if (turnOnEcho == 1) then Spring.Echo(cQueue[2].id) end --for debugging
				end --if #cQueue>=2
			end --if ((cQueue[1].id==40 or cQueue[1].id<0 or cQueue[1].id==90 or cQueue[1].id==10 or cQueue[1].id==125) and (unitInMotion[i][2]==1 or unitInMotion[i].isVisible == nil)
		end --if cQueue[1]~=nil
	end --if cQueue~=nil
	local output = {
		cQueueTemp = cQueue,
		allowExecution = allowExecution,
		reloadAvoidance = reloadAvoidance,
	}
	return output --disallow/allow execution
end

--check if widget's command or user's command
function IdentifyTargetOnCommandQueue(cQueueOri,persistentData,gateKeeperOutput,unitInMotionSingleUnit) --//used by DoCalculation()
	local unitID = unitInMotionSingleUnit["unitID"]
	local commandIndexTable = persistentData["commandIndexTable"]
	
	local newCommand=true -- immediately assume user's command
	local output
	--------------------------------------------------
	if commandIndexTable[unitID]==nil then --memory was empty, so fill it with zeros or non-significant number
		commandIndexTable[unitID]={widgetX=-2, widgetZ=-2 , patienceIndexA=0}
	else
		local a = -1
		local c = -1
		local b = math.modf(commandIndexTable[unitID]["widgetX"])
		local d = math.modf(commandIndexTable[unitID]["widgetZ"])
		if cQueueOri[1] then
			a = math.modf(dNil(cQueueOri[1].params[1])) --using math.modf to remove trailing decimal (only integer for matching). In case high resolution cause a fail matching with server's numbers... and use dNil incase wreckage suddenly disappear.
			c = math.modf(dNil(cQueueOri[1].params[3])) --dNil: if it is a reclaim or repair order (no z coordinate) then replace it with -1 (has similar effect to the "nil")
		end
		newCommand= (a~= b and c~=d)--compare current command with in memory
		if (turnOnEcho == 1) then --debugging
			Spring.Echo("unitID(IdentifyTargetOnCommandQueue)" .. unitID)
			Spring.Echo("commandIndexTable[unitID][widgetX](IdentifyTargetOnCommandQueue):" .. commandIndexTable[unitID]["widgetX"])
			Spring.Echo("commandIndexTable[unitID][widgetZ](IdentifyTargetOnCommandQueue):" .. commandIndexTable[unitID]["widgetZ"])
			Spring.Echo("newCommand(IdentifyTargetOnCommandQueue):")
			Spring.Echo(newCommand)
			Spring.Echo("cQueueOri[1].params[1](IdentifyTargetOnCommandQueue):" .. cQueueOri[1].params[1])
			Spring.Echo("cQueueOri[1].params[2](IdentifyTargetOnCommandQueue):" .. cQueueOri[1].params[2])
			Spring.Echo("cQueueOri[1].params[3](IdentifyTargetOnCommandQueue):" .. cQueueOri[1].params[3])
			if cQueueOri[2]~=nil then
				Spring.Echo("cQueue[2].params[1](IdentifyTargetOnCommandQueue):")
				Spring.Echo(cQueueOri[2].params[1])
				Spring.Echo("cQueue[2].params[3](IdentifyTargetOnCommandQueue):")
				Spring.Echo(cQueueOri[2].params[3])
			end
		end
	end
	if newCommand then	--if user's new command
		output = ExtractTarget (1,gateKeeperOutput["cQueueTemp"],unitInMotionSingleUnit)
		commandIndexTable[unitID]["patienceIndexA"]=0 --//reset impatience counter
	else  --if widget's previous command
		output = ExtractTarget (2,gateKeeperOutput["cQueueTemp"],unitInMotionSingleUnit)
	end
	output["newCommand"] = newCommand
	persistentData["commandIndexTable"] = commandIndexTable --note: table is referenced by memory, so it will update even without return value
	return output --return target coordinate
end

--ignore command set on this box
function TargetBoxReached (unitID, idTargetOutput)
	----Global Constant----
	local halfTargetBoxSize = halfTargetBoxSize_g
	-----------------------
	local boxSizeTrigger = idTargetOutput["boxSizeTrigger"]
	local targetCoordinate = idTargetOutput["targetCoordinate"]
	local currentX,_,currentZ = spGetUnitPosition(unitID)
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
function GetUnitLOSRadius(case,unitInMotionSingleUnit)
	----Global Constant----
	local extraLOSRadiusCONSTANT = extraLOSRadiusCONSTANTg
	-----------------------
	local fastestWeapon = unitInMotionSingleUnit["weaponInfo"]
	local unitID =unitInMotionSingleUnit["unitID"]
	local unitDefID= spGetUnitDefID(unitID)
	local unitDef= UnitDefs[unitDefID]
	local losRadius =550 --arbitrary (scout LOS)
	if unitDef~=nil then --if unitDef is not empty then use the following LOS
		losRadius= unitDef.losRadius --in normal case use real LOS
		losRadius= losRadius + extraLOSRadiusCONSTANT --add extra detection range for beyond LOS (radar)
		if case=="attack" then --if avoidance is for attack enemy: use special LOS
			
			local unitFastestReloadableWeapon = fastestWeapon["reloadableWeaponIndex"] --retrieve the quickest reloadable weapon index
			if unitFastestReloadableWeapon ~= -1 then
				local weaponRange = fastestWeapon["range"] --retrieve weapon range
				losRadius = math.max(weaponRange*0.75, losRadius) --select avoidance's detection-range to 75% of weapon range or maintain to losRadius, select which is the biggest (Note: big LOSradius mean big detection but also big "distanceCONSTANTunit_G" if "useLOS_distanceCONSTANTunit_G==true", thus bigger avoidance circle)
			end
		end
		if unitDef.isBuilder then
			losRadius = losRadius + extraLOSRadiusCONSTANT --add additional/more detection range for constructors for quicker reaction vs enemy radar dot
		end
	end
	return losRadius
end

--return a table of surrounding enemy
function GetAllUnitsInRectangle(unitID, losRadius, attacker,excludedEnemyID)
	local x,y,z = spGetUnitPosition(unitID)
	local unitDefID = spGetUnitDefID(unitID)
	local unitDef = UnitDefs[unitDefID]
	local iAmConstructor = unitDef.isBuilder
	local iAmNotCloaked = not spGetUnitIsCloaked(unitID) --unitID is "this" unit (our unit)
	
	local unitsInRectangle = spGetUnitsInRectangle(x-losRadius, z-losRadius, x+losRadius, z+losRadius)
	local relevantUnit={}
	local arrayIndex=0
	
	--add attackerID into enemy list
	relevantUnit, arrayIndex = AddAttackerIDToEnemyList (unitID, losRadius, relevantUnit, arrayIndex, attacker)
	--
	for _, rectangleUnitID in ipairs(unitsInRectangle) do
		local isAlly= spIsUnitAllied(rectangleUnitID)
		if (rectangleUnitID ~= unitID) and not isAlly and rectangleUnitID~=excludedEnemyID then --filter out ally units and self and exclusive-exclusion
			local rectangleUnitTeamID = spGetUnitTeam(rectangleUnitID)
			if (rectangleUnitTeamID ~= gaiaTeamID) then --filter out gaia (non aligned unit)
				local recUnitDefID = spGetUnitDefID(rectangleUnitID)
				local registerEnemy = false
				if recUnitDefID~=nil and (iAmConstructor and iAmNotCloaked) then --if enemy is in LOS & I am a visible constructor: then
					local recUnitDef = UnitDefs[recUnitDefID] --retrieve enemy definition
					local enemyParalyzed,_,_ = spGetUnitIsStunned (rectangleUnitID)
					local disarmed = spGetUnitRulesParam(rectangleUnitID,"disarmed")
					if recUnitDef["weapons"][1]~=nil and not enemyParalyzed and (not disarmed or disarmed ~= 1) then -- check enemy for weapons and paralyze effect
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
	relevantUnit["count"] = arrayIndex
	return relevantUnit
end

--allow a unit to recognize fleeing enemy; so it doesn't need to avoid them
function CatalogueMovingObject(surroundingUnits, unitID,losRadius)
	local unitsSeparation={}
	if (surroundingUnits["count"] and surroundingUnits["count"]>0) then --don't catalogue anything if no enemy exist
		local unitDepth = 99
		local sonarDetected = false
		local halfLosRadius = losRadius/2
		--if unitType == 4 then --//if unit is amphibious, then:
			_,unitDepth,_ = spGetUnitPosition(unitID) --//get unit's y-axis. Less than 0 mean submerged.
		--end
		local unitXvel,_,unitZvel = spGetUnitVelocity(unitID)
		local unitSpeed = math.sqrt(unitXvel*unitXvel+unitZvel*unitZvel)
		for i=1,surroundingUnits["count"],1 do --//iterate over all enemy list.
			local unitRectangleID=surroundingUnits[i]
			if (unitRectangleID ~= nil) then
				local recXvel,_,recZvel = spGetUnitVelocity(unitRectangleID)
				recXvel = recXvel or 0
				recZvel = recZvel or 0
				local recSpeed = math.sqrt(recXvel*recXvel+recZvel*recZvel)
				local relativeAngle 	= GetUnitRelativeAngle (unitID, unitRectangleID)
				local unitDirection,_,_	= GetUnitDirection(unitID)
				local unitSeparation	= spGetUnitSeparation (unitID, unitRectangleID, true)
				if math.abs(unitDirection- relativeAngle)< (collisionAngleG) or (recSpeed>3*unitSpeed) then --unit inside the collision angle? or is super fast? remember unit currrent saperation for comparison again later
					unitsSeparation[unitRectangleID]=unitSeparation
				else --unit outside the collision angle? set to an arbitrary 9999 which mean "do not need comparision, always avoid"
					unitsSeparation[unitRectangleID]=9999
				end
				if unitDepth <0 then --//if unit is submerged, then:
					--local enemySonarRadius = (spGetUnitSensorRadius(unitRectangleID,"sonar") or 0)
					local enemyDefID = spGetUnitDefID(unitRectangleID)
					local unitDefsSonarContent = 9999 --//set to very large so that any un-identified contact is assumed as having sonar (as threat).
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

function GetImpatience(idTargetOutput,unitID, persistentData)
	local newCommand = idTargetOutput["newCommand"]
	local commandIndexTable = persistentData["commandIndexTable"]
	local impatienceTrigger=1 --zero will de-activate auto reverse
	if commandIndexTable[unitID]["patienceIndexA"]>=6 then impatienceTrigger=0 end --//if impatience index level 6 (after 6 time avoidance) then trigger impatience. Impatience will deactivate/change some values downstream
	if not newCommand and activateImpatienceG==1 then
		commandIndexTable[unitID]["patienceIndexA"]=commandIndexTable[unitID]["patienceIndexA"]+1 --increase impatience index if impatience system is activate
	end
	if (turnOnEcho == 1) then Spring.Echo("commandIndexTable[unitID][patienceIndexA] (GetImpatienceLevel) " .. commandIndexTable[unitID]["patienceIndexA"]) end
	persistentData["commandIndexTable"] = commandIndexTable --Note: this will update since its referenced by memory
	return impatienceTrigger
end

function UseNearbyAllyAsTarget(unitID, persistentData)
	local x,y,z = -1,-1,-1
	if WG.OPTICS_cluster then
		local allyClusterInfo = persistentData["allyClusterInfo"]
		local myTeamID = persistentData["myTeamID"]
		if (allyClusterInfo["age"]>= 3) then --//only update after 4 cycle:
			allyClusterInfo["age"]= 0
			allyClusterInfo["coords"] = {}
			local allUnits = spGetAllUnits()
			local unorderedUnitList = {}
			for i=1, #allUnits, 1 do --//convert unit list into a compatible format for the Clustering function below
				local unitID_list = allUnits[i]
				if spIsUnitAllied(unitID_list, unitID) then
					local x,y,z = spGetUnitPosition(unitID_list)
					local unitDefID_list = spGetUnitDefID(unitID_list)
					local unitDef = UnitDefs[unitDefID_list]
					local unitSpeed =unitDef["speed"]
					if (unitSpeed>0) then --//if moving units
						if (unitDef.isBuilder) and not unitDef.customParams.commtype then --if constructor
							--intentionally empty. Not include builder.
						elseif unitDef.customParams.commtype then --if COMMANDER,
							unorderedUnitList[unitID_list] = {x,y,z} --//store
						elseif not (unitDef["canFly"] or unitDef["isAirUnit"]) then --if all ground unit, amphibious, and ships (except commander)
							unorderedUnitList[unitID_list] = {x,y,z} --//store
						elseif (unitDef.hoverAttack== true) then --if gunships
							--intentionally empty. Not include gunships.
						end
					else --if buildings
						unorderedUnitList[unitID_list] = {x,y,z} --//store
					end
				end
			end
			local cluster, _ = WG.OPTICS_cluster(unorderedUnitList, 600,3, myTeamID,300) --//find clusters with atleast 3 unit per cluster and with at least within 300-elmo from each other
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
				allyClusterInfo["coords"][#allyClusterInfo["coords"]+1] = {meanX, meanY, meanZ} --//record cluster position
			end
		end --//end cluster detection
		local nearestCluster = -1
		local nearestDistance = 99999
		local coordinateList = allyClusterInfo["coords"]
		local px,_,pz = spGetUnitPosition(unitID)
		for i=1, #coordinateList do
			local distance = Distance(coordinateList[i][1], coordinateList[i][3] , px, pz)
			if distance < nearestDistance then
				nearestDistance = distance
				nearestCluster = i
			end
		end
		if nearestCluster > 0 then
			x,y,z = coordinateList[nearestCluster][1],coordinateList[nearestCluster][2],coordinateList[nearestCluster][3]
		end
		persistentData["allyClusterInfo"] = allyClusterInfo --update content
	end
	if x == -1 then
		local nearbyAllyUnitID = Spring.GetUnitNearestAlly (unitID, 600)
		if nearbyAllyUnitID ~= nearbyAllyUnitID then
			x,y,z = spGetUnitPosition(nearbyAllyUnitID)
		end
	end
	return {x,y,z}
end

function AvoidanceCalculator(losRadius,surroundingUnits,unitsSeparation,impatienceTrigger,persistentData,idTargetOutput,unitInMotionSingleUnit)
	local newCommand = idTargetOutput["newCommand"]
	local skippingTimer = persistentData["skippingTimer"]
	local unitID = unitInMotionSingleUnit["unitID"]
	local unitSpeed = unitInMotionSingleUnit["unitSpeed"]
	local graphCONSTANTtrigger = idTargetOutput["graphCONSTANTtrigger"]
	local fixedPointCONSTANTtrigger = idTargetOutput["fixedPointCONSTANTtrigger"]
	local targetCoordinate = idTargetOutput["targetCoordinate"]
	local decloakScaling = unitInMotionSingleUnit["decloakScaling"]
	
	if (unitID~=nil) and (targetCoordinate ~= nil) then --prevent idle/non-existent/ unit with invalid command from using collision avoidance
		local aCONSTANT 								= aCONSTANTg --attractor constant (amplitude multiplier)
		local obsCONSTANT 								=obsCONSTANTg --repulsor constant (amplitude multiplier)
		local unitDirection, _, wasMoving		= GetUnitDirection(unitID) --get unit direction
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
		
		local sumAllUnitOutput = {
			wTotal = nil,
			dSum = nil,
			fObstacleSum = nil,
			dFobstacle = nil,
			nearestFrontObstacleRange = nil,
			normalizingFactor = nil,
		}
		--count every enemy unit and sum its contribution to the obstacle/repulsor variable
		sumAllUnitOutput=SumAllUnitAroundUnitID (obsCONSTANT,unitDirection,losRadius,surroundingUnits,unitsSeparation,impatienceTrigger,graphCONSTANTtrigger,unitInMotionSingleUnit,skippingTimer)
		--calculate appropriate behaviour based on the constant and above summation value
		local wTarget, wObstacle = CheckWhichFixedPointIsStable (fTargetSlope, fTarget, fixedPointCONSTANTtrigger,sumAllUnitOutput)
		--convert an angular command into a coordinate command
		local newX, newZ= ToCoordinate(wTarget, wObstacle, fTarget, unitDirection, losRadius, impatienceTrigger, skippingTimer, wasMoving, newCommand,sumAllUnitOutput, unitInMotionSingleUnit)
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
function InsertCommandQueue(unitID,cQueue,cQueueGKPed,newCommand,persistentData)
	------- localize global constant:
	local consRetreatTimeout = consRetreatTimeoutG
	local commandTimeout = commandTimeoutG
	------- end global constant
	local now = persistentData["now"]
	local commandTTL = persistentData["commandTTL"]
	local commandIndexTable = persistentData["commandIndexTable"]

	local orderArray={nil,nil,nil,nil,nil,nil}
	local queueIndex=1
	local avoidanceCommand = true
	if not newCommand then  --if widget's command then delete it
		if not cQueue or not cQueue[1] then --happen when unit has NIL command (this), and somehow is same as widget's command (see: IdentifyTargetOnCommandQueue), and somehow unit currently has mono-command (see: CheckUserOverride)
			if turnOnEcho==2 then
				Spring.Echo("UnitIsDead (InsertCommandQueue):")
				Spring.Echo(Spring.GetUnitIsDead(unitID))
				Spring.Echo("ValidUnitID (InsertCommandQueue):")
				Spring.Echo(Spring.ValidUnitID(unitID))
				Spring.Echo("WidgetX (InsertCommandQueue):")
				Spring.Echo(commandIndexTable[unitID]["widgetX"])
				Spring.Echo("WidgetZ (InsertCommandQueue):")
				Spring.Echo(commandIndexTable[unitID]["widgetZ"])
			end
		else
			orderArray[1] = {CMD_REMOVE, {cQueue[1].tag}, {}} --spGiveOrderToUnit(unitID, CMD_REMOVE, {cQueue[1].tag}, {} ) --delete previous widget command
			local lastIndx = commandTTL[unitID][1] --commandTTL[unitID]'s table lenght
			commandTTL[unitID][lastIndx] = nil --//delete the last watchdog entry (the "not newCommand" means that previous widget's command haven't changed yet (nothing has interrupted this unit, same is with commandTTL), and so if command is to delete then it is good opportunity to also delete its timeout info at *commandTTL* too). Deleting this entry mean that this particular command will no longer be checked for timeout.
			commandTTL[unitID][1] = lastIndx -1 --refresh table lenght
			-- Technical note: emptying commandTTL[unitID][#commandTTL[unitID]] is not technically required (not emptying it only make commandTTL countdown longer, but a mistake in emptying a commandTTL could make unit more prone to stuck when fleeing to impassable coordinate.
			queueIndex=2 --skip index 1 of stored command. Skip widget's command
		end
	end
	if (#cQueue>=queueIndex+1) then --if is queue={reclaim, area reclaim,stop}, or: queue={move,reclaim, area reclaim,stop}, or: queue={area reclaim, stop}, or:queue={move, area reclaim, stop}.
		if (cQueue[queueIndex].id==CMD_REPAIR or cQueue[queueIndex].id==CMD_RECLAIM or cQueue[queueIndex].id==CMD_RESURRECT) then --if first (1) queue is reclaim/ressurect/repair
			if cQueue[queueIndex+1].id==CMD_RECLAIM or cQueue[queueIndex+1].id==CMD_RESURRECT then --if second (2) queue is also reclaim/ressurect
				--if (not Spring.ValidFeatureID(cQueue[queueIndex+1].params[1]-Game.maxUnits) or (not Spring.ValidFeatureID(cQueue[queueIndex+1].params[1]))) and not Spring.ValidUnitID(cQueue[queueIndex+1].params[1]) then --if it was an area command
				if (cQueue[queueIndex+1].params[4]~=nil) then  --second (2) queue is area reclaim. area command should has no "nil" on params 1,2,3, & 4
					orderArray[#orderArray+1] = {CMD_REMOVE, {cQueue[queueIndex].tag}, {}} -- spGiveOrderToUnit(unitID, CMD_REMOVE, {cQueue[queueIndex].tag}, {} ) --delete latest reclaiming/ressurecting command (skip the target:wreck/units). Allow command reset
					local coordinate = (FindSafeHavenForCons(unitID, now)) or  (cQueue[queueIndex+1])
					orderArray[#orderArray+1] = {CMD_INSERT, {0, CMD_RAW_MOVE, CMD_OPT_INTERNAL, coordinate.params[1], coordinate.params[2], coordinate.params[3]}, {"alt"}} --spGiveOrderToUnit(unitID, CMD_INSERT, {0, CMD_RAW_MOVE, CMD_OPT_INTERNAL, coordinate.params[1], coordinate.params[2], coordinate.params[3]}, {"alt"} ) --divert unit to the center of reclaim/repair command OR to any heavy concentration of ally (haven)
					local lastIndx = commandTTL[unitID][1] --commandTTL[unitID]'s table lenght
					commandTTL[unitID][lastIndx +1] = {countDown = consRetreatTimeout, widgetCommand= {coordinate.params[1], coordinate.params[3]}} --//remember this command on watchdog's commandTTL table. It has 15x*RefreshUnitUpdateRate* to expire
					commandTTL[unitID][1] = lastIndx +1--refresh table lenght
					avoidanceCommand = false
				end
			elseif cQueue[queueIndex+1].id==CMD_REPAIR then --if second (2) queue is also repair
				--if (not Spring.ValidFeatureID(cQueue[queueIndex+1].params[1]-Game.maxUnits) or (not Spring.ValidFeatureID(cQueue[queueIndex+1].params[1]))) and not Spring.ValidUnitID(cQueue[queueIndex+1].params[1]) then --if it was an area command
				if (cQueue[queueIndex+1].params[4]~=nil) then  --area command should has no "nil" on params 1,2,3, & 4
					orderArray[#orderArray+1] = {CMD_REMOVE, {cQueue[queueIndex].tag}, {}} --spGiveOrderToUnit(unitID, CMD_REMOVE, {cQueue[queueIndex].tag}, {} ) --delete current repair command, (skip the target:units). Reset the repair command
				end
			elseif (cQueue[queueIndex].params[4]~=nil) then  --if first (1) queue is area reclaim (an area reclaim without any wreckage to reclaim). area command should has no "nil" on params 1,2,3, & 4
				local coordinate = (FindSafeHavenForCons(unitID, now)) or  (cQueue[queueIndex])
				orderArray[#orderArray+1] = {CMD_INSERT, {0, CMD_RAW_MOVE, CMD_OPT_INTERNAL, coordinate.params[1], coordinate.params[2], coordinate.params[3]}, {"alt"}} --spGiveOrderToUnit(unitID, CMD_INSERT, {0, CMD_RAW_MOVE, CMD_OPT_INTERNAL, coordinate.params[1], coordinate.params[2], coordinate.params[3]}, {"alt"} ) --divert unit to the center of reclaim/repair command
				local lastIndx = commandTTL[unitID][1] --commandTTL[unitID]'s table lenght
				commandTTL[unitID][lastIndx+1] = {countDown = commandTimeout, widgetCommand= {coordinate.params[1], coordinate.params[3]}} --//remember this command on watchdog's commandTTL table. It has 2x*RefreshUnitUpdateRate* to expire
				commandTTL[unitID][1] = lastIndx +1--refresh table lenght
				avoidanceCommand = false
			end
		end
	end
	if (turnOnEcho == 1) then
		Spring.Echo("unitID(InsertCommandQueue)" .. unitID)
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
	persistentData["commandTTL"] = commandTTL ----return updated memory tables used to check for command's expiration age.
	return avoidanceCommand, orderArray --return whether new command is to be issued
end
---------------------------------Level2
---------------------------------Level3 (low-level function)
--check if unit is vulnerable/reloading
function CheckIfUnitIsReloading(unitInMotionSingleUnitTable)
	---Global Constant---
	local criticalShieldLevel =criticalShieldLevelG
	local minimumRemainingReloadTime =minimumRemainingReloadTimeG
	local secondPerGameFrame =secondPerGameFrameG
	------
	--local unitType = unitInMotionSingleUnitTable["unitType"] --retrieve stored unittype
	local shieldIsCritical =false
	local weaponIsEmpty = false
	local fastestWeapon = unitInMotionSingleUnitTable["weaponInfo"]
	--if unitType ==2 or unitType == 1 then
		local unitID = unitInMotionSingleUnitTable["unitID"] --retrieve stored unitID
		local unitShieldPower = fastestWeapon["unitShieldPower"] --retrieve registered full shield power
		if unitShieldPower ~= -1 then
			local _, currentPower = spGetUnitShieldState(unitID)
			if currentPower~=nil then
				if currentPower/unitShieldPower <criticalShieldLevel then
					shieldIsCritical = true
				end
			end
		end
		local unitFastestReloadableWeapon = fastestWeapon["reloadableWeaponIndex"] --retrieve the quickest reloadable weapon index
		local fastestReloadTime = fastestWeapon["reloadTime"] --in second
		if unitFastestReloadableWeapon ~= -1 then
			-- local unitSpeed = unitInMotionSingleUnitTable["unitSpeed"]
			-- local distancePerSecond = unitSpeed
			-- local fastUnit_shortRange = unitSpeed > fastestWeapon["range"] --check if unit can exit range easily if *this widget* evasion is activated
			-- local unitValidForReloadEvasion = true
			-- if fastUnit_shortRange then
				-- unitValidForReloadEvasion = fastestReloadTime > 2.5 --check if unit will have enough time to return from *this widget* evasion
			-- end
			-- if unitValidForReloadEvasion then
				local weaponReloadFrame = spGetUnitWeaponState(unitID, unitFastestReloadableWeapon, "reloadFrame") --Somehow the weapon table actually start at "0", so minus 1 from actual value
				local currentFrame, _ = spGetGameFrame()
				local remainingTime = (weaponReloadFrame - currentFrame)*secondPerGameFrame --convert to second
				-- weaponIsEmpty = (remainingTime > math.max(minimumRemainingReloadTime,fastestReloadTime*0.25))
				weaponIsEmpty = (remainingTime > minimumRemainingReloadTime)
				if (turnOnEcho == 1) then --debugging
					Spring.Echo(unitFastestReloadableWeapon)
					Spring.Echo(fastestWeapon["range"])
				end
			-- end
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

function ExtractTarget (queueIndex, cQueue,unitInMotionSingleUnit) --//used by IdentifyTargetOnCommandQueue()
	local unitID = unitInMotionSingleUnit["unitID"]
	local targetCoordinate = {nil,nil,nil}
	local fixedPointCONSTANTtrigger = unitInMotionSingleUnit["fixedPointType"]
	local unitVisible = (unitInMotionSingleUnit["isVisible"]== "yes")
	local weaponRange = unitInMotionSingleUnit["weaponInfo"]["range"]
	local weaponType = unitInMotionSingleUnit["weaponType"]
	
	local boxSizeTrigger=0 --an arbitrary constant/variable, which trigger some other action/choice way way downstream. The purpose is to control when avoidance must be cut-off using custom value (ie: 1,2,3,4) for specific cases.
	local graphCONSTANTtrigger = {}
	local case=""
	local targetID=nil
	------------------------------------------------
	if (cQueue[queueIndex].id==CMD_RAW_MOVE or cQueue[queueIndex].id<0) then --move or building stuff
		local targetPosX, targetPosY, targetPosZ = -1, -1, -1 -- (-1) is default value because -1 represent "no target"
		if cQueue[queueIndex].params[1]~= nil and cQueue[queueIndex].params[2]~=nil and cQueue[queueIndex].params[3]~=nil then --confirm that the coordinate exist
			targetPosX, targetPosY, targetPosZ = cQueue[queueIndex].params[1], cQueue[queueIndex].params[2],cQueue[queueIndex].params[3]
		-- elseif cQueue[queueIndex].params[1]~= nil then --check whether its refering to a nanoframe
			-- local nanoframeID = cQueue[queueIndex].params[1]
			-- targetPosX, targetPosY, targetPosZ = spGetUnitPosition(nanoframeID)
			-- if (turnOnEcho == 2)then Spring.Echo("ExtractTarget, MoveCommand: is using nanoframeID") end
		else
			if (turnOnEcho == 2)then
				local defID = spGetUnitDefID(unitID)
				local ud = UnitDefs[defID or -1]
				if ud then
					Spring.Echo("Dynamic Avoidance move/build target is nil: fallback to no target " .. ud.humanName)--certain command has negative id but nil parameters. This is unknown command. ie: -32
				else
					Spring.Echo("Dynamic Avoidance move/build target is nil: fallback to no target")
				end
			end
		end
		boxSizeTrigger=1 --//avoidance deactivation 'halfboxsize' for MOVE command
		graphCONSTANTtrigger[1] = 1 --use standard angle scale (take ~10 cycle to do 180 flip, but more predictable)
		graphCONSTANTtrigger[2] = 1
		
		if #cQueue >= queueIndex+1 then --this make unit retreating (that don't have safe haven coordinate) after reclaiming/ressurecting to have no target (and thus will retreat toward random position).
			if cQueue[queueIndex+1].id==CMD_RECLAIM or cQueue[queueIndex+1].id==CMD_RESURRECT then --//reclaim command has 2 stage: 1 is move back to base, 2 is going reclaim. If detected reclaim or ressurect at 2nd queue then identify as area reclaim
				if (cQueue[queueIndex].params[1]==cQueue[queueIndex+1].params[1]
				and cQueue[queueIndex].params[2]==cQueue[queueIndex+1].params[2] --if retreat position equal to area reclaim/resurrect center (only happen if no safe haven coordinate detected)
				and cQueue[queueIndex].params[3]==cQueue[queueIndex+1].params[3]) or
				(cQueue[queueIndex].params[1]==cQueue[queueIndex+1].params[2]
				and cQueue[queueIndex].params[2]==cQueue[queueIndex+1].params[3] --this 2nd condition happen when there is wreck to reclaim and the first params is the featureID.
				and cQueue[queueIndex].params[3]==cQueue[queueIndex+1].params[4])
				then --area reclaim will have no "nil", and will equal to retreat coordinate when retreating to center of area reclaim.
					targetPosX, targetPosY, targetPosZ = -1, -1, -1 --//if area reclaim under the above condition, then avoid forever in presence of enemy, ELSE if no enemy (no avoidance): it reach retreat point and resume reclaiming
					boxSizeTrigger=1 --//avoidance deactivation 'halfboxsize' for MOVE command
				end
			end
		end
		
		targetCoordinate={targetPosX, targetPosY, targetPosZ } --send away the target for move command
		case = 'movebuild'
	elseif cQueue[queueIndex].id==CMD_RECLAIM or cQueue[queueIndex].id==CMD_RESURRECT then --reclaim or ressurect
		-- local a = Spring.GetUnitCmdDescs(unitID, Spring.FindUnitCmdDesc(unitID, 90), Spring.FindUnitCmdDesc(unitID, 90))
		-- Spring.Echo(a[queueIndex]["name"])
		local wreckPosX, wreckPosY, wreckPosZ = -1, -1, -1 -- -1 is default value because -1 represent "no target"
		local areaMode = false
		local foundMatch = false
		--Method 1: set target to individual wreckage, else (if failed) revert to center of current area-command or to no target.
		-- [[
		local posX, posY, posZ = GetUnitOrFeaturePosition(cQueue[queueIndex].params[1])
		if posX then
			foundMatch=true
			wreckPosX, wreckPosY, wreckPosZ = posX, posY, posZ
			targetID = cQueue[queueIndex].params[1]
		end
		if foundMatch then --next: check if this is actually an area reclaim/ressurect
			if cQueue[queueIndex].params[4] ~= nil then --area reclaim should has no "nil" on params 1,2,3, & 4 and in this case params 1 contain featureID/unitID because its the 2nd part of the area-reclaim command that reclaim wreck/target
				areaMode = true
				wreckPosX, wreckPosY,wreckPosZ = cQueue[queueIndex].params[2], cQueue[queueIndex].params[3],cQueue[queueIndex].params[4]
			end
		elseif cQueue[queueIndex].params[4] ~= nil then --1st part of the area-reclaim command (an empty area-command)
			areaMode = true
			wreckPosX, wreckPosY,wreckPosZ = cQueue[queueIndex].params[1], cQueue[queueIndex].params[2],cQueue[queueIndex].params[3]
		else --have no unit match but have no area coordinate either, but is RECLAIM command, something must be wrong:
			if (turnOnEcho == 2)then  Spring.Echo("Dynamic Avoidance reclaim targetting failure: fallback to no target") end
		end
		--]]

		targetCoordinate={wreckPosX, wreckPosY,wreckPosZ} --use wreck/center-of-area-command as target
		--graphCONSTANTtrigger[1] = 2 --use bigger angle scale for initial avoidance: after that is a MOVE command to the center or area-command which uses standard angle scale (take ~4 cycle to do 180 flip, but more chaotic)
		--graphCONSTANTtrigger[2] = 2
		graphCONSTANTtrigger[1] = 1 --use standard angle scale (take ~10 cycle to do 180 flip, but more predictable)
		graphCONSTANTtrigger[2] = 1
		boxSizeTrigger=2 --use deactivation 'halfboxsize' for RECLAIM/RESURRECT command
		
		if not areaMode then --signature for discrete RECLAIM/RESURRECT command.
			boxSizeTrigger = 1 --change to deactivation 'halfboxsize' similar to MOVE command if user queued a discrete reclaim/ressurect command
			--graphCONSTANTtrigger[1] = 1 --override: use standard angle scale (take ~10 cycle to do 180 flip, but more predictable)
			--graphCONSTANTtrigger[2] = 1
		end
		case = 'reclaimressurect'
	elseif cQueue[queueIndex].id==CMD_REPAIR then --repair command
		local unitPosX, unitPosY, unitPosZ = -1, -1, -1 -- (-1) is default value because -1 represent "no target"
		local targetUnitID=cQueue[queueIndex].params[1]
	
		if spValidUnitID(targetUnitID) then --if has unit ID
			unitPosX, unitPosY, unitPosZ = spGetUnitPosition(targetUnitID)
			targetID = targetUnitID
		elseif cQueue[queueIndex].params[1]~= nil and cQueue[queueIndex].params[2]~=nil and cQueue[queueIndex].params[3]~=nil then --if no unit then use coordinate
			unitPosX, unitPosY,unitPosZ = cQueue[queueIndex].params[1], cQueue[queueIndex].params[2],cQueue[queueIndex].params[3]
		else
			if (turnOnEcho == 2)then Spring.Echo("Dynamic Avoidance repair targetting failure: fallback to no target") end
		end
		targetCoordinate={unitPosX, unitPosY,unitPosZ} --use ally unit as target
		boxSizeTrigger=3 --change to deactivation 'halfboxsize' similar to REPAIR command
		graphCONSTANTtrigger[1] = 1
		graphCONSTANTtrigger[2] = 1
		case = 'repair'
	elseif (cQueue[1].id == cMD_DummyG) or (cQueue[1].id == cMD_Dummy_atkG) then
		targetCoordinate = {-1, -1,-1} --no target (only avoidance)
		boxSizeTrigger = nil --//value not needed; because 'halfboxsize' for a "-1" target always return "not reached" (infinite avoidance), calculation is skipped (no nil error)
		graphCONSTANTtrigger[1] = 1 --//this value doesn't matter because 'cMD_DummyG' don't use attractor (-1 disabled the attractor calculation, and 'fixedPointCONSTANTtrigger' behaviour ignore attractor). Needed because "fTarget" is tied to this variable in "AvoidanceCalculator()".
		graphCONSTANTtrigger[2] = 1
		fixedPointCONSTANTtrigger = 3 --//use behaviour that promote avoidance/ignore attractor
		case = 'cmddummys'
	elseif cQueue[queueIndex].id == CMD_GUARD then
		local unitPosX, unitPosY, unitPosZ = -1, -1, -1 -- (-1) is default value because -1 represent "no target"
		local targetUnitID = cQueue[queueIndex].params[1]
		if spValidUnitID(targetUnitID) then --if valid unit ID, not fake (if fake then will use "no target" for pure avoidance)
			local unitDirection = 0
			unitDirection, unitPosY,_ = GetUnitDirection(targetUnitID) --get target's direction in radian
			unitPosX, unitPosZ = ConvertToXZ(targetUnitID, unitDirection, 200) --project a target at 200m in front of guarded unit
			targetID = targetUnitID
		else
			if (turnOnEcho == 2)then Spring.Echo("Dynamic Avoidance guard targetting failure: fallback to no target") end
		end
		targetCoordinate={unitPosX, unitPosY,unitPosZ} --use ally unit as target
		boxSizeTrigger = 4 --//deactivation 'halfboxsize' for GUARD command
		graphCONSTANTtrigger[1] = 2 --//use more aggressive attraction because it GUARD units. It need big result.
		graphCONSTANTtrigger[2] = 1	--//(if 1) use less aggressive avoidance because need to stay close to units. It need not stray.
		case = 'guard'
	elseif cQueue[queueIndex].id == CMD_ATTACK then
		local targetPosX, targetPosY, targetPosZ = -1, -1, -1 -- (-1) is default value because -1 represent "no target"
		boxSizeTrigger = nil --//value not needed when target is "-1" which always return "not reached" (a case where boxSizeTrigger is not used)
		graphCONSTANTtrigger[1] = 1 --//this value doesn't matter because 'CMD_ATTACK' don't use attractor (-1 already disabled the attractor calculation, and 'fixedPointCONSTANTtrigger' ignore attractor). Needed because "fTarget" is tied to this variable in "AvoidanceCalculator()".
		graphCONSTANTtrigger[2] = 2	--//use more aggressive avoidance because it often run just once or twice. It need big result.
		fixedPointCONSTANTtrigger = 3 --//use behaviour that promote avoidance/ignore attractor (incase -1 is not enough)
		if unitVisible and weaponType~=2 then --not arty
			local enemyID = cQueue[queueIndex].params[1]
			local x,y,z = spGetUnitPosition(enemyID)
			if x then
				targetPosX, targetPosY, targetPosZ = x,y,z --set target to enemy
				targetID = enemyID
				-- if weaponType==0  then --melee unit set bigger targetReached box.
					-- boxSizeTrigger = 1 --if user initiate an attack while avoidance is necessary (eg: while reloading), then set deactivation 'halfboxsize' for MOVE command (ie: 400m range)
				-- elseif weaponType==1 then
				boxSizeTrigger = 2 --set deactivation 'halfboxsize' for RECLAIM/RESURRECT command (ie: 0m range/ always flee)
				-- end
				fixedPointCONSTANTtrigger = 1 --//use general behaviour that balance between target & avoidance
			end
		end
		targetCoordinate={targetPosX, targetPosY, targetPosZ} --set target to enemy unit or none
		case = 'attack'
	else --if queue has no match/ is empty: then use no-target. eg: A case where undefined command is allowed into the system, or when engine delete the next queues of a valid command and widget expect it to still be there.
		targetCoordinate={-1, -1, -1}
		--if for some reason command queue[2] is already empty then use these backup value as target:
		boxSizeTrigger = nil --//value not needed when target is "-1" which always return "not reached" (a case where boxSizeTrigger is not used)
		graphCONSTANTtrigger[1] = 1  --//needed because "fTarget" is tied to this variable in "AvoidanceCalculator()". This value doesn't matter because -1 already skip attractor calculation & 'fixedPointCONSTANTtrigger' already ignore attractor values.
		graphCONSTANTtrigger[2] = 1
		fixedPointCONSTANTtrigger = 3
		case = 'none'
	end
	local output = {
		targetCoordinate = targetCoordinate,
		boxSizeTrigger = boxSizeTrigger,
		graphCONSTANTtrigger = graphCONSTANTtrigger,
		fixedPointCONSTANTtrigger = fixedPointCONSTANTtrigger,
		case = case,
		targetID = targetID,
	}
	return output
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

function GetUnitRelativeAngle (unitIDmain,unitID2,unitIDmainX,unitIDmainZ,unitID2X,unitID2Z)
	local x,z = unitIDmainX,unitIDmainZ
	local rX, rZ=unitID2X,unitID2Z --use inputted position
	if not x then --empty?
		x,_,z = spGetUnitPosition(unitIDmain) --use standard position
	end
	if not rX then
		rX, _, rZ= spGetUnitPosition(unitID2)
	end
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
function SumAllUnitAroundUnitID (obsCONSTANT,unitDirection,losRadius,surroundingUnits,unitsSeparation,impatienceTrigger,graphCONSTANTtrigger,unitInMotionSingleUnit,skippingTimer)
	local thisUnitID = unitInMotionSingleUnit["unitID"]
	
	local safetyMarginCONSTANT = safetyMarginCONSTANTunitG -- make the slopes in the extremeties of obstacle graph more sloppy (refer to "non-Linear Dynamic system approach to modelling behavior" -SiomeGoldenstein, Edward Large, DimitrisMetaxas)
	local smCONSTANT = smCONSTANTunitG --?
	local distanceCONSTANT = distanceCONSTANTunitG
	local useLOS_distanceCONSTANT = useLOS_distanceCONSTANTunit_G
	local normalizeObsGraph = normalizeObsGraphG
	local cmd_then_DoCalculation_delay = cmd_then_DoCalculation_delayG
	----
	local wTotal=0
	local fObstacleSum=0
	local dFobstacle=0
	local dSum=0
	local nearestFrontObstacleRange =999
	local normalizingFactor = 1
	
	if (turnOnEcho == 1) then Spring.Echo("unitID(SumAllUnitAroundUnitID)" .. thisUnitID) end
	if (surroundingUnits["count"] and surroundingUnits["count"]>0) then --don't execute if no enemy unit exist
		local graphSample={}
		if normalizeObsGraph then --an option (default OFF) allow the obstacle graph to be normalized for experimenting purposes
			for i=1, 180+1, 1 do
				graphSample[i]=0 --initialize content 360 points
			end
		end
		local thisXvel,_,thisZvel = spGetUnitVelocity(thisUnitID)
		local thisX,_,thisZ = spGetUnitPosition(thisUnitID)
		local delay_1 = skippingTimer.averageDelay/2
		local delay_2 = cmd_then_DoCalculation_delay
		local thisXvel_delay2,thisZvel_delay2 =  GetDistancePerDelay(thisXvel,thisZvel, delay_2)
		local thisXvel_delay1,thisZvel_delay1 = GetDistancePerDelay(thisXvel,thisZvel,delay_1) --convert per-frame velocity into per-second velocity, then into elmo-per-averageNetworkDelay
		for i=1,surroundingUnits["count"], 1 do
			local unitRectangleID=surroundingUnits[i]
			if (unitRectangleID ~= nil)then --excluded any nil entry
				local recX_delay1,recZ_delay1,unitSeparation_1,_,_,unitSeparation_2 = GetTargetPositionAfterDelay(unitRectangleID, delay_1,delay_2,thisXvel_delay1,thisZvel_delay1,thisXvel_delay2,thisZvel_delay2,thisX,thisZ)
				if unitsSeparation[unitRectangleID]==nil then unitsSeparation[unitRectangleID]=9999 end --if enemy spontaneously appear then set the memorized separation distance to 9999; maybe previous polling missed it and to prevent nil
				if (turnOnEcho == 1) then
					Spring.Echo("unitSeparation <unitsSeparation[unitRectangleID](SumAllUnitAroundUnitID)")
					Spring.Echo(unitSeparation <unitsSeparation[unitRectangleID])
				end
				if unitSeparation_2 - unitsSeparation[unitRectangleID] < 30 then --see if the enemy in collision front is maintaining distance/fleeing or is closing in
					local relativeAngle 	= GetUnitRelativeAngle (thisUnitID, unitRectangleID,thisX,thisZ,recX_delay1,recZ_delay1) -- obstacle's angular position with respect to our coordinate
					local subtendedAngle	= GetUnitSubtendedAngle (thisUnitID, unitRectangleID, losRadius,unitSeparation_1) -- obstacle & our unit's angular size

					distanceCONSTANT=distanceCONSTANTunitG --reset distance constant
					if useLOS_distanceCONSTANT then
						distanceCONSTANT= losRadius --use unit's LOS instead of constant so that longer range unit has bigger avoidance radius.
					end
					
					--get obstacle/ enemy/repulsor wave function
					if impatienceTrigger==0 then --impatienceTrigger reach zero means that unit is impatient
						distanceCONSTANT=distanceCONSTANT/2
					end
					local ri, wi, di,diff1 = GetRiWiDi (unitDirection, relativeAngle, subtendedAngle, unitSeparation_1, safetyMarginCONSTANT, smCONSTANT, distanceCONSTANT,obsCONSTANT)
					local fObstacle = ri*wi*di
					
					--get second obstacle/enemy/repulsor wave function to calculate slope
					local ri2, wi2, di2, diff2= GetRiWiDi (unitDirection, relativeAngle, subtendedAngle, unitSeparation_1, safetyMarginCONSTANT, smCONSTANT, distanceCONSTANT, obsCONSTANT, true)
					local fObstacle2 = ri2*wi2*di2
					
					--create a snapshot of the entire graph. Resolution: 360 datapoint
					local dI = math.exp(-1*unitSeparation_1/distanceCONSTANT) --distance multiplier
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
					wTotal, dSum, fObstacleSum,dFobstacle, nearestFrontObstacleRange= DoAllSummation (wi, fObstacle, fObstacleSlope, di,wTotal, unitDirection, unitSeparation_1, relativeAngle, dSum, fObstacleSum,dFobstacle, nearestFrontObstacleRange)
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
	local output = {
		wTotal = wTotal,
		dSum = dSum,
		fObstacleSum = fObstacleSum,
		dFobstacle = dFobstacle,
		nearestFrontObstacleRange = nearestFrontObstacleRange,
		normalizingFactor = normalizingFactor,
	}
	return output --return obstacle's calculation result
end

--determine appropriate behaviour
function CheckWhichFixedPointIsStable (fTargetSlope, fTarget, fixedPointCONSTANTtrigger,sumAllUnitOutput)
	local dFobstacle = sumAllUnitOutput["dFobstacle"]
	local dSum = sumAllUnitOutput["dSum"]
	local wTotal = sumAllUnitOutput["wTotal"]
	local fObstacleSum = sumAllUnitOutput["fObstacleSum"]
	
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
function ToCoordinate(wTarget, wObstacle, fTarget, unitDirection, losRadius, impatienceTrigger, skippingTimer, wasMoving, newCommand,sumAllUnitOutput, unitInMotionSingleUnit)
	local safetyDistanceCONSTANT=safetyDistanceCONSTANT_fG
	local timeToContactCONSTANT=timeToContactCONSTANTg
	local activateAutoReverse=activateAutoReverseG
	---------
	local thisUnitID = unitInMotionSingleUnit["unitID"]
	local unitSpeed = unitInMotionSingleUnit["unitSpeed"]
	local nearestFrontObstacleRange = sumAllUnitOutput["nearestFrontObstacleRange"]
	local fObstacleSum = sumAllUnitOutput["fObstacleSum"]
	local normalizingFactor = sumAllUnitOutput["normalizingFactor"]
	
	if (nearestFrontObstacleRange> losRadius) then nearestFrontObstacleRange = 999 end --if no obstacle infront of unit then set nearest obstacle as far as LOS to prevent infinite velocity.
	local newUnitAngleDerived= GetNewAngle(unitDirection, wTarget, fTarget, wObstacle, fObstacleSum, normalizingFactor) --derive a new angle from calculation for move solution

	local velocity=unitSpeed*(math.max(timeToContactCONSTANT, skippingTimer.averageDelay + timeToContactCONSTANT)) --scale-down/scale-up command lenght based on system delay (because short command will make unit move in jittery way & avoidance stop prematurely). *NOTE: select either preset velocity (timeToContactCONSTANT==cmd_then_DoCalculation_delayG) or the one taking account delay measurement (skippingTimer.networkDelay + cmd_then_DoCalculation_delay), which one is highest, times unitSpeed as defined by UnitDefs.
	local networkDelayDrift = 0
	if wasMoving then  --unit drift contributed by network lag/2 (divide-by-2 because averageDelay is a roundtrip delay and we just want the delay of stuff measured on screen), only calculated when unit is known to be moving (eg: is using lastPosition to determine direction), but network lag value is not accurate enough to yield an accurate drift prediction.
		networkDelayDrift = unitSpeed*(skippingTimer.averageDelay/2)
	-- else --if initially stationary then add this backward motion (as 'hax' against unit move toward enemy because of avoidance due to firing/reloading weapon)
		-- networkDelayDrift = -1*unitSpeed/2
	end
	local maximumVelocity = (nearestFrontObstacleRange- safetyDistanceCONSTANT)/timeToContactCONSTANT --calculate the velocity that will cause a collision within the next "timeToContactCONSTANT" second.
	activateAutoReverse=activateAutoReverse*impatienceTrigger --activate/deactivate 'autoReverse' if impatience system is used
	local doReverseNow = false
	if (maximumVelocity <= velocity) and (activateAutoReverse==1) and (not newCommand) then
		--velocity = -unitSpeed	--set to reverse if impact is imminent & when autoReverse is active & when isn't a newCommand. NewCommand is TRUE if its on initial avoidance. We don't want auto-reverse on initial avoidance (we rely on normal avoidance first, then auto-reverse if it about to collide with enemy).
		doReverseNow = true
	end
	
	if (turnOnEcho == 1) then
		Spring.Echo("maximumVelocity(ToCoordinate)" .. maximumVelocity)
		Spring.Echo("activateAutoReverse(ToCoordinate)" .. activateAutoReverse)
		Spring.Echo("unitDirection(ToCoordinate)" .. unitDirection)
	end
	
	local newX, newZ= ConvertToXZ(thisUnitID, newUnitAngleDerived,velocity, unitDirection, networkDelayDrift,doReverseNow) --convert angle into coordinate form
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
	if options.enableReturnToBase.value==false or WG.OPTICS_cluster == nil then --//if epicmenu option 'Return To Base' is false then return nil
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
				if (unitDef.isBuilder or unitDef["canCloak"]) and not unitDef.customParams.commtype then --if cloakies and constructor, and not com (ZK)
					--intentionally empty. Not include cloakies and builder.
				elseif unitDef.customParams.commtype then --if COMMANDER,
					unorderedUnitList[unitID_list] = {x,y,z} --//store
				elseif not (unitDef["canFly"] or unitDef["isAirUnit"]) then --if all ground unit, amphibious, and ships (except commander)
					--unorderedUnitList[unitID_list] = {x,y,z} --//store
				elseif (unitDef.hoverAttack== true) then --if gunships
					--intentionally empty. Not include gunships.
				end
			else --if buildings
				unorderedUnitList[unitID_list] = {x,y,z} --//store
			end
		end
		local cluster, _ = WG.OPTICS_cluster(unorderedUnitList, 600,3, myTeamID,300) --//find clusters with atleast 3 unit per cluster and with at least within 300-meter from each other
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

function GetUnitOrFeaturePosition(id) --copied from cmd_commandinsert.lua widget (by dizekat)
	if id<=Game.maxUnits and spValidUnitID(id) then
		return spGetUnitPosition(id)
	elseif spValidFeatureID(id-Game.maxUnits) then
		return spGetFeaturePosition(id-Game.maxUnits) --featureID is always offset by maxunit count
	end
	return nil
end

function GetUnitDirection(unitID) --give unit direction in radian, 2D
	local dx, dz = 0,0
	local isMoving = true
	local _,currentY = spGetUnitPosition(unitID)
	dx,_,dz= spGetUnitVelocity(unitID)
	if (dx == 0 and dz == 0) then --use the reported vector if velocity failed to reveal any vector
		dx,_,dz= spGetUnitDirection(unitID)
		isMoving = false
	end
	local dxdz = math.sqrt(dx*dx + dz*dz) --hypothenus for xz direction
	local unitDirection = math.atan2(dx/dxdz, dz/dxdz)
	if (turnOnEcho == 1) then
		Spring.Echo("direction(GetUnitDirection) " .. unitDirection*180/math.pi)
	end
	return unitDirection, currentY, isMoving
end

function ConvertToXZ(thisUnitID, newUnitAngleDerived, velocity, unitDirection, networkDelayDrift,doReverseNow)
	--localize global constant
	local velocityAddingCONSTANT=velocityAddingCONSTANTg
	local velocityScalingCONSTANT=velocityScalingCONSTANTg
	--
	
	local x,_,z = spGetUnitPosition(thisUnitID)
	local distanceToTravelInSecond=velocity*velocityScalingCONSTANT+velocityAddingCONSTANT*Sgn(velocity) --add multiplier & adder. note: we multiply "velocityAddingCONSTANT" with velocity Sign ("Sgn") because we might have reverse speed (due to auto-reverse)
	local newX = 0
	local newZ = 0
	if doReverseNow then
		local reverseDirection = unitDirection+math.pi --0 degree + 180 degree = reverse direction
		newX = distanceToTravelInSecond*math.sin(reverseDirection) + x
		newZ = distanceToTravelInSecond*math.cos(reverseDirection) + z
	else
		newX = distanceToTravelInSecond*math.sin(newUnitAngleDerived) + x -- issue a command on the ground to achieve a desired angular turn
		newZ = distanceToTravelInSecond*math.cos(newUnitAngleDerived) + z
	end

	if (unitDirection ~= nil) and (networkDelayDrift~=0) then --need this check because argument #4 & #5 can be empty (for other usage). Also used in ExtractTarget for GUARD command.
		local distanceTraveledDueToNetworkDelay = networkDelayDrift
		newX = distanceTraveledDueToNetworkDelay*math.sin(unitDirection) + newX -- translate move command abit further forward; to account for lag. Network Lag makes move command lags behind the unit.
		newZ = distanceTraveledDueToNetworkDelay*math.cos(unitDirection) + newZ
	end
	
	newX = math.min(newX,Game.mapSizeX)
	newX = math.max(newX,0)
	newZ = math.min(newZ,Game.mapSizeZ)
	newZ = math.max(newZ,0)
	
	if (turnOnEcho == 1) then
		Spring.Echo("x(ConvertToXZ) " .. x)
		Spring.Echo("z(ConvertToXZ) " .. z)
		Spring.Echo("newX(ConvertToXZ) " .. newX)
		Spring.Echo("newZ(ConvertToXZ) " .. newZ)
	end
	return newX, newZ
end

function GetTargetPositionAfterDelay(targetUnitID, delay1,delay2,thisXvel_delay1,thisZvel_delay1,thisXvel_delay2,thisZvel_delay2,thisX,thisZ)
	local recXvel,_,recZvel = spGetUnitVelocity(targetUnitID)
	local recX,_,recZ = spGetUnitPosition(targetUnitID)
	recXvel = recXvel or 0
	recZvel = recZvel or 0
	local recXvel_delay2, recZvel_delay2 = GetDistancePerDelay(recXvel,recZvel, delay2)
	recXvel_delay2 = recXvel_delay2 - thisXvel_delay2 --calculate relative elmo-per-delay
	recZvel_delay2 = recZvel_delay2 - thisZvel_delay2
	local recX_delay2 = recX + recXvel_delay2 --predict obstacle's offsetted position after a delay has passed
	local recZ_delay2 = recZ + recZvel_delay2
	local unitSeparation_2 = Distance(recX_delay2,recZ_delay2,thisX,thisZ)
	local recXvel_delay1, recZvel_delay1 = GetDistancePerDelay(recXvel,recZvel,delay1)
	recXvel_delay1 = recXvel_delay1 - thisXvel_delay1 --calculate relative elmo-per-averageNetworkDelay
	recZvel_delay1 = recZvel_delay1 - thisZvel_delay1
	local recX_delay1 = recX + recXvel_delay1 --predict obstacle's offsetted position after network delay has passed
	local recZ_delay1 = recZ + recZvel_delay1
	local unitSeparation_1 = Distance(recX_delay1,recZ_delay1,thisX,thisZ) --spGetUnitSeparation (thisUnitID, unitRectangleID, true) --get 2D distance
	return recX_delay1,recZ_delay1,unitSeparation_1,recX_delay2,recZ_delay2,unitSeparation_2
end

--get enemy angular size with respect to unit's perspective
function GetUnitSubtendedAngle (unitIDmain, unitID2, losRadius,unitSeparation)
	local unitSize2 =32 --a commander size for an unidentified enemy unit
	local unitDefID2= spGetUnitDefID(unitID2)
	local unitDef2= UnitDefs[unitDefID2]
	if (unitDef2~=nil) then
		unitSize2 = unitDef2.xsize*8 --8 unitDistance per each square times unitDef's square, a correct size for an identified unit
	end
	
	local unitDefID= spGetUnitDefID(unitIDmain)
	local unitDef= UnitDefs[unitDefID]
	local unitSize = unitDef.xsize*8 --8 is the actual Distance per square
	
	if (not unitDef["canCloak"]) and (unitDef2~=nil) then --non-cloaky unit view enemy size as its weapon range (this to make it avoid getting into range)
		unitSize2 = unitDef2.maxWeaponRange
	end
	
	if (unitDef["canCloak"]) then --cloaky unit use decloak distance as body size (to avoid getting too close)
		unitSize = unitDef["decloakDistance"]
	end
	
	local separationDistance = unitSeparation
	--if (unitID2~=nil) then separationDistance = spGetUnitSeparation (unitIDmain, unitID2, true) --actual separation distance
	--else separationDistance = losRadius -- GetUnitLOSRadius(unitIDmain) --as far as unit's reported LOSradius
	--end

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
	local angleFromNoise = Sgn((-1)*angleFromObstacle)*(noiseAngleG)*GaussianNoise() --(noiseAngleG)*(GaussianNoise()*2-1) --for random in negative & positive direction
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
		-- Spring.Echo("unitAngleDerived (getNewAngle)" ..unitAngleDerived*180/math.pi)
		-- Spring.Echo("newUnitAngleDerived (getNewAngle)" .. newUnitAngleDerived*180/math.pi)
		-- Spring.Echo("angleFromTarget (getNewAngle)" .. angleFromTarget*180/math.pi)
		-- Spring.Echo("angleFromObstacle (getNewAngle)" .. angleFromObstacle*180/math.pi)
		-- Spring.Echo("fTarget (getNewAngle)" .. fTarget)
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

function GetDistancePerDelay(velocityX, velocityZ, delaySecond)
	return velocityX*30*delaySecond,velocityZ*30*delaySecond --convert per-frame velocity into per-second velocity, then into elmo-per-delay
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
