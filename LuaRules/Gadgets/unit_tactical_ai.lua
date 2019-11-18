
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
if (not gadgetHandler:IsSyncedCode()) then
	return false  --  no unsynced code
end


--------------------------------------------------------------------------------
-- Speedups

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

local armedUnitDefIDs = {}
for i = 1, #UnitDefs do
	if not UnitDefs[i].modCategories["unarmed"] then
		armedUnitDefIDs[i] = true
	end
end

local ALLY_TABLE = {
	ally = true,
}

--------------------------------------------------------------------------------
-- Globals

local unit = {}
local unitList = {count = 0, data = {}}
local unitAIBehaviour = {}
local externallyHandledUnit = {}

local HEADING_TO_RAD = (math.pi*2/2^16)

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
	params  = {0, 'AI Off','AI On'}
}
--------------------------
---- Unit AI
--------------------------

local function distance(x1,y1,x2,y2)
	return sqrt((x1-x2)^2 + (y1-y2)^2)
end

local function getUnitOrderState(unitID, data, cmdID, cmdOpts, cp_1, cp_2, cp_3, holdPos)
	-- ret 1: enemy ID, value of -1 means no manual target set so the nearest enemy should be used.
	--        Return false means the unit does not want orders from tactical ai.
	-- ret 2: true if there is a move command at the start of queue which will need removal.
	-- ret 3: true if the unit is using AI due to a fight or patrol command.
	-- ret 4: fallback enemy ID. This is set if the unit has a non-manual attack command.
	--        Use it as a fallback if there is no behaviour against the nearest enemy.
	-- ret 5, 6, 7: Fight command target
	
	if not cmdID then
		if (not holdPos) then
			return -1, false -- could still skirm from static or flee
		end
		return false -- no queue and on hold position.
	end
	if (holdPos and cmdID == CMD_ATTACK and Spring.Utilities.CheckBit(gadget:GetInfo().name, cmdOpts, CMD.OPT_INTERNAL)) then
		if spGetCommandQueue(unitID, 0) == 1 then
			return false -- set to hold position and is auto-acquiring target
		end
	end
	
	if cmdID == CMD_FIGHT then
		return -1, false, true, nil, cp_1, cp_2, cp_3
	elseif cmdID == CMD_ATTACK then -- if I attack
		local cmdID_2 = Spring.GetUnitCurrentCommand(unitID, 2)
		if ((not holdPos) or (cmdID_2 == CMD_FIGHT)) then
			local target, check = cp_1, cp_2
			if (not check) and spValidUnitID(target) then -- if I target a unit
				if not (cmdID == CMD_FIGHT or cmdID_2 == CMD_FIGHT or Spring.Utilities.CheckBit(gadget:GetInfo().name, cmdOpts, CMD.OPT_INTERNAL)) then -- only skirm single target when given the order manually
					return target, false
				else
					return -1, false, true, target
				end
			elseif (cmdID == CMD_FIGHT) then --  if I target the ground and have fight or patrol command
				return -1, false, nil, nil, cp_1, cp_2, cp_3
			end
		end
	elseif (cmdID == CMD_MOVE or cmdID == CMD_RAW_MOVE) and (cp_1 == data.cx) and (cp_2 == data.cy) and (cp_3 == data.cz) then
		local cmdID_2, cmdOpts_2, _, cps_1, cps_2, cps_3 = Spring.GetUnitCurrentCommand(unitID, 2)
		if cmdID_2 then
			local cmdID_3 = Spring.GetUnitCurrentCommand(unitID, 3)
			if cmdID_2 == CMD_FIGHT or (cmdID_2 == CMD_ATTACK and ((not holdPos) or cmdID_3 == CMD_FIGHT)) then -- if the next command is attack, patrol or fight
				local target, check = cps_1, cps_2
				if not check then -- if I target a unit
					if not (cmdID_2 == CMD_FIGHT or cmdID_3 == CMD_FIGHT or Spring.Utilities.CheckBit(gadget:GetInfo().name, cmdOpts_2, CMD.OPT_INTERNAL)) then -- only skirm single target when given the order manually
						return target, true, nil, nil, cps_1, cps_2, cps_3
					else
						return -1, true, true, target, cps_1, cps_2, cps_3
					end
				elseif (cmdID_2 == CMD_FIGHT) then -- if I target the ground and have fight or patrol command
					return -1, true, true, nil, cps_1, cps_2, cps_3
				end
			end
		end
	end

	return false
