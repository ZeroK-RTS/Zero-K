function widget:GetInfo()
	return {
		name	= "Context Menu",
		desc	= "v0.1 Chili Context Menu\nPress [Space] while clicking for a context menu.",
		author	= "CarRepairer, localized by Shaman",
		date	= "2009-06-02",
		license	= "GNU GPL, v2 or later",
		layer	= 0,
		enabled	= true,
	}
end

--[[
Todo:
- Puppy kamikaziness (is through weapon/gadget, not self-D)
- Deployability (Crab, Djinn, Slasher) - needs sensible way to convey these, each one does different thing when static
- Weapon impulse (no idea how the values relate to applied force, will need research)
- Drone production (would need some work to do properly because of entanglement)
- Clogging (Dirtbag)
- Water tank (Archer)

Customparams to add to units:
stats_show_death_explosion

Customparams to add to weapons:
stats_hide_aoe
stats_hide_range
stats_hide_damage
stats_hide_reload
stats_hide_dps
stats_hide_projectile_speed
]]

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

include("keysym.lua")
VFS.Include("LuaRules/Utilities/numberfunctions.lua")
VFS.Include("LuaRules/Utilities/versionCompare.lua")
local carrierDefs = {}

local spSendLuaRulesMsg			= Spring.SendLuaRulesMsg
local spGetCurrentTooltip		= Spring.GetCurrentTooltip
local spGetUnitDefID			= Spring.GetUnitDefID
local spGetUnitAllyTeam			= Spring.GetUnitAllyTeam
local spGetUnitTeam				= Spring.GetUnitTeam
local spTraceScreenRay			= Spring.TraceScreenRay
local spGetTeamInfo				= Spring.GetTeamInfo
local spGetPlayerInfo			= Spring.GetPlayerInfo
local spGetTeamColor			= Spring.GetTeamColor
local spGetModKeyState			= Spring.GetModKeyState

local abs						= math.abs
local strFormat 				= string.format

local echo = Spring.Echo

local VFSMODE      = VFS.RAW_FIRST
local ignoreweapon, iconFormat = VFS.Include(LUAUI_DIRNAME .. "Configs/chilitip_conf.lua" , nil, VFSMODE)
local confdata = VFS.Include(LUAUI_DIRNAME .. "Configs/epicmenu_conf.lua", nil, VFSMODE)
local color = confdata.color

local iconTypesPath = LUAUI_DIRNAME.."Configs/icontypes.lua"
local icontypes = VFS.FileExists(iconTypesPath) and VFS.Include(iconTypesPath)

local emptyTable = {}

local moduleDefs, chassisDefs, upgradeUtilities = VFS.Include("LuaRules/Configs/dynamic_comm_defs.lua")

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local Chili
local Button
local Label
local Window
local ScrollPanel
local StackPanel
local Grid
local TextBox
local Image
local screen0
local color2incolor

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local WINDOW_WIDTH  = 650
local B_HEIGHT 		= 30
local icon_size 	= 18

local scrH, scrW 		= 0,0
local myAlliance 		= Spring.GetLocalAllyTeamID()
local myTeamID 			= Spring.GetLocalTeamID()

local ceasefires 		= (not Spring.FixedAllies())
local marketandbounty 	= false

local window_unitcontext
local statswindows = {}

local colorCyan = {0.2, 0.7, 1, 1}
local colorFire = {1, 0.3, 0, 1}
local colorPurple = {0.9, 0.2, 1, 1}
local colorDisarm = {0.5, 0.5, 0.5, 1}
local colorCapture = {0.6, 1, 0.6, 1}

local valkMaxCost = tonumber(UnitDefNames.gunshiptrans.customParams.transportcost)
local valkMaxSize = UnitDefNames.gunshiptrans.transportSize * 2

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Generate unit behaviour paths
local BEHAVIOUR_PATH = "Settings/Unit Behaviour/Default States/"

local behaviourPath = {}
local unitAlreadyAdded = {}

local function AddFactoryOfUnits(defName)
	if unitAlreadyAdded[defName] then
		return
	end
	local ud = UnitDefNames[defName]
	local name = string.gsub(ud.humanName, "/", "-")
	local path = BEHAVIOUR_PATH .. name
	behaviourPath[ud.id] = path
	if ud.customParams.parent_of_plate then
		behaviourPath[UnitDefNames[ud.customParams.parent_of_plate].id] = path
	end
	for i = 1, #ud.buildOptions do
		behaviourPath[ud.buildOptions[i]] = path
	end
end

AddFactoryOfUnits("factoryshield")
AddFactoryOfUnits("factorycloak")
AddFactoryOfUnits("factoryveh")
AddFactoryOfUnits("factoryplane")
AddFactoryOfUnits("factorygunship")
AddFactoryOfUnits("factoryhover")
AddFactoryOfUnits("factoryamph")
AddFactoryOfUnits("factoryspider")
AddFactoryOfUnits("factoryjump")
AddFactoryOfUnits("factorytank")
AddFactoryOfUnits("factoryship")
AddFactoryOfUnits("striderhub")
AddFactoryOfUnits("staticmissilesilo")

local buildOpts = VFS.Include("gamedata/buildoptions.lua")
local factory_commands, econ_commands, defense_commands, special_commands = include("Configs/integral_menu_commands_processed.lua", nil, VFS.RAW_FIRST)

local droneDefs, _, commanderDroneDefs = VFS.Include("LuaRules/Configs/drone_defs.lua")
for id, data in pairs(droneDefs) do -- For whatever reason, unitDefID is not the same.
	carrierDefs[UnitDefs[id].name] = data
end


for i = 1, #buildOpts do
	local name = buildOpts[i]
	local unitDefID = UnitDefNames[name].id
	local isDrone = UnitDefs[unitDefID].customParams.is_drone ~= nil
	if econ_commands[-unitDefID] then
		behaviourPath[unitDefID] = BEHAVIOUR_PATH .. "Economy"
	elseif defense_commands[-unitDefID] then
		behaviourPath[unitDefID] = BEHAVIOUR_PATH .. "Defence"
	elseif special_commands[-unitDefID] then
		behaviourPath[unitDefID] = BEHAVIOUR_PATH .. "Special"
	elseif not isDrone then
		behaviourPath[-unitDefID] = BEHAVIOUR_PATH .. "Misc"
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local function MakeStatsWindow()
end

options_order = {'shortNotation', 'window_height', 'window_to_cursor', 'window_pos_x', 'window_pos_y', 'text_hotkey'}
options_path = 'Help/Unit List'
options = {
	shortNotation = {
		name = "Short Number Notation",
		type = 'bool',
		value = false,
		noHotkey = true,
		desc = 'Shows short number notation for HP and other values.',
		path = 'Settings/HUD Panels/Unit Stats Help Window'
	},
	window_height = {
		name = "Window Height",
		type = 'number',
		value = 450,
		min = 450,
		max = 1000,
		desc = 'Set default window height.',
		path = 'Settings/HUD Panels/Unit Stats Help Window'
	},
	window_to_cursor = {
		name = "Create window under cursor",
		type = 'bool',
		value = true,
		desc = 'Creates the window under the mouse cursor, otherwise uses the values below for position.',
		path = 'Settings/HUD Panels/Unit Stats Help Window'
	},
	window_pos_x = {
		name = "Window Default X",
		type = 'number',
		value = 150,
		min = 0,
		max = 2000,
		path = 'Settings/HUD Panels/Unit Stats Help Window'
	},
	window_pos_y = {
		name = "Window Default Y",
		type = 'number',
		value = 150,
		min = 0,
		max = 2000,
		path = 'Settings/HUD Panels/Unit Stats Help Window'
	},
	
	text_hotkey = {
		name = 'Global Construction Hotkeys',
		type = 'text',
		value = [[These hotkey are always active. To edit the in-tab hotkeys look in "Hotkeys/Command Panel". Each tab can even have their own layout.]],
		path = 'Hotkeys/Construction',
	},
}

local hitscan = {
	BeamLaser = true,
	LightningCannon = true,
} -- there's no point in making this table repeatedly when we're going to reuse it.

local localizationCommon = {
	player = "Player",
	commander = "Commander",
	health = "Health",
	metal = "Metal",
	energy = "Energy",
	buildpower = "Buildpower",
}

local localization = {
	menu_close = "close",
	edit_behavior = "edit behavior",
	target_water_only = "(water only)",
	target_manual_fire = "(manual fire)",
	target_antiair = "(anti-air only)",
	target_guidance = "(guidance only)",
	shield_hp = "Strength",
	shield_percost = "Strength per metal",
	shield_regencost = "Regen cost",
	shield_delay = "Regen delay",
	shield_nolink = "Does not link with other shields",
	vampirism_heals = "Heals self for",
	vampirism_perhit = "health per hit",
	wolverine_mine = "mine",
	altitude_bonus = "Altitude bonus",
	stats_damage = "Damage",
	stats_duringcloakstrike = "(during cloak strike)",
	stats_shielddamage = "Shield damage",
	stats_reload = "Reload time",
	stats_aimtime = "Aim time",
	stats_horizontal_deviation = "Max Horizontal deviation",
	stats_vertical_deviation = "Max Vertical Deviation",
	stats_exponential_damage_increase = "Increases by",
	stats_exponential_damage_capsat = "Caps out at",
	stats_ignores_shield = "Ignores shields",
	stats_stun_time = "Stun time",
	stats_burn_time = "Burn time",
	stats_aoe = "Explosion radius",
	stats_weapon_speed = "Projectile speed",
	stats_force_decloak = "Forces decloak for",
	weapon_instant_hit = "Instantly hits",
	stats_missile_launch_speed = "Launch speed",
	stats_missile_speed = "Max speed",
	stats_missile_fuel_time = "Flight Time",
	stats_acceleration = "Acceleration",
	explodes_on_timeout = "Explodes on timeout",
	falls_on_timeout = "Falls down on timeout",
	stats_homing = "Guidance Rate",
	stats_cruisemissile = "Cruise Missile",
	stats_cruisealtitude = "Altitude",
	stats_begins_descent = "Begins descent",
	stats_from_target = "elmo from target",
	stats_tracks_target = "Tracks target",
	stats_guided_cruise = "Guided Cruise, unguided descent",
	laser_guided = "Laser Guided",
	needs_guidance = "(Needs external guidance)",
	external_targeter = "Provides External Guidance",
	stats_inaccuracy = "Inaccuracy",
	stats_wobble = "Flight Instability",
	stats_wobble_desc = "up to",
	stats_blastwave_only_allies = "Only affects allies",
	stats_burst_time = "Burst time",
	stats_armor_boost_friendly_only = "Boosts Allied Units' Armor",
	stats_armor_boost_all = "Boosts All Units' Armor",
	stats_armor_boost = "Armor bonus",
	duration = "Duration",
	stats_armor_boost_doesnt_diminish_duration = "Duration does not diminish with distance",
	stats_armor_boost_doesnt_diminish_effect = "Effect does not diminish with distance",
	stats_armor_boost_diminishes = "Effect and duration falloff with distance",
	stats_armor_pen = "Ignores Armor",
	stats_spawns = "Spawns",
	stats_spawn_duration = "Self destructs after",
	stats_blastwave = "Creates a blastwave",
	stats_blastwave_startsize = "Initial Size",
	stats_blastwave_healing_set = "Heals up to",
	stats_blastwave_initial_healing = "Initial Healing",
	stats_blastwave_initial_damage = "Initial Damage",
	stats_overslow_duration = "Saturated Slow",
	stats_impulse = "Impulse",
	stats_blastwave_expansion_rate = "Expansion rate",
	stats_blastwave_power_loss = "Power loss",
	stats_blastwave_final_radius = "Final radius",
	stats_slows_down_after_firing = "Speed lowers after firing",
	weapon_creates_gravity_well = "Creates a gravity well",
	weapon_groundfire = "Sets the ground on fire",
	weapon_creates_singularity = "Creates a Singularity",
	weapon_firing_arc = "Firing Arc",
	weapon_grid_demand = "Grid Needed",
	grid_link = "Grid Link Range",
	grid_needed = "Required Grid Energy",
	altitude = "Altitude",
	sight_range = "Sight range",
	singularity_strength = "Strength",
	weapon_arcing = "Arcing shot",
	weapon_stockpile_time = "Stockpile time",
	weapon_stockpile_cost = "Stockpile cost",
	weapon_smooths_ground = "Smoothes ground",
	weapon_moves_structures = "Smoothes under structures",
	weapon_high_traj = "High Trajectory",
	weapon_toggable_traj = "Toggable Trajectory",
	weapon_water_capable = "Water capable",
	weapon_potential_friendly_fire = "Potential Friendly Fire",
	weapon_no_ground_collide = "Passes through ground",
	weapon_increased_damage_vs_large = "Damage increase vs large units",
	weapon_damage_falloff = "Damage falls off with range",
	weapon_damage_closeup_falloff = "Damage increases with range",
	weapon_no_friendly_fire = "No friendly fire",
	weapon_piercing = "Piercing",
	weapon_shield_drain = "Costs shield to fire:",
	weapon_shield_drain_desc = "charge per shot",
	weapon_aim_delay = "Aiming delay",
	weapon_inaccuracy_vs_moving = "Inaccurate against moving targets",
	weapon_interceptable = "Can be shot down by antinukes",
	weapon_cluster_munitions = "Cluster Submunitions",
	weapon_cluster_ttr = "Time-To-Release",
	spooling_weapon = "Spooling Weapon",
	spooling_weapon_bonus = "Bonus reload speed per shot",
	spooling_max_bonus = "Maximum firerate bonus",
	spooling_bonus_time_to_max = "Time Until Max Firerate",
	construction = "Construction",
	starting_buildpower = "Starting buildpower",
	buildpower_increases_use = "Buildpower increases with use",
	max_buildpower = "Maximum buildpower",
	buildpower_diminishes_with_disuse = "Buildpower decreases after disuse",
	decay_rate = "Decay rate",
	base_buildpower = "Base Buildpower",
	recharge_delay = "Recharge delay",
	buildpower_regen_rate = "Regeneration rate",
	can_resurrect = "Can resurrect wreckage",
	only_assists = "Can only assist",
	vampirism = "Vampirism",
	vampirism_kills_increase_hp = "Increases max with kills",
	armored_unit = "Hardened Armor",
	armor_reduction = "Damage Reduction",
	armor_type_1 = "Applies while closed",
	armor_type_2 = "Applies while stopped",
	forced_closed = "Forcefully closed on damage",
	area_cloak = "Area cloak",
	upkeep = "Upkeep",
	recon_pulse = "Recon Pulse",
	recon_pulse_desc = "Jams enemy cloaking. Range: 500",
	recon_pulse_applied = "Pings every 2 seconds",
	personal_cloak = "Personal Cloak",
	upkeep_mobile = "Upkeep while mobile",
	upkeep_stationary = "Upkeep while stationary",
	decloak_radius = "Decloak Radius",
	cloakstrike = "Cloaked Ambush Advantage",
	cloakstrike_lose_advantage = "Loses multipler alongside cloak when shooting",
	unit_no_decloak_on_fire = "Doesn't lose cloak upon shooting",
	only_idle = "Only when idle",
	idle_cloak_free = "Free and automated",
	cloak_regen = "Regenerates while cloaked",
	provides_intel = "Provides intel",
	radar = "Radar Range",
	jamming = "Radar Stealth Field",
	improves_radar = "Improves radar accuracy",
	speed = "Speed",
	movement = "Movement Type",
	climbs = "Maximum Slope Tolerance",
	turn_rate = "Turn rate",
	metal_income = "Metal Income",
	energy_income = "Energy Income",
	unit_info = "Unit Info",
	mid_air_jump = "Midair jump",
	morphing = "Morphing",
	morphs_to = "Morphs to",
	cost = "Cost",
	bp = "Build Rate",
	rate = "Rate",
	rank_required = "Required Rank",
	morph_time = "Time",
	not_disabled_morph = "Not disabled during morph",
	disabled_morph = "Disabled during morph",
	improved_regen = "Improved regeneration",
	idle_regen = "Idle Regeneration",
	regen_time_to_enable = "Time to enable",
	constant_regen = "Combat Regeneration",
	nano_regen = "Nanite Reactive Armor",
	base_regen = "Base Regeneration",
	max_regen = "Max Regeneration",
	max_below = "Maximum bonus below",
	water_regen = "Water Regeneration",
	armor_regen = "Armored Regeneration",
	teleporter = "Teleporter",
	spawns_beacon = "Spawns a beacon for one-way recall",
	spawn_time = "Time to spawn",
	at_depth = "At depth",
	mass = "Mass",
	teleport_throughput = "Throughput",
	rearm_repair = "Rearms and repairs aircraft",
	rearm_pads = "Pads",
	pad_bp = "Pad buildpower",
	drone_bound = "Bound to owner",
	drone_cannot_direct_control = "Cannot be directly controlled",
	drone_uses_owners_commands = "Uses owner's commands",
	drone_bound_to_range = "Must stay in range of owner",
	drone_dies_on_owner_death = "Will die if owner does",
	speed_boost = "Speed boost",
	wind_gen = "Generates energy from wind",
	wind_variable_income = "Variable income",
	max_generation = "Maximum Generation",
	wind_100_height = "Energy per 100 height",
	grey_goo = "Grey Goo",
	grey_goo_consumption = "Uses nearby wreckage for replication",
	jump = "Jumping",
	dangerous_reclaim = "Explodes when attempting to reclaim",
	floats = "Floating",
	can_move_to_surface = "Can move from seabed to surface",
	cannot_move_sideways = "Cannot move sideways while afloat",
	sinks_when_stun = "Sinks when stunned",
	float_when_stun = "Stays afloat when stunned",
	transportation = "Transports Units",
	transport_type = "Transport Type",
	transport_light = "Light",
	transport_heavy = "Heavy",
	transport_light_speed = "Loaded Speed",
	transport_heavy_speed = "Heavy Load Speed",
	anti_interception = "Can intercept strategic nukes",
	combat_slowdown = "Combat slowdown",
	radar_invisible = "Invisible to Radar",
	instant_selfd = "Instant self-destruction",
	requires_geo = "Requires thermal vent to build",
	extracts_metal = "Extracts metal",
	fireproof = "Fireproof (Immune to burning damage)",
	gravitronic_regulation = "Gravitronic Regulation (Immune to impulse)",
	storage = "Stores Resources",
	shared_to_team = "Shares metal extraction to team",
	free = "Free",
	movetype_immobile = "Immobile",
	movetype_plane = "Aircraft",
	movetype_gunship = "Gunship",
	movetype_sub = "Submarine",
	movetype_waterwalker = "Swimming",
	movetype_hover = "Hovercraft",
	movetype_amph = "Amphibious",
	movetype_spider = "All-terrain",
	movetype_bot = "Bot",
	movetype_veh = "Vehicle",
	movetype_ship = "Ship",
	level = "Level",
	chassis = "Chassis",
	modules = "MODULES",
	death_explosion = "Death Explosion",
	builds = "BUILDS",
	weapons = "WEAPONS",
	abilities = "ABILITIES",
	stats = "STATS",
	time_to_reach = "Time to reach",
	speed_while_reloading = "Movement speed while reloading",
	drone_max_range = "Drone Max Range",
	drone_target_range = "Drone Acqusition Range",
	drone_controllable = "Controllable",
	drone_verybigrange = "Infinite max range",
	drone_autofabs = "Drone autofabs",
	drone_production_speed = "Drone Build Speed",
	can_be_transported = "Transportable",
	min_output = "Minimum Output",
	max_output = "Maximum Output",
	output_compounds = "Output increases over time",
	output_decays = "Output decays over time",
	cloaked_speed = "Cloaked Speed",
	decloaked_speed = "Decloaked Speed",
	pull = "pull",
	push = "push",
	radius = "Radius",
	stats_range = "Range",
	regen = "Regeneration",
	acronyms_hp = "hp",
	acronyms_second = "sec",
	acronyms_dps = "DPS",
	acronyms_agl = "AGL",
	acronyms_emp = "EMP",
	acronyms_slow = "S",
	acronyms_disarm = "D",
	acronyms_capture = "C",
	alliance = "Team",
	team = "Squad",
	yes = "Yes",
	no = "No",
	drone_carrier = "Drone carrier",
	drone_buildslots = "Number of Autofabs",
	cooldown = "Cooldown",
	drone_label = "Drone Complement",
	drones_per_cycle = "Drones started per cycle",
	drone_build_time = "Build time",
	chainlightning = "Forks to nearby units:",
	chainlightning_jumps = "Jumps to",
	chainlightning_efficency = "Effiency:",
	chainlightning_extrajumps = "Forks jump to nearby units",
	field_fac = "field factory",
	disrupts_shields = "Disrupts shields"
}

