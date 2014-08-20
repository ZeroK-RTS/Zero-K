--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
  return {
    name      = "Chili Pro Hud",
    desc      = "v0.001 HUD like pro games.",
    author    = "CarRepairer",
    date      = "2014-07-16",
    license   = "GNU GPL, v2 or later",
    layer     = -100004,
    enabled   = false,
	
	handler = true,
  }
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
local spSendCommands			= Spring.SendCommands

local echo = Spring.Echo

local Chili
local Window
local screen0

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local window_hud


local added2 = {}
local timer = 0
local updateFrequency = 2


local chattemp = false
local playerlisttemp = false
local playerlisttemp2 = false
local epictemp = false
local minimappostpone = true

local setOptions = false

local timerCycles = 0


--[[
	qDiv1-3 = 3 relative positions on screen where hud quadrisects
--]]


local qDiv1 = 25
local qDiv2 = 45
local qDiv3 = 70

local qDiv1s
local qDiv2s
local qDiv3s

local qWid1s
local qWid2s
local qWid3s



--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--functions




local function Setup()
	window_hud = Window:New{  
		name = "ProHud",
		parent = screen0,
		
		--dockable=true,draggable=true,
		x = 0,
		y = '65%',
		width  = '100%',
		height = '35%',
		padding = {0,0,0,0};
		
		draggable = false,
		resizable = false,
		--color = {1,1,1,0.4},
		color = {1,1,1,0},
	}
	
	
	local scX,scY= Spring.GetViewGeometry() --get current screen size
	echo('screensize', scX,scY )
	
	if scX < 1600 then
		qDiv1 = 20
		qDiv2 = 40
		qDiv3 = 70
	end

	
	qDiv1s = qDiv1 .. '%'
	qDiv2s = qDiv2.. '%'
	qDiv3s = qDiv3.. '%'
	
	qWid1s = qDiv1s 
	qWid2s = (qDiv2-qDiv1) .. '%'
	qWid3s = (qDiv3-qDiv2) .. '%'
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--callins
function widget:Initialize()
	if (not WG.Chili) then
		widgetHandler:RemoveWidget()
		return
	end
	
	Chili = WG.Chili
	Window = Chili.Window
	screen0 = Chili.Screen0

	--disables
	widgetHandler:DisableWidget("Chili Chat 2.1") 
	--widgetHandler:DisableWidget("Chili Crude Player List")
	widgetHandler:DisableWidget("Chili Deluxe Player List - Alpha 2.02")
	widgetHandler:DisableWidget("Chili FactoryBar") 
	widgetHandler:DisableWidget("Chili Gesture Menu") 
	widgetHandler:DisableWidget("Chili Integral Menu") 
	
	--enables
	--widgetHandler:EnableWidget("Chili Deluxe Player List - Alpha 2.02")
	widgetHandler:EnableWidget("Chili Crude Player List")
	widgetHandler:EnableWidget("Chili FactoryPanel") 
	widgetHandler:EnableWidget("Chili Keyboard Menu")
	widgetHandler:EnableWidget("Chili Minimap") 
	widgetHandler:EnableWidget("Chili Pro Console Test") 
	widgetHandler:EnableWidget("Chili Resource Bars")
	
	
	widgetHandler:EnableWidget("Chili Docking") 
	
	--widgetHandler:DisableWidget("Chili Docking")
	
	Setup()
	
	--widgetHandler:DisableWidget("Chili Docking") 
	

end

local windows = {
	ResourceBars=1,
	Minimap=1,
	facpanel=1,
	selections=1,
	ProConsole=1,
	keyboardmenu=1,
}

local curChildren = {}

function widget:Shutdown()
	echo('Prohud shutdown')
	widgetHandler:EnableWidget("Chili Docking") 
	
	--[[ doesn't work!!!!!!
	for k,_ in pairs(windows) do
		local win = window_hud:GetChildByName(k)
		echo('??', k)
		if win then
			echo(k)
			screen0:AddChild(win)
		end
	end
	--]]
	--[[ doesn't work!!!!!!
	for _, win in ipairs(window_hud.children) do
		echo('winname shut?', win.name)
		screen0:AddChild(win)
	end
	--]]
	
	for _, win in ipairs(curChildren) do
		win.resizable = true
		--win.dockable = true
		win.tweakDraggable = true
		win.tweakResizable = true
		screen0:AddChild(win)
	end
	
end

