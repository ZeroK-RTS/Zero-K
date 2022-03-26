--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
  return {
    name      = "Unit Start State",
    desc      = "Configurable starting unit states for units",
    author    = "GoogleFrog",
    date      = "13 April 2011", --last update: 29 January 2014
    license   = "GNU GPL, v2 or later",
	handler   = false,
    layer     = 1,
    enabled   = true,  --  loaded by default?
  }
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

VFS.Include("LuaRules/Configs/customcmds.h.lua")

local overkillPrevention, overkillPreventionBlackHole = include("LuaRules/Configs/overkill_prevention_defs.lua")
local baitPreventionDefault = include("LuaRules/Configs/bait_prevention_defs.lua")
local alwaysHoldPos, holdPosException, dontFireAtRadarUnits, factoryDefs = VFS.Include("LuaUI/Configs/unit_state_defaults.lua")
local defaultSelectionRank = VFS.Include(LUAUI_DIRNAME .. "Configs/selection_rank.lua")
local spectatingState = select(1, Spring.GetSpectatingState())

local unitsToFactory = {} -- [unitDefName] = factoryDefName

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local preventBaitTip = "\nAvoidance is disabled for units with Force Fire (only for the target), Attack Move or Patrol commands."
local badTargetDescStr = "\n\nAvoid Bad Targets prevents auto-aim at low value targets. It is disabled for units with Force Fire (only for the target), Attack Move or Patrol commands. The lowest level avoids armoured targets (excluding Crab) while levels Light to Heavy ignore unidentified radar dots."


local tooltipFunc = {}
local tooltips = {
	movestate = {
		[-1] = "Inherit from factory",
		[0] = "Hold position",
		[1] = "Maneuver",
		[2] = "Roam",
	},
	firestate = {
		[-1] = "Inherit from factory",
		[0] = "Hold fire",
		[1] = "Return fire",
		[2] = "Fire at will",
	},
	priority = {
		[-1] = "Inherit from factory",
		[0] = "Low priority",
		[1] = "Normal priority",
		[2] = "High priority",
	},
	retreat = {
		[-1] = "Inherit from factory",
		[0] = "Never Retreat",
		[1] = "Retreat at 30% health",
		[2] = "Retreat at 65% health",
		[3] = "Retreat at 99% health",
	},
	auto_call_transport = {
		[-1] = "Inherit from factory",
		[0] = "Disabled",
		[1] = "Enabled",
	},
	flylandstate = {
		[-1] = "Inherit from factory",
		[0] = "Fly when idle",
		[1] = "Land when idle",
	},
	floatstate = {
		[-1] = "Inherit from factory",
		[0] = "Never float",
		[1] = "Float to attack",
		[2] = "Float to attack or when idle",
	},
	goostate = {
		[0] = "Never gather",
		[1] = "Gather when not cloaked",
		[2] = "Always Gather",
	},
	selectionrank = {
		[0] = "0",
		[1] = "1",
		[2] = "2",
		[3] = "3",
	},
	formationrank = {
		[0] = "0",
		[1] = "1",
		[2] = "2",
		[3] = "3",
	},
	prevent_bait = {
		[0] = "Disable target avoidance.",
		[1] = "Avoid shooting at light drones, Wind, Solar, Claw, Dirtbag, low value nanoframes and armoured targets (excluding Crab)." .. preventBaitTip,
		[2] = "Avoid shooting at units costing less than 90, Razor, Sparrow, unknown radar dots, low value nanoframes and armoured targets (except Crab)." .. preventBaitTip,
		[3] = "Avoid shooting at units costing less than 240 (excluding Stardust) as well as, Raptor, unknown radar dots, low value nanoframes and armoured targets (excluding Crab). Disables Ward Fire." .. preventBaitTip,
		[4] = "Avoid shooting at  units costing less than 420, unknown radar dots, low value nanoframes and armoured targets (excluding Crab). Disables Ward Fire." .. preventBaitTip,
	},
	fire_at_shield = {
		[0] = "Disabled.",
		[1] = "Shoot at the shields of Thugs, Felons and Convicts when nothing else is in range.",
	},
	fire_towards_enemy = {
		[0] = "Disabled.",
		[1] = "Shoot towards the closest enemy when nothing else is in range.",
	},
}

for name, values in pairs(tooltips) do
	tooltipFunc[name] = function (_, v)
		return values[v] or "??"
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local function IsGround(ud)
	return not ud.canFly
end

local function IsFactory(ud)
	return ud.customParams.factorytab or ud.customParams.child_of_factory
end

local impulseUnitDefID = {}
for i = 1, #UnitDefs do
	local ud = UnitDefs[i]
	for _, w in pairs(ud.weapons) do
		local wd = WeaponDefs[w.weaponDef]
		if wd.customParams and wd.customParams.impulse then
			impulseUnitDefID[i] = true
			break
		end
	end
end

options_path = 'Settings/Unit Behaviour/Default States'
options_order = {
	'inheritcontrol', 'presetlabel',
	'resetMoveStates', 'holdPosition',
	'skirmHoldPosition', 'artyHoldPosition', 'aaHoldPosition',
	'enableTacticalAI', 'disableTacticalAI',
	'preventBaitOff', 'preventBaitDefault', 'preventBaitMinOne', 'preventBaitPlusOne',
	'enableAutoAssist', 'disableAutoAssist',
	'enableAutoCallTransport', 'disableAutoCallTransport',
	'setRanksToDefault', 'setRanksToThree',
	'setFactoryRanksToThree', 'setFactoryRanksToTwo',
	'categorieslabel',
	'commander_label',
	'commander_firestate0',
	'commander_movestate1',
	'commander_constructor_buildpriority',
	'commander_misc_priority',
	'commander_retreat',
	'commander_auto_call_transport_2',
	'commander_selection_rank',
	'commander_formation_rank',
}