end

local function clearOrder(unitID,data, cmdID, cmdTag, cp_1, cp_2, cp_3)
	-- removes move order
	if data.receivedOrder then
		if (cmdID and (cmdID == CMD_MOVE or cmdID == CMD_RAW_MOVE)) then -- if I am moving
			if (cp_1 == data.cx) and (cp_2 == data.cy) and (cp_3 == data.cz) then -- if I was given this move command by this gadget
				spGiveOrderToUnit(unitID, CMD_REMOVE, {cmdTag}, 0)
				GG.StopRawMoveUnit(unitID, true)
			end
		end
		data.receivedOrder = false
	end
end

local function swarmEnemy(unitID, behaviour, enemy, enemyUnitDef, typeKnown, move, cmdID, cmdTag, fightX, fightY, fightZ, n)

	local data = unit[unitID]

	if enemy and typeKnown then
	
		local pointDis = spGetUnitSeparation(enemy,unitID,true)
		
		if pointDis then
			local enemyRange = behaviour.swarmEnemyDefaultRange
			if enemyUnitDef and typeKnown then
				enemyRange = UnitDefs[enemyUnitDef].maxWeaponRange
			end
			if pointDis < enemyRange+behaviour.swarmLeeway then -- if I am within enemy range
				if behaviour.maxSwarmRange < pointDis then -- if I cannot shoot at the enemy
					
					local ex,ey,ez = spGetUnitPosition(enemy) -- enemy position
					local ux,uy,uz = spGetUnitPosition(unitID) -- my position
					local cx,cy,cz -- command position
					
					-- insert move commands to jink towards enemy
					data.jinkDir = data.jinkDir*-1
					
					-- jink towards the enemy
					if behaviour.localJinkOrder and behaviour.jinkParallelLength < pointDis then
						cx = ux+(-(ux-ex)*behaviour.jinkParallelLength-(uz-ez)*data.jinkDir*behaviour.jinkTangentLength)/pointDis
						cy = uy
						cz = uz+(-(uz-ez)*behaviour.jinkParallelLength+(ux-ex)*data.jinkDir*behaviour.jinkTangentLength)/pointDis
					else
						cx = ex+(uz-ez)*data.jinkDir*behaviour.jinkTangentLength/pointDis
						cy = ey
						cz = ez+(ux-ex)*data.jinkDir*behaviour.jinkTangentLength/pointDis
					end
					
					GG.recursion_GiveOrderToUnit = true
					if move then
						spGiveOrderToUnit(unitID, CMD_REMOVE, {cmdTag}, 0 )
						cx,cy,cz = GiveClampedOrderToUnit(unitID, CMD_INSERT, {0, CMD_RAW_MOVE, CMD_OPT_INTERNAL, cx,cy,cz }, CMD.OPT_ALT )
					else
						cx,cy,cz = GiveClampedOrderToUnit(unitID, CMD_INSERT, {0, CMD_RAW_MOVE, CMD_OPT_INTERNAL, cx,cy,cz }, CMD.OPT_ALT )
					end
					GG.recursion_GiveOrderToUnit = false
					data.cx,data.cy,data.cz = cx,cy,cz
					
					data.receivedOrder = true
					return true
				else
					-- if I can shoot at the enemy
					local ex,ey,ez = spGetUnitPosition(enemy) -- enemy position
					local ux,uy,uz = spGetUnitPosition(unitID) -- my position
					local cx,cy,cz -- command position
					
					if behaviour.circleStrafe then
						-- jink around the enemy
						local up = 0
						local ep = 1
						if pointDis < behaviour.minCircleStrafeDistance then
							up = 1
							ep = 0
						end
						
						cx = ux*up+ex*ep+data.rot*(uz-ez)*behaviour.strafeOrderLength/pointDis
						cy = uy
						cz = uz*up+ez*ep-data.rot*(ux-ex)*behaviour.strafeOrderLength/pointDis
						
					else
						if pointDis > behaviour.minSwarmRange then
							-- jink at max range
							cx = ux+data.rot*(uz-ez)*behaviour.strafeOrderLength/pointDis
							cy = uy
							cz = uz-data.rot*(ux-ex)*behaviour.strafeOrderLength/pointDis
							data.rot = data.rot*-1
						else
							data.jinkDir = data.jinkDir*-1 -- jink away
							cx = ux-(-(ux-ex)*behaviour.jinkAwayParallelLength-(uz-ez)*data.jinkDir*behaviour.jinkTangentLength)/pointDis
							cy = uy
							cz = uz-(-(uz-ez)*behaviour.jinkAwayParallelLength+(ux-ex)*data.jinkDir*behaviour.jinkTangentLength)/pointDis
						end
					end
					
					GG.recursion_GiveOrderToUnit = true
					if move then
						cx,cy,cz = GiveClampedOrderToUnit(unitID, CMD_INSERT, {0, CMD_RAW_MOVE, CMD_OPT_INTERNAL, cx,cy,cz }, CMD.OPT_ALT )
						spGiveOrderToUnit(unitID, CMD_REMOVE, {cmdTag}, 0 )
					else
						cx,cy,cz = GiveClampedOrderToUnit(unitID, CMD_INSERT, {0, CMD_RAW_MOVE, CMD_OPT_INTERNAL, cx,cy,cz }, CMD.OPT_ALT )
					end
					GG.recursion_GiveOrderToUnit = false
					data.cx,data.cy,data.cz = cx,cy,cz
					data.receivedOrder = true
				end
				return true
			end
		end
		
	else
		
		if ((cmdID == CMD_FIGHT) or move) and fightZ then
			local ex,ey,ez = fightX, fightY, fightZ
			local ux,uy,uz = spGetUnitPosition(unitID) -- my position
			local cx,cy,cz -- command position
			
			local pointDis = distance(ex,ez,ux,uz)
			
			-- insert move commands to jink towards enemy
			data.jinkDir = data.jinkDir*-1
			
			-- jink towards the enemy
			if behaviour.localJinkOrder and behaviour.jinkParallelLength < pointDis then
				cx = ux+(-(ux-ex)*behaviour.jinkParallelLength-(uz-ez)*data.jinkDir*behaviour.jinkTangentLength)/pointDis
				cy = uy
				cz = uz+(-(uz-ez)*behaviour.jinkParallelLength+(ux-ex)*data.jinkDir*behaviour.jinkTangentLength)/pointDis
			else
				cx = ex+(uz-ez)*data.jinkDir*behaviour.jinkTangentLength/pointDis
				cy = ey
				cz = ez+(ux-ex)*data.jinkDir*behaviour.jinkTangentLength/pointDis
			end
			
			if move then
				spGiveOrderToUnit(unitID, CMD_INSERT, {0, CMD_RAW_MOVE, CMD_OPT_INTERNAL, cx,cy,cz }, CMD.OPT_ALT )
				spGiveOrderToUnit(unitID, CMD_REMOVE, {cmdTag}, 0 )
			else
				spGiveOrderToUnit(unitID, CMD_INSERT, {0, CMD_RAW_MOVE, CMD_OPT_INTERNAL, cx,cy,cz }, CMD.OPT_ALT )
			end
			--Spring.SetUnitMoveGoal(unitID, cx,cy,cz)
			data.cx,data.cy,data.cz = cx,cy,cz
				
			data.receivedOrder = true
			return true
		end
	end
	
	return false
	
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

