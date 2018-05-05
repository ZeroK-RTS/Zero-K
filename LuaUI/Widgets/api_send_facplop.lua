function widget:GetInfo() return {
	name        = "Record facplop",
	layer       = 1,
	enabled     = true,
	alwaysStart = true,
} end

local myTeamID = Spring.GetLocalTeamID()
function widget:Initialize()
	if Spring.GetSpectatingState() then
		widgetHandler:RemoveWidget()
	end
end

VFS.Include("LuaRules/Configs/start_setup.lua", nil, VFS.GAME)
function widget:UnitCreated(unitID, unitDefID, teamID)
	if teamID ~= myTeamID or not ploppableDefs[unitDefID] then
		return
	end

	local str = "SPRINGIE:facplop," .. UnitDefs[unitDefID].name .. "," .. myTeamID .. "," .. select(6, Spring.GetTeamInfo(myTeamID)) .. "," .. Spring.GetPlayerInfo(Spring.GetLocalPlayerID()) .. ",END_PLOP"
	Spring.SendCommands("wbynum 255 " .. str)
	widgetHandler:RemoveWidget()
end
