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

-- Chili
-- local Chili, screen0
-- local ebConsole
local lblContext
-- local spSuggestions, scrollSuggestions

-- autocheat
-- TODO: make it part of the extensions instead
autoCheat = true
local autoCheatBuffer = {}

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

CHONSOLE_MODULES_FOLDER = CHONSOLE_FOLDER .. "/luaui/widgets/modules"
VFS.Include(CHONSOLE_MODULES_FOLDER .. "/extension.lua", nil, VFS.DEF_MODE)
VFS.Include(CHONSOLE_MODULES_FOLDER .. "/history.lua", nil, VFS.DEF_MODE)
VFS.Include(CHONSOLE_MODULES_FOLDER .. "/marker.lua", nil, VFS.DEF_MODE)
VFS.Include(CHONSOLE_MODULES_FOLDER .. "/suggestions.lua", nil, VFS.DEF_MODE)
VFS.Include(CHONSOLE_MODULES_FOLDER .. "/util.lua", nil, VFS.DEF_MODE)

function GetText()
	if ebConsole then
		return ebConsole.text
	else
		return ""
	end
end

function widget:Initialize()
	if not WG.Chili then
		widgetHandler:RemoveWidget(widget)
	end
	Chili = WG.Chili
	screen0 = Chili.Screen0

	InitializeExtensions()
	LoadTranslations()
	LoadExtensions()

	StartMarker()

	table.merge(config.console, {
		parent = screen0,
		KeyPress = function(...)
			if not ParseKey(...) then
				return Chili.EditBox.KeyPress(...)
			end
			return true
		end,
		TextInput = function(...)
			if not ParseText(...) then
				return Chili.EditBox.TextInput(...)
			end
			return true
		end,
		OnKeyPress = { function(...)
			PostParseKey(...)
		end},
		OnTextInput = { function(...)
			PostParseKey(...)
		end},
		OnFocusUpdate = { function(...)
			PostFocusUpdate(...)
		end},
	})
	ebConsole = Chili.EditBox:New(config.console)
	ebConsole:Hide()
	
	table.merge(config.suggestions, {
		borderColor = { 0, 0, 0, 0 },
		focusColor = { 0, 0, 0, 0 },
		backgroundColor = { 0, 0, 0, 1 },
		parent = screen0,
		scrollbarSize = 4,
	})
	scrollSuggestions = Chili.ScrollPanel:New(config.suggestions)
	spSuggestions = Chili.Control:New {
		x = 0,
		y = 0,
		autosize = true,
		itemMargin    = {0,0,0,0},
		itemPadding   = {0,0,0,0},
		padding 	  = {0,0,0,0},
		parent = scrollSuggestions,
	}
	scrollSuggestions:Hide()
	
	lblContext = Chili.Label:New {
		width = 90,
		align = "right",
		caption = "",
		parent = screen0,
		font = {
			font = config.console.font.font,
			size = config.console.font.size,
			shadow = true,
		},
	}
	lblContext:Hide()
	
	LoadHistory()
	
	GenerateSuggestions()
	local vsx, vsy = Spring.GetViewGeometry()
	ResizeUI(vsx, vsy)
end

function ResizeUI(vsx, vsy)
	if not AreSuggestionsInverted() then
		scrollSuggestions:SetPos(ebConsole.x, ebConsole.y + ebConsole.height + scrollSuggestions.offsetY, ebConsole.width, scrollSuggestions.height)
	else
		scrollSuggestions:SetPos(ebConsole.x, ebConsole.y - scrollSuggestions.height - scrollSuggestions.offsetY, ebConsole.width, scrollSuggestions.height)
	end
	spSuggestions:SetPos(nil, nil, spSuggestions.width, spSuggestions.height)
-- 	spSuggestions:SetPos(nil, nil, 300, 200)
	--FIXME: either use config or better autodetection of these values
	--lblContext:SetPos(ebConsole.x - lblContext.width - 6, ebConsole.y + 7)
	lblContext:SetPos(ebConsole.x - lblContext.width - 10, ebConsole.y + 6)
end

function widget:ViewResize(vsx, vsy)
	ResizeUI(vsx, vsy)
end

function widget:Shutdown()
	CloseHistory()
	CloseMarker()
end

function widget:KeyPress(key, ...)
	local parsedKey = false
	if key == Spring.GetKeyCode("enter") or key == Spring.GetKeyCode("numpad_enter") then
		if not ebConsole.visible then
			ebConsole:Show()
		end
		screen0:FocusControl(ebConsole)
		parsedKey = true
	end
	parsedKey = KeyPressContext(key, ...) or parsedKey
	if GetCurrentContext() ~= nil then
		ShowContext()
	end
	return parsedKey