local function skirmEnemy(unitID, behaviour, enemy, enemyUnitDef, move, cmdID, cmdTag, n, haveFightAndHoldPos, doHug)

	local data = unit[unitID]
	--local pointDis = spGetUnitSeparation (enemy,unitID,true)
	
	local vx,vy,vz, enemySpeed = spGetUnitVelocity(enemy)
	local ex,ey,ez,_,aimY = spGetUnitPosition(enemy, false, true) -- enemy position
	local ux,uy,uz = spGetUnitPosition(unitID) -- my position

	if not (ex and vx) then
		return behaviour.skirmKeepOrder
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
	local dx,dy,dz = ex + vx*predict, ey + vy*predict, ez + vz*predict
	if behaviour.selfVelocityPrediction then
		local uvx,uvy,uvz = spGetUnitVelocity(unitID)
		dx,dy,dz = dx - uvx*behaviour.velocityPrediction, dy - uvy*behaviour.velocityPrediction, dz - uvz*behaviour.velocityPrediction
	end
	
	local eDistSq = ex^2 + ey^2 + ez^2
	local eDist = sqrt(eDistSq)
	
	-- Scalar projection of prediction vector onto enemy vector
	local predProj = (ex*dx + ey*dy + ez*dz)/eDistSq

	-- Calculate predicted enemy distance
	local predictedDist = eDist
	if predProj > 0 then
		predictedDist = predictedDist*predProj
	else
		-- In this case the enemy is predicted to go past me
		predictedDist = 0
	end
	local skirmRange = (doHug and behaviour.hugRange) or ((GetEffectiveWeaponRange(data.udID, -dy, behaviour.weaponNum) or 0) - behaviour.skirmLeeway)
	local reloadFrames
	if behaviour.reloadSkirmLeeway then
		local reloadState = spGetUnitWeaponState(unitID, behaviour.weaponNum, 'reloadState')
		if reloadState then
			reloadFrames = reloadState - n
			if reloadFrames > 0 then
				skirmRange = skirmRange + reloadFrames*behaviour.reloadSkirmLeeway
			end
		end
	end
	
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
					reloadFrames = reloadState - n
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
			cx,cy,cz = GiveClampedOrderToUnit(unitID, CMD_INSERT, {0, CMD_RAW_MOVE, CMD_OPT_INTERNAL, cx,cy,cz }, CMD.OPT_ALT )
			spGiveOrderToUnit(unitID, CMD_REMOVE, {cmdTag}, 0 )
		else
			cx,cy,cz = GiveClampedOrderToUnit(unitID, CMD_INSERT, {0, CMD_RAW_MOVE, CMD_OPT_INTERNAL, cx,cy,cz }, CMD.OPT_ALT )
		end
		GG.recursion_GiveOrderToUnit = false
		data.cx, data.cy, data.cz = cx, cy, cz
		data.receivedOrder = true
		return true
	elseif cmdID and move and not behaviour.skirmKeepOrder then
		spGiveOrderToUnit(unitID, CMD_REMOVE, {cmdTag}, 0 )
	end

	return behaviour.skirmKeepOrder
