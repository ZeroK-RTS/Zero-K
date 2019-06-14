--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
if not gadgetHandler:IsSyncedCode() then
	return
end
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
--Version 1.003
--Changelog:
--24/6/2014 added carrier building drone on emit point. 

--around 1/1/2017: added hold fire functionality, recall drones button, circular drone leash, drones pay attention to set target
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
include("LuaRules/Configs/customcmds.h.lua")

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
local spSetUnitRulesParam = Spring.SetUnitRulesParam
local spGetGameFrame    = Spring.GetGameFrame
local random            = math.random
local CMD_ATTACK		= CMD.ATTACK

local emptyTable = {}
local INLOS_ACCESS = {inlos = true}

-- thingsWhichAreDrones is an optimisation for AllowCommand, no longer used but it'll stay here for now
local carrierDefs, thingsWhichAreDrones, unitRulesCarrierDefs = include "LuaRules/Configs/drone_defs.lua"

local DEFAULT_UPDATE_ORDER_FREQUENCY = 40 -- gameframes
local IDLE_DISTANCE = 120
local ACTIVE_DISTANCE = 180
local DRONE_HEIGHT = 120
local RECALL_TIMEOUT = 300

local generateDrones = {}
local carrierList = {}
local droneList = {}
local drones_to_move = {}
local killList = {}

local GiveClampedOrderToUnit = Spring.Utilities.GiveClampedOrderToUnit

local recallDronesCmdDesc = {
	id      = CMD_RECALL_DRONES,
	type    = CMDTYPE.ICON,
	name    = 'Recall Drones',
	cursor  = 'Load units',
	action  = 'recalldrones',
	tooltip = 'Recall any owned drones to the mothership.',
}

local toggleDronesCmdDesc = {
	id      = CMD_TOGGLE_DRONES,
	type    = CMDTYPE.ICON_MODE,
	name    = 'Drone Generation',
	cursor  = 'Load units',
	action  = 'toggledrones',
	tooltip = 'Toggle drone creation.',
	params  = {1, 'Disabled','Enabled'}
}
local toggleParams = {params = {1, 'Disabled','Enabled'}}

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
local function RandomPointInUnitCircle()
	local angle = random(0, 2*math.pi)
	local distance = math.pow(random(0, 1), 0.5)
	return math.cos(angle)*distance, math.sin(angle)*distance
end

local function ChangeDroneRulesParam(unitID, diff)
	local count = Spring.GetUnitRulesParam(unitID, "dronesControlled") or 0
	count = count + diff
	Spring.SetUnitRulesParam(unitID, "dronesControlled", count, INLOS_ACCESS)
end

local function InitCarrier(unitID, carrierData, teamID, maxDronesOverride)
	local toReturn  = {teamID = teamID, droneSets = {}, occupiedPieces={}, droneInQueue= {}}
	local unitPieces = GetUnitPieceMap(unitID)
	local usedPieces = carrierData.spawnPieces
	if usedPieces then
		toReturn.spawnPieces = {}
		for i = 1, #usedPieces do
			toReturn.spawnPieces[i] = unitPieces[usedPieces[i]]
		end
		toReturn.pieceIndex = 1
	end
	local maxDronesTotal = 0
	for i = 1, #carrierData do
		-- toReturn.droneSets[i] = Spring.Utilities.CopyTable(carrierData[i])
		toReturn.droneSets[i] = {nil}
		--same as above, but we assign reference to "carrierDefs[i]" table in memory to avoid duplicates, DO NOT CHANGE ITS CONTENT (its constant & config value only).
		toReturn.droneSets[i].config = carrierData[i]
		toReturn.droneSets[i].maxDrones = (maxDronesOverride and maxDronesOverride[i]) or carrierData[i].maxDrones
		maxDronesTotal = maxDronesTotal + toReturn.droneSets[i].maxDrones
		toReturn.droneSets[i].reload = carrierData[i].reloadTime
		toReturn.droneSets[i].droneCount = 0
		toReturn.droneSets[i].drones = {}
		toReturn.droneSets[i].buildCount = 0
	end
	if maxDronesTotal > 0 then
		Spring.SetUnitRulesParam(unitID, "dronesControlled", 0, INLOS_ACCESS)
		Spring.SetUnitRulesParam(unitID, "dronesControlledMax", maxDronesTotal, INLOS_ACCESS)
	end
	return toReturn
end

