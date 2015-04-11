function widget:GetInfo() return {
	name	= "Unit Marker Zero-K",
	desc	= "[v1.3.10] Marks spotted buildings of interest and commander corpse.",
	author	= "Sprung",
	date	= "2015-04-11",
	license	= "GNU GPL v2",
	layer	= 0,
	enabled	= true,
} end

local knownUnits = {}
local unitList = {}

if VFS.FileExists("LuaUI/Configs/unit_marker_local.lua") then
	unitList = VFS.Include("LuaUI/Configs/unit_marker_local.lua")
else
	unitList = VFS.Include("LuaUI/Configs/unit_marker.lua")
end

function widget:Initialize()
	if Spring.GetSpectatingState() then
		widgetHandler:RemoveWidget()
		return
	end
end

function widget:PlayerChanged ()
	widget:Initialize ()
end

function widget:TeamDied ()
	widget:Initialize ()
end

function widget:UnitEnteredLos (unitID, unitTeam)
	if Spring.IsUnitAllied(unitID) then return end

	local unitDefID = Spring.GetUnitDefID (unitID)
	if not unitDefID then return end -- safety just in case

	if unitList[unitDefID] and ((not knownUnits[unitID]) or (knownUnits[unitID] ~= unitDefID)) then
		local x, y, z = Spring.GetUnitPosition(unitID)
		local markerText = unitList[unitDefID].markerText or UnitDefs[unitDefID].humanName
		if not unitList[unitDefID].mark_each_appearance then
			knownUnits[unitID] = unitDefID
		end
		if unitList[unitDefID].show_owner then
			local owner_name = Spring.GetPlayerInfo(select(2, Spring.GetTeamInfo(Spring.GetUnitTeam(unitID))))
			markerText = markerText .. " (" .. owner_name .. ")"
		end
		Spring.MarkerAddPoint (x, y, z, markerText, true)
	end
end

function widget:UnitDestroyed(unitID, unitDefID, unitTeam)
	knownUnits[unitID] = nil
end
