--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
  return {
    name      = "ResetState",
    desc      = 'v2.01 Set hotkeys for "holdfire,stop" and "holdposition,stop" in the menu',
    author    = "CarRepairer",
    date      = "2009-01-27",
    license   = "GNU GPL, v2 or later",
    layer     = -1,
	handler	= true,
    enabled   = true,
  }
end


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local CMD_RESETFIRE = 10003
local CMD_RESETMOVE = 10004


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:CommandsChanged()
	for _, unitID in ipairs( Spring.GetSelectedUnits() ) do
		--local ud = UnitDefs[Spring.GetUnitDefID(unitID)]
		table.insert(widgetHandler.customCommands, {
			id      = CMD_RESETFIRE,
			name	= 'Hold Fire & Stop',
			type    = CMDTYPE.ICON,
			tooltip = 'Hold fire and stop.',
			action  = 'resetfire',
			params  = { }, 
			pos = {CMD_MOVE_STATE,CMD_FIRE_STATE, }, 
		})

		table.insert(widgetHandler.customCommands, {
			id      = CMD_RESETMOVE,
			name	= 'Hold Pos & Stop',
			type    = CMDTYPE.ICON,
			tooltip = 'Hold position and stop.',
			action  = 'resetmove',
			params  = { }, 
			pos = {CMD_MOVE_STATE,CMD_FIRE_STATE, }, 
		})

	
	end
end

function widget:CommandNotify(cmdID, cmdParams, cmdOptions)
	if cmdID == CMD_RESETFIRE then
		Spring.GiveOrder(CMD.FIRE_STATE, {0}, {}) 
		Spring.GiveOrder(CMD.STOP, {}, {})
		return true
	elseif cmdID == CMD_RESETMOVE then
		Spring.GiveOrder(CMD.MOVE_STATE, { 0 }, {})
		Spring.GiveOrder(CMD.STOP, {}, {})
		return true
	end
end


function widget:Initialize()
	if Spring.GetSpectatingState() or Spring.IsReplay() then
		widgetHandler:RemoveWidget()
		return true
	end	
end
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
