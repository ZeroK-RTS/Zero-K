function widget:GetInfo() return {
	name = "In-game Guide",
	enabled = true,
} end

options_path = 'Help'

options = {
	ingameguide_concept_wreckage = {
		name = "Wreckage",
		value= "When destroyed, units leave wreckage containing a part of their metal worth. This value can then be Reclaimed by constructors, which makes wreckage an important source of income. Wrecks are also physical objects and thus can obstruct projectiles and movement.",
		path = "Concepts"
	},
	ingameguide_concept_radar = {
		name = "Radar",
		value= "Radar is a sensor type that can detect the presence of enemy units at long range. It is very cheap, but cannot determine the unit types and the reported position is not perfectly accurate. Radar can be jammed to prevent units from being detected.",
		path = "Concepts"
	},
	ingameguide_concept_cloak = {
		name = "Cloak",
		value= "Cloak prevents units from being detected and seen by enemies. Taking damage, shooting, or moving too close to an enemy will decloak the unit.",
		path = "Concepts"
	},
	ingameguide_damage_emp = {
		name = "EMP",
		value= "EMP does not reduce the target's health; instead, it accumulates in the unit and will stun it when it exceeds its current health (reaching 100% on the health bar). Further EMP damage will increase the stun time. A stunned unit cannot do anything. EMP gradually wears off on its own.",
		path = "Damage Types"
	},
	ingameguide_damage_slow = {
		name = "Slow",
		value= "Slow damage accumulates in units and reduces most of their parameters, including movement and reload speed. A unit cannot be slowed beyond 50% and slow gradually wears off on its own.",
		path = "Damage Types"
	},
	ingameguide_damage_disarm = {
		name = "Disarm",
		value= "Disarm damage does not reduce the target's health; instead, it accumulates in the unit and will prevent shooting and using abilities it when it exceeds its current health (reaching 100% on the health bar). Further Disarm damage will increase the time of that effect. Disarm gradually wears off on its own.",
		path = "Damage Types"
	},
	ingameguide_damage_fire = {
		name = "Fire",
		value= "Flamethrowers and napalm can set units on fire. This causes them to steadily take damage for extended periods of time. Amphibious units can extinguish fire by moving underwater.",
		path = "Damage Types"
	},
	ingameguide_roles_raider = {
		name = "Raider",
		value= "Fast, light units who deal high damage. Use to harass the enemy economy and to counter skirmishers. Counter with riot units and defenses.",
		path = "Unit Roles"
	},
	ingameguide_roles_skirm = {
		name = "Skirmisher",
		value= "Skirishers are units designed to stay at range and kite their targets. Good in numbers and against slow units such as assaults and riots.",
		path = "Unit Roles"
	},
	ingameguide_roles_riot = {
		name = "Riot",
		value= "Riot units excel at crowd control, typically dealing lots of damage in a wide area - excellent against raiders. They are typically slow and have low range though, so counter them with skirmishers.",
		path = "Unit Roles"
	},
	ingameguide_ui_priority = {
		name = "Priority",
		value= "Constructors and units under construction can be assigned high or low priority. Units with higher priority are guaranteed to be assigned resources before those with lower.",
		path = "UI Features"
	},
	ingameguide_ui_repeat = {
		name = "Repeat",
		value= "The repeat toggle causes all finished orders to be copied onto the end of the order queue. Most importantly, factories can be made to build the selected unit composition indefinitely, but it can also be used for normal orders, for example area-repair on repeat sets up a repair haven.",
		path = "UI Features"
	},
	ingameguide_ui_labels = {
		name = "Labels",
		value= "By holding the ~ key and double-leftclicking on a location, a text label marker can be placed. The middle mouse button can be used to place a marker without a label. Dragging the left mouse button can be used to draw markings and the right mouse button is used to erase markers and drawings.",
		path = "UI Features"
	},
	ingameguide_ui_ferryroutes = {
		name = "Ferry routes",
		value= "Air transports can be made to automatically ferry units from a selected area to another. First, place a ferry route using the ferry route placement button. Transports can be assigned to ferry routes by moving them into the input circle. Units given a move order inside the circle will automatically wait for being transported before continuing with their orders.",
		path = "UI Features"
	},
	ingameguide_ui_retreat = {
		name = "Retreat",
		value= "Mobile units can be set to retreat when their health is brought low. Retreat zones can be placed on the map and will serve as targets for the retreating units, who will remain there until their health is brought back to full.",
		path = "UI Features"
	},
	ingameguide_ui_firestates = {
		name = "Fire States",
		value= "You can control how armed units pick targets using fire states.\n\nFire At Will (green) means they automatically acquire all targets.\nReturn Fire (yellow) has them only target units they have been dealt damage by.\nHold Fire (red) means the unit will only listen to manual attack orders.",
		path = "UI Features"
	},
	ingameguide_ui_movestates = {
		name = "Move States",
		value= "You can control your units' aggressiveness using move states.\n\nRoam (green) means the unit can chase its targets without restrictions.\nManeuver (yellow) makes units chase enemies, but only a limited distance from their original location.\nHold Position (red) means units will never chase enemies unless given a direct attack order.",
		path = "UI Features"
	},
}

options_order = {}

for key, value in pairs(options) do
	value.type = 'text'
	value.path = options_path .. '/' .. value.path
	options_order[#options_order+1] = key
end
