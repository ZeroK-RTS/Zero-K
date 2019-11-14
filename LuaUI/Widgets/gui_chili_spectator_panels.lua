--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
  return {
    name      = "Chili Spectator Panels",
    desc      = "Manages UI panels for displaying team information while spectating.",
    author    = "GoogleFrog",
    date      = "5 August 2015",
    license   = "GNU GPL, v2 or later",
    layer     = 0,
    enabled   = true
  }
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

include("colors.h.lua")
VFS.Include("LuaRules/Configs/constants.lua")

local GetLeftRightAllyTeamIDs = VFS.Include("LuaUI/Headers/allyteam_selection_utilities.lua")
local GetFlowStr = VFS.Include("LuaUI/Headers/ecopanels.lua")

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local abs = math.abs
local spGetTeamResources = Spring.GetTeamResources
local spGetTeamRulesParam = Spring.GetTeamRulesParam

local Chili
local screen0

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local col_metal = {136/255,214/255,251/255,1}
local col_energy = {.93,.93,0,1}
local col_empty = {0,0,0,0}
local col_expense
local positiveColourStr
local negativeColourStr

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local playerWindow
local economyWindowData
local allyTeamData

local enabled = false
local enabledPlayer = false
local enabledResource = false

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Options Functions

local function UpdateResourceWindowFonts(windowData)
	windowData.metalPanel.label_income.font.size = options.resourceMainFontSize.value
	windowData.metalPanel.label_overdrive.font.size = options.resourceFontSize.value
	windowData.metalPanel.label_reclaim.font.size = options.resourceFontSize.value
	windowData.energyPanel.label_income.font.size = options.resourceMainFontSize.value
	windowData.energyPanel.label_overdrive.font.size = options.resourceFontSize.value
	windowData.energyPanel.label_reclaim.font.size = options.resourceFontSize.value
	
	windowData.metalPanel.bar:SetCaption(GetFlowStr(windowData.metalPanel.bar.net, options.flowAsArrows.value, positiveColourStr, negativeColourStr))
	windowData.metalPanel.bar.font.size = options.flowAsArrows.value and 20 or 16
	windowData.metalPanel.bar.fontOffset = options.flowAsArrows.value and -2 or 1
	windowData.energyPanel.barOverlay:SetCaption(GetFlowStr(windowData.energyPanel.barOverlay.net, options.flowAsArrows.value, positiveColourStr, negativeColourStr))
	windowData.energyPanel.barOverlay.font.size = options.flowAsArrows.value and 20 or 16
	windowData.energyPanel.barOverlay.fontOffset = options.flowAsArrows.value and -2 or 1

	windowData.metalPanel.label_income:Invalidate()
	windowData.metalPanel.label_overdrive:Invalidate()
	windowData.metalPanel.label_reclaim:Invalidate()
	windowData.energyPanel.label_income:Invalidate()
	windowData.energyPanel.label_overdrive:Invalidate()
	windowData.energyPanel.label_reclaim:Invalidate()
	windowData.metalPanel.mainPanel:Invalidate()
	windowData.energyPanel.mainPanel:Invalidate()
end

local function UpdatePlayerWindowFonts()
	playerWindow.nameLeft.font.size = options.playerMainFontSize.value
	playerWindow.nameRight.font.size = options.playerMainFontSize.value
	playerWindow.winsLeft.font.size = options.playerMainFontSize.value
	playerWindow.winsRight.font.size = options.playerMainFontSize.value
	
	playerWindow.nameLeft:Invalidate()
	playerWindow.nameRight:Invalidate()
	playerWindow.winsLeft:Invalidate()
	playerWindow.winsRight:Invalidate()
	playerWindow.mainPanel:Invalidate()
end

local function option_UpdateFonts()
	if economyWindowData then
		UpdateResourceWindowFonts(economyWindowData[1])
		UpdateResourceWindowFonts(economyWindowData[2])
	end
	if playerWindow then
		UpdatePlayerWindowFonts()
	end
end

local function option_ColourBlindUpdate()
	positiveColourStr = (options.colourBlind.value and YellowStr) or GreenStr
	negativeColourStr = (options.colourBlind.value and BlueStr) or RedStr
	col_expense = (options.colourBlind.value and {.2,.3,1,1}) or {1,.3,.2,1}
end

local function ShowOptions(self)
	local alt, ctrl, meta, shift = Spring.GetModKeyState()
	if not meta then
		return false
	end
	WG.crude.OpenPath(options_path)
	WG.crude.ShowMenu()
	return true
