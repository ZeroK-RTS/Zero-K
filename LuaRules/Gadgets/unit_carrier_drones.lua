if (not gadgetHandler:IsSyncedCode()) then return end
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
function gadget:GetInfo()
	return {
		name      = "Carrier Drones",
		desc      = "Spawns drones for aircraft carriers",
		author    = "TheFatConroller, modified by KingRaptor",
		date      = "12.01.2008",
		license   = "GNU GPL, v2 or later",
		layer     = 0,
		enabled   = true
	}
end
--Version 1.001
--Changelog:
--24/6/2014 added carrier building drone on emit point. 
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
local AddUnitDamage     = Spring.AddUnitDamage
local CreateUnit        = Spring.CreateUnit
local GetCommandQueue   = Spring.GetCommandQueue
local GetUnitIsStunned  = Spring.GetUnitIsStunned
local GetUnitPieceMap	= Spring.GetUnitPieceMap
local GetUnitPiecePosDir= Spring.GetUnitPiecePosDir
local GetUnitPosition   = Spring.GetUnitPosition
local GiveOrderToUnit   = Spring.GiveOrderToUnit
local SetUnitPosition   = Spring.SetUnitPosition
local SetUnitNoSelect   = Spring.SetUnitNoSelect
local TransferUnit      = Spring.TransferUnit
local spGetUnitRulesParam = Spring.GetUnitRulesParam
local random            = math.random
local CMD_ATTACK		= CMD.ATTACK

local emptyTable = {}

-- thingsWhichAreDrones is an optimisation for AllowCommand
local carrierDefs, thingsWhichAreDrones = include "LuaRules/Configs/drone_defs.lua"

local DEFAULT_UPDATE_ORDER_FREQUENCY = 40 -- gameframes
local DEFAULT_MAX_DRONE_RANGE = 1500

local BUILD_UPDATE_INTERVAL = 15 --gameframe

local carrierList = {}
local droneList = {}
local drones_to_move = {}
local killList = {}

local GiveClampedOrderToUnit = Spring.Utilities.GiveClampedOrderToUnit

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
local function InitCarrier(unitID, unitDefID, teamID)
	local carrierData = carrierDefs[unitDefID]
	local toReturn  = {unitDefID = unitDefID, teamID = teamID, droneSets = {}, occupiedPieces={}, droneInQueue= {}}
	local unitPieces = GetUnitPieceMap(unitID)
	local usedPieces = carrierData.spawnPieces
	if usedPieces then
		toReturn.spawnPieces = {}
		for i=1,#usedPieces do
			toReturn.spawnPieces[i] = unitPieces[usedPieces[i]]
		end
		toReturn.pieceIndex = 1
	end
	for i=1,#carrierData do
		-- toReturn.droneSets[i] = Spring.Utilities.CopyTable(carrierData[i])
		toReturn.droneSets[i] = {nil}
		toReturn.droneSets[i].config = carrierData[i] --same as above, but we assign reference to "carrierData[i]" in memory to avoid duplicates, also, we have no plan to change config value.
		toReturn.droneSets[i].reload = carrierData[i].reloadTime
		toReturn.droneSets[i].droneCount = 0
		toReturn.droneSets[i].drones = {}
		toReturn.droneSets[i].buildCount = 0
	end
	return toReturn
end