options = {
	inheritcontrol = {
		name = "Inherit Factory Control Group",
		type = 'bool',
		value = false,
		path = "Settings/Interface/Control Groups",
	},

	presetlabel = {name = "presetlabel", type = 'label', value = "Presets", path = options_path},

	resetMoveStates = {
		type = 'button',
		name = "Clear Move States",
		desc = "Set all land units to inherit their move state from factory (overrides holdpos for skirms, arty and AA but not Crab, Fencer or Tremor)",
		path = "Settings/Unit Behaviour/Default States/Presets",
		OnChange = function ()
			for i = 1, #options_order do
				local opt = options_order[i]
				local find = string.find(opt, "_movestate1")
				local name = find and string.sub(opt,0,find-1)
				local ud = name and UnitDefNames[name]
				if ud and not alwaysHoldPos[ud.id] and IsGround(ud) then
					options[opt].value = -1
				end
			end
		end,
	},

	holdPosition = {
		type = 'button',
		name = "Hold Position",
		desc = "Set all land units to hold position",
		path = "Settings/Unit Behaviour/Default States/Presets",
		OnChange = function ()
			for i = 1, #options_order do
				local opt = options_order[i]
				local find = string.find(opt, "_movestate1")
				local name = find and string.sub(opt,0,find-1)
				local ud = name and UnitDefNames[name]
				if ud and not holdPosException[ud.id] and IsGround(ud) then
					options[opt].value = 0
				end
			end
		end,
	},

	skirmHoldPosition = {
		type = 'button',
		name = "Hold Position (Skirmishers)",
		desc = "Set all skirmishers to hold position",
		path = "Settings/Unit Behaviour/Default States/Presets",
		OnChange = function ()
			for i = 1, #options_order do
				local opt = options_order[i]
				local find = string.find(opt, "_movestate1")
				local name = find and string.sub(opt,0,find-1)
				local ud = name and UnitDefNames[name]
				if ud and (string.match(ud.tooltip, 'Skirm') or string.match(ud.tooltip, 'Capture') or string.match(ud.tooltip, 'Black Hole')) and IsGround(ud) then
					options[opt].value = 0
				end
			end
		end,
	},

	artyHoldPosition = {
		type = 'button',
		name = "Hold Position (Artillery)",
		desc = "Set all artillery units to hold position",
		path = "Settings/Unit Behaviour/Default States/Presets",
		OnChange = function ()
			for i = 1, #options_order do
				local opt = options_order[i]
				local find = string.find(opt, "_movestate1")
				local name = find and string.sub(opt,0,find-1)
				local ud = name and UnitDefNames[name]
				if ud and string.match(ud.tooltip, 'Arti') and IsGround(ud) then
					options[opt].value = 0
				end
			end
		end,
	},

	aaHoldPosition = {
		type = 'button',
		name = "Hold Position (Anti-Air)",
		desc = "Set all non-flying anti-air units to hold position",
		path = "Settings/Unit Behaviour/Default States/Presets",
		OnChange = function ()
			for i = 1, #options_order do
				local opt = options_order[i]
				local find = string.find(opt, "_movestate1")
				local name = find and string.sub(opt,0,find-1)
				local ud = name and UnitDefNames[name]
				if ud and string.match(ud.tooltip, 'Anti') and string.match(ud.tooltip, 'Air') and IsGround(ud) then
					options[opt].value = 0
				end
			end
		end,
	},

	categorieslabel = {name = "presetlabel", type = 'label', value = "Categories", path = options_path},

	disableTacticalAI = {
		type = 'button',
		name = "Disable Tactical AI",
		desc = "Disables tactical AI (jinking and skirming) for all units.",
		path = "Settings/Unit Behaviour/Default States/Presets",
		OnChange = function ()
			for i = 1, #options_order do
				local opt = options_order[i]
				local find = string.find(opt, "_tactical_ai_2")
				local name = find and string.sub(opt,0,find-1)
				local ud = name and UnitDefNames[name]
				if ud then
					options[opt].value = false
				end
			end
		end,
	},

	enableTacticalAI = {
		type = 'button',
		name = "Enable Tactical AI",
		desc = "Enables tactical AI (jinking and skirming) for all units.",
		path = "Settings/Unit Behaviour/Default States/Presets",
		OnChange = function ()
			for i = 1, #options_order do
				local opt = options_order[i]
				local find = string.find(opt, "_tactical_ai_2")
				local name = find and string.sub(opt,0,find-1)
				local ud = name and UnitDefNames[name]
				if ud then
					options[opt].value = true
				end
			end
		end,
	},
	preventBaitOff = {
		type = 'button',
		name = "Disable Avoid Bad Targets",
		desc = "Disable low value target avoidance for all units." .. badTargetDescStr,
		path = "Settings/Unit Behaviour/Default States/Presets",
		OnChange = function ()
			for i = 1, #options_order do
				local opt = options_order[i]
				local find = string.find(opt, "_prevent_bait")
				local name = find and string.sub(opt,0,find-1)
				local ud = name and UnitDefNames[name]
				if ud then
					options[opt].value = 0
				end
			end
		end,
	},
	preventBaitDefault = {
		type = 'button',
		name = "Default Avoid Bad Targets",
		desc = "Set low value target avoidance back to the default. This causes some units with costly or high reload shots to ignore targets at the 40 or 100 threshold." .. badTargetDescStr,
		path = "Settings/Unit Behaviour/Default States/Presets",
		OnChange = function ()
			for i = 1, #options_order do
				local opt = options_order[i]
				local find = string.find(opt, "_prevent_bait")
				local name = find and string.sub(opt,0,find-1)
				local ud = name and UnitDefNames[name]
				if ud then
					options[opt].value = baitPreventionDefault[ud.id]
				end
			end
		end,
	},
	preventBaitMinOne = {
		type = 'button',
		name = "Set min Avoid Bad Targets",
		desc = "Set low value target avoidance to a cost threshold of 40 if the default is not higher." .. badTargetDescStr,
		path = "Settings/Unit Behaviour/Default States/Presets",
		OnChange = function ()
			for i = 1, #options_order do
				local opt = options_order[i]
				local find = string.find(opt, "_prevent_bait")
				local name = find and string.sub(opt,0,find-1)
				local ud = name and UnitDefNames[name]
				if ud then
					options[opt].value = math.max(1, baitPreventionDefault[ud.id])
				end
			end
		end,
	},
	preventBaitPlusOne = {
		type = 'button',
		name = "Set high Avoid Bad Targets",
		desc = "Set low value target avoidance to one higher than the default for all units." .. badTargetDescStr,
		path = "Settings/Unit Behaviour/Default States/Presets",
		OnChange = function ()
			for i = 1, #options_order do
				local opt = options_order[i]
				local find = string.find(opt, "_prevent_bait")
				local name = find and string.sub(opt,0,find-1)
				local ud = name and UnitDefNames[name]
				if ud then
					options[opt].value = baitPreventionDefault[ud.id] + 1
				end
			end
		end,
	},
	
	enableAutoAssist = {
		type = 'button',
		name = "Enable Auto Assist",
		desc = "Enables auto assist for all factories.",
		path = "Settings/Unit Behaviour/Default States/Presets",
		OnChange = function ()
			for i = 1, #options_order do
				local opt = options_order[i]
				local find = string.find(opt, "_auto_assist")
				local name = find and string.sub(opt,0,find-1)
				local ud = name and UnitDefNames[name]
				if ud then
					options[opt].value = true
				end
			end
		end,
	},
	disableAutoAssist = {
		type = 'button',
		name = "Disable Auto Assist",
		desc = "Disables auto assist for all factories.",
		path = "Settings/Unit Behaviour/Default States/Presets",
		OnChange = function ()
			for i = 1, #options_order do
				local opt = options_order[i]
				local find = string.find(opt, "_auto_assist")
				local name = find and string.sub(opt,0,find-1)
				local ud = name and UnitDefNames[name]
				if ud then
					options[opt].value = false
				end
			end
		end,
	},
	
	enableAutoCallTransport = {
		type = 'button',
		name = "Enable Auto Call Transport",
		desc = "Enables auto call transport for all factories, sets constructors to inherit.",
		path = "Settings/Unit Behaviour/Default States/Presets",
		OnChange = function ()
			for i = 1, #options_order do
				local opt = options_order[i]
				local find = string.find(opt, "_auto_call_transport_2")
				local name = find and string.sub(opt,0,find-1)
				local ud = name and UnitDefNames[name]
				if ud then
					if options[opt].min == 0 then
						options[opt].value = 1
					else
						options[opt].value = -1
					end
				end
			end
		end,
	},
	disableAutoCallTransport = {
		type = 'button',
		name = "Disable Auto Call Transport",
		desc = "Disables auto call transport for all factories, sets constructors to inherit.",
		path = "Settings/Unit Behaviour/Default States/Presets",
		OnChange = function ()
			for i = 1, #options_order do
				local opt = options_order[i]
				local find = string.find(opt, "_auto_call_transport_2")
				local name = find and string.sub(opt,0,find-1)
				local ud = name and UnitDefNames[name]
				if ud then
					if options[opt].min == 0 then
						options[opt].value = 0
					else
						options[opt].value = -1
					end
				end
			end
		end,
	},
	setRanksToDefault = {
		type = 'button',
		name = "Set Select Rank to Default",
		desc = "Resets selection ranks to default, 1 for structures, 2 for constructors and 3 for combat units (including commander).",
		path = "Settings/Unit Behaviour/Default States/Presets",
		OnChange = function ()
			options.commander_selection_rank.value = 3
			for i = 1, #options_order do
				local opt = options_order[i]
				local find = string.find(opt, "_selection_rank")
				local name = find and string.sub(opt, 0, find - 1)
				local ud = name and UnitDefNames[name]
				if ud then
					options[opt].value = defaultSelectionRank[ud.id] or 3
				end
			end
		end,
	},
	setRanksToThree = {
		type = 'button',
		name = "Set All Select Rank to 3",
		desc = "Effectively disables selection ranking while retaining the ability to manually set ranks.",
		path = "Settings/Unit Behaviour/Default States/Presets",
		OnChange = function ()
			options.commander_selection_rank.value = 3
			for i = 1, #options_order do
				local opt = options_order[i]
				local find = string.find(opt, "_selection_rank")
				if find then
					options[opt].value = 3
				end
			end
		end,
	},
	setFactoryRanksToThree = {
		type = 'button',
		name = "Factory Select Rank to 3",
		desc = "Sets Factories and Plates to have selection rank 3.",
		path = "Settings/Unit Behaviour/Default States/Presets",
		OnChange = function ()
			options.commander_selection_rank.value = 3
			for i = 1, #options_order do
				local opt = options_order[i]
				local find = string.find(opt, "_selection_rank")
				local name = find and string.sub(opt, 0, find - 1)
				local ud = name and UnitDefNames[name]
				if ud and IsFactory(ud) then
					options[opt].value = 3
				end
			end
		end,
	},
	setFactoryRanksToTwo = {
		type = 'button',
		name = "Factory Select Rank to 2",
		desc = "Sets Factories and Plates to have selection rank 2.",
		path = "Settings/Unit Behaviour/Default States/Presets",
		OnChange = function ()
			options.commander_selection_rank.value = 3
			for i = 1, #options_order do
				local opt = options_order[i]
				local find = string.find(opt, "_selection_rank")
				local name = find and string.sub(opt, 0, find - 1)
				local ud = name and UnitDefNames[name]
				if ud and IsFactory(ud) then
					options[opt].value = 2
				end
			end
		end,
	},
	
	commander_label = {
		name = "label",
		type = 'label',
		value = "Commander",
		path = "Settings/Unit Behaviour/Default States/Misc",
	},

	commander_firestate0 = {
		name = "  Firestate",
		desc = "Values: hold fire, return fire, fire at will",
		type = 'number',
		value = 2, -- commander are fire@will by default
		min = 0, -- most firestates are -1 but no factory/unit build comm (yet)
		max = 2,
		step = 1,
		path = "Settings/Unit Behaviour/Default States/Misc",
		tooltipFunction = tooltipFunc.firestate,
	},

	commander_movestate1 = {
		name = "  Movestate",
		desc = "Values: hold position, maneuver, roam",
		type = 'number',
		value = 1,
		min = 0,-- no factory/unit build comm (yet)
		max = 2,
		step = 1,
		path = "Settings/Unit Behaviour/Default States/Misc",
		tooltipFunction = tooltipFunc.movestate,
	},

	commander_constructor_buildpriority = {
		name = "  Constructor Build Priority",
		desc = "Values: Low, Normal, High",
		type = 'number',
		value = 1,
		min = 0,
		max = 2,
		step = 1,
		path = "Settings/Unit Behaviour/Default States/Misc",
		tooltipFunction = tooltipFunc.priority,
	},

	commander_misc_priority = {
		name = "  Miscellaneous Priority",
		desc = "Values: Low, Normal, High",
		type = 'number',
		value = 1,
		min = 0,
		max = 2,
		step = 1,
		path = "Settings/Unit Behaviour/Default States/Misc",
		tooltipFunction = tooltipFunc.priority,
	},

	commander_retreat = {
		name = "  Retreat At Value",
		desc = "Values: no retreat, 30%, 65%, 99% health remaining",
		type = 'number',
		value = 0,
		min = 0,
		max = 3,
		step = 1,
		path = "Settings/Unit Behaviour/Default States/Misc",
		tooltipFunction = tooltipFunc.retreat,
	},
	
	commander_auto_call_transport_2 = {
		name = "  Auto Call Transport",
		desc = "Values: Disabled, Enabled",
		type = 'number',
		value = 0,
		min = 0,
		max = 1,
		step = 1,
		path = "Settings/Unit Behaviour/Default States/Misc",
		tooltipFunction = tooltipFunc.auto_call_transport,
	},

	commander_selection_rank = {
		name = "  Selection Rank",
		desc = "Selection Rank: when selecting multiple units only those of highest rank are selected. Hold shift to ignore rank.",
		type = 'number',
		value = 3,
		min = 0,
		max = 3,
		step = 1,
		path = "Settings/Unit Behaviour/Default States/Misc",
		tooltipFunction = tooltipFunc.selectionrank,
	},

	commander_formation_rank = {
		name = "  Formation Rank",
		desc = "Formation Rank: units of lower rank line up in front of units of higher rank when given line movement orders.",
		type = 'number',
		value = 2,
		min = 0,
		max = 3,
		step = 1,
		path = "Settings/Unit Behaviour/Default States/Misc",
		tooltipFunction = tooltipFunc.formationrank,
	},
}

