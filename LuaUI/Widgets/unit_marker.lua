function widget:GetInfo() return {
	name    = "Unit Marker Zero-K",
	desc    = "[v1.4.0] Marks spotted buildings of interest and commander corpse. Updates location and build progress.",
	author  = "Sprung, rollmops",
	date    = "2015-04-11",
	license = "GNU GPL v2",
	layer   = -1,
	enabled = true,
} end


local unitList
local activeDefID = {}

-- associative arrays, where keys are 'unitID's, to save the position and the text of the last marker of a given unit.
local lastMarkerText = {}
local lastPos = {}

-- since issuing spMarkerErasePosition (to remove the old marker) and then spMarkerAddPoint (to make a new marker)
-- doesn't seem to work in cases where location is not changed (the new marker disappears after less than 1 second, I
-- think it is somehow related to both commands being processed in the same drawing frame?), I made an ugly hack,
-- namely, after spMarkerErasePosition, I defer the creation of the new marker: the text and the position of the new
-- marker are stored in markersToMake, (keys are again 'unitID's), then the script counts 'frames_defer' game frames,
-- and only then spMarkerAddPoint is issued.
local markersToMake = {}
local frames_defer = 15

local markingActive = false

local spGetAIInfo           = Spring.GetAIInfo
local spGetPlayerInfo       = Spring.GetPlayerInfo
local spGetSpectatingState  = Spring.GetSpectatingState
local spGetTeamInfo         = Spring.GetTeamInfo
local spGetUnitDefID        = Spring.GetUnitDefID
local spGetUnitHealth       = Spring.GetUnitHealth
local spGetUnitPosition     = Spring.GetUnitPosition
local spIsUnitAllied        = Spring.IsUnitAllied
local spMarkerAddPoint      = Spring.MarkerAddPoint
local spMarkerErasePosition = Spring.MarkerErasePosition
local sputGetHumanName      = Spring.Utilities.GetHumanName

-- for additional feature: for markers of building in progress, add the game time at which the specified building progress was spotted
local spGetGameSeconds = Spring.GetGameSeconds

if VFS.FileExists("LuaUI/Configs/unit_marker_local.lua", nil, VFS.RAW) then
	unitList = VFS.Include("LuaUI/Configs/unit_marker_local.lua", nil, VFS.RAW)
else
	unitList = VFS.Include("LuaUI/Configs/unit_marker.lua")
end

options_path = 'Settings/Interface/Unit Marker'

options_order = { 'enableAll', 'disableAll', 'unitslabel'}
options = {
	enableAll = {
		type='button',
		name= "Enable All",
		desc = "Marks all listed units.",
		path = options_path .. "/Presets",
		OnChange = function ()
			for i = 1, #options_order do
				local opt = options_order[i]
				local find = string.find(opt, "_mark")
				local name = find and string.sub(opt,0,find-1)
				local ud = name and UnitDefNames[name]
				if ud then
					options[opt].value = true
				end
			end
			for unitDefID in pairs(unitList) do
				activeDefID[unitDefID] = true
			end
			if not markingActive then
				widgetHandler:UpdateCallIn('UnitEnteredLos')
				markingActive = true
			end
		end,
		noHotkey = true,
	},
	disableAll = {
		type='button',
		name= "Disable All",
		desc = "Mark nothing.",
		path = options_path .. "/Presets",
		OnChange = function ()
			for i = 1, #options_order do
				local opt = options_order[i]
				local find = string.find(opt, "_mark")
				local name = find and string.sub(opt,0,find-1)
				local ud = name and UnitDefNames[name]
				if ud then
					options[opt].value = false
				end
			end
			for unitDefID,_ in pairs(unitList) do
				activeDefID[unitDefID] = false
			end
			if markingActive then
				widgetHandler:RemoveCallIn('UnitEnteredLos')
				markingActive = false
			end
		end,
		noHotkey = true,
	},
	unitslabel = {name = "unitslabel", type = 'label', value = "Individual Toggles", path = options_path},
}

