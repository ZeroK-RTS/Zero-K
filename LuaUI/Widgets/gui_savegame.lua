--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
	return {
		name      = "Save Game Menu",
		desc      = "bla",
		author    = "KingRaptor",
		date      = "2016.11.24",
		license   = "GNU GPL, v2 or later",
		layer     = -9999,
		enabled   = true  --  loaded by default?
	}
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
local SAVEGAME_BUTTON_HEIGHT = 128
local SAVE_DIR = "Saves"
local SAVE_DIR_LENGTH = string.len(SAVE_DIR) + 2
local AUTOSAVE_DIR = SAVE_DIR .. "/auto"
local MAX_SAVES = 999
--------------------------------------------------------------------------------
-- Chili elements
--------------------------------------------------------------------------------
local Chili
local Window
local Panel
local Grid
local StackPanel
local ScrollPanel
local TextBox
local Label
local Button

-- chili elements
local window
local saveGrid
local saveScroll
local saveFilenameEdit, saveDescEdit
local saveControls = {}	-- {filename, container, titleLabel, descTextBox, image (someday), isNew}

--------------------------------------------------------------------------------
-- data
--------------------------------------------------------------------------------
local saves = {}
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Makes a control grey for disabled, or whitish for enabled
local function SetControlGreyout(control, state)
	if state then
		control.backgroundColor = {0.4, 0.4, 0.4, 1}
		control.font.color = {0.4, 0.4, 0.4, 1}
		control:Invalidate()
	else
		control.backgroundColor = {.8,.8,.8,1}
		control.font.color = nil
		control:Invalidate()
	end
end

local function WriteDate(dateTable)
	return string.format("%02d/%02d/%04d", dateTable.day, dateTable.month, dateTable.year)
	.. " " .. string.format("%02d:%02d:%02d", dateTable.hour, dateTable.min, dateTable.sec)
end

local function SecondsToClock(seconds)
	local seconds = tonumber(seconds)

	if seconds <= 0 then
		return "00:00";
	else
		hours = string.format("%02d", math.floor(seconds/3600));
		mins = string.format("%02d", math.floor(seconds/60 - (hours*60)));
		secs = string.format("%02d", math.floor(seconds - hours*3600 - mins *60));
		if seconds >= 3600 then
			return hours..":"..mins..":"..secs
		else
			return mins..":"..secs
		end
	end
end

local function DisposeWindow()
	if window then
		window:Dispose()
		window = nil
	end
end

local function trim(str)
  return str:match'^()%s*$' and '' or str:match'^%s*(.*%S)'
end

--------------------------------------------------------------------------------
-- Savegame utlity functions
--------------------------------------------------------------------------------
-- FIXME: currently unused as it doesn't seem to give the correct order
local function SortSavesByDate(a, b)
	if a == nil or b == nil then
		return false
	end
	--Spring.Echo(a.id, b.id, a.date.hour, b.date.hour, a.date.hour>b.date.hour)
	
	if a.date.year > b.date.year then return true end
	if a.date.yday > b.date.yday then return true end
	if a.date.hour > b.date.hour then return true end
	if a.date.min > b.date.min then return true end
	if a.date.sec > b.date.sec then return true end
	return false
end

local function SortSavesByFilename(a, b)
	if a == nil or b == nil then
		return false
	end
	if a.filename and b.filename then
		return a.filename > b.filename
	end
	return false
end

-- Returns the data stored in a save file
local function GetSave(path)
	local ret = nil
	local success, err = pcall(function()
		local saveData = VFS.Include(path)
		saveData.filename = string.sub(path, SAVE_DIR_LENGTH, -5)	-- pure filename without directory or extension
		saveData.path = path
		ret = saveData
	end)
	if (not success) then
		Spring.Log(widget:GetInfo().name, LOG.ERROR, "Error getting saves: " .. err)
	else
		return ret
	end
end

