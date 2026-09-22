
if  not(gadgetHandler:IsSyncedCode()) then
	return
end

function gadget:GetInfo()
	return {
		name = "Transport Load Unload",
		desc = "Sets up a constant 8 elmos load/unload radius for air transports and allows unload as soon as distance is reached (104.0.1 - maintenace 686+)",
		author = "Doo",
		date = "2018",
		license = "PD",
		layer = 0,
		enabled = true,
	}
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local airTransports = {}
local lightTransport = {}
local allowTransportCache = {}

local pickupDistSq = 16^2
local waitDistSq = 80^2

local waitTimer = {}
local waitTag = {}
local waiters = {}

for unitDefID, ud in pairs(UnitDefs) do
	if (ud.isTransport and ud.canFly) then
		airTransports[unitDefID] = true

		if ud.customParams.islighttransport then
			lightTransport[unitDefID] = true
			allowTransportCache[unitDefID] = {}
		end
	end
end

local function DistSq(x1, y1, z1, x2, y2, z2)
	return (x1 - x2)^2 + (y1 - y2)^2 + (z1 - z2)^2
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function gadget:AllowUnitTransport(transporterID, transporterUnitDefID, transporterTeam, transporteeID, transporteeUnitDefID, transporteeTeam)
	if not lightTransport[transporterUnitDefID] then
		return true
	end
	if allowTransportCache[transporterUnitDefID][transporteeUnitDefID] then
		return (allowTransportCache[transporterUnitDefID][transporteeUnitDefID] == 1)
	end
	local allowed = not UnitDefs[transporteeUnitDefID].customParams.requireheavytrans
	allowTransportCache[transporterUnitDefID][transporteeUnitDefID] = ((allowed and 1) or 0)
	return allowed
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function gadget:AllowUnitTransportLoad(transporterID, transporterUnitDefID, transporterTeam, transporteeID, transporteeUnitDefID, transporteeTeam, goalX, goalY, goalZ)
	if not airTransports[transporterUnitDefID] then
		return true
	end
	local x, y, z = Spring.GetUnitPosition(transporterID)
	local isAlly = (Spring.GetUnitAllyTeam(transporterID) == Spring.GetUnitAllyTeam(transporteeID))
	local distSq = DistSq(x, y, z, goalX, goalY, goalZ)
	if distSq > pickupDistSq then
		if isAlly and distSq < waitDistSq then
			local cmdID = Spring.GetUnitCurrentCommand(transporteeID)
			if cmdID ~= CMD.WAIT and not waitTag[transporteeID] then
				Spring.GiveOrderToUnit(transporteeID, CMD.WAIT, {}, {})
				local cmdID2, _, cmdTag = Spring.GetUnitCurrentCommand(transporteeID)
				if cmdID2 == CMD.WAIT then
					waitTimer[transporteeID] = 2
					waitTag[transporteeID] = cmdTag
					waiters[#waiters + 1] = transporteeID
				end
			end
		end
		return false
	end
	if not isAlly then
		local _,_,_,speed = Spring.GetUnitVelocity(transporteeID)
		if speed > 0.5 then
			return false
		elseif speed > 0.05 then
			-- Allow floating units, Placeholder, etc... to be picked up
			local ux, uy, uz = Spring.GetUnitPosition(transporteeID)
			local ground = Spring.GetGroundHeight(ux, uz)
			if uy < ground + 1 then
				return false
			end
		end
	end
	Spring.SetUnitVelocity(transporterID, 0, 0, 0)
	return true
end

function gadget:AllowUnitTransportUnload(transporterID, transporterUnitDefID, transporterTeam, transporteeID, transporteeUnitDefID, transporteeTeam, goalX, goalY, goalZ)
	if not airTransports[transporterUnitDefID] then
		return true
	end
	local x, y, z = Spring.GetUnitPosition(transporteeID)
	if DistSq(x, y, z, goalX, goalY, goalZ) > 144 then
		if DistSq(x, 0, z, goalX, 0, goalZ) <= 64 then
			local _,_,_,speed = Spring.GetUnitVelocity(transporterID)
			if speed > 0.25 then
				return false
			end
		else
			return false
		end
	end
	Spring.SetUnitVelocity(transporterID, 0,0,0)
	return true
end

function gadget:GameFrame(n)
	if (#waiters == 0) or (n%16 ~= 0) then
		return
	end
	for i = #waiters, 1, -1 do
		local unitID = waiters[i]
		if (waitTimer[unitID] or 0) > 1 then
			waitTimer[unitID] = waitTimer[unitID] - 1
		else
			if Spring.ValidUnitID(unitID) then
				local cmdID, _, cmdTag = Spring.GetUnitCurrentCommand(unitID)
				if cmdID == CMD.WAIT and cmdTag == waitTag[unitID] then
					Spring.GiveOrderToUnit(unitID, CMD.REMOVE, cmdTag, 0)
				end
			end
			waitTag[unitID] = nil
			waitTimer[unitID] = nil
			waiters[i] = waiters[#waiters]
			waiters[#waiters] = nil
		end
	end
end
