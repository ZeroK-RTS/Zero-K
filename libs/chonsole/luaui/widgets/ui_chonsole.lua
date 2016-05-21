function widget:GetInfo()
  return {
    name      = "Chonsole",
    desc      = "Chili Console",
    author    = "gajop",
    date      = "in the future",
    license   = "GPL-v2",
    layer     = 2000,
    enabled   = true,
  }
end

VFS.Include(CHONSOLE_FOLDER .. "/luaui/config/globals.lua", nil, VFS.DEF_MODE)

-- context 
local currentContext

local function explode(div,str)
	if (div=='') then return 
		false 
	end
	local pos,arr = 0,{}
	-- for each divider found
	for st,sp in function() return string.find(str,div,pos,true) end do
		table.insert(arr,string.sub(str,pos,st-1)) -- Attach chars left of current divider
		pos = sp + 1 -- Jump past current divider
	end
	table.insert(arr,string.sub(str,pos)) -- Attach chars right of last divider
	return arr
end

-- Chili
local Chili, screen0
local ebConsole
local lblContext
local spSuggestions, scrollSuggestions

local vsx, vsy

-- history
local historyFilePath = ".console_history"
local historyFile
local history = {}

local currentHistory = 0
local filteredHistory = {}

-- suggestions
local currentSuggestion = 0
local currentSubSuggestion = 0
local suggestions = {}
local suggestionNameMapping = {} -- name -> index in "suggestions" table
local filteredSuggestions = {}
local dynamicSuggestions = {}
local preText -- used to determine if text changed

-- autocheat
-- TODO: make it part of the extensions instead
autoCheat = true
local autoCheatBuffer = {}

-- extensions
local cmdConfig = {}
local contextParser = {}

-- Hack for ZK as it normally squelches echos
-- if Game.gameName:find("Zero-K") or Game.gameName:find("Scened ZK") then
-- 	-- FIXME: override Spring.Echo only for this widget
-- 	local oldEcho = Spring.Echo
-- 	Spring.Echo = function(...) 
-- 		x = {...}
-- 		for i = 1, #x do
-- 			x[i] = "game_message:" .. tostring(x[i])
-- 		end
-- 		oldEcho(unpack(x))
-- 	end
-- end

-- extension API
function GetCurrentContext()
	return currentContext
end
function ResetCurrentContext()
	currentContext = { display = i18n("say_context", {default="Say:"}), name = "say", persist = true }
	ShowContext()
end
-- this is used to identify the current command used in Sync
local currentCmd = ""
function Sync(...)
	local x = {...}
	local msg = "chonsole|" .. currentCmd
	for _, v in pairs(x) do
		msg = msg .. "|" .. v
	end
	Spring.SendLuaRulesMsg(msg)
end
-- extension API end

function string.trimLeft(str)
  return str:gsub("^%s*(.-)", "%1")
end

function string.trim(str)
  return str:gsub("^%s*(.-)%s*$", "%1")
end

local function ExtractDir(filepath)
  filepath = filepath:gsub("\\", "/")
  local lastChar = filepath:sub(-1)
  if (lastChar == "/") then
    filepath = filepath:sub(1,-2)
  end
  local pos,b,e,match,init,n = 1,1,1,1,0,0
  repeat
    pos,init,n = b,init+1,n+1
    b,init,match = filepath:find("/",init,true)
  until (not b)
  if (n==1) then
    return filepath
  else
    return filepath:sub(1,pos)
  end
end

local function ExtractFileName(filepath)
  filepath = filepath:gsub("\\", "/")
  local lastChar = filepath:sub(-1)
  if (lastChar == "/") then
    filepath = filepath:sub(1,-2)
  end
  local pos,b,e,match,init,n = 1,1,1,1,0,0
  repeat
    pos,init,n = b,init+1,n+1
    b,init,match = filepath:find("/",init,true)
  until (not b)
  if (n==1) then
    return filepath
  else
    return filepath:sub(pos+1)
  end
end

