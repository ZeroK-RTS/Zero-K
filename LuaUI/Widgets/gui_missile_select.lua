--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
  return {
    name      = "Missile Selection",
    desc      = "Selects nearby missiles.",
    author    = "Histidine",
    date      = "2018.07.25",
    license   = "CC-0",
    layer     = 0,
    enabled   = true,
    handler   = true,
  }
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
VFS.Include("LuaRules/Configs/customcmds.h.lua")

local SEARCH_RANGE = 96

local siloDefID = UnitDefNames.staticmissilesilo.id

local missileDefIDs = {}
local missileNames = {"tacnuke", "seismic", "empmissile", "napalmmissile"}

for i=1,#missileNames do
  if UnitDefNames[missileNames[i]] then
	missileDefIDs[UnitDefNames[missileNames[i]].id] = true
  end
end

local selectMissilesCmdDesc = {
	id      = CMD_SELECT_MISSILES,
	type    = CMDTYPE.ICON,
	name    = 'Select Missiles',
	action  = 'selectmissiles',
	tooltip = 'Select all missiles close to this silo.',
	texture = "LuaUI/Images/Commands/Bold/missile.png",
	params  = {}
}

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
local toSelect = nil

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:CommandsChanged()
	local selectedUnits = Spring.GetSelectedUnits()
	local unitID = selectedUnits and selectedUnits[1]
	local unitDefID = unitID and Spring.GetUnitDefID(unitID)
	if unitDefID == siloDefID then
	  local customCommands = widgetHandler.customCommands
	  table.insert(customCommands, selectMissilesCmdDesc)
	end
end

function widget:UnitCommand(unitID, unitDefID, unitTeam, cmdID, cmdParams, cmdOpts)
	if cmdID ~= CMD_SELECT_MISSILES then 
		return false
	end
	if unitDefID ~= siloDefID then
		return false
	end
	
	toSelect = toSelect or {}
	local x, y, z = Spring.GetUnitPosition(unitID)
	local units = Spring.GetUnitsInRectangle(x - SEARCH_RANGE, z - SEARCH_RANGE, x + SEARCH_RANGE, z + SEARCH_RANGE)
	for i=1,#units do
		local unitID = units[i]
		local unitDefID = Spring.GetUnitDefID(unitID)
		if unitDefID and missileDefIDs[unitDefID] then
		  toSelect[#toSelect + 1] = unitID
		end
	end
end

function widget:Update()
  if toSelect ~= nil then
	local alt, ctrl, meta, shift = Spring.GetModKeyState()
	Spring.SelectUnitArray(toSelect, shift)
	toSelect = nil
  end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
