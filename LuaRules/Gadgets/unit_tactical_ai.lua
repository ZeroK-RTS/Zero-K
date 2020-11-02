
function gadget:GetInfo()
	return {
		name     = "Tactical Unit AI",
		desc    = "Implements tactial AI for some units. Uses commands.",
		author    = "Google Frog",
		date    = "April 20 2010",
		license    = "GNU GPL, v2 or later",
		layer    = 0,
		enabled = true,
	}
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

if (not gadgetHandler:IsSyncedCode()) then
	return false  --  no unsynced code
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Speedups

local spGetGameFrame        = Spring.GetGameFrame
local spInsertUnitCmdDesc   = Spring.InsertUnitCmdDesc
local spGetCommandQueue     = Spring.GetCommandQueue
local spGetUnitDefID        = Spring.GetUnitDefID
local spGetUnitPosition     = Spring.GetUnitPosition
local spGetUnitVelocity     = Spring.GetUnitVelocity
local spGiveOrderToUnit     = Spring.GiveOrderToUnit
local spGetUnitNearestEnemy = Spring.GetUnitNearestEnemy
local spGetUnitSeparation   = Spring.GetUnitSeparation
local spEditUnitCmdDesc     = Spring.EditUnitCmdDesc
local spFindUnitCmdDesc     = Spring.FindUnitCmdDesc
local spGetUnitAllyTeam     = Spring.GetUnitAllyTeam
local spGetUnitLosState     = Spring.GetUnitLosState
local spValidUnitID         = Spring.ValidUnitID
local spGetUnitIsStunned    = Spring.GetUnitIsStunned
local spGetUnitRulesParam   = Spring.GetUnitRulesParam
local spGetUnitWeaponState  = Spring.GetUnitWeaponState
local random                = math.random
local sqrt                  = math.sqrt
local min                   = math.min

local GiveClampedOrderToUnit = Spring.Utilities.GiveClampedOrderToUnit
local GetEffectiveWeaponRange = Spring.Utilities.GetEffectiveWeaponRange

local unitDefRanges = {}
local unitDefRealRanges = {}
local armedUnitDefIDs = {}
for i = 1, #UnitDefs do
	if not UnitDefs[i].modCategories["unarmed"] then
		armedUnitDefIDs[i] = true
	end
end

local ALLY_TABLE = {
	ally = true,
}

local DEBUG_NAME = "TACTICAL AI"

local AGGRESSIVE_FRAMES = 80
local AVOID_HEIGHT_DIFF = 25

local UPDATE_RATE = 20
local MAX_UPRATE_RATE = 2

local unitAIBehaviour = include("LuaRules/Configs/tactical_ai_defs.lua")

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Globals

local unit = {}
local unitList = {count = 0, data = {}}
local externallyHandledUnit = {}

local aggressiveTarget = {}

local needNextUpdate = false

local HEADING_TO_RAD = (math.pi*2/2^16)

local debugAll = false
local debugAction = false
local debugUnit = false

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Commands

local CMD_MOVE         = CMD.MOVE
local CMD_ATTACK       = CMD.ATTACK
local CMD_FIGHT        = CMD.FIGHT
local CMD_WAIT         = CMD.WAIT
local CMD_OPT_INTERNAL = CMD.OPT_INTERNAL
local CMD_OPT_RIGHT    = CMD.OPT_RIGHT
local CMD_INSERT       = CMD.INSERT
local CMD_REMOVE       = CMD.REMOVE

include("LuaRules/Configs/customcmds.h.lua")

local unitAICmdDesc = {
	id      = CMD_UNIT_AI,
	type    = CMDTYPE.ICON_MODE,
	name    = 'Unit AI',
	action  = 'unitai',
	tooltip = 'Toggles smart unit AI for the unit',
	params  = {0, 'AI Off', 'AI On'}
}

local stateCommands = include("LuaRules/Configs/state_commands.lua")

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
---- Utilities

local function DistSq(x1, y1, x2, y2)
	return (x1 - x2)^2 + (y1 - y2)^2
end

local function Dist(x1, y1, x2, y2)
	return sqrt((x1 - x2)^2 + (y1 - y2)^2)
end

local function GetUnitVisibleInformation(unitID, allyTeamID)
	if (not unitID) or select(2, spGetUnitIsStunned(unitID)) then
		return
	end
	local states = spGetUnitLosState(unitID, allyTeamID, false)
	return spGetUnitDefID(unitID), states and states.typed
end

local function GetUnitBehavior(unitID, unitDefID)
	if unitAIBehaviour[unitDefID].waterline then
		local bx, by, bz = spGetUnitPosition(unitID, true)
		if unitAIBehaviour[unitDefID].floatWaterline then
			by = Spring.GetGroundHeight(bx, bz)
		end
		if by < unitAIBehaviour[unitDefID].waterline then
			return unitAIBehaviour[unitDefID].sea
		else
			return unitAIBehaviour[unitDefID].land
		end
	else
		return unitAIBehaviour[unitDefID]
	end
end

local function GetEnemyRange(enemyDefID)
	if not unitDefRanges[enemyDefID] then
		local ud = UnitDefs[enemyDefID]
		unitDefRanges[enemyDefID] = (ud.customParams.percieved_range and tonumber(ud.customParams.percieved_range)) or ud.maxWeaponRange
	end
	return unitDefRanges[enemyDefID]
end

local function GetEnemyRealRange(enemyDefID)
	if not unitDefRealRanges[enemyDefID] then
		local ud = UnitDefs[enemyDefID]
		unitDefRealRanges[enemyDefID] = ud.maxWeaponRange
	end
	return unitDefRealRanges[enemyDefID]
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
---- Unit AI Utilities

