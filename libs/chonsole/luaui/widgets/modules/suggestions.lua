-- suggestions
local currentSuggestion = 0
local currentSubSuggestion = 0
local suggestions = {}
local suggestionNameMapping = {} -- name -> index in "suggestions" table
local filteredSuggestions = {}
local dynamicSuggestions = {}
local preText -- used to determine if text changed

-- name suggestions
local nameSuggestions = {}
local nameSuggestionIndx = 1
local nameSuggestionTxt

function GetSuggestionIndexByName(name)
	local index = suggestionNameMapping[name]
	if index then
		return suggestions[index]
	else
		return nil
	end
end

function MakeSuggestion(suggestion)
	local ctrlSuggestion = Chili.Button:New {
		x = 0,
		minHeight = config.suggestions.font.size + config.suggestions.suggestionPadding,
		autosize = true,
		width = "100%",
		resizable = false,
		draggable = false,
		padding  = {0,0,0,0},
		--focusColor = { 0, 0, 0, 0 },
		caption = "",
	}
	local lblSuggestion = Chili.Label:New {
		x = 0,
		caption = "",
		autosize = true,
		padding = {0, 0, 0, 0},
		font = {
			size = config.suggestions.font.size,
-- 			shadow = false,
			color = config.suggestions.suggestionColor,
			font = config.console.font.file,
		},
		parent = ctrlSuggestion,
	}
	ctrlSuggestion.lblSuggestion = lblSuggestion
	local lblDescription = Chili.Label:New {
		x = 300,
		autosize = true,
		caption = "",
		padding = {0, 0, 0, 0},
		font = {
			size = config.suggestions.font.size,
-- 			shadow = false,
			color = config.suggestions.descriptionColor,
			font = config.console.fontFile,
		},
		parent = ctrlSuggestion,
	}
	ctrlSuggestion.lblDescription = lblDescription
	if suggestion.cheat then 
		local lblCheat = Chili.Label:New {
			width = 100,
			x = 200,
			caption = i18n("cheat_command", {default="(cheat)"}),
			align = "right",
			padding = {0, 0, 0, 0},
			font = {
				size = config.suggestions.fontSize,
-- 				shadow = false,
				font = config.console.fontFile,
			},
			parent = ctrlSuggestion,
		}
		ctrlSuggestion.lblCheat = lblCheat
	end
	return ctrlSuggestion
end

function PopulateSuggestion(ctrlSuggestion, suggestion)
	ctrlSuggestion.id = suggestion.id
	ctrlSuggestion.OnClick = {
		function()
			local txt = suggestion.text
			if suggestion.dynId ~= nil then
				txt = suggestions[filteredSuggestions[1]].text .. " " .. txt
			end
			ebConsole:SetText(txt)
			ebConsole.cursor = #ebConsole.text + 1
			screen0:FocusControl(ebConsole)
			UpdateSuggestions()
		end,
	}
	ctrlSuggestion.lblSuggestion:SetCaption(suggestion.text)
	ctrlSuggestion.lblDescription:SetCaption(suggestion.description or "")
	return ctrlSuggestion
end

function CreateSuggestion(suggestion)
	return PopulateSuggestion(MakeSuggestion(suggestion), suggestion)
end