end

ShowOptions = {ShowOptions}

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Options

options_path = 'Settings/HUD Panels/Spectator Panels'

options_order = {
	'enableSpectator',
	'clanNameLengthCutoff',
	
	'lable_playerPanel',
	'enablePlayerPanel',
	'playerOpacity',
	'playerMainFontSize',
	'playerFontSize',
	
	'lable_economyPanels',
	'enableEconomyPanels',
	'resourceOpacity',
	'resourceMainFontSize',
	'resourceFontSize',
	'flowAsArrows',
	'colourBlind',
	'fancySkinning',
}
 
local econName, econPath = "Chili Economy Panel Default", "Settings/HUD Panels/Economy Panel"
options = {
	enableSpectator = {
		name  = "Enable as Spectator",
		type  = "bool",
		value = false,
		OnChange = function(self)
			local enabled = option_CheckEnable(self)
			WG.SetWidgetOption(econName, econPath, "ecoPanelHideSpec", enabled)
		end,
		desc = "Enables the spectator resource bars when spectating a game with two teams."
	},
	clanNameLengthCutoff = {
		name  = "Max Clan Name Length",
		type  = "number",
		value = 12, min = 0, max = 60, step = 1,
		desc = "Clans with full names shorter than this are displayed in full. Otherwise the short name is used. Requires reload."
	},
	
	lable_playerPanel = {type = 'label', name = 'Player Panel',},
	enablePlayerPanel = {
		name  = "Enable Player Panel",
		type  = "bool",
		value = true,
		OnChange = function(self) option_CheckEnablePlayer(self) end,
	},
	playerOpacity = {
		name  = "Opacity",
		type  = "number",
		value = 0.6, min = 0, max = 1, step = 0.01,
		OnChange = function(self)
				if playerWindow then
					playerWindow.mainPanel.color = {1,1,1,self.value}
					playerWindow.mainPanel.backgroundColor = {1,1,1,self.value}
					playerWindow.mainPanel:Invalidate()
					playerWindow.window:Invalidate()
				end
			end,
	},
	playerMainFontSize = {
		name  = "Main Font Size",
		type  = "number",
		value = 25, min = 8, max = 60, step = 1,
		OnChange = option_UpdateFonts,
	},
	playerFontSize = {
		name  = "Font Size",
		type  = "number",
		value = 16, min = 8, max = 40, step = 1,
		OnChange = option_UpdateFonts,
	},
	
	lable_economyPanels = {type = 'label', name = 'Economy Panels',},
	enableEconomyPanels = {
		name  = "Enable Economy Panels",
		type  = "bool",
		value = true,
		OnChange = function(self) option_CheckEnableResource(self) end,
	},
	flowAsArrows = {
		name  = "Flow as arrows",
		desc = "Use arrows instead of a number for the flow. Each arrow is 5 resources per second.",
		type  = "bool",
		value = true,
		noHotkey = true,
		OnChange = option_UpdateFonts,
	},
	resourceOpacity = {
		name  = "Opacity",
		type  = "number",
		value = 0.6, min = 0, max = 1, step = 0.01,
		OnChange = function(self)
				if economyWindowData then
					economyWindowData[1].metalPanel.mainPanel.color = {1,1,1,self.value}
					economyWindowData[1].metalPanel.mainPanel.backgroundColor = {1,1,1,self.value}
					economyWindowData[1].metalPanel.mainPanel:Invalidate()
					economyWindowData[1].energyPanel.mainPanel.color = {1,1,1,self.value}
					economyWindowData[1].energyPanel.mainPanel.backgroundColor = {1,1,1,self.value}
					economyWindowData[1].energyPanel.mainPanel:Invalidate()
					economyWindowData[1].window:Invalidate()
					
					economyWindowData[2].metalPanel.mainPanel.color = {1,1,1,self.value}
					economyWindowData[2].metalPanel.mainPanel.backgroundColor = {1,1,1,self.value}
					economyWindowData[2].metalPanel.mainPanel:Invalidate()
					economyWindowData[2].energyPanel.mainPanel.color = {1,1,1,self.value}
					economyWindowData[2].energyPanel.mainPanel.backgroundColor = {1,1,1,self.value}
					economyWindowData[2].energyPanel.mainPanel:Invalidate()
					economyWindowData[2].window:Invalidate()
				end
			end,
	},
	resourceMainFontSize = {
		name  = "Main Font Size",
		type  = "number",
		value = 25, min = 8, max = 60, step = 1,
		OnChange = option_UpdateFonts,
	},
	resourceFontSize = {
		name  = "Font Size",
		type  = "number",
		value = 16, min = 8, max = 40, step = 1,
		OnChange = option_UpdateFonts,
	},
	colourBlind = {
		name  = "Colourblind mode",
		type  = "bool",
		value = false,
		noHotkey = true,
		OnChange = option_ColourBlindUpdate,
		desc = "Uses Blue and Yellow instead of Red and Green for number display"
	},
	fancySkinning = {
		name = 'Fancy Skinning',
		type = 'radioButton',
		value = 'panel',
		items = {
			{key = 'panel', name = 'None'},
			--{key = 'panel_0001', name = 'Flush',},
			{key = 'panel_1011', name = 'Not Flush',},
		},
		OnChange = function (self)
			if not (playerWindow and playerWindow.mainPanel) then
				return
			end
			local currentSkin = Chili.theme.skin.general.skinName
			local skin = Chili.SkinHandler.GetSkin(currentSkin)
			
			local className = self.value
			local newClass = skin.panel
			if skin[className] then
				newClass = skin[className]
			end
			
			playerWindow.mainPanel.tiles = newClass.tiles
			playerWindow.mainPanel.TileImageFG = newClass.TileImageFG
			--playerWindow.mainPanel.backgroundColor = newClass.backgroundColor
			playerWindow.mainPanel.TileImageBK = newClass.TileImageBK
			if newClass.padding then
				playerWindow.mainPanel.padding = newClass.padding
				playerWindow.mainPanel:UpdateClientArea()
			end
			playerWindow.mainPanel:Invalidate()
		end,
		hidden = true,
		noHotkey = true,
	},
}

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Resource Window Management

