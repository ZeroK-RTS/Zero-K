function widget:GetInfo() return {
	name      = "Icon Sets",
	desc      = "Manages alternate icon/buildpic sets.",
	author    = "Sprung",
	license   = "PD",
	layer     = 1,
	enabled   = true,
} end

options_path = 'Settings/Graphics/Unit Visibility/Radar Icons'
options_order = { 'coniconchassis', 'gunship_pictograms' }
options = {
	coniconchassis = {
		name = 'Show constructor chassis',
		desc = 'Do constructor icons show chassis? Conveys more information but reduces visibility somewhat.',
		type = 'bool',
		value = false,
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
	gunship_pictograms = {
		name = 'Use pictograms for gunships',
		desc = 'Do gunships use pictograms instead of the usual role icons?',
		type = 'bool',
		value = true,
		OnChange = function(self)
			if not self.value then
				Spring.SetUnitDefIcon(UnitDefNames["blastwing"].id, "gunshipspecial")
				Spring.SetUnitDefIcon(UnitDefNames["bladew"].id, "gunshipscout")
				Spring.SetUnitDefIcon(UnitDefNames["armkam"].id, "gunshipraider")
				Spring.SetUnitDefIcon(UnitDefNames["gunshipsupport"].id, "gunshipskirm")
				Spring.SetUnitDefIcon(UnitDefNames["armbrawl"].id, "heavygunshipskirm")
				Spring.SetUnitDefIcon(UnitDefNames["blackdawn"].id, "heavygunshipassault")
				-- Spring.SetUnitDefIcon(UnitDefNames["corcrw"].id, "gunshipriot")
				Spring.SetUnitDefIcon(UnitDefNames["corvalk"].id, "gunshiptransport")
				Spring.SetUnitDefIcon(UnitDefNames["corbtrans"].id, "heavygunshiptransport")
			else
				Spring.SetUnitDefIcon(UnitDefNames["blastwing"].id, "airbomb")
				Spring.SetUnitDefIcon(UnitDefNames["bladew"].id, "smallgunship")
				Spring.SetUnitDefIcon(UnitDefNames["armkam"].id, "gunship")
				Spring.SetUnitDefIcon(UnitDefNames["gunshipsupport"].id, "gunshipears")
				Spring.SetUnitDefIcon(UnitDefNames["armbrawl"].id, "heavygunship")
				Spring.SetUnitDefIcon(UnitDefNames["blackdawn"].id, "heavygunshipears")
				-- Spring.SetUnitDefIcon(UnitDefNames["corcrw"].id, "supergunship")
				Spring.SetUnitDefIcon(UnitDefNames["corvalk"].id, "airtransport")
				Spring.SetUnitDefIcon(UnitDefNames["corbtrans"].id, "airtransportbig")
			end

			-- same in both, listed for completeness
			Spring.SetUnitDefIcon(UnitDefNames["gunshipaa"].id, "gunshipaa")
		end,
	},
}
