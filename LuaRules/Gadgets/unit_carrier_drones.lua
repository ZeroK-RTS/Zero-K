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

-- thingsWhichAreDrones is an optimisation for AllowCommand
local carrierDefs, thingsWhichAreDrones = include "LuaRules/Configs/drone_defs.lua"

local DEFAULT_UPDATE_ORDER_FREQUENCY = 40 -- gameframes
local DEFAULT_MAX_DRONE_RANGE = 1500

local carrierList = {}
local droneList = {}
local drones_to_move = {}
local killList = {}

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
local function InitCarrier(unitID, unitDefID, teamID)
	local carrierData = carrierDefs[unitDefID]
	local toReturn  = {unitDefID = unitDefID, teamID = teamID, droneSets = {}}
	local unitPieces = GetUnitPieceMap(unitID)
	local usedPieces = carrierData.spawnPieces
	if usedPieces then
		toReturn.spawnPieces = {}
		for i=1,#usedPieces do
			toReturn.spawnPieces[i] = unitPieces[usedPieces[i]]
		end
	end
	for i=1,#carrierData do
		toReturn.droneSets[i] = Spring.Utilities.CopyTable(carrierData[i])
		toReturn.droneSets[i].reload = toReturn.droneSets[i].reloadTime
		toReturn.droneSets[i].droneCount = 0
		toReturn.droneSets[i].drones = {}
	end
	return toReturn
end

local function NewDrone(unitID, unitDefID, droneName, setNum)
	local carrierEntry = carrierList[unitID]
	local _, _, _, x, y, z = GetUnitPosition(unitID, true)
	local xS, yS, zS = x, y, z
	local rot = 0
	if carrierEntry.spawnPieces then
		local piece = math.random(#carrierEntry.spawnPieces)
		local px, py, pz, pdx, pdy, pdz = GetUnitPiecePosDir(unitID, carrierEntry.spawnPieces[piece])
		xS, yS, zS = px, py, pz
		rot = Spring.GetHeadingFromVector(pdx, pdz)/65536*2*math.pi + math.pi
	else
		local angle = math.rad(random(1,360))
		xS = (x + (math.sin(angle) * 20))
		zS = (z + (math.cos(angle) * 20))
		rot = angle
	end
	local droneID = CreateUnit(droneName,xS,yS,zS,1,carrierList[unitID].teamID)
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
		GiveOrderToUnit(droneID, CMD.FIGHT,	{x + random(-300,300), 60, z + random(-300,300)}, {""})
		GiveOrderToUnit(droneID, CMD.GUARD, {unitID} , {"shift"})

		SetUnitNoSelect(droneID,true)

		droneList[droneID] = {carrier = unitID, set = setNum}
	end
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
				GiveOrderToUnit(droneID, CMD.FIGHT, {(px + (random(0,300) - 150)), (py+120), (pz + (random(0,300) - 150))} , {""})
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
					GiveOrderToUnit(droneID, CMD.FIGHT, {px + random(-100,100), (py+120), pz + random(-100,100)} , 0)
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
	if (carrierDefs[unitDefID]) then
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
						set.reload = (set.reload - 1)
					elseif (set.droneCount < carrierDef.maxDrones) then
						for n=1,carrierDef.spawnSize do
							if (set.droneCount >= set.maxDrones) then
								break
							end
							NewDrone(carrierID, carrier.unitDefID, carrierDef.drone, i )
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
end

function gadget:Initialize()  
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