local function Mix(startColour, endColour, interpParam)
	return {endColour[1] * interpParam + startColour[1] * (1 - interpParam),
	endColour[2] * interpParam + startColour[2] * (1 - interpParam),
	endColour[3] * interpParam + startColour[3] * (1 - interpParam),
	endColour[4] * interpParam + startColour[4] * (1 - interpParam), }
end

local BlinkStatusFunc = {
	[1] = function (index)
		index = index%12
		if index < 6 then
			return index*0.8/5
		else
			return (11 - index)*0.8/5
		end
	end,
	[2] = function (index)
		index = index%8
		if index < 4 then
			return 0.25 + index*0.75/3
		else
			return 0.25 + (7 - index)*0.75/3
		end
	end,
}

local BLINK_UPDATE_RATE = 0.1

local function UpdateResourceWindowFlash(sideID, blinkIndex)
	local windowData = economyWindowData[sideID]
	
	if windowData.metalPanel.flashing then
		windowData.metalPanel.bar:SetColor(Mix({col_metal[1], col_metal[2], col_metal[3], 0.65}, col_expense, BlinkStatusFunc[windowData.metalPanel.flashing](blinkIndex)))
	end

	if windowData.energyPanel.flashing then
		windowData.energyPanel.barOverlay:SetColor(col_expense[1], col_expense[2], col_expense[3], BlinkStatusFunc[windowData.energyPanel.flashing](blinkIndex)*0.7)
	end
end

function UpdateResourceWindowFlashMain(blinkIndex)
	UpdateResourceWindowFlash(1, blinkIndex)
	UpdateResourceWindowFlash(2, blinkIndex)
end

local function GetFontMult(input)
	if input < 10^3 - 0.5 then
		return 1
	else
		return 0.8
	end
end

local function Format(input, override)
	
	local leadingString = positiveColourStr .. "+"
	if input < 0 then
		leadingString = negativeColourStr .. "-"
	end
	leadingString = override or leadingString
	input = math.abs(input)
	
	if input < 0.05 then
		if override then
			return override .. "0.0"
		end
		return WhiteStr .. "0"
	elseif input < 10 - 0.05 then
		return leadingString .. ("%.1f"):format(input) .. WhiteStr
	elseif input < 10^3 - 0.5 then
		return leadingString .. ("%.0f"):format(input) .. WhiteStr
	elseif input < 10^4 then
		return leadingString .. ("%.1f"):format(input/1000) .. "k" .. WhiteStr
	elseif input < 10^5 then
		return leadingString .. ("%.0f"):format(input/1000) .. "k" .. WhiteStr
	else
		return leadingString .. ("%.0f"):format(input/1000) .. "k" .. WhiteStr
	end