local function GetUnitOrderState(unitID, unitData, cmdID, cmdOpts, cp_1, cp_2, cp_3, holdPos)
	-- ret 1: enemy ID, value of -1 means no manual target set so the nearest enemy should be used.
	--        Return false means the unit does not want orders from tactical ai.
	-- ret 2: true if there is a move command at the start of queue which will need removal.
	-- ret 3: true if the unit is using AI due to a fight or patrol command.
	-- ret 4: fallback enemy ID. This is set if the unit has a non-manual attack command.
	--        Use it as a fallback if there is no behaviour against the nearest enemy.
	-- ret 5, 6, 7: Fight command target
	-- ret 8: Has return position move order
	
	if not cmdID then
		if (not holdPos) then
			return -1, false -- could still skirm from static or flee
		end
		return false -- no queue and on hold position.
	end
	if (holdPos and cmdID == CMD_ATTACK and Spring.Utilities.CheckBit(DEBUG_NAME, cmdOpts, CMD.OPT_INTERNAL)) then
		if spGetCommandQueue(unitID, 0) == 1 then
			return false -- set to hold position and is auto-acquiring target
		end
	end
	
	if cmdID == CMD_FIGHT then
		return -1, false, true, nil, cp_1, cp_2, cp_3
	elseif cmdID == CMD_ATTACK then -- if I attack
		local cmdID_2 = Spring.GetUnitCurrentCommand(unitID, 2)
		if ((not holdPos) or (cmdID_2 == CMD_FIGHT)) then
			local target, twoParams = cp_1, cp_2
			if twoParams then
				if (cmdID == CMD_FIGHT) then
					--  if I target the ground and have fight or patrol comman
					return -1, false, nil, nil, cp_1, cp_2, cp_3
				end
			else
				-- if I target a unit
				if (cmdID == CMD_FIGHT or cmdID_2 == CMD_FIGHT) then
					-- Do not skirm single target with FIGHT
					return -1, false, true, spValidUnitID(target) and target 
				elseif Spring.Utilities.CheckBit(DEBUG_NAME, cmdOpts, CMD.OPT_INTERNAL) then
					-- Do no skirm single target when it is auto attack
					return -1, false, false, spValidUnitID(target) and target
				elseif spValidUnitID(target) then
					-- only skirm single target when given the order manually
					return target, false
				end
			end
		end
	elseif (cmdID == CMD_MOVE or cmdID == CMD_RAW_MOVE) and (cp_1 == unitData.cx) and (cp_2 == unitData.cy) and (cp_3 == unitData.cz) then
		local cmdID_2, cmdOpts_2, _, cps_1, cps_2, cps_3 = Spring.GetUnitCurrentCommand(unitID, 2)
		if not cmdID_2 then
			return -1, true
		end
		local cmdID_3 = Spring.GetUnitCurrentCommand(unitID, 3)
		if cmdID_2 == CMD_FIGHT or (cmdID_2 == CMD_ATTACK and ((not holdPos) or cmdID_3 == CMD_FIGHT)) then -- if the next command is attack, patrol or fight
			local target, twoParams = cps_1, cps_2
			if twoParams then
				if (cmdID_2 == CMD_FIGHT) then
					-- if I target the ground and have fight or patrol command
					return -1, true, true, nil, cps_1, cps_2, cps_3
				end
			elseif spValidUnitID(target) then -- if I target a unit
				-- if I target a unit
				if (cmdID_2 == CMD_FIGHT or cmdID_3 == CMD_FIGHT) then 
					-- Do not skirm single target with FIGHT
					return -1, true, true, target, cps_1, cps_2, cps_3
				elseif Spring.Utilities.CheckBit(DEBUG_NAME, cmdOpts_2, CMD.OPT_INTERNAL) then
					-- Do no skirm single target when it is auto attack
					return -1, true, false, target, cps_1, cps_2, cps_3
				else
					-- only skirm single target when given the order manually
					return target, true, false, nil, cps_1, cps_2, cps_3 
				end
			end
		end
		return -1, true
	end

	return false
end

local function ClearOrder(unitID, unitData, cmdID, cmdTag, cp_1, cp_2, cp_3)
	-- removes move order
	if unitData.receivedOrder then
		if (cmdID and (cmdID == CMD_MOVE or cmdID == CMD_RAW_MOVE)) then -- if I am moving
			if (cp_1 == unitData.cx) and (cp_2 == unitData.cy) and (cp_3 == unitData.cz) then -- if I was given this move command by this gadget
				spGiveOrderToUnit(unitID, CMD_REMOVE, {cmdTag}, 0 )
				GG.StopRawMoveUnit(unitID, true)
			end
		end
		unitData.receivedOrder = false
	end
end

local function HeadingAllowReloadSkirmBlock(unitID, blockThreshold, ex, ez)
	local heading = Spring.GetUnitHeading(unitID)*HEADING_TO_RAD
	local hx = math.sin(heading)
	local hz = math.cos(heading)
	local dist = math.sqrt(ex^2 + ez^2)
	ex, ez = ex/dist, ez/dist
	local dot = hx*ex + hz * ez
	return dot < blockThreshold
end

local function ReturnUnitToIdlePos(unitID, unitData, force)
	unitData.queueReturnX = unitData.idleX
	unitData.queueReturnZ = unitData.idleZ
	unitData.setReturn = true
	unitData.forceReturn = force
end

local function SetIdleAgression(unitID, unitData, enemy, frame)
	if not enemy then
		unitData.idleAgression = false
		return
	end
	aggressiveTarget[enemy] = (frame or spGetGameFrame()) + AGGRESSIVE_FRAMES
	unitData.idleAgression = true
end

local function CheckTargetAggression(enemy, frame)
	if not aggressiveTarget[enemy] then
		return false
	end
	if frame > aggressiveTarget[enemy] then
		aggressiveTarget[enemy] = nil
		return false
	end
	return true
end

local function UpdateIdleAgressionState(unitID, behaviour, unitData, frame, enemy, enemyUnitDefID, defaultEnemyRange, enemyDist, ux, uz, ex, ez, ignoreCloseEnemyAggress)
	-- This function uses three locations (enemypos, unitpos, unit idle pos) and decides to do one of three things
	-- * Stop fighting, via SetIdleAgression(unitID, unitData, true, frame)
	-- * Stop fleeing, via ReturnUnitToIdlePos(unitID, unitData, true)
	-- * Nothing
	if not unitData.idleX then
		return true
	end
	
	local enemyRange = defaultEnemyRange
	if enemyUnitDefID then
		enemyRange = GetEnemyRealRange(enemyUnitDefID)
	end
	
	local doDebug = (debugUnit and debugUnit[unitID]) or debugAll
	if doDebug then
		Spring.Echo("=== Update Idle Aggresion", unitID, " ===")
		Spring.Utilities.UnitEcho(unitID, "unit")
		if enemy and enemy ~= -1 then
			Spring.Utilities.UnitEcho(enemy, "enemy")
		end
	end
	
	if not unitData.idleAgression then
		if CheckTargetAggression(enemy, frame) then
			SetIdleAgression(unitID, unitData, enemy, frame)
			if doDebug then
				Spring.Utilities.UnitEcho(unitID, "A")
			end
			return true
		end
	end
	
	local myIdleDistSq = DistSq(unitData.idleX, unitData.idleZ, ux, uz)
	--Spring.Utilities.UnitEcho(unitID, "C")
	local enemyIdleDistSq = DistSq(unitData.idleX, unitData.idleZ, ex, ez)
	local enemyPushingMe = (enemyIdleDistSq < myIdleDistSq) or (enemyIdleDistSq < enemyRange^2)
	unitData.wantFightReturn = enemyPushingMe -- Return with fight if you need to return through an enemy
	
	if doDebug then
		Spring.Echo("enemyRange", math.floor(enemyRange), "enemyDist", math.floor(enemyDist), "range", math.floor(enemyRange), "commit", math.floor(behaviour.idleCommitDist))
		Spring.Echo("ux, uz, ex, ez", math.floor(ux), math.floor(uz), math.floor(ex), math.floor(ez))
		Spring.Echo("agress", math.floor(math.sqrt(behaviour.idlePushAggressDistSq)), "meToIdle", math.floor(math.sqrt(myIdleDistSq)), "enemyToIdle", math.floor(math.sqrt(DistSq(unitData.idleX, unitData.idleZ, ex, ez))))
		Spring.Echo("Check 1", enemyDist < enemyRange, behaviour.idlePushAggressDistSq < myIdleDistSq)
		Spring.Echo("Check 2", enemyPushingMe, enemyDist*behaviour.idleEnemyDistMult + math.sqrt(myIdleDistSq) *behaviour.idleCommitDistMult < behaviour.idleCommitDist)
		Spring.Echo("Check 3", behaviour.idleChaseEnemyLeeway < math.sqrt(myIdleDistSq))
	end
	
	-- Do not switch from flee to skirm unless pushed as it is often a bad idea.
	local ignoreCloseEnemyAggress = enemyUnitDefID and (behaviour.skirms and behaviour.skirms[enemyUnitDefID] and not (behaviour.hugs and behaviour.hugs[enemyUnitDefID]))
	
	if (enemyDist < enemyRange and not ignoreCloseEnemyAggress) or behaviour.idlePushAggressDistSq < myIdleDistSq then
		local myIdleDist = math.sqrt(myIdleDistSq) 
		if enemyPushingMe or enemyDist*behaviour.idleEnemyDistMult + myIdleDist*behaviour.idleCommitDistMult < behaviour.idleCommitDist then
			-- I am further from where I started than my enemy, or I am already committed to fighting (to a point). Agress.
			SetIdleAgression(unitID, unitData, enemy, frame)
			if doDebug then
				Spring.Echo("Set Aggression")
			end
		elseif behaviour.idleChaseEnemyLeeway < myIdleDist then
			-- Enemy is not blocking my retreat to idle pos, retreat.
			ReturnUnitToIdlePos(unitID, unitData, true)
			if doDebug then
				Spring.Echo("Set Return")
			end
		end
	end
	return false
