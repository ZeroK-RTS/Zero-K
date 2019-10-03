local playerID = Spring.GetMyPlayerID()
local rank = playerID and select(9, Spring.GetPlayerInfo(playerID, false))

-------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
  return {
    name      = "Nubtron",
    desc      = "v0.411 Friendly Tutorial Robot",
    author    = "CarRepairer",
    date      = "2008-08-18",
    license   = "GNU GPL, v2 or later",
    layer     = 1,
--[[before enabling, read commit message 5482]]
    --enabled   = (rank and rank == 1) or true,
    enabled   = false
  }
end

if VFS.FileExists("mission.lua") then
  -- don't run in a mission
	return
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local echo = Spring.Echo

local Spring          = Spring
local gl, GL          = gl, GL
local widgetHandler   = widgetHandler
local math            = math
local table           = table

local glColor			= gl.Color
local glLineWidth		= gl.LineWidth
local glDepthTest		= gl.DepthTest
local glDrawGroundCircle	= gl.DrawGroundCircle


local GetActiveCmdDescs	= Spring.GetActiveCmdDescs
local GetActiveCommand	= Spring.GetActiveCommand
local GetAllUnits	= Spring.GetAllUnits
local GetCurrentTooltip = Spring.GetCurrentTooltip
local GetFullBuildQueue	= Spring.GetFullBuildQueue
local GetGameFrame	= Spring.GetGameFrame
local GetGameSeconds	= Spring.GetGameSeconds
local GetUnitPosition	= Spring.GetUnitPosition
local GetMapDrawMode	= Spring.GetMapDrawMode
local GetMouseState	= Spring.GetMouseState
local GetSelectedUnits	= Spring.GetSelectedUnits
local spGetUnitCurrentCommand = Spring.GetUnitCurrentCommand
local GetUnitDefID	= Spring.GetUnitDefID
local GetUnitHealth	= Spring.GetUnitHealth
local GetUnitIsBuilding	= Spring.GetUnitIsBuilding
local GetUnitTeam	= Spring.GetUnitTeam
local GetTeamResources	= Spring.GetTeamResources

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

-- Chili classes
local Chili
local Button
local Label
local Checkbox
local Window
local ScrollPanel
local StackPanel
local LayoutPanel
local Grid
local Trackbar
local TextBox
local Image
local Progressbar
local Control

local window_nubtron, title, tip, blurb, img, button_next
local wantClickNubtron, showImage = true, true
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local CMD_REPAIR        = CMD.REPAIR
local CMD_GUARD		= CMD.GUARD

local titleColor	= {1, 1, 1, 1 }
local tipColor		= {1, 1, 1, 0.9}
local messageColor	= {1,1,1,1}
local emphasisColorIn	= "\255\255\255\10"
local messageColorIn	= "\255\255\255\255"

local viewSizeX, viewSizeY
local w			= 550
local h			= 85
local px		= -1
local py		= -1

local mThresh		= 6
local eThresh		= 10

local metalIncome, energyIncome	= 0,0
local myTeamID, myFaction, myCommID, guardingConID
local myLabID = 0
local curStepNum, curTaskNum
--local checkAllUnitsFlag
--local buildFacing
local commBuildingUnitID, labBuildingUnitID

local cycle = 1

local finishedUnits = {}
local unfinishedUnits = {}
local finishedUnitCount = {}
local unfinishedUnitCount = {}

local conditions = {}
local tempConditions = {
	clickedNubtron=1,
	rotatedBuilding=1,
}

local lang = 'en'



--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local classesByUnit = {}
local nubtronData = VFS.Include(LUAUI_DIRNAME .. "Configs/nubtron_config.lua", nil, VFS.RAW_FIRST)
local unitClasses = nubtronData.unitClasses
local unitClassNames = nubtronData.unitClassNames
local mClasses = nubtronData.mClasses
local steps = nubtronData.steps
local tasks = nubtronData.tasks
local taskOrder = nubtronData.taskOrder
nubtronData = nil

