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

local SelectNextPlayer = function() end

options_path = 'Settings/Spectating/Player View'
options_order = {'followNextPlayer','specviewselection',}
options={
	followNextPlayer = {
		name = "Select Next Player",
		desc = "Quickly select next player. Hotkey this button.",
		type = 'button',
		OnChange = function(self) SelectNextPlayer() end,
	},
	specviewselection = {
		type='radioButton',
		name='View and Selection Restriction',
		items = {
			{name = 'Chosen player only',key='viewchosenplayer', desc="Point of view of current player, and you can only select the current player's units.", hotkey=nil},
			{name = 'Full vision',key='viewall', desc="Unlimited line of sight, but you can only select current player's units.", hotkey=nil},
			{name = 'Player vision with full selection',key='selectanyunit', desc="Point of view of current player, and you can select any unit.", hotkey=nil},
			{name = 'Full vision and selection',key='viewallselectany', desc="Unlimited line of sight, and you can select any unit.", hotkey=nil},
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
		-- I cannot read users mind, use first valid unit
		local lastTeam = spGetMyTeamID()
		for i, id in ipairs(selection) do
			local team = spGetUnitTeam(id)

			-- with specfullview 0, you can still unknowingly
			-- select enemy units, but they won't look valid,
			-- i.e. nil team. Skip those
			if team then

				if team ~= lastTeam then
					spSendCommands("specteam "..team)
				end
				break
			end
		end
	end
end
----------------------------------------------------
--code for "SelectNextPlayer" button----
--pressing the button will cycle view thru available teams flawlessly--

SelectNextPlayer = function ()
	local currentTeam = Spring.GetLocalTeamID()
	local playerTableSortTeamID = Spring.GetPlayerRoster(2)
	local currentTeamIndex, firstPlayerIndex, teamIndexGoto = -1,nil,nil
	for i=1, #playerTableSortTeamID do
		local teamID = playerTableSortTeamID[i][3]
		local isSpec = playerTableSortTeamID[i][5]
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
				if (not isSpec ) then --not spectator
					break
				end
				teamIndexGoto = teamIndexGoto + 1
			end
		end
		Spring.SelectUnit(nil)
		spSendCommands("specteam "..playerTableSortTeamID[teamIndexGoto][3])
		Spring.Echo("game_message:Spectating team: " .. playerTableSortTeamID[teamIndexGoto][1]) --player's name
	end
end
