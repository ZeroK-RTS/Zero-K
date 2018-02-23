function gadget:GetInfo()
	return {
		name      = "Transportability",
		desc      = "Controls the transportability of units.",
		author    = "GoogleFrog",
		date      = "24 February 2018",
		license   = "GNU GPL, v2 or later",
		layer     = 0,
		enabled   = false
	}
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local lightTransportable = {}
for i = 1, #UnitDefs do
	local ud = UnitDefs[i]
	if ud.customParams.light_transportable then
		lightTransportable[i] = true
	end
end

local lightTransport = {}
for i = 1, #UnitDefs do
	local ud = UnitDefs[i]
	if ud.customParams.transportcost then
		lightTransport[i] = true
	end
end

--SYNCED
if (not gadgetHandler:IsSyncedCode()) then
   return false
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function gadget:AllowUnitTransport(transporterID, transporterUnitDefID, transporterTeam, transporteeID, transporteeUnitDefID, transporteeTeam)
	if lightTransport[transporterUnitDefID] and not lightTransportable[transporteeUnitDefID] then
		return false
	end
	return true
end