local function NewDrone(unitID, unitDefID, droneName, setNum, droneBuiltExternally)
	local carrierEntry = carrierList[unitID]
	local _, _, _, x, y, z = GetUnitPosition(unitID, true)
	local xS, yS, zS = x, y, z
	local rot = 0
	if carrierEntry.spawnPieces and not droneBuiltExternally then
		local index = carrierEntry.pieceIndex
		local px, py, pz, pdx, pdy, pdz = GetUnitPiecePosDir(unitID, carrierEntry.spawnPieces[index])
		xS, yS, zS = px, py, pz
		rot = Spring.GetHeadingFromVector(pdx, pdz)/65536*2*math.pi + math.pi
		
		index = index + 1
		if index > #carrierEntry.spawnPieces then
			index = 1
		end
		carrierEntry.pieceIndex = index
	else
		local angle = math.rad(random(1,360))
		xS = (x + (math.sin(angle) * 20))
		zS = (z + (math.cos(angle) * 20))
		rot = angle
	end
	--Note: create unit argument: (unitDefID|unitDefName,x,y,z,facing,teamID,build,flattenGround,targetID,builderID)
	local droneID = CreateUnit(droneName,xS,yS,zS,1,carrierList[unitID].teamID, droneBuiltExternally and true,false,nil,unitID)
	if droneID then
		local droneSet = carrierEntry.droneSets[setNum]
		droneSet.reload = droneSet.config.reloadTime
		droneSet.droneCount = droneSet.droneCount + 1
		droneSet.drones[droneID] = true
		
		--SetUnitPosition(droneID, xS, zS, true)
		Spring.MoveCtrl.Enable(droneID)
		Spring.MoveCtrl.SetPosition(droneID, xS, yS, zS)
		--Spring.MoveCtrl.SetRotation(droneID, 0, rot, 0)
		Spring.MoveCtrl.Disable(droneID)
		Spring.SetUnitCOBValue(droneID,82,(rot - math.pi)*65536/2/math.pi)
		
		GiveOrderToUnit(droneID, CMD.MOVE_STATE, { 2 }, 0)
		GiveOrderToUnit(droneID, CMD.IDLEMODE, { 0 }, 0)
		GiveClampedOrderToUnit(droneID, CMD.FIGHT, {x + random(-300,300), 60, z + random(-300,300)}, {""})
		GiveOrderToUnit(droneID, CMD.GUARD, {unitID} , {"shift"})

		SetUnitNoSelect(droneID,true)

		droneList[droneID] = {carrier = unitID, set = setNum}
	end
	return droneID,rot
end

--START OF----------------------------
--drone nanoframe attachment code:----

function AddUnitToEmptyPad(carrierID,droneType)
	local carrierData = carrierList[carrierID]
	local unitIDAdded
	local CheckCreateStart = function(pieceNum)
		if not carrierData.occupiedPieces[pieceNum] then -- Note: We could do a strict checking of empty space here (Spring.GetUnitInBox()) before spawning drone, but that require a loop to check if & when its empty.
			local carrierDefID = carrierData.unitDefID
			local droneDefID = carrierData.droneSets[droneType].config.drone
			unitIDAdded = NewDrone(carrierID, carrierDefID, droneDefID, droneType, true)
			if unitIDAdded then
				local offsets = carrierData.droneSets[droneType].config.offsets
				SitOnPad(unitIDAdded,carrierID,pieceNum,offsets)
				carrierData.occupiedPieces[pieceNum] = true
				if carrierData.droneSets[droneType].config.colvolTweaked then --can be used to move collision volume away from carrier to avoid collision
					Spring.SetUnitMidAndAimPos(unitIDAdded,offsets.colvolMidX,offsets.colvolMidY,offsets.colvolMidZ,offsets.aimX,offsets.aimY,offsets.aimZ,true) --offset whole colvol & aim point (red dot) above the carrier (use /debugcolvol to check)
				end
				return true
			end
		end
		return false
	end
	if carrierList[carrierID].spawnPieces then --have airpad or emit point
		for i=1, #carrierList[carrierID].spawnPieces do
			local pieceNum = carrierList[carrierID].spawnPieces[i]
			if CheckCreateStart(pieceNum) then
				break
			end
		end
	else
		CheckCreateStart(0) --use unit's body as emit point
	end
	return unitIDAdded
end

local coroutines = {}
local coroutineCount = 0
local coroutine = coroutine
local Sleep	    = coroutine.yield
local assert    = assert
local function StartScript(fn)
	local co = coroutine.create(fn)
	coroutineCount = coroutineCount + 1 --in case new co-routine is added in same frame
	coroutines[coroutineCount] = co
end

function UpdateCoroutines() 
	coroutineCount = #coroutines
	local i=1
	while (i<=coroutineCount) do
		local co = coroutines[i] 
		if (coroutine.status(co) ~= "dead") then 
			assert(coroutine.resume(co))
			i = i + 1
		else
			coroutines[i] = coroutines[coroutineCount]
			coroutines[coroutineCount] = nil
			coroutineCount = coroutineCount -1
		end
	end 
