if not gadgetHandler:IsSyncedCode() then return end

function gadget:GetInfo()
	return {
		name = "Manualfire Description",
		desc = "Sets custom descriptions for units manualfire commands",
		author = "GoogleFrog",
		date = "16 November 2023",
		license  = "GNU GPL, v2 or later",
		layer = -1,
		enabled = false
	}
end

local manualFireDesc = {}
for i = 1, #UnitDefs do
	local ud = UnitDefs[i]
	if ud.customParams.manualfire_desc then
		manualFireDesc[i] = ud.customParams.manualfire_desc
	end
end

GG.DEFAULT_MANUALFIRE_DESC = "Fire Special Weapon: Fire the unit's special weapon."

function gadget:UnitCreated(unitID, unitDefID)
	local cmdDecsIndex = Spring.FindUnitCmdDesc(unitID, CMD.MANUALFIRE)
	if not cmdDecsIndex then
		return
	end
	local cmdDesc = Spring.GetUnitCmdDescs(unitID, cmdDecsIndex, cmdDecsIndex)
	cmdDesc = cmdDesc and cmdDesc[1]
	if not cmdDesc then
		return
	end
	cmdDesc.tooltip = manualFireDesc[unitDefID] or GG.DEFAULT_MANUALFIRE_DESC
	Spring.Utilities.UnitEcho(unitID, "EditUnitCmdDesc")
	Spring.Utilities.TableEcho(cmdDesc)
	Spring.EditUnitCmdDesc(unitID,  CMD.MANUALFIRE, cmdDesc)
end