function widget:Update(dt)
	timer = timer + dt
	if timer < updateFrequency then
		return
	end
	timer = 0
	
	timerCycles = timerCycles + 1
	
	--[[
		
		1640 - normal
		< 1640 - no rows of 7
	]]
	
	
	
	local win = screen0:GetChildByName('ProChat')
	if win and not chattemp then
		chattemp  = true
		win.dockable = false
		win.bottom = nil
		win.right = nil
		win.x = "10%"
		win.y = "10%"
		
		--win.x = 10
		--win.y = 10
		
		win:DetectRelativeBounds()
		win:SetPosRelative('35%', '48%', '25%', '25%')
		--win:SetPos('40%', '68%', '15%', '5%')
		
		win:RequestRealign()
	end
	
	
	--a bunch of messy stuff that needs to occur after docking has its way
	if timerCycles == 4 then
		--widgetHandler:EnableWidget("Chili Docking")
		win = screen0:GetChildByName('Player List')
		
		--fixme: minimap options must go AFTER addchild
		WG.SetWidgetOption("Chili Minimap","Settings/HUD Panels/Minimap","use_map_ratio","armap")
		WG.SetWidgetOption("Chili Minimap","Settings/HUD Panels/Minimap","buttonsOnRight",true )
		WG.SetWidgetOption("Chili Minimap","Settings/HUD Panels/Minimap","opacity",1 )
		
		win = screen0:GetChildByName('Player List')
		if win and not playerlisttemp then
			playerlisttemp  = true
			
			--win.dockable = false
			--win.minimizable = false
			
			win.bottom = nil
			win.right = nil
			win.x = "10%"
			win.y = "10%"
			
			--win.x = 10
			--win.y = 10
			
			win:DetectRelativeBounds()
			win:SetPosRelative('0%', '25%', '25%', '40%')
			--win:SetPos('40%', '68%', '15%', '5%')
			
			win:RequestRealign()
		end
	end
	
	
	win = screen0:GetChildByName('epicmenubar')
	if win and not epictemp then
		epictemp = true
		
		win.bottom = nil
		win.right = nil
		win.x = "10%"
		win.y = "10%"
		
		win:DetectRelativeBounds()
		win:SetPosRelative('40%', '0%' )
		
		win:RequestRealign()
	end
	
	
	if not setOptions then
		setOptions = true
		
		WG.SetWidgetOption("Chili Pro Console Test","Settings/HUD Panels/Chat/Pro Console/Color Setup","color_console_background", {1,1,1,1} )
		
		WG.SetWidgetOption("Chili Keyboard Menu","Settings/HUD Panels/KB Menu","opacity", 1 )
		
		WG.SetWidgetOption("Chili Selections & CursorTip","Settings/HUD Panels/Selected Units Window","alwaysShowSelectionWin", true )
		
		WG.SetWidgetOption("Chili Core Selector","Settings/HUD Panels/Core Selector","hideWindow", true )
		
		--window_hud.dockable=false
		--window_hud.draggable=false
		
	end
	
	for k,_ in pairs(windows) do
		
		local win = screen0:GetChildByName(k)
		if win then
		
			win.resizable = false
			win.tweakDraggable = false
			win.tweakResizable = false
			
			--the following two lines make everything magically work
			win.bottom = nil
			win.right = nil
			win.y = "10%"
			win:DetectRelativeBounds()
			
			
			if k == 'ResourceBars' then
				win:SetPosRelative('75%', 0, '25%', '25%')
			elseif k == 'Minimap' then
				win:SetPosRelative('0%', '0%', qWid1s, '100%')
				win.minimizable = false --fixme check if needed
			elseif k == 'facpanel' then
				win:SetPosRelative(qDiv1s, '25%', qWid2s, '75%')
			elseif k == 'selections' then
				win.minWidth = 400,
				--win:GetChildByName('unitInfoLabel').
				win:SetPosRelative(qDiv2s, '25%', qWid3s, '45%')
			elseif k == 'ProConsole' then
				win:SetPosRelative(qDiv2s, '70%', qWid3s, '30%')
			elseif k == 'keyboardmenu' then
				win:SetPosRelative(qDiv3s, '25%', '30%', '75%')
			end
			
			--if not added2[k] then
			--echo('0000000000000000 placing prohud', k)
			
			screen0:RemoveChild( win )
			window_hud:AddChild( win )
			
			--echo( '///////', win.name, win.parent.name )
			
			curChildren = {}
			
			for _, win in ipairs(window_hud.children) do
				curChildren[#curChildren+1] = win
				--screen0:AddChild(win)
			end
			
			--[[
			win:Update()
			win:Invalidate()
			win:UpdateClientArea()
			--]]
		end
		
	end
	
	
end

