function widget:GetInfo() return {
	name = "In-game Guide",
	enabled = enable,
} end

options_path = 'Help'

options = {
	ingameguide_concept_wreckage = {
		name = WG.Translate("interface", "helpmenu_wreck"),
		value= WG.Translate("interface", "helpmenu_wreck_txt"),
		path = WG.Translate("interface", "helpmenu_concepts")
	},
	ingameguide_concept_overdrive = {
		name = WG.Translate("interface", "helpmenu_overdrive"),
		value= WG.Translate("interface", "helpmenu_overdrive_txt"),
		path = WG.Translate("interface", "helpmenu_concepts")
	},
	ingameguide_concept_grid = {
		name = WG.Translate("interface", "helpmenu_grid"),
		value= WG.Translate("interface", "helpmenu_grid_txt"),
		path = WG.Translate("interface", "helpmenu_concepts")
	},
	ingameguide_concept_radar = {
		name = WG.Translate("interface", "helpmenu_radar"),
		value= WG.Translate("interface", "helpmenu_radar_txt"),
		path = WG.Translate("interface", "helpmenu_concepts")
	},
	ingameguide_concept_cloak = {
		name = WG.Translate("interface", "helpmenu_cloak"),
		value= WG.Translate("interface", "helpmenu_cloak_txt"),
		path = WG.Translate("interface", "helpmenu_concepts")
	},
	ingameguide_damage_emp = {
		name = WG.Translate("interface", "helpmenu_emp"),
		value= WG.Translate("interface", "helpmenu_emp_txt"),
		path = WG.Translate("interface", "helpmenu_dmgtypes")
	},
	ingameguide_damage_slow = {
		name = WG.Translate("interface", "helpmenu_slow"),
		value= WG.Translate("interface", "helpmenu_slow_txt"),
		path = WG.Translate("interface", "helpmenu_dmgtypes")
	},
	ingameguide_damage_disarm = {
		name = WG.Translate("interface", "helpmenu_disarm"),
		value= WG.Translate("interface", "helpmenu_disarm_txt"),
		path = WG.Translate("interface", "helpmenu_dmgtypes")
	},
	ingameguide_damage_fire = {
		name = WG.Translate("interface", "helpmenu_fire"),
		value= WG.Translate("interface", "helpmenu_fire_txt"),
		path = WG.Translate("interface", "helpmenu_dmgtypes")
	},
	ingameguide_damage_gauss = {
		name = WG.Translate("interface", "helpmenu_gauss"),
		value= WG.Translate("interface", "helpmenu_gauss_txt"),
		path = WG.Translate("interface", "helpmenu_dmgtypes")
	},
	ingameguide_damage_collision = {
		name = WG.Translate("interface", "helpmenu_collision"),
		value= WG.Translate("interface", "helpmenu_collision_txt"),
		path = WG.Translate("interface", "helpmenu_dmgtypes")
	},
	ingameguide_damage_capture = {
		name = WG.Translate("interface", "helpmenu_capture"),
		value= WG.Translate("interface", "helpmenu_capture_txt"),
		path = WG.Translate("interface", "helpmenu_dmgtypes")
	},
	ingameguide_roles_raider = {
		name = WG.Translate("interface", "helpmenu_raiders"),
		value= WG.Translate("interface", "helpmenu_raiders_txt"),
		path = WG.Translate("interface", "helpmenu_uroles")
	},
	ingameguide_roles_skirm = {
		name = WG.Translate("interface", "helpmenu_skirms"),
		value= WG.Translate("interface", "helpmenu_skirms_txt"),
		path = WG.Translate("interface", "helpmenu_uroles")
	},
	ingameguide_roles_riot = {
		name = WG.Translate("interface", "helpmenu_riots"),
		value= WG.Translate("interface", "helpmenu_riots_txt"),
		path = WG.Translate("interface", "helpmenu_uroles")
	},
	ingameguide_roles_assault = {
		name = WG.Translate("interface", "helpmenu_assaults"),
		value= WG.Translate("interface", "helpmenu_assautls_txt"),
		path = WG.Translate("interface", "helpmenu_uroles")
	},
	ingameguide_roles_arty = {
		name = WG.Translate("interface", "helpmenu_arty"),
		value= WG.Translate("interface", "helpmenu_arty_txt"),
		path = WG.Translate("interface", "helpmenu_uroles")
	},
	ingameguide_ui_priority = {
		name = WG.Translate("interface", "helpmenu_priority"),
		value= WG.Translate("interface", "helpmenu_priority_txt"),
		path = WG.Translate("interface", "helpmenu_uifeatures")
	},
	ingameguide_ui_repeat = {
		name = WG.Translate("interface", "helpmenu_repeat"),
		value= WG.Translate("interface", "helpmenu_repeat_txt"),
		path = WG.Translate("interface", "helpmenu_uifeatures")
	},
	ingameguide_ui_labels = {
		name = WG.Translate("interface", "helpmenu_labels"),
		value= WG.Translate("interface", "helpmenu_labels_txt"),
		path = WG.Translate("interface", "helpmenu_uifeatures")
	},
	ingameguide_ui_ferryroutes = {
		name = WG.Translate("interface", "helpmenu_ferry"),
		value= WG.Translate("interface", "helpmenu_ferry_txt"),
		path = WG.Translate("interface", "helpmenu_uifeatures")
	},
	ingameguide_ui_retreat = {
		name = WG.Translate("interface", "helpmenu_retreat"),
		value= WG.Translate("interface", "helpmenu_retreat_txt"),
		path = WG.Translate("interface", "helpmenu_uifeatures")
	},
	ingameguide_ui_firestates = {
		name = WG.Translate("interface", "helpmenu_fstates"),
		value= WG.Translate("interface", "helpmenu_fstates_txt"),
		path = WG.Translate("interface", "helpmenu_uifeatures")
	},
	ingameguide_ui_movestates = {
		name = WG.Translate("interface", "helpmenu_mstates"),
		value= WG.Translate("interface", "helpmenu_mstates_txt"),
		path = WG.Translate("interface", "helpmenu_uifeatures")
	},
	ingameguide_ui_mapoverlay = {
		name = WG.Translate("interface", "helpmenu_map"),
		value= WG.Translate("interface", "helpmenu_map_txt"),
		path = WG.Translate("interface", "helpmenu_uifeatures")
	},
}

options_order = {}

for key, value in pairs(options) do
	value.type = 'text'
	value.path = options_path .. '/' .. value.path
	options_order[#options_order+1] = key
end
