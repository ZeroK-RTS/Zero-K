--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
	return {
		name      = "Galaxy Battle Handler",
		desc      = "Reports outcome of galaxy battle.",
		author    = "GoogleFrog",
		date      = "7 February 2016",
		license   = "GNU GPL, v2 or later",
		layer     = 0,
		enabled   = true,
		alwaysStart = true,
		hidden    = true,
	}
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
local campaignBattleID = Spring.GetModOptions().singleplayercampaignbattleid
if not campaignBattleID then
	return
end

local BUTTON_SIZE = 25
local BONUS_TOGGLE_IMAGE = 'LuaUI/images/plus_green.png'

local spGetMouseState = Spring.GetMouseState

local max, min = math.max, math.min

local glColor               = gl.Color
local glTexture             = gl.Texture
local glPopMatrix           = gl.PopMatrix
local glPushMatrix          = gl.PushMatrix
local glTranslate           = gl.Translate
local glText                = gl.Text
local glBeginEnd            = gl.BeginEnd
local glTexRect             = gl.TexRect
local glLoadFont            = gl.LoadFont
local glDeleteFont          = gl.DeleteFont
local glRect                = gl.Rect
local glLineWidth           = gl.LineWidth
local glDepthTest           = gl.DepthTest

local osClock               = os.clock

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Variables/config

local Chili

local WIN_MESSAGE = "Campaign_PlanetBattleWon"
local LOST_MESSAGE = "Campaign_PlanetBattleLost"
local LOAD_CAMPAIGN_MESSAGE = "Campaign_LoadCampaign"
local myAllyTeamID = Spring.GetMyAllyTeamID()

local SUCCESS_ICON = LUAUI_DIRNAME .. "images/tick.png"
local FAILURE_ICON = LUAUI_DIRNAME .. "images/cross.png"
local OBJECTIVE_ICON = LUAUI_DIRNAME .. "images/bullet.png"

local mainObjectiveBlock, bonusObjectiveBlock
local globalCommandButton

local SetBonusObjectivesVisibility

local missionWon, missionEndFrame, missionEndTime, missionResultSent

-- wait this many frames after victory to make sure your commander doesn't die.
local VICTORY_SUSTAIN_FRAMES = 50 

----------------------------------------------------------------------------------
----------------------------------------------------------------------------------
-- Endgame screen

local boxWidth = 240
local boxHeight = 60
local autoFadeTime = 1.9
local continueFadeInTime = 1.3
local wndBorderSize = 4
local fontSizeHeadline = 84
local fontSizeAddon = 20
local fontPath = "LuaUI/Fonts/MicrogrammaDBold.ttf"
local minTransparency_autoFade = 0.1
local maxTransparency_autoFade = 0.7

local screenx, screeny, myFont
local screenCenterX, screenCenterY, wndX1, wndY1, wndX2, wndY2
local victoryTextX, defeatTextX, defeatTextX, lowerTextX
local textY, lineOffset, yCenter, xCut, mouseOver

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Utilities

local function CustomKeyToUsefulTable(dataRaw)
	if not dataRaw then
		return
	end
	if not (dataRaw and type(dataRaw) == 'string') then
		if dataRaw then
			Spring.Echo("Customkey data error for team", teamID)
		end
	else
		dataRaw = string.gsub(dataRaw, '_', '=')
		dataRaw = Spring.Utilities.Base64Decode(dataRaw)
		local dataFunc, err = loadstring("return " .. dataRaw)
		if dataFunc then 
			local success, usefulTable = pcall(dataFunc)
			if success then
				if collectgarbage then
					collectgarbage("collect")
				end
				return usefulTable
			end
		end
		if err then
			Spring.Echo("Customkey error", err)
		end
	end
	if collectgarbage then
		collectgarbage("collect")
	end
end

local function SetWindowSkin(targetPanel, className)
	local currentSkin = Chili.theme.skin.general.skinName
	local skin = Chili.SkinHandler.GetSkin(currentSkin)
	local newClass = skin.panel
	if skin[className] then
		newClass = skin[className]
	end
	
	targetPanel.tiles = newClass.tiles
	targetPanel.TileImage = newClass.TileImage
	--targetPanel.backgroundColor = newClass.backgroundColor
	if newClass.padding then
		targetPanel.padding = newClass.padding
		targetPanel:UpdateClientArea()
	end
	targetPanel:Invalidate()
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Objectives Handler

