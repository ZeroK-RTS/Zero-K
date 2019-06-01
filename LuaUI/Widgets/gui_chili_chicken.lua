--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
	return {
		name      = "Chili Chicken Panel",
		desc      = "Indian cuisine",
		author    = "quantum, KingRaptor",
		date      = "May 04, 2008",
		license   = "GNU GPL, v2 or later",
		layer     = -9, 
		enabled   = true  --  loaded by default?
	}
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

if (not Spring.GetGameRulesParam("difficulty")) then
	return false
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
VFS.Include("LuaRules/Utilities/tobool.lua")

local Spring          = Spring
local gl, GL          = gl, GL
local widgetHandler   = widgetHandler
local math            = math
local table           = table

local panelFont		  = "LuaUI/Fonts/komtxt__.ttf"
local waveFont        = LUAUI_DIRNAME.."Fonts/Skrawl_40"
local panelTexture    = LUAUI_DIRNAME.."Images/panel.tga"

local viewSizeX, viewSizeY = 0,0

local red             = "\255\255\001\001"
local white           = "\255\255\255\255"
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
local gameInfo		  = {}
local waveMessage
local waveSpacingY    = 7
local waveY           = 800
local waveSpeed       = 0.2
local waveCount       = 0
local waveTime
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

-- include the unsynced (widget) config data
local file 				= LUAUI_DIRNAME .. 'Configs/chickengui_config.lua'
local configs 			= VFS.Include(file, nil, VFS.RAW_FIRST)
--local difficulties 		= configs.difficulties
local roostName 		= configs.roostName
local chickenColorSet 	= configs.colorSet

local chickenNamesPlural = {}
for chickenName, color in pairs(chickenColorSet) do
	chickenNamesPlural[chickenName] = color .. Spring.Utilities.GetHumanName(UnitDefNames[chickenName]) .. "\008"
end

local eggs = (Spring.GetModOptions().eggs == '1')
local speed = (Spring.GetModOptions().speedchicken == '1')

local hidePanel = Spring.Utilities.tobool(Spring.GetModOptions().chicken_hidepanel)
local noWaveMessages = Spring.Utilities.tobool(Spring.GetModOptions().chicken_nowavemessages)

-- include the synced (gadget) config data
VFS.Include("LuaRules/Configs/spawn_defs.lua", nil, VFS.ZIP)

-- totally broken: claims it changes the data but doesn't!
--[[
for key, value in pairs(widget.difficulties[modes[Spring.GetGameRulesParam("difficulty")] ]) do
		widget.key = value
end
widget.difficulties = nil
]]--

local difficulty = widget.difficulties[modes[Spring.GetGameRulesParam("difficulty")]]

local rules = {
	"queenTime",
	"humanAggro",
	"lagging",
	"difficulty",
	"techAccel",
	"malus",
	roostName .. "Count",
	roostName .. "Kills",
}

