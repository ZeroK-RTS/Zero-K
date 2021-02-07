
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
	if DistSq(x, y, z, goalX, goalY, goalZ) > 256 then
		return false
	end
	if Spring.GetUnitAllyTeam(transporterID) ~= Spring.GetUnitAllyTeam(transporteeID) then
		local _,_,_,speed = Spring.GetUnitVelocity(transporteeID)
		if speed > 0.5 then
			-- Allow for floating, Crab uncurl, Placeholder, etc.
			return false
		end
	end
	Spring.SetUnitVelocity(transporterID, 0,0,0)
	return true
end

function gadget:AllowUnitTransportUnload(transporterID, transporterUnitDefID, transporterTeam, transporteeID, transporteeUnitDefID, transporteeTeam, goalX, goalY, goalZ)
	if not airTransports[transporterUnitDefID] then
		return true
	end
	local x, y, z = Spring.GetUnitPosition(transporteeID)
	if DistSq(x, y, z, goalX, goalY, goalZ) > 256 then
		return false
	end
	Spring.SetUnitVelocity(transporterID, 0,0,0)
	return true
end
