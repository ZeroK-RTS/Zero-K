-- $Id$
  


function widget:GetInfo()
  return {
    name      = "Show All Commands",
    desc      = "Acts like CTRL-A SHIFT all the time",
    author    = "Google Frog",
    date      = "Mar 1, 2009",
    license   = "GNU GPL, v2 or later",
    layer     = 0,
    enabled   = false  --  loaded by default?
  }
end

local spDrawUnitCommands = Spring.DrawUnitCommands
local spGetAllUnits = Spring.GetAllUnits
local spSendLuaRulesMsg = Spring.SendLuaRulesMsg
local spIsGUIHidden = Spring.IsGUIHidden
local spGetModKeyState = Spring.GetModKeyState
local spIsUnitSelected = Spring.IsUnitSelected

local drawUnits = {}

options_path = 'Settings/Interface/Command Visibility'
options_order = { 'showonlyonshift'}
options = {
	
	showonlyonshift = {
		name = 'Show only on shift',
		type = 'bool',
		value = false,
		--OnChange = function() Spring.SendCommands{'showhealthbars'} end,
	},
}

function widget:DrawWorld()

	if not spIsGUIHidden()  then
		for i, v in pairs(drawUnits) do
			if i and (not options.showonlyonshift.value or select(4,spGetModKeyState()) or (spIsUnitSelected(i) and true)) then
				spDrawUnitCommands(i)
			end
		end
	end
end

function widget:UnitCreated(unitID)
	drawUnits[unitID] = true
end

function widget:UnitGiven(unitID, unitDefID, oldTeam, newTeam)
	drawUnits[unitID] = true
end

function widget:UnitDestroyed(unitID)
	if (drawUnits[unitID]) then
		drawUnits[unitID] = nil
	end
end

function widget:GameFrame(n)
	if (n == 1) then
		local units = spGetAllUnits()
  
		for i, id in pairs(units) do
			widget:UnitCreated(id)
		end
	end
end

function widget:Initialize()
    spSendLuaRulesMsg("target_on_the_move_draw_always")
	local units = spGetAllUnits()
	for i, id in pairs(units) do
		widget:UnitCreated(id)
	end
end

function widget:Shutdown()
    spSendLuaRulesMsg("target_on_the_move_draw_normal")
end