for chickenName,_ in pairs(chickenColorSet) do
	rules[#rules + 1] = chickenName .. 'Count'
	rules[#rules + 1] = chickenName .. 'Kills'
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local Chili
local Button
local Label
local Window
local Panel
local TextBox
local Image
local Progressbar
local Control
local Font

-- elements
local window, labelStack, background
local global_command_button
local label_anger, label_chickens, label_burrows, label_aggro, label_tech, label_mode

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
fontHandler.UseFont(waveFont)
local waveFontSize   = fontHandler.GetFontSize()

--------------------------------------------------------------------------------
-- utility functions
--------------------------------------------------------------------------------

local function GetCount(type)
	local t = {}
	local total = 0
	for chickenName,colorInfo in pairs(chickenColorSet) do
		local subTotal = gameInfo[chickenName..type]
		t[#t+1] = colorInfo..subTotal
		total = total + subTotal
	end
	return total
end

-- I'm sure there's something to do this automatically but ehhh...
local function FormatTime(s)
	if not s then return '' end
	s = math.floor(s)
	local neg = (s < 0)
	if neg then s = -s end	-- invert it here and add the minus sign later, since it breaks if we try to work on it directly
	local m = math.floor(s/60)
	s = s%60
	local h = math.floor(m/60)
	m = m%60
	if s < 10 then s = "0"..s end
	if m < 10 then m = "0"..m end
	local str = (h..":"..m..":"..s)
	if neg then str = "-"..str end
	return str
end

-- explanation for string.char: http://springrts.com/phpbb/viewtopic.php?f=23&t=24952
local function GetColor(percent)
	local midpt = (percent > 50)
	local r, g
	if midpt then 
		r = 255
		g = math.floor(255*(100-percent)/50)
	else
		r = math.floor(255*percent/50)
		g = 255
	end
	return string.char(255,r,g,0)
end

local function GetColorAggression(value)
	local r,g,b
	if (value<=-1) then
		r = 255
		g = math.max(255 + value*25, 0)
		b = math.max(255 + value*25, 0)
	elseif (value>=1) then
		r = math.max(255 - value*25, 0)
		g = 255
		b = math.max(255 - value*25, 0)
	else
		r=255
		g=255
		b=255
	end
	return string.char(255,r,g,b)
end

-- gets the synced config setting for current difficulty
local function GetDifficultyValue(value)
	return difficulty[value] or widget[value]
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
local tooltipAnger, tooltipBurrowRespawn, tooltipBurrowTech, toolTIpBurrowTech2 = '', '', '', ''

local function WriteTooltipsOnce()
	local regressTime = GetDifficultyValue('burrowRegressTime')/gameInfo.malus
	--tooltipAnger = "Each burrow killed reduces time remaining by ".. ("%.1f"):format(GetDifficultyValue('burrowQueenTime')/gameInfo.malus) .." seconds"
	tooltipBurrowRespawn = "When killed, each burrow has a ".. math.floor(GetDifficultyValue('burrowRespawnChance')*100) .."% chance of respawning"
	label_aggro.tooltip = "Each burrow killed increases aggression rating by "..("%.1f"):format(GetDifficultyValue('humanAggroPerBurrow')/gameInfo.malus).."\n"..
		"Aggression rating decreases by "..("%.2f"):format(GetDifficultyValue('humanAggroDecay')).." per wave"
	tooltipBurrowTech = "Each burrow killed reduces chicken tech progress by "..("%.1f"):format(regressTime).. " seconds"
	tooltipBurrowTech2 = "Tech progress floor = " .. math.floor(GetDifficultyValue('techTimeFloorFactor')*100) .."% of game time"
end

-- generates breakdown of kills and deaths for each chicken type, sorted by appearance order ingame
local function MakeChickenBreakdown()
	local chickenTypes = difficulty.chickenTypes
	local t = {}
	local tNames = {}	-- reverse direction: get chicken name from final string
	for chickenName,colorInfo in pairs(chickenColorSet) do
		local count = gameInfo[chickenName.."Count"]
		local kills = gameInfo[chickenName.."Kills"]
		local str = "\n"..chickenNamesPlural[chickenName]..": \255\0\255\0"..count.."\008/\255\255\0\0"..kills
		t[#t+1] = str
		tNames[str] = chickenName
	end
	-- sort by chicken appearance
	table.sort(t,
				function(a,b)
					if (not chickenTypes[tNames[a]]) or (not chickenTypes[tNames[b]]) then
						return false
					end
					return chickenTypes[tNames[a]]["time"] < chickenTypes[tNames[b]]["time"]
				end
			)
	--table.sort(t, function(a,b) return tNames[a] < tNames[b] end )	-- alphabetical order
	return table.concat(t)
end

-- done every second
local function UpdateAnger()
	local curTime = Spring.GetGameSeconds()
	local saveOffset = (Spring.GetGameRulesParam("totalSaveGameFrame") or 0) / Game.gameSpeed
	local angerPercent = ((curTime + saveOffset) / (gameInfo.queenTime + saveOffset) * 100)
	local angerString = "Hive Anger : ".. GetColor( math.min(angerPercent, 100) )..math.floor(angerPercent).."% \008"
	if (angerPercent < 100) and (not endlessMode) then angerString = angerString .. "("..FormatTime(gameInfo.queenTime - curTime) .. " left)" end
	label_anger:SetCaption(angerString)
end

-- done every 2 seconds
local function UpdateRules()
	for _, rule in pairs(rules) do
		gameInfo[rule] = Spring.GetGameRulesParam(rule) or 0
	end

	-- write info
	local chickenCount, chickenKills = GetCount("Count"), GetCount("Kills")
	label_chickens:SetCaption("Chickens alive/killed : \255\0\255\0"..chickenCount.."\008/\255\255\0\0"..chickenKills)
	label_burrows:SetCaption("Burrows alive/killed : \255\0\255\0"..gameInfo[roostName .. "Count"].."\008/\255\255\0\0"..gameInfo[roostName .. "Kills"])
--[[?	if (gameInfo["humanAggro"] >=4) then
		label_aggro:SetCaption("Player aggression rating: \255\0\255\0"..("%.3f"):format(gameInfo["humanAggro"]))
	elseif (gameInfo["humanAggro"] < 4) and (gameInfo["humanAggro"] >= 2) then
		label_aggro:SetCaption("Player aggression rating: \255\120\255\150"..("%.3f"):format(gameInfo["humanAggro"]))
	elseif (gameInfo["humanAggro"] < 2) and (gameInfo["humanAggro"] >= 0.5) then
		label_aggro:SetCaption("Player aggression rating: \255\200\255\150"..("%.3f"):format(gameInfo["humanAggro"]))
	elseif (gameInfo["humanAggro"] < 0.5) and (gameInfo["humanAggro"] >= -0.5) then
		label_aggro:SetCaption("Player aggression rating: \255\255\255\255"..("%.3f"):format(gameInfo["humanAggro"]))
	elseif (gameInfo["humanAggro"] < -0.5) and (gameInfo["humanAggro"] >= -2) then
		label_aggro:SetCaption("Player aggression rating: \255\255\255\130"..("%.3f"):format(gameInfo["humanAggro"]))
	elseif (gameInfo["humanAggro"] < -2) then
		label_aggro:SetCaption("Player aggression rating: \255\255\230\0"..("%.3f"):format(gameInfo["humanAggro"]))
	elseif (gameInfo["humanAggro"] < -4) then
		label_aggro:SetCaption("Player aggression rating: \255\255\0\0"..("%.3f"):format(gameInfo["humanAggro"]))
	end]]--
	label_aggro:SetCaption("Player aggression rating: "..GetColorAggression(gameInfo["humanAggro"])..("%.3f"):format(gameInfo["humanAggro"]))
	
	label_tech:SetCaption("Tech progress modifier : "..FormatTime(gameInfo["techAccel"]))
	label_chickens.tooltip = "Chickens spawn every ".. GetDifficultyValue('chickenSpawnRate') .." seconds\n"..MakeChickenBreakdown()

	-- tooltips, antilag
	local miniQueenTime = difficulty.miniQueenTime and difficulty.miniQueenTime[1]
	local aggro = math.max(gameInfo["humanAggro"], GetDifficultyValue('humanAggroQueenTimeMin'))
	aggro = math.min(aggro, GetDifficultyValue('humanAggroQueenTimeMax'))
	local queenTimeReduction = GetDifficultyValue('burrowQueenTime')*GetDifficultyValue('humanAggroQueenTimeFactor')*aggro
	queenTimeReduction = math.max(queenTimeReduction, 0)
	
	local tooltipAnger = "Killing a burrow (at current PAR) reduces time remaining by ".. ("%.1f"):format(queenTimeReduction) .." seconds"
	if miniQueenTime then tooltipAnger = tooltipAnger .. "\nDragons arrive at ".. FormatTime(math.floor(gameInfo.queenTime * miniQueenTime)) .. " (".. math.floor(miniQueenTime*100) .."%)" end
	label_anger.tooltip = tooltipAnger
		
	local techTime = -gameInfo["humanAggro"]
	if techTime > 0 then
		techTime = techTime * GetDifficultyValue('humanAggroTechTimeRegress')
	else
		techTime = techTime * GetDifficultyValue('humanAggroTechTimeProgress')
	end
	label_tech.tooltip = tooltipBurrowTech --.."\nTech progress change next wave (at current PAR): "..("%.1f"):format(techTime) .." seconds"	--FIXME: gives misleading values
	
	label_burrows.tooltip = "Burrow spawn time (at current burrow count): ".. ("%.1f"):format(GetDifficultyValue('burrowSpawnRate')*0.25*(gameInfo[roostName.."Count"] + 1)/gameInfo.malus) .." seconds\n"..
							tooltipBurrowRespawn
	
	if (gameInfo.lagging == 1) then label_mode:SetCaption(red.."Anti-Lag Enabled\008")
	else
		local substr = ''
		if eggs and speed then
			substr = " (Spd Eggs)"
		elseif eggs then
			substr = " (Eggs)"
		elseif speed then
			substr = " (Speed)"
		end
		label_mode:SetCaption("Mode: " .. configs.difficulties[gameInfo.difficulty] .. substr)
	end
end

--------------------------------------------------------------------------------
-- wave messages
--------------------------------------------------------------------------------
local function WaveRow(n)
	return n*(waveFontSize+waveSpacingY)
end

local function MakeLine(chicken, n)
	if (n <= 0) then
		return
	end
	local humanName = Spring.Utilities.GetHumanName(UnitDefNames[chicken])
	local color = chickenColorSet[chicken] or ""
	return color..humanName.." x"..n
end

function ChickenEvent(chickenEventArgs)
	if (chickenEventArgs.type == "wave") then
		if noWaveMessages then
			return
		end
		
		local chicken1Name       = chickenEventArgs[1]
		local chicken2Name       = chickenEventArgs[2]
		local chicken1Number     = chickenEventArgs[3]
		local chicken2Number     = chickenEventArgs[4]
		if (gameInfo[roostName .. 'Count'] < 1) then
			return
		end
		waveMessage    = {}
		waveCount      = waveCount + 1
		waveMessage[1] = "Wave "..waveCount 
		if (chicken1Name and chicken2Name and chicken1Name == chicken2Name) then
			if (chicken2Number and chicken2Number) then
				waveMessage[2] = 
					MakeLine(chicken1Name, (chicken2Number+chicken1Number)*gameInfo[roostName .. 'Count'])
			else
				waveMessage[2] =
					MakeLine(chicken1Name, chicken1Number*gameInfo[roostName .. 'Count'])
			end
		elseif (chicken1Name and chicken2Name) then
			waveMessage[2] = MakeLine(chicken1Name, chicken1Number*gameInfo[roostName .. 'Count'])
			waveMessage[3] = MakeLine(chicken2Name, chicken2Number*gameInfo[roostName .. 'Count'])
		end
		
		waveTime = Spring.GetTimer()
		
	-- table.foreachi(waveMessage, print)
	-- local t = Spring.GetGameSeconds() 
	-- print(string.format("time %d:%d", t/60, t%60))
	-- print""
	elseif (chickenEventArgs.type == "burrowSpawn") then
		UpdateRules()
	elseif (chickenEventArgs.type == "miniQueen") then
		waveMessage    = {}
		waveMessage[1] = "Here be dragons!"
		waveTime = Spring.GetTimer()
	elseif (chickenEventArgs.type == "queen") then
		waveMessage    = {}
		waveMessage[1] = "The Hive is angered!"
		waveTime = Spring.GetTimer()
	elseif (chickenEventArgs.type == "refresh") then
		UpdateRules()
		UpdateAnger()
	end
end

function widget:DrawScreen()
	viewSizeX, viewSizeY = gl.GetViewSizes()
	if (waveMessage)  then
		local t = Spring.GetTimer()
		fontHandler.UseFont(waveFont)
		local waveY = viewSizeY - Spring.DiffTimers(t, waveTime)*waveSpeed*viewSizeY
		if (waveY > 0) then
			for i=1,#waveMessage do
				fontHandler.DrawCentered(waveMessage[i], viewSizeX/2, waveY-WaveRow(i))
			end
		else
			waveMessage = nil
			waveY = viewSizeY
		end
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:Initialize()
	-- setup Chili
	Chili = WG.Chili
	Button = Chili.Button
	Label = Chili.Label
	Checkbox = Chili.Checkbox
	Window = Chili.Window
	Panel = Chili.Panel
	StackPanel = Chili.StackPanel
	TextBox = Chili.TextBox
	Image = Chili.Image
	Progressbar = Chili.Progressbar
	Font = Chili.Font
	Control = Chili.Control
	screen0 = Chili.Screen0
	
	--create main Chili elements
	local screenWidth,screenHeight = Spring.GetWindowGeometry()
	
	local labelHeight = 22
	local fontSize = 16
	
	window = Window:New{
		parent = screen0,
		name   = 'chickenpanel';
		color = {0, 0, 0, 0},
		width = 270;
		height = 189;
		right = 0; 
		y = 100,
		dockable = true;
		draggable = false,
		resizable = false,
		tweakDraggable = true,
		tweakResizable = false,
		minWidth = MIN_WIDTH,
		minHeight = MIN_HEIGHT,
		padding = {0, 0, 0, 0},
		--itemMargin  = {0, 0, 0, 0},
	}
	
	labelStack = StackPanel:New{
		parent = window,
		resizeItems = false;
		orientation   = "vertical";
		height = 175;
		width =  260;
		x = 20,
		y = 10,
		padding = {0, 0, 0, 0},
		itemMargin  = {0, 0, 0, 0},
	}
	
	background = Image:New{
		width=270;
		height=189;
		y=0;
		x=0;
		keepAspect = false,
		file = panelTexture;
		parent = window;
		disableChildrenHitTest = false,
	}
	
	label_anger = Label:New{
		parent = labelStack,
		autosize=false;
		align="left";
		valign="center";
		caption = '';
		height = labelHeight,
		width = "100%";
		font = {font = panelFont, size = fontSize, shadow = true, outline = true,},
	}
	label_chickens = Label:New{
		parent = labelStack,
		autosize=false;
		align="left";
		valign="center";
		caption = '';
		height = labelHeight,
		width = "100%";
		font = {font = panelFont, size = fontSize, shadow = true, outline = true,},
	}
	label_burrows = Label:New{
		parent = labelStack,
		autosize=false;
		align="left";
		valign="center";
		caption = '';
		height = labelHeight,
		width = "100%";
		font = {font = panelFont, size = fontSize, shadow = true, outline = true,},
	}
	label_aggro = Label:New{
		parent = labelStack,
		autosize=false;
		align="left";
		valign="center";
		caption = '';
		height = labelHeight,
		width = "100%";
		font = {font = panelFont, size = fontSize, shadow = true, outline = true,},
	}	
	label_tech = Label:New{
		parent = labelStack,
		autosize=false;
		align="left";
		valign="center";
		caption = '';
		height = labelHeight,
		width = "100%";
		font = {font = panelFont, size = fontSize, shadow = true, outline = true,},
	}
	label_mode = Label:New{
		parent = labelStack,
		autosize=false;
		align="center";
		valign="center";
		caption = '',
		height = labelHeight*2,
		width = "100%";
		font = {font = panelFont, size = fontSize, shadow = true, outline = true,},
	}
	
	widgetHandler:RegisterGlobal("ChickenEvent", ChickenEvent)
	UpdateRules()
	WriteTooltipsOnce()
	UpdateAnger()

	-- Activate tooltips for labels, they do not have them in default chili
	function label_anger:HitTest(x,y) return self end
	function label_chickens:HitTest(x,y) return self end
	function label_burrows:HitTest(x,y) return self end
	function label_aggro:HitTest(x,y) return self end
	function label_tech:HitTest(x,y) return self end
	
	if hidePanel then
		window:Hide()
	end

	if WG.GlobalCommandBar and not hidePanel then
		local function ToggleWindow()
			if window.visible then
				window:Hide()
			else
				window:Show()
			end
		end
		global_command_button = WG.GlobalCommandBar.AddCommand("LuaUI/Images/chicken.png", "Chicken info", ToggleWindow)
	end
end

function widget:Shutdown()
	fontHandler.FreeFont(waveFont)
	widgetHandler:DeregisterGlobal("ChickenEvent")
end

function widget:GameFrame(n)
	if (n%60< 1) then UpdateRules() end
	-- every second for smoother countdown
	if (n%30< 1) then UpdateAnger() end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

