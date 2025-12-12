--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
if gadgetHandler:IsSyncedCode() then
	return
end
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function gadget:GetInfo()
	return {
		name      = "Retexture Custom Param",
		desc      = "Implements cp.override_tex1 and cp.override_tex2.",
		author    = "GoogleFrog",
		date      = "12 December 2025",
		license   = "GNU GPL, v2 or later",
		layer     = 0,
		enabled   = true,  --  loaded by default?
	}
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local tex1UnitDefIDs = {}
local tex2UnitDefIDs = {}
for i = 1, #UnitDefs do
	local ud = UnitDefs[i]
	local tex1 = ud.customParams.override_tex1
	local tex2 = ud.customParams.override_tex2
	if tex1 then
		tex1UnitDefIDs[i] = tex1
	end
	if tex2 then
		tex2UnitDefIDs[i] = tex2
	end
end

function gadget:UnitCreated(unitID, unitDefID)
	if not (tex1UnitDefIDs[unitDefID] or tex2UnitDefIDs[unitDefID]) then
		return
	end
	local tex1 = tex1UnitDefIDs[unitDefID]
	local tex2 = tex2UnitDefIDs[unitDefID]
	if tex1 then
		tex1 = "unittextures/" .. tex1
	end
	if tex2 then
		tex2 = "unittextures/" .. tex2
	end
	if GG.CUSGL4 and GG.CUSGL4.SetUnitTexture then
		GG.CUSGL4.SetUnitTexture(unitID, tex1, tex2)
	end
end

function gadget:Initialize()
	for _, unitID in ipairs(Spring.GetAllUnits()) do
		local unitDefID = Spring.GetUnitDefID(unitID)
		gadget:UnitCreated(unitID, unitDefID)
	end
end
