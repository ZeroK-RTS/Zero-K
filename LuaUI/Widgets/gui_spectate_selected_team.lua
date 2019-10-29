function widget:GetInfo()
  return {
    name     = "Spectate Selected Team",
    desc     = "Automatically spectate team based on selected units, and other spectate options.",
    author   = "SirMaverick",
    version  = "0.205", --has added options
    date     = "2010", --2013
    license  = "GNU GPL, v2 or later",
    layer     = 0,
    enabled   = true
  }
end

local spGetUnitTeam = Spring.GetUnitTeam
local spGetMyTeamID = Spring.GetMyTeamID
local spSendCommands = Spring.SendCommands

local specOld = false
local spec = false
local team

local SelectNextPlayer = function() end

options_path = 'Settings/Interface/Spectating'
options_order = {'followNextPlayer','specviewselection',}
options={
	followNextPlayer = {
		name = "Select Next Player",
		desc = "Quickly select next player. Is useful when spectating using COFC's Follow Player Cursor mode & when this button is hotkeyed.",
		type = 'button',
		OnChange = function(self) SelectNextPlayer() end,
	},
	specviewselection = {
		type='radioButton',
		name='Spectator View Selection',
		items = {
			{name = 'View Chosen Player',key='viewchosenplayer', desc="Point of view of current player, and you can only select the current player's units.", hotkey=nil},
			{name = 'View All',key='viewall', desc="Unlimited line of sight, but you can only select current player's units.", hotkey=nil},
			{name = 'Select Any Unit',key='selectanyunit', desc="Point of view of current player, and you can select any unit.", hotkey=nil},
			{name = 'View All & Select Any',key='viewallselectany', desc="Unlimited line of sight, and you can select any unit.", hotkey=nil},
		},
		value = 'viewallselectany',
		OnChange = function(self)
			local key = self.value
			if key == 'viewchosenplayer' then
				spSendCommands{"specfullview 0"}
			elseif key == 'viewall' then
				spSendCommands{"specfullview 1"}
			elseif key == 'selectanyunit' then
				spSendCommands{"specfullview 2"}
			elseif key == 'viewallselectany' then
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
    local lastTeam = spGetMyTeamID()
    if team and team ~= lastTeam then
      spSendCommands("specteam "..team)
    end
  end
end
----------------------------------------------------
--code for "SelectNextPlayer" button----
--pressing the button will cycle view thru available teams flawlessly--
--code compatibility note: Spring 91's PlayerRoster return "isSpec" as number 1 or 0, but in Spring 93.2 it return it as boolean.

SelectNextPlayer = function ()
	local currentTeam = Spring.GetLocalTeamID()
	local playerTableSortTeamID = Spring.GetPlayerRoster(2)
	local isSpring91 = type(playerTableSortTeamID[1][5])=='number'
	local currentTeamIndex, firstPlayerIndex, teamIndexGoto = -1,nil,nil
	for i=1, #playerTableSortTeamID do
		local teamID = playerTableSortTeamID[i][3]
		local isSpec = playerTableSortTeamID[i][5]
		if ( isSpring91 ) then isSpec = ( isSpec==1 )
		end
		if (not isSpec ) then
			if not firstPlayerIndex then --if spectator portion has finished: mark this index
				firstPlayerIndex = i
			end
			if currentTeam == teamID then --if current selection is this team:  mark this index
				currentTeamIndex = i
				break
			end
		end
	end
	if firstPlayerIndex then
		if currentTeamIndex == -1 then --if current selection is spectator: select random player
			teamIndexGoto = math.random(firstPlayerIndex,#playerTableSortTeamID)
		elseif currentTeamIndex <= #playerTableSortTeamID then
			teamIndexGoto = currentTeamIndex + 1 --if player list is at beginning: go to next index
			for i=1,#playerTableSortTeamID - firstPlayerIndex +1 do --find player that we can spectate . NOTE: "#playerTableSortTeamID - firstPlayerIndex +1" is the amount of non-spec player.
				if teamIndexGoto > #playerTableSortTeamID then  --if player list is at end: go to first index
					teamIndexGoto = firstPlayerIndex
				end
				local isSpec = playerTableSortTeamID[teamIndexGoto][5]
				if ( isSpring91 ) then isSpec = ( isSpec==1 )
				end
				if (not isSpec ) then --not spectator
					break
				end
				teamIndexGoto = teamIndexGoto + 1
			end
		end
		spSendCommands("specteam "..playerTableSortTeamID[teamIndexGoto][3])
		Spring.Echo("game_message:Spectating team: " .. playerTableSortTeamID[teamIndexGoto][1]) --player's name
		local teamsUnit = Spring.GetTeamUnits(playerTableSortTeamID[teamIndexGoto][3])
		if teamsUnit and teamsUnit[1] then
			Spring.SelectUnitArray({teamsUnit[math.random(1,#teamsUnit)],}) --select this player's unit
		else
			Spring.SelectUnitArray({nil,})
		end
	end
end