end


local function GetAiExitEarly(unitID, unitData, behaviour)
	if (unitData.active) and (spGetUnitRulesParam(unitID, "disable_tac_ai") ~= 1) then
		return false
	end
	if unitData.receivedOrder then
		local cmdID, _, cmdTag, cp_1, cp_2, cp_3 = Spring.GetUnitCurrentCommand(unitID)
		ClearOrder(unitID, unitData, cmdID, cmdTag, cp_1, cp_2, cp_3)
	end
	return true
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
---- Unit AI Execution

local function DoSwarmEnemy(unitID, behaviour, unitData, enemy, enemyUnitDef, typeKnown, move, isIdleAttack, cmdID, cmdTag, fightX, fightY, fightZ, frame)
	local unitData = unit[unitID]

	if debugAction then
		Spring.Utilities.UnitEcho(unitID, "flee")
	end
	
	if not (enemy and typeKnown) then
		if not (((cmdID == CMD_FIGHT) or move) and fightZ) then
			return false
		end
		local ex, ey, ez = fightX, fightY, fightZ
		local ux, uy, uz = spGetUnitPosition(unitID) -- my position
		local cx, cy, cz -- command position
		
		local pointDis = Dist(ex, ez, ux, uz)
		
		-- insert move commands to jink towards enemy
		unitData.jinkDir = unitData.jinkDir*-1
		
		-- jink towards the enemy
		if behaviour.localJinkOrder and behaviour.jinkParallelLength < pointDis then
			cx = ux+(-(ux-ex)*behaviour.jinkParallelLength-(uz-ez)*unitData.jinkDir*behaviour.jinkTangentLength)/pointDis
			cy = uy
			cz = uz+(-(uz-ez)*behaviour.jinkParallelLength+(ux-ex)*unitData.jinkDir*behaviour.jinkTangentLength)/pointDis
		else
			cx = ex+(uz-ez)*unitData.jinkDir*behaviour.jinkTangentLength/pointDis
			cy = ey
			cz = ez+(ux-ex)*unitData.jinkDir*behaviour.jinkTangentLength/pointDis
		end
		
		if move then
			spGiveOrderToUnit(unitID, CMD_INSERT, {0, CMD_RAW_MOVE, CMD_OPT_INTERNAL, cx, cy, cz }, CMD.OPT_ALT )
			spGiveOrderToUnit(unitID, CMD_REMOVE, {cmdTag}, 0 )
		else
			spGiveOrderToUnit(unitID, CMD_INSERT, {0, CMD_RAW_MOVE, CMD_OPT_INTERNAL, cx, cy, cz }, CMD.OPT_ALT )
		end
		--Spring.SetUnitMoveGoal(unitID, cx, cy, cz)
		unitData.cx, unitData.cy, unitData.cz = cx, cy, cz
		
		unitData.receivedOrder = true
		return true
	end
	
	local pointDis = spGetUnitSeparation(enemy, unitID, true)
	if not pointDis then
		return false
	end
	
	local enemyRange = behaviour.swarmEnemyDefaultRange
	if enemyUnitDef and typeKnown then
		enemyRange = GetEnemyRange(enemyUnitDef)
	end
	
	if not (pointDis < enemyRange + behaviour.swarmLeeway) then
		return false -- if I am not within enemy range then don't swarm
	end
	
	local ex, ey, ez = spGetUnitPosition(enemy) -- enemy position
	local ux, uy, uz = spGetUnitPosition(unitID) -- my position
	local cx, cy, cz -- command position
	
	if isIdleAttack then
		if (debugUnit and debugUnit[unitID]) or debugAll then
			Spring.Echo("=== DoSwarmEnemy", unitID, " ===")
		end
		
		UpdateIdleAgressionState(unitID, behaviour, unitData, frame, enemy, typeKnown and enemyUnitDef, behaviour.swarmEnemyDefaultRange, pointDis, ux, uz, ex, ez)
	end
	
	if behaviour.maxSwarmRange < pointDis then -- if I cannot shoot at the enemy
		-- insert move commands to jink towards enemy
		unitData.jinkDir = unitData.jinkDir*-1
		
		-- jink towards the enemy
		if behaviour.localJinkOrder and behaviour.jinkParallelLength < pointDis then
			cx = ux+(-(ux-ex)*behaviour.jinkParallelLength-(uz-ez)*unitData.jinkDir*behaviour.jinkTangentLength)/pointDis
			cy = uy
			cz = uz+(-(uz-ez)*behaviour.jinkParallelLength+(ux-ex)*unitData.jinkDir*behaviour.jinkTangentLength)/pointDis
		else
			cx = ex+(uz-ez)*unitData.jinkDir*behaviour.jinkTangentLength/pointDis
			cy = ey
			cz = ez+(ux-ex)*unitData.jinkDir*behaviour.jinkTangentLength/pointDis
		end
		
		GG.recursion_GiveOrderToUnit = true
		if move then
			cx, cy, cz = GiveClampedOrderToUnit(unitID, CMD_INSERT, {0, CMD_RAW_MOVE, CMD_OPT_INTERNAL, cx, cy, cz }, CMD.OPT_ALT )
			spGiveOrderToUnit(unitID, CMD_REMOVE, {cmdTag}, 0 )
		else
			cx, cy, cz = GiveClampedOrderToUnit(unitID, CMD_INSERT, {0, CMD_RAW_MOVE, CMD_OPT_INTERNAL, cx, cy, cz }, CMD.OPT_ALT )
		end
		GG.recursion_GiveOrderToUnit = false
		unitData.cx, unitData. cy, unitData.cz = cx, cy, cz
		
		unitData.receivedOrder = true
	else
		if behaviour.circleStrafe then
			-- jink around the enemy
			local up = 0
			local ep = 1
			if pointDis < behaviour.minCircleStrafeDistance then
				up = 1
				ep = 0
			end
			
			cx = ux*up + ex*ep + unitData.rot*(uz-ez)*behaviour.strafeOrderLength/pointDis
			cy = uy
			cz = uz*up + ez*ep - unitData.rot*(ux-ex)*behaviour.strafeOrderLength/pointDis
			
		else
			if pointDis > behaviour.minSwarmRange then
				-- jink at max range
				cx = ux + unitData.rot*(uz-ez)*behaviour.strafeOrderLength/pointDis
				cy = uy
				cz = uz - unitData.rot*(ux-ex)*behaviour.strafeOrderLength/pointDis
				unitData.rot = unitData.rot*-1
			else
				unitData.jinkDir = unitData.jinkDir*-1 -- jink away
				cx = ux-(-(ux-ex)*behaviour.jinkAwayParallelLength-(uz-ez)*unitData.jinkDir*behaviour.jinkTangentLength)/pointDis
				cy = uy
				cz = uz-(-(uz-ez)*behaviour.jinkAwayParallelLength+(ux-ex)*unitData.jinkDir*behaviour.jinkTangentLength)/pointDis
			end
		end
		
		GG.recursion_GiveOrderToUnit = true
		if move then
			cx, cy, cz = GiveClampedOrderToUnit(unitID, CMD_INSERT, {0, CMD_RAW_MOVE, CMD_OPT_INTERNAL, cx, cy, cz }, CMD.OPT_ALT )
			spGiveOrderToUnit(unitID, CMD_REMOVE, {cmdTag}, 0 )
		else
			cx, cy, cz = GiveClampedOrderToUnit(unitID, CMD_INSERT, {0, CMD_RAW_MOVE, CMD_OPT_INTERNAL, cx, cy, cz }, CMD.OPT_ALT )
		end
		GG.recursion_GiveOrderToUnit = false
		unitData.cx, unitData.cy, unitData.cz = cx, cy, cz
		unitData.receivedOrder = true
	end
	
	return true