end

local function fleeEnemy(unitID, behaviour, enemy, enemyUnitDef, typeKnown, move, cmdID, cmdTag, n)

	local data = unit[unitID]

	local enemyRange = behaviour.minFleeRange
	
	if enemyUnitDef and typeKnown then
		local range = UnitDefs[enemyUnitDef].maxWeaponRange
		if range > enemyRange then
			enemyRange = range
		end
	end

	--local pointDis = spGetUnitSeparation (enemy,unitID,true)
	
	local vx,vy,vz = spGetUnitVelocity(enemy)
	local ex,ey,ez = spGetUnitPosition(enemy) -- enemy position
	local ux,uy,uz = spGetUnitPosition(unitID) -- my position
	local dx,dy,dz = ex + vx*behaviour.velocityPrediction, ey + vy*behaviour.velocityPrediction, ez + vz*behaviour.velocityPrediction
	if behaviour.selfVelocityPrediction then
		local uvx,uvy,uvz = spGetUnitVelocity(unitID)
		dx,dy,dz = dx - uvx*behaviour.velocityPrediction, dy - uvy*behaviour.velocityPrediction, dz - uvz*behaviour.velocityPrediction
	end
	
	local pointDis = sqrt((dx-ux)^2 + (dy-uy)^2 + (dz-uz)^2)

	if enemyRange + behaviour.fleeLeeway > pointDis then

		local dis = behaviour.fleeOrderDis
		local f = dis/pointDis
		if (pointDis+dis > behaviour.skirmRange-behaviour.stoppingDistance) then
			f = (enemyRange+behaviour.fleeDistance-pointDis)/pointDis
		end
		local cx = ux+(ux-ex)*f
		local cy = uy
		local cz = uz+(uz-ez)*f

		GG.recursion_GiveOrderToUnit = true

		if cmdID then
			if move then
				spGiveOrderToUnit(unitID, CMD_REMOVE, {cmdTag}, 0 )
				cx,cy,cz = GiveClampedOrderToUnit(unitID, CMD_INSERT, {0, CMD_RAW_MOVE, CMD_OPT_INTERNAL, cx,cy,cz }, CMD.OPT_ALT )
			else
				cx,cy,cz = GiveClampedOrderToUnit(unitID, CMD_INSERT, {0, CMD_RAW_MOVE, CMD_OPT_INTERNAL, cx,cy,cz }, CMD.OPT_ALT )
			end
		else
			cx,cy,cz = GiveClampedOrderToUnit(unitID, CMD_FIGHT, {cx,cy,cz }, CMD_OPT_RIGHT )
		end
		GG.recursion_GiveOrderToUnit = false
		data.cx,data.cy,data.cz = cx,cy,cz
		data.receivedOrder = true
		return true
	elseif cmdID and move then
		spGiveOrderToUnit(unitID, CMD_REMOVE, {cmdTag}, 0 )
	end

	return false
