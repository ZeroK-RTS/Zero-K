-------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
  return {
    name      = "Nubtron",
    desc      = "v0.41 Friendly Tutorial Robot",
    author    = "CarRepairer",
    date      = "2008-08-18",
    license   = "GNU GPL, v2 or later",
    layer     = 1, 
--[[before enabling, read commit message 5482]]
    enabled   = false  --  loaded by default?
  }
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

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
local GetUnitCommands	= Spring.GetUnitCommands
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
local Colorbars
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

--- unit classes ---
local classesByUnit = {}
local unitClasses = {
	Mex	= { 'cormex' },
	Solar	= { 'armsolar' },
	LLT	= { 'corllt' },
	BotLab	= { 'factoryshield' },
	Radar	= { 'corrad' },

	Con	= { 'cornecro' },
	Raider	= { 'corak' },
}
local unitClassNames = {
	Mex	= 'Mex',
	Solar	= 'Solar Collector',
	LLT	= 'LLT',
	BotLab	= 'Bot Lab',
	Radar	= 'Radar',

	Con	= 'Constructor',
	Raider	= 'Raider',
}

local mClasses = { Con=1, Raider=1, }

-- generic sub states
local steps = {	
	intro = {
		--message		= 'Hello! I am Nubtron, the friendly robot. I will teach you how to play Complete Annihilation. <(Click here to continue)>',
		passIfAny	= { 'clickedNubtron', },
	},
	intro2 = {
		--message		= 'Just follow my instructions. You can drag this window around by my face. <(Click here to continue)>',
		passIfAny	= { 'clickedNubtron'},
	},
	intro3 = {
		--message		= 'Practice zooming the camera in and out with your mouse\'s scroll wheel <(Click here to continue)>',
		passIfAny	= { 'clickedNubtron' },
	},
	intro4 = {
		--message		= 'Practice panning the camera up, down, left and right with your arrow keys. <(Click here to continue)>',
		passIfAny	= { 'clickedNubtron' },
	},
	intro5 = {
		--message		= 'Place your starting position by clicking on a nice flat spot on the map, then click on the <Ready> button',
		passIfAny	= { 'gameStarted' },

	},
	selectComm = {
		--message		= 'Select only your commander by clicking on it or pressing <ctrl+c>.',
		passIfAny	= {'commSelected'}
	},
	showMetalMap = {
		--message		= 'View the metal map by pressing <F4>.',
		passIfAny	= { 'metalMapView' }
	},
	hideMetalMap = {
		--message		= 'Hide the metal map by pressing <F4>.',
		passIfAnyNot	= { 'metalMapView' }
	},

	selectBotLab = {
		--message		= 'Select only your Bot Lab by clicking on it (the blue circles will help you find it).',
		passIfAny	= { 'BotLabSelected' }
	},

	selectCon = {
		--message		= 'Select one constructor by clicking on it (the blue circles will help you find it).',
		--image		= { arm='unitpics/'.. unitClasses.Con[1] ..'.png', core='unitpics/'.. unitClasses.Con[2] ..'.png' },
		image		= unitClasses.Con[1] ..'.png',
		passIfAny	= { 'ConSelected' },
	},

	guardFac = {
		--message		= 'Have the constructor guard your Bot Lab by right clicking on the Lab. The constructor will assist it until you give it a different order.',
		errIfAnyNot	= { 'ConSelected' },
	},

	--[[
	rotate = {
		--message		= 'Try rotating.',
		errIfAnyNot	= { 'commSelected', 'BotLabBuildSelected' },
		passIfAny	= { 'clickedNubtron' }
	},
	--]]
	tutorialEnd = {
		--message		= 'This is the end of the tutorial. It is now safe to shut off Nubtron. Goodbye! (Click here to restart tutorial)',
		passIfAny	= {'clickedNubtron'}
	},
}