-- Loads the list of save files and their contents
local function GetSaves()
	Spring.CreateDir(SAVE_DIR)
	saves = {}
	local savefiles = VFS.DirList(SAVE_DIR, "*.lua")
	for i=1,#savefiles do
		local path = savefiles[i]
		local saveData = GetSave(path)
		if saveData then
			saves[#saves + 1] = saveData
		end
	end
	table.sort(saves, SortSavesByFilename)
end

-- e.g. if save slots 1, 2, 5, and 7 are used, return 3
-- only use for save name fallback
local function FindFirstEmptySaveSlot()
	for i=0,MAX_SAVES do
		local num = string.format("%03d", i)
		if not VFS.FileExists(SAVE_DIR .. "/save" .. num .. ".lua") then
			return i
		end
	end
	return MAX_SAVES
end

local function GetSaveDescText(saveFile)
	if not saveFile then return "" end
	return (saveFile.description or "no description")
		.. "\n" .. saveFile.gameName .. " " .. saveFile.gameVersion
		.. "\n" .. saveFile.map
		.. "\n" .. (WG.Translate("interface", "time_ingame") or "Ingame time").. ": " ..  SecondsToClock(saveFile.gameframe/30)
		.. "\n" .. WriteDate(saveFile.date)
end

local function RemoveSaveControls(filename)
	local function remove(tbl, filename)
		local parent = nil
		for i=1,#tbl do
			local entry = tbl[i]
			if entry.filename == filename then
				parent = entry.container.parent
				entry.container:Dispose()
				table.remove(tbl, i)
				break
			end
		end
		parent:Invalidate()
	end
	remove(saveControls, filename)
end

local function RemoveAllSaveControls()
	for i=1,#saveControls do
		saveControls[i].container:Dispose()
	end
	saveControls = {}
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
local function SaveGame(filename)
	local success, err = pcall(function()
		Spring.CreateDir(SAVE_DIR)
		filename = (filename and trim(filename)) or ("save" .. string.format("%03d", FindFirstEmptySaveSlot()))
		path = SAVE_DIR .. "/" .. filename .. ".lua"
		local saveData = {}
		--saveData.filename = filename
		saveData.date = os.date('*t')
		saveData.description = isAutosave and "" or saveDescEdit.text
		saveData.gameName = Game.gameName
		saveData.gameVersion = Game.gameVersion
		saveData.engineVersion = Game.version
		saveData.map = Game.mapName
		saveData.gameframe = Spring.GetGameFrame()
		saveData.playerName = Spring.GetPlayerInfo(Spring.GetMyPlayerID())
		table.save(saveData, path)
		Spring.SendCommands("luasave " .. filename .. " -y")
		
		saveFilenameEdit:SetText(filename)
		Spring.Log(widget:GetInfo().name, LOG.INFO, "Saved game to " .. path)
		
		DisposeWindow()
	end)
	if (not success) then
		Spring.Log(widget:GetInfo().name, LOG.ERROR, "Error saving game: " .. err)
	end
end

local function LoadGameByFilename(filename)
	local saveData = GetSave(SAVE_DIR .. '/' .. filename .. ".lua")
	if saveData then
		local success, err = pcall(function()
			if saveData.description then
				saveDescEdit:SetText(saveData.description)
			end
			
			--Spring.Log(widget:GetInfo().name, LOG.INFO, "Save file " .. path .. " loaded")
			DisposeWindow()
			local script = [[
[GAME]
{
	SaveFile=__FILE__;
	IsHost=1;
	OnlyLocal=1;
	MyPlayerName=__PLAYERNAME__;
}
]]
			script = script:gsub("__FILE__", filename .. ".slsf")
			script = script:gsub("__PLAYERNAME__", saveData.playerName)
			Spring.Reload(script)
		end)
		if (not success) then
			Spring.Log(widget:GetInfo().name, LOG.ERROR, "Error loading game: " .. err)
		end
	else
		Spring.Log(widget:GetInfo().name, LOG.ERROR, "Save game " .. filename .. " not found")
	end
	saveFilenameEdit:SetText(filename)
end

local function DeleteSave(filename)
	if not filename then
		Spring.Log(widget:GetInfo().name, LOG.ERROR, "No filename specified for save deletion")
	end
	local success, err = pcall(function()
		local pathNoExtension = SAVE_DIR .. "/" .. filename
		os.remove(pathNoExtension .. ".lua")
		os.remove(pathNoExtension .. ".slsf")
		RemoveSaveControls(filename)
	end)
	if (not success) then
		Spring.Log(widget:GetInfo().name, LOG.ERROR, "Error deleting save " .. filename .. ": " .. err)
	end
end


--------------------------------------------------------------------------------
-- Save/Load UI
--------------------------------------------------------------------------------
local function SaveLoadConfirmationDialogPopup(filename, saveMode)
	local text = saveMode and (WG.Translate("interface", "save_overwrite_confirm") or ("Save \"" .. filename .. "\" already exists. Overwrite?"))
				or WG.Translate("interface", "load_confirm") or ("Loading will lose any unsaved progress.\nDo you wish to continue?")
	local yesFunc = function()
			if (saveMode) then
				SaveGame(filename)
				-- TODO refresh UI
			else
				LoadGameByFilename(filename)
			end
		end
	WG.crude.MakeExitConfirmWindow(text, yesFunc)
end

local function PromptSave(filename)
	filename = filename or saveFilenameEdit.text
	filename = trim(filename)
	local saveExists = filename and VFS.FileExists(SAVE_DIR .. "/" .. filename .. ".lua") or false
	if saveExists then
		SaveLoadConfirmationDialogPopup(filename, true)
	else
		SaveGame(filename)
	end
end

-- Makes a button for a save game on the save/load screen
local function AddSaveEntryButton(saveFile, saveMode)
	local controlsEntry = {filename = saveFile and saveFile.filename}
	local parent = saveStack
	
	controlsEntry.container = Panel:New {
		parent = parent,
		height = SAVEGAME_BUTTON_HEIGHT,
		width = "100%",
		x = 0,
		--y = (SAVEGAME_BUTTON_HEIGHT) * count,
		caption = "",
		backgroundColor = {1,1,1,0},
	}
	controlsEntry.button = Button:New {
		parent = controlsEntry.container,
		x = 0,
		right = (saveFile and 96 + 8 or 0) + 0,
		y = 0,
		bottom = 0,
		caption = "",
		OnClick = { function(self)
				if saveMode then
					PromptSave(saveFile and saveFile.filename or nil)
				else
					SaveLoadConfirmationDialogPopup(saveFile.filename, false)
				end
			end
		}
	}
	--controlsEntry.stack = StackPanel:New {
	--	parent = controlsEntry.button,
	--	height = "100%",
	--	width = "100%",
	--	orientation = "vertical",
	--	resizeItems = false,
	--	autoArrangeV = false,	
	--}
	local caption = saveFile and saveFile.filename or (WG.Translate("interface", "save_new_game") or "New save")
	controlsEntry.titleLabel = Label:New {
		parent = controlsEntry.button,
		caption = caption,
		valign = "center",
		x = 8,
		y = 2,
		font = { size = 16 },
	}
	if saveFile then
		controlsEntry.descTextbox = TextBox:New {
			parent = controlsEntry.button,
			x = 8,
			y = 24,
			right = 8,
			bottom = 8,
			text = GetSaveDescText(saveFile),
			font = { size = 14 },
		}
		controlsEntry.deleteButton = Button:New {
			parent = controlsEntry.container,
			width = 96,
			right = 0,
			y = 4,
			bottom = 4,
			caption = WG.Translate("interface", "delete") or "Delete",
			--backgroundColor = {0.4,0.4,0.4,1},
			OnClick = { function(self)
					WG.crude.MakeExitConfirmWindow("Are you sure you want to delete this save?", function() 
						DeleteSave(saveFile.filename)
					end)
				end
			}
		}
	end
	return controlsEntry
end

-- Generates the buttons for the savegames on the save/load screen
local function AddSaveEntryButtons(saveMode)
	local startIndex = #saves
	local count = 0
	if (saveMode) then
		-- add new game panel
		saveControls[#saveControls + 1] = AddSaveEntryButton(nil, true)
		count = 1
	end
	
	for i=startIndex,1,-1 do
		saveControls[#saveControls + 1] = AddSaveEntryButton(saves[i], saveMode)
		count = count + 1;
	end
end

--------------------------------------------------------------------------------
-- Make Chili controls
--------------------------------------------------------------------------------
local function CreateWindow(save)
	DisposeWindow()

	saveScroll = ScrollPanel:New {
		name = 'zk_saveUI_saveScroll',
		orientation = "vertical",
		x = 0,
		y = 12,
		width = "100%",
		bottom = 64,
		children = {}
	}
	saveStack = StackPanel:New {
		name = 'zk_saveUI_saveStack',
		parent = saveScroll,
		orientation = "vertical",
		x = 0,
		width = "100%",
		y = 0,
		autosize = true,
		resizeItems = false,
		autoArrangeV = false,
	}
	saveFilenameEdit = Chili.EditBox:New {
		name = 'zk_saveUI_saveFilename',
		x = 0,
		right = 88,
		bottom = 36,
		height = 20,
		width = "100%",
		text = "Save filename",
		font = { size = 16 },
	}
	saveDescEdit = Chili.EditBox:New {
		name = 'zk_saveUI_saveDesc',
		x = 0,
		right = 88,
		bottom = 4,
		height = 20,
		width = "100%",
		text = "Save description",
		font = { size = 16 },
	}
	
	window = Window:New {
		name = 'zk_saveUI_saveWindow',
		parent = Chili.Screen0,
		x = Chili.Screen0.width / 2 - 320,
		y = "20%",
		width = 640,
		height = "60%",
		backgroundColor = {0, 0, 0, 0},
		caption = save and "Save Game" or "Load Game",
		resizable = false,
		tweakResizable = false,
		children = {
			Button:New {
				name = 'zk_saveUI_saveBack',
				width = 80,
				height = 64,
				bottom = 0,
				right = 0,
				caption = WG.Translate("interface", "close") or "Close",
				OnClick = {function() DisposeWindow() end},
				font = {size = 18}
			},
			saveFilenameEdit,
			saveDescEdit,
			saveScroll,
		}
	}
	GetSaves()
	AddSaveEntryButtons(save)
end

--------------------------------------------------------------------------------
-- callins
--------------------------------------------------------------------------------
function widget:Initialize()
	Chili = WG.Chili
	Window = Chili.Window
	Panel = Chili.Panel
	StackPanel = Chili.StackPanel
	ScrollPanel = Chili.ScrollPanel
	Label = Chili.Label
	TextBox = Chili.TextBox
	Button = Chili.Button
	
	WG.SaveGame = {
		CreateWindow = CreateWindow
	}
end

function widget:Shutdown()

end