end

local function GetUnitVisibleInformation(unitID, allyTeamID)
	if (not unitID) or select(2, spGetUnitIsStunned(unitID)) then
		return
	end
	local states = spGetUnitLosState(unitID, allyTeamID, false)
	return spGetUnitDefID(unitID), states and states.typed
end

local function DoTacticalAI(unitID, cmdID, cmdOpts, cmdTag, cp_1, cp_2, cp_3, fx, fy, fz, data, behaviour, enemy, enemyUnitDef, typeKnown, move, haveFight, holdPos, particularEnemy, frame, alwaysJink)
	-- Apologies for this function.
	local usefulEnemy = false
	if not (typeKnown and (not haveFight) and behaviour.fightOnlyUnits and behaviour.fightOnlyUnits[enemyUnitDef]) then
		if behaviour.fightOnlyUnits and behaviour.fightOnlyUnits[enemyUnitDef] and behaviour.fightOnlyOverride then
			behaviour = behaviour.fightOnlyOverride
		end
		
		local checkSkirm = true

		if alwaysJink or (enemy and typeKnown and behaviour.swarms[enemyUnitDef]) then
			--Spring.Echo("unit checking swarm")
			usefulEnemy = true
			if swarmEnemy(unitID, behaviour, enemy, enemyUnitDef, typeKnown, move, cmdID, cmdTag, fx, fy, fz, frame) then
				checkSkirm = false
			else
				clearOrder(unitID, data, cmdID, cmdTag, cp_1, cp_2, cp_3)
			end
		end
		if checkSkirm then
			local typeSkirm = typeKnown and (behaviour.skirms[enemyUnitDef] or (behaviour.hugs and behaviour.hugs[enemyUnitDef]))
			if enemy and (typeSkirm or ((not typeKnown) and behaviour.skirmRadar) or behaviour.skirmEverything) then
				--Spring.Echo("unit checking skirm")
				usefulEnemy = true
				if not skirmEnemy(unitID, behaviour, enemy, enemyUnitDef, move, cmdID, cmdTag, frame, haveFight and holdPos, particularEnemy and (behaviour.hugs and behaviour.hugs[enemyUnitDef])) then
					clearOrder(unitID, data, cmdID, cmdTag, cp_1, cp_2, cp_3)
				end
			else
				if (enemy and behaviour.fleeEverything) or not((not enemy)
						or (cmdID == CMD_ATTACK and not Spring.Utilities.CheckBit(gadget:GetInfo().name, cmdOpts, CMD.OPT_INTERNAL))
						-- if I have been given attack order manually do not flee
						or not ((typeKnown and (behaviour.flees[enemyUnitDef] or (behaviour.fleeCombat and armedUnitDefIDs[enemyUnitDef])))
						-- if I have los and the unit is a fleeable or a unit is unarmed and I flee combat - flee
						or (not typeKnown and behaviour.fleeRadar))) then
						-- if I do not have los and flee radar dot, flee
					usefulEnemy = true
					if not fleeEnemy(unitID, behaviour, enemy, enemyUnitDef, typeKnown, move, cmdID, cmdTag, frame) then
						clearOrder(unitID, data, cmdID, cmdTag, cp_1, cp_2, cp_3)
					end
					--Spring.Echo("unit checking flee")
				end
			end
		end
	end
	return usefulEnemy
end