end

function widget:MousePress(x, y, button)
	return MarkerMousePress(x, y, button)
end

function widget:MouseMove(x, y, dx, dy, button)
	return MarkerMouseMove(x, y, dx, dy, button)
end

function ParseText(ebConsole, utf8char)
	return MarkerParseText(utf8char)
end

function ParseKey(ebConsole, key, mods, isRepeat)
	MarkerParseKey(key, mods, isRepeat)
	if key == Spring.GetKeyCode("enter") or 
		key == Spring.GetKeyCode("numpad_enter") then
		if not ParseKeyContext(key, mods, isRepeat) then
			ProcessText(GetText())
			HideConsole()
		end
	elseif key == Spring.GetKeyCode("esc") then
		HideConsole()
	elseif key == Spring.GetKeyCode("up") then
		if not SuggestionsUp() then
			if GetCurrentHistory() == 0 then
				FilterHistory(GetText())
			end
			NextHistoryItem()
		end
	elseif key == Spring.GetKeyCode("down") then
		if GetCurrentHistory() > 0 then
			PrevHistoryItem()
		else
			SuggestionsDown()
		end
	elseif key == Spring.GetKeyCode("tab") then
		if not SuggestionsTab() then
			NameSuggestionTab()
		end
	elseif key == Spring.GetKeyCode("pageup") then
		for i = 1, config.suggestions.pageUpFactor do
			if not SuggestionsUp() then
				break
			end
		end
	elseif key == Spring.GetKeyCode("pagedown") then
		for i = 1, config.suggestions.pageDownFactor do
			SuggestionsDown()
		end
	else
		preText = GetText()
		return false
	end
	return true
end

function UpdateTexture()
	texName = nil
	local txt = GetText()
	if txt:sub(1, #"/texture ") == "/texture " then
		local cmdParts = explode(" ", txt:sub(#"/texture"+1):trimLeft():gsub("%s+", " "))
		local partialCmd = cmdParts[1]:lower()
		texName = partialCmd
	end
end

function PostParseKey(...)
	local txt = GetText()

	if not TryEnterContext(txt) and not GetCurrentContext().persist then
		ResetCurrentContext()
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
	ResetCurrentHistory()
	currentSuggestion = 0
	currentSubSuggestion = 0
	lblContext:Hide()
	HideSuggestions()
end

function PostFocusUpdate(...)
	if not ebConsole.state.focused and ebConsole.visible and ebConsole.keepFocus then
		delayFocus = true -- FIXME: should really use WG.delay or similar functionality
	end
end

function ShowContext()
	if not ebConsole.visible then
		return
	end
-- 	EnterCurrentContext(GetText())
	if not lblContext.visible then
		lblContext:Show()
	end
	lblContext.font.color = GetCurrentContext().color or {1, 1, 1, 1}
	lblContext:SetCaption(GetCurrentContext().display)
	ebConsole.font.color = GetCurrentContext().color or {1, 1, 1, 1}
	ebConsole.cursorColor = GetCurrentContext().color or {1, 1, 1, 1}
	ebConsole.font:Invalidate()
end

function ShowHistoryItem()
	ebConsole:SetText(GetCurrentHistoryItem())
	ebConsole.cursor = #GetText() + 1
end

function ProcessText(str)
-- 	if #str:trim() == 0 then
-- 		return
-- 	end
	AddHistory(str)
	-- command
	if str:sub(1, 1) == '/' then
		local command = str:sub(2):trimLeft()
		local cmdParts = explode(" ", command:gsub("%s+", " "))
		for _, cmd in pairs(GetExtensions()) do
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
		
		Spring.Echo(command)
		local suggestion = GetSuggestionIndexByName(cmdParts[1])
		if suggestion then
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
		if GetCurrentContext().name == "label" then
			AddMarker(str)
			ResetCurrentContext()
		else
			if not ExecuteCurrentContext(str, cmd) then
				Spring.Echo("Unexpected context " .. GetCurrentContext().name)
				Spring.SendCommands("say " .. str)
			end
		end
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
	if delayFocus then
		delayFocus = false
		screen0:FocusControl(ebConsole)
	end
end

function widget:PlayerChanged(playerID)
	if PlayerChanged then
		PlayerChanged(playerID)
	end
end