end

local function DoSkirmEnemy(unitID, behaviour, unitData, enemy, enemyUnitDef, typeKnown, move, isIdleAttack, cmdID, cmdTag, frame, haveFightAndHoldPos, doHug)
	local unitData = unit[unitID]
	--local pointDis = spGetUnitSeparation (enemy, unitID, true)
	
	local vx, vy, vz, enemySpeed = spGetUnitVelocity(enemy)
	local ex, ey, ez, _, aimY = spGetUnitPosition(enemy, false, true) -- enemy position
	local ux, uy, uz = spGetUnitPosition(unitID) -- my position

	if not (ex and vx) then
		return behaviour.skirmKeepOrder
	end
	
	if debugAction then
		Spring.Utilities.UnitEcho(unitID, "skirm")
	end
	
	local origEx, origEz = ex, ez
	
	if enemyUnitDef and behaviour.avoidHeightDiff and behaviour.avoidHeightDiff[enemyUnitDef] then
		if ey - uy > AVOID_HEIGHT_DIFF or ey - uy < -AVOID_HEIGHT_DIFF then
			return behaviour.skirmKeepOrder
		end
	end

	-- Use aim position as enemy position
	ey = aimY or ey
	
	-- The e vector is relative to unit position
	ex, ey, ez = ex - ux, ey - uy, ez - uz
	
	local predict = 1
	if enemySpeed < behaviour.mySpeed*0.95 then
		predict = 0.8*enemySpeed/behaviour.mySpeed
	end
	predict = predict*behaviour.velocityPrediction
	
	-- The d vector is also relative to unit position.
	local dx, dy, dz = ex + vx*predict, ey + vy*predict, ez + vz*predict
	if behaviour.selfVelocityPrediction then
		local uvx, uvy, uvz = spGetUnitVelocity(unitID)
		dx, dy, dz = dx - uvx*behaviour.velocityPrediction, dy - uvy*behaviour.velocityPrediction, dz - uvz*behaviour.velocityPrediction
	end
	
	local eDistSq = ex^2 + ey^2 + ez^2
	local eDist = sqrt(eDistSq)
	
	-- Scalar projection of prediction vector onto enemy vector
	local predProj = (ex*dx + ey*dy + ez*dz)/eDistSq

	-- Calculate predicted enemy distance
	local predictedDist = eDist
	if predProj > 0 then
		if behaviour.velPredChaseFactor and predProj > 1 then
			predictedDist = predictedDist*((predProj - 1)*behaviour.velPredChaseFactor + 1)
		else
			predictedDist = predictedDist*predProj
		end
	else
		-- In this case the enemy is predicted to go past me
		predictedDist = 0
	end
	
	if isIdleAttack then
		if (debugUnit and debugUnit[unitID]) or debugAll then
			Spring.Echo("=== DoSkirmEnemy", unitID, " ===")
		end
		UpdateIdleAgressionState(unitID, behaviour, unitData, frame, enemy, typeKnown and enemyUnitDef, 250, predictedDist, ux, uz, origEx, origEz)
	end
	
	local skirmRange = (doHug and behaviour.hugRange) or ((GetEffectiveWeaponRange(unitData.udID, -dy, behaviour.weaponNum) or 0) - behaviour.skirmLeeway)
	--Spring.Echo("skirmRange", skirmRange, GetEffectiveWeaponRange(unitData.udID, -dy, behaviour.weaponNum))
	local reloadFrames
	if behaviour.reloadSkirmLeeway then
		local reloadState = spGetUnitWeaponState(unitID, behaviour.weaponNum, 'reloadState')
		if reloadState then
			reloadFrames = reloadState - frame
			if reloadFrames > 0 then
				skirmRange = skirmRange + reloadFrames*behaviour.reloadSkirmLeeway
			end
		end
	end
	
	if enemyUnitDef and behaviour.bonusRangeUnits and behaviour.bonusRangeUnits[enemyUnitDef] then
		local oldSkirmRange = skirmRange
		skirmRange = skirmRange + behaviour.bonusRangeUnits[enemyUnitDef]
		if behaviour.wardFireRange and skirmRange > predictedDist and predictedDist > oldSkirmRange then
			local tx, tz = ux + behaviour.wardFireRange*ex/eDist, uz + behaviour.wardFireRange*ez/eDist
			local ty = math.max(0, Spring.GetGroundHeight(tx, tz)) + behaviour.wardFireHeight
			GG.SetTemporaryPosTarget(unitID, tx, ty, tz, false, 40)
		end
	end
	
	--Spring.Echo("skirmRange", skirmRange, "pred", predictedDist, "frame", Spring.GetGameFrame())
	if doHug or skirmRange > predictedDist then
		if behaviour.skirmOnlyNearEnemyRange then
			local enemyRange = (GetEffectiveWeaponRange(enemyUnitDef, dy, behaviour.weaponNum) or 0) + behaviour.skirmOnlyNearEnemyRange
			if enemyRange < predictedDist then
				return behaviour.skirmKeepOrder
			end
		end
		
		if (not doHug) and (behaviour.skirmBlockedApproachOnFight or not haveFightAndHoldPos) and behaviour.skirmBlockedApproachFrames then
			if not reloadFrames then
				local reloadState = spGetUnitWeaponState(unitID, behaviour.weaponNum, 'reloadState')
				if reloadState then
					reloadFrames = reloadState - frame
				end
			end
			
			-- Negative reloadFrames is how many frames the weapon has been loaded for.
			-- If a unit has not fired then it has been loaded since frame zero.
			if reloadFrames and (behaviour.skirmBlockedApproachFrames < -reloadFrames) then
				if (not behaviour.skirmBlockApproachHeadingBlock) or HeadingAllowReloadSkirmBlock(unitID, behaviour.skirmBlockApproachHeadingBlock, ex, ez) then
					if cmdID and move and not behaviour.skirmKeepOrder then
						spGiveOrderToUnit(unitID, CMD_REMOVE, {cmdTag}, 0 )
					end
					return behaviour.skirmKeepOrder
				end
			end
		end
		
		local wantedDis = min(behaviour.skirmOrderDis, skirmRange - behaviour.stoppingDistance - predictedDist)
		if behaviour.skirmOrderDisMin and behaviour.skirmOrderDisMin > wantedDis then
			wantedDis = behaviour.skirmOrderDisMin
		end
		local cx = ux - wantedDis*ex/eDist
		local cy = uy
		local cz = uz - wantedDis*ez/eDist
		
		GG.recursion_GiveOrderToUnit = true
		if move then
			cx, cy, cz = GiveClampedOrderToUnit(unitID, CMD_INSERT, {0, CMD_RAW_MOVE, CMD_OPT_INTERNAL, cx, cy, cz }, CMD.OPT_ALT )
			spGiveOrderToUnit(unitID, CMD_REMOVE, {cmdTag}, 0 )
		else
			cx, cy, cz = GiveClampedOrderToUnit(unitID, CMD_INSERT, {0, CMD_RAW_MOVE, CMD_OPT_INTERNAL, cx, cy, cz }, CMD.OPT_ALT )
		end
		GG.recursion_GiveOrderToUnit = false
		unitData.cx, unitData.cy, unitData.cz = cx, cy, cz
		unitData.receivedOrder = true
		return true
	elseif cmdID and move and not behaviour.skirmKeepOrder then
		spGiveOrderToUnit(unitID, CMD_REMOVE, {cmdTag}, 0 )
		return true
	end

	return behaviour.skirmKeepOrder