end

local function GetPitchYawRoll(front, top) --This allow compatibility with Spring 91
	--NOTE:
	--angle measurement and direction setting is based on right-hand coordinate system, but Spring might rely on left-hand coordinate system.
	--So, input for math.sin and math.cos, or positive/negative sign, or math.atan2 might be swapped with respect to the usual whenever convenient.

	--1) Processing FRONT's vector to get Pitch and Yaw
	local x,y,z = front[1], front[2],front[3]
	local xz = math.sqrt(x*x + z*z) --hypothenus
	local yaw = math.atan2 (x/xz, z/xz) --So facing south is 0-radian, and west is negative radian, and east is positive radian
	local pitch = math.atan2 (y,xz) --So facing upward is positive radian, and downward is negative radian
	
	--2) Processing TOP's vector to get Roll
	x,y,z = top[1], top[2],top[3]
	--rotate coordinate around Y-axis until Yaw value is 0 (a reset) 
	local newX = x* math.cos (-yaw) + z*  math.sin (-yaw)
	local newY = y
	local newZ = z* math.cos (-yaw) - x* math.sin (-yaw)
	x,y,z = newX,newY,newZ
	--rotate coordinate around X-axis until Pitch value is 0 (a reset) 
	newX = x 
	newY = y* math.cos (-pitch) + z* math.sin (-pitch)
	newZ = z* math.cos (-pitch) - y* math.sin (-pitch)
	x,y,z = newX,newY,newZ
	local roll =  math.atan2 (x, y) --So lifting right wing is positive radian, and lowering right wing is negative radian
	
	return pitch, yaw, roll
end

local function GetOffsetRotated(rx,ry,rz,front,top,right)
	local offX = front[1]*rz + top[1]*ry - right[1]*rx
	local offY = front[2]*rz + top[2]*ry - right[2]*rx
	local offZ = front[3]*rz + top[3]*ry - right[3]*rx
	return offX,offY,offZ
end

local HEADING_TO_RAD = (math.pi*2/2^16)
local RAD_TO_HEADING = 1/HEADING_TO_RAD
local PI = math.pi
local cos = math.cos
local sin = math.sin
local acos = math.acos
local floor = math.floor
local sqrt = math.sqrt
local exp = math.exp
local min = math.min

