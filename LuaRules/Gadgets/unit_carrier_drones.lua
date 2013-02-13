-- $Id: unit_carrier_drones.lua 3291 2008-11-25 00:36:20Z licho $
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
--  file:    unit_carrier_drones.lua
--  brief:   Spawns drones for aircraft carriers
--  author:  
--
--  Copyright (C) 2007.
--  Licensed under the terms of the GNU GPL, v2 or later.
--
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function gadget:GetInfo()
  return {
    name      = "CarrierDrones",
    desc      = "Spawns drones for aircraft carriers",
    author    = "TheFatConroller, modified by KingRaptor",
    date      = "12.01.2008",
    license   = "GNU GPL, v2 or later",
    layer     = 0,
    enabled   = true  --  loaded by default?
  }
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

-- SYNCED CODE
if (not gadgetHandler:IsSyncedCode()) then
  return
end


--Speed-ups

local GetUnitPosition   = Spring.GetUnitPosition
local CreateUnit        = Spring.CreateUnit
local AddUnitDamage     = Spring.AddUnitDamage
local GiveOrderToUnit   = Spring.GiveOrderToUnit
local GetCommandQueue   = Spring.GetCommandQueue
local SetUnitPosition   = Spring.SetUnitPosition
local SetUnitNoSelect   = Spring.SetUnitNoSelect
local random            = math.random
local CMD_ATTACK		= CMD.ATTACK

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local carrierDefs = include "LuaRules/Configs/drone_defs.lua"

local DEFAULT_UPDATE_ORDER_FREQUENCY = 60	-- gameframes
local DEFAULT_MAX_DRONE_RANGE = 1500

local carrierList = {}
local droneList = {}

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local function InitCarrier(unitDefID, teamID)
	local carrierData = carrierDefs[unitDefID]
	local toReturn  = {unitDefID = unitDefID, teamID = teamID, droneSets = {}}
	for i=1,#carrierData do
		toReturn.droneSets[i] = Spring.Utilities.CopyTable(carrierData[i])
		toReturn.droneSets[i].reload = toReturn.droneSets[i].reloadTime
		toReturn.droneSets[i].droneCount = 0
		toReturn.droneSets[i].drones = {}
		--Spring.Echo("new drone set",i)
	end
	return toReturn
end

local function NewDrone(unitID, unitDefID, droneName, setNum)
	local _, _, _, x, y, z = GetUnitPosition(unitID, true)
	local angle = math.rad(random(1,360))
	local xS = (x + (math.sin(angle) * 20))
	local zS = (z + (math.cos(angle) * 20))
	local droneID = CreateUnit(droneName,x,y,z,1,carrierList[unitID].teamID)
	local droneSet = carrierList[unitID].droneSets[setNum]
	droneSet.reload = carrierDefs[unitDefID][setNum].reloadTime
	droneSet.droneCount = droneSet.droneCount + 1
	droneSet.drones[droneID] = true
	
	SetUnitPosition(droneID, xS, zS, true)
	GiveOrderToUnit(droneID, CMD.MOVE_STATE, { 2 }, {})
	GiveOrderToUnit(droneID, CMD.IDLEMODE, { 0 }, {})
	--GiveOrderToUnit(droneID, CMD.AUTOREPAIRLEVEL, { 3 }, {})
	GiveOrderToUnit(droneID, CMD.FIGHT,	{(x + (random(0,600) - 300)), 60, (z + (random(0,600) - 300))}, {""})
	GiveOrderToUnit(droneID, CMD.GUARD, {unitID} , {"shift"})
		
	SetUnitNoSelect(droneID,true)
	
	droneList[droneID] = {carrier = unitID, set = setNum}
end

function gadget:UnitDestroyed(unitID, unitDefID, unitTeam)
	if (carrierList[unitID]) then
		local carrier = carrierList[unitID]
		for i=1,#carrier.droneSets do
			local set = carrier.droneSets[i]
			for droneID in pairs(set.drones) do
				droneList[droneID] = nil
				AddUnitDamage(droneID,1000)
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
		carrierList[unitID] = InitCarrier(unitDefID, unitTeam)
	end
end


function gadget:AllowUnitTransfer(unitID, unitDefID, oldTeam, newTeam, capture)
	if carrierList[unitID] then
		carrierList[unitID].teamID = newTeam
	end
	return true