end

local function DoFleeEnemy(unitID, behaviour, unitData, enemy, enemyUnitDef, typeKnown, move, isIdleAttack, cmdID, cmdTag, frame)
	local unitData = unit[unitID]
	local enemyRange = behaviour.minFleeRange
	
	if enemyUnitDef and typeKnown then
		local range = GetEnemyRange(enemyUnitDef)
		if range > enemyRange then
			enemyRange = range
		end
	end
	if debugAction then
		Spring.Utilities.UnitEcho(unitID, "flee")
	end
	local prediction = behaviour.fleeVelPrediction or behaviour.velocityPrediction
	local vx, vy, vz = spGetUnitVelocity(enemy)
	local ex, ey, ez = spGetUnitPosition(enemy) -- enemy position
	local ux, uy, uz = spGetUnitPosition(unitID) -- my position
	local dx, dy, dz = ex + vx*prediction, ey + vy*prediction, ez + vz*prediction
	if behaviour.selfVelocityPrediction then
		local uvx, uvy, uvz = spGetUnitVelocity(unitID)
		dx, dy, dz = dx - uvx*prediction, dy - uvy*prediction, dz - uvz*prediction
	end
	
	-- Don't use velocity to overestimate distance when fleeing.
	local predictDistSq = DistSq(ux, uz, dx, dz)
	local origDistSq = DistSq(ux, uz, ex, ez)
	local pointDis = ((predictDistSq < origDistSq) and math.sqrt(predictDistSq)) or math.sqrt(origDistSq)

	if isIdleAttack then
		if (debugUnit and debugUnit[unitID]) or debugAll then
			Spring.Echo("=== DoFleeEnemy", unitID, " ===")
		end
		if UpdateIdleAgressionState(unitID, behaviour, unitData, frame, enemy, typeKnown and enemyUnitDef, behaviour.minFleeRange, pointDis, ux, uz, ex, ez) then
			return false
		end
	end
	
	if enemyRange + behaviour.fleeLeeway > pointDis then
		local dis = behaviour.fleeOrderDis
		if (pointDis+dis > behaviour.skirmRange-behaviour.stoppingDistance) then
			dis = (enemyRange+behaviour.fleeDistance-pointDis)
		end
		local f = dis/pointDis
		local cx = ux+(ux-ex)*f
		local cy = uy
		local cz = uz+(uz-ez)*f

		GG.recursion_GiveOrderToUnit = true

		if cmdID then
			if move then
				cx, cy, cz = GiveClampedOrderToUnit(unitID, CMD_INSERT, {0, CMD_RAW_MOVE, CMD_OPT_INTERNAL, cx, cy, cz }, CMD.OPT_ALT )
				spGiveOrderToUnit(unitID, CMD_REMOVE, {cmdTag}, 0 )
			else
				cx, cy, cz = GiveClampedOrderToUnit(unitID, CMD_INSERT, {0, CMD_RAW_MOVE, CMD_OPT_INTERNAL, cx, cy, cz }, CMD.OPT_ALT )
			end
		elseif isIdleAttack then
			cx, cy, cz = GiveClampedOrderToUnit(unitID, CMD_RAW_MOVE, {cx, cy, cz }, CMD_OPT_RIGHT )
		else
			cx, cy, cz = GiveClampedOrderToUnit(unitID, CMD_FIGHT, {cx, cy, cz }, CMD_OPT_RIGHT )
		end
		GG.recursion_GiveOrderToUnit = false
		unitData.cx, unitData.cy, unitData.cz = cx, cy, cz
		unitData.receivedOrder = true
		return true
	elseif cmdID and move then
		spGiveOrderToUnit(unitID, CMD_REMOVE, {cmdTag}, 0 )
	end

	return false
