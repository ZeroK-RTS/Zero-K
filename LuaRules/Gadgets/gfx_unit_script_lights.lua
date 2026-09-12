local gadget = gadget ---@type Gadget

function gadget:GetInfo()
	return {
		name = "Unit Script Lights and Distortion",
		desc = "Forwards Lighting Events to Widgets from COB Unit scripts",
		author = "Beherith",
		date = "Apr, 2008",
		license = "GNU GPL, v2 or later",
		layer = 0,
		enabled = true,
	}
end

if gadgetHandler:IsSyncedCode() then
	local SendToUnsynced = SendToUnsynced

	local uniqueParam = 0
	local function GetNextParam()
		uniqueParam = uniqueParam + 1
		return uniqueParam
	end

	function GG.UnitScriptLight(unitID, unitDefID, lightIndex, param)
		--Spring.Echo("Synced Gadget UnitScriptLight", unitID, unitDefID, lightIndex, param)
		param = param or GetNextParam()
		SendToUnsynced("cob_UnitScriptLight", unitID, unitDefID, lightIndex, param)
	end

	function GG.UnitScriptDistortion(unitID, unitDefID, lightIndex, param)
		--Spring.Echo("Synced Gadget UnitScriptDistortion", unitID, unitDefID, lightIndex, param)
		param = param or GetNextParam()
		SendToUnsynced("cob_UnitScriptDistortion", unitID, unitDefID, lightIndex, param)
	end
else -- UNSYNCED
	local myAllyTeamID = Spring.GetLocalAllyTeamID()
	local myPlayerID = Spring.GetLocalPlayerID()
	local mySpec, fullview = Spring.GetSpectatingState()
	local spIsUnitInLos = Spring.IsUnitInLos

	function gadget:PlayerChanged(playerID)
		if playerID == myPlayerID then
			myAllyTeamID = Spring.GetLocalAllyTeamID()
			mySpec, fullview = Spring.GetSpectatingState()
		end
	end

	local function UnitScriptLight(_, unitID, unitDefID, lightIndex, param)
		if not fullview and not spIsUnitInLos(unitID, myAllyTeamID) then
			return
		end
		--Spring.Echo("Unsynced UnitScriptLight", unitID, unitDefID, lightIndex, param)
		if Script.LuaUI("UnitScriptLight") then
			Script.LuaUI.UnitScriptLight(unitID, unitDefID, lightIndex, param)
		end
	end

	local function UnitScriptDistortion(_, unitID, unitDefID, lightIndex, param)
		if not fullview and not spIsUnitInLos(unitID, myAllyTeamID) then
			return
		end
		--Spring.Echo("Unsynced UnitScriptDistortion", unitID, unitDefID, lightIndex, param)
		if Script.LuaUI("UnitScriptDistortion") then
			Script.LuaUI.UnitScriptDistortion(unitID, unitDefID, lightIndex, param)
		end
	end

	function gadget:Initialize()
		gadgetHandler:AddSyncAction("cob_UnitScriptLight", UnitScriptLight)
		gadgetHandler:AddSyncAction("cob_UnitScriptDistortion", UnitScriptDistortion)
	end

	function gadget:Shutdown()
		gadgetHandler:RemoveSyncAction("cob_UnitScriptLight")
		gadgetHandler:RemoveSyncAction("cob_UnitScriptDistortion")
	end
end