local mcSetVelocity			= Spring.MoveCtrl.SetVelocity
local mcSetRotationVelocity	= Spring.MoveCtrl.SetRotationVelocity
local mcSetPosition			= Spring.MoveCtrl.SetPosition
local mcSetRotation			= Spring.MoveCtrl.SetRotation
local mcDisable				= Spring.MoveCtrl.Disable
local mcEnable				= Spring.MoveCtrl.Enable
function SitOnPad(unitID,carrierID, padPieceID,offsets)
	-- From unit_refuel_pad_handler.lua (author: GoogleFrog)
	-- South is 0 radians and increases counter-clockwise
	
	Spring.SetUnitHealth(unitID,{ build = 0 })
	
	local GetPlacementPosition = function(inputID,pieceNum)
		if (pieceNum==0) then
			local _,_,_,mx,my,mz = Spring.GetUnitPosition(inputID,true)
			local dx,dy,dz = Spring.GetUnitDirection(inputID)
			return mx,my,mz,dx,dy,dz
		else
			return Spring.GetUnitPiecePosDir(inputID, pieceNum)
		end
	end
	
	local AddNextDroneFromQueue = function(inputID)
		if #carrierList[inputID].droneInQueue > 0 then
			if AddUnitToEmptyPad(inputID,carrierList[inputID].droneInQueue[1]) then --pad cleared, immediately add any unit from queue
				table.remove(carrierList[inputID].droneInQueue,1)
			end
		end
	end
	
	mcEnable(unitID)
	Spring.SetUnitLeaveTracks(unitID, false)
	mcSetVelocity(unitID, 0, 0, 0)
	mcSetPosition(unitID,GetPlacementPosition(carrierID,padPieceID))
	
	-- deactivate unit to cause the lups jets away
	Spring.SetUnitCOBValue(unitID, COB.ACTIVATION, 0)
	
	local function SitLoop()
		local previousDir,currentDir
		local pitch,yaw,roll,pitch,yaw,roll
		local px, py, pz, dx, dy, dz,vx,vy,vz, offx,offy,offz
		-- local magnitude, newPadHeading
		local landDuration = 0
		local buildProgress,health
		local droneType = droneList[unitID].set
		local droneInfo = carrierList[carrierID].droneSets[droneType]
		local build_step = droneInfo.config.buildStep
		local build_step_health = droneInfo.config.buildStepHealth
		while true do
			if (not droneList[unitID]) then --droneList[unitID] became NIL when drone or carrier is destroyed (in UnitDestroyed()). Is NIL at beginning of frame and this piece of code run at end of frame
				if carrierList[carrierID] then
					droneInfo.buildCount = droneInfo.buildCount - 1
					carrierList[carrierID].occupiedPieces[padPieceID] = false
					AddNextDroneFromQueue(carrierID) --add next drone in this vacant position
				end
				return --nothing else to do
			elseif (not carrierList[carrierID]) then --carrierList[carrierID] is NIL because it was MORPHED.
				carrierID = droneList[unitID].carrier
				carrierList[carrierID].occupiedPieces[padPieceID] = false
				padPieceID = (carrierList[carrierID].spawnPieces and carrierList[carrierID].spawnPieces[1]) or 0
				carrierList[carrierID].occupiedPieces[padPieceID] = true --block pad
			end
			
			vx,vy,vz = Spring.GetUnitVelocity(carrierID)
			px, py, pz, dx, dy, dz = GetPlacementPosition(carrierID,padPieceID)
			currentDir = dx + dy*100 + dz* 10000
			if previousDir ~= currentDir then --refresh pitch/yaw/roll calculation when unit had slight turning
				previousDir = currentDir
				front, top, right = Spring.GetUnitVectors(carrierID)
				pitch,yaw,roll = GetPitchYawRoll(front, top)
				offx,offy,offz = GetOffsetRotated(offsets[1],offsets[2],offsets[3],front,top,right)
			end
			mcSetVelocity(unitID,vx,vy,vz)
			mcSetPosition(unitID,px+vx+offx, py+vy+offy, pz+vz+offz)
			mcSetRotation(unitID,-pitch,yaw,-roll) --Spring conveniently rotate Y-axis first, X-axis 2nd, and Z-axis 3rd which allow Yaw,Pitch & Roll control.
			
			landDuration = landDuration + 1
			if landDuration % BUILD_UPDATE_INTERVAL == 0 then
				health,_,_,_,buildProgress = Spring.GetUnitHealth(unitID)
				buildProgress = buildProgress+build_step --progress
				Spring.SetUnitHealth(unitID,{health=health+build_step_health, build = buildProgress }) 
				if buildProgress >= 1 then 
					break
				end
			end
			
			Sleep()
		end
		droneInfo.buildCount = droneInfo.buildCount - 1
		carrierList[carrierID].occupiedPieces[padPieceID] = false
		Spring.SetUnitLeaveTracks(unitID, true)
		Spring.SetUnitVelocity(unitID, 0, 0, 0)
		mcDisable(unitID)
		GG.UpdateUnitAttributes(unitID) --update pending attribute changes in unit_attributes.lua if available 
		
		if droneInfo.config.colvolTweaked then
			Spring.SetUnitMidAndAimPos(unitID,0,0,0,0,0,0,true)
		end
		
		-- activate unit and its jets
		Spring.SetUnitCOBValue(unitID, COB.ACTIVATION, 1)
		
		AddNextDroneFromQueue(carrierID) --this create next drone in this position (in this same GameFrame!), so it might look overlapped but that's just minor details
	end
	
	StartScript(SitLoop)
end
--drone nanoframe attachment code------
--END----------------------------------