end

local function DoAiLessIdleCheck(unitID, behaviour, unitData, frame, enemy, enemyUnitDef, typeKnown)
	local pointDis = spGetUnitSeparation(enemy, unitID, true)
	if not pointDis then
		return false
	end
	
	if debugAction then
		Spring.Utilities.UnitEcho(unitID, "check")
	end
	
	local ex, ey, ez = spGetUnitPosition(enemy) -- enemy position
	local ux, uy, uz = spGetUnitPosition(unitID) -- my position
	
	if (debugUnit and debugUnit[unitID]) or debugAll then
		Spring.Utilities.UnitEcho(unitID, "Idle " .. unitID)
		Spring.Echo("=== DoAiLessIdleCheck", unitID, " ===")
		Spring.Echo("ex, ey, ez", ex, ey, ez, "ux, uy, uz", ux, uy, uz)
	end
	
	UpdateIdleAgressionState(unitID, behaviour, unitData, frame, enemy, typeKnown and enemyUnitDef, 250, pointDis, ux, uz, ex, ez)
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
---- Unit AI Selection

local function DoTacticalAI(unitID, cmdID, cmdOpts, cmdTag, cp_1, cp_2, cp_3,
		fx, fy, fz, unitData, behaviour, enemy, enemyUnitDef, typeKnown,
		move, haveFight, holdPos, isIdleAttack, particularEnemy, frame, alwaysJink)
	
	if (typeKnown and (not haveFight) and behaviour.fightOnlyUnits and behaviour.fightOnlyUnits[enemyUnitDef]) then
		return false -- Do not tactical AI enemy if it is fight-only.
	end
	
	if behaviour.fightOnlyUnits and behaviour.fightOnlyUnits[enemyUnitDef] and behaviour.fightOnlyOverride then
		behaviour = behaviour.fightOnlyOverride
	end
	
	if isIdleAttack and enemy and (not unitData.idleAgression) and typeKnown and ((behaviour.idleFleeCombat and armedUnitDefIDs[enemyUnitDef]) or (behaviour.idleFlee and behaviour.idleFlee[enemyUnitDef])) then
		if not DoFleeEnemy(unitID, behaviour, unitData, enemy, enemyUnitDef, typeKnown, move, isIdleAttack, cmdID, cmdTag, frame) then
			ClearOrder(unitID, unitData, cmdID, cmdTag, cp_1, cp_2, cp_3)
		end
		return true
	end
	
	local didSwarm = false
	if alwaysJink or (enemy and typeKnown and behaviour.swarms and behaviour.swarms[enemyUnitDef]) then
		--Spring.Echo("unit checking swarm")
		if DoSwarmEnemy(unitID, behaviour, unitData, enemy, enemyUnitDef, typeKnown, move, isIdleAttack, cmdID, cmdTag, fx, fy, fz, frame) then
			didSwarm = true
		else
			ClearOrder(unitID, unitData, cmdID, cmdTag, cp_1, cp_2, cp_3)
		end
	end
	
	if didSwarm then
		-- Units can immediately transition to skirm after swarming.
		-- This can happen if a known auto-target becomes too far away.
		return true
	end
	
	if not enemy then
		return false
	end
	
	local typeSkirm = typeKnown and behaviour.skirms and (behaviour.skirms[enemyUnitDef] or (behaviour.hugs and behaviour.hugs[enemyUnitDef]))
	if (typeSkirm or ((not typeKnown) and behaviour.skirmRadar) or behaviour.skirmEverything) then
		--Spring.Echo("unit checking skirm")
		if not DoSkirmEnemy(unitID, behaviour, unitData, enemy, enemyUnitDef, typeKnown, move, isIdleAttack, cmdID, cmdTag, frame,
				haveFight and holdPos, particularEnemy and (behaviour.hugs and behaviour.hugs[enemyUnitDef])) then
			ClearOrder(unitID, unitData, cmdID, cmdTag, cp_1, cp_2, cp_3)
		end
		return true
	end
	
	if behaviour.fleeEverything then
		if not DoFleeEnemy(unitID, behaviour, unitData, enemy, enemyUnitDef, typeKnown, move, isIdleAttack, cmdID, cmdTag, frame) then
			ClearOrder(unitID, unitData, cmdID, cmdTag, cp_1, cp_2, cp_3)
		end
		return true
	end
	
	if (cmdID == CMD_ATTACK and not Spring.Utilities.CheckBit(DEBUG_NAME, cmdOpts, CMD.OPT_INTERNAL)) then
		return false -- if I have been given attack order manually do not flee
	end
	
	if (typeKnown and ((behaviour.flees and behaviour.flees[enemyUnitDef]) or (behaviour.fleeCombat and armedUnitDefIDs[enemyUnitDef])))
			or (not typeKnown and behaviour.fleeRadar) then
		-- if I have los and the unit is a fleeable or a unit is unarmed and I flee combat - flee
		-- if I do not have los and flee radar dot, flee
		if not DoFleeEnemy(unitID, behaviour, unitData, enemy, enemyUnitDef, typeKnown, move, isIdleAttack, cmdID, cmdTag, frame) then
			ClearOrder(unitID, unitData, cmdID, cmdTag, cp_1, cp_2, cp_3)
		end
		return true
	end
	
	return false
end

