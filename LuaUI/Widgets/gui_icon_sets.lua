function widget:GetInfo() return {
	name      = "Icon Sets",
	desc      = "Manages alternate icon/buildpic sets.",
	author    = "Sprung",
	license   = "PD",
	layer     = 1,
	enabled   = true,
} end

options_path = 'Settings/Graphics/Unit Visibility/Radar Icons'
options_order = { 'coniconchassis' }
options = {
	coniconchassis = {
		name = 'Show constructor chassis',
		desc = 'Do constructor icons show chassis? Conveys more information but reduces visibility somewhat.',
		type = 'bool',
		value = false,
		noHotkey = true,
		OnChange = function(self)
			if not self.value then
				Spring.SetUnitDefIcon(UnitDefNames["armrectr"].id, "builder")
				Spring.SetUnitDefIcon(UnitDefNames["cornecro"].id, "builder")
				Spring.SetUnitDefIcon(UnitDefNames["corned"].id, "builder")
				Spring.SetUnitDefIcon(UnitDefNames["coracv"].id, "builder")
				Spring.SetUnitDefIcon(UnitDefNames["amphcon"].id, "builder")
				Spring.SetUnitDefIcon(UnitDefNames["corfast"].id, "builder")
				Spring.SetUnitDefIcon(UnitDefNames["arm_spider"].id, "builder")
				Spring.SetUnitDefIcon(UnitDefNames["corch"].id, "builder")
				Spring.SetUnitDefIcon(UnitDefNames["shipcon"].id, "builder")
			else
				Spring.SetUnitDefIcon(UnitDefNames["armrectr"].id, "kbotbuilder")
				Spring.SetUnitDefIcon(UnitDefNames["cornecro"].id, "walkerbuilder")
				Spring.SetUnitDefIcon(UnitDefNames["corned"].id, "vehiclebuilder")
				Spring.SetUnitDefIcon(UnitDefNames["coracv"].id, "tankbuilder")
				Spring.SetUnitDefIcon(UnitDefNames["amphcon"].id, "amphbuilder")
				Spring.SetUnitDefIcon(UnitDefNames["corfast"].id, "jumpjetbuilder")
				Spring.SetUnitDefIcon(UnitDefNames["arm_spider"].id, "spiderbuilder")
				Spring.SetUnitDefIcon(UnitDefNames["corch"].id, "hoverbuilder")
				Spring.SetUnitDefIcon(UnitDefNames["shipcon"].id, "shipbuilder")
			end
		end,
	},
}