function widget:Initialize()
	if not WG.Chili then
		widgetHandler:RemoveWidget(widget)
	end
	Chili = WG.Chili
	screen0 = Chili.Screen0
	i18n = WG.i18n
	if not i18n then
		-- optional support for i18n
		i18n = function(key, data)
			data = data or {}
			return data.default or key
		end
	end
	
	-- Load global translations
	if WG.i18n then
		VFS.Include(CHONSOLE_FOLDER .. "/i18n.lua", nil, VFS.DEF_MODE)
		if translations ~= nil then
			i18n.load(translations)
		end
	end
	
	-- Load extensions
	for _, f in pairs(VFS.DirList(CHONSOLE_FOLDER .. "/exts", "*", VFS.DEF_MODE)) do
		-- Load translations first
		if WG.i18n then
			local fname = ExtractFileName(f)
			local fdir = ExtractDir(f)
			local i18nFile = fdir .. "i18n/" .. fname
			if VFS.FileExists(i18nFile, nil, VFS.DEF_MODE) then
				local success, err = pcall(function() VFS.Include(i18nFile, nil, VFS.DEF_MODE) end)
				if not success then
					Spring.Log("Chonsole", LOG.ERROR, "Error loading translation file: " .. f)
					Spring.Log("Chonsole", LOG.ERROR, err)
				end
				if translations ~= nil then
					i18n.load(translations)
				end
			end
		end
		-- Load extension
		commands = nil
		local success, err = pcall(function() VFS.Include(f, nil, VFS.DEF_MODE) end)
		if not success then
			Spring.Log("Chonsole", LOG.ERROR, "Error loading extension file: " .. f)
			Spring.Log("Chonsole", LOG.ERROR, err)
		else
			if commands ~= nil then
				for _, cmd in pairs(commands) do
					table.insert(cmdConfig, cmd)
				end
			end
			if context ~= nil then
				for _, parser in pairs(context) do
					table.insert(contextParser, parser)
				end
			end
		end
	end
	
	Spring.SendCommands("unbindkeyset enter chat")
	
	table.merge(config.console, {
		parent = screen0,
		KeyPress = function(...)
			if not ParseKey(...) then
				return Chili.EditBox.KeyPress(...)
			end
			return true
		end,
		OnKeyPress = { function(...)
			PostParseKey(...)
		end},
		OnTextInput =  { function(...)
			PostParseKey(...)
		end},
	})
	ebConsole = Chili.EditBox:New(config.console)
	ebConsole:Hide()
	
	scrollSuggestions = Chili.ScrollPanel:New {
		borderColor = { 0, 0, 0, 0 },
		focusColor = { 0, 0, 0, 0 },
		backgroundColor = { 0, 0, 0, 1 },
		parent = screen0,
		scrollbarSize = 4,
	}
	spSuggestions = Chili.Control:New {
		x = 0,
		y = 0,
		autosize = true,
		itemMargin    = {0,0,0,0},
		itemPadding   = {0,0,0,0},
		padding 	  = {0, 0, 0, 0},
		parent = scrollSuggestions,
	}
	scrollSuggestions:Hide()
	
	lblContext = Chili.Label:New {
		width = 90,
		align = "right",
		caption = "",
		parent = screen0,
		font = {
			font = config.console.font.file,
			size = config.console.font.size,
			shadow = true,
		},
	}
	lblContext:Hide()
	
	-- read history
	pcall(function()
		for line in io.lines(historyFilePath) do 
			table.insert(history, line)
		end
	end)
	
	historyFile = io.open(historyFilePath, "a")
	
	GenerateSuggestions()
	local vsx, vsy = Spring.GetViewGeometry()
	ResizeUI(vsx, vsy)
end

function AreSuggestionsInverted()
	if config.suggestions.inverted then
		return true
	end
	local _, vsy = Spring.GetViewGeometry()
	local y = config.console.y * vsy + ebConsole.height
	local h = config.suggestions.h * vsy
	return y + h > vsy and y - h >= 0
end