local function DoUnitUpdate(unitID, frame, slowUpdate)
	local unitData = unit[unitID]
	
	if unitData.lastUpdate and unitData.lastUpdate + MAX_UPRATE_RATE > frame then
		return
	end
	unitData.lastUpdate = frame
	
	local exitEarly = GetAiExitEarly(unitID, unitData)
	if exitEarly and not slowUpdate then
		return
	end
	
	local cmdID, cmdOpts, cmdTag, cp_1, cp_2, cp_3 = Spring.GetUnitCurrentCommand(unitID)
	local moveState = Spring.Utilities.GetUnitMoveState(unitID)
	local roamState = (moveState == 2)
	local middleMoveState = (moveState == 1)
	local holdPos = (moveState == 0)
	
	local behaviour
	if not (middleMoveState and unitData.wasIdle) then
		if exitEarly then
			unitData.idleWantReturn = false
			return
		end
		behaviour = GetUnitBehavior(unitID, unitData.udID)
		if behaviour.onlyIdleHandling then
			unitData.idleWantReturn = false
			return
		end
	end
	
	local enemy, move, haveFight, autoAttackEnemyID, fightX, fightY, fightZ = GetUnitOrderState(unitID, unitData, cmdID, cmdOpts, cp_1, cp_2, cp_3, holdPos)
	local isIdleAttack = middleMoveState and ((not cmdID) or (autoAttackEnemyID and not haveFight))
	
	if unitData.wasIdle and haveFight and (not isIdleAttack) and unitData.rx then
		if (fightX == unitData.rx) and (fightY == unitData.ry) and (fightZ == unitData.rz) and (not holdPos) then
			isIdleAttack = true
		else
			unitData.rx = nil
		end
	end
	
	local doDebug = (debugUnit and debugUnit[unitID]) or debugAll
	if doDebug then
		Spring.Echo("=== DoUnitAIUpdate", unitID, " ===")
		Spring.Utilities.UnitEcho(unitID, "update " .. unitID)
		Spring.Echo("cmdID", cmdID, "enemy", enemy, "move", move, "haveFight", haveFight, "autoAttackEnemyID", autoAttackEnemyID)
		Spring.Echo("wasIdle", unitData.wasIdle, "isIdleAttack", isIdleAttack, "idleWantReturn", unitData.idleWantReturn)
		Spring.Echo("queueReturnX queueReturnZ", unitData.queueReturnX, unitData.queueReturnZ, "setReturn", unitData.setReturn)
	end
	
	unitData.idleWantReturn = unitData.wasIdle and ((unitData.idleWantReturn and (enemy == -1 or move) and not haveFight) or isIdleAttack)
	if doDebug then
		Spring.Echo("after", "idleWantReturn", unitData.idleWantReturn)
		Spring.Utilities.UnitEcho(unitID, unitData.idleWantReturn and "W" or "O_O")
	end
	
	local sentTacticalAiOrder = false
	if (enemy) then -- if I am fighting/patroling ground, idle, or targeting an enemy
		local particularEnemy = ((enemy ~= -1) or autoAttackEnemyID) and true
		
		behaviour = behaviour or GetUnitBehavior(unitID, unitData.udID)
		local alwaysJink = (behaviour.alwaysJinkFight and ((cmdID == CMD_FIGHT) or move))
		local enemyUnitDef = false
		local typeKnown = false
		
		if not alwaysJink then
			if enemy == -1 then -- if I am fighting/patroling ground get nearest enemy
				enemy = (spGetUnitNearestEnemy(unitID, (cmdID and behaviour.idleSearchRange) or behaviour.searchRange, true) or false)
			end
			--Spring.Utilities.UnitEcho(enemy)
			--Spring.Echo("enemy spotted 2")
			-- don't get info on out of los units
			--Spring.Echo("enemy in los")
			-- use AI on target
			enemyUnitDef, typeKnown = GetUnitVisibleInformation(enemy, unitData.allyTeam)
		end
		
		if not (exitEarly or behaviour.onlyIdleHandling) then
			--Spring.Echo("cmdID", cmdID, cmdTag, move, math.random())
			sentTacticalAiOrder = DoTacticalAI(unitID, cmdID, cmdOpts, cmdTag, cp_1, cp_2, cp_3,
				fightX, fightY, fightZ, unitData, behaviour, enemy, enemyUnitDef, typeKnown,
				move, haveFight, holdPos, unitData.idleWantReturn, particularEnemy, frame, alwaysJink)
			
			if autoAttackEnemyID and not sentTacticalAiOrder then
				enemyUnitDef, typeKnown = GetUnitVisibleInformation(autoAttackEnemyID, unitData.allyTeam)
				sentTacticalAiOrder = DoTacticalAI(unitID, cmdID, cmdOpts, cmdTag, cp_1, cp_2, cp_3,
					fightX, fightY, fightZ, unitData, behaviour, autoAttackEnemyID, enemyUnitDef, typeKnown,
					move, haveFight, holdPos, unitData.idleWantReturn, particularEnemy, frame, alwaysJink)
			end
		end
		
		if enemy and enemy ~= -1 and unitData.idleWantReturn and not sentTacticalAiOrder then
			DoAiLessIdleCheck(unitID, behaviour, unitData, frame, enemy, enemyUnitDef, typeKnown)
		end
	end
	
	if unitData.queueReturnX or ((not cmdID) and unitData.setReturn and unitData.idleX) then
		local rx, rz = unitData.queueReturnX or unitData.idleX, unitData.queueReturnZ or unitData.idleZ
		unitData.queueReturnX = nil
		unitData.queueReturnZ = nil
		unitData.idleWantReturn = nil
		if roamState then -- Roam
			unitData.setReturn = false
		elseif (sentTacticalAiOrder or cmdID or holdPos) and not unitData.forceReturn then
			-- Save for next idle
			unitData.idleX = rx
			unitData.idleZ = rz
			unitData.idleWantReturn = true
		else
			-- If the command queue is empty (ie still idle) then return to position
			local ry = math.max(0, Spring.GetGroundHeight(rx, rz) or 0)
			GiveClampedOrderToUnit(unitID, unitData.wantFightReturn and CMD_FIGHT or CMD_RAW_MOVE, {rx, ry, rz}, CMD.OPT_ALT )
			unitData.setReturn = nil
			unitData.forceReturn = nil
			if unitData.wantFightReturn then
				unitData.rx, unitData.ry, unitData.rz = rx, ry, rz
			end
		end
	end
end

local function UpdateUnits(frame, start, increment)
	--[[
	for unitID, unitData in pairs(unit) do
		if not spValidUnitID(unitID) then
			Spring.Echo("stuff")
		else
	--]]
	local slowUpdate = (frame%3 == 0)
	
	local index = start
	local listData = unitList.data
	while index <= unitList.count do
		local unitID = listData[index]
		if not spValidUnitID(unitID) then
			listData[index] = listData[unitList.count]
			listData[unitList.count] = nil
			unitList.count = unitList.count - 1
			unit[unitID] = nil
		else
			index = index + increment
			DoUnitUpdate(unitID, frame, slowUpdate)
		end
	end
	
	if needNextUpdate then
		for i = 1, #needNextUpdate do
			if spValidUnitID(needNextUpdate[i]) then
				DoUnitUpdate(needNextUpdate[i], frame, false)
			end
		end
		needNextUpdate = false
	end
end

function gadget:GameFrame(n)
	UpdateUnits(n, n%UPDATE_RATE + 1, UPDATE_RATE)
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Idle Handling