function GenerateSuggestions()
	suggestions = GetCommandList()
	for i, suggestion in pairs(suggestions) do
		suggestion.text = "/" .. suggestion.command:lower()
		suggestion.visible = false
		suggestion.id = i
		suggestionNameMapping[suggestion.command:lower()] = i
	end
	if config.suggestions.disableMenu then
		return
	end
	spSuggestions.ctrls = {}
	for _, suggestion in pairs(suggestions) do
		local ctrlSuggestion = CreateSuggestion(suggestion)
		spSuggestions.ctrls[suggestion.id] = ctrlSuggestion
		spSuggestions:AddChild(ctrlSuggestion)
	end
	local fakeCtrl = Chili.Button:New {
		x = 0,
		y = (#suggestions - 1) * (config.suggestions.font.size + config.suggestions.suggestionPadding),
		height = (config.suggestions.font.size + config.suggestions.suggestionPadding),
		autosize = true,
		--width = "100%",
		resizable = false,
		draggable = false,
		padding  = {0,0,0,0},
		focusColor = { 0, 0, 0, 0 },
		backgroundColor = { 0, 0, 0, 0 },
		id = -1,
		caption = "",
	}
	-- FIXME: fake control because chili has bugs
	spSuggestions:AddChild(fakeCtrl)
	spSuggestions.fakeCtrl = fakeCtrl
end

function CleanupSuggestions()
	-- cleanup dynamic suggestions
	for _, dynamicSuggestion in pairs(dynamicSuggestions) do
		dynamicSuggestion.visible = false
	end

	filteredSuggestions = {}
	
	for _, suggestion in pairs(suggestions) do
		suggestion.visible = false
	end
end

function FilterSuggestions(txt)
	CleanupSuggestions()
	
	local count = 0
	if txt:sub(1, 1) == "/" then
		local cmdParts = explode(" ", txt:sub(2):trimLeft():gsub("%s+", " "))
		local partialCmd = cmdParts[1]:lower()
		local addedCommands = {}
		for _, suggestion in pairs(suggestions) do
			local cmdName = suggestion.command:lower()
			local matched
			if #cmdParts > 1 then 
				matched = cmdName == partialCmd
			else
				matched = cmdName:starts(partialCmd)
			end
			if matched and not addedCommands[suggestion.id] then
				suggestion.visible = true
				count = count + 1
				table.insert(filteredSuggestions, suggestion.id)
				addedCommands[suggestion.id] = true
			end
		end
-- 		for _, command in pairs(commandList) do
-- 			if command.command:lower():find(partialCmd:lower()) and not addedCommands[command.command] then
-- 				table.insert(suggestions, { command = "/" .. command.command, text = command.command, description = command.description, cheat = command.cheat })
-- 				addedCommands[command.command] = true
-- 			end
-- 		end

		-- generate sub suggestions when only one field is visible
		if count == 1 then
			local suggestion = suggestions[filteredSuggestions[1]]
			if suggestion.suggestions ~= nil then
				local subSuggestions
				local success, err = pcall(function() 
					subSuggestions = suggestion.suggestions(txt, cmdParts)
				end)
				if not success then
					Spring.Log("Chonsole", LOG.ERROR, "Error obtaining suggestions for command: " .. tostring(suggestion.command))
					Spring.Log("Chonsole", LOG.ERROR, err)
					return
				end
-- 				if config.suggestions.disableMenu then
-- 					return
-- 				end
				for i, subSuggestion in pairs(subSuggestions) do
					if subSuggestion.visible == nil then
						subSuggestion.visible = true
					end
					subSuggestion.dynId = #dynamicSuggestions + 1
					if i > #dynamicSuggestions then
						if not config.suggestions.disableMenu then
							local ctrlSuggestion = CreateSuggestion(subSuggestion)
							subSuggestion.ctrlSuggestion = ctrlSuggestion
							spSuggestions:AddChild(ctrlSuggestion)
						end
						table.insert(dynamicSuggestions, subSuggestion)
					else
						local ctrlSuggestion = dynamicSuggestions[i].ctrlSuggestion
						dynamicSuggestions[i] = subSuggestion
						if not config.suggestions.disableMenu then
							dynamicSuggestions[i].ctrlSuggestion = ctrlSuggestion
							PopulateSuggestion(ctrlSuggestion, subSuggestion)
						end
					end
				end
			end
		end
	end
end

function ShowSuggestions()
	if not scrollSuggestions.visible and not config.suggestions.disableMenu then
		scrollSuggestions:Show()
	end
	
	FilterSuggestions(ebConsole.text)
	UpdateSuggestions()
end

function UpdateSuggestionDisplay(suggestion, ctrlSuggestion, row)
	if suggestion.visible then
		ctrlSuggestion.y = (row - 1) * (config.suggestions.font.size + config.suggestions.suggestionPadding)

		if not ctrlSuggestion.visible then
			ctrlSuggestion:Show()
		end

		if currentSubSuggestion == 0 and suggestion.id ~= nil and suggestion.id == filteredSuggestions[currentSuggestion] then
			ctrlSuggestion.backgroundColor = config.suggestions.suggestionColor
		elseif suggestion.dynId ~= nil and suggestion.dynId == currentSubSuggestion then
			ctrlSuggestion.backgroundColor = config.suggestions.suggestionColor
		elseif suggestion.id == nil then
 			ctrlSuggestion.backgroundColor = config.suggestions.subsuggestionColor
		else
			ctrlSuggestion.backgroundColor = { 0, 0, 0, 0 }
		end

		if suggestion.cheat then
			local cheatColor
			if Spring.IsCheatingEnabled() then
				cheatColor = config.suggestions.cheatEnabledColor
			elseif autoCheat then
				cheatColor = config.suggestions.autoCheatColor
			else
				cheatColor = config.suggestions.cheatDisabledColor
			end
			ctrlSuggestion.lblCheat.font.color = cheatColor
			ctrlSuggestion.lblCheat:Invalidate()
		end

		ctrlSuggestion:Invalidate()
	elseif ctrlSuggestion.visible then
		ctrlSuggestion:Hide()
	end
end

function UpdateSuggestions()
	if config.suggestions.disableMenu then
		return
	end

	UpdateTexture()
	local count = 0
	for _, suggestion in pairs(suggestions) do
		local ctrlSuggestion = spSuggestions.ctrls[suggestion.id]
		if suggestion.visible then
			count = count + 1
		end
		UpdateSuggestionDisplay(suggestion, ctrlSuggestion, count)
	end
	for _, dynamicSuggestion in pairs(dynamicSuggestions) do
		count = count + 1
		local ctrlSuggestion = dynamicSuggestion.ctrlSuggestion
		ctrlSuggestion.x = 50
		UpdateSuggestionDisplay(dynamicSuggestion, ctrlSuggestion, count)
	end

	-- FIXME: magic numbers and fake controls ^_^
	spSuggestions.fakeCtrl.y = (count-1+1) * (config.suggestions.font.size + config.suggestions.suggestionPadding)

	if currentSuggestion ~= 0 and scrollSuggestions.visible then
		local suggestion = suggestions[filteredSuggestions[currentSuggestion]]
		if suggestion == nil then
			Spring.Echo("BUG!", currentSuggestion, #filteredSuggestions, filteredSuggestions[currentSuggestion])
		else
			local selY = spSuggestions.ctrls[suggestion.id].y
			scrollSuggestions:SetScrollPos(0, selY, true, false)
		end
	end
	if count > 0 and not scrollSuggestions.visible then
		scrollSuggestions:RequestUpdate()
		scrollSuggestions:Show()
	elseif count == 0 and scrollSuggestions.visible then
		scrollSuggestions:Hide()
	end

	spSuggestions:Invalidate()
end

function HideSuggestions()
	CleanupSuggestions()
	if scrollSuggestions.visible then
		scrollSuggestions:Hide()
	end
end

function AreSuggestionsInverted()
	if config.suggestions.forceDirection == "up" then
		return true
	elseif config.suggestions.forceDirection == "down" then
		return false
	end
	local _, vsy = Spring.GetViewGeometry()
	local y = ebConsole.y + ebConsole.height
	local h = config.suggestions.height
	return y + h > vsy and y - h >= 0
end

function SuggestionsUp()
	if currentSubSuggestion > 1 then
		currentSubSuggestion = currentSubSuggestion - 1
		local suggestion = dynamicSuggestions[currentSubSuggestion]
		ebConsole:SetText(suggestion.command)
		ebConsole.cursor = #ebConsole.text + 1
		UpdateSuggestions()
		return true
	elseif currentSuggestion > 1 then
		currentSuggestion = currentSuggestion - 1
		local id = filteredSuggestions[currentSuggestion]
		ebConsole:SetText(suggestions[id].text)
		ebConsole.cursor = #ebConsole.text + 1
		UpdateSuggestions()
		return true
	end
end

function SuggestionsDown()
	if not (#filteredSuggestions > currentSuggestion or (#dynamicSuggestions > currentSubSuggestion and dynamicSuggestions[currentSubSuggestion+1].visible)) then
		return false
	end
	
	if #filteredSuggestions == 1 and #dynamicSuggestions ~= 0 then
		if #dynamicSuggestions > currentSubSuggestion and dynamicSuggestions[currentSubSuggestion+1].visible then
			currentSubSuggestion = currentSubSuggestion + 1
			local suggestion = dynamicSuggestions[currentSubSuggestion]
			ebConsole:SetText(suggestion.command)
			ebConsole.cursor = #ebConsole.text + 1
			UpdateSuggestions()
			return true
		end
	elseif #filteredSuggestions > currentSuggestion then
		currentSuggestion = currentSuggestion + 1
		local id = filteredSuggestions[currentSuggestion]
		ebConsole:SetText(suggestions[id].text)
		ebConsole.cursor = #ebConsole.text + 1
		UpdateSuggestions()
		return true
	end
end

function PrintSuggestions()
	for _, suggestion in pairs(suggestions) do
		Spring.Echo(suggestion.text)
	end
end

function SuggestionsTab()
	if #filteredSuggestions == 0 then
		return
	end
	if config.suggestions.disableMenu then
-- 		PrintSuggestions()
-- 		return
	end
	local nextSuggestion, nextSubSuggestion
	if #filteredSuggestions > currentSuggestion then
		nextSuggestion = currentSuggestion + 1
	else
		nextSuggestion = 1
	end
	if #dynamicSuggestions > currentSubSuggestion and dynamicSuggestions[currentSubSuggestion+1].visible then
		nextSubSuggestion = currentSubSuggestion + 1
	else
		nextSubSuggestion = 1
	end
	if #filteredSuggestions == 1 and #dynamicSuggestions ~= 0 and #suggestions[filteredSuggestions[1]].text <= #ebConsole.text then
		if #dynamicSuggestions[nextSubSuggestion].command >= #ebConsole.text or currentSubSuggestion ~= 0 then
			currentSubSuggestion = nextSubSuggestion
			local suggestion = dynamicSuggestions[currentSubSuggestion]
			if #dynamicSuggestions > 1 then
				ebConsole:SetText(suggestion.command)
			else
				ebConsole:SetText(suggestion.command .. " ")
			end
			ebConsole.cursor = #ebConsole.text + 1
			UpdateSuggestions()
		end
	elseif #suggestions[filteredSuggestions[nextSuggestion]].text >= #ebConsole.text or currentSuggestion ~= 0 then
		currentSuggestion = nextSuggestion
		local id = filteredSuggestions[currentSuggestion]
		if #filteredSuggestions > 1 then
			ebConsole:SetText(suggestions[id].text)
		else
			-- this will also select it if there's only one option
			ebConsole:SetText(suggestions[id].text .. " ")
		end
		ebConsole.cursor = #ebConsole.text + 1
		UpdateSuggestions()
	end
	return true
end

local function _GetCurrentWord()
	local txt = ebConsole.text
	local startX, endX = 1, 1
	for i = ebConsole.cursor-1, 1, -1 do
		if txt:sub(i, i) == " " then
			startX = i + 1
			break
		end
	end
	endX = txt:find(" ", ebConsole.cursor) or (#txt + 1)
	endX = endX - 1
	return txt:sub(startX, endX), startX, endX
end

local function _GetPlayerNames()
	local playerNames = {}
	for _, playerID in pairs(Spring.GetPlayerList()) do
		local name = Spring.GetPlayerInfo(playerID)
		table.insert(playerNames, name)
	end
	return playerNames
end

local function _ParseClan(word)
	if word:sub(1, 1) == "[" then
		local endClan = word:find("]")
		if endClan then
			word = word:sub(endClan+1)
		end
	end
	return word
end

local function _SetName(playerName, startX, endX)
	ebConsole:SetText(ebConsole.text:sub(1, startX-1) .. playerName .. ebConsole.text:sub(endX + 1))
	ebConsole.cursor = startX + #playerName
end

local function _ResetNameSuggestions()
	nameSuggestions = {}
	nameSuggestionIndx = 1
	nameSuggestionTxt = word
end

function NameSuggestionTab()
	local playerNames = _GetPlayerNames()

	local word, startX, endX = _GetCurrentWord()
	word = _ParseClan(word)
	if #word == 0 then
		return
	end

	if #nameSuggestions ~= 0 and nameSuggestionTxt == word then
		nameSuggestionIndx = nameSuggestionIndx + 1
		if nameSuggestionIndx > #nameSuggestions then
			nameSuggestionIndx = 1
		end
		_SetName(nameSuggestions[nameSuggestionIndx], startX, endX)
		return true
	end

	_ResetNameSuggestions()
	for _, playerName in pairs(playerNames) do
		if playerName:starts(word) or _ParseClan(playerName):starts(word) then
			_SetName(playerName, startX, endX)
			table.insert(nameSuggestions, playerName)
		end
	end
	return #nameSuggestions > 0
end

function GetCommandList()
	local commandList = {}
	
	if Spring.GetUICommands then
		commandList = Spring.GetUICommands()
	else
		Spring.Log("Chonsole", LOG.ERROR, "Using unsupported engine: no Spring.GetUICommands function")
	end
	
	local names = {}
	for _, command in pairs(commandList) do
		if command.synced then
			names[command.command:lower()] = true
		end
	end
	-- removed unsynced commands
	for i = #commandList, 1, -1 do
		local cmd = commandList[i]
		if not cmd.synced and names[cmd.command:lower()] then
			Spring.Log("Chonsole", LOG.NOTICE, "Removed duplicate command: ", cmd.command, cmd.description)
			table.remove(commandList, i)
		end
	end
	
	-- create a name mapping and merge any existing commands
	names = {}
	for _, command in pairs(commandList) do
		names[command.command:lower()] = command
	end
	for _, command in pairs(GetExtensions()) do
		local cmd = names[command.command:lower()]
		if cmd == nil then
			table.insert(commandList, command)
		else
			table.merge(cmd, command)
		end
	end
	table.sort(commandList, function(cmd1, cmd2) 
		return cmd1.command:lower() < cmd2.command:lower() 
	end)
	return commandList
end