function ResizeUI(_vsx, _vsy)
	vsx, vsy = _vsx, _vsy
	if not AreSuggestionsInverted() then
		scrollSuggestions:SetPos(ebConsole.x, ebConsole.y + ebConsole.height + config.suggestions.y, ebConsole.width, ebConsole.height * vsy)
	else
		local sh = config.suggestions.h * vsy
		scrollSuggestions:SetPos(ebConsole.x, ebConsole.y - sh - config.suggestions.y, ebConsole.width, sh)
	end
	spSuggestions:SetPos(nil, nil, config.console.width, config.suggestions.h * vsy)
	--FIXME: ZK/old-chili specific values
	--lblContext:SetPos(ebConsole.x - lblContext.width - 6, ebConsole.y + 7)
	lblContext:SetPos(ebConsole.x - lblContext.width - 10, ebConsole.y + 4)
end

function widget:ViewResize(vsx, vsy)
	ResizeUI(vsx, vsy)
end

function widget:Shutdown()
	if historyFile then
		historyFile:close()
	end
	Spring.SendCommands("bindkeyset enter chat") --because because.
end

function widget:KeyPress(key, ...)
	if key == Spring.GetKeyCode("enter") or key == Spring.GetKeyCode("numpad_enter") then
		if not ebConsole.visible then
			ebConsole:Show()
		end
		screen0:FocusControl(ebConsole)
		if currentContext == nil or not currentContext.persist then
			currentContext = { display = i18n("say_context", {default="Say:"}), name = "say", persist = true }
		end
		ShowContext()
		return true
	end
end

function SuggestionsUp()
	if currentSubSuggestion > 1 then
		currentSubSuggestion = currentSubSuggestion - 1
		local suggestion = dynamicSuggestions[currentSubSuggestion].suggestion
		ebConsole:SetText(suggestion.command)
		ebConsole.cursor = #ebConsole.text + 1
		UpdateSuggestions()
	elseif currentSuggestion > 1 then
		currentSuggestion = currentSuggestion - 1
-- 			if currentSuggestion > 0 then
		local id = filteredSuggestions[currentSuggestion]
		ebConsole:SetText(suggestions[id].text)
		ebConsole.cursor = #ebConsole.text + 1
		UpdateSuggestions()
-- 			end
	end
end

function SuggestionsDown()
	if #filteredSuggestions == 1 and #dynamicSuggestions ~= 0 then
		if #dynamicSuggestions > currentSubSuggestion and dynamicSuggestions[currentSubSuggestion+1].suggestion.visible then
			currentSubSuggestion = currentSubSuggestion + 1
			local suggestion = dynamicSuggestions[currentSubSuggestion].suggestion
			ebConsole:SetText(suggestion.command)
			ebConsole.cursor = #ebConsole.text + 1
			UpdateSuggestions()
		end
	elseif #filteredSuggestions > currentSuggestion then
		currentSuggestion = currentSuggestion + 1
		local id = filteredSuggestions[currentSuggestion]
		ebConsole:SetText(suggestions[id].text)
		ebConsole.cursor = #ebConsole.text + 1
		UpdateSuggestions()
	end
end