local factory_commands, econ_commands, defense_commands, special_commands = include("Configs/integral_menu_commands.lua")

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local function CheckState() end

local function setCondition(condition)
	if not conditions[condition] then
		--Spring.Echo('add cond', condition)
		conditions[condition] = true
		CheckState()
	end
end
local function remCondition(condition)
	if conditions[condition] then
		--Spring.Echo('rem cond', condition)
		conditions[condition] = nil
		CheckState()
	end
end

local function testForAnyConditions(conditionsToTest)
	if conditionsToTest then
		for _,condition in pairs(conditionsToTest) do
			if conditions[condition] then
				return true
			end
		end
	end
	return false
end

local function testForAllConditions(conditionsToTest)
	if conditionsToTest then
		for _,condition in pairs(conditionsToTest) do
			if not conditions[condition] then
				return false
			end
		end
	else
		return false
	end
	return true
end

local function testForAnyNotConditions(conditionsToTest)
	if conditionsToTest then
		for _,condition in pairs(conditionsToTest) do
			if not conditions[condition] then
				return true
			end
		end
	end
	return false
end

local function resetTempConditions()
	for condition,_ in pairs(conditions) do
		if tempConditions[condition] then
			conditions[condition] = nil
		end
	end
end

local function GetCurTask()
	return tasks[ taskOrder[curTaskNum] ]
end

