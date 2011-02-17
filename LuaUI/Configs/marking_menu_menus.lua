local menu_armcom = include("Configs/marking_menu_menu_armcom.lua")
local menu_armcsa = include("Configs/marking_menu_menu_armcsa.lua")
local menu_chickenbroodqueen = include("Configs/marking_menu_menu_chickenbroodqueen.lua")


local menu_use = {
  armcsa = menu_armcsa,
  
  chickenbroodqueen = menu_chickenbroodqueen,
}

for name,udef in pairs(UnitDefNames) do
	if udef.buildOptions and not menu_use[name] then
		menu_use[name] = menu_armcom
	end
end

return menu_use