local function updateUnits(frame, start, increment)
	--[[
	for unitID, data in pairs(unit) do
		if not spValidUnitID(unitID) then
			Spring.Echo("stuff")
		else
	--]]
		
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
			local data = unit[unitID]
			
			--Spring.Echo("unit parsed")
			if (not data.active) or spGetUnitRulesParam(unitID,"disable_tac_ai") == 1 then
				if data.receivedOrder then
					local cmdID, _, cmdTag, cp_1, cp_2, cp_3 = Spring.GetUnitCurrentCommand(unitID)
					clearOrder(unitID, data, cmdID, cmdTag, cp_1, cp_2, cp_3)
				end
				break
			end
			
			local cmdID, cmdOpts, cmdTag, cp_1, cp_2, cp_3 = Spring.GetUnitCurrentCommand(unitID)
			local holdPos = (Spring.Utilities.GetUnitMoveState(unitID) == 0)
			local enemy, move, haveFight, autoAttackEnemyID, fightX, fightY, fightZ = getUnitOrderState(unitID, data, cmdID, cmdOpts, cp_1, cp_2, cp_3, holdPos)
			
			--local ux,uy,uz = spGetUnitPosition(unitID)
			--Spring.MarkerAddPoint(ux,uy,uz,"unit active")
			if (enemy) then -- if I am fighting/patroling ground or targeting an enemy
				local particularEnemy = ((enemy ~= -1) or autoAttackEnemyID) and true
				local behaviour
				if unitAIBehaviour[data.udID].waterline then
					local _,by = spGetUnitPosition(unitID, true)
					if by < unitAIBehaviour[data.udID].waterline then
						behaviour = unitAIBehaviour[data.udID].sea
					else
						behaviour = unitAIBehaviour[data.udID].land
					end
				else
					behaviour = unitAIBehaviour[data.udID]
				end
				
				local alwaysJink = (behaviour.alwaysJinkFight and ((cmdID == CMD_FIGHT) or move))
				local enemyUnitDef = false
				local typeKnown = false
				
				if not alwaysJink then
					if enemy == -1 then -- if I am fighting/patroling ground get nearest enemy
						enemy = (spGetUnitNearestEnemy(unitID,behaviour.searchRange,true) or false)
					end
					--GG.UnitEcho(enemy)
					--Spring.Echo("enemy spotted 2")
					-- don't get info on out of los units
					--Spring.Echo("enemy in los")
					-- use AI on target

					enemyUnitDef, typeKnown = GetUnitVisibleInformation(enemy, data.allyTeam)
				end
				
				local usefulEnemy = DoTacticalAI(unitID, cmdID, cmdOpts, cmdTag, cp_1, cp_2, cp_3, fightX, fightY, fightZ,
					data, behaviour, enemy, enemyUnitDef, typeKnown, move, haveFight, holdPos, particularEnemy, frame, alwaysJink)
				
				if autoAttackEnemyID and not usefulEnemy then
					enemyUnitDef, typeKnown = GetUnitVisibleInformation(autoAttackEnemyID, data.allyTeam)
					DoTacticalAI(unitID, cmdID, cmdOpts, cmdTag, cp_1, cp_2, cp_3, fightX, fightY, fightZ,
						data, behaviour, autoAttackEnemyID, enemyUnitDef, typeKnown, move, haveFight, holdPos, particularEnemy, frame, alwaysJink)
				end
			end
		end
	end
end

function gadget:GameFrame(n)
 
	-- update orders
	--if (n%20<1) then
	--	updateUnits(n, 1, 1)
	--end
	 
	updateUnits(n, n%20+1, 20)
  
end

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

------------------------------------------------------
-- Load Ai behaviour

