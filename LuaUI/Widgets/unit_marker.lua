function widget:GetInfo() return {
	name    = "Unit Marker Zero-K",
	desc    = "[v1.3.10] Marks spotted buildings of interest and commander corpse.",
	author  = "Sprung",
	date    = "2015-04-11",
	license = "GNU GPL v2",
	layer   = -1,
	enabled = true,
} end

local knownUnits = {}
local unitList
local activeDefID = {}

local markingActive = false

local sp = Spring
local spGetAIInfo          = sp.GetAIInfo
local spGetPlayerInfo      = sp.GetPlayerInfo
local spGetSpectatingState = sp.GetSpectatingState
local spGetTeamInfo        = sp.GetTeamInfo
local spGetUnitDefID       = sp.GetUnitDefID
local spGetUnitHealth      = sp.GetUnitHealth
local spGetUnitPosition    = sp.GetUnitPosition
local spIsUnitAllied       = sp.IsUnitAllied
local spMarkerAddPoint     = sp.MarkerAddPoint
local sputGetHumanName     = sp.Utilities.GetHumanName

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
	if not data or knownUnits[unitID] == unitDefID then
		return
	end

	local markerText = data.markerText or sputGetHumanName(UnitDefs[unitDefID])

	if not data.mark_each_appearance then
		knownUnits[unitID] = unitDefID
	end

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
		markerText = markerText .. " (" .. math.floor(100 * buildProgress) .. "%)"
	end

	local x, y, z = spGetUnitPosition(unitID)
	spMarkerAddPoint (x, y, z, markerText, true)
end

function widget:UnitDestroyed(unitID, unitDefID, unitTeam)
	knownUnits[unitID] = nil
end
