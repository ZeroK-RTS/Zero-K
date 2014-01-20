-- $Id$
function widget:GetInfo()
  return {
    name      = "Show All Commands v2",
    desc      = "Provide ZK Epicmenu with Command visibility options. Go to \255\90\255\90Setting/ Interface/ Command Visibility\255\255\255\255 for options.", --"Acts like CTRL-A SHIFT all the time",
    author    = "Google Frog, msafwan",
    date      = "Mar 1, 2009, July 1 2013",
    license   = "GNU GPL, v2 or later",
    layer     = 0,
    enabled   = true  --  loaded by default?
  }
end
--Changelog:
--July 1 2013 (msafwan add chili radiobutton and new options!)
--NOTE: this options will behave correctly if "alwaysDrawQueue == 0" in cmdcolors.txt

local spDrawUnitCommands = Spring.DrawUnitCommands
local spGetAllUnits = Spring.GetAllUnits
local spSendLuaRulesMsg = Spring.SendLuaRulesMsg
local spIsGUIHidden = Spring.IsGUIHidden
local spGetModKeyState = Spring.GetModKeyState
local spIsUnitSelected = Spring.IsUnitSelected

local drawUnits = {}
local commandLevel = 1 --default at start of widget is to be disabled!

options_path = 'Settings/Interface/Command Visibility'
options_order = { 
'showallcommandselection','lblincludeallies','includeallies', 
}
options = {
	showallcommandselection = {
		type='radioButton', 
		name='Commands are drawn for',
		items = {
			{name = 'All units',key='showallcommand', desc="Command always drawn on all units.", hotkey=nil},
			{name = 'Selected units, All with SHIFT',key='onlyselection', desc="Command always drawn on selected unit, pressing SHIFT will draw it for all units.", hotkey=nil},
			{name = 'Selected units',key='onlyselectionlow', desc="Command always drawn on selected unit.", hotkey=nil},
			{name = 'All units with SHIFT',key='showallonshift', desc="Commands always hidden, but pressing SHIFT will draw it for all units.", hotkey=nil},
			{name = 'Selected units on SHIFT',key='showminimal', desc="Commands always hidden, pressing SHIFT will draw it on selected units.", hotkey=nil},
		},
		value = 'showminimal',  --default at start of widget is to be disabled!
		OnChange = function(self)
			local key = self.value
			if key == 'onlyselectionlow' then
				commandLevel = 5
				spSendLuaRulesMsg("target_move_selectionlow")
			elseif key == 'showallcommand' then
				commandLevel = 4
				spSendLuaRulesMsg("target_move_all")
			elseif key == 'onlyselection' then
				commandLevel = 3
				spSendLuaRulesMsg("target_move_selection")
			elseif key == 'showallonshift' then
				commandLevel = 2
				spSendLuaRulesMsg("target_move_shift")
			elseif key == 'showminimal' then
				commandLevel = 1
				spSendLuaRulesMsg("target_move_minimal")
			end
		end,
	},
	lblincludeallies = {name='Allies', type='label'},
	includeallies = {
		name = 'Include ally selections',
		desc = 'When showing commands for selected units, show them for both your own and your allies\' selections.',
		type = 'bool',
		value = false,
	},
}
-----
function widget:Update()
	if not spIsGUIHidden()  then
		for i, v in pairs(drawUnits) do
			if i then
				local shift = select(4,spGetModKeyState())
				
				if
				(commandLevel==4) or --all
				(commandLevel==2 and shift) or --shift
				(commandLevel==3 and (spIsUnitSelected(i) or (options.includeallies.value and WG.allySelUnits[i]) or shift )  ) or --selection/shift
				(commandLevel==5 and (spIsUnitSelected(i) or (options.includeallies.value and WG.allySelUnits[i]) )           ) or --selection
				(commandLevel==1 and (spIsUnitSelected(i) or (options.includeallies.value and WG.allySelUnits[i]) ) and shift )    --minimal, but with allies
				then 
					spDrawUnitCommands(i)
				end
				
			end
		end
	end
end

function PoolUnit()
	local units = spGetAllUnits()
	for i, id in pairs(units) do
		drawUnits[id] = true
	end
end
------
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
-----
function widget:GameFrame(n)
	if (n > 0) then
		PoolUnit()
		widgetHandler:RemoveCallIn("GameFrame") 
	end
end

-- function widget:Initialize()
    -- spSendLuaRulesMsg("target_on_the_move_all")
-- end

function widget:Shutdown()
    spSendLuaRulesMsg("target_move_minimal")
end