-- main states
local tasks = {
	
	{
		--desc		= 'Introduction',
		states		= {'intro', 'intro2', 'intro3', 'intro4', 'intro5', },
	},
	{
		--desc		= 'Restore your interface',
		states		= { 'hideMetalMap', },
	},
	{
		--desc		= 'Building a Metal Extractor (mex)',		
		--tip			= 'Metal extractors output metal which is the heart of your economy.',
		states		= { 'selectComm', 'showMetalMap', 'finishMex', 'selectBuildMex', 'startMex', 'buildMex', 'hideMetalMap' },
		passIfAll	= { 'haveMex',},
	},
	{
		--desc		= 'Building a Solar Collector',
		--tip			= 'Energy generating structures power your mexes and factories.',
		states		= { 'selectComm', 'finishSolar', 'selectBuildSolar', 'startSolar', 'buildSolar'},
		errIfAny	= { 'metalMapView' },
		errIfAnyNot	= { 'haveMex' },
		passIfAll	= { 'haveSolar',},
	},
	{
		--desc		= 'Building a Light Laser Tower (LLT)',
		states		= { 'selectComm', 'finishLLT', 'selectBuildLLT', 'startLLT', 'buildLLT' },
		errIfAny	= { 'metalMapView' },
		errIfAnyNot	= { 'haveMex', 'haveSolar' },
		passIfAll	= { 'haveLLT',},
	},
	{
		--desc		= 'Building another mex on a different metal spot.',
		---tip			= 'Always try to acquire more metal spots to build more mexes.',
		states		= { 'selectComm', 'showMetalMap', 'finishMex', 'selectBuildMex', 'startMex', 'buildMex', 'hideMetalMap'},
		errIfAnyNot	= { 'haveMex', 'haveSolar' },
		passIfAnyNot	= { 'lowMetalIncome', },
	},
	{
		--desc		= 'Building another Solar Collector',
		--tip			= 'Always try and build more energy structures to keep your economy growing.',
		states		= { 'selectComm', 'finishSolar', 'selectBuildSolar', 'startSolar', 'buildSolar', },
		errIfAny	= { 'metalMapView', },
		errIfAnyNot	= { 'haveMex', 'haveSolar' },
		passIfAnyNot	= { 'lowEnergyIncome', }
	},
	{
		--desc		= 'Building a Factory',
		states		= { 'selectComm', 'finishBotLab', 'selectBuildBotLab', 'startBotLab', 'buildBotLab' },
		errIfAny	= { 'metalMapView', 'lowMetalIncome', 'lowEnergyIncome', },
		errIfAnyNot	= { 'haveMex', 'haveSolar', 'haveLLT' },
		passIfAll	= { 'haveBotLab',},
	},
	{
		--desc		= 'Building a Radar',
		--tip			= 'Radar coverage shows you distant enemy units as blips.',
		states		= { 'selectComm', 'finishRadar', 'selectBuildRadar', 'startRadar', 'buildRadar' },
		errIfAny	= { 'metalMapView', 'lowMetalIncome', 'lowEnergyIncome', },
		errIfAnyNot	= { 'haveMex', 'haveSolar', 'haveLLT', 'haveBotLab' },
		passIfAll	= { 'haveRadar',},
	},
	{
		--desc		= 'Building a Constructor',
		--tip			= 'Just like your Commander, Constructors build (and assist building of) structures.',
		states		= { 'selectBotLab', 'selectBuildCon', 'buildCon' },
		errIfAny	= { 'metalMapView', 'lowMetalIncome', 'lowEnergyIncome', },
		errIfAnyNot	= { 'haveMex', 'haveSolar', 'haveLLT', 'haveBotLab', 'haveRadar' },
		passIfAll	= { 'haveCon',},
	},
	{
		--desc		= 'Using a constructor to assist your factory',
		--tip			= 'Factories that are assisted by constructors build faster.',
		states		= { 'selectCon', 'guardFac', },
		errIfAny	= { 'metalMapView', 'lowMetalIncome', 'lowEnergyIncome', },
		errIfAnyNot	= { 'haveMex', 'haveSolar', 'haveLLT', 'haveBotLab', 'haveRadar', 'haveCon' },
		passIfAll	= { 'guardFac',},
	},
	{
		--desc		= 'Building Raider Bots in your factory.',
		--tip			= 'Combat units are used to attack your enemies and make them suffer.',
		states		= { 'selectBotLab', 'selectBuildRaider', 'buildRaider', },
		errIfAny	= { 'metalMapView', 'lowMetalIncome', 'lowEnergyIncome', },
		errIfAnyNot	= { 'haveMex', 'haveSolar', 'haveLLT', 'haveBotLab', 'haveRadar', 'haveCon', 'guardFac' },
		passIfAll	= { 'haveRaider',},
	},
	{
		--desc		= 'Congratulations!',
		errIfAny	= { 'metalMapView' },
		states		= { 'tutorialEnd'},
	},
}

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------



function setCondition(condition)
	if not conditions[condition] then
		--Spring.Echo('add cond', condition)
		conditions[condition] = true
		CheckState()
	end
end
function remCondition(condition)
	if conditions[condition] then
		--Spring.Echo('rem cond', condition)
		conditions[condition] = nil
		CheckState()
	end
end

function GetFirstCommand(unitID)
	local queue = GetUnitCommands(unitID)
	return queue and queue[1]
end

function testForAnyConditions(conditionsToTest)
	if conditionsToTest then
		for _,condition in pairs(conditionsToTest) do
			if conditions[condition] then
				return true
			end
		end
	end
	return false
end

function testForAllConditions(conditionsToTest)
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

function testForAnyNotConditions(conditionsToTest)
	if conditionsToTest then
		for _,condition in pairs(conditionsToTest) do
			if not conditions[condition] then
				return true
			end
		end
	end
	return false
end

function resetTempConditions()
	for condition,_ in pairs(conditions) do
		if tempConditions[condition] then
			conditions[condition] = nil
		end
	end
end