end

local function GetTimeString()
  local secs = math.floor(Spring.GetGameSeconds())
  if (timeSecs ~= secs) then
    timeSecs = secs
    local h = math.floor(secs / 3600)
    local m = math.floor((secs % 3600) / 60)
    local s = math.floor(secs % 60)
    if (h > 0) then
      timeString = string.format('%02i:%02i:%02i', h, m, s)
    else
      timeString = string.format('%02i:%02i', m, s)
    end
  end
  return timeString
end

local function UpdateResourcePanel(panel, income, net, overdrive, reclaim, storage, storageMax)
	if storageMax > 0 then
		panel.bar:SetValue(100*storage/storageMax)
	else
		panel.bar:SetValue(0)
	end
	
	-- local newFontSize = math.round(GetFontMult(income)*options.resourceMainFontSize.value)
	-- panel.label_income.font.size = newFontSize
	panel.label_income.font.size =math.round(GetFontMult(income)*options.resourceMainFontSize.value)
	panel.label_income:Invalidate()
	panel.label_income:SetCaption(Format(income, ""))
	
	if panel.barOverlay then
		panel.barOverlay:SetCaption(GetFlowStr(net, options.flowAsArrows.value, positiveColourStr, negativeColourStr))
		panel.barOverlay.net = net
	else
		panel.bar:SetCaption(GetFlowStr(net, options.flowAsArrows.value, positiveColourStr, negativeColourStr))
		panel.bar.net = net
	end
	
	panel.label_overdrive:SetCaption("OD: " .. Format(overdrive))
	panel.label_reclaim:SetCaption("Re: " .. Format(reclaim))
end

local function UpdateResourceWindowPanel(sideID)
	local allyTeamID = allyTeamData[sideID].allyTeamID
	local teams = Spring.GetTeamList(allyTeamID)
	local windowData = economyWindowData[sideID]
	
	if not (teams and teams[1]) or (not windowData) then
		return
	end
	
	--// Update Economy Values
	-- These are the values displayed on the UI
	local metalIncome = 0
	local metalOverdrive = spGetTeamRulesParam(teams[1], "OD_team_metalOverdrive") or 0
	-- metalReclaim set below
	local metalStorage = 0
	local metalStorageMax = 0
	
	local metalSpent = 0
	
	local energyWaste = spGetTeamRulesParam(teams[1], "OD_team_energyWaste") or 0
	-- energyIncome set below
	local energyOverdrive = spGetTeamRulesParam(teams[1], "OD_team_energyOverdrive") or 0
	local energyReclaim = 0
	local energyStorage = 0
	local energyStorageMax = 0
	
	-- Calculate the values
	for i = 1, #teams do
		local mCurr, mStor, mPull, mInco, mExpe, mShar, mSent, mReci = spGetTeamResources(teams[i], "metal")
		metalIncome = metalIncome + (mInco or 0)
		metalStorage = metalStorage + (mCurr or 0)
		metalStorageMax = metalStorageMax + (mStor or 0) - HIDDEN_STORAGE
		
		metalSpent = metalSpent + (mExpe or 0)
		
		local extraMetalPull = spGetTeamRulesParam(teams[i], "extraMetalPull") or 0
		
		local eCurr, eStor, ePull, eInco, eExpe, eShar, eSent, eReci = spGetTeamResources(teams[i], "energy")
		local extraEnergyPull = spGetTeamRulesParam(teams[i], "extraEnergyPull") or 0
		
		local energyOverdrive = spGetTeamRulesParam(teams[i], "OD_energyOverdrive") or 0
		local energyChange    = spGetTeamRulesParam(teams[i], "OD_energyChange") or 0
		local extraChange     = math.min(0, energyChange) - math.min(0, energyOverdrive)
		
		energyReclaim = energyReclaim + (eInco or 0) - math.max(0, energyChange)
		
		energyStorage = energyStorage + math.min((eCurr or 0), (eStor or 0) - HIDDEN_STORAGE)
		energyStorageMax = energyStorageMax + (eStor or 0) - HIDDEN_STORAGE
	end
	
	energyReclaim = math.max(0, energyReclaim)
	
	local metalReclaim = metalIncome
			- (spGetTeamRulesParam(teams[1], "OD_team_metalOverdrive") or 0)
			- (spGetTeamRulesParam(teams[1], "OD_team_metalBase") or 0)
			- (spGetTeamRulesParam(teams[1], "OD_team_metalMisc") or 0)
	local energyIncome = (spGetTeamRulesParam(teams[1], "OD_team_energyIncome") or 0) + energyReclaim
	
	local metalNet = metalStorage - (economyWindowData[sideID].lastMetalStorage or 0)
	economyWindowData[sideID].lastMetalStorage = metalStorage
	
	local energyNet = energyStorage - (economyWindowData[sideID].lastEnergyStorage or 0)
	economyWindowData[sideID].lastEnergyStorage = energyStorage
	
	--// Flashing
	local newMetalFlash = (metalIncome - metalSpent + metalStorage >= metalStorageMax)
	if windowData.metalPanel.flashing and not newMetalFlash then
		windowData.metalPanel.bar:SetColor(col_metal)
	end
	windowData.metalPanel.flashing = newMetalFlash and 1
	
	local newEnergyFlash = (energyStorage <= energyStorageMax*0.1)
		or (energyWaste > 0)
	if windowData.energyPanel.flashing and not newEnergyFlash then
		windowData.energyPanel.barOverlay:SetColor(col_empty)
	end
	windowData.energyPanel.flashing = newEnergyFlash and 1

	--// Update GUI
	UpdateResourcePanel(windowData.metalPanel, metalIncome, metalNet,
		metalOverdrive, metalReclaim, metalStorage, metalStorageMax)
	UpdateResourcePanel(windowData.energyPanel, energyIncome, energyNet,
		-energyOverdrive, energyReclaim, energyStorage, energyStorageMax)
