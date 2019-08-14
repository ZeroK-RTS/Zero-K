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

local LOAD_GAME_STRING = "loadFilename "
local SAVE_TYPE = (Spring.Utilities.IsCurrentVersionNewerThan(104, 1322) and "save ") or "luasave "
-- https://springrts.com/mantis/view.php?id=6219
-- https://springrts.com/mantis/view.php?id=6222

--------------------------------------------------------------------------------
-- Chili elements
--------------------------------------------------------------------------------
local Chili
local Window
local Control
local Panel
local Grid
local StackPanel
local ScrollPanel
local TextBox
local Label
local Button

local mainWindow

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
options_path = 'Settings/Misc/Autosave'
options =
{
	enableautosave = {
		name = 'Enable Autosave',
		type = 'bool',
		value = false,
		simpleMode = true,
		everyMode = true,
	},
	autosaveFrequency = {
		name = 'Autosave Frequency (minutes)',
		type = 'number',
		min = 1, max = 60, step = 1,
		value = 10,
		simpleMode = true,
		everyMode = true,
	},
}

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
	if mainWindow then
		mainWindow:Dispose()
		mainWindow = nil
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
		return a.filename < b.filename
	end
	return false
end

local function GetSaveExtension(path)
	if VFS.FileExists(path .. ".ssf") then
		return ".ssf"
	end
	return VFS.FileExists(path .. ".slsf") and ".slsf"
end

local function GetSaveWithExtension(path)
	local ext = GetSaveExtension(path)
	return ext and path .. ext
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
		Spring.Log(widget:GetInfo().name, LOG.ERROR, "Error getting save " .. path .. ": " .. err)
	else
		local engineSaveFilename = GetSaveWithExtension(string.sub(path, 1, -5))
		if not engineSaveFilename then
			--Spring.Log(widget:GetInfo().name, LOG.ERROR, "Save " .. engineSaveFilename .. " does not exist")
			return nil
		else
			return ret
		end
	end
end