function ParseKey(ebConsole, key, mods, ...)
	if key == Spring.GetKeyCode("enter") or 
		key == Spring.GetKeyCode("numpad_enter") then
		ProcessText(ebConsole.text)
		HideConsole()
	elseif key == Spring.GetKeyCode("esc") then
		HideConsole()
	elseif key == Spring.GetKeyCode("up") then
		if currentSuggestion > 0 or currentSubSuggestion > 0 then
			SuggestionsUp()
		else
			if currentHistory == 0 then
				FilterHistory(ebConsole.text)
			end
			if #filteredHistory > currentHistory then
				--and not (currentHistory == 0 and ebConsole.text ~= "") 
				currentHistory = currentHistory + 1
				ShowHistoryItem()
				ShowSuggestions()
			end
		end
	elseif key == Spring.GetKeyCode("down") then
		if currentHistory > 0 then
			currentHistory = currentHistory - 1
			ShowHistoryItem()
			ShowSuggestions()
		elseif #filteredSuggestions > currentSuggestion or (#dynamicSuggestions > currentSubSuggestion and dynamicSuggestions[currentSubSuggestion+1].suggestion.visible) then
			SuggestionsDown()
		end
	elseif key == Spring.GetKeyCode("tab") then
		if #filteredSuggestions == 0 then
			return true
		end
		local nextSuggestion, nextSubSuggestion
		if #filteredSuggestions > currentSuggestion then
			nextSuggestion = currentSuggestion + 1
		else
			nextSuggestion = 1
		end
		if #dynamicSuggestions > currentSubSuggestion and dynamicSuggestions[currentSubSuggestion+1].suggestion.visible then
			nextSubSuggestion = currentSubSuggestion + 1
		else
			nextSubSuggestion = 1
		end
		if #filteredSuggestions == 1 and #dynamicSuggestions ~= 0 and #suggestions[filteredSuggestions[1]].text <= #ebConsole.text then
			if #dynamicSuggestions[nextSubSuggestion].suggestion.command >= #ebConsole.text or currentSubSuggestion ~= 0 then
				currentSubSuggestion = nextSubSuggestion
				local suggestion = dynamicSuggestions[currentSubSuggestion].suggestion
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
	elseif key == Spring.GetKeyCode("pageup") then
		for i = 1, config.suggestions.pageUpFactor do
			if currentSuggestion > 0 or currentSubSuggestion > 0 then
				SuggestionsUp()
			end
		end
	elseif key == Spring.GetKeyCode("pagedown") then
		for i = 1, config.suggestions.pageDownFactor do
			if #filteredSuggestions > currentSuggestion or (#dynamicSuggestions > currentSubSuggestion and dynamicSuggestions[currentSubSuggestion+1].suggestion.visible) then
				SuggestionsDown()
			end
		end
	else
		preText = ebConsole.text
		return false
	end
	return true
end

function FilterHistory(txt)
	filteredHistory = {}
	for _, historyItem in pairs(history) do
		if historyItem:starts(txt) then
			table.insert(filteredHistory, historyItem)
		end
	end
end