end

function UpdateResourceWindowMain()
	UpdateResourceWindowPanel(1)
	UpdateResourceWindowPanel(2)
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Resource Window Creation

local function CreateResourceWindowPanel(parentData, left, width, resourceColor, barOverlay)
	local parentPanel = parentData.mainPanel
	local data = {}
	
	--// Panel configuration
	local incomeX      = "1%"
	local incomeY      = "10%"
	local incomeWidth  = "24%"
	local incomeHeight = "70%"
	
	local overdriveX    = "29%"
	local reclaimX     = "63%"
	local textY       = "51%"
	local textWidth   = "60%"
	local textHeight  = "32%"
	
	local barX      = "26%"
	local barY      = "12%"
	local barRight  = "4%"
	local barHeight = "36%"
	
	data.mainPanel = Chili.Control:New{
		parent = parentPanel,
		x      = left,
		width  = width,
		y      = 0,
		bottom = 0,
		padding = {0,0,0,0},
		backgroundColor = {1,1,1,options.resourceOpacity.value},
		color = {1,1,1,options.resourceOpacity.value},
		dockable = false;
		draggable = false,
		resizable = false,
		OnMouseDown = ShowOptions,
	}
	
	if barOverlay then
		data.barOverlay = Chili.Progressbar:New{
			parent = data.mainPanel,
			orientation = "horizontal",
			value  = 100,
			color  = {0,0,0,0},
			x      = barX,
			y      = barY,
			right  = barRight,
			height = barHeight,
			noSkin = true,
			fontOffset = -2,
			font   = {
				size = 20,
				color = {.8,.8,.8,.95},
				outline = true,
				outlineWidth = 2,
				outlineWeight = 2
			},
			net = 0, -- cache, not a chili thing
		}
	end
	
	data.bar = Chili.Progressbar:New{
		parent = data.mainPanel,
		color  = resourceColor,
		orientation = "horizontal",
		x      = barX,
		y      = barY,
		right  = barRight,
		height = barHeight,
		value  = 0,
		fontShadow = false,
		fontOffset = -2,
		font   = {
			size = 20,
			color = {.8,.8,.8,.95},
			outline = true,
			outlineWidth = 2,
			outlineWeight = 2
		},
		net = 0, -- cache, not a chili thing
	}
	
	data.label_income = Chili.Label:New{
		parent = data.mainPanel,
		x      = incomeX,
		y      = incomeY,
		width  = incomeWidth,
		height = incomeHeight,
		caption = "0.0",
		valign = "center",
 		align  = "center",
		autosize = false,
		font   = {
			size = options.resourceMainFontSize.value,
			outline = true,
			outlineWidth = 2,
			outlineWeight = 2,
			color = resourceColor,
		},
	}
	
	data.label_overdrive = Chili.Label:New{
		parent = data.mainPanel,
		x      = overdriveX,
		y      = textY,
		width  = textWidth,
		height = textHeight,
		caption = "OD: 0",
		valign = "center",
 		align  = "left",
		autosize = false,
		font   = {size = options.resourceFontSize.value, outline = true, outlineWidth = 2, outlineWeight = 2},
	}
	
	data.label_reclaim = Chili.Label:New{
		parent = data.mainPanel,
		x      = reclaimX,
		y      = textY,
		width  = textWidth,
		height = textHeight,
		caption = "Re: 0",
		valign = "center",
 		align  = "left",
		autosize = false,
		font   = {size = options.resourceFontSize.value, outline = true, outlineWidth = 2, outlineWeight = 2},
	}
	
	return data
