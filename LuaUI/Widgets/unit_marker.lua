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
local unitList = {}

local markingActive = false

if VFS.FileExists("LuaUI/Configs/unit_marker_local.lua") then
	unitList = VFS.Include("LuaUI/Configs/unit_marker_local.lua")
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
			for unitDefID,_ in pairs(unitList) do
				unitList[unitDefID].active = true
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
				unitList[unitDefID].active = false
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

for unitDefID,_ in pairs(unitList) do
	local ud = (not unitDefID) or UnitDefs[unitDefID]
	if ud then
		options[ud.name .. "_mark"] = {
			name = "  " .. Spring.Utilities.GetHumanName(ud) or "",
			type = 'bool',
			value = false,
			OnChange = function (self)
				unitList[unitDefID].active = self.value
				if self.value and not markingActive then
					widgetHandler:UpdateCallIn('UnitEnteredLos')
					markingActive = true
				end
			end,
			noHotkey = true,
		}
		options_order[#options_order+1] = ud.name .. "_mark"
	end
end

function widget:Initialize()
	if not markingActive then
		widgetHandler:RemoveCallIn("UnitEnteredLos")
	end
	if Spring.GetSpectatingState() then
		widgetHandler:RemoveCallIn("UnitEnteredLos")
	elseif markingActive then
		widgetHandler:UpdateCallIn('UnitEnteredLos')
	end
end

function widget:PlayerChanged ()
	widget:Initialize ()
end

function widget:TeamDied ()
	widget:Initialize ()
end

function widget:UnitEnteredLos (unitID, teamID)
	if Spring.IsUnitAllied(unitID) or Spring.GetSpectatingState() then return end

	local unitDefID = Spring.GetUnitDefID (unitID)
	if not unitDefID then return end -- safety just in case

	if unitList[unitDefID] and unitList[unitDefID].active and ((not knownUnits[unitID]) or (knownUnits[unitID] ~= unitDefID)) then
		local x, y, z = Spring.GetUnitPosition(unitID)
		local markerText = unitList[unitDefID].markerText or Spring.Utilities.GetHumanName(UnitDefs[unitDefID])
		if not unitList[unitDefID].mark_each_appearance then
			knownUnits[unitID] = unitDefID
		end
		if unitList[unitDefID].show_owner then
			local _,playerID,_,isAI = Spring.GetTeamInfo(teamID, false)
			local owner_name
			if isAI then
				local _,botName,_,botType = Spring.GetAIInfo(teamID)
				owner_name = (botType or "AI") .." - " .. (botName or "unnamed")
			else
				owner_name = Spring.GetPlayerInfo(playerID, false) or "nobody"
			end

			markerText = markerText .. " (" .. owner_name .. ")"
		end
		Spring.MarkerAddPoint (x, y, z, markerText, true)
	end
end

function widget:UnitDestroyed(unitID, unitDefID, unitTeam)
	knownUnits[unitID] = nil
end
