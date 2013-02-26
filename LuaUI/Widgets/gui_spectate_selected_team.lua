function widget:GetInfo()
  return {
    name     = "Spectate Selected Team",
    desc     = "Automatically spectate team base on selected units.",
    author   = "SirMaverick",
    date     = "2010", --2013
    license  = "GNU GPL, v2 or later",
    layer     = 0,
    enabled   = true
  }
end

local spGetUnitTeam = Spring.GetUnitTeam
local spSendCommands = Spring.SendCommands

local specOld = false
local spec = false
local team

local SelectNextPlayer = function() end

options_path = 'Settings/Interface/Spectating'
options_order = {'followNextPlayer','speviesel',}
options={
	followNextPlayer = {
		name = "Select Next Player",
		desc = "Quickly select next player. Is useful when spectating using COFC's Follow Player Cursor mode & when this button is hotkeyed.",
		type = 'button',
		OnChange = function(self) SelectNextPlayer() end, 
	},
	speviesel = {
		type='radioButton', 
		name='Spectator View Selection',
		items = {
			{name = 'View Chosen Player',key='viechopla', desc="Strictly using point-of-view of current player.", hotkey=nil},
			{name = 'View All',key='vieall', desc="Unlimited line-of-sight, but you can only select current player's unit.", hotkey=nil},
			{name = 'Select Any Unit',key='selanyuni', desc="Point-on-view of current player, and you can select any unit.", hotkey=nil},
			{name = 'View All & Select Any',key='vieallandselany', desc="Unlimited line-of-sight, and you can select any unit.", hotkey=nil},
		},
		value = 'vieallandselany',
		OnChange = function(self)
			local key = self.value
			if key == 'viechopla' then
				spSendCommands{"specfullview 0"}
			elseif key == 'vieall' then
				spSendCommands{"specfullview 1"}
			elseif key == 'selanyuni' then
				spSendCommands{"specfullview 2"}
			elseif key == 'vieallandselany' then
				spSendCommands{"specfullview 3"}
			end
		end,
	},
}
function widget:Initialize()
  specOld = spec
  spec = Spring.GetSpectatingState()
  if spec == false then
    widgetHandler:RemoveCallIn("SelectionChanged")
  end
end

function widget:PlayerChanged()
  specOld = spec
  spec = Spring.GetSpectatingState()
  if not spec and specOld then
    widgetHandler:RemoveCallIn("SelectionChanged")
  elseif spec and not specOld then
    widgetHandler:UpdateCallIn("SelectionChanged")
  end
end

function widget:SelectionChanged(selection)
  if selection and #selection > 0 then
    -- I cannot read users mind, use first unit
    team = spGetUnitTeam(selection[1])
    if team then
      spSendCommands("specteam "..team)
    end
  end
end
----------------------------------------------------
--SelectNextPlayer button (26.2.2013 by msafwan)----

SelectNextPlayer = function ()
	local currentTeam = Spring.GetLocalTeamID()
	local playerTableSortTeamID = Spring.GetPlayerRoster(2)
	local currentTeamIndex, firstPlayerIndex, teamIDIndexGoto
	for i=1, #playerTableSortTeamID do
		local teamID = playerTableSortTeamID[i][3]
		if currentTeam == teamID then --if current selection is this team:  mark this index
			currentTeamIndex = i
		end
		if teamID~= 0 and not firstPlayerIndex then --if spectator portion has finished: mark this index
			firstPlayerIndex = i-1 --(note: minus 1 to include teamID with 0, but note that all spectator has teamID 0 too)
		end
	end
	if currentTeamIndex and firstPlayerIndex then
		if currentTeamIndex < firstPlayerIndex then --if current selection is spectator: select random player
			teamIndexGoto = math.random(firstPlayerIndex,#playerTableSortTeamID)
		elseif currentTeamIndex < #playerTableSortTeamID then --if player list is still long: go to next index
			teamIndexGoto = currentTeamIndex + 1
		elseif currentTeamIndex == #playerTableSortTeamID then --if player list is at end: go to first index
			teamIndexGoto = firstPlayerIndex
		end
		if (options.speviesel.value == 'vieallandselany') then --if View & select all, then: 
			local teamsUnit = Spring.GetTeamUnits(playerTableSortTeamID[teamIndexGoto][3])
			if teamsUnit and teamsUnit[1] then
				Spring.SelectUnitArray({teamsUnit[math.random(1,#teamsUnit)],}) --select this player's unit
			end
			local selUnits = Spring.GetSelectedUnits()
			if selUnits and selUnits[1] then
				Spring.Echo("Spectating team: " .. playerTableSortTeamID[teamIndexGoto][1]) --player's name
			end
		else
			spSendCommands("specteam "..playerTableSortTeamID[teamIndexGoto][3])
			Spring.Echo("Spectating team: " .. playerTableSortTeamID[teamIndexGoto][1]) --player's name
		end
	end
end