end

local function CreateResourceWindow(allyTeamDataNumber, x, width)
	local data = {}
	
	data.window = Chili.Window:New{
		parent = screen0,
		dockable = true,
		name = "SpectatorEconomyPanel_vz_" .. allyTeamDataNumber,
		x = x,
		y = 58,
		width  = width,
		height = 62,
		classname = "main_window_small_very_flat",
		draggable = false,
		resizable = false,
		tweakDraggable = true,
		tweakResizable = true,
		minimizable = false,
		OnMouseDown = ShowOptions,
		tooltip = "Economy for " .. allyTeamData[allyTeamDataNumber].name,
	}
	
	data.mainPanel = Chili.Control:New{
		parent = data.window,
		padding = {0,0,0,0},
		y      = 0,
		x      = 0,
		right  = 0,
		bottom = 0,
		dockable = false;
		draggable = false,
		resizable = false,
		OnMouseDown = ShowOptions,
		tooltip = "Economy for " .. allyTeamData[allyTeamDataNumber].name,
	}
	
	function data.window:HitTest(x,y) return self end
	function data.mainPanel:HitTest(x,y) return self end
	
	data.metalPanel = CreateResourceWindowPanel(data, 0, "50%", col_metal, false)
	data.energyPanel = CreateResourceWindowPanel(data, "50%", "50%", col_energy, true)
	
	return data
end

local function AddEconomyWindows()
	if enabledEconomy then
		return
	end
	if economyWindowData then
		screen0:AddChild(economyWindowData[1].window)
		screen0:AddChild(economyWindowData[2].window)
	else
		Spring.SendCommands("resbar 0")
		
		local screenWidth,screenHeight = Spring.GetWindowGeometry()
		local screenHorizCentre = screenWidth / 2
		local spacing = 360
		local econWidth = 480
		
		economyWindowData = {
			[1] = CreateResourceWindow(1, screenHorizCentre - spacing/2 - econWidth, econWidth),
			[2] = CreateResourceWindow(2, screenHorizCentre + spacing/2, econWidth),
		}
	end
	enabledEconomy = true
end

local function RemoveEconomyWindows()
	if enabledEconomy then
		screen0:RemoveChild(economyWindowData[1].window)
		screen0:RemoveChild(economyWindowData[2].window)
		enabledEconomy = false
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Player Window Creation

