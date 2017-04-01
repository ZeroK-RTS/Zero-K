--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
  return {
    name      = "PlanetWars Info",
    desc      = "Writes some PW stuff",
    author    = "KingRaptor (L.J. Lim)",
    date      = "Nov 2010",
    license   = "GNU GPL, v2 or later",
    layer     = 1, 
    enabled   = true  --  loaded by default?
  }
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
local Chili

local infoWindow, teleportWindow
local teleportProgress, teleportLabel, teleportImage

local imageDir = "LuaUI/Configs/Factions/"
local WINDOW_HEIGHT = 108
local WINDOW_WIDTH = 220
local IMAGE_WIDTH = 32

local factions = {
	Cybernetic = {name = "Cybernetic Front", color = {136,170,255} },
	--Dynasty = {name = "Dynasty of Earth", color = {255, 170, 32} },
	Dynasty = {name = "Dynasty of Man", color = {255, 191, 0} },
	Machines = {name = "Free Machines", color = {170, 0, 0} },
	Empire = {name = "Empire Reborn", color = {96, 16, 255} },
	Liberty = {name = "Liberated Humanity", color = {85, 187, 85} },
	SynPact = {name = "Synthetic Pact", color = {83, 136, 235} },
}

for faction, data in pairs(factions) do
	for i=1,3 do
		data.color[i] = data.color[i]/255
	end
end


local numCharges = -1
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
local function IsSpec()
	return (Spring.GetSpectatingState() or Spring.IsReplay())
end

local function CheckHaveEvacuable()
	if Spring.GetGameRulesParam("pw_have_evacuable") ~= 1 then
		if teleportWindow then
			teleportWindow:Dispose()
		end
	end
end

local function UpdateBar()
	if not teleportWindow then
		return
	end
	
	local current = Spring.GetGameRulesParam("pw_teleport_charge") or 0
	local needed = Spring.GetGameRulesParam("pw_teleport_charge_needed") or 1
	local currentRemainder = current%needed
	local numChargesNew = math.floor(current/needed)
	
	teleportProgress:SetValue(current/needed)
	local percent = math.floor(current/needed * 100 + 0.5)
	teleportProgress:SetCaption(percent .. "%")
	
	if numChargesNew ~= numCharges then
		local text = " teleport charge(s)"
		if (numChargesNew > 0)  then
			text = "\255\0\255\32\ "..numChargesNew.. text .. "\008"
			teleportImage.color = {1,1,1,1}
		else
			text = "\255\128\128\128\ 0" .. text .. "\008"
			teleportImage.color = {0.3, 0.3, 0.3, 1}
		end
		teleportLabel:SetCaption(text)
		teleportImage:Invalidate()
		
		numCharges = numChargesNew
	end
end

local function CreateTeleportWindow()
	if Spring.GetGameFrame() > 1 and Spring.GetGameRulesParam("pw_have_evacuable") ~= 1 then
		return
	end

	teleportWindow = Chili.Window:New{
		name   = 'pw_teleport_meter';
		parent = Chili.Screen0;
		width = 240,
		height = 64,
		left = 2,
		y = 32,
		dockable = true,
		draggable = false,
		resizable = false,
		tweakDraggable = true,
		tweakResizable = false,
		padding = {8, 8, 8, 8}
	}
	teleportImage = Chili.Image:New{
		parent = teleportWindow,
		right = 0,
		y = 0,
		height = 24,
		width = 24,
		file = "LuaUI/Images/commands/Bold/drop_beacon.png"
	}
	teleportLabel = Chili.Label:New{
		parent = teleportWindow,
		x = 0,
		y = 0,
		align = "left";
		valign = "top";
		caption = '';
		height = 18,
		width = "100%";
		font = {size = 14};
	}

	teleportProgress = WG.Chili.Progressbar:New{
		parent = teleportWindow,
		x	= 0,
		bottom 	= 0,
		right 	= 0,
		height	= 20,
		max     = 1;
		caption = "0%";
		color   =  {0.15,0.4,0.9,1}
	}
	UpdateBar()
end


