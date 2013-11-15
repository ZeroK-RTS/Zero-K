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

local window, stackPanelMain
local stackPanels = {}

local imageDir = "LuaUI/Configs/Factions/"
local WINDOW_HEIGHT = 108
local WINDOW_WIDTH = 220
local IMAGE_WIDTH = 32

local factions = {
	Cybernetic = {name = "Cybernetic Front", color = {136,170,255} },
	Dynasty = {name = "Dynasty of Earth", color = {255, 170, 32} },
	Machines = {name = "Free Machines", color = {170, 0, 0} },
	Empire = {name = "Empire Reborn", color = {96, 16, 255} },
	Liberty = {name = "Liberated Humanity", color = {85, 187, 85} },
}

for faction, data in pairs(factions) do
	for i=1,3 do
		data.color[i] = data.color[i]/255
	end
end

local function IsSpec()
	return (Spring.GetSpectatingState() or Spring.IsReplay())
end
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
function widget:GameFrame(n)
	if n%120 == 1 and (not IsSpec()) then
		widgetHandler:RemoveWidget()
	end
end

function widget:Initialize()
	local modoptions = Spring.GetModOptions()
	local planet = modoptions.planet
	local attacker = modoptions.attackingfaction
	local defender = modoptions.defendingfaction
	
	if not planet then
		widgetHandler:RemoveWidget()
		return
	end

	Chili = WG.Chili
	
	window = Chili.Window:New{
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
		parent = window,
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