for unitDefID in pairs(unitList) do
	local ud = UnitDefs[unitDefID]
	options[ud.name .. "_mark"] = {
		name = "  " .. sputGetHumanName(ud) or "",
		type = 'bool',
		value = false,
		OnChange = function (self)
			activeDefID[unitDefID] = self.value
			if self.value and not markingActive then
				widgetHandler:UpdateCallIn('UnitEnteredLos')
				markingActive = true
			end
		end,
		noHotkey = true,
	}
	options_order[#options_order+1] = ud.name .. "_mark"
end

local function refreshCallin()
	if not markingActive then
		widgetHandler:RemoveCallIn("UnitEnteredLos")
	end
	if spGetSpectatingState() then
		widgetHandler:RemoveCallIn("UnitEnteredLos")
	elseif markingActive then
		widgetHandler:UpdateCallIn('UnitEnteredLos')
	end
end

widget.PlayerChanged = refreshCallin
widget.Initialize = refreshCallin
widget.TeamDied = refreshCallin

function widget:UnitEnteredLos (unitID, teamID)
	if spIsUnitAllied(unitID) or spGetSpectatingState() then
		return
	end

	local unitDefID = spGetUnitDefID (unitID)
	if not unitDefID or not activeDefID[unitDefID] then
		return
	end

	local data = unitList[unitDefID]
	if not data then
		return
	end

	local markerText = data.markerText or sputGetHumanName(UnitDefs[unitDefID])
	if data.show_owner then
		local _,playerID,_,isAI = spGetTeamInfo(teamID, false)
		local owner_name
		if isAI then
			local _,botName,_,botType = spGetAIInfo(teamID)
			owner_name = (botType or "AI") .." - " .. (botName or "unnamed")
		else
			owner_name = spGetPlayerInfo(playerID, false) or "nobody"
		end
		markerText = markerText .. " (" .. owner_name .. ")"
	end

	local _, _, _, _, buildProgress = spGetUnitHealth(unitID)
	if buildProgress < 1 then
		markerText = markerText .. " (" .. math.floor(100 * buildProgress) .. "% at " ..  os.date( "%M:%S", spGetGameSeconds()) .. ")"
	end

	local x, y, z = spGetUnitPosition(unitID)

	-- if there were no markers issued for the given unitID, make a marker immediately
	if not lastMarkerText[unitID] then
		spMarkerAddPoint (x, y, z, markerText, true)

	-- if there was a marker, but the text of it or the location of the unit has changed, remove the existing marker and save the details of the new marker, which will be actually made after 'frames_defer' game frames, see widget:GameFrame below).
	elseif markerText ~= lastMarkerText[unitID] or x ~= lastPos[unitID][1] or y ~= lastPos[unitID][2] or z ~= lastPos[unitID][3] then
		spMarkerErasePosition(lastPos[unitID][1], lastPos[unitID][2], lastPos[unitID][3])
		markersToMake[unitID] = { x, y, z, markerText, frames_defer }
	end

	-- save the text and position of the marker as last known.
	lastPos[unitID] = {x, y, z}
	lastMarkerText[unitID] = markerText
end

-- each game frame, loop over all the deferred markers and decrease their deferment counters. For a maker that its counter reached zero, issue marker command and remove its details from markersToMake
function widget:GameFrame()
	for u, m in pairs(markersToMake) do
		if m[5] > 0 then
			markersToMake[u][5] = markersToMake[u][5] - 1
		else
			spMarkerAddPoint ( m[1], m[2], m[3], m[4], true)
			markersToMake[u] = nil
		end
	end
end

-- if a unit destroyed, remove both actual and deferred markers and all the related info.
function widget:UnitDestroyed(unitID, unitDefID, unitTeam)
	markersToMake[unitID] = nil
	lastMarkerText[unitID] = nil
	if lastPos[unitID] then
		spMarkerErasePosition(lastPos[unitID][1], lastPos[unitID][2], lastPos[unitID][3])
	end
	lastPos[unitID] = nil
end
