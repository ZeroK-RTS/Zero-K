
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
local airTransports = {
	[UnitDefNames["gunshiptrans"].id] = true,
	[UnitDefNames["gunshipheavytrans"].id] = true,
}

local lightTransport = {}
local allowTransportCache = {}
for unitDefID, _ in pairs(airTransports) do
	if UnitDefs[unitDefID].customParams.islighttransport then
		lightTransport[unitDefID] = true
		allowTransportCache[unitDefID] = {}
	end
end

local function DistSq(pos1, pos2)
	local difX = pos1[1] - pos2[1]
	local difY = pos1[2] - pos2[2]
	local difZ = pos1[3] - pos2[3]
	return difX^2 + difY^2 + difZ^2
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
	local pos1 = {Spring.GetUnitPosition(transporterID)}
	local pos2 = {goalX, goalY, goalZ}
	if DistSq(pos1, pos2) > 256 then
		return false
	end
	Spring.SetUnitVelocity(transporterID, 0,0,0)
	return true
end

function gadget:AllowUnitTransportUnload(transporterID, transporterUnitDefID, transporterTeam, transporteeID, transporteeUnitDefID, transporteeTeam, goalX, goalY, goalZ)
	if not airTransports[transporterUnitDefID] then
		return true
	end
	local pos1 = {Spring.GetUnitPosition(transporterID)}
	local pos2 = {goalX, goalY, goalZ}
	if DistSq(pos1, pos2) > 256 then
		return false
	end
	Spring.SetUnitVelocity(transporterID, 0,0,0)
	return true
end
