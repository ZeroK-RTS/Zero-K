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
	}
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
local campaignBattleID = Spring.GetModOptions().singleplayercampaignbattleid
local missionDifficulty = tonumber(Spring.GetModOptions().planetmissiondifficulty) or 2
if not campaignBattleID then
	return
end

--local tipsOverride, textOverride = VFS.Include("LuaUI/Configs/missionTipOverride.lua")

local BUTTON_SIZE = 25
local BONUS_TOGGLE_IMAGE = 'LuaUI/images/plus_green.png'
local BRIEFING_IMAGE = LUAUI_DIRNAME .. "images/advplayerslist/random.png"

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
local RESIGN_MESSAGE = "Campaign_PlanetBattleResign"
local LOAD_CAMPAIGN_MESSAGE = "Campaign_LoadCampaign"
local myAllyTeamID = Spring.GetMyAllyTeamID()

local SUCCESS_ICON = LUAUI_DIRNAME .. "images/tick.png"
local FAILURE_ICON = LUAUI_DIRNAME .. "images/cross.png"
local OBJECTIVE_ICON = LUAUI_DIRNAME .. "images/bullet.png"

local mainObjectiveBlock, bonusObjectiveBlock
local globalCommandButton

local objectivesWindow
local briefingWindow

local missionWon, missionEndFrame, missionEndTime, missionResultSent

-- wait this many frames after victory to make sure your commander doesn't die.
local VICTORY_SUSTAIN_FRAMES = 50

local ADD_GLOBAL_COMMAND_BUTTON = false
local SCREEN_EDGE = 8

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

local gameNotStarted = true
local wantPause = false
local firstUpdates = 0

local screenx, screeny, myFont
local screenCenterX, screenCenterY, wndX1, wndY1, wndX2, wndY2
local victoryTextX, defeatTextX, defeatTextX, lowerTextX
local textY, lineOffset, yCenter, xCut, mouseOver

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Utilities

VFS.Include("LuaRules/Utilities/tablefunctions.lua")

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

local function TakeMouseOffEdge()
	-- Take off the edge to prevent pregame scroll and commander loss.
	-- This usually doesn't matter because in other game modes the player starts zoomed out.
	local mx, my, lmb, mmb, rmb, outsideSpring = Spring.GetMouseState()
	if outsideSpring then
		return
	end
	
	local screenWidth, screenHeight = Spring.GetWindowGeometry()
	local changed = false
	
	if mx < SCREEN_EDGE then
		mx = SCREEN_EDGE
		changed = true
	elseif mx > screenWidth - SCREEN_EDGE then
		mx = screenWidth - SCREEN_EDGE
		changed = true
	end
	
	if my < SCREEN_EDGE then
		my = SCREEN_EDGE
		changed = true
	elseif my > screenHeight - SCREEN_EDGE then
		my = screenHeight - SCREEN_EDGE
		changed = true
	end
	
	if changed then
		Spring.WarpMouse(mx, my)
	end
	return changed
end

