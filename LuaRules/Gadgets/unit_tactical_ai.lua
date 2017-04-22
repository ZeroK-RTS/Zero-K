function gadget:GetInfo()
  return {
	name 	= "Tactical Unit AI",
	desc	= "Implements tactial AI for some units. Uses move goals (unreliable).",
	author	= "Google Frog",
	date	= "April 20 2010",
	license	= "GNU GPL, v2 or later",
	layer	= 0,
	enabled = false --true,
  }
end

--------------------------------------------------------------------------------
if (not gadgetHandler:IsSyncedCode()) then
  return false  --  no unsynced code
end


--------------------------------------------------------------------------------
-- Speedups

local spInsertUnitCmdDesc   = Spring.InsertUnitCmdDesc
local spGetCommandQueue		= Spring.GetCommandQueue
local spGetUnitDefID		= Spring.GetUnitDefID	
local spGetUnitPosition		= Spring.GetUnitPosition
local spGetUnitVelocity		= Spring.GetUnitVelocity
local spGiveOrderToUnit		= Spring.GiveOrderToUnit
local spGetUnitNearestEnemy = Spring.GetUnitNearestEnemy
local spGetUnitSeparation 	= Spring.GetUnitSeparation
local spEditUnitCmdDesc 	= Spring.EditUnitCmdDesc
local spFindUnitCmdDesc		= Spring.FindUnitCmdDesc
local spGetUnitAllyTeam		= Spring.GetUnitAllyTeam
local spGetUnitLosState		= Spring.GetUnitLosState
local spGetUnitStates		= Spring.GetUnitStates
local spValidUnitID			= Spring.ValidUnitID
local spGetUnitIsStunned    = Spring.GetUnitIsStunned
local spGetUnitRulesParam	= Spring.GetUnitRulesParam
local random 				= math.random
local sqrt 					= math.sqrt
local min                   = math.min

local ClampPosition = Spring.Utilities.ClampPosition
local GetEffectiveWeaponRange = Spring.Utilities.GetEffectiveWeaponRange

--------------------------------------------------------------------------------
-- Globals

local unit = {}
local unitList = {count = 0, data = {}}
local unitAIBehaviour = {}

--------------------------------------------------------------------------------
-- Commands

local CMD_MOVE			= CMD.MOVE
local CMD_ATTACK		= CMD.ATTACK
local CMD_FIGHT			= CMD.FIGHT
local CMD_WAIT			= CMD.WAIT
local CMD_OPT_INTERNAL 	= CMD.OPT_INTERNAL
local CMD_OPT_RIGHT 	= CMD.OPT_RIGHT
local CMD_INSERT 		= CMD.INSERT
local CMD_REMOVE 		= CMD.REMOVE

include("LuaRules/Configs/customcmds.h.lua")

local unitAICmdDesc = {
	id      = CMD_UNIT_AI,
	type    = CMDTYPE.ICON_MODE,
	name    = 'Unit AI',
	action  = 'unitai',
	tooltip	= 'Toggles smart unit AI for the unit',
	params 	= {0, 'AI Off','AI On'}
}
--------------------------
---- Move Goal Handling
--------------------------
local function distance(x1,y1,x2,y2)
	return sqrt((x1-x2)^2 + (y1-y2)^2)
end

local function ClampedRawMove(unitID, x, y, z, data)
	x, z = ClampPosition(x, z)
	Spring.SetUnitMoveGoal(unitID, x, y, z, 8, nil, true)
	data.moveGoalSet = true
end

local function ClearMoveGoal(unitID, data)
	-- removes move order
	if data.moveGoalSet then
		local x,y,z = spGetUnitPosition(unitID)
		Spring.SetUnitMoveGoal(unitID, x, y, z, 8, nil, false)
		data.moveGoalSet = false
	end
end

