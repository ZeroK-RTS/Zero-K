function widget:GetInfo()
  return {
    name      = "Dota shop",
    desc      = "Buy creep",
    author    = "N0U",
    date      = "Nov 29, 2012",
    license   = "GNU GPL, v2 or later",
    layer     = -9, 
    enabled   = true  --  loaded by default?
  }
end

if (Spring.GetModOptions().zkmode ~= "dota") then
  return
end

local Chili
 
 -- MEMBERS
local helloWorldLabel
local warriorButton
 
 -- SCRIPT FUNCTIONS
 -- WIDGET CODE
 
local function buyUnit(chiliButton, x, y, button, mods) 
	Spring.SendLuaRulesMsg("dotashop_buy_"..chiliButton.dotashop_unit)
	--Spring.SendLuaGaiaMsg("buy_warrior")
	--Spring.SendCommands("buy_warrior")
end
 
local lastX=10
local function addButton(texture,unit)
	local button  = Chili.Button:New {
			parent = helloWorldWindow,
			x = lastX,
			y = 10,
			width = 60,
			height = 60,
			--padding = {5, 5, 5, 5},
		--	margin = {0, 0, 0, 0},
			--minWidth = 40,
			--minHeight = 40,
			isDisabled = false,
			fontsize = 13,
			textColor = {1,1,1,1},
			OnMouseDown = {buyUnit},
			dotashop_unit=unit,
	}
	local image= Chili.Image:New {
				x=0,
				y=0,
				width="100%",
				height="100%",
				keepAspect = true,	--isState;
				file = "unitpics/"..texture,
				parent = button,
	}
	
	lastX=lastX+button.width+5
	return button
end

function widget:Initialize()	
 	if (not WG.Chili) then
 		widgetHandler:RemoveWidget()
 		return
 	end
 	
 	Chili      = WG.Chili
 	local screen0 = Chili.Screen0

 	helloWorldWindow = Chili.Window:New{
 		x = '50%',
 		y = '50%',	
 		dockable = true,
 		parent = screen0,
 		caption = "Dota shop",
 		width = 20+3*60+2*5,
 		height = 90,
 	--	backgroundColor = {0.8,0.8,0.8,0.9},
 	}	
 	
 	addButton("armwar.png","warrior")
 	addButton("armpw.png","glave") 	
 	addButton("armzeus.png","zeus") 	
	
 end