local function GetBehaviourTable(behaviourData, ud)
	
	local weaponRange
	if behaviourData.weaponNum and ud.weapons[behaviourData.weaponNum] then
		local weaponDefID = ud.weapons[behaviourData.weaponNum].weaponDef
		weaponRange = WeaponDefs[weaponDefID].range
	else
		weaponRange = ud.maxWeaponRange
	end
	
	behaviourData.weaponNum               = (behaviourData.weaponNum or 1)
	behaviourData.maxSwarmRange           = weaponRange - (behaviourData.maxSwarmLeeway or 0)
	behaviourData.minSwarmRange           = weaponRange - (behaviourData.minSwarmLeeway or weaponRange/2)
	behaviourData.minCircleStrafeDistance = weaponRange - (behaviourData.minCircleStrafeDistance or behaviourDefaults.defaultMinCircleStrafeDistance)
	behaviourData.skirmRange              = weaponRange
	behaviourData.skirmLeeway             = (behaviourData.skirmLeeway or 0)
	behaviourData.jinkTangentLength       = (behaviourData.jinkTangentLength or behaviourDefaults.defaultJinkTangentLength)
	behaviourData.jinkParallelLength      = (behaviourData.jinkParallelLength or behaviourDefaults.defaultJinkParallelLength)
	behaviourData.jinkAwayParallelLength  = (behaviourData.jinkAwayParallelLength or behaviourDefaults.defaultJinkAwayParallelLength)
	behaviourData.localJinkOrder          = (behaviourData.alwaysJinkFight or behaviourDefaults.defaultLocalJinkOrder)
	behaviourData.stoppingDistance        = (behaviourData.stoppingDistance or 0)
	behaviourData.strafeOrderLength       = (behaviourData.strafeOrderLength or behaviourDefaults.defaultStrafeOrderLength)
	behaviourData.fleeLeeway              = (behaviourData.fleeLeeway or 100)
	behaviourData.fleeDistance            = (behaviourData.fleeDistance or 100)
	behaviourData.minFleeRange            = (behaviourData.minFleeRange or 0)
	behaviourData.swarmLeeway             = (behaviourData.swarmLeeway or 50)
	behaviourData.skirmOrderDis           = (behaviourData.skirmOrderDis or behaviourDefaults.defaultSkirmOrderDis)
	behaviourData.velocityPrediction      = (behaviourData.velocityPrediction or behaviourDefaults.defaultVelocityPrediction)
	behaviourData.searchRange             = (behaviourData.searchRange or math.max(weaponRange + 100, 800))
	behaviourData.fleeOrderDis            = (behaviourData.fleeOrderDis or 120)
	behaviourData.hugRange                = (behaviourData.hugRange or behaviourDefaults.defaultHugRange)
	behaviourData.minFleeRange            = behaviourData.minFleeRange - behaviourData.fleeLeeway
	behaviourData.mySpeed                 = ud.speed/30
	
	if behaviourData.fightOnlyOverride then
		for k, v in pairs(behaviourData) do
			if not (k == "fightOnlyOverride" or behaviourData.fightOnlyOverride[k]) then
				behaviourData.fightOnlyOverride[k] = v
			end
		end
		behaviourData.fightOnlyOverride = GetBehaviourTable(behaviourData.fightOnlyOverride, ud)
	end
	
	return behaviourData
end

local function LoadBehaviour(unitConfigArray, behaviourDefaults)
	for unitDef, behaviourData in pairs(unitConfigArray) do
		local ud = UnitDefNames[unitDef]
		
		if ud then
			if behaviourData.land and behaviourData.sea then
				unitAIBehaviour[ud.id] = {
					defaultAIState = (behaviourData.defaultAIState or behaviourDefaults.defaultState),
					waterline = (behaviourData.waterline or 0),
					land = GetBehaviourTable(behaviourData.land, ud),
					sea = GetBehaviourTable(behaviourData.sea, ud),
				}
			else
				unitAIBehaviour[ud.id] = GetBehaviourTable(behaviourData, ud)
				unitAIBehaviour[ud.id].defaultAIState = (behaviourData.defaultAIState or behaviourDefaults.defaultState)
			end
		end
	end
end

--------------------------------------------------------------------------------
-- Unit adding/removal

function gadget:Initialize()

	-- import config
	behaviourDefs, behaviourDefaults = include("LuaRules/Configs/tactical_ai_defs.lua")
	if not behaviourDefs then
		Spring.Log(gadget:GetInfo().name, LOG.ERROR, "LuaRules/Configs/tactical_ai_defs.lua not found")
		gadgetHandler:RemoveGadget()
		return
	end
	LoadBehaviour(behaviourDefs, behaviourDefaults)

	-- register command
	gadgetHandler:RegisterCMDID(CMD_UNIT_AI)
	
	-- load active units
	for _, unitID in ipairs(Spring.GetAllUnits()) do
		local unitDefID = spGetUnitDefID(unitID)
		local teamID = Spring.GetUnitTeam(unitID)
		gadget:UnitCreated(unitID, unitDefID, teamID)
	end
	
end

function gadget:UnitCreated(unitID, unitDefID, unitTeam, builderID)

	local ud = UnitDefs[unitDefID]
	-- add swarmers
	if unitAIBehaviour[unitDefID] then
		behaviour = unitAIBehaviour[unitDefID]
		spInsertUnitCmdDesc(unitID, unitAICmdDesc)
		
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
			jinkDir = random(0,1)*2-1,
			rot = random(0,1)*2-1,
			active = false,
			receivedOrder = false,
			allyTeam = spGetUnitAllyTeam(unitID),
		}
		
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