--------------------------
---- Unit AI
--------------------------
local function getUnitOrderState(unitID,data,cQueue)
	-- ret 1: enemy ID, value of -1 means not target and one should be found. Return false means the unit does not want orders from tactical ai.
	-- ret 2: true if there is a move command at the start of queue which will need removal.
	-- ret 3: true if the unit is using AI due to a fight or patrol command.
	
	if not cQueue or #cQueue == 0 then
		local movestate = spGetUnitStates(unitID).movestate
		if movestate ~= 0 then
			return -1, false -- could still skirm from static or flee
		end
		return false -- no queue and on hold postition.
	end
	
	local movestate = spGetUnitStates(unitID).movestate
	if (#cQueue == 1 and movestate == 0 and cQueue[1].id == CMD_ATTACK and cQueue[1].options.internal) then
		return false -- set to hold position and is auto-aquiring target
	end
	
	local fightTwo = (#cQueue > 1 and cQueue[2].id == CMD_FIGHT)
	if cQueue[1].id == CMD_FIGHT then
		return -1, false, true
	elseif cQueue[1].id == CMD_ATTACK and (movestate ~= 0 or fightTwo) then -- if I attack 
		local target,check = cQueue[1].params[1],cQueue[1].params[2]
		if (not check) and spValidUnitID(target) then -- if I target a unit
			if not (cQueue[1].id == CMD_FIGHT or fightTwo) then -- only skirm single target when given the order manually
				return target, false
			else
				return -1, false, true
			end
		elseif (cQueue[1].id == 16) then --  if I target the ground and have fight or patrol command
			return -1, false, true
		end
	end

	return false
end


local function swarmEnemy(unitID, behaviour, enemy, enemyUnitDef, typeKnown, move, cQueue,n)

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
                    
					ClampedRawMove(unitID, cx,cy,cz, data)
					return true
				else -- if I can shoot at the enemy

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
							data.jinkDir = data.jinkDir*-1					-- jink away
							cx = ux-(-(ux-ex)*behaviour.jinkParallelLength-(uz-ez)*data.jinkDir*behaviour.jinkTangentLength)/pointDis
							cy = uy
							cz = uz-(-(uz-ez)*behaviour.jinkParallelLength+(ux-ex)*data.jinkDir*behaviour.jinkTangentLength)/pointDis
						end
					end
					
					ClampedRawMove(unitID, cx,cy,cz, data)
				end
				return true
			end
		end
		
	else
	
		if ((#cQueue > 0 and cQueue[1].id == CMD_FIGHT) or move) and cQueue[1].params[3] then
			local ex,ey,ez -- enemy position
			if move and #cQueue > 1 and cQueue[2].params[3] then
				ex,ey,ez = cQueue[2].params[1],cQueue[2].params[2],cQueue[2].params[3]
			else
				ex,ey,ez = cQueue[1].params[1],cQueue[1].params[2],cQueue[1].params[3] 
			end
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
            
			ClampedRawMove(unitID, cx,cy,cz, data)
			return true
		end
	end
	
	return false
	
end


local function skirmEnemy(unitID, behaviour, enemy, enemyUnitDef, move, n, doHug)

	local data = unit[unitID]
	
	--local pointDis = spGetUnitSeparation (enemy,unitID,true)
	
	local vx,vy,vz = spGetUnitVelocity(enemy)
	local ex,ey,ez,_,aimY = spGetUnitPosition(enemy, false, true) -- enemy position
	local ux,uy,uz = spGetUnitPosition(unitID) -- my position
	local cx,cy,cz -- command position	

	if not (ex and vx) then
		return behaviour.skirmKeepOrder
	end	
	
	-- Use aim position as enemy position
	ey = aimY or ey
	
	-- The e vector is relative to unit position
	ex, ey, ez = ex - ux, ey - uy, ez - uz
	
	-- The d vector is also relative to unit position.
	local dx,dy,dz = ex + vx*behaviour.velocityPrediction, ey + vy*behaviour.velocityPrediction, ez + vz*behaviour.velocityPrediction
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
	local skirmRange = (doHug and behaviour.hugRange) or (GetEffectiveWeaponRange(data.udID, -dy, behaviour.weaponNum) - behaviour.skirmLeeway)

	if doHug or skirmRange > predictedDist then
	
		if behaviour.skirmOnlyNearEnemyRange then
			local enemyRange = GetEffectiveWeaponRange(enemyUnitDef, dy, behaviour.weaponNum) + behaviour.skirmOnlyNearEnemyRange
			if enemyRange < predictedDist then
				return behaviour.skirmKeepOrder
			end
		end
		
		local wantedDis = min(behaviour.skirmOrderDis, skirmRange - behaviour.stoppingDistance - predictedDist)
		local cx = ux - wantedDis*ex/eDist
		local cy = uy
		local cz = uz - wantedDis*ez/eDist
		
		if move then
			spGiveOrderToUnit(unitID, CMD_REMOVE, {cQueue[1].tag}, {} )
			GiveClampedOrderToUnit(unitID, CMD_INSERT, {0, CMD_RAW_MOVE, CMD_OPT_INTERNAL, cx,cy,cz }, {"alt"} )
		else
			GiveClampedOrderToUnit(unitID, CMD_INSERT, {0, CMD_RAW_MOVE, CMD_OPT_INTERNAL, cx,cy,cz }, {"alt"} )
		end
		
		ClampedRawMove(unitID, cx,cy,cz, data)
		return true
	elseif not behaviour.skirmKeepOrder then
		ClearMoveGoal(unitID, data)
	end

	return behaviour.skirmKeepOrder
end

local function fleeEnemy(unitID, behaviour, enemy, enemyUnitDef, typeKnown, move, cQueue,n)

	local data = unit[unitID]

	if (not enemy) or (#cQueue > 0 and cQueue[1].id == CMD_ATTACK and not cQueue[1].options.internal) or -- if I have been given attack order manually do not flee
	not ((typeKnown and (behaviour.flees[enemyUnitDef] or (behaviour.fleeCombat and not UnitDefs[enemyUnitDef].modCategories["unarmed"]))) 
	-- if I have los and the unit is a fleeable or a unit is unarmed and I flee combat - flee
	or (not typeKnown and behaviour.fleeRadar)) then -- if I do not have los and flee radar dot, flee
		return false
	end

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
	local cx,cy,cz -- command position	
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

		ClampedRawMove(unitID, cx,cy,cz, data)
		return true
	else
		ClearMoveGoal(unitID, data)
	end

	return false
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
				if data.moveGoalSet then
					ClearMoveGoal(unitID, data)
				end
				break
			end
			local cQueue = spGetCommandQueue(unitID,2)
			local enemy, move, haveFight = getUnitOrderState(unitID,data,cQueue) -- returns target enemy and movement state
			--local ux,uy,uz = spGetUnitPosition(unitID)
			--Spring.MarkerAddPoint(ux,uy,uz,"unit active")
			if (enemy) then -- if I am fighting/patroling ground or targeting an enemy
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
				
				local alwaysJink = (((#cQueue > 0 and cQueue[1].id == CMD_FIGHT) or move) and behaviour.alwaysJinkFight)
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

					if enemy and not select(2,spGetUnitIsStunned(enemy)) then
						local states = spGetUnitLosState(enemy,data.allyTeam,false)
						if states then
							typeKnown = states.typed
						end
						enemyUnitDef = spGetUnitDefID(enemy)
					end
				end
				
				if not (typeKnown and (not haveFight) and behaviour.fightOnlyUnits and behaviour.fightOnlyUnits[enemyUnitDef]) then
					local checkSkirm = true

					if alwaysJink or (enemy and typeKnown and behaviour.swarms[enemyUnitDef]) then
						--Spring.Echo("unit checking swarm")
						if swarmEnemy(unitID, behaviour, enemy, enemyUnitDef, typeKnown, move, cQueue, frame) then
							checkSkirm = false
						else
							ClearMoveGoal(unitID, data)
						end
					end
					if checkSkirm then
						local typeSkirm = typeKnown and (behaviour.skirms[enemyUnitDef] or (behaviour.hugs and behaviour.hugs[enemyUnitDef]))
						if enemy and (typeSkirm or ((not typeKnown) and behaviour.skirmRadar) or behaviour.skirmEverything) then
							--Spring.Echo("unit checking skirm")
							if not skirmEnemy(unitID, behaviour, enemy, enemyUnitDef, move, cQueue, frame, (behaviour.hugs and behaviour.hugs[enemyUnitDef])) then
								clearOrder(unitID,data,cQueue)
							end
						else
							--Spring.Echo("unit checking flee")
							if not fleeEnemy(unitID, behaviour, enemy, enemyUnitDef, typeKnown, move, cQueue, frame) then
								ClearMoveGoal(unitID, data)
							end
						end
					end
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
	if unit[unitID] then
		local state = cmdParams[1]
		local cmdDescID = spFindUnitCmdDesc(unitID, CMD_UNIT_AI)
		
		if (cmdDescID) then
			unitAICmdDesc.params[1] = state
			spEditUnitCmdDesc(unitID, cmdDescID, { params = unitAICmdDesc.params})
			unit[unitID].active = (state == 1)
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
	
	local behaviourTable = {
		skirms = behaviourData.skirms, 
		swarms = behaviourData.swarms, 
		flees  = behaviourData.flees,
		hugs   = behaviourData.hugs,
		fightOnlyUnits = behaviourData.fightOnlyUnits,
		weaponNum = (behaviourData.weaponNum or 1), 
		circleStrafe = (behaviourData.circleStrafe or false), 
		skirmRadar = (behaviourData.skirmRadar or false), 
		skirmEverything = (behaviourData.skirmEverything or false), 
		maxSwarmRange = weaponRange - (behaviourData.maxSwarmLeeway or 0), 
		minSwarmRange = weaponRange - (behaviourData.minSwarmLeeway or weaponRange/2),
		minCircleStrafeDistance = weaponRange - (behaviourData.minCircleStrafeDistance or behaviourDefaults.defaultMinCircleStrafeDistance),
		skirmRange = weaponRange,
		skirmLeeway = (behaviourData.skirmLeeway or 0),
		skirmOnlyNearEnemyRange = (behaviourData.skirmOnlyNearEnemyRange or false),
		skirmKeepOrder = (behaviourData.skirmKeepOrder or false),
		jinkTangentLength = (behaviourData.jinkTangentLength or behaviourDefaults.defaultJinkTangentLength),
		jinkParallelLength =  (behaviourData.jinkParallelLength or behaviourDefaults.defaultJinkParallelLength),
		alwaysJinkFight = (behaviourData.alwaysJinkFight or false),
		localJinkOrder = (behaviourData.alwaysJinkFight or behaviourDefaults.defaultLocalJinkOrder),
		stoppingDistance = (behaviourData.stoppingDistance or 0),
		strafeOrderLength = (behaviourData.strafeOrderLength or behaviourDefaults.defaultStrafeOrderLength),
		fleeCombat = (behaviourData.fleeCombat or false), 
		fleeLeeway = (behaviourData.fleeLeeway or 100), 
		fleeDistance = (behaviourData.fleeDistance or 100), 
		fleeRadar = (behaviourData.fleeRadar or false), 
		minFleeRange = (behaviourData.minFleeRange or 0), 
		swarmLeeway = (behaviourData.swarmLeeway or 50), 
		skirmOrderDis = (behaviourData.skirmOrderDis or behaviourDefaults.defaultSkirmOrderDis),
		velocityPrediction = (behaviourData.velocityPrediction or behaviourDefaults.defaultVelocityPrediction),
		selfVelocityPrediction = behaviourData.selfVelocityPrediction,
		searchRange = (behaviourData.searchRange or 800),
		fleeOrderDis = (behaviourData.fleeOrderDis or 120),
		hugRange = (behaviourData.hugRange or behaviourDefaults.defaultHugRange),
	}
	
	behaviourTable.minFleeRange = behaviourTable.minFleeRange - behaviourTable.fleeLeeway
	
	return behaviourTable
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
		--Spring.Echo("unit added")
		if not unit[unitID] then
			unitList.count = unitList.count + 1
			unitList.data[unitList.count] = unitID
		end
		
		unit[unitID] = {
			udID = unitDefID,
			jinkDir = random(0,1)*2-1, 
			rot = random(0,1)*2-1,
			active = false,
			moveGoalSet = false,
			allyTeam = spGetUnitAllyTeam(unitID),
		}
		
		if (behaviour.defaultAIState == 1) then
			AIToggleCommand(unitID, {1}, {})
		else
			AIToggleCommand(unitID, {0}, {})
		end
		--Spring.Echo("")
		
	end
	
end
