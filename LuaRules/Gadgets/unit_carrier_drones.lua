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
local random            = math.random
local CMD_ATTACK		= CMD.ATTACK

local spGetUnitRulesParam = Spring.GetUnitRulesParam

-- thingsWhichAreDrones is an optimisation for AllowCommand
local carrierDefs, thingsWhichAreDrones = include "LuaRules/Configs/drone_defs.lua"

local DEFAULT_UPDATE_ORDER_FREQUENCY = 40 -- gameframes
local DEFAULT_MAX_DRONE_RANGE = 1500

local BUILD_UPDATE_INTERVAL = 15 --gameframe
local DRONE_COLVOL_BUILD_OFFSET = 25 --elmo from carrier where drone's colvol will appear (model will still appear specified emit point. A config is a TODO)

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
		toReturn.droneSets[i] = Spring.Utilities.CopyTable(carrierData[i])
		toReturn.droneSets[i].reload = toReturn.droneSets[i].reloadTime
		toReturn.droneSets[i].droneCount = 0
		toReturn.droneSets[i].drones = {}
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
		droneSet.reload = carrierDefs[unitDefID][setNum].reloadTime
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

function AddUnitToEmptyPad(carrierID,carrierDefID,droneName, setNum)
	local carrierData = carrierList[carrierID]
	carrierData.droneInQueue[ #carrierData.droneInQueue+ 1 ] = droneName
	local clearDist = 10
	for i=1, #carrierList[carrierID].spawnPieces do
		local pieceNum = carrierList[carrierID].spawnPieces[i]
		local uxx,uyy,uzz = GetUnitPiecePosDir(carrierID, pieceNum)
		local somethingOnThePad = Spring.GetUnitsInBox(uxx-clearDist,uyy-clearDist,uzz-clearDist, uxx+clearDist,uyy+clearDist,uzz+clearDist)
		if not carrierData.occupiedPieces[pieceNum] and ((#somethingOnThePad == 1 and somethingOnThePad[1]== carrierID) or (#somethingOnThePad == 0)) then
			local unitIDAdded,rotation = NewDrone(carrierID, carrierDefID, droneName, setNum, true)
			if unitIDAdded then
				table.remove(carrierData.droneInQueue,1)
				SitOnPad(unitIDAdded,carrierID,pieceNum,rotation)
			
				carrierData.occupiedPieces[pieceNum] = true
				droneList[unitIDAdded].defaultRadius = Spring.GetUnitRadius(unitIDAdded)
				
				--Move collision volume away from carrier to avoid collision
				Spring.SetUnitMidAndAimPos(unitIDAdded,0,DRONE_COLVOL_BUILD_OFFSET,0,0,DRONE_COLVOL_BUILD_OFFSET,0,true) --offset whole colvol & aim point (red dot) above the carrier (use /debugcolvol to check)
				Spring.SetUnitRadiusAndHeight(unitIDAdded,10,nil)
				break;
			end
		end
	end
	return unitIDAdded, unitDefIDToAdd
end

local coroutines = {}
local coroutine = coroutine
local Sleep	    = coroutine.yield
local assert    = assert
local function StartScript(fn)
	local co = coroutine.create(fn)
	coroutines[#coroutines + 1] = co
end

function UpdateCoroutines() 
	local coroutineCount = #coroutines
	local i=1
	while (i<=coroutineCount) do 
		local co = coroutines[i] 
		if (coroutine.status(co) ~= "dead") then 
			assert(coroutine.resume(coroutines[i]))
		else
			coroutines[i] = coroutines[coroutineCount]
			coroutines[coroutineCount] = nil
			coroutineCount = coroutineCount -1
			i = i - 1
		end
		i = i + 1
	end 
end

local function GetPitchYawRoll(unitID) --This allow compatibility with Spring 91
	--NOTE:
	--angle measurement and direction setting is based on right-hand coordinate system, but Spring might rely on left-hand coordinate system.
	--So, input for math.sin, math.cos and math.atan2 might be swapped with respect to the usual whenever convenient.

	local front, top, right = Spring.GetUnitVectors(unitID)
	--1) Processing FRONT's vector to get Pitch and Yaw
	local x,y,z = front[1], front[2],front[3]
	local xz = math.sqrt(x*x + z*z) --hypothenus
	local yaw = math.atan2 (x/xz, z/xz) --So facing south is 0-degree, and west is negative degree
	local pitch = math.atan2 (y,xz) --So facing forward is 0-degree, and downward is negative degree
	
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
	local roll =  math.atan2 (x, y) --So lifting right wing is positive degree, and lowering right wing is negative degree
	
	-- Spring.Echo("Pitch:" .. pitch*180/math.pi)
	-- Spring.Echo("Yaw:" .. yaw*180/math.pi)
	-- Spring.Echo("Roll:" .. roll*180/math.pi)
	return pitch, yaw, roll
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
function SitOnPad(unitID,carrierID, padPieceID,rotation)
	-- From unit_refuel_pad_handler.lua (author: GoogleFrog)
	-- South is 0 radians and increases counter-clockwise
	
	Spring.SetUnitHealth(unitID,{ build = 0 })
	
	local px, py, pz, dx, dy, dz = Spring.GetUnitPiecePosDir(carrierID, padPieceID)
	-- local ury = rotation*PI/180
	
	mcEnable(unitID)
	Spring.SetUnitLeaveTracks(unitID, false)
	
	Spring.SetUnitVelocity(unitID, 0, 0, 0)
	mcSetVelocity(unitID, 0, 0, 0)
	mcSetPosition(unitID,px, py, pz)
	
	-- deactivate unit to cause the lups jets away
	Spring.SetUnitCOBValue(unitID, COB.ACTIVATION, 0)
	
	local function SitLoop()
		local previousDir,currentDir
		local pitch,yaw,roll
		local px, py, pz, dx, dy, dz,vx,vy,vz
		-- local magnitude, newPadHeading
		local landDuration = 0
		local buildProgress,health
		local droneInfo = carrierList[carrierID].droneSets[(droneList[unitID].set)]
		local build_step = droneInfo.buildStep
		local build_step_health = droneInfo.buildStepHealth
		while true do
			if (not carrierList[carrierID]) or (not droneList[unitID]) then
				if Spring.ValidUnitID(unitID) then
					Spring.DestroyUnit(unitID, true, false) -- selfd = true, reclaim = false
				end
				if carrierList[carrierID] then
					carrierList[carrierID].occupiedPieces[padPieceID] = false
				end
				return
			end
			
			vx,vy,vz = Spring.GetUnitVelocity(carrierID)
			px, py, pz, dx, dy, dz = Spring.GetUnitPiecePosDir(carrierID, padPieceID)
			currentDir = dx + dy*100 + dz* 10000
			if previousDir ~= currentDir then --refresh pitch/yaw/roll calculation when unit had slight turning
				previousDir = currentDir
				pitch,yaw,roll = GetPitchYawRoll(carrierID)
				-- magnitude = math.sqrt(dx^2+dy^2+dz^2)
				-- dx = dx/magnitude --todo: some trigonometry for pitch & yaw (not compatible with Spring91). It ensure colvol appear at same relative position
				-- dy = dy/magnitude
				-- dz = dz/magnitude --need to normalize or the output is skewed when unit pitch & yaw
				-- newPadHeading = acos(dz)
				-- if dx < 0 then
					-- newPadHeading = 2*PI-newPadHeading --for level unit only!
				-- end
			end
			mcSetVelocity(unitID,vx,vy,vz)
			mcSetPosition(unitID,px+vx, py+vy, pz+vz)
			-- mcSetRotation(unitID,0,newPadHeading+ury,0)
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
		carrierList[carrierID].occupiedPieces[padPieceID] = false
		Spring.SetUnitLeaveTracks(unitID, true)
		Spring.SetUnitVelocity(unitID, 0, 0, 0)
		mcDisable(unitID)
		GG.UpdateUnitAttributes(unitID) --update pending attribute changes in unit_attributes.lua if available 
		
		Spring.SetUnitMidAndAimPos(unitID,0,0,0,0,0,0,true)
		Spring.SetUnitRadiusAndHeight(unitID,droneList[unitID].defaultRadius,nil)
		
		
		-- activate unit and its jets
		Spring.SetUnitCOBValue(unitID, COB.ACTIVATION, 1)
	end
	
	StartScript(SitLoop)
end

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
	local droneSendDistance = false
	local px,py,pz
	if cQueueC and cQueueC[1] and cQueueC[1].id == CMD_ATTACK then
		local ox,oy,oz = GetUnitPosition(carrierID)
		local params = cQueueC[1].params
		if #params == 1 then
			px,py,pz = GetUnitPosition(params[1])
		else
			px,py,pz = cQueueC[1].params[1], cQueueC[1].params[2], cQueueC[1].params[3]
		end
		if not px then
			return
		end
		
		droneSendDistance = GetDistance(ox,px,oz,pz)
	end
	
	for i=1,#carrierList[carrierID].droneSets do
		local set = carrierList[carrierID].droneSets[i]
		if droneSendDistance and droneSendDistance < set.range then
			for droneID in pairs(set.drones) do
				droneList[droneID] = nil	-- to keep AllowCommand from blocking the order
				GiveClampedOrderToUnit(droneID, CMD.FIGHT, {(px + (random(0,300) - 150)), (py+120), (pz + (random(0,300) - 150))} , {""})
				--GiveOrderToUnit(droneID, CMD.GUARD, {carrierID} , {"shift"})
				droneList[droneID] = {carrier = carrierID, set = i}
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
					droneList[droneID] = nil	-- to keep AllowCommand from blocking the order
					GiveClampedOrderToUnit(droneID, CMD.FIGHT, {px + random(-100,100), (py+120), pz + random(-100,100)} , 0)
					GiveOrderToUnit(droneID, CMD.GUARD, {carrierID} , {"shift"})
					droneList[droneID] = {carrier = carrierID, set = i}
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
					local carrierDef = carrierDefs[carrier.unitDefID][i]
					local set = carrier.droneSets[i]
					if (set.reload > 0) then
						local reloadMult = spGetUnitRulesParam(carrierID, "totalReloadSpeedChange") or 1
						set.reload = (set.reload - reloadMult)
						
					elseif (set.droneCount < set.maxDrones) then
						for n=1,set.spawnSize do
							if (set.droneCount >= set.maxDrones) then
								break
							end
							AddUnitToEmptyPad(carrierID, carrier.unitDefID, carrierDef.drone, i )
							-- NewDrone(carrierID, carrier.unitDefID, carrierDef.drone, i )
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
	--pre-calculate some buildtime related variable
	local buildUpProgress
	for name,carrierData in pairs(carrierDefs) do
		for i=1,#carrierData do
			buildUpProgress = 1/(carrierData[i].buildTime)*(BUILD_UPDATE_INTERVAL/30) -- derived from: time_to_complete = (1.0/build_step_fraction)*build_interval
			carrierDefs[name][i].buildStep = buildUpProgress
			carrierDefs[name][i].buildStepHealth = buildUpProgress*UnitDefs[carrierData[i].drone].health
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