local function GetObjectivesBlock(holderWindow, position, items, gameRulesParam)
	
	local missionsLabel = Chili.Label:New{
		x = 8,
		y = position,
		width = "100%",
		height = 18,
		align = "left",
		valign = "top",
		caption = "",
		fontsize = 18,
		parent = holderWindow,
	}
	position = position + 26
	
	local objectives = {}
	
	for i = 1, #items do
		local label = Chili.TextBox:New{
			x = 22,
			y = position,
			right = 4,
			height = 18,
			align = "left",
			valign = "top",
			text = items[i].description,
			fontsize = 14,
			parent = holderWindow,
		}
		local image = Chili.Image:New{
			x = 4,
			y = position - 3,
			width = 16,
			height = 16,
			file = OBJECTIVE_ICON,
			parent = holderWindow,
		}
		objectives[i] = {
			position = position,
			label = label,
			image = image,
		}
		position = position + (#label.physicalLines)*16
	end
	
	local function UpdateSuccess(index)
		if objectives[index].terminated then
			return
		end
		local newSuccess = Spring.GetGameRulesParam(gameRulesParam .. index)
		if not newSuccess then
			return
		end
		
		objectives[index].image.file = (newSuccess == 1 and SUCCESS_ICON) or FAILURE_ICON
		objectives[index].image:Invalidate()
		
		objectives[index].success = (newSuccess == 1)
		objectives[index].terminated = true
		objectives[index].image = image
	end
	
	local function UpdateObjectiveSuccess()
		if gameRulesParam then
			for i = 1, #objectives do
				UpdateSuccess(i)
			end
		end
	end
	
	UpdateObjectiveSuccess()
	
	local externalFunctions = {}
	
	function externalFunctions.Update()
		UpdateObjectiveSuccess()
	end
	function externalFunctions.UpdateTooltip(text)
		missionsLabel:SetCaption(text)
	end
	
	function externalFunctions.MakeObjectivesString()
		local objectivesString = ""
		for i = 1, #objectives do
			if objectives[i].success then
				objectivesString = objectivesString .. "1"
			else
				objectivesString = objectivesString .. "0"
			end
		end
		return objectivesString
	end
	
	return externalFunctions, position
end

local function InitializeObjectivesWindow()
	local objectiveList = CustomKeyToUsefulTable(Spring.GetModOptions().objectiveconfig) or {}
	local bonusObjectiveList = CustomKeyToUsefulTable(Spring.GetModOptions().bonusobjectiveconfig) or {}
	
	local thereAreBonusObjectives = (bonusObjectiveList and #bonusObjectiveList > 0)
	
	local holderWindow = Chili.Window:New{
		classname = "main_window_small",
		name = 'mission_galaxy_objectives',
		x = 2,
		y = 50,
		width = 320,
		height = 22 + 16*(#objectiveList),
		dockable = true,
		draggable = false,
		resizable = false,
		tweakDraggable = true,
		tweakResizable = false,
		parent = Chili.Screen0,
	}
	
	local position = 4
	mainObjectiveBlock, position = GetObjectivesBlock(holderWindow, position, objectiveList,  "objectiveSuccess_")
	local mainHeight = position + holderWindow.padding[2] + holderWindow.padding[4] + 3 
	local bonusHeight
	
	if #bonusObjectiveList > 0 then
		position = position + 8
		bonusObjectiveBlock, position = GetObjectivesBlock(holderWindow, position, bonusObjectiveList, "bonusObjectiveSuccess_")
		bonusHeight = position + holderWindow.padding[2] + holderWindow.padding[4] + 3 
	end
	
	if WG.GlobalCommandBar then
		local function ToggleWindow()
			if holderWindow then
				holderWindow:SetVisibility(not holderWindow.visible)
			end
		end
		globalCommandButton = WG.GlobalCommandBar.AddCommand(LUAUI_DIRNAME .. "images/advplayerslist/random.png", "", ToggleWindow)
	end
	
	holderWindow:SetPos(nil, nil, nil, position + holderWindow.padding[2] + holderWindow.padding[4] + 3)
	
	local bonusVisible = true
	local function SetBonusVisibility(newVisible)
		if (not thereAreBonusObjectives) or (newVisible == bonusVisible) then
			return
		end
		bonusVisible = newVisible
		local newHeight = (newVisible and bonusHeight) or mainHeight
		if newHeight < 120 then
			SetWindowSkin(holderWindow, "main_window_small_flat")
		else
			SetWindowSkin(holderWindow, "main_window_small")
		end
		holderWindow:SetPos(nil, nil, nil, newHeight)
	end
	SetBonusVisibility(false)
	
	local bonusToggleButton
	if thereAreBonusObjectives then
		bonusToggleButton = Chili.Button:New{
			y = 3,
			right = 3,
			width = BUTTON_SIZE,
			height = BUTTON_SIZE,
			caption = "",
			tooltip = "Toggle bonus objectives",
			padding = {0,0,0,0},
			OnClick = {
				function ()
					SetBonusVisibility(not bonusVisible)
				end
			},
			parent = holderWindow,
			children = {
				Chili.Image:New{
					file = BONUS_TOGGLE_IMAGE,
					x = 0,
					y = 0,
					right = 0,
					bottom = 0,
				}
			},
		}
	end
	
	return SetBonusVisibility
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Victory/Defeat

local function SendVictoryToLuaMenu(planetID)
	local luaMenu = Spring.GetMenuName and Spring.SendLuaMenuMsg and Spring.GetMenuName()
	if luaMenu then
		local bonusObjectiveString = bonusObjectiveBlock and bonusObjectiveBlock.MakeObjectivesString()
		Spring.SendLuaMenuMsg(WIN_MESSAGE .. planetID .. " " .. (bonusObjectiveString or ""))
	end
end

local function SendDefeatToLuaMenu(planetID)
	local luaMenu = Spring.GetMenuName and Spring.SendLuaMenuMsg and Spring.GetMenuName()
	if luaMenu then
		Spring.SendLuaMenuMsg(LOST_MESSAGE .. planetID)
	end
end

local function SendMissionResult()
	if missionResultSent or (not missionSustainedTime) or Spring.IsReplay() then
		return
	end
	missionResultSent = true
	
	local campaignSaveName = Spring.GetModOptions().singleplayercampaignsavename
	if campaignSaveName and campaignSaveName ~= "" then
		Spring.SendLuaMenuMsg(LOAD_CAMPAIGN_MESSAGE .. campaignSaveName)
	end
	
	if bonusObjectiveBlock then
		bonusObjectiveBlock.Update()
	end
	
	if missionWon then
		SendVictoryToLuaMenu(campaignBattleID)
	else
		SendDefeatToLuaMenu(campaignBattleID)
	end
end

local function MissionGameOver(newMissionWon)
	if missionEndFrame and (newMissionWon == missionWon) then
		return
	end
	
	-- Don't turn lost missions into won missions.
	if newMissionWon and missionEndFrame then
		return
	end
	missionWon = newMissionWon
	missionEndFrame = Spring.GetGameFrame() + VICTORY_SUSTAIN_FRAMES
	missionEndTime = osClock()
	
	if WG.Music then
		WG.Music.PlayGameOverMusic(missionWon)
	end
end

-- Resign from within luaUI
local function MissionResign()
	Spring.SendLuaRulesMsg("galaxyMissionResign")
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Draw end screen

-- Mostly from pause screen (very_bad_soldier)

--Commons
local function ResetGl() 
	glColor( { 1.0, 1.0, 1.0, 1.0 } )
	glLineWidth( 1.0 )
	glDepthTest(false)
	glTexture(false)
end

function IsOverWindow(x, y)
	if not missionEndTime then
		return false
	end
	if ((x > screenCenterX - boxWidth) and (y < screenCenterY + boxHeight) and 
		(x < screenCenterX + boxWidth) and (y > screenCenterY - boxHeight)) then	
		return true
	end
	return false
end
 
function widget:MousePress(x, y, button)
	if missionSustainedTime then
		local outsideSpring = select(6, spGetMouseState())
		if (not outsideSpring) and IsOverWindow(x, y) then
			SendMissionResult()
			if Spring.GetMenuName and Spring.GetMenuName() ~= "" then
				Spring.Reload("")
			else
				Spring.SendCommands("quitforce")
			end
		end
	end
end

function widget:Update()
	if missionSustainedTime then
		local x, y, _, _, _, outsideSpring = spGetMouseState()
		if (not outsideSpring) and (IsOverWindow(x, y)) then
			mouseOver = true
		else
			mouseOver = false
		end
	end
end

local function DrawGameOverScreen(now)
	local diffPauseTime = (now - missionEndTime)
	
	local text =  { 1.0, 1.0, (mouseOver and 0.95) or 1.0, 1.0 }
	local text2 =  { 0.95, 0.95, (mouseOver and 0.9) or 0.95, 1.0 }
	local outline =  { 0.4, 0.4, 0.4, 1.0 }
	local colorWnd = { 0.0, 0.0, 0.0, 0.6 }
	local mouseOverColor = { 0.015, 0.028, 0.01, 0.6 }

	-- Fade in
	local factor = min(maxTransparency_autoFade, max(diffPauseTime / autoFadeTime, minTransparency_autoFade))
	colorWnd[4] = colorWnd[4]*factor
	text[4] = text[4]*factor
	outline[4] = outline[4]*factor
	mouseOverColor[4] = mouseOverColor[4]*factor
	
	
	--draw window
	glPushMatrix()
	
	if mouseOver then
		glColor(mouseOverColor)
	else
		glColor(colorWnd)
	end
	
	glRect( wndX1, wndY1, wndX2, wndY2 )
	glRect( wndX1 - wndBorderSize, wndY1 + wndBorderSize, wndX2 + wndBorderSize, wndY2 - wndBorderSize)
	
	myFont:Begin()
	myFont:SetOutlineColor( outline )

	myFont:SetTextColor( text )
	myFont:Print((missionWon and "Victory") or "Defeat", (missionWon and victoryTextX) or defeatTextX, textY, fontSizeHeadline, "O" )
	
	if missionSustainedTime then
		local secondaryFactor = min(maxTransparency_autoFade, max((now - missionSustainedTime) / continueFadeInTime, 0))
		text2[4] = text2[4]*secondaryFactor
		myFont:SetTextColor( text2 )
		myFont:Print( "Click to continue", lowerTextX, textY - lineOffset, fontSizeAddon, "O" )
	end
	
	myFont:End()
	
	glPopMatrix()
	
	glTexture(false)
end

local function UpdateWindowCoords()
	screenx, screeny = widgetHandler:GetViewSizes()
	
	screenCenterX = screenx / 2
	screenCenterY = screeny / 2
	wndX1 = screenCenterX - boxWidth
	wndY1 = screenCenterY + boxHeight
	wndX2 = screenCenterX + boxWidth
	wndY2 = screenCenterY - boxHeight

	victoryTextX = wndX1 + (wndX2 - wndX1) * 0.12
	defeatTextX = wndX1 + (wndX2 - wndX1) * 0.15
	lowerTextX = wndX1 + (wndX2 - wndX1) * 0.30
	textY = wndY2 + (wndY1 - wndY2) * 0.3
	lineOffset = (wndY1 - wndY2) * 0.24
	
	yCenter = wndY2 + (wndY1 - wndY2) * 0.5
	xCut = wndX1 + (wndX2 - wndX1) * 0.19
end

function widget:ViewResize(viewSizeX, viewSizeY)
	UpdateWindowCoords()
end

function widget:DrawScreen()
	if missionEndTime then
		local now = osClock()
		DrawGameOverScreen(now)
		ResetGl()
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local function languageChanged()
	if globalCommandButton then
		globalCommandButton.tooltip = WG.Translate("interface", "toggle_mission_objectives_name") .. "\n\n" .. WG.Translate("interface", "toggle_mission_objectives_desc")
		globalCommandButton:Invalidate()
	end
	if mainObjectiveBlock then
		mainObjectiveBlock.UpdateTooltip(WG.Translate("interface", "main_objectives"))
	end
	if bonusObjectiveBlock then
		bonusObjectiveBlock.UpdateTooltip(WG.Translate("interface", "bonus_objectives"))
	end
end

function widget:GameFrame(n)
	if n%30 == 0 then
		if mainObjectiveBlock then
			mainObjectiveBlock.Update()
		end
		if bonusObjectiveBlock then
			bonusObjectiveBlock.Update()
		end
	end
	if missionEndFrame and missionEndFrame <= n then
		missionSustainedTime = osClock()
		missionEndFrame = nil
	end
end

function widget:Initialize()
	Chili = WG.Chili
	SetBonusObjectivesVisibility = InitializeObjectivesWindow()
	WG.InitializeTranslation (languageChanged, GetInfo().name)
	
	widgetHandler:RegisterGlobal('MissionGameOver', MissionGameOver)
	
	WG.MissionResign = MissionResign
	
	myFont = glLoadFont(fontPath, fontSizeHeadline)
	UpdateWindowCoords()
	
	local initMissionGameOver = Spring.GetGameRulesParam("MissionGameOver")
	if initMissionGameOver then
		MissionGameOver(initMissionGameOver == 1)
	end
end

function widget:Shutdown()
	SendMissionResult()
	glDeleteFont(myFont)
end