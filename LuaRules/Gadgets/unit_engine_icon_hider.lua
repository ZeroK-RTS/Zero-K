function gadget:GetInfo()
	return {
		name    = "Engine Icon Hider",
		desc    = "Hides the engine unit icons while the Radar Icons GL4 widget draws them.",
		author  = "moss-orbit-9f339e",
		date    = "2026-11-24",
		license = "GNU GPL, v2 or later",
		layer   = 0,
		enabled = true,
	}
end

if gadgetHandler:IsSyncedCode() then
	return false
end

local spSetUnitIconDraw = Spring.SetUnitIconDraw
local spUnitIconGetDraw = Spring.UnitIconGetDraw
local spGetConfigInt    = Spring.GetConfigInt

local HIDE_ALL = 1
local HIDE_WORLD = 2 -- the engine minimap still draws its icons

local mode = 0
local hidden = false
local gameHidden = {}
local gameHiddenDefs = {}
if UnitDefNames.terraunit then
	gameHiddenDefs[UnitDefNames.terraunit.id] = true
end

local function HideUnit(unitID, unitDefID)
	if gameHiddenDefs[unitDefID] or spUnitIconGetDraw(unitID) == false then
		gameHidden[unitID] = true
		return
	end
	spSetUnitIconDraw(unitID, false)
end

local function SetHidden(hide)
	hidden = hide
	local units = Spring.GetAllUnits()
	for i = 1, #units do
		local unitID = units[i]
		if hide then
			HideUnit(unitID, Spring.GetUnitDefID(unitID))
		elseif not gameHidden[unitID] then
			spSetUnitIconDraw(unitID, true)
		end
	end
	if not hide then
		gameHidden = {}
	end
end

function gadget:Update()
	mode = spGetConfigInt("LuaRadarIcons", 0) -- Set by the widget, not saved.
	local wanted = (mode == HIDE_ALL)
	if wanted ~= hidden then
		SetHidden(wanted)
	end
end

function gadget:DrawWorld()
	if mode == HIDE_WORLD and not hidden then
		SetHidden(true)
	end
end

function gadget:DrawScreen()
	if mode == HIDE_WORLD and hidden then
		SetHidden(false)
	end
end

function gadget:UnitCreated(unitID, unitDefID)
	if hidden then
		HideUnit(unitID, unitDefID)
	end
end

function gadget:UnitDestroyed(unitID)
	gameHidden[unitID] = nil
end

function gadget:Shutdown()
	if hidden then
		SetHidden(false)
	end
end