local function CreatePlayerWindow()
	local data = {}
	
	local screenWidth,screenHeight = Spring.GetWindowGeometry()
	local screenHorizCentre = screenWidth / 2
	local playerWindowWidth = 500

	data.window = Chili.Window:New{
		parent = screen0,
		backgroundColor = {0, 0, 0, 0},
		color = {0, 0, 0, 0},
		dockable = true,
		name = "SpectatorPlayerPanel",
		padding = {0,0,0,0},
		x = screenHorizCentre - playerWindowWidth/2,
		y = 0,
		clientWidth  = playerWindowWidth,
		clientHeight = 50,
		draggable = false,
		resizable = false,
		tweakDraggable = true,
		tweakResizable = true,
		minimizable = false,
		OnMouseDown = ShowOptions,
	}
	
	data.mainPanel = Chili.Panel:New{
		classname = options.fancySkinning.value,
		backgroundColor = {1,1,1,options.playerOpacity.value},
		color = {1,1,1,options.playerOpacity.value},
		parent = data.window,
		padding = {0,0,0,0},
		y      = 0,
		x      = 0,
		right  = 0,
		bottom = 0,
		dockable = false;
		draggable = false,
		resizable = false,
		OnMouseDown = ShowOptions,
	}
	
	function data.window:HitTest(x,y) return self end
	function data.mainPanel:HitTest(x,y) return self end
	
	-- Panel internals
	local nameOuter = 45
	local nameInner = "51%"
	local winsOuter = 16
	local winsInner = "80%"
	
	local texY = "8%"
	local texBottom = "15%"

	data.time = Chili.Label:New{
		parent = data.mainPanel,
		x      = 0,
		y      = texY,
		right  = 0,
		bottom = texBottom,
		caption = GetTimeString(),
		valign = "center",
 		align  = "center",
		autosize = false,
		font   = {
			size = math.round(options.playerMainFontSize.value*allyTeamData[1].nameSize),
			outline = true,
			outlineWidth = 2,
			outlineWeight = 2,
			color = {0.95, 1.0, 1.0, 1},
		},
	}
	
	data.nameLeft = Chili.Label:New{
		parent = data.mainPanel,
		x      = nameOuter,
		y      = texY,
		right  = nameInner,
		bottom = texBottom,
		caption = allyTeamData[1].name,
		valign = "center",
 		align  = "left",
		autosize = false,
		font   = {
			size = math.round(options.playerMainFontSize.value*allyTeamData[1].nameSize),
			outline = true,
			outlineWidth = 2,
			outlineWeight = 2,
			color = allyTeamData[1].color,
		},
	}
	
	data.nameRight = Chili.Label:New{
		parent = data.mainPanel,
		x      = nameInner,
		y      = texY,
		right  = nameOuter,
		bottom = texBottom,
		caption = allyTeamData[2].name,
		valign = "center",
 		align  = "right",
		autosize = false,
		font   = {
			size = math.round(options.playerMainFontSize.value*allyTeamData[2].nameSize),
			outline = true,
			outlineWidth = 2,
			outlineWeight = 2,
			color = allyTeamData[2].color,
		},
	}
	
	data.winsLeft  = Chili.Label:New{
		parent = data.mainPanel,
		x      = winsOuter,
		y      = texY,
		right  = winsInner,
		bottom = texBottom,
		caption = allyTeamData[1].winString,
		valign = "center",
 		align  = "left",
		autosize = false,
		font   = {
			size = options.playerMainFontSize.value,
			outline = true,
			outlineWidth = 2,
			outlineWeight = 2,
			color = allyTeamData[1].color,
		},
	}
	
	data.winsRight  = Chili.Label:New{
		parent = data.mainPanel,
		x      = winsInner,
		y      = texY,
		right  = winsOuter,
		bottom = texBottom,
		caption = allyTeamData[2].winString,
		valign = "center",
 		align  = "right",
		autosize = false,
		font   = {
			size = options.playerMainFontSize.value,
			outline = true,
			outlineWidth = 2,
			outlineWeight = 2,
			color = allyTeamData[2].color,
		},
	}
	
	return data
end

local function AddPlayerWindow()
	if enabledPlayer then
		return
	end
	if playerWindow then
		screen0:AddChild(playerWindow.window)
	else
		playerWindow = CreatePlayerWindow()
	end
	enabledPlayer = true
end

local function RemovePlayerWindow()
	if enabledPlayer then
		screen0:RemoveChild(playerWindow.window)
		enabledPlayer = false
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Window Visiblity Management

local function GetWinString(name)
	local winTable = WG.WinCounter_currentWinTable
	if winTable and winTable[name] and winTable[name].wins then
		return (winTable[name].wonLastGame and "*" or "") .. winTable[name].wins
	end
	return ""
end

local function GetOpposingAllyTeams()
	local gaiaAllyTeamID = select(6, Spring.GetTeamInfo(Spring.GetGaiaTeamID(), false))
	local returnData = {}
	local allyTeamList = GetLeftRightAllyTeamIDs()
	for i = 1, #allyTeamList do
		local allyTeamID = allyTeamList[i]

		local teamList = Spring.GetTeamList(allyTeamID)
		if allyTeamID ~= gaiaAllyTeamID and #teamList > 0 then

			local winString
			local playerName
			for j = 1, #teamList do
				local _, playerID, _, isAI = Spring.GetTeamInfo (teamList[j], false)
				if not isAI then
					playerName = Spring.GetPlayerInfo(playerID, false)
					winString = GetWinString(playerName)
					break
				end
			end

			local name = Spring.GetGameRulesParam("allyteam_long_name_" .. allyTeamID) or "Unknown"
			if name and string.len(name) > options.clanNameLengthCutoff.value then
				name = Spring.GetGameRulesParam("allyteam_short_name_" .. allyTeamID) or name
			end

			returnData[#returnData + 1] = {
				allyTeamID = allyTeamID, -- allyTeamID for the team
				name = name, -- Large display name of the team
				nameSize = 1, -- Display size factor of the team name.
				teamID = teamList[1], -- representitive teamID
				color = {Spring.GetTeamColor(teamList[1])} or {1,1,1,1}, -- color of the teams text (color of first player)
				playerName = playerName or "AI", -- representitive player name (for win counter)
				winString = winString or "0", -- Win string from win counter
			}
		end
	end

	if #returnData ~= 2 then
		return false
	end
	
	return returnData
