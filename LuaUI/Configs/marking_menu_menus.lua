local menu_armcom = include("Configs/marking_menu_menu_armcom.lua")
local menu_armcsa = include("Configs/marking_menu_menu_armcsa.lua")
local menu_chickenbroodqueen = include("Configs/marking_menu_menu_chickenbroodqueen.lua")


local menu_use = {
  armca = menu_armcom,
  armrectr = menu_armcom,
  arm_spider = menu_armcom,

  coracv = menu_armcom,
  corch = menu_armcom,
  corcs = menu_armcom,
  corfast = menu_armcom,
  cornecro = menu_armcom,
  corned = menu_armcom,
  
  armcsa = menu_armcsa,
  
  armcom = menu_armcom,
  corcom = menu_armcom,
  commrecon = menu_armcom,
  commsupport = menu_armcom,
  armadvcom = menu_armcom,
  coradvcom = menu_armcom,
  commadvrecon = menu_armcom,
  commadvsupport = menu_armcom,
  
  chickenbroodqueen = menu_chickenbroodqueen,
}

return menu_use