local function CreateCarrier(unitID)
	Spring.InsertUnitCmdDesc(unitID, recallDronesCmdDesc)
	Spring.InsertUnitCmdDesc(unitID, toggleDronesCmdDesc)
	generateDrones[unitID] = true
end

local function Drones_InitializeDynamicCarrier(unitID)
	if carrierList[unitID] then
		return
	end
	
	local carrierData = {}
	local maxDronesOverride = {}
	for name, data in pairs(unitRulesCarrierDefs) do
		local drones = Spring.GetUnitRulesParam(unitID, "carrier_count_" .. name)
		if drones then
			carrierData[#carrierData + 1] = data
			maxDronesOverride[#maxDronesOverride + 1] = drones
			CreateCarrier(unitID)
		end
	end
	carrierList[unitID] = InitCarrier(unitID, carrierData, Spring.GetUnitTeam(unitID), maxDronesOverride)
end

-- communicates to unitscript, copied from unit_float_toggle; should be extracted to utility 
-- preferably that before i PR this
local function callScript(unitID, funcName, args)
	local func = Spring.UnitScript.GetScriptEnv(unitID)[funcName]
	if func then
		Spring.UnitScript.CallAsUnit(unitID, func, args)
	end
end

local function NewDrone(unitID, droneName, setNum, droneBuiltExternally)
	local carrierEntry = carrierList[unitID]
	local _, _, _, x, y, z = GetUnitPosition(unitID, true)
	local xS, yS, zS = x, y, z
	local rot = 0
	local piece = nil
	if carrierEntry.spawnPieces and not droneBuiltExternally then
		local index = carrierEntry.pieceIndex
		piece = carrierEntry.spawnPieces[index];
		local px, py, pz, pdx, pdy, pdz = GetUnitPiecePosDir(unitID, piece)
		xS, yS, zS = px, py, pz
		rot = Spring.GetHeadingFromVector(pdx, pdz)/65536*2*math.pi + math.pi
		
		index = index + 1
		if index > #carrierEntry.spawnPieces then
			index = 1
		end
		carrierEntry.pieceIndex = index
	else
		local angle = math.rad(random(1, 360))
		xS = (x + (math.sin(angle) * 20))
		zS = (z + (math.cos(angle) * 20))
		rot = angle
	end
	
	--Note: create unit argument: (unitDefID|unitDefName, x, y, z, facing, teamID, build, flattenGround, targetID, builderID)
	local droneID = CreateUnit(droneName, xS, yS, zS, 1, carrierList[unitID].teamID, droneBuiltExternally and true, false, nil, unitID)
	if droneID then
		Spring.SetUnitRulesParam(droneID, "parent_unit_id", unitID)
		Spring.SetUnitRulesParam(droneID, "drone_set_index", setNum)
		local droneSet = carrierEntry.droneSets[setNum]
		droneSet.droneCount = droneSet.droneCount + 1
		ChangeDroneRulesParam(unitID, 1)
		droneSet.drones[droneID] = true
		
		--SetUnitPosition(droneID, xS, zS, true)
		Spring.MoveCtrl.Enable(droneID)
		Spring.MoveCtrl.SetPosition(droneID, xS, yS, zS)
		Spring.MoveCtrl.Disable(droneID)
		Spring.SetUnitCOBValue(droneID, 82, (rot - math.pi)*65536/2/math.pi)
		
		local firestate = Spring.Utilities.GetUnitFireState(unitID)
		GiveOrderToUnit(droneID, CMD.MOVE_STATE, { 2 }, 0)
		GiveOrderToUnit(droneID, CMD.FIRE_STATE, { firestate }, 0)
		GiveOrderToUnit(droneID, CMD.IDLEMODE, { 0 }, 0)
		local rx, rz = RandomPointInUnitCircle()
		-- Drones intentionall use CMD.MOVE instead of CMD_RAW_MOVE as they do not require any of the features
		GiveClampedOrderToUnit(droneID, CMD.MOVE, {x + rx*IDLE_DISTANCE, y+DRONE_HEIGHT, z + rz*IDLE_DISTANCE}, 0)
		GiveOrderToUnit(droneID, CMD.GUARD, {unitID} , CMD.OPT_SHIFT)

		SetUnitNoSelect(droneID, true)

		droneList[droneID] = {carrier = unitID, set = setNum}
	end
	return droneID, rot
end

--START OF----------------------------
--drone nanoframe attachment code:----

function AddUnitToEmptyPad(carrierID, droneType)
	local carrierData = carrierList[carrierID]
	local unitIDAdded
	local CheckCreateStart = function(pieceNum)
		if not carrierData.occupiedPieces[pieceNum] then -- Note: We could do a strict checking of empty space here (Spring.GetUnitInBox()) before spawning drone, but that require a loop to check if & when its empty.
			local droneDefID = carrierData.droneSets[droneType].config.drone
			unitIDAdded = NewDrone(carrierID, droneDefID, droneType, true)
			if unitIDAdded then
				local offsets = carrierData.droneSets[droneType].config.offsets
				SitOnPad(unitIDAdded, carrierID, pieceNum, offsets)
				carrierData.occupiedPieces[pieceNum] = true
				if carrierData.droneSets[droneType].config.colvolTweaked then --can be used to move collision volume away from carrier to avoid collision
					Spring.SetUnitMidAndAimPos(unitIDAdded, offsets.colvolMidX, offsets.colvolMidY, offsets.colvolMidZ, offsets.aimX, offsets.aimY, offsets.aimZ, true) 
					--offset whole colvol & aim point (red dot) above the carrier (use /debugcolvol to check)
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
				--- notify carrier that it should start a drone building animation
				callScript(carrierID, "Carrier_droneStarted", pieceNum)
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
local Sleep     = coroutine.yield
local assert    = assert
local function StartScript(fn)
	local co = coroutine.create(fn)
	coroutineCount = coroutineCount + 1 --in case new co-routine is added in same frame
	coroutines[coroutineCount] = co
end

function UpdateCoroutines() 
	coroutineCount = #coroutines
	local i = 1
	while (i <= coroutineCount) do
		local co = coroutines[i] 
		if (coroutine.status(co) ~= "dead") then 
			assert(coroutine.resume(co))
			i = i + 1
		else
			coroutines[i] = coroutines[coroutineCount]
			coroutines[coroutineCount] = nil
			coroutineCount = coroutineCount - 1
		end
	end 
end

local function GetPitchYawRoll(front, top) --This allow compatibility with Spring 91
	--NOTE:
	--angle measurement and direction setting is based on right-hand coordinate system, but Spring might rely on left-hand coordinate system.
	--So, input for math.sin and math.cos, or positive/negative sign, or math.atan2 might be swapped with respect to the usual whenever convenient.

	--1) Processing FRONT's vector to get Pitch and Yaw
	local x, y, z = front[1], front[2], front[3]
	local xz = math.sqrt(x*x + z*z) --hypothenus
	local yaw = math.atan2 (x/xz, z/xz) --So facing south is 0-radian, and west is negative radian, and east is positive radian
	local pitch = math.atan2 (y, xz) --So facing upward is positive radian, and downward is negative radian
	
	--2) Processing TOP's vector to get Roll
	x, y, z = top[1], top[2], top[3]
	--rotate coordinate around Y-axis until Yaw value is 0 (a reset) 
	local newX = x* math.cos (-yaw) + z*  math.sin (-yaw)
	local newY = y
	local newZ = z* math.cos (-yaw) - x* math.sin (-yaw)
	x, y, z = newX, newY, newZ
	--rotate coordinate around X-axis until Pitch value is 0 (a reset) 
	newX = x 
	newY = y* math.cos (-pitch) + z* math.sin (-pitch)
	newZ = z* math.cos (-pitch) - y* math.sin (-pitch)
	x, y, z = newX, newY, newZ
	local roll =  math.atan2 (x, y) --So lifting right wing is positive radian, and lowering right wing is negative radian
	
	return pitch, yaw, roll
