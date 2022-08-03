
function widget:GetInfo()
	return {
		name      = "Disable attack command",
		desc      = "Implements disable attack command",
		author    = "Google Frog",
		date      = "12 Janurary 2018",
		license   = "GNU GPL, v2 or later",
		layer     = -100,
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

VFS.Include("LuaRules/Configs/customcmds.h.lua")
local CMD_ATTACK = CMD.ATTACK
local CMD_INSERT = CMD.INSERT
local CMD_MANUALFIRE = CMD.MANUALFIRE

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------

local attackDisabledUnits = {}

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Command Handling
function SetDisableAttack(unit, value)
	if attackDisabledUnits[unit] then
		attackDisabledUnits[unit] = value
	end
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
		-- TODO: handle commands imbeded in CMD_INSERT though it dosen't seem to need it.
		if cmdID ~= CMD_ATTACK and cmdID ~= CMD_UNIT_SET_TARGET and cmdID ~= CMD_UNIT_SET_TARGET_CIRCLE then
			return
		end

		local units = WG.units or Spring.GetSelectedUnits()
		local selected = {}
		for i = 1, #units do
			if attackDisabledUnits[units[i]] ~= 1 then
				selected[#selected + 1] = units[i]
			end
		end

		WG.units = selected
		return
	end

	local units = WG.units or Spring.GetSelectedUnits()

	for i = 1, #units do
		SetDisableAttack(units[i], cmdParams[1])
	end

	return true
end

function widget:UnitCommandNotify(unitID, id, params, options)
	if id ~= CMD_MANUALFIRE then
		return false
	end

	if attackDisabledUnits[unitID] then
		Spring.GiveOrderToUnit(unitID, CMD_ATTACK, params, options)
		return true
	end
	return false
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

	WG.CmdDisableAttack = {
		FilterSelectedUnits = FilterSelectedUnits,
		SetDisableAttack = SetDisableAttack
	}
end