end

local function GetDistance(x1, x2, y1, y2)
	return ((x1-x2)^2 + (y1-y2)^2)^0.5
end

local function UpdateCarrierTarget(carrierID)
	local cQueueC = GetCommandQueue(carrierID, 1)
	if cQueueC and cQueueC[1] and cQueueC[1].id == CMD_ATTACK then
		local ox,oy,oz = GetUnitPosition(carrierID)
		local params = cQueueC[1].params
		local px,py,pz
		if #params == 1 then
			px,py,pz = Spring.GetUnitPosition(params[1])
		else
			px,py,pz = unpack(params)
		end
		if not px then 
			return 
		end
		-- check range
		local dist = GetDistance(ox,px,oz,pz)
		
		
		for i=1,#carrierList[carrierID].droneSets do
			local set = carrierList[carrierID].droneSets[i]
			if dist < set.range then
				for droneID in pairs(set.drones) do
					--[[
					local cQueue = GetCommandQueue(droneID, 1)
					local engaged = false
					if cQueue and cQueue[1] and cQueue[1].id == CMD_ATTACK then
						engaged = true
					end
					]]--
					--if not engaged then
						--Spring.Echo("Ordering drone " .. droneID .. " to attack")
					droneList[droneID] = nil	-- to keep AllowCommand from blocking the order
					GiveOrderToUnit(droneID, CMD.FIGHT, {(px + (random(0,200) - 100)), (py+120), (pz + (random(0,200) - 100))} , {""})
					GiveOrderToUnit(droneID, CMD.GUARD, {carrierID} , {"shift"})
					droneList[droneID] = {carrier = carrierID, set = i}
					--end
				end
			end
		end
	else
		for i=1,#carrierList[carrierID].droneSets do
			local set = carrierList[carrierID].droneSets[i]
			for droneID in pairs(set.drones) do
				local cQueue = GetCommandQueue(droneID)
				local engaged = false
				for i=1, (cQueue and #cQueue or 0) do
					if cQueue[i].id == CMD.FIGHT then
						engaged = true
						break
					end
				end
				if not engaged then
					local px,py,pz = GetUnitPosition(carrierID)
					droneList[droneID] = nil	-- to keep AllowCommand from blocking the order
					GiveOrderToUnit(droneID, CMD.FIGHT, {(px + (random(0,200) - 100)), (py+120), (pz + (random(0,200) - 100))} , {""})
					GiveOrderToUnit(droneID, CMD.GUARD, {carrierID} , {"shift"})
					droneList[droneID] = {carrier = carrierID, set = i}
				end
			end
		end
	end
end

function gadget:AllowCommand(unitID, unitDefID, teamID, cmdID, cmdParams, cmdOptions)
	if (droneList[unitID] ~= nil) then
		return false
	else
		return true
	end
end

--[[
function gadget:UnitCommand(unitID, unitDefID, teamID, cmdID, cmdParams, cmdOptions)
	if (carrierList[unitID]) then
		UpdateCarrierTarget(unitID)
	end
end
]]--

function gadget:GameFrame(n)
	if (((n+1) % 30) < 0.1) then
		for carrierID, carrier in pairs(carrierList) do
			--Spring.Echo("alpha", carrierID)
			for i=1,#carrier.droneSets do
				--Spring.Echo("bravo", carrierID, i)
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
	if ((n % DEFAULT_UPDATE_ORDER_FREQUENCY) < 0.1) then
		for i,_ in pairs(carrierList) do
			UpdateCarrierTarget(i)
		end
	end
end

function gadget:Initialize()
	for _, unitID in ipairs(Spring.GetAllUnits()) do
		local _,_,_,_,build  = Spring.GetUnitHealth(unitID)
		if build == 1 then
			local unitDefID = Spring.GetUnitDefID(unitID)
			local team = Spring.GetUnitTeam(unitID)
			
			gadget:UnitFinished(unitID, unitDefID, team)
		end
	end
end

--[[
function gadget:Initialize()
	for udid,data in pairs(carrierDefs) do
		if data.weapon then
			Script.SetWatchWeapon(WeaponDefNames[data.weapon].id)
		end
	end
end
]]--
  
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
