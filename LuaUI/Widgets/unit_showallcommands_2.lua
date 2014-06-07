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
local spGetUnitAllyTeam = Spring.GetUnitAllyTeam
local spGetSelectedUnits = Spring.GetSelectedUnits

local selectedUnitCount = 0
local selectedUnits 

local drawUnit = {count = 0, data = {}}
local drawUnitID = {}

local commandLevel = 1 --default at start of widget is to be disabled!

local myAllyTeamID = Spring.GetLocalAllyTeamID()
local spectating = Spring.GetSpectatingState()
local myPlayerID = Spring.GetLocalPlayerID()

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
local function UpdateSelection(newSelectedUnits)
	selectedUnitCount = #newSelectedUnits
	selectedUnits = newSelectedUnits
end


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
			if key == 'showallcommand' then
				commandLevel = 5
				spSendLuaRulesMsg("target_move_all")
			elseif key == 'onlyselection' then
				commandLevel = 4
				spSendLuaRulesMsg("target_move_selection")
				UpdateSelection(spGetSelectedUnits())
			elseif key == 'onlyselectionlow' then
				commandLevel = 3
				spSendLuaRulesMsg("target_move_selectionlow")
				UpdateSelection(spGetSelectedUnits())
			elseif key == 'showallonshift' then
				commandLevel = 2
				spSendLuaRulesMsg("target_move_shift")
				UpdateSelection(spGetSelectedUnits())
			elseif key == 'showminimal' then
				commandLevel = 1
				spSendLuaRulesMsg("target_move_minimal")
				UpdateSelection(spGetSelectedUnits())
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

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local function AddUnit(unitID)
	if not drawUnitID[unitID] then
		if spectating or spGetUnitAllyTeam(unitID) == myAllyTeamID then
			local list = drawUnit
			list.count = list.count + 1
			list.data[list.count] = unitID
			drawUnitID[unitID] = list.count
		end
	end
end

local function RemoveUnit(unitID)
	if drawUnitID[unitID] then
		local index = drawUnitID[unitID]
		local list = drawUnit
		list.data[index] = list.data[list.count]
		drawUnitID[list.data[index]] = index
		list.data[list.count] = nil
		list.count = list.count - 1
		drawUnitID[unitID] = nil
	end
end

local function GetDrawLevel()
	local shift = select(4,spGetModKeyState())
	if commandLevel == 1 then
		return shift, false
	elseif commandLevel == 2 then
		return false, shift
	elseif commandLevel == 3 then
		return true, false
	elseif commandLevel == 4 then
		return true, shift
	else -- commandLevel == 5
		return true, true
	end
end


function widget:Update()
	if not spIsGUIHidden()  then
		local drawSelected, drawAll = GetDrawLevel(commandLevel, shift)
		if drawAll then
			local count = drawUnit.count
			local units = drawUnit.data
			for i = 1, count do
				spDrawUnitCommands(units[i])
			end
		elseif drawSelected then
			local sel = selectedUnits
			for i = 1, selectedUnitCount do
				spDrawUnitCommands(sel[i])
			end
			if options.includeallies.value then
				local count = drawUnit.count
				local units = drawUnit.data
				for i = 1, count do
					local unitID = units[i]
					if WG.allySelUnits[unitID] then
						spDrawUnitCommands(unitID)
					end
				end
			end
		end
	end
end


function widget:SelectionChanged(newSelection)
	if commandLevel ~= 5 then
		UpdateSelection(newSelection)
	end
end

function PoolUnit()
	local units = spGetAllUnits()
	for _, unitID in ipairs(units) do
		AddUnit(unitID)
	end
end

------
function widget:PlayerChanged(playerID) 
	if myPlayerID == playerID then
		spectating = Spring.GetSpectatingState()
		allyTeamID = Spring.GetLocalAllyTeamID()
		PoolUnit()
	end
end

function widget:UnitCreated(unitID, unitDefID, unitTeam)
	AddUnit(unitID)
end

function widget:UnitGiven(unitID, unitDefID, oldTeam, newTeam)
	AddUnit(unitID)
end

function widget:UnitDestroyed(unitID)
	RemoveUnit(unitID)
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