function UpdateTexture()
	texName = nil
	local txt = ebConsole.text
	if txt:sub(1, #"/texture ") == "/texture " then
		local cmdParts = explode(" ", txt:sub(#"/texture"+1):trimLeft():gsub("%s+", " "))
		local partialCmd = cmdParts[1]:lower()
		texName = partialCmd
	end
end

function PostParseKey(...)
	local txt = ebConsole.text
	if txt:lower() == "/a " or txt:lower() == "a:" then
		ebConsole:SetText("")
		currentContext = { display = i18n("allies_context", {default="Allies:"}), name = "allies", persist = true }
	elseif txt:lower() == "/s " or txt:lower() == "/say " then
		ebConsole:SetText("")
		currentContext = { display = i18n("say_context", {default="Say:"}), name = "say", persist = true }
	elseif txt:lower() == "/spec " or txt:lower() == "s:" then
		ebConsole:SetText("")
		currentContext = { display = i18n("spectators_context", {default="Spectators:"}), name = "spectators", persist = true }
-- 	elseif txt:trim():starts("/") and #txt:trim() > 1 then
-- 		currentContext = { display = "Command:", name = "command", persist = false }
	else
		local res, context = false, nil
		for _, parser in pairs(contextParser) do
			local success, err = pcall(function() res, context = parser.parse(txt) end)
			if not success then
				Spring.Log("Chonsole", LOG.ERROR, "Error processing custom context: " .. tostring(cmd.command))
				Spring.Log("Chonsole", LOG.ERROR, err)
			end
			if res then
				ebConsole:SetText("")
				currentContext = context
				break
			end
		end
		
		if not res and not currentContext.persist then
			currentContext = { display = i18n("say_context", {default="Say:"}), name = "say", persist = true }
		end
	end
	if preText ~= txt then -- only update suggestions if text changed
		currentSuggestion = 0
		currentSubSuggestion = 0
		UpdateSuggestions()
		if #txt > 0 and txt:sub(1, 1) == "/" then
			ShowSuggestions()
		else
			HideSuggestions()
		end
	end
	UpdateTexture()
	ShowContext()
end

function HideConsole()
	ebConsole:Hide()
	screen0:FocusControl(nil)
	ebConsole:SetText("")
	currentHistory = 0
	currentSuggestion = 0
	currentSubSuggestion = 0
	lblContext:Hide()
	HideSuggestions()
end

function string.starts(String,Start)
   return string.sub(String,1,string.len(Start))==Start
end

function ShowContext()
	if not lblContext.visible then
		lblContext:Show()
	end
	lblContext:SetCaption(currentContext.display)
end

function MakeSuggestion(suggestion)
	local ctrlSuggestion = Chili.Button:New {
		x = 0,
		minHeight = config.suggestions.fontSize + config.suggestions.padding,
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
			size = config.suggestions.fontSize,
-- 			shadow = false,
			color = config.suggestions.suggestionColor,
			font = config.console.fontFile,
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
			size = config.suggestions.fontSize,
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
	spSuggestions.ctrls = {}
	for _, suggestion in pairs(suggestions) do
		local ctrlSuggestion = CreateSuggestion(suggestion)
		spSuggestions.ctrls[suggestion.id] = ctrlSuggestion
		spSuggestions:AddChild(ctrlSuggestion)
	end
	local fakeCtrl = Chili.Button:New {
		x = 0,
		y = (#suggestions - 1) * (config.suggestions.fontSize + config.suggestions.padding),
		height = (config.suggestions.fontSize + config.suggestions.padding),
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
		dynamicSuggestion.suggestion.visible = false
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
				for i, subSuggestion in pairs(subSuggestions) do
					if subSuggestion.visible == nil then
						subSuggestion.visible = true
					end
					subSuggestion.dynId = #dynamicSuggestions + 1
					if i > #dynamicSuggestions then
						local ctrlSuggestion = CreateSuggestion(subSuggestion)
						ctrlSuggestion.suggestion = subSuggestion
						table.insert(dynamicSuggestions, ctrlSuggestion)
						spSuggestions:AddChild(ctrlSuggestion)
					else
						local ctrlSuggestion = dynamicSuggestions[i]
						ctrlSuggestion.suggestion.visible = true
						ctrlSuggestion.suggestion = subSuggestion
						PopulateSuggestion(ctrlSuggestion, subSuggestion)
					end
				end
			end
		end
	end
end

function ShowSuggestions()
	if not scrollSuggestions.visible then
		scrollSuggestions:Show()
	end
	
	FilterSuggestions(ebConsole.text)
	UpdateSuggestions()	
end

function UpdateSuggestionDisplay(suggestion, ctrlSuggestion, row)
	if suggestion.visible then
		ctrlSuggestion.y = (row - 1) * (config.suggestions.fontSize + config.suggestions.padding)

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
		dynamicSuggestion.x = 50
		UpdateSuggestionDisplay(dynamicSuggestion.suggestion, dynamicSuggestion, count)
	end

	-- FIXME: magic numbers and fake controls ^_^
	spSuggestions.fakeCtrl.y = (count-1+1) * (config.suggestions.fontSize + config.suggestions.padding)

	if currentSuggestion ~= 0 and scrollSuggestions.visible then
		local suggestion = suggestions[filteredSuggestions[currentSuggestion]]
		local selY = spSuggestions.ctrls[suggestion.id].y
		scrollSuggestions:SetScrollPos(0, selY, true, false)
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

function ShowHistoryItem()
	if currentHistory == 0 then
		ebConsole:SetText("")
	end
	local historyItem = filteredHistory[#filteredHistory - currentHistory + 1]
	if historyItem ~= nil then
		ebConsole:SetText(historyItem)
		ebConsole.cursor = #ebConsole.text + 1
	end
end

function ExecuteCustomCommand(cmd, command, cmdParts)
	currentCmd = cmd.command
	local success, err = pcall(function() cmd.exec(command, cmdParts) end)
	if not success then
		Spring.Log("Chonsole", LOG.ERROR, "Error executing custom command: " .. tostring(cmd.command))
		Spring.Log("Chonsole", LOG.ERROR, err)
	end
	currentCmd = ""
end

function ProcessText(str)
	if #str:trim() == 0 then
		return
	end
	AddHistory(str)
	-- command
	if str:sub(1, 1) == '/' then
		local command = str:sub(2):trimLeft()
		local cmdParts = explode(" ", command:gsub("%s+", " "))
		for _, cmd in pairs(cmdConfig) do
			if cmd.command == cmdParts[1]:lower() and cmd.exec ~= nil then
				if not cmd.cheat or Spring.IsCheatingEnabled() then
					ExecuteCustomCommand(cmd, command, cmdParts)
				elseif autoCheat then
					Spring.SendCommands("cheat 1")
					table.insert(autoCheatBuffer, {cmd, command, cmdParts})
				else
					Spring.Echo("Enable cheats with /cheat or /autocheat")
					-- NOTICE: Custom commands won't even be attempted if they're supposed to fail
					-- In case a user tries to manually send such attempts, it will still be stopped in the gadget.
					-- ExecuteCustomCommand(cmd, command, cmdParts)
				end
				return
			end
		end
		
		local index = suggestionNameMapping[cmdParts[1]]
		Spring.Echo(command)
		if index then
			local suggestion = suggestions[index]
			if (suggestion.cheat or cmdParts[1]:lower() == "luarules" and cmdParts[2]:lower() == "reload") and not Spring.IsCheatingEnabled() then
				if autoCheat then
					Spring.SendCommands("cheat 1")
					table.insert(autoCheatBuffer, command)
				else
					Spring.Echo("Enable cheats with /cheat or /autocheat")
					-- NOTICE: It will still try to execute the engine command which should fail.
					Spring.SendCommands(command)
				end
			else
				Spring.SendCommands(command)
			end
		else
			Spring.Log("Chonsole", LOG.WARNING, "Unknown command: " .. command)
			Spring.SendCommands(command)
		end
	else
		local command
		if currentContext.name == "say" then
			command = "say "
		elseif currentContext.name == "allies" then
			command = "say a:"
		elseif currentContext.name == "spectators" then
			command = "say s:"
		else
			local found = false
			for _, parser in pairs(contextParser) do
				if currentContext.name == parser.name then
					local success, err = pcall(function() parser.exec(str, currentContext) end)
					if not success then
						Spring.Log("Chonsole", LOG.ERROR, "Error executing custom context: " .. tostring(cmd.command))
						Spring.Log("Chonsole", LOG.ERROR, err)
					end
					found = true
					break
				end
			end
			
			if not found then
				Spring.Echo(currentContext)
				Spring.Echo("Unexpected context " .. currentContext.name)
				command = "say "
			end
		end
		if command then
			Spring.SendCommands(command .. str)
		end
		--Spring.SendMessageToTeam(Spring.GetMyTeamID(), str)
	end
end

function widget:DrawWorld()
	if delayGL then
		delayGL()
		delayGL = nil
	end
end

-- TODO: Make this part of the gl.lua extension, i.e. un-hardcode
function widget:DrawScreen()
	if texName then
		gl.PushMatrix()
			local texInfo = gl.TextureInfo(texName)
			if texInfo and texInfo.xsize >= 0 then
				gl.Texture(texName)
				-- FIXME: y is inverted in OpenGL (with respect to Chili)
				-- TODO: Fix magic numbers (make them configurable)
				gl.TexRect(ebConsole.x-400, ebConsole.y, ebConsole.x, ebConsole.y + 400)
				local sizeStr = tostring(texInfo.xsize) .. "x" .. tostring(texInfo.ysize)
				if texInfo.xsize == 0 then
					gl.Color(1, 0, 0)
				end
				gl.Text(sizeStr, ebConsole.x - 240, ebConsole.y - 15, 16)
			end
		gl.PopMatrix()
	end
end

function widget:Update()
	if #autoCheatBuffer > 0 and Spring.IsCheatingEnabled() then
		for _, command in pairs(autoCheatBuffer) do
			-- engine command
			if type(command) == "string" then
				Spring.SendCommands(command)
			-- custom command
			elseif type(command) == "table" then
				ExecuteCustomCommand(command[1], command[2], command[3])
			end
		end
		autoCheatBuffer = {}
		Spring.SendCommands("cheat 0")
	end
end

function AddHistory(str)
	if #history > 0 and history[#history] == str then
		return
	end
	table.insert(history, str)
	if historyFile then
		historyFile:write(str .. "\n")
	end
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
	for _, command in pairs(cmdConfig) do
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