-- morph uses this
local function transferCarrierData(unitID, unitDefID, unitTeam, newUnitID)
	-- UnitFinished (above) should already be called for this new unit.
	if carrierList[newUnitID] then
		carrierList[newUnitID] = Spring.Utilities.CopyTable(carrierList[unitID], true) -- deep copy?
		  -- old carrier data removal (transfering drones to new carrier, old will "die" (on morph) silently without taking drones together to the grave)...
		local carrier = carrierList[unitID]
		for i=1,#carrier.droneSets do
			local set = carrier.droneSets[i]
			for droneID in pairs(set.drones) do
				droneList[droneID].carrier = newUnitID
				GiveOrderToUnit(droneID, CMD.GUARD, {newUnitID} , {"shift"})
			end
		end
		carrierList[unitID] = nil
	end
end

local function isCarrier(unitID)
	if (carrierList[unitID]) then
		return true
	end
	return false
end

-- morph uses this
GG.isCarrier = isCarrier
GG.transferCarrierData = transferCarrierData

local function GetDistance(x1, x2, y1, y2)
	return ((x1-x2)^2 + (y1-y2)^2)^0.5
end

local function UpdateCarrierTarget(carrierID)
	local cQueueC = GetCommandQueue(carrierID, 1)
	local droneSendDistance = nil
	local px,py,pz
	local target
	if cQueueC and cQueueC[1] and cQueueC[1].id == CMD_ATTACK then
		local ox,oy,oz = GetUnitPosition(carrierID)
		local params = cQueueC[1].params
		if #params == 1 then
			target = {params[1]}
			px,py,pz = GetUnitPosition(params[1])
		else
			px,py,pz = cQueueC[1].params[1], cQueueC[1].params[2], cQueueC[1].params[3]
		end
		if px then
			droneSendDistance = GetDistance(ox,px,oz,pz)
		end
		
	end
	
	local states = Spring.GetUnitStates(carrierID) or emptyTable
	local holdfire = states.firestate == 0
	
	for i=1,#carrierList[carrierID].droneSets do
		local set = carrierList[carrierID].droneSets[i]
		if droneSendDistance and droneSendDistance < set.config.range then
			local tempCONTAINER --temporarily keep table when "droneList[]" is emptied and restored.
			for droneID in pairs(set.drones) do
				tempCONTAINER = droneList[droneID]
				droneList[droneID] = nil -- to keep AllowCommand from blocking the order
				if target then
					GiveOrderToUnit(droneID, CMD.ATTACK, target, 0)
				else
					GiveClampedOrderToUnit(droneID, CMD.FIGHT, {(px + (random(0,300) - 150)), (py+120), (pz + (random(0,300) - 150))} , 0)
				end
				--GiveOrderToUnit(droneID, CMD.GUARD, {carrierID} , {"shift"})
				droneList[droneID] = tempCONTAINER --restore original table
			end
		else
			for droneID in pairs(set.drones) do
				local cQueue = GetCommandQueue(droneID, -1)
				local engaged = false
				for i=1, (cQueue and #cQueue or 0) do
					if cQueue[i].id == CMD.FIGHT then
						engaged = true
						break
					end
				end
				if not engaged then
					px,py,pz = GetUnitPosition(carrierID)
					
					local temp = droneList[droneID]
					droneList[droneID] = nil	-- to keep AllowCommand from blocking the order
					GiveClampedOrderToUnit(droneID, holdfire and CMD.MOVE or CMD.FIGHT, {px + random(-100,100), (py+120), pz + random(-100,100)} , 0)
					GiveOrderToUnit(droneID, CMD.GUARD, {carrierID} , {"shift"})
					droneList[droneID] = temp
				end
			end
		end	
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function gadget:AllowCommand_GetWantedCommand()
	return true
end

function gadget:AllowCommand_GetWantedUnitDefID()
	return thingsWhichAreDrones
end

function gadget:AllowCommand(unitID, unitDefID, teamID, cmdID, cmdParams, cmdOptions)
	if (droneList[unitID] ~= nil) then
		return false
	else
		return true
	end
end

function gadget:UnitDestroyed(unitID, unitDefID, unitTeam)
	if (carrierList[unitID]) then
		local carrier = carrierList[unitID]
		for i=1,#carrier.droneSets do
			local set = carrier.droneSets[i]
			for droneID in pairs(set.drones) do
				droneList[droneID] = nil
				killList[droneID] = true
			end
		end
		carrierList[unitID] = nil
	elseif (droneList[unitID]) then
		local carrierID = droneList[unitID].carrier
		local setID = droneList[unitID].set
		local droneSet = carrierList[carrierID].droneSets[setID]
		droneSet.droneCount = (droneSet.droneCount - 1)
		droneSet.drones[unitID] = nil
		droneList[unitID] = nil
	end
end

function gadget:UnitFinished(unitID, unitDefID, unitTeam)
	if (carrierDefs[unitDefID]) and not carrierList[unitID] then
		carrierList[unitID] = InitCarrier(unitID, unitDefID, unitTeam)
	end
end

function gadget:UnitGiven(unitID, unitDefID, newTeam)
	if carrierList[unitID] then
		carrierList[unitID].teamID = newTeam
		for i=1,#carrierList[unitID].droneSets do
			local set = carrierList[unitID].droneSets[i]
			for droneID, _ in pairs(set.drones) do
				drones_to_move[droneID] = newTeam
			end
		end
	end
end

function gadget:GameFrame(n)
	if (((n+1) % 30) == 0) then
		for carrierID, carrier in pairs(carrierList) do
			if (not GetUnitIsStunned(carrierID)) then
				for i=1,#carrier.droneSets do
					local set = carrier.droneSets[i]
					if (set.reload > 0) then
						local reloadMult = spGetUnitRulesParam(carrierID, "totalReloadSpeedChange") or 1
						set.reload = (set.reload - reloadMult)
						
					elseif (set.droneCount < set.config.maxDrones) and set.buildCount==0 then --not reach max count and finished previous queue
						for n=1,set.config.spawnSize do
							if (set.droneCount >= set.config.maxDrones) then
								break
							end
							-- Method1: Spawn instantly,
							-- NewDrone(carrierID, carrier.unitDefID, set.config.drone, i )
							
							-- Method2: Build nanoframe,
							set.buildCount = n
							carrierList[carrierID].droneInQueue[ #carrierList[carrierID].droneInQueue+ 1 ] = i
							if AddUnitToEmptyPad(carrierID, i ) then
								table.remove(carrierList[carrierID].droneInQueue,1)
							end
						end
					end
				end
			end
		end
		for droneID, team in pairs(drones_to_move) do
			TransferUnit(droneID, team, false)
			drones_to_move[droneID] = nil
		end
		for unitID in pairs(killList) do
			Spring.DestroyUnit(unitID, true)
			killList[unitID] = nil
		end
	end
	if ((n % DEFAULT_UPDATE_ORDER_FREQUENCY) == 0) then
		for i,_ in pairs(carrierList) do
			UpdateCarrierTarget(i)
		end
	end
	UpdateCoroutines() --maintain nanoframe position relative to carrier
end

function gadget:Initialize()
	--pre-calculate some buildtime related variable (this will be copied to carrierList[] table when carrier is initialized)
	local buildUpProgress
	for name,carrierData in pairs(carrierDefs) do
		for i=1,#carrierData do
			buildUpProgress = 1/(carrierData[i].buildTime)*(BUILD_UPDATE_INTERVAL/30) -- derived from: time_to_complete = (1.0/build_step_fraction)*build_interval
			carrierDefs[name][i].buildStep = buildUpProgress
			carrierDefs[name][i].buildStepHealth = buildUpProgress*UnitDefs[carrierData[i].drone].health
			carrierDefs[name][i].colvolTweaked = carrierData[i].offsets.colvolMidX~=0 or carrierData[i].offsets.colvolMidY~=0
											or carrierData[i].offsets.colvolMidZ~=0 or carrierData[i].offsets.aimX~=0
											or carrierData[i].offsets.aimY~=0 or carrierData[i].offsets.aimZ~=0 
		end
	end

	for _, unitID in ipairs(Spring.GetAllUnits()) do
		local build  = select(5,Spring.GetUnitHealth(unitID))
		if build == 1 then
			local unitDefID = Spring.GetUnitDefID(unitID)
			local team = Spring.GetUnitTeam(unitID)
			gadget:UnitFinished(unitID, unitDefID, team)
		end
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
