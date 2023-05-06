
function gadget:GetInfo()
	return {
		name = "Teleport handler API",
		desc = "Helps handle all the tricks required to move structures around.",
		author = "GoogleFrog",
		date = "6 May 2023",
		license = "GNU GPL, v2 or later",
		layer = 0,
		enabled = true
	}
end

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
if gadgetHandler:IsSyncedCode() then -- SYNCED
-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------

local function CallScript(unitID, funcName, args)
	local func = Spring.UnitScript.GetScriptEnv(unitID)
	if func then
		func = func[funcName]
		if func then
			return Spring.UnitScript.CallAsUnit(unitID, func, args)
		end
	end
	return false
end

function GG.MoveStructure(unitID, tx, tz)
	local unitDefID = Spring.GetUnitDefID(unitID)
	tx, tz = Spring.Utilities.SnapToBuildGrid(unitDefID, Spring.GetUnitBuildFacing(unitID), tx, tz)
	
	if GG.TerraformFunctions then
		GG.TerraformFunctions.StructureMoveSetup(unitID, unitDefID)
	end
	GG.Overdrive_MoveOrTransferSetup(unitID, unitDefID)
	
	Spring.SetUnitPosition(unitID, tx, tz)
	
	GG.Overdrive_MoveOrTransferAftermath(unitID, unitDefID)
	if GG.TerraformFunctions then
		GG.TerraformFunctions.StructureMoveAftermath(unitID, unitDefID)
	end
	
	SendToUnsynced("UnitStructureMoved", unitID, unitDefID, tx, tz)
end

function GG.MoveMobileUnit(unitID, tx, ty, tz)
	if not CallScript(unitID, "unit_teleported", {tx, ty, tz}) then
		Spring.SetUnitPosition(unitID, tx, tz)
		Spring.MoveCtrl.Enable(unitID)
		Spring.MoveCtrl.SetPosition(unitID, tx, ty, tz)
		Spring.MoveCtrl.Disable(unitID)
	end
end

function GG.MoveGeneralUnit(unitID, tx, ty, tz)
	local unitDefID = Spring.GetUnitDefID(unitID)
	local isMobile = Spring.Utilities.GetMovetypeUnitDefID(unitDefID)
	if isMobile then
		ty = ty or Spring.GetGroundHeight(tx, tz)
		GG.MoveMobileUnit(unitID, tx, ty, tz)
	else
		GG.MoveStructure(unitID, tx, tz)
	end
end

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
else -- UNSYNCED
-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------

local function UnitStructureMoved(unitID, unitDefID, tx, tz)
	if Script.LuaUI['UnitStructureMoved'] then
		Script.LuaUI.UnitStructureMoved(unitID, unitDefID, tx, tz)
	end
end

function gadget:Initialize()
	gadgetHandler:AddSyncAction("UnitStructureMoved", UnitStructureMoved)
end


-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
end -- END UNSYNCED
-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------