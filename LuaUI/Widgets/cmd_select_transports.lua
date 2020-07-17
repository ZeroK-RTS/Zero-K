function widget:GetInfo()
	return {
		name      = "Hotkeys for Transport Selection",
		desc      = "Adds some common selection hotkeys that can be bound via Integral Menu",
		author    = "Shaman",
		date      = "July 7, 2020",
		license   = "CC-0",
		layer     = 0,
		enabled   = true,
	}
end

local charonID = UnitDefNames["gunshiptrans"].id
local hercID = UnitDefNames["gunshipheavytrans"].id

local spGetSelectedUnits = Spring.GetSelectedUnits
local spSelectUnitArray = Spring.SelectUnitArray
local spGetUnitIsTransporting = Spring.GetUnitIsTransporting
local spGetUnitDefID = Spring.GetUnitDefID
local spGetTeamUnitsByDefs = Spring.GetTeamUnitsByDefs
local spGetMyTeamID = Spring.GetMyTeamID
local spGetModKeyState = Spring.GetModKeyState

local function IsTransporting(unitID)
	local transported = spGetUnitIsTransporting(unitID)
	if transported ~= nil and #transported > 0 then
		return true
	else
		return false
	end
end


local function FilterTransports(wanted)
	local selection = Spring.GetSelectedUnits()
	local newselection = {}
	for i = 1, #selection do
		local unitDefID = spGetUnitDefID(selection[i])
		if (unitDefID == charonID or unitDefID == hercID) and wanted == "unloaded" and IsTransporting(selection[i]) == false then
			newselection[#newselection+1] = selection[i]
		elseif (unitDefID == charonID or unitDefID == hercID) and wanted == "loaded" and IsTransporting(selection[i]) then
			newselection[#newselection+1] = selection[i]
		end
	end
	spSelectUnitArray(newselection,false)
end

-- Set up selection hotkeys
options = {
	selectfulltransports = { type = 'button',
		name = 'Select Full Transports',
		desc = 'Selects all full transports.',
		action = 'selectfulltransports',
		path = 'Hotkeys/Selection',
		dontRegisterAction = true,
	},
	selectemptytransports = { type = 'button',
		name = 'Select Empty Transports',
		desc = 'Selects all empty transports.',
		action = 'selectemptytransports',
		path = 'Hotkeys/Selection',
		dontRegisterAction = true,
	},
	filteremptytransports = { type = 'button',
		name = 'Only loaded transports',
		desc = 'Removes all units that arent loaded transports from the current selection.',
		action = 'filteremptytransports',
		path = 'Hotkeys/Selection',
		dontRegisterAction = true,
	},
	filterfulltransports = { type = 'button',
		name = 'Only unloaded transports',
		desc = 'Removes all units that arent unloaded transports from the current selection.',
		action = 'filterfulltransports',
		path = 'Hotkeys/Selection',
		dontRegisterAction = true,
	},
}
options_path = 'Hotkeys/selection/'
options_order = {
	'selectfulltransports',
	'selectemptytransports',
	'filterfulltransports',
	'filteremptytransports',
}

local function FilterFullTransports()
	FilterTransports("loaded")
end

local function FilterEmptyTransports()
	FilterTransports("unloaded")
end

local function SelectFullTransports()
	local _,_,_,addselect = spGetModKeyState()
	local alltrans = spGetTeamUnitsByDefs(spGetMyTeamID(),charonID)
	local allheavytrans = spGetTeamUnitsByDefs(spGetMyTeamID(),hercID)
	local newselection = {}
	for i=1, #alltrans do
		if IsTransporting(alltrans[i]) == true then
			newselection[#newselection+1] = alltrans[i]
		end
	end
	for i=1, #allheavytrans do
		if IsTransporting(allheavytrans[i]) == true then
			newselection[#newselection+1] = allheavytrans[i]
		end
	end
	spSelectUnitArray(newselection,addselect)
end

local function SelectEmptyTransports()
	local _,_,_,addselect = spGetModKeyState()
	local alltrans = spGetTeamUnitsByDefs(spGetMyTeamID(),charonID)
	local allheavytrans = spGetTeamUnitsByDefs(spGetMyTeamID(),hercID)
	local newselection = {}
	for i=1, #alltrans do
		if IsTransporting(alltrans[i]) == false then
			newselection[#newselection+1] = alltrans[i]
		end
	end
	for i=1, #allheavytrans do
		if IsTransporting(allheavytrans[i]) == false then
			newselection[#newselection+1] = allheavytrans[i]
		end
	end
	spSelectUnitArray(newselection,addselect)
end

function widget:Shutdown()
	widgetHandler:RemoveAction("selectfulltransports")
	widgetHandler:RemoveAction("selectemptytransports")
	widgetHandler:RemoveAction("filteremptytransports")
	widgetHandler:RemoveAction("filterfulltransports")
end

function widget:Initialize()
	widgetHandler:AddAction("selectemptytransports", SelectEmptyTransports, nil, 'tp')
	widgetHandler:AddAction("selectfulltransports", SelectFullTransports, nil, 'tp')
	widgetHandler:AddAction("filteremptytransports", FilterEmptyTransports, nil, 'tp')
	widgetHandler:AddAction("filterfulltransports", FilterFullTransports, nil, 'tp')
end