CheckState = function()

	local curTask = GetCurTask()
	local curStep = steps[curTask.states[curStepNum]]
	local taskStates = curTask.states
	
	if curStep.passIfAny and curStep.passIfAny[1] == 'clickedNubtron' then
		if not wantClickNubtron then
			wantClickNubtron = true
			window_nubtron:AddChild(button_next)
		end
	else
		if wantClickNubtron then
			wantClickNubtron = false
			window_nubtron:RemoveChild(button_next)
		end
	end


	---- Task Error ----
	local taskErr = testForAllConditions(curTask.errIfAll)
			or testForAnyConditions(curTask.errIfAny)
			or testForAnyNotConditions(curTask.errIfAnyNot)

	---- Task Pass ----
	local taskPass = testForAllConditions(curTask.passIfAll)
		or testForAnyConditions(curTask.passIfAny)
		or testForAnyNotConditions(curTask.passIfAnyNot)

	---- Task Check ----
	if taskErr then
		resetTempConditions()
		curTaskNum = 2
		curStepNum = 1
		CheckState()
		return

	elseif taskPass then
		resetTempConditions()
		curStepNum = 1
		curTaskNum = (curTaskNum % #taskOrder)+1
		CheckState()
		return
	end

	---- Step Error ----
	local stepErr = testForAllConditions(curStep.errIfAll)
			or testForAnyConditions(curStep.errIfAny)
			or testForAnyNotConditions(curStep.errIfAnyNot)

	---- Step Pass ----
	local stepPass = testForAllConditions(curStep.passIfAll)
			or testForAnyConditions(curStep.passIfAny)
			or testForAnyNotConditions(curStep.passIfAnyNot)

	---- Step Check ----
	if stepPass then
		resetTempConditions()
		if curStepNum < #taskStates then
			curStepNum = curStepNum + 1
		else
			curStepNum = 1
			curTaskNum = (curTaskNum % #taskOrder)+1
		end
		
		CheckState()
	elseif stepErr then
		resetTempConditions()
		curStepNum = 1
		CheckState()

	end
end

local function CheckAllUnits()

	for unitClass, units in pairs(unitClasses) do
		conditions['build'..unitClass] = nil
		conditions['selbuild'..unitClass] = nil
	end

	-- commander
	local cmdID, _, _, cmdParam1 = myCommID and spGetUnitCurrentCommand(myCommID)
	if cmdID then
		local udBuilding = UnitDefs[-cmdID]
		if udBuilding then
			local buildeeClass = classesByUnit[udBuilding.name]
			if buildeeClass then
				setCondition('build' .. buildeeClass)
			end

		elseif cmdID == CMD_REPAIR then
			
			local repaireeID = cmdParam1
			local udRepairee = UnitDefs[GetUnitDefID(repaireeID)]
			local repaireeClass = classesByUnit[udRepairee.name]

			if repaireeClass then
				local _, _, _, _, repaireeBuildProgress = GetUnitHealth(repaireeID)
				if repaireeBuildProgress < 1 then
					setCondition('build' .. repaireeClass)
				end
			end
		end
	end

	-- factory
	local bq = GetFullBuildQueue(myLabID)
	if bq and bq[1] then
		for udid, uCount in pairs(bq[1]) do
			local buildeeName = UnitDefs[udid].name
			local buildeeClass = classesByUnit[buildeeName]
			if buildeeClass then
				setCondition('build'.. buildeeClass)
			end
		end
		labBuildingUnitID = GetUnitIsBuilding(myLabID)
	end

		

	--constructors
	conditions.guardFac = nil
	for finUnitID, _ in pairs(finishedUnits['Con']) do
		local fCmdID, _, _, fCmdParam1 = spGetUnitCurrentCommand(finUnitID)
		if fCmdID
			and (
				   (fCmdID == CMD_GUARD  and fCmdParam1 == myLabID)
				or (fCmdID == CMD_REPAIR and fCmdParam1 == labBuildingUnitID)
			)
		then
			conditions.guardFac = true
		end
	end

	--- building a structure ---
	local activeCmdIndex,activeid ,_,buildUnitName = GetActiveCommand()
	--Spring.Echo('act cmd index, id', aciveCmdIndex, activeid)

	if classesByUnit[buildUnitName] then
		setCondition('selbuild' .. classesByUnit[buildUnitName] )
	end
	local cmddesc = GetActiveCmdDescs()
	--Spring.Echo ("active cmd", unitName)
	--Spring.Echo ("active cmddesc", cmddesc[1][1])
	CheckState()

end

local function addFinishedUnit(unitClass, unitID)
	if not finishedUnits[unitClass][unitID] then
		finishedUnits[unitClass][unitID] = unitID
		finishedUnitCount[unitClass] = finishedUnitCount[unitClass] + 1
		setCondition('have'.. unitClass)
	end
end

local function remFinishedUnit(unitClass, unitID)
	if finishedUnits[unitClass][unitID] then
		finishedUnits[unitClass][unitID] = nil
		finishedUnitCount[unitClass] = finishedUnitCount[unitClass] - 1
		if finishedUnitCount[unitClass] == 0 then
			remCondition('have'.. unitClass)
		end
	end
end

local function addUnfinishedUnit(unitClass, unitID)
	if not unfinishedUnits[unitClass][unitID] then
		unfinishedUnits[unitClass][unitID] = unitID
		unfinishedUnitCount[unitClass] = unfinishedUnitCount[unitClass] + 1
		setCondition('unf'.. unitClass)
	end
end

local function remUnfinishedUnit(unitClass, unitID)
	if unfinishedUnits[unitClass][unitID] then
		unfinishedUnits[unitClass][unitID] = nil
		unfinishedUnitCount[unitClass] = unfinishedUnitCount[unitClass] - 1
		if unfinishedUnitCount[unitClass] == 0 then
			remCondition('unf'.. unitClass)
		end
	end
end

local function addTabText(unitDefID)
	if factory_commands[-unitDefID] then
		return " under the Factory tab."
	elseif econ_commands[-unitDefID] then
		return " under the Econ tab."
	elseif defense_commands[-unitDefID] then
		return " under the Defense tab."
	elseif special_commands[-unitDefID] then
		return " under the Special tab."
	end
	return " under the Units tab."
end

local function SetupText(lang)
	local texts = VFS.Include(LUAUI_DIRNAME .. "Configs/nubtron_texts.lua", nil, VFS.RAW_FIRST)
	local texts_lang = texts[lang]
	
	if not texts_lang then
		texts_lang = texts.en
	end
	
	for i,taskName in ipairs(taskOrder) do
		tasks[taskName].desc = texts_lang.tasks.descs[taskName]
		tasks[taskName].tip = texts_lang.tasks.tips[taskName]
	end
	for k,_ in pairs(steps) do
		steps[k].message = texts_lang.steps[k]
	end
	
	for unitClass, units in pairs(unitClasses) do
		unitClassName = unitClassNames[unitClass]
		if mClasses[unitClass] then
			steps['selectBuild'.. unitClass].message 	= texts_lang.steps.selectBuild_m:gsub('#replace#', unitClassName) .. addTabText(UnitDefNames[units[1]].id)
			steps['build'.. unitClass].message 			= texts_lang.steps.build_m:gsub('#replace#', unitClassName)
		else
			steps['finish'.. unitClass].message			= texts_lang.steps.finish:gsub('#replace#', unitClassName)
			steps['selectBuild'.. unitClass].message	= texts_lang.steps.selectBuild:gsub('#replace#', unitClassName) .. addTabText(UnitDefNames[units[1]].id)
			steps['start'.. unitClass].message			= texts_lang.steps.start:gsub('#replace#', unitClassName)
			steps['build'.. unitClass].message			= texts_lang.steps.build:gsub('#replace#', unitClassName)
		end
	end
	steps.startMex.message 			= texts_lang.steps.startMex
	steps.selectBuildMex.message 	= texts_lang.steps.selectBuildMex
	steps.startBotLab.message		= texts_lang.steps.startBotLab
end
local function SetupText_test(_,_,words)
	SetupText(words[1])
end

local function SetupNubtronWindow()
	local imgsize = 80
	local nextbuttonwidth = 40
	title = Label:New {
		width="100%";
		--height="100%";
		x=imgsize+2,
		
		autosize=false;
		align="left";
		valign="top";
		caption = 'Title';
		fontSize = 14;
		fontShadow = true;
		parent = button;
	}
	tip = Label:New {
		width="100%";
		--height="100%";
		x=imgsize+2,
		y=18,
		
		autosize=false;
		align="left";
		valign="top";
		caption = 'Tip';
		fontSize = 10;
		fontShadow = true;
		parent = button;
	}
	blurb = TextBox:New {
		width="100%";
		--height="100%";
		x=imgsize+2,
		y=35,
		bottom=0,
		right = imgsize+2 + nextbuttonwidth,
		
		autosize=false;
		align="left";
		valign="top";
		caption = text;
		fontSize = 12;
		fontShadow = true;
		parent = button;
	}
	
	imgnubtron = Image:New {
		width = imgsize;
		height = imgsize;
		file = 'LuaUI/Images/friendly.png';
	}
	img = Image:New {
		width = imgsize;
		height = imgsize * (4/5);
		keepAspect = false,
		right=0,
		bottom=0,
		file = '';
	}
	button_next = Button:New {
		width = nextbuttonwidth;
		height = 50;
		caption = 'Next',
		right = imgsize+2,
		bottom = 0,
		OnClick = {
			function(self)
				setCondition('clickedNubtron')
			end
		}
	}
	local button_x = Button:New {
		width = 20;
		height = 15;
		caption = 'X',
		right = 2,
		captionColor = {1,0,0,1},
		OnClick = {
			function(self)
				Spring.SendCommands({"luaui togglewidget Nubtron"})
				--widgetHandler:RemoveWidget() --when using this, it requires two clicks to restart the widget from the menu
			end
		}
	}
	
		
	
	window_nubtron = Window:New{
		parent = screen0,
		name   = 'nubtron';
		--color = {0, 0, 0, 0},
		width = 550;
		height = imgsize+20;
		x = 450;
		bottom = 52;
		dockable = false;
		draggable = true,
		resizable = false,
		tweakDraggable = true,
		tweakResizable = false,
		padding = {10, 10, 10, 10},
		--itemMargin  = {0, 0, 0, 0},
		children = {
			title,
			tip,
			blurb,
			img,
			imgnubtron,
			button_next,
			button_x,
		},
	}
end
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--calins

function widget:DrawWorld()

	local curTask = GetCurTask()
	local curStep = steps[curTask.states[curStepNum]]

	local curStepName = curTask.states[curStepNum]
	
	local gameFrame = GetGameFrame()
	local frame32 = (gameFrame) % 32
	local pulse = frame32 / 32
	local radius = 100 - pulse*40

	-- draw circle around units --
	for unitClass, units in pairs(unitClasses) do
		
		local unitSet
		if curStepName == 'finish'.. unitClass then
			unitSet = unfinishedUnits[unitClass]
			glColor(1,0,0, pulse)
		elseif curStepName == 'select'.. unitClass then
			unitSet = finishedUnits[unitClass]
			glColor(0.3,0.3,1, pulse)
		end
		if unitSet then
			glLineWidth(2)
			glDepthTest(true)
			for unitID, _ in pairs(unitSet) do
				local ux, uy, uz = GetUnitPosition(unitID)
				if ux then
					for i = 1, 5 do
						glDrawGroundCircle(ux, uy, uz, radius +3*i, 32)
					end
				end
			end
		end
		
	end
	glDepthTest(false)
	glLineWidth(1.0)
	glColor(1,1,1,1)
end

function widget:UnitCreated(unitID, unitDefID, unitTeam)
	if unitTeam == myTeamID then
		local ud = UnitDefs[unitDefID]
		local _, _, _, _, buildProgress = GetUnitHealth(unitID)
		local unitClass = classesByUnit[ud.name]
		if unitClass then
			addUnfinishedUnit(unitClass, unitID)
			if unitClass == 'BotLab' then
				myLabID = unitID
			end

			--[[
			if buildProgress == 1 then
				setCondition('have'.. classesByUnit[ud.name])
			end
			--]]
		end
	end
end

function widget:UnitFinished(unitID, unitDefID, unitTeam)
	if unitTeam == myTeamID then
		local ud = UnitDefs[unitDefID]
		local unitClass = classesByUnit[ud.name]
		if unitClass then
			addFinishedUnit(unitClass, unitID)
			remUnfinishedUnit(unitClass, unitID)
		end
		if ud.name == 'corcom' then
			myFaction = 'core'
		end
		if ud and ud.customParams.commtype then
			myCommID = unitID
		end

	end
end

function widget:UnitDestroyed(unitID, unitDefID, unitTeam)
	if unitTeam == myTeamID then
		local ud = UnitDefs[unitDefID]
		local unitClass = classesByUnit[ud.name]
		if unitClass then
			remFinishedUnit(unitClass, unitID)
			remUnfinishedUnit(unitClass, unitID)
		end
		if unitClass == 'BotLab' then
			myLabID = 0
		end
		if unitID == myCommID then
			myCommID = nil
		end

	end
end


function widget:Initialize()

	-- setup Chili
	Chili = WG.Chili
	Button = Chili.Button
	Label = Chili.Label
	Checkbox = Chili.Checkbox
	Window = Chili.Window
	Panel = Chili.Panel
	ScrollPanel = Chili.ScrollPanel
	StackPanel = Chili.StackPanel
	LayoutPanel = Chili.LayoutPanel
	Grid = Chili.Grid
	Trackbar = Chili.Trackbar
	TextBox = Chili.TextBox
	Image = Chili.Image
	Progressbar = Chili.Progressbar
	Control = Chili.Control
	screen0 = Chili.Screen0
	
	SetupNubtronWindow()
	
	for unitClass, units in pairs(unitClasses) do
		for _,unit in pairs(units) do
			classesByUnit[unit] = unitClass
		end
		finishedUnits[unitClass] = {}
		unfinishedUnits[unitClass] = {}
		
		finishedUnitCount[unitClass] = 0
		unfinishedUnitCount[unitClass] = 0

		conditions['have'..unitClass] = nil
		conditions['unf'..unitClass] = nil
		conditions['build'..unitClass] = nil
		conditions['selbuild'..unitClass] = nil

		unitClassName = unitClassNames[unitClass]

		-- generic build structure steps
		if mClasses[unitClass] then
			steps['selectBuild'.. unitClass] = {
				--message		= 'Select the '.. unitClassName ..' from your build menu (build-icon shown here).',
				--image		= { arm='unitpics/'.. unitClasses[unitClass][1] ..'.png', core='unitpics/'.. unitClasses[unitClass][2] ..'.png' },
				image		= 'unitpics/'.. unitClasses[unitClass][1] ..'.png',
				errIfAnyNot	= { 'BotLabSelected', },
				passIfAny	= { 'build'.. unitClass, 'have'.. unitClass }
				}
			steps['build'.. unitClass] = {
				--message		= 'You are now building a '.. unitClassName ..'. <Wait for it to finish.>',
				errIfAnyNot	= { 'BotLabSelected', 'build'.. unitClass },
				--passIfAny	= { 'build'.. unitClass }
				}

		else
			steps['finish'.. unitClass] = {
				--message		= 'You have an unfinished '.. unitClassName ..' shown by the red circles. <Right click on it to finish building>. ',
				errIfAnyNot	= { 'commSelected', },
				passIfAny	= { 'build'.. unitClass },
				passIfAnyNot	= { 'unf'.. unitClass },
				}
			steps['selectBuild'.. unitClass] = {
				--message		= 'Select the '.. unitClassName ..' from your build menu (build-icon shown here). ',
				--image		= { arm='unitpics/'.. unitClasses[unitClass][1] ..'.png', core='unitpics/'.. unitClasses[unitClass][2] ..'.png' },
				image		= 'unitpics/'.. unitClasses[unitClass][1] ..'.png',
				errIfAnyNot	= { 'commSelected', },
				passIfAny	= { 'selbuild'.. unitClass, 'build'.. unitClass }
				}
			steps['start'.. unitClass] = {
				--message		= '<Place it near your other structures.> It will turn red if you try to place it on uneven terrain and you\'ll have to select it again.',
				errIfAnyNot	= { 'commSelected', 'selbuild'.. unitClass, },
				passIfAny	= { 'build'.. unitClass }
				}
			steps['build'.. unitClass] = {
				--message		= 'Good work! You are now building a '.. unitClassName ..'. <Wait for it to finish.>',
				errIfAnyNot	= { 'commSelected', 'build'.. unitClass },
				}
		end
	end

	--steps.startMex.message = 'Place it on a green patch.'
	steps.startMex.errIfAnyNot[#steps.startMex.errIfAnyNot + 1] = 'metalMapView'
	steps.selectBuildMex.errIfAnyNot[#steps.selectBuildMex.errIfAnyNot + 1] = 'metalMapView'
	--steps.selectBuildMex.message = 'The build-icon for the mex is shown to the right. Select it in your build menu on the left.'
	--steps.startBotLab.message = 'Before placing it, you can rotate the structure with the <[> and <]> keys. <Turn it and place it so that units can easily exit the front>. It will turn red if you try to place it on uneven terrain.'

	curTaskNum = 1
	curStepNum = 1

	myTeamID = Spring.GetLocalTeamID()
	_, _, _, _, myFaction = Spring.GetTeamInfo(myTeamID, false)

	local allUnits = GetAllUnits()
	for _, unitID in pairs(allUnits) do
		local unitDefID = GetUnitDefID(unitID)
		local unitTeam = GetUnitTeam(unitID)
		local ud = UnitDefs[unitDefID]
		local _, _, _, _, buildProgress = GetUnitHealth(unitID)

		if ud and ud.customParams.commtype and unitTeam == myTeamID then
			myCommID = unitID
		end

		widget:UnitCreated(unitID, unitDefID, unitTeam)
		if buildProgress == 1 then
			widget:UnitFinished(unitID, unitDefID, unitTeam)
		end
	end

	if (myFaction == "random") then
		myFaction = "arm"
	end
	--[[
	if UnitDefs[myCommID].name == 'corcom' then
		myFaction = 'core'
	end
	--]]
	
	SetupText(lang)
end

function widget:SelectionChanged(selectedUnits)
	for unitClass, units in pairs(unitClasses) do
		conditions[unitClass ..'Selected'] = nil
		conditions['commSelected'] = nil
	end

	--local selectedUnits = GetSelectedUnits()
	if #selectedUnits == 1 then
		local unitID = selectedUnits[1]
		local unitDefID = GetUnitDefID(unitID)
		local ud = UnitDefs[unitDefID]
		
		if ud.customParams.commtype then
			setCondition('commSelected')
		elseif classesByUnit[ud.name] then
			setCondition( classesByUnit[ud.name] ..'Selected')
		end

	end
	CheckState()
end

function widget:Shutdown()
	fontHandler.FreeFonts()
	fontHandler.FreeCache()
end


 
function widget:ViewResize(vsx, vsy)
	viewSizeX = vsx
	viewSizeY = vsy
end

function widget:Update()
	cycle = (cycle + 1) % 100
	if cycle == 1 then
		if WG.lang and (lang ~= WG.lang()) then
			lang = (WG.lang and WG.lang()) or "en"
			SetupText(lang)
		end
	end
	local gameFrame = GetGameFrame()
	local frame32 = (gameFrame) % 32

	if (frame32 < 0.1) then
		--- started game ---
		if GetGameSeconds() > 2 then
			setCondition('gameStarted')
		end
		
		
		--- metal map or showeco---
		if GetMapDrawMode() == 'metal' or WG.showeco == true then
			setCondition('metalMapView')
		else
			remCondition('metalMapView')
		end

		--- build facing direction ---
		--[[
		if buildFacing ~= Spring.GetUnitBuildFacing() then
			buildFacing = Spring.GetUnitBuildFacing()
			setCondition('rotatedBuilding')
		end
		--]]

		--- Check resources ---
		--local mCurrentLevel, mStorage, mPull, mIncome, mExpense, mShare, mSent, mReceived = GetTeamResources('teamID')
		local mCurrentLevel, mStorage, mPull, mIncome = GetTeamResources(myTeamID, 'metal')
		local eCurrentLevel, eStorage, ePull, eIncome = GetTeamResources(myTeamID, 'energy')
		metalIncome = mIncome
		energyIncome = eIncome
		
		if metalIncome < mThresh then
			setCondition('lowMetalIncome')
		elseif metalIncome > mThresh+1 then
			remCondition('lowMetalIncome')
		end
		if energyIncome < eThresh then
			setCondition('lowEnergyIncome')
		elseif energyIncome > eThresh+1 then
			remCondition('lowEnergyIncome')
		end
		
		CheckAllUnits()
	end

	local curTask = GetCurTask()
	local curStep = steps[curTask.states[curStepNum]]
	
	
	if curStep.image then
		local imageToUse
		if type(curStep.image) == 'table' then
			imageToUse = curStep.image[myFaction]
		else
			imageToUse = curStep.image
		end
		if not showImage then
			showImage = true
			window_nubtron:AddChild(img)
		end
		img.file = imageToUse
		img:Invalidate()
	else
		if showImage then
			showImage = false
			window_nubtron:RemoveChild(img)
		end
	end
	
	title:SetCaption(curTask.desc)
	tip:SetCaption(curTask.tip or '')
	local formattedLine = curStep.message:gsub('<', emphasisColorIn):gsub('>', messageColorIn)
	blurb:SetText(formattedLine)
	
end
	
	
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