function CheckState()

	local curTask = tasks[curTaskNum]
	local curStep = steps[tasks[curTaskNum].states[curStepNum]]
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
		curTaskNum = (curTaskNum % #tasks)+1
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
			curTaskNum = (curTaskNum % #tasks)+1
		end
		
		CheckState()
	elseif stepErr then
		resetTempConditions()
		curStepNum = 1
		CheckState()

	end
end

function CheckAllUnits()

	for unitClass, units in pairs(unitClasses) do
		conditions['build'..unitClass] = nil
		conditions['selbuild'..unitClass] = nil
	end

	-- commander
	local cmd1 = myCommID and GetFirstCommand(myCommID)
	if cmd1 then
		local udBuilding = UnitDefs[-cmd1.id]
		if udBuilding then
			local buildeeClass = classesByUnit[udBuilding.name]
			if buildeeClass then
				setCondition('build' .. buildeeClass)				
			end

		elseif cmd1.id == CMD_REPAIR then
			
			--Spring.Echo('cmd params', cmd1.params[1], cmd1.params[2], cmd1.params[3], cmd1.params[4], cmd1.params[5])
			--Spring.Echo('cmd options', cmd1.options[1], cmd1.options[2], cmd1.options[3], cmd1.options[4], cmd1.options[5])
			local repaireeID = cmd1.params[1]
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
		local cmd1 = GetFirstCommand(finUnitID)		
		if cmd1
			and (
				(cmd1.id == CMD_GUARD and cmd1.params[1] == myLabID)
				or (cmd1.id == CMD_REPAIR and cmd1.params[1] == labBuildingUnitID)
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

local function setup_text(lang)
	local texts = VFS.Include(LUAUI_DIRNAME .. "Configs/nubtron_texts.lua", nil, VFS.RAW_FIRST)
	local texts_lang = texts[lang]
	
	if not texts_lang then
		texts_lang = texts.en
	end
	
	for i,_ in ipairs(tasks) do
		tasks[i].desc = texts_lang.tasks.descs[i]
		tasks[i].tip = texts_lang.tasks.tips[i]
	end
	for k,_ in pairs(steps) do
		steps[k].message = texts_lang.steps[k]
	end
	
	for unitClass, units in pairs(unitClasses) do
		unitClassName = unitClassNames[unitClass]
		if mClasses[unitClass] then
			steps['selectBuild'.. unitClass].message 	= texts_lang.steps.selectBuild_m:gsub('#replace#', unitClassName) 
			steps['build'.. unitClass].message 			= texts_lang.steps.build_m:gsub('#replace#', unitClassName)
		else
			steps['finish'.. unitClass].message			= texts_lang.steps.finish:gsub('#replace#', unitClassName)
			steps['selectBuild'.. unitClass].message	= texts_lang.steps.selectBuild:gsub('#replace#', unitClassName)
			steps['start'.. unitClass].message			= texts_lang.steps.start:gsub('#replace#', unitClassName)
			steps['build'.. unitClass].message			= texts_lang.steps.build:gsub('#replace#', unitClassName)
		end
	end
	steps.startMex.message 			= texts_lang.steps.startMex
	steps.selectBuildMex.message 	= texts_lang.steps.selectBuildMex
	steps.startBotLab.message		= texts_lang.steps.startBotLab
end
local function setup_text_test(_,_,words)
	setup_text(words[1])
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
		fontSize = 16;
		fontShadow = true;
		parent = button;
	}
	tip = Label:New {
		width="100%";
		--height="100%";
		x=imgsize+2,
		y=15,
		
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
		y=40,
		bottom=0,
		right = imgsize+2 + nextbuttonwidth,
		
		autosize=false;
		align="left";
		valign="top";
		caption = text;
		fontSize = 14;
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
		right=imgsize+2,
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
		right=2,
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
		width = 600;
		height = imgsize+20; 
		x = 0; 
		bottom = 0;
		dockable = true;
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


function widget:DrawWorld()

	local curTask = tasks[curTaskNum]
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
	glLineWidth(0)
	glColor(0,0,0,0)
end
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

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
		if ud and ud.isCommander then
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
	Colorbars = Chili.Colorbars
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
	_, _, _, _, myFaction = Spring.GetTeamInfo(myTeamID)

	local allUnits = GetAllUnits()
	for _, unitID in pairs(allUnits) do
		local unitDefID = GetUnitDefID(unitID)
		local unitTeam = GetUnitTeam(unitID)
		local ud = UnitDefs[unitDefID]
		local _, _, _, _, buildProgress = GetUnitHealth(unitID)

		if ud and ud.isCommander and unitTeam == myTeamID then
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
	
	setup_text(lang)
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
		
		if ud.isCommander then
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

local cycle = 1
function widget:Update()
	cycle = (cycle + 1) % 100
	if cycle == 1 then
		if WG.lang and (lang ~= WG.lang) then
			lang = WG.lang
			setup_text(lang)
		end
	end
	local gameFrame = GetGameFrame()
	local frame32 = (gameFrame) % 32

	if (frame32 < 0.1) then
		--- started game ---
		if GetGameSeconds() > 2 then
			setCondition('gameStarted')
		end
		
		
		--- metal map ---
		if GetMapDrawMode() == 'metal' then
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

	local curTask = tasks[curTaskNum]
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
