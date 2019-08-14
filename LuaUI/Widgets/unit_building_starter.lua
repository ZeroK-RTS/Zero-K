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

local buildings = {}	-- {[1] = {x = posX, z = posZ, ud = unitID}}	-- unitID is only set when building is created
local toClear = {}	-- {[1] = {x = posX, z = posZ, unitID = unitID}}	-- entries created in UnitCreated, iterated in GameFrame
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
local spGetUnitCurrentCommand = Spring.GetUnitCurrentCommand
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
	for index, i in pairs(buildings) do
		if (i.x) then
			if (abs(i.x - ux) < 16) and (abs(i.z - uz) < 16) then
				i.ud = ud
				return true
			end
		end
	end
	return false
end

function widget:GameFrame(f)
	if f % 2 ~= 1 then
		return
	end
	
	local newClear = {}
	for i=1,#toClear do
		local entry = toClear[i]
		-- minimum progress requirement is there because otherwise a con can start multiple nanoframes in one gameframe
		-- (probably as many as it can reach, in fact)
		local health, _, _, _, buildProgress = Spring.GetUnitHealth(entry.unitID)
		if health and health > 3 then
		--if buildProgress > 0.01 then
			local ux, uz = entry.x, entry.z
			local units = spGetTeamUnits(team)
			for _, unit_id in ipairs(units) do
				local cmdID, cmdOpt, cmdTag, cx, cy, cz = spGetUnitCurrentCommand(unit_id)
				if cmdID and cmdID < 0 then
					if (abs(cx-ux) < 16) and (abs(cz-uz) < 16) then
						spGiveOrderToUnit(unit_id, CMD_REMOVE, {cmdTag}, 0 )
					end
				end
			end
		else
			newClear[#newClear + 1] = entry
		end
	end
	toClear = newClear
end

function widget:UnitCreated(unitID, unitDefID, unitTeam)
	if (unitTeam ~= team) then
		return
	end
	local ux, uy, uz  = spGetUnitPosition(unitID)
	
	local check = CheckBuilding(ux,uz,unitID)
	if check then
		toClear[#toClear + 1] = {unitID = unitID, x = ux, z = uz}
	end
end

function widget:UnitFinished(unitID, unitDefID, unitTeam)
	for j, i in pairs(buildings) do
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
