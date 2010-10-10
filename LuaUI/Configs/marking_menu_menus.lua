
local menu_corcom = include("Configs/marking_menu_menu_corcom.lua")
local menu_armcom = include("Configs/marking_menu_menu_armcom.lua")

local menu_armcsa = include("Configs/marking_menu_menu_armcsa.lua")
local menu_corcsa = include("Configs/marking_menu_menu_corcsa.lua")


local menu_use = {
  armca = menu_armcom,
  armrectr = menu_armcom,
  arm_spider = menu_armcom,

  coracv = menu_corcom,
  corch = menu_armcom,
  corcs = menu_armcom,
  corfast = menu_armcom,
  cornecro = menu_armcom,
  corned = menu_armcom,
  
  armcsa = menu_armcsa
  
  armcom = menu_armcom,
  corcom = menu_armcom,
  commrecon = menu_armcom,
  commsupport = menu_armcom,
  armadvcom = menu_armcom,
  coradvcom = menu_armcom,
  commadvrecon = menu_armcom,
  commadvsupport = menu_armcom,
}

-- override menus for 1 faction
if Game.modShortName == "CA1f" then
  for i,v in pairs(menu_use) do
    menu_use[i] = menu_armcom
  end

end

return menu_use