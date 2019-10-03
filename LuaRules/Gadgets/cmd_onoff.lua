--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
if not gadgetHandler:IsSyncedCode() then
	return
end
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function gadget:GetInfo()
	return {
		name      = "On/Off",
		desc      = "Implemented wanted On/Off command",
		author    = "GoogleFrog",
		date      = "1 September, 2019",
		license   = "GNU GPL, v2 or later",
		layer     = 1, -- After weapon_impulse
		enabled   = true  --  loaded by default?
	}
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

include("LuaRules/Configs/customcmds.h.lua")

local CMD_ONOFF = CMD.ONOFF

local wantOnOffCmdDesc = {
	id      = CMD_WANT_ONOFF,
	type    = CMDTYPE.ICON_MODE,
	name    = 'Cloak State',
	action  = 'wantonoff',
	tooltip = 'Unit activation state',
	params  = {0, 'Off', 'On'}
}

local pushPullCmdDesc = {
	id      = CMD_PUSH_PULL,
	type    = CMDTYPE.ICON_MODE,
	name    = 'Push / Pull',
	action  = 'pushpull',
	tooltip = 'Toggles whether gravity weapons push or pull',
	params  = {0, 'Push','Pull'}
}

local spFindUnitCmdDesc   = Spring.FindUnitCmdDesc
local spEditUnitCmdDesc   = Spring.EditUnitCmdDesc
local spInsertUnitCmdDesc = Spring.InsertUnitCmdDesc
local spRemoveUnitCmdDesc = Spring.RemoveUnitCmdDesc
local spGiveOrderToUnit   = Spring.GiveOrderToUnit

local function IsImpulseUnit(ud)
	for _, w in pairs(ud.weapons) do
		local wd = WeaponDefs[w.weaponDef]
		if wd and wd.customParams and wd.customParams.impulse then
			return true
		end
	end
	return false
end

local onOffUnits = {}
local cmdDescUnits = {}
for i = 1,#UnitDefs do
	local ud = UnitDefs[i]
	if ud.onOffable then
		onOffUnits[i] = ((ud.activateWhenBuilt and 1) or 0)
		if IsImpulseUnit(ud) then
			cmdDescUnits[i] = pushPullCmdDesc
		else
			cmdDescUnits[i] = wantOnOffCmdDesc
		end
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Vars

local unitWantedState = {}
local lastCommandWantedState = {}

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Command Handling

local function OnOffToggleCommand(unitID, unitDefID, instantCommand, state, fromCommand)
	if not onOffUnits[unitDefID] then
		return
	end
	local cmdDescID = spFindUnitCmdDesc(unitID, cmdDescUnits[unitDefID].id)
	if not cmdDescID then
		return
	end
	
	if state then
		if state ~= unitWantedState[unitID] then
			unitWantedState[unitID] = state
			cmdDescUnits[unitDefID].params[1] = state
			spEditUnitCmdDesc(unitID, cmdDescID, {params = cmdDescUnits[unitDefID].params})
		end
	else
		state = unitWantedState[unitID]
	end
	
	if fromCommand then
		lastCommandWantedState[unitID] = state
	end
	
	if state then
		if instantCommand then
			spGiveOrderToUnit(unitID, CMD_ONOFF, {state, CMD_WANT_ONOFF}, 0)
		elseif GG.DelegateOrder then
			GG.DelegateOrder(unitID, CMD_ONOFF, {state, CMD_WANT_ONOFF}, 0)
		end
	end
end
GG.OnOffToggleCommand = OnOffToggleCommand

function gadget:AllowCommand_GetWantedCommand()
	return {[CMD_WANT_ONOFF] = true, [CMD_PUSH_PULL] = true, [CMD_ONOFF] = true}
end

function gadget:AllowCommand_GetWantedUnitDefID()
	return onOffUnits
end

function gadget:AllowCommand(unitID, unitDefID, teamID, cmdID, cmdParams, cmdOptions)
	if (cmdID == CMD_ONOFF) then
		return (cmdParams[2] == CMD_WANT_ONOFF) -- we block any on/off that we didn't call ourselves
	end
	if (cmdID ~= CMD_WANT_ONOFF) and (cmdID ~= CMD_PUSH_PULL) then
		return true  -- command was not used
	end
	OnOffToggleCommand(unitID, unitDefID, false, cmdParams[1], true)
	return false  -- command was used
end

local function OnOff_GetWantedState(unitID)
	return unitID and (unitWantedState[unitID] == 1)
end
GG.OnOff_GetWantedState = OnOff_GetWantedState

local function OnOff_GetLastCommandWantedState(unitID)
	return unitID and (lastCommandWantedState[unitID] == 1)
end
GG.OnOff_GetLastCommandWantedState = OnOff_GetLastCommandWantedState

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function gadget:UnitDestroyed(unitID, unitDefID, unitTeam)
	if onOffUnits[unitDefID] then
		unitWantedState[unitID] = nil
		lastCommandWantedState[unitID] = nil
	end
end

function gadget:UnitFinished(unitID, unitDefID, teamID)
	if not onOffUnits[unitDefID] then
		return
	end
	OnOffToggleCommand(unitID, unitDefID, true)
end

function gadget:UnitCreated(unitID, unitDefID, teamID)
	if not onOffUnits[unitDefID] then
		return
	end

	local onoffDescID = spFindUnitCmdDesc(unitID, CMD_ONOFF)
	if onoffDescID then
		spRemoveUnitCmdDesc(unitID, onoffDescID)
	end
	spInsertUnitCmdDesc(unitID, cmdDescUnits[unitDefID])
	OnOffToggleCommand(unitID, unitDefID, false, onOffUnits[unitDefID], true)
end

function gadget:Initialize()
	-- load active units
	for _, unitID in ipairs(Spring.GetAllUnits()) do
		local unitDefID = Spring.GetUnitDefID(unitID)
		gadget:UnitCreated(unitID, unitDefID)
	end
end