end

local function GetOffsetRotated(rx, ry, rz, front, top, right)
	local offX = front[1]*rz + top[1]*ry - right[1]*rx
	local offY = front[2]*rz + top[2]*ry - right[2]*rx
	local offZ = front[3]*rz + top[3]*ry - right[3]*rx
	return offX, offY, offZ
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

local mcSetVelocity         = Spring.MoveCtrl.SetVelocity
local mcSetPosition         = Spring.MoveCtrl.SetPosition
local mcSetRotation         = Spring.MoveCtrl.SetRotation
local mcDisable             = Spring.MoveCtrl.Disable
local mcEnable              = Spring.MoveCtrl.Enable

local function GetBuildRate(unitID)
	if not generateDrones[unitID] then
		return 0
	end
	local stunned_or_inbuild = GetUnitIsStunned(unitID) or (spGetUnitRulesParam(unitID, "disarmed") == 1)
	if stunned_or_inbuild then
		return 0
	end
	return spGetUnitRulesParam(unitID, "totalReloadSpeedChange") or 1
end

function SitOnPad(unitID, carrierID, padPieceID, offsets)
	-- From unit_refuel_pad_handler.lua (author: GoogleFrog)
	-- South is 0 radians and increases counter-clockwise
	
	Spring.SetUnitHealth(unitID, {build = 0})
	
	local GetPlacementPosition = function(inputID, pieceNum)
		if (pieceNum == 0) then
			local _, _, _, mx, my, mz = Spring.GetUnitPosition(inputID, true)
			local dx, dy, dz = Spring.GetUnitDirection(inputID)
			return mx, my, mz, dx, dy, dz
		else
			return Spring.GetUnitPiecePosDir(inputID, pieceNum)
		end
	end
	
	local AddNextDroneFromQueue = function(inputID)
		if #carrierList[inputID].droneInQueue > 0 then
			if AddUnitToEmptyPad(inputID, carrierList[inputID].droneInQueue[1]) then --pad cleared, immediately add any unit from queue
				table.remove(carrierList[inputID].droneInQueue, 1)
			end
		end
	end
	
	mcEnable(unitID)
	Spring.SetUnitLeaveTracks(unitID, false)
	Spring.SetUnitBlocking(unitID, false, false, true, true, false, true, false)
	mcSetVelocity(unitID, 0, 0, 0)
	mcSetPosition(unitID, GetPlacementPosition(carrierID, padPieceID))
	
	-- deactivate unit to cause the lups jets away
	Spring.SetUnitCOBValue(unitID, COB.ACTIVATION, 0)
	
	local function SitLoop()
		local previousDir, currentDir
		local pitch, yaw, roll
		local px, py, pz, dx, dy, dz, vx, vy, vz, offx, offy, offz
		-- local magnitude, newPadHeading
		
		if not droneList[unitID] then
			--droneList[unitID] became NIL when drone or carrier is destroyed (in UnitDestroyed()). Is NIL at beginning of frame and this piece of code run at end of frame
			if carrierList[carrierID] then
				droneInfo.buildCount = droneInfo.buildCount - 1
				carrierList[carrierID].occupiedPieces[padPieceID] = false
				AddNextDroneFromQueue(carrierID) --add next drone in this vacant position
				GG.StopMiscPriorityResourcing(carrierID, miscPriorityKey)
			end
			return --nothing else to do
		end
		
		local miscPriorityKey = "drone_" .. unitID
		local oldBuildRate = false
		local buildProgress, health
		local droneType = droneList[unitID].set
		local droneInfo = carrierList[carrierID].droneSets[droneType] --may persist even after "carrierList[carrierID]" is emptied
		local build_step = droneInfo.config.buildStep
		local build_step_health = droneInfo.config.buildStepHealth
		
		local buildStepCost = droneInfo.config.buildStepCost
		local perSecondCost = droneInfo.config.perSecondCost
		
		local resTable
		if buildStepCost then
			resTable = {
				m = buildStepCost,
				e = buildStepCost,
			}
		end
		
		while true do
			if (not droneList[unitID]) then
				--droneList[unitID] became NIL when drone or carrier is destroyed (in UnitDestroyed()). Is NIL at beginning of frame and this piece of code run at end of frame
				if carrierList[carrierID] then
					droneInfo.buildCount = droneInfo.buildCount - 1
					carrierList[carrierID].occupiedPieces[padPieceID] = false
					AddNextDroneFromQueue(carrierID) --add next drone in this vacant position
					GG.StopMiscPriorityResourcing(carrierID, miscPriorityKey)
				end
				return --nothing else to do
			elseif (not carrierList[carrierID]) then --carrierList[carrierID] is NIL because it was MORPHED.
				carrierID = droneList[unitID].carrier
				padPieceID = (carrierList[carrierID].spawnPieces and carrierList[carrierID].spawnPieces[1]) or 0
				carrierList[carrierID].occupiedPieces[padPieceID] = true --block pad
				oldBuildRate = false -- Update MiscPriority for morphed unit.
			end
			
			vx, vy, vz = Spring.GetUnitVelocity(carrierID)
			px, py, pz, dx, dy, dz = GetPlacementPosition(carrierID, padPieceID)
			currentDir = dx + dy*100 + dz* 10000
			if previousDir ~= currentDir then --refresh pitch/yaw/roll calculation when unit had slight turning
				previousDir = currentDir
				front, top, right = Spring.GetUnitVectors(carrierID)
				pitch, yaw, roll = GetPitchYawRoll(front, top)
				offx, offy, offz = GetOffsetRotated(offsets[1], offsets[2], offsets[3], front, top, right)
			end
			mcSetVelocity(unitID, vx, vy, vz)
			mcSetPosition(unitID, px + vx + offx, py + vy + offy, pz + vz + offz)
			mcSetRotation(unitID, pitch, -yaw, roll) --Spring conveniently rotate Y-axis first, X-axis 2nd, and Z-axis 3rd which allow Yaw, Pitch & Roll control.
			
			local buildRate = GetBuildRate(carrierID) 
			if perSecondCost and oldBuildRate ~= buildRate then
				oldBuildRate = buildRate
				GG.StartMiscPriorityResourcing(carrierID, perSecondCost*buildRate, false, miscPriorityKey)
				resTable.m = buildStepCost*buildRate
				resTable.e = buildStepCost*buildRate
			end
			
			-- Check if the change can be carried out
			if (buildRate > 0) and ((not perSecondCost) or (GG.AllowMiscPriorityBuildStep(carrierID, Spring.GetUnitTeam(carrierID), false, resTable) and Spring.UseUnitResource(carrierID, resTable))) then
				health, _, _, _, buildProgress = Spring.GetUnitHealth(unitID)
				buildProgress = buildProgress + (build_step*buildRate) --progress
				Spring.SetUnitHealth(unitID, {health = health + (build_step_health*buildRate), build = buildProgress}) 
				if buildProgress >= 1 then 
					callScript(carrierID, "Carrier_droneCompleted", padPieceID)
					break
				end
			end
			
			Sleep()
		end
		
		GG.StopMiscPriorityResourcing(carrierID, miscPriorityKey)
		
		droneInfo.buildCount = droneInfo.buildCount - 1
		carrierList[carrierID].occupiedPieces[padPieceID] = false
		Spring.SetUnitLeaveTracks(unitID, true)
		Spring.SetUnitVelocity(unitID, 0, 0, 0)
		Spring.SetUnitBlocking(unitID, false, true, true, true, false, true, false)
		mcDisable(unitID)
		GG.UpdateUnitAttributes(unitID) --update pending attribute changes in unit_attributes.lua if available 
		
		if droneInfo.config.colvolTweaked then
			Spring.SetUnitMidAndAimPos(unitID, 0, 0, 0, 0, 0, 0, true)
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
--[[
local function transferCarrierData(unitID, unitDefID, unitTeam, newUnitID)
	-- UnitFinished (above) should already be called for this new unit.
	if carrierList[newUnitID] then
		carrierList[newUnitID] = Spring.Utilities.CopyTable(carrierList[unitID], true) -- deep copy?
		  -- old carrier data removal (transfering drones to new carrier, old will "die" (on morph) silently without taking drones together to the grave)...
		local carrier = carrierList[unitID]
		for i=1, #carrier.droneSets do
			local set = carrier.droneSets[i]
			for droneID in pairs(set.drones) do
				droneList[droneID].carrier = newUnitID
				GiveOrderToUnit(droneID, CMD.GUARD, {newUnitID} , CMD.OPT_SHIFT)
			end
		end
		carrierList[unitID] = nil
	end
end
--]]