-- Loads the list of save files and their contents
local function GetSaves()
	Spring.CreateDir(SAVE_DIR)
	local saves = {}
	local savefiles = VFS.DirList(SAVE_DIR, "*.lua")
	for i = 1, #savefiles do
		local path = savefiles[i]
		local saveData = GetSave(path)
		if saveData then
			saves[#saves + 1] = saveData
		end
	end
	table.sort(saves, SortSavesByFilename)
	return saves
end

-- e.g. if save slots 1, 2, 5, and 7 are used, return 3
-- only use for save name fallback
local function FindFirstEmptySaveSlot()
	for i = 0, MAX_SAVES do
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
		.. "\n" .. (WG.Translate("interface", "time_ingame") or "Ingame time").. ": " ..  SecondsToClock((saveFile.totalGameframe or saveFile.gameframe or 0)/30)
		.. "\n" .. WriteDate(saveFile.date)
end

local function RemoveAllSaveControls()
	for i=1,#saveControls do
		saveControls[i].container:Dispose()
	end
	saveControls = {}
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
local function SaveGame(filename, description, requireOverwrite)
	local success, err = pcall(
		function()
			Spring.CreateDir(SAVE_DIR)
			filename = (filename and trim(filename)) or ("save" .. string.format("%03d", FindFirstEmptySaveSlot()))
			path = SAVE_DIR .. "/" .. filename .. ".lua"
			local saveData = {}
			--saveData.filename = filename
			saveData.date = os.date('*t')
			saveData.description = description or "No description"
			saveData.gameName = Game.gameName
			saveData.gameVersion = Game.gameVersion
			saveData.engineVersion = Spring.Utilities.GetEngineVersion()
			saveData.map = Game.mapName
			saveData.gameID = (Spring.GetGameRulesParam("save_gameID") or Game.gameID)
			saveData.gameframe = Spring.GetGameFrame()
			saveData.totalGameframe = Spring.GetGameFrame() + (Spring.GetGameRulesParam("totalSaveGameFrame") or 0)
			saveData.playerName = Spring.GetPlayerInfo(Spring.GetMyPlayerID(), false)
			table.save(saveData, path)
			
			-- TODO: back up existing save?
			--if VFS.FileExists(SAVE_DIR .. "/" .. filename) then
			--end
			
			if requireOverwrite then
				Spring.SendCommands(SAVE_TYPE .. filename .. " -y")
			else
				Spring.SendCommands(SAVE_TYPE .. filename)
			end
			Spring.Log(widget:GetInfo().name, LOG.INFO, "Saved game to " .. path)
			
			DisposeWindow()
		end
	)
	if (not success) then
		Spring.Log(widget:GetInfo().name, LOG.ERROR, "Error saving game: " .. err)
	end
end

local function LoadGameByFilename(filename)
	local saveData = GetSave(SAVE_DIR .. '/' .. filename .. ".lua")
	if saveData then
		if Spring.GetMenuName and Spring.SendLuaMenuMsg and Spring.GetMenuName() then
			Spring.SendLuaMenuMsg(LOAD_GAME_STRING .. filename)
		else
			local ext = GetSaveExtension(SAVE_DIR .. '/' .. filename)
			if not ext then
				Spring.Log(widget:GetInfo().name, LOG.ERROR, "Error loading game: cannot find save file.")
				return
			end
			local success, err = pcall(
				function()
					-- This should perhaps be handled in chobby first?
					--Spring.Log(widget:GetInfo().name, LOG.INFO, "Save file " .. path .. " loaded")
					
					local script = [[
	[GAME]
	{
		SaveFile=__FILE__;
		IsHost=1;
		OnlyLocal=1;
		MyPlayerName=__PLAYERNAME__;
	}
	]]
					script = script:gsub("__FILE__", filename .. ext)
					script = script:gsub("__PLAYERNAME__", saveData.playerName)
					Spring.Reload(script)
				end
			)
			if (not success) then
				Spring.Log(widget:GetInfo().name, LOG.ERROR, "Error loading game: " .. err)
			end
		end
	else
		Spring.Log(widget:GetInfo().name, LOG.ERROR, "Save game " .. filename .. " not found")
	end
	if saveFilenameEdit then
		saveFilenameEdit:SetText(filename)
	end
end

local function DeleteSave(filename)
	if not filename then
		Spring.Log(widget:GetInfo().name, LOG.ERROR, "No filename specified for save deletion")
	end
	local success, err = pcall(function()
		local pathNoExtension = SAVE_DIR .. "/" .. filename
		os.remove(pathNoExtension .. ".lua")
		local saveFilePath = GetSaveWithExtension(pathNoExtension)
		if saveFilePath then
			os.remove(saveFilePath)
		end
	end)
	if (not success) then
		Spring.Log(widget:GetInfo().name, LOG.ERROR, "Error deleting save " .. filename .. ": " .. err)
	end
end

--------------------------------------------------------------------------------
-- Save/Load UI
--------------------------------------------------------------------------------
local function SaveLoadConfirmationDialogPopup(filename, saveMode, description)
	local text
	if saveMode then
		text = WG.Translate("interface", "save_overwrite_confirm") or ("Save \"" .. filename .. "\" already exists. Overwrite?")
	else
		text = WG.Translate("interface", "load_confirm") or ("Loading will lose any unsaved progress.\nDo you wish to continue?")
	end
	
	local yesFunc = function()
			if (saveMode) then
				DeleteSave(filename)
				SaveGame(filename, description, true)
				-- TODO refresh UI
			else
				LoadGameByFilename(filename)
			end
		end
	WG.crude.MakeExitConfirmWindow(text, yesFunc, 78, true, false)
end

local function PromptSave(filename, description)
	filename = filename or saveFilenameEdit.text
	filename = trim(filename)
	filename = string.gsub(filename, " ", "_")
	local saveExists = filename and VFS.FileExists(SAVE_DIR .. "/" .. filename .. ".lua") or false
	if saveExists then
		SaveLoadConfirmationDialogPopup(filename, true)
	else
		SaveGame(filename, description)
		WG.crude.KillSubWindow(false)
	end
end

local function GetButtonYPos(index)
	return (index - 1)*SAVEGAME_BUTTON_HEIGHT + 4
end

local function UpdateSaveButtonPositions(container)
	for i = 1, #container.children do
		local child = container.children[i]
		child:SetPos(child.x, GetButtonYPos(#container.children - i + 1))	-- assume reverse order, to match the ordering of the original save buttons
	end
end

-- Makes a button for a save game on the save/load screen
local function AddSaveEntryButton(parent, saveFile, position, saveMode)
	local controlsEntry = {filename = saveFile and saveFile.filename}
	
	local holder = Control:New {
		name = "save_" .. saveFile.filename,
		height = SAVEGAME_BUTTON_HEIGHT,
		width = "100%",
		y =  GetButtonYPos(position),
		x = 0,
		parent = parent,
	}
	
	local button = Button:New {
		parent = holder,
		x = 0,
		right = (saveFile and 96 + 8 or 0) + 0,
		y = 0,
		bottom = 0,
		caption = "",
		OnClick = { function(self)
				if saveMode then
					PromptSave(saveFile.filename, saveFile.description)
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
	local titleLabel = Label:New {
		parent = button,
		caption = saveFile and saveFile.filename,
		valign = "center",
		x = 8,
		y = 2,
		font = { size = 16 },
	}
	local descTextbox = TextBox:New {
		parent = button,
		x = 8,
		y = 24,
		right = 8,
		bottom = 8,
		text = GetSaveDescText(saveFile),
		font = { size = 14 },
	}
	local deleteButton = Button:New {
		parent = holder,
		width = 96,
		right = 0,
		y = 4,
		bottom = 4,
		caption = WG.Translate("interface", "delete") or "Delete",
		--backgroundColor = {0.4,0.4,0.4,1},
		OnClick = { function(self)
				WG.crude.MakeExitConfirmWindow("Are you sure you want to delete this save?", function()
					DeleteSave(saveFile.filename)
					holder:Dispose()
					UpdateSaveButtonPositions(parent)
				end, 78, false, false)
			end
		}
	}
	return controlsEntry
end

-- Generates the buttons for the savegames on the save/load screen
local function FillSaveStackWithSaves(parent, saves, saveMode)
	for i = #saves, 1, -1 do
		AddSaveEntryButton(parent, saves[i], i, saveMode)
	end
end

--------------------------------------------------------------------------------
-- Make Chili controls
--------------------------------------------------------------------------------

local function GetSavesList(parent, saveMode)
	local saves = GetSaves()
	FillSaveStackWithSaves(parent, saves, saveMode)
end

local function CreateWindow(saveMode)
	DisposeWindow()
	if WG.crude and WG.crude.AllowPauseOnMenuChange(true) then
		Spring.SendCommands("pause 1")
	end
	
	mainWindow = Window:New {
		name = 'zk_saveUI_saveWindow',
		x = Chili.Screen0.width / 2 - 320,
		y = "20%",
		width = 640,
		height = "60%",
		classname = "main_window",
		backgroundColor = {0, 0, 0, 0},
		caption = saveMode and "Save Game" or "Load Game",
		resizable = false,
		tweakResizable = false,
		parent = Chili.Screen0,
	}
	
	local saveScroll = ScrollPanel:New {
		name = 'zk_saveUI_saveScroll',
		orientation = "vertical",
		x = 5,
		y = 18,
		right = 5,
		bottom = 80,
		parent = mainWindow,
	}
	
	GetSavesList(saveScroll, saveMode)
	
	if saveMode then
		local saveFilenameEdit = Chili.EditBox:New {
			name = 'zk_saveUI_saveFilename',
			x = 5,
			right = (saveMode and 174) or 94,
			bottom = 42,
			height = 28,
			width = "100%",
			hint = "Save Filename",
			font = {size = 16},
			parent = mainWindow,
		}
		
		local saveDescEdit = Chili.EditBox:New {
			name = 'zk_saveUI_saveDesc',
			x = 5,
			right = (saveMode and 174) or 94,
			bottom = 8,
			height = 28,
			width = "100%",
			hint = "Save Description",
			font = {size = 16},
			parent = mainWindow,
		}
	
		local saveButton = Button:New {
			name = 'saveButton',
			width = 80,
			height = 66,
			bottom = 6,
			right = 90,
			caption = WG.Translate("interface", "save") or "Save",
			OnClick = {
				function ()
					if saveFilenameEdit.text and string.len(saveFilenameEdit.text) ~= 0 then
						PromptSave(saveFilenameEdit.text, saveDescEdit.text)
					end
				end
			},
			font = {size = 18},
			parent = mainWindow,
		}
	end
	
	local closeButton = Button:New {
		name = 'closeButton',
		width = 80,
		height = 66,
		bottom = 6,
		right = 5,
		caption = WG.Translate("interface", "close") or "Close",
		OnClick = {DisposeWindow},
		font = {size = 18},
		parent = mainWindow,
	}
end

--------------------------------------------------------------------------------
-- External Functions
--------------------------------------------------------------------------------

local externalFunctions = {}

function externalFunctions.CreateSaveWindow()
	CreateWindow(true)
end

function externalFunctions.CreateLoadWindow()
	CreateWindow(false)
end

--------------------------------------------------------------------------------
-- callins
--------------------------------------------------------------------------------
function widget:Initialize()
	Chili = WG.Chili
	Control = Chili.Control
	Window = Chili.Window
	Panel = Chili.Panel
	StackPanel = Chili.StackPanel
	ScrollPanel = Chili.ScrollPanel
	Label = Chili.Label
	TextBox = Chili.TextBox
	Button = Chili.Button
	
	WG.SaveGame = externalFunctions
end

function widget:Shutdown()

end

function widget:GameFrame(n)
	if not options.enableautosave.value then
		return
	end
	if options.autosaveFrequency.value == 0 then
		return
	end
	if n % (options.autosaveFrequency.value * 1800) == 0 and n ~= 0 then
		if Spring.GetSpectatingState() or Spring.IsReplay() or (not WG.crude.IsSinglePlayer()) then
			return
		end
		Spring.Log(widget:GetInfo().name, LOG.INFO, "Autosaving")
		SaveGame("autosave", "", true)
	end
end
