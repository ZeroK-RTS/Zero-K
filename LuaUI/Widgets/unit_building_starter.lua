-- $Id$

function widget:GetInfo()
	return {
		name      = "Building Starter",
		desc      = "v2 Hold Q to queue a building to be started and not continued.",
		author    = "Google Frog",
		date      = "Dec 13, 2008",
		license   = "GNU GPL, v2 or later",
		layer     = 5,
		enabled   = true  --  loaded by default?
	}
end

local buildings = {}
local numBuildings = 0

local team = Spring.GetMyTeamID()
include("keysym.h.lua")
local _, ToKeysyms = include("Configs/integral_menu_special_keys.lua")

local CMD_REMOVE = CMD.REMOVE

local buildingStartKey = KEYSYMS.Q
local function HotkeyChangeNotification()
	local key = WG.crude.GetHotkeyRaw("epic_building_starter_hotkey")
	buildingStartKey = ToKeysyms(key and key[1])
end

options_order = {'hotkey'}
options_path = 'Hotkeys/Construction'
options = {
	hotkey = {
		name = 'Place Nanoframes',
		desc = 'Hold this key during structure placement to queue structures which are to placed but not constructed.',
		type = 'button',
		hotkey = "Q",
		bindWithAny = true,
		dontRegisterAction = true,
		OnHotkeyChange = HotkeyChangeNotification,
		path = hotkeyPath,
	},
}

-- Speedups
local spGiveOrderToUnit = Spring.GiveOrderToUnit
local spGetTeamUnits = Spring.GetTeamUnits
local spGetCommandQueue = Spring.GetCommandQueue
local spGetUnitPosition = Spring.GetUnitPosition
local spGetKeyState = Spring.GetKeyState
local spGetSelectedUnits = Spring.GetSelectedUnits

local abs = math.abs

function widget:Initialize()
	 if (Spring.GetSpectatingState() or Spring.IsReplay()) and (not Spring.IsCheatingEnabled()) then
		Spring.Echo("<Building Starter>: disabled for spectators")
		widgetHandler:RemoveWidget()
	end
	HotkeyChangeNotification()
end

function widget:CommandNotify(id, params, options)
	if (id < 0) then
		local ux = params[1]
		local uz = params[3]
		if buildingStartKey and spGetKeyState(buildingStartKey) then
			buildings[numBuildings] = { x = ux, z = uz}
			numBuildings = numBuildings+1
		else
			for j, i in pairs(buildings) do
				if (i.x) then
					if (i.x == ux) and (i.z == uz) then
						buildings[j] = nil
					end
				end
			end
		end
	end
end

function CheckBuilding(ux,uz,ud)
	for _, i in pairs(buildings) do
		if (i.x) then
			if (abs(i.x - ux) < 16) and (abs(i.z - uz) < 16) then
				i.ud = ud
				return true
			end
		end
	end
	return false
end

function widget:UnitCreated(unitID, unitDefID, unitTeam)
	if (unitTeam ~= team) then 
		return
	end

	local units = spGetTeamUnits(team)
	local ux, uy, uz  = spGetUnitPosition(unitID)

	if CheckBuilding(ux,uz,unitID) then
		for _, unit_id in ipairs(units) do
			local cQueue = spGetCommandQueue(unit_id, 1)
			if cQueue and cQueue[1] then
				local command = cQueue[1]
				if command.id < 0 then 
					local cx = command.params[1]
					local cz = command.params[3]
					if (abs(cx-ux) < 16) and (abs(cz-uz) < 16) then
						spGiveOrderToUnit(unit_id, CMD_REMOVE, {command.tag}, 0 )
					end
				end
			end
		end
	end
end

function widget:UnitFinished(unitID, unitDefID, unitTeam)
	for j, i in ipairs(buildings) do
		if (i.ud) then
			buildings[j] = nil
		end
	end
end

function widget:UnitDestroyed(unitID, unitDefID, unitTeam)
	for j, i in pairs(buildings) do
		if (i.ud) then
			buildings[j] = nil
		end
	end
end
