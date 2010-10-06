
local menu_corcom = include("Configs/marking_menu_menu_corcom.lua")
local menu_armcom = include("Configs/marking_menu_menu_armcom.lua")

local menu_armcsa = include("Configs/marking_menu_menu_armcsa.lua")
local menu_corcsa = include("Configs/marking_menu_menu_corcsa.lua")


local menu_use = {
  armbeaver = menu_armcom,
  armca = menu_armcom,
  armch = menu_armcom,
  armcombattle2 = menu_armcom,
  armcombuild2 = menu_armcom,
  armcomdgun2 = menu_armcom,
  armcomdgun = menu_armcom,
  armcom = menu_armcom,
  armcs = menu_armcom,
  armdecom = menu_armcom,
  armrectr = menu_armcom,
  arm_spider = menu_armcom,
  consul = menu_armcom,
  pioneer = menu_armcom,

  armcsa = menu_armcsa,
  
  corcom = menu_corcom,
  coracv =menu_corcom,
  corca = menu_corcom,
  corch = menu_corcom,
  corcombattle2 = menu_corcom,
  corcombuild2 = menu_corcom,
  corcomdgun2 = menu_corcom,
  corcomdgun = menu_corcom,
  corcs = menu_corcom,
  cordecom = menu_corcom,
  corfast = menu_corcom,
  cornecro = menu_corcom,
  corned = menu_corcom,
  pinchy = menu_corcom,
  
  corcsa = menu_corcsa,
}

-- override menus for 1 faction
if Game.modShortName == "CA1f" then
  for i,v in pairs(menu_use) do
    menu_use[i] = menu_armcom
  end
  menu_use.armcsa = menu_armcsa
  menu_use.commrecon = menu_armcom
  menu_use.commsupport = menu_armcom
end

return menu_use