local tacticalAIUnits = {}
local wardFireUnits = {}
local wardFireCmdID = {}
do
	local tacticalAIDefs, behaviourDefaults = VFS.Include("LuaRules/Configs/tactical_ai_defs.lua", nil, VFS.ZIP)
	for unitDefID, behaviourData in pairs(tacticalAIDefs) do
		if not behaviourData.onlyIdleHandling then
			local unitDefName = unitDefID and UnitDefs[unitDefID]
			unitDefName = unitDefName and unitDefName.name
			if unitDefName then
				tacticalAIUnits[unitDefName] = {value = (behaviourData.defaultAIState or behaviourDefaults.defaultState) == 1}
			end
			if behaviourData.hasWardFire then
				wardFireUnits[unitDefName] = (behaviourData.wardFireDefault and 1) or 0
				wardFireCmdID[unitDefName] = behaviourData.wardFireCmdID
			end
		end
	end
end

local unitAlreadyAdded = {}

local function addLabel(text, path) -- doesn't work with order
	path = (path and "Settings/Unit Behaviour/Default States/" .. path) or "Settings/Unit Behaviour/Default States"
	options[text .. "_label"] = {
		name = "label",
		type = 'label',
		value = text,
		path = path,
	}
	options_order[#options_order+1] = text .. "_label"
end

local function addUnit(defName, path)

	if unitAlreadyAdded[defName] then
		return
	end

	unitAlreadyAdded[defName] = true

	path = "Settings/Unit Behaviour/Default States/" .. path
	local ud = UnitDefNames[defName]
	if not ud then
		Spring.Echo("Initial States invalid unit " .. defName)
		return
	end
	local unitDefID = ud.id

	options[defName .. "_label"] = {
		name = "label",
		type = 'label',
		value = Spring.Utilities.GetHumanName(ud),
		path = path,
	}
	options_order[#options_order+1] = defName .. "_label"

	if ud.canAttack or ud.isFactory then
		options[defName .. "_firestate0"] = {
			name = "  Firestate",
			desc = "Values: inherit from factory, hold fire, return fire, fire at will",
			type = 'number',
			value = ud.fireState, -- most firestates are -1
			min = -1,
			max = 2,
			step = 1,
			path = path,
			tooltipFunction = tooltipFunc.firestate,
		}
		options_order[#options_order+1] = defName .. "_firestate0"
	end

	if (ud.canMove or ud.canPatrol) and ((not ud.isBuilding) or ud.isFactory) then
		options[defName .. "_movestate1"] = {
			name = "  Movestate",
			desc = "Values: inherit from factory, hold position, maneuver, roam",
			type = 'number',
			value = ud.moveState,
			min = -1,
			max = 2,
			step = 1,
			path = path,
			tooltipFunction = tooltipFunc.movestate,
		}
		options_order[#options_order+1] = defName .. "_movestate1"
	end

	if (ud.canFly) then
		options[defName .. "_flylandstate_1"] = {
			name = "  Fly/Land State",
			desc = "Values: inherit from factory, fly, land",
			type = 'number',
			value = (ud.customParams and ud.customParams.landflystate and ((ud.customParams.landflystate == "1" and 1) or 0)) or -1,
			min = -1,
			max = 1,
			step = 1,
			path = path,
			tooltipFunction = tooltipFunc.flylandstate,
		}
		options_order[#options_order+1] = defName .. "_flylandstate_1"
	elseif ud.customParams and ud.customParams.landflystate then
		options[defName .. "_flylandstate_1_factory"] = {
			name = "  Fly/Land State for factory",
			desc = "Values: fly, land",
			type = 'number',
			value = (ud.customParams and ud.customParams.landflystate and ud.customParams.landflystate == "1" and 1) or 0,
			min = 0,
			max = 1,
			step = 1,
			path = path,
			tooltipFunction = tooltipFunc.flylandstate,
		}
		options_order[#options_order+1] = defName .. "_flylandstate_1_factory"
	end

	if ud.isFactory or ud.customParams.isfakefactory then
		options[defName .. "_repeat"] = {
			name = "  Repeat",
			desc = "Repeat construction queue.",
			type = 'bool',
			value = false,
			path = path,
		}
		options_order[#options_order+1] = defName .. "_repeat"
	end
	
	if factoryDefs[unitDefID] then
		options[defName .. "_auto_assist"] = {
			name = "  Auto Assist",
			desc = "Newly built constructors assist the factory",
			type = 'bool',
			value = false,
			path = path,
		}
		options_order[#options_order+1] = defName .. "_auto_assist"
	end

	if ud.customParams and ud.customParams.airstrafecontrol then
		options[defName .. "_airstrafe1"] = {
			name = "  Air Strafe",
			desc = "Air Strafe: check box to turn it on",
			type = 'bool',
			value = ud.customParams.airstrafecontrol == "1",
			path = path,
		}
		options_order[#options_order+1] = defName .. "_airstrafe1"
	end

	if ud.customParams and ud.customParams.floattoggle then
		options[defName .. "_floattoggle"] = {
			name = "  Float State",
			desc = "Values: Never float, float to attack, float to attack or when idle",
			type = 'number',
			value = (ud.customParams and ud.customParams.floattoggle) or 1,
			min = 0,
			max = 2,
			step = 1,
			path = path,
			tooltipFunction = tooltipFunc.floatstate,
		}
		options_order[#options_order+1] = defName .. "_floattoggle"
	end

	if ud.customParams and ud.customParams.grey_goo then
		options[defName .. "_goostate"] = {
			name = "  Puppy Goo",
			desc = "Values: Never gather, Gather when not cloaked, Always Gather",
			type = 'number',
			value = (ud.customParams and ud.customParams.grey_goo) or 1,
			min = 0,
			max = 2,
			step = 1,
			path = path,
			tooltipFunction = tooltipFunc.goostate,
		}
		options_order[#options_order+1] = defName .. "_goostate"
	end

	options[defName .. "_buildpriority_0"] = {
		name = "  Nanoframe Build Priority",
		desc = "Values: Inherit, Low, Normal, High",
		type = 'number',
		value = -1,
		min = -1,
		max = 2,
		step = 1,
		path = path,
		tooltipFunction = tooltipFunc.priority,
	}
	options_order[#options_order+1] = defName .. "_buildpriority_0"

	if ud.isImmobile then
		options[defName .. "_buildpriority_0"].value = 1
	end

	if ud.canAssist and ud.buildSpeed ~= 0 then
		options[defName .. "_constructor_buildpriority"] = {
			name = "  Constructor Build Priority",
			desc = "Values: Low, Normal, High",
			type = 'number',
			value = 1,
			min = 0,
			max = 2,
			step = 1,
			path = path,
			tooltipFunction = tooltipFunc.priority,
		}
		options_order[#options_order+1] = defName .. "_constructor_buildpriority"
	end

	if ud.customParams.priority_misc then
		options[defName .. "_misc_priority"] = {
			name = "  Miscellaneous Priority",
			desc = "Values: Low, Normal, High",
			type = 'number',
			value = ud.customParams.priority_misc,
			min = 0,
			max = 2,
			step = 1,
			path = path,
			tooltipFunction = tooltipFunc.priority,
		}
		options_order[#options_order+1] = defName .. "_misc_priority"
	end
	
	if ud.isMobileBuilder and not ud.isAirUnit and not ud.cantBeTransported then
		options[defName .. "_auto_call_transport_2"] = {
			name = "  Auto Call Transport",
			desc = "Values: Inherit, Disabled, Enabled",
			type = 'number',
			value = -1,
			min = -1,
			max = 1,
			step = 1,
			path = path,
			tooltipFunction = tooltipFunc.auto_call_transport,
		}
		options_order[#options_order+1] = defName .. "_auto_call_transport_2"
	elseif Spring.Utilities.isGroundFactory(ud) then
		options[defName .. "_auto_call_transport_2"] = {
			name = "  Auto Call Transport",
			desc = "Values: Disabled, Enabled",
			type = 'number',
			value = 0,
			min = 0,
			max = 1,
			step = 1,
			path = path,
			tooltipFunction = tooltipFunc.auto_call_transport,
		}
		options_order[#options_order+1] = defName .. "_auto_call_transport_2"
	end
	
	if (ud.canMove or ud.isFactory) then
		options[defName .. "_retreatpercent"] = {
			name = "  Retreat at value",
			desc = "Values: inherit from factory, no retreat, 33%, 65%, 99% health remaining",
			type = 'number',
			value = -1,
			min = -1,
			max = 3,
			step = 1,
			path = path,
			tooltipFunction = tooltipFunc.retreat,
		}
		options_order[#options_order+1] = defName .. "_retreatpercent"
	end

	options[defName .. "_selection_rank"] = {
		name = "  Selection Rank",
		desc = "Selection Rank: when selecting multiple units only those of highest rank are selected. Hold shift to ignore rank.",
		type = 'number',
		value = defaultSelectionRank[unitDefID] or 3,
		min = 0,
		max = 3,
		step = 1,
		path = path,
		tooltipFunction = tooltipFunc.selectionrank,
	}
	options_order[#options_order+1] = defName .. "_selection_rank"
	
	if ud.canMove and not ud.isFactory and not (ud.springCategories.fixedwing) then
		options[defName .. "_formation_rank"] = {
			name = "  Formation Rank",
			desc = "Formation Rank: set rank in formation",
			type = 'number',
			value = 2,
			min = 0,
			max = 3,
			step = 1,
			path = path,
			tooltipFunction = tooltipFunc.formationrank,
		}
		options_order[#options_order+1] = defName .. "_formation_rank"
	end
	
	if tacticalAIUnits[defName] then
		options[defName .. "_tactical_ai_2"] = {
			name = "  Smart AI",
			desc = "Smart AI: check box to turn it on",
			type = 'bool',
			value = tacticalAIUnits[defName].value,
			path = path,
		}
		options_order[#options_order+1] = defName .. "_tactical_ai_2"
	end
	
	if (ud.transportCapacity >= 1) and ud.canFly then
		options[defName .. "_tactical_ai_transport"] = {
			name = "  Transport AI",
			desc = "Transport AI: check box to have transports ferry units automatically.",
			type = 'bool',
			value = ud.metalCost < 200, -- Automatically enabled for light transports.
			path = path,
		}
		options_order[#options_order+1] = defName .. "_tactical_ai_transport"
	end

	if dontFireAtRadarUnits[unitDefID] ~= nil then
		options[defName .. "_fire_at_radar"] = {
			name = "  Fire at radar",
			desc = "Check box to make these units fire at radar. All other units fire at radar but these have the option not to.",
			type = 'bool',
			value = dontFireAtRadarUnits[unitDefID],
			path = path,
		}
		options_order[#options_order+1] = defName .. "_fire_at_radar"
	end

	if overkillPrevention[unitDefID] or overkillPreventionBlackHole[unitDefID] then
		options[defName .. "_overkill_prevention"] = {
			name = "  Overkill Prevention",
			desc = "Check box to make these units avoid firing at targets that are already likely to die due to incoming fire.",
			type = 'bool',
			value = true,
			path = path,
		}
		options_order[#options_order+1] = defName .. "_overkill_prevention"
	end

	if wardFireUnits[defName] then
		local def = wardFireUnits[defName]
		local wardCmd = wardFireCmdID[defName]
		
		if wardCmd == CMD_FIRE_AT_SHIELD then
			options[defName .. "_fire_at_shield"] = {
				name = "  Fire at Shields",
				desc = "Shoot at the shields of Thugs, Felons and Convicts when nothing else is in range.",
				type = 'bool',
				value = (wardFireUnits[defName] == 1),
				path = path,
				tooltipFunction = tooltipFunc.prevent_bait,
			}
			options_order[#options_order+1] = defName .. "_fire_at_shield"
		elseif wardCmd == CMD_FIRE_TOWARDS_ENEMY then
			options[defName .. "_fire_towards_enemy"] = {
				name = "  Fire Towards Enemies",
				desc = "Shoot towards the closest enemy when nothing else is in range.",
				type = 'bool',
				value = (wardFireUnits[defName] == 1),
				path = path,
				tooltipFunction = tooltipFunc.prevent_bait,
			}
			options_order[#options_order+1] = defName .. "_fire_towards_enemy"
		end
	end

	if baitPreventionDefault[unitDefID] then
		options[defName .. "_prevent_bait"] = {
			name = "  Avoid bad targets",
			desc = "Avoid shooting at low value targets, set by a threshold.",
			type = 'number',
			value = baitPreventionDefault[unitDefID],
			min = 0,
			max = 4,
			step = 1,
			path = path,
			tooltipFunction = tooltipFunc.prevent_bait,
		}
		options_order[#options_order+1] = defName .. "_prevent_bait"
	end

	if ud.canCloak then
		options[defName .. "_personal_cloak_0"] = {
			name = "  Personal Cloak",
			desc = "Personal Cloak: check box to turn it on",
			type = 'bool',
			value = ud.customParams.initcloaked,
			path = path,
		}
		options_order[#options_order+1] = defName .. "_personal_cloak_0"
	end

	if ud.onOffable then
		if impulseUnitDefID[unitDefID] then
			options[defName .. "_impulseMode"] = {
				name = "  Gravity Gun Push/Pull",
				desc = "Check box to default to Push.",
				type = 'bool',
				value = true,
				path = path,
			}
			options_order[#options_order+1] = defName .. "_impulseMode"
		else
			options[defName .. "_activateWhenBuilt"] = {
				name = "  On/Off State",
				desc = "Check box to set the unit to On when built.",
				type = 'bool',
				value = ud.activateWhenBuilt,
				path = path,
			}
			options_order[#options_order+1] = defName .. "_activateWhenBuilt"
		end
	end
	
	if ud.customParams.attack_toggle then
		options[defName .. "_disableattack"] = {
			name = "  Disable Attack Commands",
			desc = "Check the box to make the unit not respond to attack commands.",
			type = 'bool',
			value = false,
			path = path,
		}
		options_order[#options_order+1] = defName .. "_disableattack"
	end
	
	if ud.canStockpile then
		options[defName .. "_stockpile"] = {
			name = "  Initial Stockpile",
			desc = "Initial Stockpile: The default stockpile limit of the unit.",
			type = 'number',
			value = (ud.name == "turretaaheavy" and 100 or 10),
			min = 0,
			max = 100,
			step = 1,
			path = path,
		}
		options_order[#options_order+1] = defName .. "_stockpile"
	end
end

local function AddFactoryOfUnits(defName, plateDefName)
	if unitAlreadyAdded[defName] then
		return
	end
	local ud = UnitDefNames[defName]
	local name = string.gsub(ud.humanName, "/", "-")
	addUnit(defName, name)
	if plateDefName then
		addUnit(plateDefName, name)
	end
	for i = 1, #ud.buildOptions do
		addUnit(UnitDefs[ud.buildOptions[i]].name, name)
		unitsToFactory[UnitDefs[ud.buildOptions[i]].name] = defName
	end
end

AddFactoryOfUnits("factoryshield",  "plateshield")
AddFactoryOfUnits("factorycloak",   "platecloak")
AddFactoryOfUnits("factoryveh",     "plateveh")
AddFactoryOfUnits("factoryplane",   "plateplane")
AddFactoryOfUnits("factorygunship", "plategunship")
AddFactoryOfUnits("factoryhover",   "platehover")
AddFactoryOfUnits("factoryamph",    "plateamph")
AddFactoryOfUnits("factoryspider",  "platespider")
AddFactoryOfUnits("factoryjump",    "platejump")
AddFactoryOfUnits("factorytank",    "platetank")
AddFactoryOfUnits("factoryship",    "plateship")
AddFactoryOfUnits("striderhub")
AddFactoryOfUnits("staticmissilesilo")

local buildOpts = VFS.Include("gamedata/buildoptions.lua")
local factory_commands, econ_commands, defense_commands, special_commands = include("Configs/integral_menu_commands_processed.lua", nil, VFS.RAW_FIRST)

for i = 1, #buildOpts do
	local name = buildOpts[i]
	if econ_commands[-UnitDefNames[name].id] then
		addUnit(name,"Economy")
	elseif defense_commands[-UnitDefNames[name].id] then
		addUnit(name,"Defence")
	elseif special_commands[-UnitDefNames[name].id] then
		addUnit(name,"Special")
	else
		addUnit(name,"Misc")
	end
end

local function AmITeamLeader(teamID)
	local myTeam = (teamID == Spring.GetMyTeamID())
	local amLeader = myTeam and (Spring.GetMyPlayerID() == select (2, Spring.GetTeamInfo(teamID, false)))
	return myTeam, amLeader
end

local function SetControlGroup(unitID, factID)
	local factGroup = Spring.GetUnitGroup(factID)
	if (not factGroup) then
		return
	end
	if options.inheritcontrol.value  then
		Spring.SetUnitGroup(unitID, factGroup)
		return
	end
	
	local unitGroup = Spring.GetUnitGroup(unitID)
	if (not unitGroup) then
		return
	end
	if (unitGroup == factGroup) then
		Spring.SetUnitGroup(unitID, -1)
	end
end

local function ApplyUniversalUnitStates(unitID, unitDefID, unitTeam, builderID)
	local ud = UnitDefs[unitDefID]
	local name = ud.name
	
	if options[name .. "_selection_rank"] and WG.SetSelectionRank then
		WG.SetSelectionRank(unitID, options[name .. "_selection_rank"].value)
	end
	if ud.customParams.commtype or ud.customParams.level then
		if options.commander_selection_rank and WG.SetSelectionRank then
			WG.SetSelectionRank(unitID, options.commander_selection_rank.value)
		end
	end
	
	if options[name .. "_formation_rank"] and WG.SetFormationRank then
		WG.SetFormationRank(unitID, options[name .. "_formation_rank"].value)
	end
	if ud.customParams.commtype or ud.customParams.level then
		if options.commander_formation_rank and WG.SetFormationRank then
			WG.SetFormationRank(unitID, options.commander_formation_rank.value)
		end
	end
end

local function GetFactoryDefState(unitDefName, stateName)
	--Spring.Echo("Getting state " .. stateName .. " for " .. unitDefName)
	local factoryName = unitsToFactory[unitDefName]
	if not factoryName then
		return nil
	end
	local opt = options[factoryName .. "_" .. stateName]
	local state = opt and opt.value
	--Spring.Echo("Parent state is " .. state)
	if state == -1 then
		return GetFactoryDefState(factoryName, stateName)
	else
		return state
	end
end

local function GetStateValue(unitDefName, stateName)
	return options[unitDefName .. "_" .. stateName] and options[unitDefName .. "_" .. stateName].value
end

local function QueueState(unitDefName, stateName, cmdID, cmdArray, invertBool)
	local value = GetStateValue(unitDefName, stateName)
	if value == nil then
		return
	end
	if type(value) == "boolean" then
		if invertBool then
			value = not value
		end
		value = value and 1 or 0
	end
	cmdArray[#cmdArray + 1] = {cmdID, {value}, CMD.OPT_SHIFT}
end

local function StockpileUnit(unitID, wanted, orderArray)
	local stocked, queued = Spring.GetUnitStockpile(unitID)
	local to_add = wanted - stocked - queued
	while to_add > 0 do
		local added = 1
		local code = 0
		if to_add >= 100 then
			code = CMD.OPT_SHIFT + CMD.OPT_CTRL
			added = 100
		elseif to_add >= 20 then
			code = CMD.OPT_CTRL
			added = 20
		elseif to_add >= 5 then
			code = CMD.OPT_SHIFT
			added = 5
		end
		orderArray[#orderArray + 1] = {CMD.STOCKPILE, {}, code}
		to_add = to_add - added
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:UnitCreated(unitID, unitDefID, unitTeam, builderID)
	if not (unitDefID and UnitDefs[unitDefID]) then
		return
	end
	-- don't apply some states to save/loaded unit
	local oldID = Spring.GetUnitRulesParam(unitID, "saveload_oldID")
	
	local myTeam, amLeader = AmITeamLeader(unitTeam)
	if not amLeader then
		if myTeam or spectatingState then
			ApplyUniversalUnitStates(unitID, unitDefID, unitTeam, builderID)
		end
		return
	end
	
	if oldID then
		return
	end

	local ud = UnitDefs[unitDefID]
	local orderArray = {}
	if ud.customParams.commtype or ud.customParams.level then
		local morphed = Spring.GetTeamRulesParam(unitTeam, "morphUnitCreating") == 1
		if morphed then
			-- Gadget and Spring unit states are applied in unit_morph gadget. Widget unit
			-- states are handled by their widget.
			return
		end

		orderArray[1] = {CMD.FIRE_STATE, {options.commander_firestate0.value}, CMD.OPT_SHIFT}
		orderArray[2] = {CMD.MOVE_STATE, {options.commander_movestate1.value}, CMD.OPT_SHIFT}
		orderArray[3] = {CMD_RETREAT, {options.commander_retreat.value}, CMD.OPT_SHIFT + (options.commander_retreat.value == 0 and CMD.OPT_RIGHT or 0)}
		if WG.SetAutoCallTransportState and options.commander_auto_call_transport_2.value == 1 then
			WG.SetAutoCallTransportState(unitID, unitDefID, true)
		end

		if options.commander_selection_rank and WG.SetSelectionRank then
			WG.SetSelectionRank(unitID, options.commander_selection_rank.value)
		end
		if options.commander_formation_rank and WG.SetFormationRank then
			WG.SetFormationRank(unitID, options.commander_formation_rank.value)
		end
	end

	local name = ud.name
	if unitAlreadyAdded[name] then
		local value = GetStateValue(name, "firestate0")
		if value ~= nil then
			if value == -1 then
				local trueBuilder = false
				if builderID then
					local bdid = Spring.GetUnitDefID(builderID)
					if UnitDefs[bdid] and UnitDefs[bdid].isFactory then
						local firestate = Spring.Utilities.GetUnitFireState(builderID)
						if firestate then
							orderArray[#orderArray + 1] = {CMD.FIRE_STATE, {firestate}, CMD.OPT_SHIFT}
							trueBuilder = true
						end
					end
				end
				if not trueBuilder then	-- inherit from factory def's start state, not the current state of any specific factory unit
					local firestate = GetFactoryDefState(name, "firestate0")
					if firestate ~= nil then
						orderArray[#orderArray + 1] = {CMD.FIRE_STATE, {firestate}, CMD.OPT_SHIFT}
					end
				end
			else
				orderArray[#orderArray + 1] = {CMD.FIRE_STATE, {value}, CMD.OPT_SHIFT}
			end
		end

		value = GetStateValue(name, "movestate1")
		if value ~= nil then
			if value == -1 then
				local trueBuilder = false
				if builderID then
					local bdid = Spring.GetUnitDefID(builderID)
					if UnitDefs[bdid] and UnitDefs[bdid].isFactory then
						local movestate = Spring.Utilities.GetUnitMoveState(builderID)
						if movestate then
							orderArray[#orderArray + 1] = {CMD.MOVE_STATE, {movestate}, CMD.OPT_SHIFT}
							trueBuilder = true
						end
					end
				end
				if not trueBuilder then	-- inherit from factory def's start state, not the current state of any specific factory unit
					local movestate = GetFactoryDefState(name, "movestate1")
					if movestate ~= nil then
						orderArray[#orderArray + 1] = {CMD.MOVE_STATE, {movestate}, CMD.OPT_SHIFT}
					end
				end
			else
				orderArray[#orderArray + 1] = {CMD.MOVE_STATE, {value}, CMD.OPT_SHIFT}
			end
		end
		
		value = GetStateValue(name, "flylandstate_1")
		if value == -1 then
			local trueBuilder = false
			if builderID then
				local bdid = Spring.GetUnitDefID(builderID)
				if UnitDefs[bdid] and UnitDefs[bdid].isFactory then
					trueBuilder = true
					-- inheritance handled in unit_air_plants gadget
				end
			end
			if not trueBuilder then	-- inherit from factory def's start state, not the current state of any specific factory unit
				value = GetFactoryDefState(name, "flylandstate_1_factory")
				if value ~= nil then
					orderArray[#orderArray + 1] = {CMD.IDLEMODE, {value}, CMD.OPT_SHIFT}
				end
			end
		elseif value then
			orderArray[#orderArray + 1] = {CMD.IDLEMODE, {value}, CMD.OPT_SHIFT}
		end
		
		QueueState(name, "repeat", CMD.REPEAT, orderArray)
		QueueState(name, "flylandstate_1_factory", CMD_AP_FLY_STATE, orderArray)
		QueueState(name, "auto_assist", CMD_FACTORY_GUARD, orderArray)
		QueueState(name, "airstrafe1", CMD_AIR_STRAFE, orderArray)
		QueueState(name, "floattoggle", CMD_UNIT_FLOAT_STATE, orderArray)
		QueueState(name, "goostate", CMD_GOO_GATHER, orderArray)
		
		local retreat = GetStateValue(name, "retreatpercent")
		if retreat == -1 then --if inherit
			if builderID then
				retreat = Spring.GetUnitRulesParam(builderID,"retreatState")
			else
				retreat = GetFactoryDefState(name, "retreatpercent")
			end
		end
		if retreat then
			if retreat == 0 then
				orderArray[#orderArray + 1] = {CMD_RETREAT, {0}, CMD.OPT_SHIFT + CMD.OPT_RIGHT}  -- to set retreat to 0, "right" option must be used
			else
				orderArray[#orderArray + 1] = {CMD_RETREAT, {retreat}, CMD.OPT_SHIFT}
			end
		end
		
		value = GetStateValue(name, "buildpriority_0")
		if value then
			if value == -1 then
				if builderID then
					local priority = Spring.GetUnitRulesParam(builderID,"buildpriority")
					if priority then
						orderArray[#orderArray + 1] = {CMD_PRIORITY, {priority}, CMD.OPT_SHIFT}
					end
				else
					local priority = GetFactoryDefState(name, "constructor_buildpriority")
					orderArray[#orderArray + 1] = {CMD_PRIORITY, {priority or 1}, CMD.OPT_SHIFT}
				end
			else
				orderArray[#orderArray + 1] = {CMD_PRIORITY, {value}, CMD.OPT_SHIFT}
			end
		end
		
		value = GetStateValue(name, "misc_priority")
		if value then
			if value ~= 1 then -- Medium is the default
				orderArray[#orderArray + 1] = {CMD_MISC_PRIORITY, {value}, CMD.OPT_SHIFT}
			end
		end
		
		value = GetStateValue(name, "auto_call_transport_2")
		if value and WG.SetAutoCallTransportState then
			if value == -1 then
				local autoCallTransport = false
				if builderID then
					autoCallTransport = WG.GetAutoCallTransportState and WG.GetAutoCallTransportState(builderID)
				else
					autoCallTransport = GetFactoryDefState(name, "auto_call_transport_2") ~= 0
				end
				if autoCallTransport then
					WG.SetAutoCallTransportState(unitID, unitDefID, true)
				end
			else
				if value == 1 then
					WG.SetAutoCallTransportState(unitID, unitDefID, true)
				end
			end
		end
		
		value = GetStateValue(name, "selection_rank")
		if value and WG.SetSelectionRank then
			WG.SetSelectionRank(unitID, value)
		end
		
		value = GetStateValue(name, "prevent_bait")
		if value then
			orderArray[#orderArray + 1] = {CMD_PREVENT_BAIT, {value}, CMD.OPT_SHIFT}
		end
		
		value = GetStateValue(name, "fire_at_shield")
		if value then
			orderArray[#orderArray + 1] = {CMD_FIRE_AT_SHIELD, {(value and 1) or 0}, CMD.OPT_SHIFT}
		end
		
		value = GetStateValue(name, "fire_towards_enemy")
		if value then
			orderArray[#orderArray + 1] = {CMD_FIRE_TOWARDS_ENEMY, {(value and 1) or 0}, CMD.OPT_SHIFT}
		end
		
		value = GetStateValue(name, "disableattack")
		if value then -- false is the default
			orderArray[#orderArray + 1] = {CMD_DISABLE_ATTACK, {1}, CMD.OPT_SHIFT}
		end

		value = GetStateValue(name, "formation_rank")
		if value and WG.SetFormationRank then
			WG.SetFormationRank(unitID, value)
		end
	
		QueueState(name, "tactical_ai_2", CMD_UNIT_AI, orderArray)
		
		value = GetStateValue(name, "tactical_ai_transport")
		if value and WG.AddTransport then
			WG.AddTransport(unitID, unitDefID)
		end
		
		value = GetStateValue(name, "stockpile")
		if value then
			StockpileUnit(unitID, value, orderArray)
		end
		
		QueueState(name, "fire_at_radar", CMD_DONT_FIRE_AT_RADAR, orderArray, true)
		QueueState(name, "overkill_prevention", CMD_PREVENT_OVERKILL, orderArray)
		QueueState(name, "personal_cloak_0", CMD_WANT_CLOAK, orderArray)
		QueueState(name, "impulseMode", CMD_PUSH_PULL, orderArray)
		QueueState(name, "activateWhenBuilt", CMD_WANT_ONOFF, orderArray)
	end

	if #orderArray > 0 then
		Spring.GiveOrderArrayToUnitArray ({unitID,},orderArray) --give out all orders at once
	end
	orderArray = nil
end

function widget:UnitDestroyed(unitID)
	local morphedTo = Spring.GetUnitRulesParam(unitID, "wasMorphedTo")
	if not morphedTo then
		return
	end

	local controlGroup = Spring.GetUnitGroup(unitID)
	if controlGroup then
		Spring.SetUnitGroup(morphedTo, controlGroup)
	end
end

function widget:UnitFromFactory(unitID, unitDefID, unitTeam, factID, factDefID, userOrders)
	if not AmITeamLeader (unitTeam) or not unitDefID or not UnitDefs[unitDefID] then
		return
	end
	
	SetControlGroup(unitID, factID)

	local name = UnitDefs[unitDefID].name
	
	-- inherit constructor build priority (not wanted)
	--[[
	local value = GetStateValue(name, "constructor_buildpriority")
	if value then
		if value == -1 then
			local priority = Spring.GetUnitRulesParam(factID,"buildpriority")
			if priority then
				Spring.GiveOrderToUnit(unitID, CMD_PRIORITY, priority, CMD.OPT_SHIFT)
			end
		end
	end
	]]
end

function widget:UnitFinished(unitID, unitDefID, unitTeam)
	if not AmITeamLeader (unitTeam) or not unitDefID or not UnitDefs[unitDefID] or (Spring.GetTeamRulesParam(unitTeam, "morphUnitCreating") == 1) then
		return
	end
	
	local oldID = Spring.GetUnitRulesParam(unitID, "saveload_oldID")
	if oldID then
		return
	end

	local orderArray = {}
	if UnitDefs[unitDefID].customParams.commtype or UnitDefs[unitDefID].customParams.level then
		orderArray[1] = {CMD_PRIORITY, {GetStateValue("commander", "constructor_buildpriority")}, CMD.OPT_SHIFT}
		orderArray[2] = {CMD_MISC_PRIORITY, {GetStateValue("commander", "misc_priority")}, CMD.OPT_SHIFT}
	end

	local name = UnitDefs[unitDefID].name
	QueueState(name, "constructor_buildpriority", CMD_PRIORITY, orderArray)

	if #orderArray > 0 then
		Spring.GiveOrderArrayToUnitArray ({unitID,},orderArray) --give out all orders at once
	end
	orderArray = nil
end

function widget:UnitGiven(unitID, unitDefID, newTeamID, teamID)
	widget:UnitCreated(unitID, unitDefID, newTeamID)
	widget:UnitFinished(unitID, unitDefID, newTeamID)
end

local function ApplyUnitStates()
	local teamID = (not spectatingState) and Spring.GetMyTeamID()
	local units = (teamID and Spring.GetTeamUnits(teamID)) or Spring.GetAllUnits()
	if units then
		for i = 1, #units do
			widget:UnitCreated(units[i], Spring.GetUnitDefID(units[i]), teamID or Spring.GetUnitTeam(units[i]), nil)
			widget:UnitFinished(units[i], Spring.GetUnitDefID(units[i]), teamID or Spring.GetUnitTeam(units[i]))
		end
	end
end

function widget:PlayerChanged()
	local newSpectatingState = select(1, Spring.GetSpectatingState())
	if newSpectatingState == spectatingState then
		return
	end
	spectatingState = newSpectatingState
	ApplyUnitStates()
end

function widget:GameFrame(n)
	if Spring.GetGameState then
		local finishedLoading, loadedFromSave, locallyPaused, lagging = Spring.GetGameState()
		if loadedFromSave then
			widgetHandler:RemoveCallIn("GameFrame", self)
			return
		end
	end
	if n < 10 then
		return
	end
	ApplyUnitStates()
	widgetHandler:RemoveCallIn("GameFrame", self)
end