local function isCarrier(unitID)
	if (carrierList[unitID]) then
		return true
	end
	return false
end

-- morph uses this
GG.isCarrier = isCarrier
--GG.transferCarrierData = transferCarrierData

local function GetDistance(x1, x2, y1, y2)
	return ((x1-x2)^2 + (y1-y2)^2)^0.5
end

local function UpdateCarrierTarget(carrierID, frame)
	local cmdID, cmdParam_1, cmdParam_2, cmdParam_3
	if Spring.Utilities.COMPAT_GET_ORDER then
		local queue = Spring.GetCommandQueue(carrierID, 1)
		if queue and queue[1] then
			local par = queue[1].params
			cmdID, cmdParam_1, cmdParam_2, cmdParam_3 = queue[1].id, par[1], par[2], par[3]
		end
	else
		cmdID, _, _, cmdParam_1, cmdParam_2, cmdParam_3 = Spring.GetUnitCurrentCommand(carrierID)
	end
	
	local droneSendDistance = nil
	local px, py, pz
	local target
	local recallDrones = false
	local attackOrder = false
	local setTargetOrder = false
	
	--checks if there is an active recall order
	local recallFrame = spGetUnitRulesParam(carrierID,"recall_frame_start")
	if recallFrame then
		if frame > recallFrame + RECALL_TIMEOUT then
			--recall has expired
			spSetUnitRulesParam(carrierID,"recall_frame_start",nil)
		else
			recallDrones = true
		end
	end
	
	--Handles an attack order given to the carrier.
	if not recallDrones and cmdID == CMD_ATTACK then
		local ox, oy, oz = GetUnitPosition(carrierID)
		if cmdParam_1 and not cmdParam_2 then
			target = {cmdParam_1}
			px, py, pz = GetUnitPosition(cmdParam_1)
		else
			px, py, pz = cmdParam_1, cmdParam_2, cmdParam_3
		end
		if px then
			droneSendDistance = GetDistance(ox, px, oz, pz)
		end
		attackOrder = true --attack order overrides set target
	end
	
	--Handles a setTarget order given to the carrier.
	if not recallDrones and not attackOrder then
		local targetType = spGetUnitRulesParam(carrierID,"target_type")
		if targetType and targetType > 0 then
			local ox, oy, oz = GetUnitPosition(carrierID)
			if targetType == 1 then --targeting ground
				px, py, pz = spGetUnitRulesParam(carrierID,"target_x"), spGetUnitRulesParam(carrierID,"target_y"), spGetUnitRulesParam(carrierID,"target_z")
			end
			if targetType == 2 then --targeting units
				local target_id = spGetUnitRulesParam(carrierID,"target_id")
				target = {target_id}
				px, py, pz = GetUnitPosition(target_id)
			end
			if px then
				droneSendDistance = GetDistance(ox, px, oz, pz)
			end
			setTargetOrder = true
		end
	end
	
	local firestate = Spring.Utilities.GetUnitFireState(carrierID)
	local holdfire = (firestate == 0)
	local rx, rz
	
	for i = 1, #carrierList[carrierID].droneSets do
	
		local set = carrierList[carrierID].droneSets[i]
		local tempCONTAINER
		
		
		for droneID in pairs(set.drones) do
			tempCONTAINER = droneList[droneID]
			droneList[droneID] = nil -- to keep AllowCommand from blocking the order
			
			if attackOrder or setTargetOrder then
				-- drones fire at will if carrier has an attack/target order
				-- a drone bomber probably should not do this
				GiveOrderToUnit(droneID, CMD.FIRE_STATE, { 2 }, 0) 
			else
				-- update firestate based on that of carrier
				GiveOrderToUnit(droneID, CMD.FIRE_STATE, { firestate }, 0) 
			end
			
			if recallDrones then
				-- move drones to carrier
				px, py, pz = GetUnitPosition(carrierID)
				rx, rz = RandomPointInUnitCircle()
				GiveClampedOrderToUnit(droneID, CMD.MOVE, {px + rx*IDLE_DISTANCE, py+DRONE_HEIGHT, pz + rz*IDLE_DISTANCE}, 0)
				GiveOrderToUnit(droneID, CMD.GUARD, {carrierID} , CMD.OPT_SHIFT)
			elseif droneSendDistance and droneSendDistance < set.config.range then
				-- attacking
				if target then
					GiveOrderToUnit(droneID, CMD.ATTACK, target, 0)
				else
					rx, rz = RandomPointInUnitCircle()
					GiveClampedOrderToUnit(droneID, CMD.FIGHT, {px + rx*ACTIVE_DISTANCE, py+DRONE_HEIGHT, pz + rz*ACTIVE_DISTANCE}, 0)
				end
			else
				-- return to carrier unless in combat
				local cQueue = GetCommandQueue(droneID, -1)
				local engaged = false
				for i=1, (cQueue and #cQueue or 0) do
					if cQueue[i].id == CMD.FIGHT and firestate > 0 then
						-- if currently fighting AND not on hold fire
						engaged = true
						break
					end
				end
				if not engaged then
					px, py, pz = GetUnitPosition(carrierID)
					rx, rz = RandomPointInUnitCircle()
					GiveClampedOrderToUnit(droneID, holdfire and CMD.MOVE or CMD.FIGHT, {px + rx*IDLE_DISTANCE, py+DRONE_HEIGHT, pz + rz*IDLE_DISTANCE}, 0)
					GiveOrderToUnit(droneID, CMD.GUARD, {carrierID} , CMD.OPT_SHIFT)
				end
			end
			
			droneList[droneID] = tempCONTAINER
		end
		
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local function ToggleDronesCommand(unitID, newState)
	local cmdDescID = Spring.FindUnitCmdDesc(unitID, CMD_TOGGLE_DRONES)
	if (cmdDescID) then
		toggleParams.params[1] = newState
		Spring.EditUnitCmdDesc(unitID, cmdDescID, toggleParams)
		generateDrones[unitID] = (newState == 1)
	end
end

function gadget:AllowCommand_GetWantedCommand()
	return true
end

function gadget:AllowCommand_GetWantedUnitDefID()
	return true
end

function gadget:AllowCommand(unitID, unitDefID, teamID, cmdID, cmdParams, cmdOptions)
	if droneList[unitID] then
		return false
	end
	if not carrierList[unitID] then
		return true
	end
	
	if cmdID == CMD_TOGGLE_DRONES then
		ToggleDronesCommand(unitID, cmdParams[1])
		return false
	end
	
	if (cmdID == CMD.ATTACK or cmdID == CMD.FIGHT or cmdID == CMD.PATROL or cmdID == CMD_UNIT_SET_TARGET or cmdID == CMD_UNIT_SET_TARGET_CIRCLE) then
		spSetUnitRulesParam(unitID,"recall_frame_start",nil)
		return true
	end
	
	if (cmdID == CMD_RECALL_DRONES) then
		
		-- Gives drones a command to recall to the carrier
		for i = 1, #carrierList[unitID].droneSets do
			local set = carrierList[unitID].droneSets[i]
			
			for droneID in pairs(set.drones) do
				px, py, pz = GetUnitPosition(unitID)
				
				local temp = droneList[droneID]
				droneList[droneID] = nil	-- to keep AllowCommand from blocking the order
				local rx, rz = RandomPointInUnitCircle()
				GiveClampedOrderToUnit(droneID, CMD.MOVE, {px + rx*IDLE_DISTANCE, py+DRONE_HEIGHT, pz + rz*IDLE_DISTANCE}, 0)
				GiveOrderToUnit(droneID, CMD.GUARD, {unitID} , CMD.OPT_SHIFT)
				droneList[droneID] = temp
			end
		end
		
		frame = spGetGameFrame()
		spSetUnitRulesParam(unitID,"recall_frame_start",frame)
		
		return false
	end
	
	return true
end

function gadget:UnitDestroyed(unitID, unitDefID, unitTeam)
	if (carrierList[unitID]) then
		local newUnitID = GG.wasMorphedTo and GG.wasMorphedTo[unitID]
		local carrier = carrierList[unitID]
		if newUnitID and carrierList[newUnitID] then --MORPHED, and MORPHED to another carrier. Note: unit_morph.lua create unit first before destroying it, so "carrierList[]" is already initialized.
			local newCarrier = carrierList[newUnitID]
			ToggleDronesCommand(newUnitID, ((generateDrones[unitID] ~= false) and 1) or 0)
			for i = 1, #carrier.droneSets do
				local set = carrier.droneSets[i]
				local newSetID = -1
				local droneCount = 0
				for j = 1, #newCarrier.droneSets do
					if newCarrier.droneSets[j].config.drone == set.config.drone then --same droneType? copy old drone data
						newCarrier.droneSets[j].droneCount = set.droneCount
						droneCount = droneCount + set.droneCount
						newCarrier.droneSets[j].reload = set.reload
						newCarrier.droneSets[j].drones = set.drones
						newSetID = j
					end
				end
				ChangeDroneRulesParam(newUnitID, droneCount)

				for droneID in pairs(set.drones) do
					droneList[droneID].carrier = newUnitID
					droneList[droneID].set = newSetID
					GiveOrderToUnit(droneID, CMD.GUARD, {newUnitID} , CMD.OPT_SHIFT)
				end
			end
		else --Carried died
			for i = 1, #carrier.droneSets do
				local set = carrier.droneSets[i]
				for droneID in pairs(set.drones) do
					droneList[droneID] = nil
					killList[droneID] = true
				end
			end
		end
		generateDrones[unitID] = nil
		carrierList[unitID] = nil
	elseif (droneList[unitID]) then
		local carrierID = droneList[unitID].carrier
		local setID = droneList[unitID].set
		if setID > -1 then --is -1 when carrier morphed and drone is incompatible with the carrier
			local droneSet = carrierList[carrierID].droneSets[setID]
			droneSet.droneCount = (droneSet.droneCount - 1)
			ChangeDroneRulesParam(carrierID, -1)
			droneSet.drones[unitID] = nil
		end
		droneList[unitID] = nil
	end
end

function gadget:UnitCreated(unitID, unitDefID, unitTeam)
	if (carrierDefs[unitDefID]) then
		CreateCarrier(unitID)
	end
end

function gadget:UnitFinished(unitID, unitDefID, unitTeam)
	if Spring.GetUnitRulesParam(unitID, "comm_level") then
		Drones_InitializeDynamicCarrier(unitID)
	end
	if (carrierDefs[unitDefID]) and not carrierList[unitID] then
		carrierList[unitID] = InitCarrier(unitID, carrierDefs[unitDefID], unitTeam)
	end
end

function gadget:UnitGiven(unitID, unitDefID, newTeam)
	if carrierList[unitID] then
		carrierList[unitID].teamID = newTeam
		for i = 1, #carrierList[unitID].droneSets do
			local set = carrierList[unitID].droneSets[i]
			for droneID, _ in pairs(set.drones) do
				-- Only transfer drones which are allied with the carrier. This is to 
				-- make carriers and capture interact in a robust, simple way. A captured
				-- drone will take up a slot on the carrier and attack the carriers allies.
				-- A captured carrier will need to have its drones killed or captured to
				-- free up slots.
				local droneTeam = Spring.GetUnitTeam(droneID)
				if droneTeam and Spring.AreTeamsAllied(droneTeam, newTeam) then
					drones_to_move[droneID] = newTeam
				end
			end
		end
	end
end

function gadget:GameFrame(n)
	if (((n+1) % 30) == 0) then
		for carrierID, carrier in pairs(carrierList) do
			if (not GetUnitIsStunned(carrierID)) then
				for i = 1, #carrier.droneSets do
					local set = carrier.droneSets[i]
					if (set.reload > 0) then
						local reloadMult = spGetUnitRulesParam(carrierID, "totalReloadSpeedChange") or 1
						set.reload = (set.reload - reloadMult)
						
					elseif (set.droneCount < set.maxDrones) and set.buildCount < set.config.maxBuild then --not reach max count and finished previous queue
						if generateDrones[carrierID] then
							for n = 1, set.config.spawnSize do
								if (set.droneCount >= set.maxDrones) then
									break
								end
								
								carrierList[carrierID].droneInQueue[ #carrierList[carrierID].droneInQueue + 1 ] = i
								if AddUnitToEmptyPad(carrierID, i ) then
									set.buildCount = set.buildCount + 1;
									table.remove(carrierList[carrierID].droneInQueue, 1)
								end
							end
							set.reload = set.config.reloadTime -- apply reloadtime when queuing construction (not when it actually happens) - helps keep a constant creation rate over time
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
		for i, _ in pairs(carrierList) do
			UpdateCarrierTarget(i, n)
		end
	end
	UpdateCoroutines() --maintain nanoframe position relative to carrier
end

function gadget:Initialize()
	gadgetHandler:RegisterCMDID(CMD_RECALL_DRONES)
	gadgetHandler:RegisterCMDID(CMD_TOGGLE_DRONES)
	GG.Drones_InitializeDynamicCarrier = Drones_InitializeDynamicCarrier
	for _, unitID in ipairs(Spring.GetAllUnits()) do
		local unitDefID = Spring.GetUnitDefID(unitID)
		local team = Spring.GetUnitTeam(unitID)
		gadget:UnitCreated(unitID, unitDefID, team)
		local build  = select(5, Spring.GetUnitHealth(unitID))
		if build == 1 then
			gadget:UnitFinished(unitID, unitDefID, team)
		end
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Save/Load

local function LoadDrone(unitID, parentID)
	Spring.DestroyUnit(unitID, false, true)
end

function gadget:Load(zip)
	for _, unitID in ipairs(Spring.GetAllUnits()) do
		local parentID = Spring.GetUnitRulesParam(unitID, "parent_unit_id")
		if parentID then
			LoadDrone(unitID, parentID)
		end
	end
end

