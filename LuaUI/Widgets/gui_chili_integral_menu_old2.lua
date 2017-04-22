--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

include("Widgets/gui_chili_integral_menu.lua")

widget.GetInfo = function()
	return {
		name      = "Chili Integral Menu Old2",
		desc      = "Integral Command Menu which looks like it used to.",
		author    = "GoogleFrog",
		date      = "13 Novemember 2016",
		license   = "GNU GPL, v2 or later",
		layer     = math.huge-10,
		enabled   = false,
		handler   = true,
	}
end

EPIC_NAME = "epic_chili_integral_menu_old2_"
EPIC_NAME_UNITS = "epic_chili_integral_menu_old2_tab_units"

configurationName = "Configs/integral_menu_config_old.lua"

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Widget Options

options_path = 'Settings/HUD Panels/Command Panel Old'

options.unitsHotkeys2.value = false
