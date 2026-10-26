-- This file is part of Zero-K (GPL v2 or later), see LICENSE.
-- Resolve membership at the point of use: moving through a portal invalidates
-- cached spatial links even when their ordinary update timer has not elapsed.
local function UnitRegion(id)
	local portal = gadgetHandler and gadgetHandler.GG and gadgetHandler.GG.PortalWorlds
	if not portal or type(id) ~= "number" then
		return
	end
	if portal.home[id] then
		return portal.home[id]
	end
	local x, _, z = Spring.GetUnitPosition(id)
	return portal.Region(x, z)
end

function Spring.Utilities.IsSamePortalRegion(first, second)
	if not (gadgetHandler and gadgetHandler.GG and gadgetHandler.GG.PortalWorlds) then
		return true
	end
	local region = UnitRegion(first)
	return region ~= nil and region == UnitRegion(second)
end

function Spring.Utilities.IsPortalPositionAllowed(unitID, x, z)
	local portal = gadgetHandler and gadgetHandler.GG and gadgetHandler.GG.PortalWorlds
	if not portal then
		return true
	end
	local region = UnitRegion(unitID)
	return region ~= nil and region == portal.Region(x, z)
end

function Spring.Utilities.IsSamePortalPosition(x, z, otherX, otherZ)
	local portal = gadgetHandler and gadgetHandler.GG and gadgetHandler.GG.PortalWorlds
	if not portal then
		return true
	end
	local region = portal.Region(x, z)
	return region ~= nil and region == portal.Region(otherX, otherZ)
end
