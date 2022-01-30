if not gadgetHandler:IsSyncedCode() then return end

function gadget:GetInfo()
	return {
		name    = "Structure death flatten fix",
		desc    = "Remove engine structure terraform to fix post-nuke 'foundation' remains.",
		author  = "GoogleFrog",
		date    = "1 Jan 2022",
		license = "GNU GPL, v2 or later",
		layer   = 0,
		enabled = true
	}
end

function gadget:UnitCreated(unitID, unitDefID)
	-- Terraform gadget already deals with structures restoring themselves to their original heights after
	-- explosions. Unlike engine restoration it does this with an infrequent poll, so hitting bewteen nuke
	-- crater and nuke damage is unlikely.
	if Spring.ValidUnitID(unitID) then
		local b1, b2, b3, b4, b5, b6, b7 = Spring.GetUnitBlocking(unitID)
		Spring.SetUnitBlocking(unitID, b1, b2, b3, b4, b5, b6, false)
	end
end