local function InitializeNewtonFirezones()
	local newtonFirezones = Spring.Utilities.CustomKeyToUsefulTable(Spring.GetModOptions().planetmissionnewtonfirezones) or {}
	if not (newtonFirezones and WG.NewtonFirezone_AddGroup) then
		return
	end
	local newtonDefID = UnitDefNames["turretimpulse"].id
	
	for i = 1, #newtonFirezones do
		local data = newtonFirezones[i]
		local units = Spring.GetUnitsInRectangle(data.newtons.x1, data.newtons.z1, data.newtons.x2, data.newtons.z2, Spring.GetMyTeamID())
		local newtons = {}
		
		for j = 1, #units do
			local unitID = units[j]
			if Spring.GetUnitDefID(unitID) == newtonDefID then
				newtons[#newtons + 1] = unitID
			end
		end
		
		if #newtons > 0 then
			data.firezone.x, data.firezone.z = data.firezone.x1, data.firezone.z1
			data.firezone.x1, data.firezone.z1 = nil, nil
			WG.NewtonFirezone_AddGroup(newtons, data.firezone)
		end
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Briefing Window

local function GetNewTextHandler(parentControl, paragraphSpacing, imageSize)
	
	local offset = 0
	
	local holder = Chili.Control:New{
		x = 0,
		y = 0,
		right = 0,
		padding = {0,0,0,0},
		parent = parentControl,
	}
	
	local externalFunctions = {}
	
	function externalFunctions.AddEntry(textBody, imageFile)
		local textPos = 4
		if imageFile then
			textPos = imageSize + 10
			
			Chili.Image:New{
				x = 4,
				y = offset,
				width = imageSize,
				height = imageSize,
				keepAspect = true,
				file = imageFile,
				parent = holder
			}
		end
		
		local label = Chili.TextBox:New{
			x = textPos,
			y = offset + 6,
			right = 4,
			height = textSpacing,
			align = "left",
			valign = "top",
			text = textBody,
			fontsize = 14,
			parent = holder,
		}
		
		local offsetSize = (#label.physicalLines)*14 + 2
		if imageFile and (offsetSize < imageSize) then
			offsetSize = imageSize
		end
		
		offset = offset + offsetSize + paragraphSpacing
		holder:SetPos(nil, nil, nil, offset - paragraphSpacing/2)
	end
	
	return externalFunctions
end

local function InitializeBriefingWindow()
	local planetInformation = Spring.Utilities.CustomKeyToUsefulTable(Spring.GetModOptions().planetmissioninformationtext) or {}
	WG.campaign_planetInformation = planetInformation
	
	local BRIEF_WIDTH = 720
	local BRIEF_HEIGHT = 680
	
	local SCROLL_POS = 70
	local SCROLL_HEIGHT = 170
	
	local externalFunctions = {}
	
	local screenWidth, screenHeight = Spring.GetWindowGeometry()
	
	local briefingWindow = Chili.Window:New{
		classname = "main_window",
		name = 'mission_galaxy_brief',
		x = math.floor((screenWidth - BRIEF_WIDTH)/2),
		y = math.max(50, math.floor((screenHeight - BRIEF_HEIGHT)/2.5)),
		width = BRIEF_WIDTH,
		height = BRIEF_HEIGHT,
		minWidth = BRIEF_WIDTH,
		minHeight = BRIEF_HEIGHT,
		dockable = false,
		draggable = false,
		resizable = false,
		tweakDraggable = true,
		tweakResizable = true,
		parent = Chili.Screen0,
	}
	briefingWindow:SetVisibility(false)
	
	Chili.Label:New{
		x = 0,
		y = 12,
		width = briefingWindow.width - (briefingWindow.padding[2] + briefingWindow.padding[4]),
		height = 26,
		fontsize = 44,
		align = "center",
		caption = "Planet " .. planetInformation.name,
		parent = briefingWindow,
	}
	
	local mainHolder = Chili.ScrollPanel:New{
		x = "4%",
		y = SCROLL_POS,
		width = "44%",
		height = SCROLL_HEIGHT,
		horizontalScrollbar = false,
		parent = briefingWindow,
	}
	
	local bonusHolder
	if bonusObjectiveBlock then
		bonusHolder = Chili.ScrollPanel:New{
			right = "4%",
			y = SCROLL_POS,
			width = "44%",
			height = SCROLL_HEIGHT,
			horizontalScrollbar = false,
			parent = briefingWindow,
		}
	end
	
	local textScroll = Chili.ScrollPanel:New{
		x = "4%",
		y = SCROLL_POS + SCROLL_HEIGHT + 22,
		right = "4%",
		bottom = 80,
		horizontalScrollbar = false,
		parent = briefingWindow,
	}
	local planetTextHandler = GetNewTextHandler(textScroll, 22, 64)
	planetTextHandler.AddEntry(textOverride or planetInformation.description)
	
	if planetInformation.tips then
		local tips = tipsOverride or planetInformation.tips
		for i = 1, #tips do
			planetTextHandler.AddEntry(tips[i].text, tips[i].image)
		end
	end
	
	Chili.Button:New{
		x = "38%",
		right = "38%",
		bottom = 10,
		height = 60,
		caption = "Continue",
		fontsize = 26,
		OnClick = {
			function ()
				externalFunctions.Hide()
				objectivesWindow.Show()
			end
		},
		parent = briefingWindow
	}
	
	local function TakeObjectivesLists()
		if mainObjectiveBlock then
			mainObjectiveBlock.SetParent(mainHolder, 0, 0)
		end
		if bonusHolder and bonusObjectiveBlock then
			bonusObjectiveBlock.SetParent(bonusHolder, 0, 0)
		end
	end
	
	function externalFunctions.Show(withoutPause)
		if WG.PauseScreen_SetEnabled then
			WG.PauseScreen_SetEnabled(false, not gameNotStarted)
		end
		if not withoutPause then
			if gameNotStarted then
				wantPause = true
			else
				local paused = select(3, Spring.GetGameSpeed())
				if not paused then
					Spring.SendCommands("pause")
				end
			end
		end
		TakeObjectivesLists()
		
		briefingWindow:SetVisibility(true)
	end
	
	function externalFunctions.Hide()
		if WG.PauseScreen_SetEnabled then
			WG.PauseScreen_SetEnabled(true)
		end
		wantPause = false
		local paused = select(3, Spring.GetGameSpeed())
		if paused then
			Spring.SendCommands("pause")
		end
		briefingWindow:SetVisibility(false)
	end

	return externalFunctions
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Objectives Handler

local function GetObjectivesBlock(holderWindow, position, items, gameRulesParam, fontSize)
	fontSize = fontSize or 14
	
	local holderControl = Chili.Control:New{
		x = 0,
		y = position,
		right = 0,
		-- height is set later.
		padding = {0, 0, 0, 0},
		parent = holderWindow,
	}
	
	local offset = 0
	local missionsLabel = Chili.Label:New{
		x = 8,
		y = offset,
		width = "100%",
		height = 18,
		align = "left",
		valign = "top",
		caption = "",
		fontsize = fontSize + 4,
		parent = holderControl,
	}
	offset = offset + 28
	
	local objectives = {}
	
	for i = 1, #items do
		local label = Chili.TextBox:New{
			x = 22,
			y = offset,
			right = 4,
			height = 18,
			align = "left",
			valign = "top",
			text = items[i].description,
			fontsize = fontSize,
			parent = holderControl,
		}
		local image = Chili.Image:New{
			x = 4,
			y = offset - 3,
			width = 16,
			height = 16,
			file = OBJECTIVE_ICON,
			parent = holderControl,
		}
		objectives[i] = {
			offset = offset,
			label = label,
			image = image,
			satisfyCount = items[i].satisfyCount,
		}
		offset = offset + (#label.physicalLines)*14 + 2
	end
	
	local function SetTentativeSuccess(index)
		-- This is success that the UI draws, but it may still be overridden with failure by luaRules.
		if objectives[index].terminated then
			return
		end
		objectives[index].image.file = SUCCESS_ICON
		objectives[index].image:Invalidate()
	end
	
	local function UpdateSuccess(index)
		if objectives[index].terminated then
			return
		end
		local newSuccess = Spring.GetGameRulesParam(gameRulesParam .. index)
		if not newSuccess then
			return
		end
		
		if satisfyCount and newSuccess < satisfyCount then
			return
		end
		
		objectives[index].image.file = (newSuccess > 0 and SUCCESS_ICON) or FAILURE_ICON
		objectives[index].image:Invalidate()
		
		objectives[index].success = (newSuccess > 0)
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
	
	function externalFunctions.SetTentativeSuccess()
		for i = 1, #objectives do
			SetTentativeSuccess(i)
		end
	end
	
	function externalFunctions.UpdateTooltip(text)
		missionsLabel:SetCaption(text)
	end
	
	function externalFunctions.SetParent(newParent, newX, newY)
		if (not holderControl.parent) or (holderControl.parent.name ~= newParent.name) then
			if holderControl.parent then
				holderControl.parent:RemoveChild(holderControl)
			end
			newParent:AddChild(holderControl)
		end
		holderControl:SetPos(newX, newY)
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
	
	holderControl:SetPos(nil, nil, nil, offset)
	
	return externalFunctions, position + offset
end

local function InitializeObjectivesWindow()
	local objectiveList = Spring.Utilities.CustomKeyToUsefulTable(Spring.GetModOptions().objectiveconfig) or {}
	local bonusObjectiveList = Spring.Utilities.CustomKeyToUsefulTable(Spring.GetModOptions().bonusobjectiveconfig) or {}
	
	local thereAreBonusObjectives = (bonusObjectiveList and #bonusObjectiveList > 0)
	if #objectiveList <= 0 and (not thereAreBonusObjectives) then
		return nil
	end
	
	local holderWindow = Chili.Window:New{
		classname = "main_window_small",
		name = 'mission_galaxy_objectives_4',
		x = 6,
		y = 44,
		width = 320,
		height = 22 + 16*(#objectiveList),
		dockable = true,
		draggable = false,
		resizable = false,
		tweakDraggable = true,
		tweakResizable = false,
		parent = Chili.Screen0,
	}
	holderWindow:SetVisibility(false)
	
	local externalFunctions = {}
	
	local position = 4
	local mainBlockPosition = position
	mainObjectiveBlock, position = GetObjectivesBlock(holderWindow, position, objectiveList,  "objectiveSuccess_")
	local mainHeight = position + holderWindow.padding[2] + holderWindow.padding[4] + 3
	local bonusHeight, bonusBlockPosition
	
	if #bonusObjectiveList > 0 then
		position = position + 8
		bonusBlockPosition = position
		bonusObjectiveBlock, position = GetObjectivesBlock(holderWindow, position, bonusObjectiveList, "bonusObjectiveSuccess_")
		bonusHeight = position + holderWindow.padding[2] + holderWindow.padding[4] + 3
	end
	
	if ADD_GLOBAL_COMMAND_BUTTON and WG.GlobalCommandBar then
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
	SetBonusVisibility(true)
	
	Chili.Button:New{
		y = 3,
		right = 3,
		width = BUTTON_SIZE,
		height = BUTTON_SIZE,
		classname = "button_tiny",
		caption = "",
		tooltip = "Show briefing",
		padding = {2,2,2,2},
		OnClick = {
			function ()
				externalFunctions.Hide()
				briefingWindow.Show()
			end
		},
		parent = holderWindow,
		children = {
			Chili.Image:New{
				file = BRIEFING_IMAGE,
				x = 0,
				y = 0,
				right = 0,
				bottom = 0,
			}
		},
	}
	
	local bonusToggleButton
	if thereAreBonusObjectives then
		bonusToggleButton = Chili.Button:New{
			y = 3,
			right = 3 + BUTTON_SIZE + 2,
			width = BUTTON_SIZE,
			height = BUTTON_SIZE,
			classname = "button_tiny",
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
	
	
	local function TakeObjectivesLists()
		if mainObjectiveBlock then
			mainObjectiveBlock.SetParent(holderWindow, 0, mainBlockPosition)
		end
		if bonusObjectiveBlock then
			bonusObjectiveBlock.SetParent(holderWindow, 0, bonusBlockPosition)
		end
	end
	
	function externalFunctions.Show()
		TakeObjectivesLists()
		holderWindow:SetVisibility(true)
	end
	
	function externalFunctions.Hide()
		holderWindow:SetVisibility(false)
	end
	
	return externalFunctions
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Victory/Defeat

local function GetTimeString()
	local frames = Spring.GetGameRulesParam("MissionGameOver_frames") or select(1, Spring.GetGameFrame()) or 0
	return frames
end

local function SendVictoryToLuaMenu(planetID)
	local luaMenu = Spring.GetMenuName and Spring.SendLuaMenuMsg and Spring.GetMenuName()
	if luaMenu then
		local bonusObjectiveString = bonusObjectiveBlock and bonusObjectiveBlock.MakeObjectivesString()
		Spring.SendLuaMenuMsg(WIN_MESSAGE .. " " .. planetID .. " " .. GetTimeString() .. " " .. (bonusObjectiveString or "") .. " " .. (missionDifficulty or "0"))
	end
end

local function SendDefeatToLuaMenu(planetID)
	local luaMenu = Spring.GetMenuName and Spring.SendLuaMenuMsg and Spring.GetMenuName()
	if luaMenu then
		Spring.SendLuaMenuMsg(LOST_MESSAGE .. " " .. planetID .. " " .. GetTimeString())
	end
end

local function SendResignToLuaMenu(planetID)
	local luaMenu = Spring.GetMenuName and Spring.SendLuaMenuMsg and Spring.GetMenuName()
	if luaMenu then
		Spring.SendLuaMenuMsg(RESIGN_MESSAGE .. " " .. planetID .. " " .. GetTimeString())
	end
end

local function SendMissionResult(shutdown)
	if missionResultSent or Spring.IsReplay() then
		return
	end
	
	if (not missionSustainedTime) then
		if shutdown then
			SendResignToLuaMenu(campaignBattleID)
		end
		return
	end
	missionResultSent = true
	
	local campaignPartialSaveData = Spring.GetModOptions().campaignpartialsavedata
	if campaignPartialSaveData and campaignPartialSaveData ~= "" then
		Spring.SendLuaMenuMsg(LOAD_CAMPAIGN_MESSAGE .. campaignPartialSaveData)
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
	
	if missionWon and mainObjectiveBlock then
		mainObjectiveBlock.SetTentativeSuccess()
	end
	
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
			return true
		end
	end
end

local function SingleplayerMode()
	local playerList = Spring.GetPlayerList()
	return #playerList == 1
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
	if gameNotStarted and SingleplayerMode() and not VFS.FileExists("mission.lua") then
		Spring.SendCommands("forcestart")
	end
	if firstUpdates then
		if TakeMouseOffEdge() and WG.ZoomToStart then
			WG.ZoomToStart()
		end
		firstUpdates = firstUpdates + 1
		if firstUpdates > 30 then
			firstUpdates = false
		end
	end
end

local function DrawGameOverScreen(now)
	local diffPauseTime = (now - missionEndTime)
	
	local text =  { 1.0, 1.0, (mouseOver and 0.9) or 1.0, 1.0 }
	local text2 =  { 0.95, 0.95, (mouseOver and 0.85) or 0.95, 1.0 }
	local outline =  { 0.4, 0.4, 0.4, 1.0 }
	local colorWnd = { 0.0, 0.0, 0.0, 0.6 }
	local mouseOverColor = { 0.022, 0.036, 0.03, 0.6 }

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
	screenx, screeny = Spring.GetViewGeometry()
	
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
		gameNotStarted = false
	end
	if missionEndFrame and missionEndFrame <= n then
		missionSustainedTime = osClock()
		missionEndFrame = nil
	end
	if wantPause then
		local paused = select(3, Spring.GetGameSpeed())
		if not paused then
			Spring.SendCommands("pause")
		end
		wantPause = false
		WG.PauseScreen_SetEnabled(false)
	end
	
	if n == 10 then
		InitializeNewtonFirezones()
	end
end

function widget:Initialize()
	Chili = WG.Chili
	objectivesWindow = InitializeObjectivesWindow()
	if objectivesWindow then
		briefingWindow = InitializeBriefingWindow()
		briefingWindow.Show()
	end
	
	WG.InitializeTranslation (languageChanged, GetInfo().name)
	
	widgetHandler:RegisterGlobal('MissionGameOver', MissionGameOver)
	Spring.SendCommands("forcestart")
	
	WG.MissionResign = MissionResign
	
	myFont = glLoadFont(fontPath, fontSizeHeadline, nil, nil) -- FIXME: nils for #2564
	UpdateWindowCoords()
	
	local initMissionGameOver = Spring.GetGameRulesParam("MissionGameOver")
	if initMissionGameOver then
		MissionGameOver(initMissionGameOver == 1)
	end
end

function widget:Shutdown()
	SendMissionResult(true)
	glDeleteFont(myFont)
end