local function CreateInfoWindow()
	local modoptions = Spring.GetModOptions()
	local planet = modoptions.planet
	local attacker = modoptions.attackingfaction
	local defender = modoptions.defendingfaction
	
	local stackPanels = {}
	
	infoWindow = Chili.Window:New{
		parent = Chili.Screen0,
		name   = 'pwinfo';
		width = WINDOW_WIDTH,
		height = WINDOW_HEIGHT,
		y = "20%",
		right = 0; 
		dockable = true;
		draggable = false,
		resizable = false,
		tweakDraggable = true,
		tweakResizable = false,
		padding = {5, 0, 5, 0},
		--color = {1, 1, 1, 0.6},
		--minimizable = true,
		--itemMargin  = {0, 0, 0, 0},
	}
	
	stackPanelMain = Chili.StackPanel:New{
		parent = infoWindow,
		resizeItems = false;
		orientation   = "vertical";
		height = "100%";
		width = "100%";
		padding = {0, 0, 0, 0},
		itemMargin  = {0, 0, 0, 0},
	}
	
	for i=1,3 do
		stackPanels[i] = Chili.Panel:New{
			parent = stackPanelMain,
			resizeItems = false;
			orientation   = "horizontal";
			height = WINDOW_HEIGHT/3;
			width = "100%";
			padding = {0, 0, 0, 0},
			itemMargin  = {0, 0, 0, 0},
			backgroundColor = {0, 0, 0, 0},
		}
	end
	
	Chili.Label:New {
		x = 0;
		width = WINDOW_WIDTH;
		height = WINDOW_HEIGHT/3;
		align = "center",
		caption = "Planet " .. planet;
		font = {
			size = 16;
			shadow = true;
		};
		parent = stackPanels[1];
	}
	
	if not attacker then
		Chili.Label:New {
			x = IMAGE_WIDTH + 16;
			height = IMAGE_WIDTH;
			caption = "No attacker";
			font = {
				size = 14;
				shadow = true;
			};
			parent = stackPanels[2];
		}
	else
		local attackerIcon = imageDir..attacker..".png"
		if VFS.FileExists(attackerIcon) then
			Chili.Image:New {
				x = 0;
				width = IMAGE_WIDTH;
				height = IMAGE_WIDTH;
				keepAspect = true,
				file = attackerIcon;
				parent = stackPanels[2];
			}
		end
		Chili.Label:New {
			x = IMAGE_WIDTH + 16;
			height = IMAGE_WIDTH;
			align="left";
			caption = factions[attacker] and factions[attacker].name or attacker or "Unknown attacker";
			font = {
				size = 14;
				shadow = true;
				color = factions[attacker] and factions[attacker].color;
			};
			parent = stackPanels[2];
		}
	end
	
	if not defender then
		Chili.Label:New {
			x = IMAGE_WIDTH + 16;
			height = IMAGE_WIDTH;
			caption = "No defender";
			font = {
				size = 14;
				shadow = true;
			};
			parent = stackPanels[3];
		}
	else
		local defenderIcon = imageDir..defender..".png"
		if VFS.FileExists(defenderIcon) then
			Chili.Image:New {
				x = 0;
				width = IMAGE_WIDTH;
				height = IMAGE_WIDTH;
				keepAspect = true,
				file = defenderIcon;
				parent = stackPanels[3];
			}
		end
		Chili.Label:New {
			x = IMAGE_WIDTH + 16;
			height = IMAGE_WIDTH;
			caption = factions[defender] and factions[defender].name or defender or "Unknown defender";
			font = {
				size = 14;
				shadow = true;
				color = factions[defender] and factions[defender].color;
			};
			parent = stackPanels[3];
		}
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
function widget:GameFrame(n)
	if n%120 == 1 and (not IsSpec()) then
		if infoWindow then
			infoWindow:Dispose()
		end
	end
	if n%10 == 3 then
		--CheckHaveEvacuable()	-- in future we might hide the window once all evacuables are destroyed or teleported away
		UpdateBar()
	end
end

function widget:Initialize()
	if not Spring.GetModOptions().planet then
		widgetHandler:RemoveWidget()
		return
	end

	Chili = WG.Chili
	CreateInfoWindow()
	CreateTeleportWindow()
end

function widget:GamePreload()
	CheckHaveEvacuable()
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------