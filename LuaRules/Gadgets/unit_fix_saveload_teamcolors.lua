if gadgetHandler:IsSyncedCode() then
	return false
end

function gadget:GetInfo() return {
	name    = "Default unit palette",
	desc    = "Set unit default color at load (unsynced since Recoil 2026.07)",
	author  = "Sprung",
	date    = "2026-09-24",
	license = "PD",
	layer   = math.huge, -- after any other palette gadgetry
	enabled = Spring.SetUnitPaletteIndex ~= nil,
} end

function gadget:Initialize()
	local units = Spring.GetAllUnits()
	for i = 1, #units do
		local unitID = units[i]
		if not Spring.GetUnitPaletteIndex(unitID) then
			Spring.SetUnitPaletteIndex(unitID, nil)
		end
	end
end