local function AddIdleUnit(unitID, unitDefID)
	if not (unit[unitID] and spValidUnitID(unitID)) then
		return
	end
	local unitData = unit[unitID]
	unitData.wasIdle = true
	
	local doDebug = (debugUnit and debugUnit[unitID]) or debugAll
	if doDebug then
		Spring.Utilities.UnitEcho(unitID, "Idle " .. unitID)
		Spring.Echo("=== Unit Idle", unitID, " ===")
	end
	
	if unitData.idleWantReturn and unitData.idleX then
		if doDebug then
			Spring.Echo("Return to idle position", unitData.idleX, unitData.idleZ)
		end
		ReturnUnitToIdlePos(unitID, unitData)
		return
	end
	
	local behaviour = GetUnitBehavior(unitID, unitData.udID)
	local nearbyEnemy = spGetUnitNearestEnemy(unitID, behaviour.leashAgressRange, true) or false
	local x, _, z = Spring.GetUnitPosition(unitID)
	
	unitData.idleX = x
	unitData.idleZ = z
	unitData.wantFightReturn = nil
	unitData.idleWantReturn = nil

	if doDebug then
		Spring.Echo("New Idle", unitData.idleX, unitData.idleZ, nearbyEnemy)
	end
	
	if nearbyEnemy then
		local enemyUnitDef, typeKnown = GetUnitVisibleInformation(nearbyEnemy, unitData.allyTeam)
		if enemyUnitDef and typeKnown then
			local enemyRange = GetEnemyRealRange(enemyUnitDef)
			if enemyRange and enemyRange > 0 then
				local enemyDist = spGetUnitSeparation(nearbyEnemy, unitID, true)
				if enemyRange + behaviour.leashEnemyRangeLeeway < enemyDist then
					nearbyEnemy = false -- Don't aggress against nearby enemy that cannot shoot.
				end
			end
		end
	end
	
	if doDebug then
		Spring.Echo("After nearby check", nearbyEnemy)
	end
	
	SetIdleAgression(unitID, unitData, nearbyEnemy)
	--Spring.Utilities.UnitEcho(unitID, "I")
end

function gadget:UnitIdle(unitID, unitDefID)
	AddIdleUnit(unitID, unitDefID)
end

function gadget:UnitCommand(unitID, unitDefID, unitTeam, cmdID, cmdParams, cmdOpts, cmdTag, playerID, fromSynced, fromLua)
	if playerID == -1 or fromLua then
		return
	end
	if cmdID and stateCommands[cmdID] then
		return
	end
	local unitData = unit[unitID]
	if not unitData then
		return
	end
	if (cmdID == CMD_FIGHT or cmdID == CMD_ATTACK) and unitData.receivedOrder and not cmdOpts.shift then
		needNextUpdate = needNextUpdate or {}
		needNextUpdate[#needNextUpdate + 1] = unitID
	end
	unitData.wasIdle = false
	unitData.idleWantReturn = false
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Command Handling

local function AIToggleCommand(unitID, cmdParams, cmdOptions)
	if unit[unitID] or externallyHandledUnit[unitID] then
		local state = cmdParams[1]
		local cmdDescID = spFindUnitCmdDesc(unitID, CMD_UNIT_AI)
		
		if (cmdDescID) then
			unitAICmdDesc.params[1] = state
			spEditUnitCmdDesc(unitID, cmdDescID, { params = unitAICmdDesc.params})
			if externallyHandledUnit[unitID] then
				Spring.SetUnitRulesParam(unitID, "tacticalAi_external", state, ALLY_TABLE)
			else
				unit[unitID].active = (state == 1)
			end
		end
	end
end

function gadget:AllowCommand_GetWantedCommand()
	return {[CMD_UNIT_AI] = true}
end

function gadget:AllowCommand_GetWantedUnitDefID()
	return true
end

function gadget:AllowCommand(unitID, unitDefID, teamID, cmdID, cmdParams, cmdOptions)
	if (cmdID ~= CMD_UNIT_AI) then
		return true  -- command was not used
	end
	AIToggleCommand(unitID, cmdParams, cmdOptions)
	return false  -- command was used
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Debug

local function ToggleDebugIdleAll(cmd, line, words, player)
	if not Spring.IsCheatingEnabled() then
		return
	end
	debugAll = not debugAll
	Spring.Echo("Debug Idle All", debugAll)
end

local function ToggleDebugAiAction(cmd, line, words, player)
	if not Spring.IsCheatingEnabled() then
		return
	end
	debugAction = not debugAction
	Spring.Echo("Debug Tactical AI", debugAction)
end

local function ToggleDebugIdleUnit(cmd, line, words, player)
	if not Spring.IsCheatingEnabled() then
		return
	end
	local unitID = tonumber(words[1])
	Spring.Echo("Debug Idle")
	if not unitID then
		Spring.Echo("Disabled")
		debugUnit = nil
		return
	end
	
	Spring.Echo("Adding unitID", unitID)
	Spring.Utilities.UnitEcho(unitID)
	debugUnit = debugUnit or {}
	debugUnit[unitID] = true
end

local function PrintUnits(cmd, line, words, player)
	if not Spring.IsCheatingEnabled() then
		return
	end
	local listData = unitList.data
	for i = 1, unitList.count do
		Spring.Utilities.UnitEcho(listData[i])
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Unit adding/removal

function gadget:Initialize()
	-- register command
	gadgetHandler:RegisterCMDID(CMD_UNIT_AI)
	
	-- load active units
	for _, unitID in ipairs(Spring.GetAllUnits()) do
		local unitDefID = spGetUnitDefID(unitID)
		local teamID = Spring.GetUnitTeam(unitID)
		gadget:UnitCreated(unitID, unitDefID, teamID)
	end
	
	gadgetHandler:AddChatAction("debugidleall", ToggleDebugIdleAll, "")
	gadgetHandler:AddChatAction("debugai", ToggleDebugAiAction, "")
	gadgetHandler:AddChatAction("debugidle", ToggleDebugIdleUnit, "")
	gadgetHandler:AddChatAction("printunits", PrintUnits, "")
end

function gadget:UnitGiven(unitID, unitDefID, teamID, oldTeamID)
	if unit[unitID] then
		unit[unitID].allyTeam = spGetUnitAllyTeam(unitID)
	end
end

function gadget:UnitCreated(unitID, unitDefID, unitTeam, builderID)
	-- add swarmers
	if not unitAIBehaviour[unitDefID] then
		return
	end
	local behaviour = unitAIBehaviour[unitDefID]
	
	if not behaviour.onlyIdleHandling then
		spInsertUnitCmdDesc(unitID, unitAICmdDesc)
	end
	
	if behaviour.externallyHandled then
		externallyHandledUnit[unitID] = true
		if (behaviour.defaultAIState == 1) then
			AIToggleCommand(unitID, {1}, {})
		else
			AIToggleCommand(unitID, {0}, {})
		end
		return
	end
	
	--Spring.Echo("unit added")
	if not unit[unitID] then
		unitList.count = unitList.count + 1
		unitList.data[unitList.count] = unitID
	end
	
	unit[unitID] = {
		cx = 0, cy = 0, cz = 0,
		udID = unitDefID,
		jinkDir = random(0, 1)*2-1,
		rot = random(0, 1)*2-1,
		active = false,
		receivedOrder = false,
		allyTeam = spGetUnitAllyTeam(unitID),
	}
	
	if not behaviour.onlyIdleHandling then
		if (behaviour.defaultAIState == 1) then
			AIToggleCommand(unitID, {1}, {})
		else
			AIToggleCommand(unitID, {0}, {})
		end
	end
end

function gadget:UnitDestroyed(unitID, unitDefID, unitTeam)
	if externallyHandledUnit[unitID] then
		externallyHandledUnit[unitID] = nil
	end
end