end


function option_CheckEnable(self)
	if not self.value then
		if enabled then
			RemovePlayerWindow()
			RemoveEconomyWindows()
			enabled = false
			WG.SpectatorPanels_enabled = false
		end
		return false
	end
	
	local spectating = select(1, Spring.GetSpectatingState())
	if not spectating then
		if enabled then
			RemovePlayerWindow()
			RemoveEconomyWindows()
			enabled = false
			WG.SpectatorPanels_enabled = false
		end
		return false
	end
	
	if enabled then
		WG.SpectatorPanels_enabled = true
		return true
	end
	
	allyTeamData = GetOpposingAllyTeams()
	if not allyTeamData then
		enabled = false
		WG.SpectatorPanels_enabled = false
		return false
	end
	
	if options.enablePlayerPanel.value then
		AddPlayerWindow()
	end
	
	if options.enableEconomyPanels.value then
		AddEconomyWindows()
	end
	
	option_UpdateFonts()

	enabled = true
	WG.SpectatorPanels_enabled = true
	return true
end

function option_CheckEnablePlayer(self)
	if not options.enableSpectator.value then
		return
	end
	
	if self.value then
		AddPlayerWindow()
	else
		RemovePlayerWindow()
	end
end

function option_CheckEnableResource(self)
	if not options.enableSpectator.value then
		return
	end
	
	if self.value then
		AddEconomyWindows()
	else
		RemoveEconomyWindows()
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:Shutdown()
	WG.SpectatorPanels_enabled = false
end

function widget:PlayerChanged(pID)
	if pID == Spring.GetMyPlayerID() then
		local oldEnabled = enabled
		local newEnabled = option_CheckEnable(options.enableSpectator)
		if WG.EconomyPanel and (newEnabled ~= oldEnabled) then
			-- new second arg is "dispose"
			-- I don't know if it specifically requires panel to be disposed, but let's do so to avoid behavior changes - KR
			WG.EconomyPanel.SetEconomyPanelVisibility(not newEnabled, true)
		end
	end
end

function widget:Initialize()
	Chili = WG.Chili
	screen0 = Chili.Screen0
	
	if (not Chili) then
		widgetHandler:RemoveWidget()
		return
	end
	option_ColourBlindUpdate()
end

local timer = 0
local blinkTimer = 0
local blinkIndex = 0
local loadOrderIndependentSpectatorCheckDone = false
function widget:Update(dt)
	--If the Economy Panel loads after this, then option_CheckEnable won't properly
	--set the Economy Panel's visibility. This check works around that problem.
	if not loadOrderIndependentSpectatorCheckDone then
		options.enableSpectator.OnChange(options.enableSpectator)
		loadOrderIndependentSpectatorCheckDone = true
	end

	timer = timer + dt
	if economyWindowData then
		blinkTimer = blinkTimer + dt
		if blinkTimer >= BLINK_UPDATE_RATE then
			blinkTimer = blinkTimer - BLINK_UPDATE_RATE
			blinkIndex = (blinkIndex + 1)%24
			UpdateResourceWindowFlashMain(blinkIndex)
		end
	end
	if timer >= 1 and playerWindow then
		playerWindow.time:SetCaption(GetTimeString())
		playerWindow.winsLeft:SetCaption(GetWinString(allyTeamData[1].playerName))
		playerWindow.winsRight:SetCaption(GetWinString(allyTeamData[2].playerName))
		timer = 0
	end
end

function widget:GameFrame(n)
	if economyWindowData and n%TEAM_SLOWUPDATE_RATE == 0 then
		UpdateResourceWindowMain()
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