local function UpdateLocalization()
	for k, _ in pairs(localization) do
		localization[k] =  WG.Translate ("interface", k)
	end
	for k, _ in  pairs(localizationCommon) do
		localizationCommon[k] = WG.Translate("interface", k)
	end
end

local alreadyAdded = {}

local function addUnit (unitDefID, path, buildable)
	if (alreadyAdded[unitDefID]) then
		return
	end
	alreadyAdded[unitDefID] = true
	local ud = UnitDefs[unitDefID]
	local unitName = ud.humanName
	local optionName = unitName .. 'help'
	options[optionName] = {
		name = unitName,
		type = 'button',
		desc = "Description For " .. unitName,
		OnChange = function(self)
			MakeStatsWindow(ud)
		end,
		path = options_path ..'/' .. path,
	}
	options_order[#options_order + 1] = optionName
	
	if (buildable) then
		optionName = unitName .. 'build'
		options[unitName .. 'build'] = {
			name=unitName,
			type='button',
			desc = "Build " .. unitName,
			action = 'buildunit_' .. ud.name,
			path = 'Hotkeys/Construction/' .. path,
		}
		options_order[#options_order + 1] = optionName
	end
end

local function AddFactoryOfUnits(defName)
	local ud = UnitDefNames[defName]
	local name = "Units/" .. string.gsub(ud.humanName, "/", "-")
	addUnit(ud.id, "Buildings/Factory", true)
	for i = 1, #ud.buildOptions do
		addUnit(ud.buildOptions[i], name, true)
	end
end

AddFactoryOfUnits("factoryshield")
AddFactoryOfUnits("factorycloak")
AddFactoryOfUnits("factoryveh")
AddFactoryOfUnits("factoryplane")
AddFactoryOfUnits("factorygunship")
AddFactoryOfUnits("factoryhover")
AddFactoryOfUnits("factoryamph")
AddFactoryOfUnits("factoryspider")
AddFactoryOfUnits("factoryjump")
AddFactoryOfUnits("factorytank")
AddFactoryOfUnits("factoryship")
AddFactoryOfUnits("striderhub")
AddFactoryOfUnits("staticmissilesilo")

local buildOpts = VFS.Include("gamedata/buildoptions.lua")
local factory_commands, econ_commands, defense_commands, special_commands = include("Configs/integral_menu_commands_processed.lua", nil, VFS.RAW_FIRST)

for i = 1, #buildOpts do
	local udid = UnitDefNames[buildOpts[i]].id
	if econ_commands[-udid] then
		addUnit(udid,"Buildings/Economy", true)
	elseif defense_commands[-udid] then
		addUnit(udid,"Buildings/Defence", true)
	elseif special_commands[-udid] then
		addUnit(udid,"Buildings/Special", true)
	end
end

-- Misc stuff without direct buildability
addUnit(UnitDefNames["energyheavygeo"].id, "Buildings/Economy", true) -- moho geo
addUnit(UnitDefNames["athena"].id, "Units/Misc", true) -- athena
addUnit(UnitDefNames["wolverine_mine"].id, "Units/Misc", false) -- maybe should go under LV fac, like wolverine? to consider.
addUnit(UnitDefNames["tele_beacon"].id, "Units/Misc", false)


local lobbyIDs = {} -- stores peoples names by lobbyID to match commanders to owners
local players = Spring.GetPlayerList()
for i = 1, #players do
	local customkeys = select(10, Spring.GetPlayerInfo(players[i]))
	if customkeys.lobbyid then
		lobbyIDs[customkeys.lobbyid] = select(1, Spring.GetPlayerInfo(players[i], false))
	end
end


--[[ Mods can add "tier 2", "moho" etc mexes that gather a different
     amount of metal per spot. In those cases, display the multiplier
     for all mexes. Avoid it for vanilla tho because it's implying. ]]
local differentMexTypeExists = false

for i = 1, #UnitDefs do
	local ud = UnitDefs[i]
	local cp = ud.customParams
	local mexMult = tonumber(cp.metal_extractor_mult)
	if mexMult and mexMult ~= 1 and mexMult > 0 then
		differentMexTypeExists = true
	end

	if not alreadyAdded[i] then
		local ud = UnitDefs[i]
		if ud.name:lower():find('pw_') and (Spring.GetGameRulesParam("planetwars_structures") == 1) then
			addUnit(i,"Misc/Planet Wars", false)
		elseif ud.name:lower():find('chicken') and Spring.GetGameRulesParam("difficulty") then -- fixme: not all of these are actually used
			addUnit(i,"Misc/Chickens", false)
		elseif ud.customParams.is_drone then
			addUnit(i,"Units/Misc/Drones", false)
		end
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function comma_value(amount, displayPlusMinus, forceDecimal)
	local formatted

	-- amount is a string when ToSI is used before calling this function
	if amount and type(amount) == "number" then
		if (amount == 0) then
			formatted = "0"
		else
			if (amount < 2 and (amount * 100)%100 ~=0) then
				if displayPlusMinus then
					formatted = strFormat("%+.2f", amount)
				else
					formatted = strFormat("%.2f", amount)
				end
			elseif (amount < 20 and (amount * 10)%10 ~=0) or forceDecimal then
				if displayPlusMinus then
					formatted = strFormat("%+.1f", amount)
				else
					formatted = strFormat("%.1f", amount)
				end
			else
				if displayPlusMinus then
					formatted = strFormat("%+d", amount)
				else
					formatted = strFormat("%d", amount)
				end
			end
		end
	elseif amount then
		formatted = amount .. ""
	else
		formatted = "Missing Data"
	end

	return formatted
end

local function numformat(num, forceDecimal)
	return options.shortNotation.value and ToSIPrec(num) or comma_value(num, false, forceDecimal)
end

local function AdjustWindow(window)
	local nx
	if (0 > window.x) then
		nx = 0
	elseif (window.x + window.width > screen0.width) then
		nx = screen0.width - window.width
	end

	local ny
	if (0 > window.y) then
		ny = 0
	elseif (window.y + window.height > screen0.height) then
		ny = screen0.height - window.height
	end

	if (nx or ny) then
		window:SetPos(nx,ny)
	end
end
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local function CloseButtonFunc(self)
	self.parent.parent:Dispose()
end
local function CloseButtonFunc2(self)
	self.parent.parent.parent:Dispose()
end

local function CloseButton(width)
	return Button:New{
		caption = localization.menu_close,
		OnClick = { CloseButtonFunc },
		width=width,
		height = B_HEIGHT,
		--backgroundColor=color.sub_back_bg,
		--textColor=color.sub_back_fg,
		--classname = "back_button",
	}
end

local UnitDefByHumanName_cache = {}
local function GetUnitDefByHumanName(humanName)
	local cached_udef = UnitDefByHumanName_cache[humanName]
	if (cached_udef ~= nil) then
		return cached_udef
	end
	-- uncomment the altResult stuff to allow a non-exact match
	--local altResult

	for _,ud in pairs(UnitDefs) do
		if (ud.humanName == humanName) then
			UnitDefByHumanName_cache[humanName] = ud
			return ud
		--elseif (ud.humanName:find(humanName)) then
		--	altResult = altResult or ud
		end
	end
	--if altResult then
	--	UnitDefByHumanName_cache[humanName] = altResult
	--	return altResult
	--end
	
	UnitDefByHumanName_cache[humanName] = false
	return false
end

local function GetShieldRegenDrain(wd)
	local shieldRegen = wd.shieldPowerRegen
	if shieldRegen == 0 and wd.customParams and wd.customParams.shield_rate then
		shieldRegen = wd.customParams.shield_rate
	end
	
	local shieldDrain = wd.shieldPowerRegenEnergy
	if shieldDrain == 0 and wd.customParams and wd.customParams.shield_drain then
		shieldDrain = wd.customParams.shield_drain
	end
	return shieldRegen, shieldDrain
end

local function AddEntryToCells(text, layer, entry, cells)
	if layer > 0 then
		text =  string.rep("\t\t", layer) .. text
	end
	cells[#cells + 1] = text
	if entry == nil then
		cells[#cells + 1] = ''
	else
		cells[#cells + 1] = entry
	end
end

local function weapons2Table(cells, ws, unitID, bombletCount, recursedWepIds, deathExplosion, cost, isFeature, layer, index)
	local isCommander
	if unitID then
		if isFeature then
			isCommander = Spring.GetFeatureRulesParam(unitID, "comm_weapon_num_1") ~= nil
		else
			isCommander = Spring.GetUnitRulesParam(unitID, "comm_weapon_num_1") ~= nil
		end
		Spring.Echo("IsCommander: " .. tostring(isCommander))
	end
	--Spring.Echo("Index: " .. tostring(index))
	local cells = cells
	local startPoint = #cells+1
	if layer == nil then layer = 0 end
	local wd
	if bombletCount then
		wd = WeaponDefNames[ws] --GetWeapon for some reason doesn't work
	else
		wd = WeaponDefs[ws.weaponID]
	end
	local recursedWepIds = recursedWepIds
	recursedWepIds[#recursedWepIds+1] = wd.name
	local cp = wd.customParams or emptyTable
	local comm_mult
	if isFeature then
		comm_mult = (unitID and Spring.GetFeatureRulesParam(unitID, "comm_damage_mult")) or 1
	else
		comm_mult = (unitID and Spring.GetUnitRulesParam(unitID, "comm_damage_mult")) or 1
	end
	local name = wd.description or "Weapon"
	if bombletCount then
		if not deathExplosion then
			name = name .. " x " .. math.floor(bombletCount * comm_mult)
		end
	elseif ws.count > 1 then
		name = name .. " x " .. ws.count
	end
	if wd.type == "TorpedoLauncher" then
		name = name .. " " .. localization.target_water_only
	end
	if wd.manualFire then
		name = name .. " " .. localization.target_manual_fire
	end
	if not bombletCount and ws.aa_only then
		name = name .. " " .. localization.target_antiair
	end
	if cp.targeter then
		name = name .. " " .. localization.target_guidance
	end
	if not (cp.bogus or cp.hideweapon)  then
		AddEntryToCells(name, layer, nil, cells)
	end
	if wd.isShield then
		local regen, drain = GetShieldRegenDrain(wd)
		AddEntryToCells(localization.shield_hp .. ":", layer + 1, wd.shieldPower .. " " .. localization.acronyms_hp, cells)
		AddEntryToCells(localization.shield_percost .. ":", layer + 1, numformat(wd.shieldPower / cost, 2), cells)
		AddEntryToCells(localization.regen .. ":", layer + 1, regen .. localization.acronyms_hp .. "/" .. localization.acronyms_second, cells)
		AddEntryToCells(localization.shield_regencost .. ":", layer + 1, drain .. " " .. localizationCommon.energy .. "/" .. localization.acronyms_second, cells)
		local rechargeDelay = tonumber(wd.shieldrechargedelay or wd.customParams.shield_recharge_delay)
		if rechargeDelay and rechargeDelay > 0 then
			AddEntryToCells(localization.shield_delay .. ":", layer + 1, rechargeDelay .. " " .. localization.acronyms_second, cells)
		end
		AddEntryToCells(localization.radius .. ':', layer + 1, wd.shieldRadius .. " elmo", cells)
		if wd.customParams.unlinked then
			AddEntryToCells(localization.shield_nolink, layer + 1, nil, cells)
		end
	else
		-- calculate damages
		if not (cp.bogus or cp.hideweapon) then
			local dam  = 0
			local damw = 0
			local dams = 0
			local damd = 0
			local damc = 0
			local stun_time = 0
			local baseDamage = tonumber(cp.stats_damage) or wd.customParams.shield_damage or 0
			if unitID and index then
				if isFeature then
					comm_mult = Spring.GetFeatureRulesParam(unitID, index .. "_actual_dmgboost") or comm_mult
				else
					comm_mult = Spring.GetUnitRulesParam(unitID, index .. "_actual_dmgboost") or comm_mult
				end
			end
			local val = baseDamage * comm_mult
			if cp.disarmdamagemult then
				damd = val * cp.disarmdamagemult
				if (cp.disarmdamageonly == "1") then
					val = 0
				end
				stun_time = tonumber(cp.disarmtimer)
			end
			if cp.timeslow_damagefactor then
				dams = val * cp.timeslow_damagefactor
				if (cp.timeslow_onlyslow == "1") then
					val = 0
				end
			end
			if cp.is_capture then
				damc = val
				val = 0
			end
			if cp.extra_damage then
				damw = tonumber(cp.extra_damage) * comm_mult
				stun_time = tonumber(wd.customParams.extra_paratime)
			end
			if wd.paralyzer then
				damw = val
				if stun_time == 0 then
					stun_time = wd.damages.paralyzeDamageTime
				end
			else
				dam = val
			end
			if cp.vampirism then
				AddEntryToCells(localization.vampirism_heals, layer + 1, numformat(tonumber(cp.vampirism) * dam, 1) .. ' ' .. localization.vampirism_perhit, cells)
			end
			-- get reloadtime and calculate dps
			local reloadtime
			if unitID and index then
				if isFeature and Spring.GetFeatureRulesParam(unitID, "comm_weapon_num_1") ~= nil then
					reloadtime = Spring.GetFeatureRulesParam(unitID, index .. "_basereload") or tonumber(cp.script_reload) or wd.reload
				elseif not isFeature and Spring.GetUnitRulesParam(unitID, "comm_weapon_num_1") ~= nil then
					reloadtime = Spring.GetUnitRulesParam(unitID, index .. "_basereload") or tonumber(cp.script_reload) or wd.reload
				else
					reloadtime = tonumber(cp.script_reload) or wd.reload
				end
			else	
				reloadtime = tonumber(cp.script_reload) or wd.reload
			end
			local maxReload = reloadtime
			local wantsExtraReloadInfo = false
			if cp.recycler then
				local maxbonus = tonumber(cp.recycle_maxbonus) -- recycle_reductiontime, recycle_reduction, recycle_reductionframes, recycle_maxbonus, recycle_bonus
				maxReload = math.ceil((reloadtime / (1 + maxbonus)) * 30) / 30
				AddEntryToCells(localization.spooling_weapon .. ":", layer + 1, nil, cells)
				local bonusReloadSpeed = tonumber(cp.recycle_bonus)
				AddEntryToCells(localization.spooling_weapon_bonus .. ":", layer + 2, numformat(bonusReloadSpeed * 100, 1) .. '%', cells)
				AddEntryToCells(localization.spooling_max_bonus .. ":", layer + 2, numformat(maxbonus * 100, 2) .. "%", cells)
				local currentFireRate = reloadtime
				local currentBonus = 0
				local totalFrames = 0
				local currentreload = math.ceil(reloadtime * 30)
				while currentBonus < maxbonus do
					totalFrames = totalFrames + currentreload
					currentBonus = math.min(currentBonus + bonusReloadSpeed, maxbonus)
					currentreload = math.ceil(reloadtime / (1 + currentBonus))
				end
				totalFrames = totalFrames / 30 -- frames -> seconds
				AddEntryToCells(localization.spooling_bonus_time_to_max .. ":", layer + 2, numformat(totalFrames, 2) .. localization.acronyms_second, cells)
			end
			if maxReload ~= reloadtime then
				wantsExtraReloadInfo = true
			end
			local aimtime = (tonumber(cp.aimdelay) or 0) / 30
			local fixedreload = reloadtime + aimtime
			local projectiles
			local bursts
			if unitID and index and isCommander then
				if isFeature then
					projectiles = Spring.GetFeatureRulesParam(unitID, index .. "_projectilecount_override") or tonumber(cp.statsprojectiles) or  wd.projectiles
					bursts = Spring.GetFeatureRulesParam(unitID, index .. "_updatedburst_count") or (tonumber(cp.script_burst) or wd.salvoSize)
				else
					local projectileRules = Spring.GetUnitRulesParam(unitID, index .. "_projectilecount_override")
					local burstRules = Spring.GetUnitRulesParam(unitID, index .. "_updatedburst_count")
					--Spring.Echo("Projectile count: " .. tostring(projectileRules))
					--Spring.Echo("Bursts: " .. tostring(burstRules))
					projectiles = projectileRules or tonumber(cp.statsprojectiles) or wd.projectiles
					bursts = burstRules or (tonumber(cp.script_burst) or wd.salvoSize)
				end
			else
				projectiles = tonumber(cp.statsprojectiles) or wd.projectiles
				bursts = (tonumber(cp.script_burst) or wd.salvoSize)
			end
			local mult = bursts * projectiles
			local dps  = dam /fixedreload
			local dpsw = damw/fixedreload
			local dpss = dams/fixedreload
			local dpsd = damd/fixedreload
			local dpsc = damc/fixedreload
			local dps_str, dam_str, shield_dam_str = '', '', ''
			local damageTypes = 0
			if dps > 0 then
				dam_str = dam_str .. numformat(dam,2)
				shield_dam_str = shield_dam_str .. numformat(dam,2)
				if cp.stats_damage_per_second then
					dps_str = dps_str .. numformat(tonumber(cp.stats_damage_per_second),2)
				else
					dps_str = dps_str .. numformat(dps*mult,2)
				end
				if wantsExtraReloadInfo then
					dps_str = dps_str .. "(" .. numformat(dam/maxReload, 2) .. ")"
				end
				damageTypes = damageTypes + 1
			end
			if dpsw > 0 then
				if dps_str ~= '' then
					dps_str = dps_str .. ' + '
					dam_str = dam_str .. ' + '
					shield_dam_str = shield_dam_str .. ' + '
				end
				dam_str = dam_str .. color2incolor(colorCyan) .. numformat(damw,2) .. " (" .. localization.acronyms_emp .. ")\008"
				shield_dam_str = shield_dam_str .. color2incolor(colorCyan) .. numformat(math.floor(damw / 3),2) .. " (" .. localization.acronyms_emp .. ")\008"
				dps_str = dps_str .. color2incolor(colorCyan) .. numformat(dpsw*mult,2) .. " (" .. localization.acronyms_emp .. ")\008"
				if wantsExtraReloadInfo then
					dps_str = dps_str .. "(" .. color2incolor(colorCyan) .. numformat(damw/maxReload, 2) .. "\008)"
				end
				damageTypes = damageTypes + 1
			end
			if dpss > 0 then
				if dps_str ~= '' then
					dps_str = dps_str .. ' + '
					dam_str = dam_str .. ' + '
					shield_dam_str = shield_dam_str .. ' + '
				end
				dam_str = dam_str .. color2incolor(colorPurple) .. numformat(dams,2) .. " (" .. localization.acronyms_slow .. ")\008"
				shield_dam_str = shield_dam_str .. color2incolor(colorPurple) .. numformat(math.floor(dams / 3),2) .. " (" .. localization.acronyms_slow .. ")\008"
				dps_str = dps_str .. color2incolor(colorPurple) .. numformat(dpss*mult,2) .. " (" .. localization.acronyms_slow .. ")\008"
				if wantsExtraReloadInfo then
					dps_str = dps_str .. "(" .. color2incolor(colorPurple) .. numformat(dams / maxReload) .. "\008)"
				end
				damageTypes = damageTypes + 1
			end
			if dpsd > 0 then
				if dps_str ~= '' then
					dps_str = dps_str .. ' + '
					dam_str = dam_str .. ' + '
					shield_dam_str = shield_dam_str .. ' + '
				end
				dam_str = dam_str .. color2incolor(colorDisarm) .. numformat(damd,2) .. " (" .. localization.acronyms_disarm .. ")\008"
				shield_dam_str = shield_dam_str .. color2incolor(colorDisarm) .. numformat(math.floor(damd / 3),2) .. " (" .. localization.acronyms_disarm .. ")\008"
				dps_str = dps_str .. color2incolor(colorDisarm) .. numformat(dpsd*mult,2) .. " (" .. localization.acronyms_disarm .. ")\008"
				if wantsExtraReloadInfo then
					dps_str = dps_str .. "(" .. color2incolor(colorDisarm) .. numformat(damd / maxReload, 2) .. "\008"
				end
				damageTypes = damageTypes + 1
			end
			if dpsc > 0 then
				if dps_str ~= '' then
					dps_str = dps_str .. ' + '
					dam_str = dam_str .. ' + '
					shield_dam_str = shield_dam_str .. ' + '
				end
				dam_str = dam_str .. color2incolor(colorCapture) .. numformat(damc,2) .. " (" .. localization.acronyms_capture .. ")\008"
				shield_dam_str = shield_dam_str .. color2incolor(colorCapture) .. numformat(damc,2) .. " (" .. localization.acronyms_capture .. ")\008"
				dps_str = dps_str .. color2incolor(colorCapture) .. numformat(dpsc*mult,2) .. " (" .. localization.acronyms_capture .. ")\008"
				if wantsExtraReloadInfo then
					dps_str = dps_str .. "(" .. color2incolor(colorCapture) .. numformat(damc / maxReload, 2) .. "\008"
				end
				damageTypes = damageTypes + 1
			end
			if mult > 1 then
				dam_str = dam_str .. " x " .. mult
				shield_dam_str = shield_dam_str .. " x " .. mult
			end
			if cp.shield_mult then
				shield_dam_str = shield_dam_str .. " x " .. math.floor(100*cp.shield_mult) .. '%'
			end
			local show_damage = not (cp.stats_hide_damage or cp.norealdamage or cp.puredecloaktime)
			local show_dps = not cp.stats_hide_dps
			local show_reload = not cp.stats_hide_reload
			local show_range = not cp.stats_hide_range
			local show_aoe = not cp.stats_hide_aoe
			local show_projectile_speed = not cp.stats_hide_projectile_speed and not hitscan[wd.type]
			if ((dps + dpsw + dpss + dpsd + dpsc) < 2) then -- no damage: newtons and such
				show_damage = false
				show_dps = false
			end
			if cp.damage_vs_shield and cp.spawns_name then -- Badger
				dam_str = tostring(cp.damage_vs_shield) .. " (" .. dam .. " + " .. (tonumber(cp.damage_vs_shield)-dam) .. " " .. localization.wolverine_mine .. ")"
				dps_str = numformat(math.floor(tonumber(cp.damage_vs_shield)/reloadtime))
			end
			if show_damage then
				if cp.cloakstrike then
					local str1 = localization.stats_damage .. ' ' .. localization.stats_duringcloakstrike .. ':'
					--Spring.Echo(tostring(dam_str))
					--Spring.Echo("dam: " .. dam)
					local csMult = tonumber(cp.cloakstrike)
					local ndmg = dam * csMult
					--Spring.Echo("ndmg: " .. ndmg)
					local npara = damw * csMult
					local nslow = dams * csMult
					local ndis = damd * csMult
					local ncap = damc * csMult
					local newstr = dam_str
					newstr = newstr:gsub(numformat(dam, 2), numformat(ndmg, 2))
					if npara then
						newstr = newstr:gsub(numformat(damw, 2), numformat(npara, 2))
					end
					if nslow then
						newstr = newstr:gsub(numformat(dams, 2), numformat(nslow, 2))
					end
					if ndis then
						newstr = newstr:gsub(numformat(damd, 2), numformat(ndis, 2))
					end
					if ncap then
						newstr = newstr:gsub(numformat(damc, 2), numformat(ncap, 2))
					end
					AddEntryToCells(str1, layer + 1, newstr, cells)
				end
				AddEntryToCells(localization.stats_damage .. ":", layer + 1, dam_str, cells)
				if cp.chainlightning_searchdist then
					local targets = cp.chainlightning_maxtargets
					local efficency = numformat((tonumber(cp.chainlightning_efficiency) or 0) * 100, 2) .. "%"
					AddEntryToCells(localization.chainlightning, layer + 1, nil, cells)
					AddEntryToCells(localization.chainlightning_jumps, layer + 1, targets, cells)
					AddEntryToCells(localization.chainlightning_efficency, layer + 2, efficency, cells)
					AddEntryToCells(localization.stats_range, layer + 2, cp.chainlightning_searchdist, cells)
					if cp.chainlightning_extrabounces then
						AddEntryToCells(localization.chainlightning_extrajumps, layer + 2, cp.chainlightning_extrabounces, cells)
					end
				end
			end
			-- shield damage
			if (wd.interceptedByShieldType ~= 0) and show_damage and not cp.stats_hide_shield_damage and not deathExplosion then
				if cp.damage_vs_shield then
					AddEntryToCells(localization.stats_shielddamage .. ':', layer + 1, numformat(cp.stats_shield_damage), cells)
				elseif tonumber(cp.stats_shield_damage) ~= baseDamage then
					local str1 = localization.stats_shielddamage .. ':'
					if damageTypes > 1 or mult > 1 then
						AddEntryToCells(str1, layer + 1, numformat(math.floor(cp.stats_shield_damage * mult * comm_mult), 2) .. "(" .. shield_dam_str .. ")", cells)
					else
						AddEntryToCells(str1, layer + 1, numformat(math.floor(cp.stats_shield_damage * mult * comm_mult), 2), cells)
					end
				end
			end
			if cp.shield_disruption then
				AddEntryToCells(localization.disrupts_shields .. ":", layer + 1, numformat(tonumber(cp.shield_disruption) / 30, 1) .. localization.acronyms_second, cells)
			end
			if cp.post_capture_reload then
				AddEntryToCells(localization.stats_reload .. ':', layer + 1, numformat (tonumber(cp.post_capture_reload)/30,2) .. localization.acronyms_second, cells)
			elseif show_reload and not bombletCount then
				AddEntryToCells(localization.stats_reload .. ':', layer + 1, numformat (reloadtime,2) .. localization.acronyms_second, cells)
			end
			if aimtime > 0 then
				local headingerror = tonumber(cp.allowedheadingerror) or 0.000001
				local pitcherror = tonumber(cp.allowedpitcherror) or 0.01
				AddEntryToCells(localization.stats_aimtime ..  ':', layer + 1, numformat(aimtime, 2) .. localization.acronyms_second, cells)
				AddEntryToCells(localization.stats_horizontal_deviation .. ':', layer + 2, numformat(headingerror/2, 1) .. "°", cells)
				AddEntryToCells(localization.stats_vertical_deviation .. ':', layer + 2, '±' .. numformat(pitcherror/2, 1) .. "°", cells)
			end
			if show_dps and not bombletCount then
				AddEntryToCells(localization.acronyms_dps .. ':', layer + 1, dps_str, cells)
				if cp.dmg_scaling then
					AddEntryToCells(localization.stats_exponential_damage_increase .. ':', layer + 1, numformat(tonumber(cp.dmg_scaling) * 3000) .. "%/s", cells) -- 3000 = 100 * 30
					local str1 = localization.stats_exponential_damage_capsat .. ':'
					if tonumber(cp.dmg_scaling_max) < 10000 then
						AddEntryToCells(str1, layer + 2, numformat(tonumber(cp.dmg_scaling_max) * 100) .. "%", cells)
					else
						AddEntryToCells(str1, layer + 2, "∞%", cells)
					end
				end
			end
			if (wd.interceptedByShieldType == 0) then
				AddEntryToCells(localization.stats_ignores_shield, layer + 1, '', cells)
			end
			if stun_time > 0 then
				AddEntryToCells(localization.stats_stun_time .. ':', layer + 1, color2incolor((damw > 0) and colorCyan or colorDisarm) .. numformat(stun_time,2) .. 's\008', cells)
			end
			if cp.setunitsonfire then
				local afterburn_frames = (cp.burntime or (450 * (wd.fireStarter or 0)))
				AddEntryToCells(localization.stats_burn_time .. ':', layer + 1, color2incolor(colorFire) .. numformat(afterburn_frames/30) .. 's (15' .. localization.acronyms_dps .. ')\008', cells)
			end
			if cp.sensortag then
				local secs = tonumber(cp.sensortag) or 0
				if secs > 0 then
					AddEntryToCells(WG.Translate("interface", "sensor_tag", {seconds = numformat(secs, 1)}), layer + 1, '', cells)
				end
			end
			if cp.sensorsteal then
				local secs = tonumber(cp.sensorsteal) or 0
				if secs > 0 then
					AddEntryToCells(WG.Translate("interface", "sensor_steal", {seconds = numformat(secs, 1)}), layer + 1, '', cells)
				end
			end
			if show_range and not bombletCount then
				local range = cp.truerange or wd.range
				local rangemult
				local baserange
				if isFeature then
					rangemult = (unitID and Spring.GetFeatureRulesParam(unitID, "comm_range_mult")) or 1
					baserange = (unitID and Spring.GetFeatureRulesParam(unitID, index .. "_range")) or cp.truerange or wd.range
				else
					rangemult = (unitID and Spring.GetUnitRulesParam(unitID, "comm_range_mult")) or 1
					baserange = (unitID and Spring.GetUnitRulesParam(unitID, index .. "_range")) or cp.truerange or wd.range
				end
				AddEntryToCells(localization.stats_range .. ':', layer + 1, numformat(baserange * rangemult, 2) .. " elmo", cells)
			end
			if wd.customParams.puredecloaktime then
				AddEntryToCells(localization.stats_force_decloak, layer + 1, numformat(wd.customParams.puredecloaktime / 30, 1) .. localization.acronyms_second, cells)
			end
			local aoe = wd.impactOnly and 0 or wd.damageAreaOfEffect
			if aoe > 15 and show_aoe then
				AddEntryToCells(localization.stats_aoe .. ':', layer + 1,  numformat(aoe) .. " elmo", cells)
			end
			if show_projectile_speed and not bombletCount then
				local speed
				if isCommander and unitID and index then
					if isFeature then
						speed = Spring.GetFeatureRulesParam(unitID, index .. "_speed") or wd.projectilespeed
					else
						speed = wd.projectilespeed
					end
				else
					speed = wd.projectilespeed
				end
				AddEntryToCells(localization.stats_weapon_speed .. ':', layer + 1, numformat(speed*30) .. " elmo/" .. localization.acronyms_second, cells)
			elseif hitscan[wd.type] then
				AddEntryToCells(localization.weapon_instant_hit, layer + 1, '', cells)
			end
			--Unimportant stuff, maybe make togglable with some option later
			if (wd.type == "MissileLauncher") then
				if ((wd.startvelocity < wd.projectilespeed) and (wd.weaponAcceleration > 0)) then
					AddEntryToCells(localization.stats_missile_launch_speed .. ':', layer + 1, numformat(wd.startvelocity*30) .. " - " .. numformat(wd.projectilespeed*30) .. " elmo/" .. localization.acronyms_second, cells)
					AddEntryToCells(localization.stats_acceleration .. ':', layer + 1, numformat(wd.weaponAcceleration*900) .. " elmo/" .. localization.acronyms_second .. "²", cells)
				else
					AddEntryToCells(localization.stats_missile_speed .. ':', layer + 1, numformat(wd.projectilespeed*30) .. " elmo/" .. localization.acronyms_second, cells)
				end
				if cp.flighttime then
					AddEntryToCells(localization.stats_missile_fuel_time .. ':', layer + 1, numformat(tonumber(cp.flighttime)) .. localization.acronyms_second, cells)
				else
					AddEntryToCells(localization.stats_missile_fuel_time .. ':', layer + 1, numformat(((wd.range / wd.projectilespeed) + (wd.selfExplode and 25 or 0))/32) .. localization.acronyms_second, cells)
				end
				if wd.selfExplode then
					AddEntryToCells(localization.explodes_on_timeout, layer + 1, '', cells)
				else
					AddEntryToCells(localization.falls_on_timeout, layer + 1, '', cells)
				end
			end
			if wd.tracks and wd.turnRate > 0 and (cp.cruisealt == nil or cp.cruisedist == nil) then
				local turnrate = wd.turnRate * 30 * 180 / math.pi
				AddEntryToCells(localization.stats_homing .. ':', layer + 1, numformat(turnrate, 1) .. " °/" .. localization.acronyms_second, cells)
			end
			if cp.ballistic_guidance then
				AddEntryToCells(localization.stats_homing .. ':', layer + 1, numformat(tonumber(cp.ballistic_guidance), 1) .. " elmos/" .. localization.acronyms_second .. "²", cells)
			end
			if cp.cruisealt and cp.cruisedist then
				AddEntryToCells(localization.stats_cruisemissile .. ':', layer + 1, '', cells)
				AddEntryToCells(localization.stats_cruisealtitude .. ':', layer + 2, cp.cruisealt .. ' elmo ' .. localization.acronyms_agl, cells)
				AddEntryToCells(localization.stats_begins_descent .. ':', layer + 2, wd.customParams.cruisedist .. ' ' .. localization.stats_from_target, cells)
				if cp.cruisetracking and cp.cruise_nolock == nil then
					local turnrate = wd.turnRate * 30 * 180 / math.pi
					AddEntryToCells(localization.stats_tracks_target .. ':', layer + 2, numformat(turnrate, 1) .. '°/' .. localization.acronyms_second, cells)
				end
				if cp.cruisetracking and cp.cruise_nolock then
					AddEntryToCells(localization.stats_guided_cruise, layer + 2, '', cells)
				end
				if wd.customParams.cruise_randomizationtype == "circle" then
					AddEntryToCells(WG.Translate("interface", "stats_circular_spread", {size = cp.cruiserandomradius}), layer + 2, '', cells)
				elseif wd.customParams.cruiserandomradius then
					AddEntryToCells(WG.Translate("interface", "stats_cruise_error", {radius = cp.cruiserandomradius}), layer + 2, '', cells)
				end
			end
			if cp.tracker and cp.externaltracker == nil then
				AddEntryToCells(localization.laser_guided, layer + 1, '', cells)
			elseif cp.tracker then
				AddEntryToCells(localization.laser_guided .. " " .. localization.needs_guidance, layer + 1, '', cells)
			end
			if cp.externaltargeter then
				AddEntryToCells(localization.external_targeter, layer + 1, '', cells)
			end
			if cp.needsuplink then
				AddEntryToCells(WG.Translate("interface", "needs_guidance_for_seconds", {seconds = numformat(cp.needsuplink / 30, 2)}) .. " " .. localization.acronyms_second, layer + 1, '', cells)
			end
			if wd.wobble > 0 then
				local wobble = wd.wobble * 30 * 180 / math.pi
				AddEntryToCells(localization.stats_wobble .. ':', layer + 1, localization.stats_wobble_desc .. " " .. numformat(wobble, 1) .. "°/" .. localization.acronyms_second, cells)
			end
			
			if wd.sprayAngle > 0 and not bombletCount then
				local sprayangle
				if unitID and isCommander then
					if isFeature then
						sprayangle = Spring.GetFeatureRulesParam(unitID, index .. "_sprayangle") or wd.sprayAngle
					else
						sprayangle = Spring.GetUnitRulesParam(unitID, index .. "_sprayangle") or wd.sprayAngle
					end
				else
					sprayangle = wd.sprayAngle
				end
				local accuracy = math.asin(sprayangle) * 90 / math.pi
				AddEntryToCells(localization.stats_inaccuracy .. ':', layer + 1, numformat(accuracy, 1) .. "°", cells)
			end
	
			if wd.type == "BeamLaser" and wd.beamtime > 0.2 then
				AddEntryToCells(localization.stats_burst_time .. ':', layer + 1, numformat(wd.beamtime) .. localization.acronyms_second, cells)
			end
			if cp.grants_armor then
				local impactsEnemies = cp.affects_enemy ~= nil
				local duration = tonumber(cp.armor_duration)
				local noScaling = cp.noscaling ~= nil
				local noTimeScaling = noScaling or cp.notimescaling ~= nil
				if not impactsEnemies then
					AddEntryToCells(localization.stats_armor_boost_friendly_only .. ":", layer + 1, '', cells)
				else
					AddEntryToCells(localization.stats_armor_boost_all .. ":", layer + 1, '', cells)
				end
				AddEntryToCells(localization.stats_armor_boost .. ":", layer + 2, numformat(tonumber(cp.grants_armor) * 100, 1) .. "%", cells)
				AddEntryToCells(localization.duration .. ":", layer + 2, numformat(duration, 1) .. localization.acronyms_second, cells)
				if not noScaling and noTimeScaling then
					AddEntryToCells(localization.stats_armor_boost_doesnt_diminish_duration, layer + 2, '', cells)
				elseif noScaling then
					AddEntryToCells(localization.stats_armor_boost_doesnt_diminish_effect, layer + 2, '', cells)
				else
					AddEntryToCells(localization.stats_armor_boost_diminishes, layer + 2, '', cells)
				end
			end
			if cp.armorpiercing then
				local apValue = tonumber(cp.armorpiercing) or 0
				if apValue ~= 0 then
					AddEntryToCells(localization.stats_armor_pen .. ":", layer + 1, numformat(apValue * 100, 1) .. "%", cells)
				end
			end
			if cp.spawns_name then
				AddEntryToCells(localization.stats_spawns .. ':', layer + 1, Spring.Utilities.GetHumanName(UnitDefNames[cp.spawns_name]), cells)
				if cp.spawns_expire then
					AddEntryToCells(localization.stats_spawn_duration .. ':', layer + 1, cp.spawns_expire .. localization.acronyms_second, cells)
				end
			end
			if cp.blastwave_size then
				AddEntryToCells(localization.stats_blastwave .. ':', layer + 1, '', cells)
				AddEntryToCells(localization.stats_blastwave_startsize .. ':', layer + 2, cp.blastwave_size, cells)
				if blastwave_healing then
					if cp.blastwave_healing_reduction then
						AddEntryToCells(localization.stats_blastwave_healing_set .. ':', layer + 2, blastwave_healing .. ' ' .. localization.acronyms_hp, cells)
					else
						AddEntryToCells(localization.stats_blastwave_initial_healing .. ':', layer + 2, blastwave_healing, cells)
					end
				end
				local slowdmg = tonumber(cp.blastwave_slowdmg) or 0 * comm_mult
				local empdmg = tonumber(cp.blastwave_empdmg) or 0 * comm_mult
				local overslow = tonumber(cp.blastwave_overslow) or 0 * comm_mult
				local emptime = tonumber(cp.blastwave_emptime) or 0 * comm_mult
				local damage = tonumber(cp.blastwave_damage) or 0 * comm_mult
				local damagestring = damage .. " "
				if empdmg > 0 then
					damagestring = damagestring .. color2incolor(colorCyan) .. empdmg .. "( " .. emptime .. localization.acronyms_second .. ")\008 "
				end
				if slowdmg > 0 then
					damagestring = damagestring .. color2incolor(colorPurple) ..slowdmg .. "\008 "
				end
				AddEntryToCells(localization.stats_blastwave_initial_damage .. ':', layer + 2, damagestring, cells)
				if overslow > 0 then
					AddEntryToCells(localization.stats_overslow_duration .. ":", layer + 2, numformat(overslow / 30, 3) .. localization.acronyms_second, cells)
				end
				if cp.blastwave_onlyfriendly then
					AddEntryToCells(localization.stats_blastwave_only_allies, layer + 2, '', cells)
				end
				local speed = tonumber(cp.blastwave_speed) or 0
				local size = tonumber(cp.blastwave_size) or 0
				local life = tonumber(cp.blastwave_life) or 1
				local impulse = tonumber(cp.blastwave_impulse) or 0
				if impulse > 0 then
					AddEntryToCells(localization.stats_impulse .. ':', layer + 2, numformat(impulse, 3), cells)
				end
				--AddEntryToCells(localization.stats_impulse ..':', layer + 2, size .. " elmos", cells) -- seems to be repeat info
				AddEntryToCells(localization.stats_blastwave_expansion_rate .. ':', layer + 2, numformat(speed * 30, 2) .. " elmo/" .. localization.acronyms_second, cells)
				AddEntryToCells(localization.stats_blastwave_power_loss .. ':', layer + 2, numformat((1 - (tonumber(cp.blastwave_lossfactor) or 0.95)) * 100, 2) .. "%/frame", cells)
				AddEntryToCells(localization.duration .. ":", layer + 2, numformat(life / 30, 3) .. localization.acronyms_second, cells)
				AddEntryToCells(localization.stats_blastwave_final_radius .. ':', layer + 2, numformat(size + (speed * life), 2) .. " elmos", cells)
			end
			
			if cp.reload_move_mod_time  and not bombletCount then
				AddEntryToCells(localization.stats_slows_down_after_firing .. ':', layer + 1, cp.reload_move_mod_time .. localization.acronyms_second, cells)
			end
			if cp.area_damage then
				if (cp.area_damage_is_impulse == "1") then
					AddEntryToCells(localization.weapon_creates_gravity_well .. ":", layer + 1, '', cells)
				else
					AddEntryToCells(localization.weapon_groundfire .. ':', layer + 1, '', cells)
					AddEntryToCells(localization.acronyms_dps .. ":", layer + 2, cp.area_damage_dps, cells)
				end
				AddEntryToCells(localization.radius .. ':', layer + 2, numformat(tonumber(cp.area_damage_radius)) .. " elmo", cells)
				AddEntryToCells(localization.duration .. ':', layer + 2, numformat(tonumber(cp.area_damage_duration)) .. " " .. localization.acronyms_second, cells)
			end
			if cp.singularity then
				AddEntryToCells(localization.weapon_creates_singularity, layer + 1, '', cells)
				AddEntryToCells(localization.duration .. ":", layer + 2, numformat(cp.singu_lifespan/30, 1) .. localization.acronyms_second, cells)
				local singustrength = tonumber(cp.singu_strength) * comm_mult
				if singustrength > 0 then
					AddEntryToCells(localization.singularity_strength .. ":", layer + 2, numformat(singustrength, 1) .. "elmo/" .. localization.acronyms_second .. localization.pull, cells)
				else
					AddEntryToCells(localization.singularity_strength .. ":", layer + 2, numformat(singustrength, 1) .. "elmo/" .. localization.acronyms_second .. localization.push, cells)
				end
				AddEntryToCells(localization.radius .. ':', layer + 2, cp.singu_radius .. " elmo", cells)
			end
			if wd.trajectoryHeight > 0  and not bombletCount then
				AddEntryToCells(localization.weapon_arcing .. ':', layer + 1, numformat(math.atan(wd.trajectoryHeight) * 180 / math.pi) .. "°", cells)
			end
	
			if not bombletCount and wd.stockpile then
				AddEntryToCells(localization.weapon_stockpile_time ..':', layer + 1, (((tonumber(ws.stockpile_time) or 0) > 0) and tonumber(ws.stockpile_time) or wd.stockpileTime) .. localization.acronyms_second, cells)
				if ((not ws.free_stockpile) and (ws.stockpile_cost or (wd.metalCost > 0))) then
					AddEntryToCells(localization.weapon_stockpile_cost .. ':', layer + 1, ws.stockpile_cost or wd.metalCost .. " " .. localizationCommon.metal, cells)
				end
			end
	
			if not bombletCount and ws.firing_arc and (ws.firing_arc > -1) then
				AddEntryToCells(localization.weapon_firing_arc .. ':', layer + 1, numformat(360*math.acos(ws.firing_arc)/math.pi) .. '°', cells)
			end
	
			if cp.needs_link then
				AddEntryToCells(localization.weapon_grid_demand .. ':', layer + 1, tonumber(cp.needs_link) .. " " .. localizationCommon.energy, cells)
			end
	
			if cp.smoothradius then
				AddEntryToCells(localization.weapon_smooths_ground, layer + 1, '', cells)
			end
			if cp["reveal_unit"] then
				local artyrevealstring = WG.Translate("interface", "weapon_arty_reveal", {time = cp["reveal_unit"]})
				AddEntryToCells(artyrevealstring, layer + 1, '', cells)
			end
			if cp.movestructures then
				AddEntryToCells(localization.weapon_moves_structures, layer + 1, '', cells)
			end
			
			if not bombletCount then
				local highTraj = wd.highTrajectory
				if highTraj == 2 then
					highTraj = ws.highTrajectory
				end
				if highTraj == 1 then
					AddEntryToCells(localization.weapon_high_traj, layer + 1, '', cells)
				elseif highTraj == 2 then
					AddEntryToCells(localization.weapon_toggable_traj, layer + 1, '', cells)
				end
			end
			
			if wd.waterWeapon and (wd.type ~= "TorpedoLauncher") then
				AddEntryToCells(localization.weapon_water_capable, layer + 1, '', cells)
			end
	
			if not wd.avoidFriendly and not wd.noFriendlyCollide then
				AddEntryToCells(localization.weapon_potential_friendly_fire, layer + 1, '', cells)
			end
	
			if wd.noGroundCollide then
				AddEntryToCells(localization.weapon_no_ground_collide, layer + 1, '', cells)
			end
	
			if wd.noExplode then
				AddEntryToCells(localization.weapon_piercing, layer + 1, '', cells)
				if not (cp.single_hit or cp.single_hit_multi) then
					AddEntryToCells(localization.weapon_increased_damage_vs_large, layer + 1, '', cells)
				end
			end
	
			if cp.dyndamageexp then
				if wd.dynDamageInverted then
					AddEntryToCells(localization.weapon_damage_closeup_falloff, layer + 1, '', cells)
				else
					AddEntryToCells(localization.weapon_damage_falloff, layer + 1, '', cells)
				end
			end
	
			if cp.nofriendlyfire then
				AddEntryToCells(localization.weapon_no_friendly_fire, layer + 1, '', cells)
			end
	
			if not bombletCount and cp.shield_drain then
				AddEntryToCells(localization.weapon_shield_drain .. ":", layer + 1, cp.shield_drain .. " " .. localization.weapon_shield_drain_desc, cells)
			end
	
			if not bombletCount and cp.aim_delay then
				AddEntryToCells(localization.weapon_aim_delay .. ':', layer + 1, numformat(tonumber(cp.aim_delay)/1000) .. localization.acronyms_second, cells)
			end
	
			if not bombletCount and wd.targetMoveError > 0 then
				AddEntryToCells(localization.weapon_inaccuracy_vs_moving, layer + 1, '', cells)
			end
			if cp.stats_custom_tooltip_1 then
				local q = 1
				local txt = ""
				local desc = ""
				local key
				while cp["stats_custom_tooltip_" .. q] do
					key = "stats_custom_tooltip_" .. q
					if string.find(key, "_contextmenu_") then -- try to translate this.
						key = string.gsub(key, "_contextmenu_", "")
						txt = localization[key]
					end
					AddEntryToCells(cp["stats_custom_tooltip_" .. q] or "", layer + 1, cp["stats_custom_tooltip_entry_" .. q] or "", cells)
					q = q + 1
				end
			end
			
			if wd.targetable and ((wd.targetable == 1) or (wd.targetable == true)) then
				AddEntryToCells(localization.weapon_interceptable, layer + 1, '', cells)
			end
		end
		--cluster info
		--RECURSION INCOMING!
		if cp.numprojectiles1 then
			if not (cp.bogus or cp.hideweapon) then
				AddEntryToCells(localization.weapon_cluster_munitions .. ':', layer + 1, '', cells)
			end
			local submunitionCount = 1
			while cp["numprojectiles" .. submunitionCount] do
				local isRecusive = false
				for i = 1, #recursedWepIds do
					if cp["projectile" .. submunitionCount] == recursedWepIds[i] then
						isRecusive = true
					end
				end
				if isRecusive then
					AddEntryToCells(WeaponDefNames[cp["projectile" .. submunitionCount]].description .. ' x ' .. cp["numprojectiles" .. submunitionCount] .. ' (Previously Listed)', layer + 1, '', cells)
				else
					cells = weapons2Table(cells, cp["projectile" .. submunitionCount], unitID, cp["numprojectiles" .. submunitionCount] * (cp.bogus and bombletCount or 1) * (cp["clustercharges"] or 1), recursedWepIds, false, cost, isFeature, layer + 2, index)
				end
				submunitionCount = submunitionCount + 1
			end
			if cp["clustercharges"] then
				AddEntryToCells(localization.weapon_cluster_ttr .. ':', layer + 1, numformat(cp["clustercharges"]/30) .. localization.acronyms_second, cells)
			end
		end
	end
	return cells
end

local function printAbilities(ud, unitID, isFeature)
	local cells = {}

	local cp = ud.customParams
	
	if ud.buildSpeed > 0 and not cp.nobuildpower then
		local bpMult = 1
		if isFeature then
			bpMult = unitID and Spring.GetFeatureRulesParam(unitID, "buildpower_mult") or 1
		elseif unitID and Spring.GetUnitRulesParam(unitID, "comm_level") then
			bpMult = unitID and Spring.GetUnitRulesParam(unitID, "buildpower_mult") or 1
		end
		local buildSpeed = ud.buildSpeed * bpMult
		AddEntryToCells(localization.construction, 1, '', cells)
		if ud.customParams.bp_overdrive then
			local charge = tonumber(ud.customParams.bp_overdrive_initialcharge)
			local maxCharge = tonumber(ud.customParams.bp_overdrive_totalcharge)
			local bonusBP = tonumber(ud.customParams.bp_overdrive_bonus) -- negative for spooling, positive for decremental
			local delay = tonumber(ud.customParams.bp_overdrive_chargedelay) -- in frames
			local rechargeRate = tonumber(ud.customParams.bp_overdrive_chargerate) -- in per second.
			local spooling = bonusBP < 0
			if spooling then
				AddEntryToCells(localization.starting_buildpower .. ':', 2, numformat((1 - bonusBP) * buildSpeed), cells)
				AddEntryToCells(localization.buildpower_increases_use, 2, '', cells)
				AddEntryToCells(localization.max_buildpower .. ':', 2, numformat(buildSpeed), cells)
				AddEntryToCells(localization.buildpower_diminishes_with_disuse .. ':', 2, numformat(delay / 30, 1) .. localization.acronyms_second, cells)
				AddEntryToCells(localization.decay_rate .. ':', 2, numformat((rechargeRate / maxCharge) * 100, 1) .. '%/' .. localization.acronyms_second, cells)
			else
				AddEntryToCells(localization.base_buildpower .. ':', 2, numformat(buildSpeed), cells)
				AddEntryToCells(localization.starting_buildpower .. ':', 2, buildSpeed * (1 + bonusBP), cells)
				AddEntryToCells(localization.recharge_delay .. ':', 2, numformat(delay / 30, 1) .. localization.acronyms_second, cells)
				AddEntryToCells(localization.buildpower_regen_rate .. ':', 2, numformat((rechargeRate / maxCharge) * 100, 1) .. '%/' .. localization.acronyms_second, cells)
			end
		else
			AddEntryToCells(localizationCommon.buildpower .. ':', 2, numformat(buildSpeed), cells)
		end
		if ud.canResurrect then
			AddEntryToCells(localization.can_resurrect, 2, '', cells)
		end
		if (#ud.buildOptions == 0) then
			AddEntryToCells(localization.only_assists, 2, '', cells)
		end
		--AddEntryToCells('', 0, '', cells)
	end
	
	if cp.vampirism_kill then
		AddEntryToCells(localization.vampirism, 1, '', cells)
		AddEntryToCells(localization.vampirism_kills_increase_hp .. ":", 2, WG.Translate("interface", "vampirism_kills_increase_hp_desc", {number = numformat(cp.vampirism_kill * 100, 1)}), cells)
	end
	if cp.field_factory then
		AddEntryToCells(localization.field_fac, 1, '', cells)
	end

	if ud.armoredMultiple < 1 then
		AddEntryToCells(localization.armored_unit, 1, '', cells)
		AddEntryToCells(localization.armor_reduction .. ':', 2, numformat((1-ud.armoredMultiple)*100) .. '%', cells)
		if cp.armortype and cp.armortype == '1' then
			AddEntryToCells(localization.armor_type_1, 2, '', cells)
		elseif cp.armortype and cp.armortype == '2' then
			AddEntryToCells(localization.armor_type_2, 2, '', cells)
		end
		if cp.force_close then
			AddEntryToCells(localization.forced_closed .. ":", 2, cp.force_close .. localization.acronyms_second, cells)
		end
		AddEntryToCells('', 0, '', cells)
	end
	local commHasAreaCloak
	if unitID and isFeature then
		commHasAreaCloak = Spring.GetFeatureRulesParam(unitID, "comm_area_cloak") ~= nil
	elseif unitID then
		commHasAreaCloak = Spring.GetUnitRulesParam(unitID, "comm_area_cloak") ~= nil
	end
	if cp.area_cloak or commHasAreaCloak then
		local areaCloakRadius, areaCloakUpkeep
		if unitID and isFeature then
			areaCloakUpkeep = unitID and Spring.GetFeatureRulesParam(unitID, "comm_area_cloak_upkeep")
			areaCloakRadius = unitID and Spring.GetFeatureRulesParam(unitID, "comm_area_cloak_radius")
		elseif unitID then
			areaCloakUpkeep = unitID and Spring.GetUnitRulesParam(unitID, "comm_area_cloak_upkeep")
			areaCloakRadius = unitID and Spring.GetUnitRulesParam(unitID, "comm_area_cloak_radius")
		else
			areaCloakUpkeep = cp.area_cloak_upkeep
			areaCloakRadius = cp.area_cloak_radius
		end
		AddEntryToCells(localization.area_cloak, 1, '', cells)
		AddEntryToCells(localization.upkeep .. ':', 1, areaCloakUpkeep .. " " .. localizationCommon.energy .. "/" .. localization.acronyms_second, cells)
		AddEntryToCells(localization.radius .. ':', 1, areaCloakRadius .. " elmo", cells)
		AddEntryToCells('', 0, '', cells)
	end
	local hasReconPulse = unitID ~= nil
	if hasReconPulse and isFeature then
		hasReconPulse = Spring.GetFeatureRulesParam(unitID, "commander_reconpulse") ~= nil
	elseif hasReconPulse then
		hasReconPulse = Spring.GetUnitRulesParam(unitID, "commander_reconpulse") ~= nil
	end
	if hasReconPulse then
		AddEntryToCells(localization.recon_pulse, 1, '', cells)
		AddEntryToCells(localization.recon_pulse_desc, 1, '', cells)
		AddEntryToCells(localization.recon_pulse_applied, 1, '', cells)
	end
	local canCloak
	if unitID and isFeature then
		canCloak = Spring.GetFeatureRulesParam(unitID, "comm_personal_cloak") ~= nil
	elseif unitID then
		canCloak = Spring.GetUnitRulesParam(unitID, "comm_personal_cloak") ~= nil
	end
	if ud.canCloak and (not unitID or canCloak) then
		local decloakDistance
		if not unitID then
			decloakDistance = ud.decloakDistance
		elseif isFeature then
			decloakDistance = Spring.GetFeatureRulesParam(unitID, "comm_decloak_distance") or ud.decloakDistance
		else
			decloakDistance = Spring.GetUnitRulesParam(unitID, "comm_decloak_distance") or ud.decloakDistance
		end
		AddEntryToCells(localization.personal_cloak, 1, '', cells)
		local extrastring
		if not ud.isImmobile and ud.cloakCost ~= ud.cloakCostMoving and ud.cloakCost > 0 then
			AddEntryToCells(localization.upkeep_mobile .. ':', 2, numformat(ud.cloakCostMoving) .. " " .. localizationCommon.energy .. "/" .. localization.acronyms_second, cells)
			extrastring = localization.upkeep_stationary .. ':'
		else
			extrastring = localization.upkeep .. ':'
		end
		if ud.cloakCost > 0 then
			AddEntryToCells(extrastring, 2, numformat(ud.cloakCost) .. " " .. localizationCommon.energy .. "/" .. localization.acronyms_second, cells)
		else
			AddEntryToCells(extrastring, 2, localization.free, cells)
		end
		AddEntryToCells(localization.decloak_radius .. ':', 2, numformat(decloakDistance) .. " elmo", cells)
		if cp.cloakstrikeduration then
			AddEntryToCells(localization.cloakstrike, 2, '', cells)
			AddEntryToCells(localization.duration .. ':', 3, numformat(cp.cloakstrikeduration/30, 1) .. localization.acronyms_second, cells)
			if ud.decloakOnFire then
				AddEntryToCells(localization.cloakstrike_lose_advantage, 3, '', cells)
			end
		end
		if not ud.decloakOnFire then
			AddEntryToCells(localization.unit_no_decloak_on_fire, 2, '', cells)
		end
	end

	if cp.idle_cloak then
		AddEntryToCells(localization.personal_cloak, 1, '', cells)
		AddEntryToCells(localization.only_idle, 2, '', cells)
		AddEntryToCells(localization.idle_cloak_free, 2, '', cells)
		AddEntryToCells(localization.decloak_radius .. ':', 2, numformat(ud.decloakDistance) .. " elmo", cells)
	end
	if cp.reveal_onprogress then
		AddEntryToCells(WG.Translate("interface", "revealpercent", {percent = numformat(tonumber(cp.reveal_onprogress) * 100, 1)}), 1, '', cells)
	end
	local commcloakregen, commrecloaktime, commjammerrange, commradarrange, nanoregen, nanomax
	if unitID then
		if isFeature then
			commcloakregen = Spring.GetFeatureRulesParam(unitID, "commcloakregen")
			commrecloaktime = Spring.GetFeatureRulesParam(unitID, "commrecloaktime")
			commjammerrange = Spring.GetFeatureRulesParam(unitID, "jammingRangeOverride")
			commradarrange = Spring.GetFeatureRulesParam(unitID, "radarRangeOverride")
			nanoregen = Spring.GetFeatureRulesParam(unitID, "commander_regen")
			nanomax = Spring.GetFeatureRulesParam(unitID, "commander_max")
		else
			commcloakregen = Spring.GetUnitRulesParam(unitID, "commcloakregen")
			commrecloaktime = Spring.GetUnitRulesParam(unitID, "commrecloaktime")
			commjammerrange = Spring.GetUnitRulesParam(unitID, "jammingRangeOverride")
			commradarrange = Spring.GetUnitRulesParam(unitID, "radarRangeOverride")
			nanoregen = Spring.GetUnitRulesParam(unitID, "commander_regen")
			nanomax = Spring.GetUnitRulesParam(unitID, "commander_max")
		end
	end
	nanomax = nanomax or cp.nano_maxregen
	nanoregen = nanoregen or cp.nanoregen
	if cp.cloakregen or commcloakregen then
		local cloakregen = commcloakregen or cp.cloakregen
		AddEntryToCells(localization.cloak_regen .. ":", 2, cloakregen .. localization.acronyms_hp .. "/" .. localization.acronyms_second, cells)
	end
	if cp.recloaktime or commrecloaktime then
		local recloaktime = commrecloaktime or cp.recloaktime
		AddEntryToCells( WG.Translate("interface", "recloaks_after_seconds", {time =  numformat(recloaktime / 30, 1)}), 2, '', cells)
	end
	AddEntryToCells('', 0, '', cells)
	local radarRadius = commradarrange or ud.radarRadius
	local jammerRadius = commjammerrange or ud.jammerRadius
	
	if (radarRadius > 0) or (jammerRadius > 0) or ud.targfac then
		AddEntryToCells(localization.provides_intel, 1, '', cells)
		if (radarRadius > 0) then
			AddEntryToCells(localization.radar .. ':', 2,numformat(radarRadius) .. " elmo", cells)
		end
		if (jammerRadius > 0) then
			AddEntryToCells(localization.jamming .. ':', 2, numformat(jammerRadius) .. " elmo", cells)
		end
		if ud.targfac then
			AddEntryToCells(localization.improves_radar, 2, '', cells)
		end
		AddEntryToCells('', 0, '', cells)
	end

	if cp.canjump and (not cp.no_jump_handling) then
		local rangebonus, reloadbonus = 0, 0
		if unitID then
			if isFeature then
				rangebonus = Spring.GetFeatureRulesParam(unitID, "comm_jumprange_bonus") or 0
				reloadbonus = Spring.GetFeatureRulesParam(unitID, "comm_jumpreload_bonus") or 0
			else
				rangebonus = Spring.GetUnitRulesParam(unitID, "comm_jumprange_bonus") or 0
				reloadbonus = Spring.GetUnitRulesParam(unitID, "comm_jumpreload_bonus") or 0
			end
		end
		rangebonus = rangebonus + 1
		reloadbonus = 1 - reloadbonus
		AddEntryToCells(localization.jump, 1, '', cells)
		AddEntryToCells(localization.stats_range .. ':', 2, numformat(cp.jump_range * rangebonus, 0) .. " elmo", cells)
		AddEntryToCells(localization.stats_reload .. ':', 2, numformat(cp.jump_reload * reloadbonus, 1) .. localization.acronyms_second, cells)
		AddEntryToCells(localization.speed .. ':', 2, numformat(30*tonumber(cp.jump_speed)) .. " elmo/" .. localization.acronyms_second, cells)
		AddEntryToCells(localization.mid_air_jump .. ':', 2, (tonumber(cp.jump_from_midair) == 0) and localization.no or localization.yes, cells)
		AddEntryToCells('', 0, '', cells)
	end

	if cp.morphto then
		AddEntryToCells(localization.morphing, 1, '', cells)
		AddEntryToCells(localization.morphs_to .. ":", 2, Spring.Utilities.GetHumanName(UnitDefNames[cp.morphto]), cells)
		AddEntryToCells(localization.cost .. ':', 2, math.max(0, (UnitDefNames[cp.morphto].buildTime - ud.buildTime)) .. " " .. localizationCommon.metal, cells)
		if cp.morphrank and (tonumber(cp.morphrank) > 0) then
			AddEntryToCells(localization.rank_required .. ':', 2, cp.morphrank, cells)
		end
		AddEntryToCells(localization.morph_time .. ':', 2, cp.morphtime .. localization.acronyms_second, cells)
		if cp.combatmorph == '1' then
			AddEntryToCells(localization.not_disabled_morph, 2, '', cells)
		else
			AddEntryToCells(localization.disabled_morph, 2, '', cells)
		end
		AddEntryToCells('', 0, '', cells)
	end
	
	if (ud.idleTime < 1800) or (cp.amph_regen) or (cp.armored_regen) or (cp.nanoregen) then
		AddEntryToCells(localization.improved_regen, 1, '', cells)
		if ud.idleTime < 1800 then
			if ud.idleTime > 0 then
				AddEntryToCells(localization.idle_regen .. ':', 2, numformat(cp.idle_regen) .. " " .. localization.acronyms_hp .. "/" .. localization.acronyms_second, cells)
				AddEntryToCells(localization.regen_time_to_enable .. ':', 2, numformat(ud.idleTime / 30) .. localization.acronyms_second, cells)
			else
				local dynamic_regen
				if isFeature then
					dynamic_regen = unitID and Spring.GetFeatureRulesParam(unitID, "comm_autorepair_rate") or cp.idle_regen
				else
					dynamic_regen = unitID and Spring.GetUnitRulesParam(unitID, "comm_autorepair_rate") or cp.idle_regen
				end
				AddEntryToCells(localization.constant_regen .. ':', 2, numformat(dynamic_regen) .. " " .. localization.acronyms_hp .. "/" .. localization.acronyms_second, cells)
			end
		end
		if nanoregen then
			local commHP = 0
			if unitID then
				if isFeature then
					commHP = Spring.GetFeatureRulesParam(unitID, "commander_healthbonus") or 0
				else
					commHP = Spring.GetUnitRulesParam(unitID, "commander_healthbonus") or 0
				end
			end
			local hp = ud.health + commHP
			AddEntryToCells(localization.nano_regen .. ":", 2, '', cells)
			AddEntryToCells(localization.base_regen .. ":", 3, nanoregen .. " " .. localization.acronyms_hp .. "/" .. localization.acronyms_second, cells)
			AddEntryToCells(localization.max_regen .. ":", 3, numformat(nanoregen * nanomax, 1) .. " " .. localization.acronyms_hp .. "/" .. localization.acronyms_second, cells)
			AddEntryToCells(localization.max_below .. ":", 3, numformat(hp / nanomax) .. localization.acronyms_hp, cells)
		end
		if cp.amph_regen then
			AddEntryToCells(localization.water_regen .. ':', 2, cp.amph_regen .. localization.acronyms_hp .. "/" .. localization.acronyms_second, cells)
			AddEntryToCells(localization.at_depth .. ':', 2, cp.amph_submerged_at .. " elmo", cells)
		end
		if cp.armored_regen then
			AddEntryToCells(localization.armor_regen .. ':', 2, numformat(tonumber(cp.armored_regen)) .. " " .. localization.acronyms_hp .. "/" .. localization.acronyms_second, cells)
		end
		AddEntryToCells('', 0, '', cells)
	end

	if cp.teleporter then
		AddEntryToCells(localization.teleporter, 1, '', cells)
		AddEntryToCells(localization.spawns_beacon, 2, '', cells)
		AddEntryToCells(localization.spawn_time .. ':', 2, numformat(tonumber(cp.teleporter_beacon_spawn_time), 1) .. localization.acronyms_second, cells)
		AddEntryToCells(localization.teleport_throughput .. ':', 2, numformat(tonumber(cp.teleporter_throughput), 1) .. localization.mass .. "/" .. localization.acronyms_second, cells)
		AddEntryToCells('', 0, '', cells)
	end

	if cp.pad_count then
		local bp = tonumber(cp.pad_bp) or 2.5
		AddEntryToCells(localization.rearm_repair, 1, '', cells)
		AddEntryToCells(localization.rearm_pads .. ':', 2, cp.pad_count, cells)
		AddEntryToCells(localization.pad_bp .. ':', 2, numformat(bp / tonumber(cp.pad_count), 1), cells) -- Future Wars mechanic! Remove the dividend for base game!
		AddEntryToCells('', 0, '', cells)
	end

	if cp.is_drone then
		AddEntryToCells(localization.drone_bound, 1, '', cells)
		if not cp.is_controllable_drone then
			AddEntryToCells(localization.drone_cannot_direct_control, 2, '', cells)
			AddEntryToCells(localization.drone_uses_owners_commands, 2, '', cells)
			AddEntryToCells(localization.drone_bound_to_range, 2, '', cells)
		end
		AddEntryToCells(localization.drone_dies_on_owner_death, 2, '', cells)
		AddEntryToCells('', 0, '', cells)
	end

	if cp.boost_speed_mult then
		AddEntryToCells(localization.speed_boost, 1, '', cells)
		AddEntryToCells(localization.speed .. ':', 2, 'x' .. cp.boost_speed_mult, cells)
		AddEntryToCells(localization.duration .. ':', 2, numformat(tonumber(cp.boost_duration), 1) .. localization.acronyms_second, cells)
		AddEntryToCells(localization.stats_reload .. ':', 2, numformat(tonumber(cp.specialreloadtime)/30, 1) .. localization.acronyms_second, cells)
		AddEntryToCells('', 0, '', cells)
	end

	if cp.windgen then
		local wind_slope = Spring.GetGameRulesParam("WindSlope") or 0
		local max_wind = Spring.GetGameRulesParam("WindMax") or 2.5
		local bonus_100 = numformat(100*wind_slope*max_wind)
		AddEntryToCells(localization.wind_gen, 1, '', cells)
		AddEntryToCells(localization.wind_variable_income, 2, '', cells)
		AddEntryToCells(localization.max_generation, 2, max_wind .. " " .. localizationCommon.energy, cells)
		AddEntryToCells(localization.altitude_bonus, 2, bonus_100 .. " " .. localization.wind_100_height, cells)
		AddEntryToCells('', 0, '', cells)
	end

	if cp.grey_goo then
		AddEntryToCells(localization.grey_goo, 1, '', cells)
		AddEntryToCells(localization.grey_goo_consumption, 2, '', cells)
		AddEntryToCells(localization.stats_spawns .. ':', 2, Spring.Utilities.GetHumanName(UnitDefNames[cp.grey_goo_spawn]), cells)
		AddEntryToCells(localization.rate .. ':', 2, cp.grey_goo_drain .. " " .. localizationCommon.metal .. "/" .. localization.acronyms_second, cells)
		AddEntryToCells(localization.cost .. ':', 2, cp.grey_goo_cost .. " " .. localizationCommon.metal, cells)
		AddEntryToCells('', 0, '', cells)
	end
	if cp.dangerous_reclaim then
		AddEntryToCells(localization.dangerous_reclaim, 1, '', cells)
	end
	if cp.floattoggle then
		AddEntryToCells(localization.floats, 1, '', cells)
		AddEntryToCells(localization.can_move_to_surface, 2, '', cells)
		AddEntryToCells(localization.cannot_move_sideways, 2, '', cells)
		if (cp.sink_on_emp ~= '0') then
			AddEntryToCells(localization.sinks_when_stun, 2, '', cells)
		else
			AddEntryToCells(localization.float_when_stun, 2, '', cells)
		end
	end

	if ud.transportCapacity and (ud.transportCapacity > 0) then
		AddEntryToCells(localization.transportation, 1, '', cells)
		AddEntryToCells(localization.transport_type .. ":", 2, ((ud.customParams.islighttransport) and localization.transport_light or localization.transport_heavy), cells)
		AddEntryToCells(localization.transport_light_speed .. ':', 2, math.floor((tonumber(ud.customParams.transport_speed_light or "1")*100) + 0.5) .. "%", cells)
		if not ud.customParams.islighttransport then
			AddEntryToCells(localization.transport_heavy_speed .. ':', 2, math.floor((tonumber(ud.customParams.transport_speed_heavy or "1")*100) + 0.5) .. "%", cells)
		end
	end

	if ud.customParams.nuke_coverage then
		AddEntryToCells(localization.anti_interception, 1, '', cells)
		AddEntryToCells(localization.stats_range .. ":", 2, ud.customParams.nuke_coverage .. " elmo", cells)
		AddEntryToCells('', 0, '', cells)
	end

	if cp.combat_slowdown then
		AddEntryToCells(localization.combat_slowdown .. ':', 1, numformat(100*tonumber(cp.combat_slowdown)) .. "%", cells)
	end
	local commJammed
	if unitID then
		if isFeature then
			commJammed = Spring.GetFeatureRulesParam(unitID, "comm_jammed") ~= nil
		else
			commJammed = Spring.GetUnitRulesParam(unitID, "comm_jammed") ~= nil
		end
	end
	if ud.stealth or commJammed then
		AddEntryToCells(localization.radar_invisible, 1, '', cells)
	end

	if ud.selfDCountdown <= 1 then
		AddEntryToCells(localization.instant_selfd, 1, '', cells)
	end

	local mexMult = tonumber(cp.metal_extractor_mult)
	if mexMult then
		cells[#cells+1] = 'Extracts metal'
		if differentMexTypeExists and mexMult > 0 then
			cells[#cells+1] = numformat(100*mexMult) .. "% extraction"
		else
			cells[#cells+1] = ''
		end
	end
	if ud.needGeo then
		AddEntryToCells(localization.requires_geo, 1, '', cells)
	end

	if cp.ismex then
		AddEntryToCells(localization.extracts_metal, 1, '', cells)
		AddEntryToCells(localization.shared_to_team, 2, '', cells)
	end
	local isFireproof
	if not unitID then
		isFireproof = cp.fireproof
	elseif isFeature then
		isFireproof = Spring.GetFeatureRulesParam(unitID, "fireproof") or cp.fireproof
	else
		isFireproof = Spring.GetUnitRulesParam(unitID, "fireproof") or cp.fireproof
	end
	
	if isFireproof then
		AddEntryToCells(localization.fireproof, 1, '', cells)
	end
	if cp.singuimmune then
		AddEntryToCells(localization.gravitronic_regulation, 1, '', cells)
	end
	local storageoverride = ud.metalStorage
	if unitID then
		if isFeature then
			storageoverride = Spring.GetFeatureRulesParam(unitID, "commander_storage_override") or ud.metalStorage
		else
			storageoverride = Spring.GetUnitRulesParam(unitID, "commander_storage_override") or ud.metalStorage
		end
	end
	if storageoverride > 0 then
		AddEntryToCells(localization.storage .. ':', 1, math.max(storageoverride, ud.metalStorage), cells)
	end
	
	if (#cells > 2 and cells[#cells-1] == '') then -- clean up last entry
		cells[#cells] = nil
		cells[#cells] = nil
	end

	return cells
end

local function printWeapons(unitDef, unitID, isFeature)
	local weaponStats = {}

	local wd = WeaponDefs
	if not wd then return false end
	
	local ucp = unitDef.customParams
	
	local commweapon1, commweapon2, commshield
	if unitID then
		if isFeature then
			commweapon1 = Spring.GetFeatureRulesParam(unitID, "comm_weapon_num_1")
			commweapon2 = Spring.GetFeatureRulesParam(unitID, "comm_weapon_num_2")
			commshield  = Spring.GetFeatureRulesParam(unitID, "comm_shield_num")
		else
			commweapon1 = Spring.GetUnitRulesParam(unitID, "comm_weapon_num_1")
			commweapon2 = Spring.GetUnitRulesParam(unitID, "comm_weapon_num_2")
			commshield = Spring.GetUnitRulesParam(unitID, "comm_shield_num")
		end
	end
	for i=1, #unitDef.weapons do
		if not unitID or -- filter out commander weapons not in current loadout
		(  i == commweapon1
		or i == commweapon2
		or i == commshield) then
			local weapon = unitDef.weapons[i]
			local weaponID = weapon.weaponDef
			local weaponDef = WeaponDefs[weaponID]

			local aa_only = true
			for cat in pairs(weapon.onlyTargets) do
				if ((cat ~= "fixedwing") and (cat ~= "gunship")) then
					aa_only = false
					break;
				end
			end

			local isDuplicate = false

			for i=1,#weaponStats do
				if weaponStats[i].weaponID == weaponID then
					weaponStats[i].count = weaponStats[i].count + 1
					isDuplicate = true
					break
				end
			end
			
			if (not isDuplicate) and not weaponDef.customParams.fake_weapon then
				local wsTemp = {
					weaponID = weaponID,
					count = 1,
					weaponNum = i,
					
					-- stuff that the weapon gets from the owner unit
					aa_only = aa_only,
					highTrajectory = unitDef.highTrajectoryType,
					free_stockpile = ucp.freestockpile,
					stockpile_time = ucp.stockpiletime,
					stockpile_cost = ucp.stockpilecost,
					firing_arc = weapon.maxAngleDif
				}
				
				-- dual wielding comms
				if (unitID and i == commweapon1 and i == commweapon2) then
					wsTemp.count = 2
				end
				weaponStats[#weaponStats+1] = wsTemp
			end
		end
	end

	local cells = {}

	for index,ws in pairs(weaponStats) do
		--if not ignoreweapon[unitDef.name] or not ignoreweapon[unitDef.name][index] then
		if (index ~= 1) then
			cells[#cells+1] = ''
			cells[#cells+1] = ''
		end
		cells = weapons2Table(cells, ws, unitID, false, {}, false, unitDef.metalCost, isFeature, 0, ws.weaponNum)
		--end
	end
	
	return cells
end

local function slopeDegrees(slope)
	return math.floor(math.deg(math.acos(1 - slope)) + 0.5)
end

local slopeTolerances = {
	VEHICLE = 27,
	BOT = 54,
	SPIDER = 90,
}

-- returns the string, plus optionally the slope if it makes sense to show
local function GetMoveType(ud)
	if ud.isImmobile then
		return localization.movetype_immobile
	elseif ud.isStrafingAirUnit then
		return localization.movetype_plane
	elseif ud.isHoveringAirUnit then
		return localization.movetype_gunship
	end

	local md = ud.moveDef
	if md.isSubmarine then
		return localization.movetype_sub
	end
	
	local smClass = Game.speedModClasses
	if md.smClass == smClass.Ship then --  TODO: Better implementation for FW subfac eventually.
		return localization.movetype_ship
	end

	local slope = slopeDegrees(md.maxSlope)
	if md.smClass == smClass.Hover then
		if slope == slopeTolerances.BOT then
			-- chickens can walk on water!
			return localization.movetype_waterwalker, slope
		else
			return localization.movetype_hover, slope
		end
	elseif md.depth > 1337 then
		return localization.movetype_amph, slope
	elseif slope == slopeTolerances.SPIDER then
		return localization.movetype_spider, slope
	elseif md.smClass == smClass.KBot then
		-- "bot" would sound weird for a chicken, but
		-- all seem to be either amphs or waterwalkers
		return localization.movetype_bot, slope
	else
		return localization.movetype_veh, slope
	end
end



local function GetWeapon(weaponName)
	return WeaponDefNames[weaponName]
end

local function AddEmptyEntry(statschildren)
	statschildren[#statschildren + 1] = Label:New{ caption = '', textColor = color.stats_fg, }
	statschildren[#statschildren + 1] = Label:New{ caption = '', textColor = color.stats_fg, }
end

local function AddEntry(text, layer, entry, color, colorentry, statschildren)
	if text == nil then
		text = ''
	end
	if layer == nil then
		layer = 0
	end
	if layer > 0 then
		text = string.rep("\t\t", layer) .. text
	end
	statschildren[#statschildren + 1] = Label:New{ caption = text, textColor = color, }
	if entry == nil then
		statschildren[#statschildren + 1] = Label:New{ caption = '', textColor = color, }
	else
		statschildren[#statschildren + 1] = Label:New{ caption = entry, textColor = colorentry, }
	end
end

local function printunitinfo(ud, buttonWidth, unitID, isFeature)
	local cp = ud.customParams
	local icons = {
		Image:New{
			file2 = (WG.GetBuildIconFrame)and(WG.GetBuildIconFrame(ud)),
			file = "#" .. ud.id,
			keepAspect = false;
			x = 32,
			y = 0,
			height  = 88*(4/5);
			width   = 88;
		},
	}
	if ud.iconType ~= 'default' then
		icons[#icons + 1] = Image:New{
			file=icontypes and icontypes[(ud and ud.iconType or "default")].bitmap
				or 'icons/'.. ud.iconType ..iconFormat,
			x = 0,
			y = 2,
			height=32,
			width=32,
		}
	end
	
	if behaviourPath[ud.id] then
		icons[#icons + 1] = Button:New{
			x = 2,
			right = 2,
			y = 88*(4/5),
			height = 30,
			caption = localization.edit_behavior,
			tooltip = "Edit the default behaviour of " .. Spring.Utilities.GetHumanName(ud) .. ".",
			OnClick = {function ()
					WG.crude.OpenPathToLabel(behaviourPath[ud.id], true, Spring.Utilities.GetHumanName(ud))
				end,
			}
		}
	end

	local helptextbox = TextBox:New{
		text = Spring.Utilities.GetHelptext(ud),
		textColor = color.stats_fg,
		width = '100%',
		height = '100%',
		padding = { 0, 0, 0, 0 },
		}
	
	local statschildren = {}
	
	local isCommander
	if isFeature then
		isCommander = unitID and Spring.GetFeatureRulesParam(unitID, "comm_level")
	else
		isCommander = (unitID and Spring.GetUnitRulesParam(unitID, "comm_level"))
	end

	local cost = numformat(ud.metalCost)
	local health = numformat(ud.health)
	local rawhealth = ud.health
	local speed = numformat(ud.speed)
	local mass = numformat(ud.mass)
	
	-- stuff for modular commanders
	local legacyModules, legacyCommCost
	if ud.customParams.commtype and not isCommander then	-- old style pregenerated commander (still used in missions etc.)
		legacyModules = WG.ModularCommAPI and WG.ModularCommAPI.GetLegacyModulesForComm(ud.id)
		legacyCommCost = ud.customParams.cost -- or (WG.GetCommUnitInfo and WG.GetCommUnitInfo(ud.id) and WG.GetCommUnitInfo(ud.id).cost)
	end

	-- dynamic comms get special treatment
	if isCommander then
		local level, chassisID, speedMult
		if isFeature then
			cost = Spring.GetFeatureRulesParam(unitID, "comm_cost") or 1200
			health = select(2, Spring.GetFeatureHealth(unitID))
			rawhealth = health
			health = numformat(health)
			speedMult = Spring.GetFeatureRulesParam(unitID, "upgradesSpeedMult") or 1
			mass = numformat(Spring.GetFeatureRulesParam(unitID, "massOverride") or ud.mass)
			level = Spring.GetFeatureRulesParam(unitID, "comm_level") or 0
			chassisID = Spring.GetFeatureRulesParam(unitID, "comm_chassis")
		else
			cost = Spring.GetUnitRulesParam(unitID, "comm_cost") or 1200
			health = select(2, Spring.GetUnitHealth(unitID))
			rawhealth = health
			health = numformat(health)
			speedMult = Spring.GetUnitRulesParam(unitID, "upgradesSpeedMult") or 1
			mass = numformat(Spring.GetUnitRulesParam(unitID, "massOverride") or ud.mass)
			level = Spring.GetUnitRulesParam(unitID, "comm_level") or 0
			chassisID = Spring.GetUnitRulesParam(unitID, "comm_chassis")
		end
		speed =  numformat(ud.speed * speedMult)
		
		
		AddEntry(string.upper(localizationCommon.commander), 0, nil, color.stats_header, nil, statschildren)
		AddEntry(localization.level .. ': ', 1, level + 1, color.stats_fg, color.stats_fg, statschildren)
		AddEntry(localization.chassis .. ': ', 1, chassisDefs[chassisID].humanName, color.stats_fg, color.stats_fg, statschildren)
		AddEmptyEntry(statschildren)
		AddEntry(localization.modules, 0, nil, color.stats_header, nil, statschildren)
		if isFeature then
			local modules = Spring.GetFeatureRulesParam(unitID, "comm_module_count")

			if modules > 0 then -- TODO: Localization
				local module_instances = {}
				for i = 1, modules do
					local moduleID = Spring.GetFeatureRulesParam(unitID, "comm_module_" .. i)
					if moduleID ~= nil then 
						module_instances[moduleID] = (module_instances[moduleID] or 0) + 1
					end
				end
				for moduleID, moduleCount in pairs(module_instances) do
					local moduleStr = moduleDefs[moduleID].humanName
					if moduleCount > 1 then moduleStr = moduleStr .. "  x" .. moduleCount end
					AddEntry(moduleStr, 1, nil, color.stats_fg, nil, statschildren)
				end
			end
		else
			local modules = Spring.GetUnitRulesParam(unitID, "comm_module_count")

			if modules > 0 then
				local module_instances = {}
				for i = 1, modules do
					local moduleID = Spring.GetUnitRulesParam(unitID, "comm_module_" .. i)
					module_instances[moduleID] = (module_instances[moduleID] or 0) + 1
				end
				for moduleID, moduleCount in pairs(module_instances) do
					local moduleStr = moduleDefs[moduleID].humanName
					if moduleCount > 1 then moduleStr = moduleStr .. "  x" .. moduleCount end
					AddEntry(moduleStr, 1, nil, color.stats_fg, nil, statschildren)
				end
			end
		end
		AddEmptyEntry(statschildren)
	end
	if legacyModules then
		AddEmptyEntry(statschildren)
		AddEntry(localization.modules, 0, nil, color.stats_header, nil, statschildren)
		for i=1, #legacyModules do
			AddEntry(legacyModules[i], 1, nil, color.stats_fg, nil, statschildren)
		end
	end

	local costStr = cost .. " " .. localizationCommon.metal
	if (legacyCommCost) then
		costStr = costStr .. "(" .. legacyCommCost .. " " .. localizationCommon.metal .. ")"
	end
	
	AddEntry(localization.stats, 0, nil, color.stats_header, nil, statschildren)
	AddEntry(localization.cost .. ": ", 1, costStr, color.stats_fg, color.stats_fg, statschildren) 
	AddEntry(localizationCommon.health .. ":", 1, health, color.stats_fg, color.stats_fg, statschildren)
	if ud.metalCost > 0 then
		AddEntry(localizationCommon.health .. "/" .. localization.cost .. ':', 1, string.format("%.2f", rawhealth / cost), color.stats_fg, color.stats_fg, statschildren)
	end
	AddEntry(localization.mass .. ":", 1, mass, color.stats_fg, color.stats_fg, statschildren)
	if not ud.isImmobile then
		if cp.cloakstrikespeed then
			local speedup = tonumber(cp.cloakstrikespeed)
			local slowdown = tonumber(cp.cloakstrikeslow)
			AddEntry(localization.cloaked_speed .. ":", 1, speed * speedup .. "elmo/" .. localization.acronyms_second, color.stats_fg, color.stats_fg, statschildren)
			AddEntry(localization.decloaked_speed .. ":", 1, speed * slowdown .. "elmo/" .. localization.acronyms_second, color.stats_fg, color.stats_fg, statschildren)
		else
			AddEntry(localization.speed .. ":", 1, speed .. "elmo/" .. localization.acronyms_second, color.stats_fg, color.stats_fg, statschildren)
		end

		local mt, slope = GetMoveType(ud)
		AddEntry(localization.movement .. ":", 1, mt, color.stats_fg, color.stats_fg, statschildren)
		if slope then
			AddEntry(localization.climbs .. ":", 1, slope .. "°", color.stats_fg, color.stats_fg, statschildren)
		end
	end

	--[[ Enable through some option perhaps
	local gameSpeed2 = Game.gameSpeed * Game.gameSpeed

	if (ud.maxAcc) > 0 then
		statschildren[#statschildren+1] = Label:New{ caption = 'Acceleration: ', textColor = color.stats_fg, }
		statschildren[#statschildren+1] = Label:New{ caption = numformat(ud.maxAcc * gameSpeed2) .. " elmo/s², textColor = color.stats_fg, }
	end
	if (ud.maxDec) > 0 then
		statschildren[#statschildren+1] = Label:New{ caption = 'Brake rate: ', textColor = color.stats_fg, }
		statschildren[#statschildren+1] = Label:New{ caption = numformat(ud.maxDec * gameSpeed2) .. " elmo/s²", textColor = color.stats_fg, }
	end ]]

	local COB_angle_to_degree = 360 / 65536
	if ud.turnRate > 0 then
		AddEntry(localization.turn_rate .. ":", 1, numformat(ud.turnRate * Game.gameSpeed * COB_angle_to_degree) .. "°/" .. localization.acronyms_second, color.stats_fg, color.stats_fg, statschildren)
	end
	local metal, energy
	if isCommander and unitID then
		if isFeature then
			metal = Spring.GetFeatureRulesParam(unitID, "wanted_metalIncome") or 0
			energy = Spring.GetFeatureRulesParam(unitID, "wanted_energyIncome") or 0
		else
			metal = Spring.GetUnitRulesParam(unitID, "wanted_metalIncome") or 0
			energy = Spring.GetUnitRulesParam(unitID, "wanted_energyIncome") or 0
		end
	else
		metal = (ud.metalMake or 0) + (ud.customParams.income_metal or 0)
		energy = (ud.energyMake or 0) - (ud.customParams.upkeep_energy or 0) + (ud.customParams.income_energy or 0)
	end

	if metal ~= 0 then
		AddEntry(localization.metal_income .. ":", 1, (metal > 0 and '+' or '') .. numformat(metal,2) .. " /" .. localization.acronyms_second, color.stats_fg, color.stats_fg, statschildren)
	end

	if energy ~= 0 then
		if ud.customParams and ud.customParams["decay_rate"] then
			energy = energy * (tonumber(ud.customParams["decay_initialrate"]) or 10)
		end
		AddEntry(localization.energy_income .. ":", 1, (energy > 0 and '+' or '') .. numformat(energy,2) .. " /" .. localization.acronyms_second, color.stats_fg, color.stats_fg, statschildren)
		if ud.customParams and ud.customParams["decay_rate"] then
			local baseoutput = ud.customParams.income_energy
			local startperc = tonumber(ud.customParams["decay_initialrate"])
			local decayperc = tonumber(ud.customParams["decay_rate"])
			local decayrate = decayperc * 100
			local mindecay = tonumber(ud.customParams["decay_minoutput"]) or 0
			local decaytime = tonumber(ud.customParams["decay_time"]) or 1
			local txt = ""
			local timetoreach = 0
			if decayrate < 0 then
				txt = localization.output_compounds .. ":"
			else
				txt = localization.output_decays ..":"
			end
			AddEntry(txt, 1, nil, color.stats_fg, nil, statschildren)
			local endperc
			local decays
			if decayrate > 0 then
				AddEntry(localization.rate .. ":", 2, numformat(decayrate, 1) .. "%/" .. numformat(decaytime, 1) .. localization.acronyms_second, color.stats_fg, color.stats_fg, statschildren)
				txt = localization.min_output .. ":"
				endperc = mindecay
				mindecay = mindecay * baseoutput
				decays = true
			else
				AddEntry(localization.rate .. ":", 2, numformat(-decayrate, 1) .. "%/" .. numformat(decaytime, 1) .. localization.acronyms_second, color.stats_fg, color.stats_fg, statschildren)
				txt = localization.max_output .. ":"
				mindecay = tonumber(ud.customParams["decay_maxoutput"]) or 0
				endperc = mindecay
				mindecay = mindecay * baseoutput
				decays = false
			end
			local sim = startperc
			while sim ~= endperc do
				timetoreach = timetoreach + decaytime
				if decayrate < 0 then
					sim = math.min(sim * (1 - decayperc), endperc)
				else
					sim = math.max(sim * (1 - decayperc), endperc)
				end
			end
			local mm = math.floor(timetoreach / 60)
			local ss = timetoreach%60
			timetoreach = string.format("%02d:%02d", mm, ss)
			decayrate = math.abs(decayrate)
			AddEntry(txt, 2, numformat(mindecay, 1), color.stats_fg, color.stats_fg, statschildren)
			AddEntry(localization.time_to_reach .. ":", 2, timetoreach, color.stats_fg, color.stats_fg, statschildren)
		end
	end
	do
		--[[local sonar
		if unitID then
			sonar = Spring.GetUnitRulesParam(unitID, "sonarRangeOverride") or ud.sonarRadius
		else
			sonar = ud.sonarRadius
		end
		if sonar > 0 then
			statschildren[#statschildren+1] = Label:New{ caption = 'Sonar: ', textColor = color.stats_fg, }
			statschildren[#statschildren+1] = Label:New{ caption = numformat(sonar) .. " elmo", textColor = color.stats_fg, }
		end]] -- Irrelevant because Sonar is dead. Add back for basegame.
		local sight
		if unitID then
			if isFeature then
				sight = Spring.GetFeatureRulesParam(unitID, "sightRangeOverride") or ud.losRadius
			else
				sight = Spring.GetUnitRulesParam(unitID, "sightRangeOverride") or ud.losRadius
			end
		else
			sight = ud.losRadius
		end
		AddEntry(localization.sight_range .. ":", 1, numformat(sight) .. " elmo", color.stats_fg, color.stats_fg, statschildren)
	end
	

	if ud.wantedHeight > 0 then
		AddEntry(localization.altitude .. ':', 1, numformat(ud.wantedHeight) .. " elmo", color.stats_fg, color.stats_fg, statschildren)
	end

	if ud.customParams.pylonrange then
		AddEntry(localization.grid_link .. ':', 1, numformat(ud.customParams.pylonrange) .. " elmo", color.stats_fg, color.stats_fg, statschildren)
	end
	if ud.customParams.neededlink then
		AddEntry(localization.grid_needed .. ":", 1, numformat(ud.customParams.neededlink) .. " " .. localizationCommon.energy, color.stats_fg, color.stats_fg, statschildren)
	end

	-- transportability by light or heavy airtrans
	if not (ud.canFly or ud.cantBeTransported) then
		AddEntry(localization.can_be_transported .. ":", 1, ((ud.customParams.requireheavytrans and localization.transport_heavy) or localization.transport_light), color.stats_fg, color.stats_fg, statschildren)
	end
	local name = ud.name

	local function fillOutDroneData(tab, maxDrones, droneBuildSpeed, reloadMult, dronerange)
		local name = Spring.Utilities.GetHumanName(UnitDefs[tab.drone])
		AddEntry(name .. " x" .. (maxDrones or tab.maxDrones), 2, nil, color.stats_header, nil, statschildren)
		AddEntry(localization.drone_build_time .. ":", 3, numformat(tab.buildTime / droneBuildSpeed, 1) .. localization.acronyms_second, color.stats_fg, color.stats_fg, statschildren)
		AddEntry(localization.cooldown .. ":", 3, numformat(tab.reloadTime / reloadMult, 1) .. localization.acronyms_second, color.stats_fg, color.stats_fg, statschildren)
		AddEntry(localization.drones_per_cycle .. ":", 3, tab.spawnSize, color.stats_fg, color.stats_fg, statschildren)
		local range, maxRange = tab.range*dronerange, tab.maxChaseRange*dronerange
		if range >= 100000 then
			AddEntry(localization.drone_verybigrange, 3, 10, color.stats_fg, color.stats_fg, statschildren)
		else
			AddEntry(localization.drone_target_range .. ":", 3,  numformat(range, 0), color.stats_fg, color.stats_fg, statschildren)
			AddEntry(localization.drone_max_range .. ":", 3, numformat(maxRange, 0), color.stats_fg, color.stats_fg, statschildren)
		end
		if tab.controllable then
			AddEntry(localization.drone_controllable, 3, 10, color.stats_fg, color.stats_fg, statschildren)
		end
	end
	
	if isCommander then
		local batDrones, compDrones, droneSlots, droneBuildSpeed, assaultDrones, repairDrones, dronerange, dronemax, reloadMult
		if isFeature then
			batDrones = Spring.GetFeatureRulesParam(unitID, "carrier_count_droneheavyslow")
			compDrones = Spring.GetFeatureRulesParam(unitID, "carrier_count_drone")
			droneBuildSpeed = Spring.GetFeatureRulesParam(unitID, "comm_drone_buildrate") or 1
			droneSlots = Spring.GetFeatureRulesParam(unitID, "comm_extra_drones") or 1
			repairDrones = Spring.GetFeatureRulesParam(unitID, "carrier_count_dronecon")
			assaultDrones = Spring.GetFeatureRulesParam(unitID, "carrier_count_droneassault")
			dronerange = 600 * (Spring.GetFeatureRulesParam(unitID, "comm_drone_range") or 1)
			dronemax = 1250 * (Spring.GetFeatureRulesParam(unitID, "comm_drone_range") or 1)
			reloadMult = Spring.GetFeatureRulesParam(unitID, "comm_drone_rebuildrate") or 1
		else
			batDrones = Spring.GetUnitRulesParam(unitID, "carrier_count_droneheavyslow")
			compDrones = Spring.GetUnitRulesParam(unitID, "carrier_count_drone")
			droneSlots = Spring.GetUnitRulesParam(unitID, "comm_extra_drones") or 1
			repairDrones = Spring.GetUnitRulesParam(unitID, "carrier_count_dronecon")
			assaultDrones = Spring.GetUnitRulesParam(unitID, "carrier_count_droneassault")
			dronemax = 1250 * (Spring.GetUnitRulesParam(unitID, "comm_drone_range") or 1)
			dronerange = 600 * (Spring.GetUnitRulesParam(unitID, "comm_drone_range") or 1)
			droneBuildSpeed = Spring.GetUnitRulesParam(unitID, "comm_drone_buildrate") or 1
			reloadMult = Spring.GetUnitRulesParam(unitID, "comm_drone_rebuildrate") or 1
		end
		local hasDrones = false
		if (batDrones and batDrones > 0) or (compDrones and compDrones > 0) or (assaultDrones and assaultDrones > 0) or (repairDrones and repairDrones > 0) then
			hasDrones = true
			AddEmptyEntry(statschildren)
			AddEntry(string.upper(localization.drone_carrier), 0, nil, color.stats_header, nil, statschildren)
			AddEntry(localization.drone_buildslots .. ":", 1, droneSlots, color.stats_fg, color.stats_fg, statschildren)
			AddEntry(localization.drone_production_speed .. ':', 1, numformat(100*droneBuildSpeed, 2) .. "%", color.stats_fg, color.stats_fg, statschildren)
			AddEmptyEntry(statschildren)
			AddEntry(localization.drone_label .. ":", 1, nil, color.stats_header, nil, statschildren)
			if assaultDrones and assaultDrones > 0 then
				fillOutDroneData(commanderDroneDefs["droneassault"], assaultDrones, droneBuildSpeed, reloadMult, dronerange)
			end
			if compDrones and compDrones > 0 then
				fillOutDroneData(commanderDroneDefs["drone"], compDrones, droneBuildSpeed, reloadMult, dronerange)
			end
			if batDrones and batDrones > 0 then
				fillOutDroneData(commanderDroneDefs["droneheavyslow"], batDrones, droneBuildSpeed, reloadMult, dronerange)
			end
			if repairDrones and repairDrones > 0 then
				fillOutDroneData(commanderDroneDefs["dronecon"], repairDrones, droneBuildSpeed, reloadMult, dronerange)
			end
		end
	elseif carrierDefs[name] then
		AddEmptyEntry(statschildren)
		AddEntry(string.upper(localization.drone_carrier), 0, nil, color.stats_header, nil, statschildren)
		local carrierDef = carrierDefs[name]
		AddEntry(localization.drone_buildslots .. ":", 1, #carrierDef.spawnPieces, color.stats_fg, color.stats_fg, statschildren)
		AddEmptyEntry(statschildren)
		AddEntry(localization.drone_label .. ":", 1, nil, color.stats_header, nil, statschildren)
		for i = 1, #carrierDef do
			local tab = carrierDef[i]
			fillOutDroneData(tab, nil, 1, 1, 1)
		end
	end
	if ud.customParams.reload_move_penalty then
		AddEntry(localization.speed_while_reloading .. ":", 1, numformat(100*tonumber(ud.customParams.reload_move_penalty)) .. "%", color.stats_fg, color.stats_fg, statschildren)
	end

	local cells = printAbilities(ud, isCommander and unitID, isFeature)
	
	if cells and #cells > 2 then
		AddEmptyEntry(statschildren)
		AddEntry(localization.abilities, 0, nil, color.stats_header, nil, statschildren)
		for i=2, #cells, 2 do
			AddEntry(cells[i - 1], 1, cells[i], color.stats_fg, color.stats_fg, statschildren)
		end
	end

	cells = printWeapons(ud, isCommander and unitID, isFeature)
	
	
	if cells and #cells > 0 then
		AddEmptyEntry(statschildren)
		AddEntry(localization.weapons, 0, nil, color.stats_header, nil, statschildren)
		for i = 2, #cells, 2 do
			AddEntry(cells[i - 1], 1, cells[i], color.stats_fg, color.stats_fg, statschildren)
		end
	end

	-- fixme: get a better way to get default buildlist?
	local default_buildlist = UnitDefNames["shieldcon"].buildOptions
	local this_buildlist = ud.buildOptions
	if ((#this_buildlist ~= #default_buildlist) and (#this_buildlist > 0)) then
		AddEmptyEntry(statschildren)
		AddEntry(localization.builds, 0, nil, color.stats_header, nil, statschildren)
		for i=1, #this_buildlist do
			AddEntry(Spring.Utilities.GetHumanName(UnitDefs[this_buildlist[i]]), 1, nil, color.stats_fg, nil, statschildren)
			-- desc. would be nice, but there is horizontal cutoff
			-- and long names can overlap (eg. Adv Radar)
			-- statschildren[#statschildren+1] = Label:New{ caption = UnitDefs[this_buildlist[i]].tooltip, textColor = colorDisarm,}
		end
	end

	-- death explosion
	if ud.canKamikaze or ud.customParams.stats_show_death_explosion then
		AddEmptyEntry(statschildren)
		AddEntry(string.upper(localization.death_explosion), 0, nil, color.stats_header, color.stats_fg, statschildren)
		
		--[[
		local weaponStats = GetWeapon( ud.deathExplosion:lower() )
		local wepCp = weaponStats.customParams
		local damageValue = tonumber(weaponStats.customParams.stats_damage)

		statschildren[#statschildren+1] = Label:New{ caption = 'Damage: ', textColor = color.stats_fg, }
		if (weaponStats.paralyzer) then
			statschildren[#statschildren+1] = Label:New{ caption = numformat(damageValue,2) .. " (P)", textColor = colorCyan, }
			statschildren[#statschildren+1] = Label:New{ caption = 'Max EMP time: ', textColor = color.stats_fg, }
			statschildren[#statschildren+1] = Label:New{ caption = numformat(weaponStats.damages.paralyzeDamageTime,2) .. "s", textColor = color.stats_fg, }
		else
			local damageSlow = (wepCp.timeslow_damagefactor or 0)*damageValue
			local damageText
			if damageSlow > 0 then
				if wepCp.timeslow_onlyslow == "1" then
					 damageText = color2incolor(colorPurple) .. numformat(damageSlow,2) .. " (S)\008"
				else
					damageText = numformat(damageValue,2) .. " + " .. color2incolor(colorPurple) .. numformat(damageSlow,2) .. " (S)\008"
				end
			else
				damageText = numformat(damageValue,2)
			end
			statschildren[#statschildren+1] = Label:New{ caption = damageText, textColor = color.stats_fg, }
		end

		statschildren[#statschildren+1] = Label:New{ caption = 'AoE radius: ', textColor = color.stats_fg, }
		statschildren[#statschildren+1] = Label:New{ caption = numformat(weaponStats.damageAreaOfEffect,2) .. " elmo", textColor = color.stats_fg, }
		
		if (weaponStats.customParams.setunitsonfire) then
			statschildren[#statschildren+1] = Label:New{ caption = 'Afterburn: ', textColor = color.stats_fg, }
			statschildren[#statschildren+1] = Label:New{ caption = numformat((weaponStats.customParams.burntime or 450)/30) .. "s (15 DPS)", textColor = colorFire, }
		end

		-- statschildren[#statschildren+1] = Label:New{ caption = 'Edge Damage: ', textColor = color.stats_fg, }
		-- statschildren[#statschildren+1] = Label:New{ caption = numformat(damageValue * weaponStats.edgeEffectiveness,2), textColor = color.stats_fg, }
		-- edge damage is always 0, see http://springrts.com/mediawiki/images/1/1c/EdgeEffectiveness.png
		]]--
		
		local cells = weapons2Table({}, ud.deathExplosion:lower(), unitID, 1, {}, true, ud.metalCost)
		
		if cells and #cells > 0 then
			for i=2, #cells, 2 do
				AddEntry(cells[i - 1], 1, cells[i], color.stats_fg, color.stats_fg, statschildren)
			end
		end
	end

	--adding this because of annoying  cutoff
	AddEmptyEntry(statschildren)
	AddEmptyEntry(statschildren)
	
	
	local stack_icons = Chili.Control:New{
		y = 3,
		right = 1,
		height = 200,
		width = 120,
		padding = {0,0,0,0},
		itemMargin = {0,4,0,4},
		children = icons,
	}
	
	local stack_stats = Grid:New{
		columns=2,
		autoArrangeV  = false,
		--height = (#statschildren/2)*statschildren[1].height,
		height = (#statschildren/2)*15,
		
		width = '100%',
		children = statschildren,
		y = 1,
		padding = {1,1,1,1},
		itemPadding = {1,1,1,1},
		itemMargin = {1,1,1,1},
	}
	
	local helptext_stack = StackPanel:New{
		orientation = 'vertical',
		autoArrangeV  = false,
		autoArrangeH  = false,
		centerItems  = false,
		right = 128,
		x = 0,
		--width = 200,
		--height = '100%',
		autosize=true,
		resizeItems = false,
		children = { helptextbox, stack_stats, },
	}
	return {
		helptext_stack,
		stack_icons,
	}
end

local function tooltipBreakdown(tooltip)
	local unitname = nil

	if tooltip:find('Build', 1, true) == 1 then
		local name = string.sub(tooltip, ((tooltip:find('BuildUnit', 1, true) == 1) and 10) or 6)
		local ud = name and UnitDefNames[name]
		return ud or false
	elseif tooltip:find('Morph', 1, true) == 1 then
		local unitDefID = tooltip:match('(%d+)')
		local udef = UnitDefs[tonumber(unitDefID)]
		return udef or false
	elseif tooltip:find('Selected', 1, true) == 1 then
		local start,fin = tooltip:find([[ - ]], 1, true)
		if start and fin then
			local unitHumanName = tooltip:sub(11,start-1)
			local udef = GetUnitDefByHumanName(unitHumanName)
			return udef or false
		end
	end
	
	return false
end

----------------------------------------------------------------

local function hideWindow(window)
	if not window then return end
	window:SetPos(-1000, -1000)
	window.visible = false
end
--[[
local function showWindow(window, x, y)
	window.visible = true
	if x then
		window:SetPos(x,y)
	end
end
--]]
local function KillStatsWindow(num)
	statswindows[num]:Dispose()
	statswindows[num] = nil
end

MakeStatsWindow = function(ud, x,y, unitID, isFeature)
	hideWindow(window_unitcontext)
	local x = x
	local y = y
	if x then
		y = scrH-y
	else
		x = scrH / 3
		y = scrH / 3
	end
	
	
	if not options.window_to_cursor.value then
		x = options.window_pos_x.value
		y = options.window_pos_y.value
	end

	local num = #statswindows+1
	local children = {
		ScrollPanel:New{
			--horizontalScrollbar = false,
			x=5,y=15,
			right = 5,
			bottom = B_HEIGHT + 10,
			padding = {2,2,2,2},
			children = printunitinfo(ud, window_width, unitID, isFeature),
		},
		Button:New{
			caption = localization.menu_close,
			OnClick = { function(self) KillStatsWindow(num) end },
			
			x=5,
			height=B_HEIGHT,
			right=5,
			bottom=5,
			
			--backgroundColor=color.sub_back_bg,
			--textColor=color.sub_back_fg,
			--classname = "back_button",
		}
	}
	if isFeature then
		statswindows[num] = Window:New{
			x = x,
			y = y,
			width  = WINDOW_WIDTH,
			height = options.window_height.value,
			resizable = true,
			parent = screen0,
			backgroundColor = color.stats_bg,
			classname = "main_window_small",
			
			minWidth = 250,
			minHeight = 300,
			
			caption = Spring.Utilities.GetFeatureName(ud, unitID) ..' - '.. Spring.Utilities.GetFeatureDescription(ud, unitID),
			
			children = children,
		}
	else
		statswindows[num] = Window:New{
			x = x,
			y = y,
			width  = WINDOW_WIDTH,
			height = options.window_height.value,
			resizable = true,
			parent = screen0,
			backgroundColor = color.stats_bg,
			classname = "main_window_small",
			
			minWidth = 250,
			minHeight = 300,
			
			caption = Spring.Utilities.GetHumanName(ud, unitID) ..' - '.. Spring.Utilities.GetDescription(ud, unitID),
			
			children = children,
		}
	end
	AdjustWindow(statswindows[num])
end

local function PriceWindow(unitID, action) -- Bitrotted?
	local window_width = 250
	
	local header = 'Offer For Sale'
	local command = '$sell'
	local cancelText = 'Cancel Sale'
	if action == 'buy' then
		header = 'Offer To Buy'
		command = '$buy'
		cancelText = 'Cancel Offer'
	elseif action == 'bounty' then
		header = 'Place Bounty (5 Minutes - Cannot cancel!)'
		command = '$bounty'
	end
	
	local children = {}
	children[#children+1] = Label:New{ caption = header, width=window_width, height=B_HEIGHT, textColor = color.context_header,}
	
	local grid_children = {}
	
	local dollar_amounts = {50,100,200,500,1000,2000,5000,10000, 0}
	for i=1, #dollar_amounts do
		local dollar_amount = dollar_amounts[i]
		local caption, func
		if action == 'bounty' then
			if dollar_amount ~= 0 then
				caption = '$' .. dollar_amount
				func = function() spSendLuaRulesMsg(  command .. '|' .. unitID .. '|' .. dollar_amount ) end
			end
		else
			caption = dollar_amount == 0 and cancelText or '$' .. dollar_amount
			func = function() spSendLuaRulesMsg(  command .. '|' .. unitID .. '|' .. dollar_amount) end
		end
		if caption then
			grid_children[#grid_children+1] = Button:New{
				caption = caption,
				OnClick = { func, CloseButtonFunc2 },
				width=window_width,
				height=B_HEIGHT,
				--backgroundColor=color.sub_back_bg,
				--textColor=color.sub_back_fg,
				--classname = "back_button",
			}
		end
	end
	--local grid_height = (B_HEIGHT)* #grid_children /3
	local grid_height = (B_HEIGHT)* 3
	local price_grid = Grid:New{
		--rows = 3,
		columns = 3,
		resizeItems=true,
		width = window_width,
		height = grid_height,
		padding = {0,0,0,0},
		itemPadding = {2,2,2,2},
		itemMargin = {0,0,0,0},
		
		children = grid_children,
	}
	
	children[#children+1] = price_grid
	
	children[#children+1] = Label:New{ caption = '', width=window_width, height=B_HEIGHT, autosize=false,}

	children[#children+1] =  CloseButton(window_width)
	
	local window_height = (B_HEIGHT) * (#children-1) + grid_height
		
	local stack1 = StackPanel:New{
		centerItems = false,
		resizeItems=false,
		width = window_width,
		height = window_height,
		padding = {0,0,0,0},
		itemPadding = {2,2,2,2},
		itemMargin = {0,0,0,0},
		children = children,
	}
	
	local window = Window:New{
		x = scrW/2,
		y = scrH/2,
		clientWidth  = window_width,
		clientHeight = window_height,
		resizable = false,
		parent = screen0,
		backgroundColor = color.context_bg,
		children = {stack1},
	}
end

local function MakeUnitContextMenu(unitID,x,y)
	local udid 			= spGetUnitDefID(unitID)
	local ud 			= UnitDefs[udid]
	if not ud then return end
	local alliance 		= spGetUnitAllyTeam(unitID)
	local team			= spGetUnitTeam(unitID)
	local _, player 	= spGetTeamInfo(team, false)
	local playerName 	= spGetPlayerInfo(player, false) or 'noname'
	local teamColor 	= {spGetTeamColor(team)}
		
	local window_width = 350
	--local buttonWidth = window_width - 0

	local children = {
		Label:New{ caption = Spring.Utilities.GetHumanName(ud) ..' - '.. Spring.Utilities.GetDescription(ud), width=window_width, textColor = color.context_header,},
		Label:New{ caption = localizationCommon.player .. ': ' .. playerName, width=window_width, textColor=teamColor },
		Label:New{ caption = localization.alliance ..' - ' .. alliance .. '    ' .. localization.team .. ' - ' .. team, width=window_width ,textColor = color.context_fg,},
		
		Button:New{
			caption = localization.unit_info,
			OnClick = { function() MakeStatsWindow(ud,x,y) end },
			width=window_width,
			--backgroundColor=color.sub_back_bg,
			--textColor=color.sub_back_fg,
			--classname = "back_button",
		},
	}
	local y = scrH-y
	local x = x
	
	if marketandbounty then -- NOT LOCALIZED: Bitrot / Removed?
		if team == myTeamID then
			children[#children+1] =  Button:New{
				caption = 'Set Sale Price',
				OnClick = { function(self) PriceWindow(unitID, 'sell') end },
				width=window_width,
				--backgroundColor=color.sub_back_bg,
				--textColor=color.sub_back_fg,
				--classname = "back_button",
			}
		else
			children[#children+1] =  Button:New{
				caption = 'Offer To Buy',
				OnClick = { function(self) PriceWindow(unitID, 'buy') end },
				width=window_width,
				--backgroundColor=color.sub_back_bg,
				--textColor=color.sub_back_fg,
				--classname = "back_button",
			}
		end
		if myAlliance ~= alliance then
			children[#children+1] =  Button:New{
				caption = 'Place Bounty',
				OnClick = { function(self) PriceWindow(unitID, 'bounty') end },
				width=window_width,
				--backgroundColor=color.sub_back_bg,
				--textColor=color.sub_back_fg,
				--classname = "back_button",
			}
		end
	end

	
	if ceasefires and myAlliance ~= alliance then -- DITTO.
		--window_height = window_height + B_HEIGHT*2 --error no such window_height!
		children[#children+1] = Button:New{ caption = 'Vote for ceasefire', OnClick = { function() spSendLuaRulesMsg('cf:y'..alliance) end }, width=window_width}
		children[#children+1] = Button:New{ caption = 'Break ceasefire/unvote', OnClick = { function() spSendLuaRulesMsg('cf:n'..alliance) spSendLuaRulesMsg('cf:b'..alliance) end }, width=window_width}
	end
	children[#children+1] = CloseButton()
	
	local window_height = (B_HEIGHT)* #children
	
	if window_unitcontext then
		window_unitcontext:Dispose()
	end
	local stack1 = StackPanel:New{
		centerItems = false,
		--autoArrangeV = true,
		--autoArrangeH = true,
		resizeItems=true,
		width = window_width,
		height = window_height,
		padding = {0,0,0,0},
		itemPadding = {2,2,2,2},
		itemMargin = {0,0,0,0},
		children = children,
	}
	
	window_unitcontext = Window:New{
		x = x,
		y = y,
		clientWidth  = window_width,
		clientHeight = window_height,
		classname = "main_window_small",
		resizable = false,
		parent = screen0,
		backgroundColor = color.context_bg,
		children = {stack1},
	}
	AdjustWindow(window_unitcontext)
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:MousePress(x,y,button)
	
	if button ~= 1 then return end
	
	local alt, ctrl, meta, shift = spGetModKeyState()
	
	if meta then
		----------
		local groundTooltip
		if WG.customToolTip then --find any custom ground tooltip placed on the ground
			local _, pos = spTraceScreenRay(x,y, true, false, false, true) --return coordinate of the ground
			for _, data in pairs(WG.customToolTip) do --iterate over WG.customToolTip
				if data.box and pos and (pos[1]>= data.box.x1 and pos[1]<= data.box.x2) and (pos[3]>= data.box.z1 and pos[3]<= data.box.z2) then --check if within box side x & check if within box side z
					groundTooltip = data.tooltip --copy tooltip
					break
				end
			end
		end
		----------
		local cur_ttstr = screen0.currentTooltip or groundTooltip or spGetCurrentTooltip()
		local ud = tooltipBreakdown(cur_ttstr)
		
		local _,cmd_id = Spring.GetActiveCommand()
		
		if cmd_id then
			return false
		end

		if ud then
			MakeStatsWindow(ud,x,y)
			return true
		end
		
		local type, data = spTraceScreenRay(x, y, false, false, false, true)
		if (type == 'unit') then
			local unitID = data
			
			if marketandbounty then
				MakeUnitContextMenu(unitID,x,y)
				return
			end
			
			local udid = UnitDefs[Spring.GetUnitDefID(unitID)]
			
			if udid then
				MakeStatsWindow(udid,x, y, unitID, false)
			end
			-- FIXME enable later when does not show useless info
			return true
		elseif (type == 'feature') then
			local fdid = Spring.GetFeatureDefID(data)
			local fd = fdid and FeatureDefs[fdid]
			local feature_name = fd and fd.name
			if feature_name then
				
				local live_name
				if fd and fd.customParams and fd.customParams.unit then
					live_name = fd.customParams.unit
				else
					live_name = feature_name:gsub('([^_]*).*', '%1')
				end
				
				local ud = UnitDefNames[live_name]
				if ud then
					MakeStatsWindow(ud, x, y, data, true)
					return true
				end
			end
		end
	end

	--[[
	if window_unitcontext and window_unitcontext.visible and (not screen0.hoveredControl or not screen0.hoveredControl:IsDescendantOf(window_unitcontext)) then
		hideWindow(window_unitcontext)
		return true
	end
	--]]
end

function widget:ViewResize(vsx, vsy)
	scrW = vsx
	scrH = vsy
end


function widget:Initialize()
	if (not WG.Chili) then
		widgetHandler:RemoveWidget(widget)
		return
	end
	-- setup Chili
	Chili = WG.Chili
	Button = Chili.Button
	Label = Chili.Label
	Window = Chili.Window
	ScrollPanel = Chili.ScrollPanel
	StackPanel = Chili.StackPanel
	Grid = Chili.Grid
	TextBox = Chili.TextBox
	Image = Chili.Image
	screen0 = Chili.Screen0
	color2incolor = Chili.color2incolor
	widget:ViewResize(Spring.GetViewGeometry())
	WG.MakeStatsWindow = MakeStatsWindow
	WG.InitializeTranslation(UpdateLocalization, GetInfo().name)
end

function widget:Shutdown()
end
