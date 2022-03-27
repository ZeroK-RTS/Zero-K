
function widget:GetInfo()
	return {
		name      = "Disable attack command",
		desc      = "Implements disable attack command",
		author    = "Google Frog",
		date      = "12 Janurary 2018",
		license   = "GNU GPL, v2 or later",
		layer     = -1,
    handler   = true,
		enabled   = true  --  loaded by default?
	}
end

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------

local attackDisabableUnitTypes = {}

for i = 1, #UnitDefs do
	local ud = UnitDefs[i]
	if ud.customParams.can_disable_attack then
		attackDisabableUnitTypes[i] = true
	end
end

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------

--include("LuaRules/Configs/customcmds.h.lua")

VFS.Include("LuaRules/Configs/customcmds.h.lua")
local CMD_ATTACK = CMD.ATTACK
local CMD_INSERT = CMD.INSERT

local unitBlockAttackCmd = {
	id      = CMD_DISABLE_ATTACK,
	type    = CMDTYPE.ICON_MODE,
	name    = 'Disable Attack',
	action  = 'disableattack',
	tooltip = 'Allow attack commands',
	params  = {0, 'Allowed', 'Blocked'}
}

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------

local attackDisabledUnits = {}

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Command Handling

function widget:GetSelectedUnits(units, cmdID, cmdParams, cmdOpts)
-- TODO: CMD_INSERT
	if cmdID ~= CMD_ATTACK then
    return
  end

	local selected = {}
	for i = 1, #units do
		if attackDisabledUnits[units[i]] ~= 1 then
			selected[#selected + 1] = units[i]
		end
	end

	return selected
end

function widget:CommandsChanged()
	local units = Spring.GetSelectedUnits()
	for i = 1, #units do
		if attackDisabledUnits[units[i]] then
			local customCommands = widgetHandler.customCommands
			customCommands[#customCommands+1] = {
				id      = CMD_DISABLE_ATTACK,
				type    = CMDTYPE.ICON_MODE,
				name    = 'Disable Attack',
				action  = 'disableattack',
				tooltip = 'Allow attack commands',
				params  = {attackDisabledUnits[units[i]], 'Allowed', 'Blocked'}
			}
      return
		end
	end
end

function widget:CommandNotify(cmdID, cmdParams, cmdOptions)
	if cmdID ~= CMD_DISABLE_ATTACK then
		return false
	end

	local units = Spring.GetSelectedUnits()
	for i = 1, #units do
		if attackDisabledUnits[units[i]] then
			attackDisabledUnits[units[i]] = cmdParams[1]
		end
	end

  return true
end

----------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------
-- Unit Handler

function widget:UnitCreated(unitID, unitDefID, teamID)
	if attackDisabableUnitTypes[unitDefID] then
		attackDisabledUnits[unitID] = 0
	end
end

function widget:UnitDestroyed(unitID, unitDefID)
	attackDisabledUnits[unitID] = nil
end

function widget:Initialize()
	for _, unitID in pairs(Spring.GetAllUnits()) do
		widget:UnitCreated(unitID, Spring.GetUnitDefID(unitID), Spring.GetUnitTeam(unitID))
	end
end
