
function gadget:GetInfo()
  return {
	name 	= "Tactical Unit AI",
	desc	= "Implements tactial AI for some units",
	author	= "Google Frog",
	date	= "April 20 2010",
	license	= "GNU GPL, v2 or later",
	layer	= 0,
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

--------------------------------------------------------------------------------
-- Globals

local unit = {}
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
---- Unit AI
--------------------------

local function distance(x1,y1,x2,y2)
	return sqrt((x1-x2)^2 + (y1-y2)^2)
end

local function getUnitState(unitID,data,cQueue)
	-- ret 1: enemy ID, value of -1 means not target and one should be found. Return false means the unit does not want orders from tactical ai.
	-- ret 2: true if there is a move command at the start of queue which will need removal.
	
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
	if cQueue[1].id == CMD_ATTACK and (movestate ~= 0 or fightTwo) then -- if I attack 
		local target,check = cQueue[1].params[1],cQueue[1].params[2]
		if (not check) and spValidUnitID(target) then -- if I target a unit
			local los = spGetUnitLosState(target,data.allyTeam,false)
			if los then
				los = los.los
			end
			if not (cQueue[1].id == CMD_FIGHT or fightTwo) then -- only skirm single target when given the order manually
				return target,false
			else
				return -1,false
			end
		elseif (cQueue[1].id == 16) then --  if I target the ground and have fight or patrol command
			return -1,false
		end
	  
    elseif (cQueue[1].id == CMD_MOVE) and #cQueue > 1 then -- if I am moving
	
		local cx,cy,cz = cQueue[1].params[1],cQueue[1].params[2],cQueue[1].params[3]
		if (cx == data.cx) and (cy == data.cy) and (cz == data.cz) then -- if I was given this move command by this gadget
			local fightThree = (#cQueue > 2 and cQueue[3].id == CMD_FIGHT)
			if cQueue[2].id == CMD_ATTACK and (movestate ~= 0 or fightThree) then -- if the next command is attack, patrol or fight
				local target,check = cQueue[2].params[1],cQueue[2].params[2]
				if not check then -- if I target a unit
					local los = spGetUnitLosState(target,data.allyTeam,false)
					if los then 
						los = los.los
					end
					if not (cQueue[2].id == CMD_FIGHT or fightThree) then -- only skirm single target when given the order manually
						return target,true
					else
						return -1,true
					end
				elseif (cQueue[2].id == 16) then -- if I target the ground and have fight or patrol command
					return -1,true
				end
			end
		end

	end

	return false
end

local function clearOrder(unitID,data,cQueue)
	-- removes move order
	if receivedOrder then

		if (#cQueue >= 1 and cQueue[1].id == CMD_MOVE) then -- if I am moving
			local cx,cy,cz = cQueue[1].params[1],cQueue[1].params[2],cQueue[1].params[3]
			if (cx == data.cx) and (cy == data.cy) and (cz == data.cz) then -- if I was given this move command by this gadget
				spGiveOrderToUnit(unitID, CMD_REMOVE, {cQueue[1].tag}, {} )
			end
		end
		receivedOrder = false
	end
end

local function swarmEnemy(unitID, enemy, enemyUnitDef, los, move, cQueue,n)

	local data = unit[unitID]
	local behaviour = unitAIBehaviour[data.udID]
	
	if enemy and los then
	
		local pointDis = spGetUnitSeparation (enemy,unitID,true)
		
		if pointDis then

			if behaviour.maxSwarmRange < pointDis then -- if I cannot shoot at the enemy
				
				local enemyRange = behaviour.swarmEnemyDefaultRange
				if enemyUnitDef and los then
					enemyRange = UnitDefs[enemyUnitDef].maxWeaponRange
				end
				
				if pointDis < enemyRange+behaviour.swarmLeeway then -- if I am within enemy range

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
                    
					if move then
						spGiveOrderToUnit(unitID, CMD_REMOVE, {cQueue[1].tag}, {} )
						spGiveOrderToUnit(unitID, CMD_INSERT, {0, CMD_MOVE, CMD_OPT_INTERNAL, cx,cy,cz }, {"alt"} )
					else
						spGiveOrderToUnit(unitID, CMD_INSERT, {0, CMD_MOVE, CMD_OPT_INTERNAL, cx,cy,cz }, {"alt"} )
					end
					data.cx,data.cy,data.cz = cx,cy,cz
					
					data.receivedOrder = true
					return true
				end
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
				
				if move then
					spGiveOrderToUnit(unitID, CMD_REMOVE, {cQueue[1].tag}, {} )
					spGiveOrderToUnit(unitID, CMD_INSERT, {0, CMD_MOVE, CMD_OPT_INTERNAL, cx,cy,cz }, {"alt"} )
				else
					spGiveOrderToUnit(unitID, CMD_INSERT, {0, CMD_MOVE, CMD_OPT_INTERNAL, cx,cy,cz }, {"alt"} )
				end
				data.cx,data.cy,data.cz = cx,cy,cz
				data.receivedOrder = true
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
            
			if move then
				spGiveOrderToUnit(unitID, CMD_REMOVE, {cQueue[1].tag}, {} )
				spGiveOrderToUnit(unitID, CMD_INSERT, {0, CMD_MOVE, CMD_OPT_INTERNAL, cx,cy,cz }, {"alt"} )
			else
				spGiveOrderToUnit(unitID, CMD_INSERT, {0, CMD_MOVE, CMD_OPT_INTERNAL, cx,cy,cz }, {"alt"} )
			end
			data.cx,data.cy,data.cz = cx,cy,cz
				
			data.receivedOrder = true
			return true
		end
	end
	
	return false
	
end


local function skirmEnemy(unitID, enemy, move, cQueue,n)

	local data = unit[unitID]
	local behaviour = unitAIBehaviour[data.udID]
	
	--local pointDis = spGetUnitSeparation (enemy,unitID,true)
	
	local vx,vy,vz = spGetUnitVelocity(enemy)
	local ex,ey,ez = spGetUnitPosition(enemy) -- enemy position
	local ux,uy,uz = spGetUnitPosition(unitID) -- my position
	local cx,cy,cz -- command position	
	
	if not (ex and vx) then
		return false
	end
	
	local dx,dy,dz = ex+vx*behaviour.velocityPrediction,ey+vy*behaviour.velocityPrediction,ez+vz*behaviour.velocityPrediction
	
	local pointDis = sqrt((dx-ux)^2 + (dy-uy)^2 + (dz-uz)^2)
	
	if behaviour.skirmRange > pointDis then

		local dis = behaviour.skirmOrderDis 
		local f = dis/pointDis
		if (pointDis+dis > behaviour.skirmRange-behaviour.stoppingDistance) then
			f = (behaviour.skirmRange-behaviour.stoppingDistance-pointDis)/pointDis
		end
		local cx = ux+(ux-ex)*f
		local cy = uy
		local cz = uz+(uz-ez)*f
		
		if move then
			spGiveOrderToUnit(unitID, CMD_REMOVE, {cQueue[1].tag}, {} )
			spGiveOrderToUnit(unitID, CMD_INSERT, {0, CMD_MOVE, CMD_OPT_INTERNAL, cx,cy,cz }, {"alt"} )
		else
			spGiveOrderToUnit(unitID, CMD_INSERT, {0, CMD_MOVE, CMD_OPT_INTERNAL, cx,cy,cz }, {"alt"} )
		end
		
		data.cx,data.cy,data.cz = cx,cy,cz
		data.receivedOrder = true
		return true
	elseif #cQueue > 0 and move then
		spGiveOrderToUnit(unitID, CMD_REMOVE, {cQueue[1].tag}, {} )
	end

	return false
end

local function fleeEnemy(unitID, enemy, enemyUnitDef, los, move, cQueue,n)

	local data = unit[unitID]
	local behaviour = unitAIBehaviour[data.udID]

	if (not enemy) or (#cQueue > 0 and cQueue[1].id == CMD_ATTACK and not cQueue[1].options.internal) or -- if I have been given attack order manually do not flee
	not ( (los and (behaviour.flees[enemyUnitDef] or (behaviour.fleeCombat and not UnitDefs[enemyUnitDef].modCategories["unarmed"]))) 
	-- if I have los and the unit is a fleeable or a unit is unarmed and I flee combat - flee
	or (not los and behaviour.fleeRadar)) then -- if I do not have los and flee radar dot, flee
		return false
	end

	local enemyRange = behaviour.minFleeRange
	
	if enemyUnitDef and los then
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
	local dx,dy,dz = ex+vx*behaviour.velocityPrediction,ey+vy*behaviour.velocityPrediction,ez+vz*behaviour.velocityPrediction
	
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

		if #cQueue > 0 then
			if move then
				spGiveOrderToUnit(unitID, CMD_REMOVE, {cQueue[1].tag}, {} )
				spGiveOrderToUnit(unitID, CMD_INSERT, {0, CMD_MOVE, CMD_OPT_INTERNAL, cx,cy,cz }, {"alt"} )
			else
				spGiveOrderToUnit(unitID, CMD_INSERT, {0, CMD_MOVE, CMD_OPT_INTERNAL, cx,cy,cz }, {"alt"} )
			end
		else
			spGiveOrderToUnit(unitID, CMD_FIGHT, {cx,cy,cz }, CMD_OPT_RIGHT )
		end
		
		data.cx,data.cy,data.cz = cx,cy,cz
		data.receivedOrder = true
		return true
	elseif #cQueue > 0 and move then
		spGiveOrderToUnit(unitID, CMD_REMOVE, {cQueue[1].tag}, {} )
	end

	return false
end

local function updateUnits(n)
	for unitID, data in pairs(unit) do
		
		while true do
			
			if not spValidUnitID(unitID) then
				unit[unitID] = nil
				break
			end
		
			--Spring.Echo("unit parsed")
			if (not data.active) or spGetUnitRulesParam(unitID,"disable_tac_ai") == 1 then
				if data.receivedOrder then
					local cQueue = spGetCommandQueue(unitID)
					clearOrder(unitID,data,cQueue)
				end
				break
			end
			local cQueue = spGetCommandQueue(unitID)
			local enemy,move = getUnitState(unitID,data,cQueue) -- returns target enemy and movement state
			--local ux,uy,uz = spGetUnitPosition(unitID)
			--Spring.MarkerAddPoint(ux,uy,uz,"unit active")
			if (enemy) then -- if I am fighting/patroling ground or targeting an enemy
				--Spring.Echo("enemy spotted 1")
				if enemy == -1 then -- if I am fighting/patroling ground get nearest enemy
					enemy = (spGetUnitNearestEnemy(unitID,unitAIBehaviour[data.udID].searchRange,true) or false)
				end
				--GG.UnitEcho(enemy)
				--Spring.Echo("enemy spotted 2")
				-- don't get info on out of los units
				--Spring.Echo("enemy in los")
				-- use AI on target
				local enemyUnitDef = false
				local los = false
				if enemy and not select(2,spGetUnitIsStunned(enemy)) then
					los = spGetUnitLosState(enemy,data.allyTeam,false)
					if los then
						los = los.los
					end
					enemyUnitDef = spGetUnitDefID(enemy)
				end
				
				if (enemy and los and unitAIBehaviour[data.udID].swarms[enemyUnitDef]) or (((#cQueue > 0 and cQueue[1].id == CMD_FIGHT) or move) and unitAIBehaviour[data.udID].alwaysJinkFight ) then
					--Spring.Echo("unit checking swarm")
					if not swarmEnemy(unitID, enemy, enemyUnitDef, los, move, cQueue,n) then
						clearOrder(unitID,data,cQueue)
					end
				elseif enemy and ((los and unitAIBehaviour[data.udID].skirms[enemyUnitDef]) or ((not los) and unitAIBehaviour[data.udID].skirmRadar) or unitAIBehaviour[data.udID].skirmEverything) then
					--Spring.Echo("unit checking skirm")
					if not skirmEnemy(unitID, enemy, move, cQueue,n) then
						clearOrder(unitID,data,cQueue)
					end
				else
					--Spring.Echo("unit checking flee")
					if not fleeEnemy(unitID, enemy, enemyUnitDef, los,move, cQueue,n) then
						clearOrder(unitID,data,cQueue)
					end
				end
				
			end
			break
		end
		
		--Spring.Echo("")
	end
	
end

function gadget:GameFrame(n)
 
	-- update orders
	if (n%20<1) then 
		updateUnits(n)
	end
  
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
		end
		unit[unitID].active = (state == 1)
	end
	
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

local function LoadBehaviour(unitConfigArray, behaviourDefaults)

	for unitDef, behaviourData in pairs(unitConfigArray) do
		local ud = UnitDefNames[unitDef]
		
		if ud then
			unitAIBehaviour[ud.id] = {
				skirms = {}, 
				swarms = {}, 
				flees  = {},
				circleStrafe = (behaviourData.circleStrafe or false), 
				skirmRadar = (behaviourData.skirmRadar or false), 
				skirmEverything = (behaviourData.skirmEverything or false), 
				maxSwarmRange = ud.maxWeaponRange - (behaviourData.maxSwarmLeeway or 0), 
				minSwarmRange = ud.maxWeaponRange - (behaviourData.minSwarmLeeway or ud.maxWeaponRange/2),
				minCircleStrafeDistance = ud.maxWeaponRange - (behaviourData.minCircleStrafeDistance or behaviourDefaults.defaultMinCircleStrafeDistance),
				skirmRange = ud.maxWeaponRange - (behaviourData.skirmLeeway or 0),
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
				searchRange = (behaviourData.searchRange or 800),
				defaultAIState = (behaviourData.defaultAIState or behaviourDefaults.defaultState),
				fleeOrderDis = (behaviourData.fleeOrderDis or 120),
			}
			
			unitAIBehaviour[ud.id].minFleeRange = unitAIBehaviour[ud.id].minFleeRange - unitAIBehaviour[ud.id].fleeLeeway

			if behaviourData.skirms then
				for skirmDef,_  in pairs(behaviourData.skirms) do
					local skirmName = UnitDefNames[skirmDef]
					if skirmName then
						unitAIBehaviour[ud.id].skirms[skirmName.id] = true
					end
				end
			end
			
			if behaviourData.swarms then
				for swarmDef,_  in pairs(behaviourData.swarms) do
					local swarmName = UnitDefNames[swarmDef]
					if swarmName then
						unitAIBehaviour[ud.id].swarms[swarmName.id] = true
					end
				end
			end
			
			if behaviourData.flees then
				for fleeDef,_  in pairs(behaviourData.flees) do
					local fleeName = UnitDefNames[fleeDef]
					if fleeName then
						unitAIBehaviour[ud.id].flees[fleeName.id] = true
					end
				end
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
		--Spring.Echo("")
		
	end
	
end

function gadget:UnitDestroyed(unitID, unitDefID, unitTeam)
	if (unit[unitID]) then
		unit[unitID] = nil
	end
end
