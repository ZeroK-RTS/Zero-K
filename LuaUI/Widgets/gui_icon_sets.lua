function widget:GetInfo() return {
	name      = "Icon Sets",
	desc      = "Manages alternate icon/buildpic sets.",
	author    = "Sprung",
	license   = "PD",
	layer     = 1,
	enabled   = true,
} end

options_path = 'Settings/Graphics/Unit Visibility/Radar Icons'
options_order = { 'coniconchassis', 'ships' }
options = {
	coniconchassis = {
		name = 'Show constructor chassis',
		desc = 'Do constructor icons show chassis? Conveys more information but reduces visibility somewhat.',
		type = 'bool',
		value = false,
		noHotkey = true,
		OnChange = function(self)
			if not self.value then
				Spring.SetUnitDefIcon(UnitDefNames["cloakcon"].id, "builder")
				Spring.SetUnitDefIcon(UnitDefNames["shieldcon"].id, "builder")
				Spring.SetUnitDefIcon(UnitDefNames["vehcon"].id, "builder")
				Spring.SetUnitDefIcon(UnitDefNames["tankcon"].id, "builder")
				Spring.SetUnitDefIcon(UnitDefNames["amphcon"].id, "builder")
				Spring.SetUnitDefIcon(UnitDefNames["jumpcon"].id, "builder")
				Spring.SetUnitDefIcon(UnitDefNames["spidercon"].id, "builder")
				Spring.SetUnitDefIcon(UnitDefNames["hovercon"].id, "builder")
				Spring.SetUnitDefIcon(UnitDefNames["shipcon"].id, "builder")
			else
				Spring.SetUnitDefIcon(UnitDefNames["cloakcon"].id, "kbotbuilder")
				Spring.SetUnitDefIcon(UnitDefNames["shieldcon"].id, "walkerbuilder")
				Spring.SetUnitDefIcon(UnitDefNames["vehcon"].id, "vehiclebuilder")
				Spring.SetUnitDefIcon(UnitDefNames["tankcon"].id, "tankbuilder")
				Spring.SetUnitDefIcon(UnitDefNames["amphcon"].id, "amphbuilder")
				Spring.SetUnitDefIcon(UnitDefNames["jumpcon"].id, "jumpjetbuilder")
				Spring.SetUnitDefIcon(UnitDefNames["spidercon"].id, "spiderbuilder")
				Spring.SetUnitDefIcon(UnitDefNames["hovercon"].id, "hoverbuilder")
				if options.ships.value then
					Spring.SetUnitDefIcon(UnitDefNames["shipcon"].id, "shipbuilder_alt")
				else
					Spring.SetUnitDefIcon(UnitDefNames["shipcon"].id, "shipbuilder")
				end
			end
		end,
	},
	ships = {
		name = 'Use standard ship icons',
		desc = 'Do ships use the standarized chassis-role icons instead of hull shape pictograms?',
		type = 'bool',
		value = false,
		noHotkey = true,
		OnChange = function(self)
			if not self.value then
				Spring.SetUnitDefIcon(UnitDefNames["shipscout"].id, "shipscout")
				Spring.SetUnitDefIcon(UnitDefNames["shiptorpraider"].id, "shiptorpraider")
				Spring.SetUnitDefIcon(UnitDefNames["shipriot"].id, "shipriot")
				Spring.SetUnitDefIcon(UnitDefNames["shipskirm"].id, "shipskirm")
				Spring.SetUnitDefIcon(UnitDefNames["shipassault"].id, "shipassault")
				Spring.SetUnitDefIcon(UnitDefNames["shiparty"].id, "shiparty")
				Spring.SetUnitDefIcon(UnitDefNames["shipaa"].id, "shipaa")
				if options.coniconchassis.value then
					Spring.SetUnitDefIcon(UnitDefNames["shipcon"].id, "shipbuilder")
				end
			else
				Spring.SetUnitDefIcon(UnitDefNames["shipscout"].id, "shipscout_alt")
				Spring.SetUnitDefIcon(UnitDefNames["shiptorpraider"].id, "shipraider_alt")
				Spring.SetUnitDefIcon(UnitDefNames["shipriot"].id, "shipriot_alt")
				Spring.SetUnitDefIcon(UnitDefNames["shipskirm"].id, "shipskirm_alt")
				Spring.SetUnitDefIcon(UnitDefNames["shipassault"].id, "shipassault_alt")
				Spring.SetUnitDefIcon(UnitDefNames["shiparty"].id, "shiparty_alt")
				Spring.SetUnitDefIcon(UnitDefNames["shipaa"].id, "shipaa_alt")
				if options.coniconchassis.value then
					Spring.SetUnitDefIcon(UnitDefNames["shipcon"].id, "shipbuilder_alt")
				end
			end
		end,
	},
}
