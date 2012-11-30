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
 
local buttownSize=50

local lastX=10
local lastY=10

local function newButtonLine()
	lastX=10
	lastY=lastY+buttownSize+5
end

local function addButton(texture,unit,tooltip)
	local button  = Chili.Button:New {
			parent = helloWorldWindow,
			x = lastX,
			y = lastY,
			width = buttownSize,
			height = buttownSize,
			padding = {0, 0, 0, 0},
			--margin = {0, 0, 0, 0},
			--minWidth = 40,
			--minHeight = 40,
			isDisabled = false,
			fontsize = 13,
			textColor = {1,1,1,1},
			OnMouseDown = {buyUnit},
			dotashop_unit=unit,
			caption="",
			tooltip=tooltip,
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
 		width = 20+7*(buttownSize+5)-5,
 		height = 20+buttownSize*2,
 	--	backgroundColor = {0.8,0.8,0.8,0.9},
 	}	
 	
 	addButton("armwar.png","warrior","Buy Warrir\nCost: 400m")
 	addButton("armpw.png","glave","Buy Glave\nCost: 250m") 	
 	addButton("armzeus.png","zeus","Buy Zeus\nCost: 700m") 	
 		 	
 	addButton("core_spectre.png","aspis","Buy Aspis\nCost: 1200m") 	
 	addButton("corthud.png","thug","Buy Thug\nCost: 700m") 		
 	addButton("spideraa.png","tarantula","Buy Tarantula\nCost: 600m") 		
 	addButton("armkam.png","banshee","Buy Banshee\nCost: 1500m") 	
 	
 	
	newButtonLine()
	addButton("armmstor.png","storage","Increase metal storage\nCost: 80% of the curent storage") 	
	addButton("armanni.png","defense","Update base defense (Max 4 times) \nCost: 300m, 350m, 500m, 750m") 	
		
	--newButtonLine()
	addButton("armcrabe.png","crabe","Buy Crabe only for one wave\nCost: 1300m") 
	addButton("armbrawl.png","brawler","Buy Brawler only for one wave\nCost: 1500m") 	
	addButton("cormak.png","outlaw","Buy Outlwar only for one wave\nCost: 300m") 
	--newButtonLine()
	addButton("module_dmg_booster.png","com_attack","Increase commander damage\nCost: 100 + 100*lvl*lvl") 
	addButton("module_heavy_armor.png","com_def","Increase commander defense\nCost: 100 + 100*lvl*lvl") 		
	addButton("module_adv_targeting.png","com_range","Increase commander attack range\nCost: 100 + 100*lvl*lvl") 
	addButton("weaponmod_autoflechette.png","com_attackSpeed","Increase commander attack speed\nCost: 100 + 100*lvl*lvl") 		
	
 end
