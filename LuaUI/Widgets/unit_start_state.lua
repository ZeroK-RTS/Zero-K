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
    enabled   = true  --  loaded by default?
  }
end

VFS.Include("LuaRules/Configs/customcmds.h.lua")

local alwaysHoldPos, holdPosException, dontFireAtRadarUnits, factoryDefs = VFS.Include("LuaUI/Configs/unit_state_defaults.lua")

local function IsGround(ud)
    return not ud.canFly and not ud.isFactory
end

options_path = 'Game/New Unit States'
options_order = {
	'inheritcontrol', 'presetlabel', 
	'resetMoveStates', 'holdPosition', 
	'skirmHoldPosition', 'artyHoldPosition', 'aaHoldPosition', 
	'enableTacticalAI', 'disableTacticalAI',
	'enableAutoAssist', 'disableAutoAssist', 
	'categorieslabel', 
	'commander_label', 
	'commander_firestate0', 
	'commander_movestate1', 
	'commander_constructor_buildpriority', 
	'commander_misc_priority', 
	'commander_retreat'
}

options = {
	inheritcontrol = {
		name = "Inherit Factory Control Group", 
		type = 'bool', 
		value = false, 
		noHotkey = true,
		path = "Settings/Interface/Control Groups",
	},

	presetlabel = {name = "presetlabel", type = 'label', value = "Presets", path = options_path},

	resetMoveStates = {
		type='button',
		name= "Clear Move States",
		desc = "Set all land units to inherit their move state from factory (overrides holdpos for skirms, arty and AA but not crabe, slasher or tremor)",
		path = "Game/New Unit States/Presets",
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
		noHotkey = true,
	},

	holdPosition = {
		type='button',
		name= "Hold Position",
		desc = "Set all land units to hold position",
		path = "Game/New Unit States/Presets",
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
		noHotkey = true,
	},

	skirmHoldPosition = {
		type='button',
		name= "Hold Position (Skirmishers)",
		desc = "Set all skirmishers to hold position",
		path = "Game/New Unit States/Presets",
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
		noHotkey = true,
	},

	artyHoldPosition = {
		type='button',
		name= "Hold Position (Artillery)",
		desc = "Set all artillery units to hold position",
		path = "Game/New Unit States/Presets",
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
		noHotkey = true,
	},

	aaHoldPosition = {
		type='button',
		name= "Hold Position (Anti-Air)",
		desc = "Set all non-flying anti-air units to hold position",
		path = "Game/New Unit States/Presets",
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
		noHotkey = true,
	},

	categorieslabel = {name = "presetlabel", type = 'label', value = "Categories", path = options_path},

	disableTacticalAI = {
		type='button',
		name= "Disable Tactical AI",
		desc = "Disables tactical AI (jinking and skirming) for all units.",
		path = "Game/New Unit States/Presets",
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
		noHotkey = true,
	},

	enableTacticalAI = {
		type='button',
		name= "Enable Tactical AI",
		desc = "Enables tactical AI (jinking and skirming) for all units.",
		path = "Game/New Unit States/Presets",
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
		noHotkey = true,
	},
	
	enableAutoAssist = {
		type='button',
		name= "Enable Auto Assist",
		desc = "Enables auto assist for all factories.",
		path = "Game/New Unit States/Presets",
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
		noHotkey = true,
	},
	disableAutoAssist = {
		type='button',
		name= "Disable Auto Assist",
		desc = "Disables auto assist for all factories.",
		path = "Game/New Unit States/Presets",
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
		noHotkey = true,
	},
	
	commander_label = {
		name = "label",
		type = 'label',
		value = "Commander",
		path = "Game/New Unit States/Misc",
	},

	commander_firestate0 = {
		name = "  Firestate",
		desc = "Values: hold fire, return fire, fire at will",
		type = 'number',
		value = 2, -- commander are fire@will by default
		min = 0, -- most firestates are -1 but no factory/unit build comm (yet)
		max = 2,
		step = 1,
		path = "Game/New Unit States/Misc",
	},

	commander_movestate1 = {
		name = "  Movestate",
		desc = "Values: hold position, maneuver, roam",
		type = 'number',
		value = 1,
		min = 0,-- no factory/unit build comm (yet)
		max = 2,
		step = 1,
		path = "Game/New Unit States/Misc",
	},

	commander_constructor_buildpriority = {
		name = "  Constructor Build Priority",
		desc = "Values: Low, Normal, High",
		type = 'number',
		value = 1,
		min = 0,
		max = 2,
		step = 1,
		path = "Game/New Unit States/Misc",
	},

	commander_misc_priority = {
		name = "  Miscellaneous Priority",
		desc = "Values: Low, Normal, High",
		type = 'number',
		value = 1,
		min = 0,
		max = 2,
		step = 1,
		path = "Game/New Unit States/Misc",
	},

	commander_retreat = {
		name = "  Retreat at value",
		desc = "Values: no retreat, 30%, 65%, 99% health remaining",
		type = 'number',
		value = 0,
		min = 0,
		max = 3,
		step = 1,
		path = "Game/New Unit States/Misc",
	},
}

local tacticalAIDefs, behaviourDefaults = VFS.Include("LuaRules/Configs/tactical_ai_defs.lua", nil, VFS.ZIP)

local tacticalAIUnits = {}

for unitDefName, behaviourData in pairs(tacticalAIDefs) do
    tacticalAIUnits[unitDefName] = {value = (behaviourData.defaultAIState or behaviourDefaults.defaultState) == 1}
end

local unitAlreadyAdded = {}

local function addLabel(text, path) -- doesn't work with order
    path = (path and "Game/New Unit States/" .. path) or "Game/New Unit States"
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

	path = "Game/New Unit States/" .. path
	local ud = UnitDefNames[defName]
	if not ud then
		Spring.Echo("Initial States invalid unit " .. defName)
		return
	end

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
		}
		options_order[#options_order+1] = defName .. "_flylandstate_1_factory"
	end

	if ud.isFactory then
		options[defName .. "_repeat"] = {
			name = "  Repeat",
			desc = "Repeat construction queue.",
			type = 'bool',
			value = false,
			path = path,
			noHotkey = true,
		}
		options_order[#options_order+1] = defName .. "_repeat"
	end
	
	if factoryDefs[ud.id] then
		options[defName .. "_auto_assist"] = {
			name = "  Auto Assist",
			desc = "Newly built constructors assist the factory",
			type = 'bool',
			value = false,
			path = path,
			noHotkey = true,
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
			noHotkey = true,
		}
		options_order[#options_order+1] = defName .. "_airstrafe1"
	end

	if ud.customParams and ud.customParams.floattoggle then
		options[defName .. "_floattoggle"] = {
			name = "  Float State",
			desc = "Values: Never float, float to attack, float when stationary",
			type = 'number',
			value = (ud.customParams and ud.customParams.floattoggle) or 1,
			min = 0,
			max = 2,
			step = 1,
			path = path,
		}
		options_order[#options_order+1] = defName .. "_floattoggle"
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
	}
	options_order[#options_order+1] = defName .. "_buildpriority_0"

	if ud.speed == 0 then
		options[defName .. "_buildpriority_0"].value = 1
	end

	if ud.canAssist and ud.buildSpeed ~= 0 then
		options[defName .. "_constructor_buildpriority"] = {
			name = "  Constructor Build Priority",
			desc = "Values: Inherit, Low, Normal, High",
			type = 'number',
			value = 1,
			min = -1,
			max = 2,
			step = 1,
			path = path,
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
		}
		options_order[#options_order+1] = defName .. "_misc_priority"
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
		}
		options_order[#options_order+1] = defName .. "_retreatpercent"
	end

	if tacticalAIUnits[defName] then
		options[defName .. "_tactical_ai_2"] = {
			name = "  Smart AI",
			desc = "Smart AI: check box to turn it on",
			type = 'bool',
			value = tacticalAIUnits[defName].value,
			path = path,
			noHotkey = true,
		}
		options_order[#options_order+1] = defName .. "_tactical_ai_2"
	end

	if dontFireAtRadarUnits[ud.id] then
		options[defName .. "_fire_at_radar"] = {
			name = "  Fire at radar",
			desc = "Check box to make these units fire at radar. All other units fire at radar but these have the option not to.",
			type = 'bool',
			value = true,
			path = path,
			noHotkey = true,
		}
		options_order[#options_order+1] = defName .. "_fire_at_radar"
	end

	if ud.canCloak then
		options[defName .. "_personal_cloak_0"] = {
			name = "  Personal Cloak",
			desc = "Personal Cloak: check box to turn it on",
			type = 'bool',
			value = ud.customParams.initcloaked,
			path = path,
			noHotkey = true,
		}
		options_order[#options_order+1] = defName .. "_personal_cloak_0"
	end

	if ud.onOffable then
		options[defName .. "_activateWhenBuilt"] = {
			name = "  On/Off State",
			desc = "Check box to set the unit to On when built.",
			type = 'bool',
			value = ud.activateWhenBuilt,
			path = path,
			noHotkey = true,
		}
		options_order[#options_order+1] = defName .. "_activateWhenBuilt"
	end
end

local function AddFactoryOfUnits(defName)
	if unitAlreadyAdded[defName] then
		return
	end
	local ud = UnitDefNames[defName]
	local name = string.gsub(ud.humanName, "/", "-")
	addUnit(defName, name)
	for i = 1, #ud.buildOptions do
		addUnit(UnitDefs[ud.buildOptions[i]].name, name)
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
AddFactoryOfUnits("missilesilo")

local buildOpts = VFS.Include("gamedata/buildoptions.lua")
local factory_commands, econ_commands, defense_commands, special_commands = include("Configs/integral_menu_commands.lua")

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

local function AmITeamLeader (teamID)
	return teamID == Spring.GetMyTeamID() and Spring.GetMyPlayerID() == select (2, Spring.GetTeamInfo (teamID))
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

function widget:UnitCreated(unitID, unitDefID, unitTeam, builderID)
	if not AmITeamLeader (unitTeam) or not unitDefID or not UnitDefs[unitDefID] then
		return
	end

	local ud = UnitDefs[unitDefID]
	local orderArray = {}
	if ud.customParams.commtype or ud.customParams.level then
		local morphed = Spring.GetTeamRulesParam(unitTeam, "morphUnitCreating") == 1
		if morphed then -- unit states are applied in unit_morph gadget
			return
		end

		orderArray[1] = {CMD.FIRE_STATE, {options.commander_firestate0.value}, {"shift"}}
		orderArray[2] = {CMD.MOVE_STATE, {options.commander_movestate1.value}, {"shift"}}
		if WG['retreat'] then
			WG['retreat'].addRetreatCommand(unitID, unitDefID, options.commander_retreat.value)
		end
	end

	local name = ud.name
	if unitAlreadyAdded[name] then
		if options[name .. "_firestate0"] and options[name .. "_firestate0"].value then
			if options[name .. "_firestate0"].value == -1 then
				if builderID then
					local bdid = Spring.GetUnitDefID(builderID)
					if UnitDefs[bdid] and UnitDefs[bdid].isFactory then
						local firestate = Spring.GetUnitStates(builderID).firestate
						if firestate then
							orderArray[#orderArray + 1] = {CMD.FIRE_STATE, {firestate}, {"shift"}}
						end
					end
				end
			else
				orderArray[#orderArray + 1] = {CMD.FIRE_STATE, {options[name .. "_firestate0"].value}, {"shift"}}
			end
		end

		if options[name .. "_movestate1"] and options[name .. "_movestate1"].value then
			if options[name .. "_movestate1"].value == -1 then
				if builderID then
					local bdid = Spring.GetUnitDefID(builderID)
					if UnitDefs[bdid] and UnitDefs[bdid].isFactory then
						local movestate = Spring.GetUnitStates(builderID).movestate
						if movestate then
							orderArray[#orderArray + 1] = {CMD.MOVE_STATE, {movestate}, {"shift"}}
						end
					end
				end
			else
				orderArray[#orderArray + 1] = {CMD.MOVE_STATE, {options[name .. "_movestate1"].value}, {"shift"}}
			end
		end

		if options[name .. "_flylandstate_1"] and options[name .. "_flylandstate_1"].value then
			--NOTE: The unit_air_plants gadget deals with inherit
			if options[name .. "_flylandstate_1"].value ~= -1 then  --if not inherit
				orderArray[#orderArray + 1] = {CMD.IDLEMODE, {options[name .. "_flylandstate_1"].value}, {"shift"}}
			end
		end

		if options[name .. "_flylandstate_1_factory"] and options[name .. "_flylandstate_1_factory"].value then
			orderArray[#orderArray + 1] = {CMD_AP_FLY_STATE, {options[name .. "_flylandstate_1_factory"].value}, {"shift"}}
		end

		if options[name .. "_repeat"] and options[name .. "_repeat"].value ~= nil then
			orderArray[#orderArray + 1] = {CMD.REPEAT, {options[name .. "_repeat"].value and 1 or 0}, {"shift"}}
		end
		
		if options[name .. "_auto_assist"] and options[name .. "_auto_assist"].value ~= nil then
			orderArray[#orderArray + 1] = {CMD_FACTORY_GUARD, {options[name .. "_auto_assist"].value and 1 or 0}, {"shift"}}
		end
		
		if options[name .. "_airstrafe1"] and options[name .. "_airstrafe1"].value ~= nil then
			orderArray[#orderArray + 1] = {CMD_AIR_STRAFE, {options[name .. "_airstrafe1"].value and 1 or 0}, {"shift"}}
		end

		if options[name .. "_floattoggle"] and options[name .. "_floattoggle"].value ~= nil then
			orderArray[#orderArray + 1] = {CMD_UNIT_FLOAT_STATE, {options[name .. "_floattoggle"].value}, {"shift"}}
		end

		if options[name .. "_retreatpercent"] and options[name .. "_retreatpercent"].value then
			local retreat = options[name .. "_retreatpercent"].value
			if retreat == -1 then --if inherit
				if builderID then
					retreat = Spring.GetUnitRulesParam(builderID,"retreatState")
				else
					retreat = nil
				end
			end
			if retreat then
				if retreat == 0 then
					orderArray[#orderArray + 1] = {CMD_RETREAT, {0}, {"shift", "right"}}  -- to set retreat to 0, "right" option must be used
				else
					orderArray[#orderArray + 1] = {CMD_RETREAT, {retreat}, {"shift"}}
				end
			end
		end

		if options[name .. "_buildpriority_0"] and options[name .. "_buildpriority_0"].value then
			if options[name .. "_buildpriority_0"].value == -1 then
				if builderID then
					local priority = Spring.GetUnitRulesParam(builderID,"buildpriority")
					if priority then
						orderArray[#orderArray + 1] = {CMD_PRIORITY, {priority}, {"shift"}}
					end
				else
					orderArray[#orderArray + 1] = {CMD_PRIORITY, {1}, {"shift"}}
				end
			else
				orderArray[#orderArray + 1] = {CMD_PRIORITY, {options[name .. "_buildpriority_0"].value}, {"shift"}}
			end
		end

		if options[name .. "_misc_priority"] and options[name .. "_misc_priority"].value then
			if options[name .. "_misc_priority"].value ~= 1 then -- Medium is the default
				orderArray[#orderArray + 1] = {CMD_MISC_PRIORITY, {options[name .. "_misc_priority"].value}, {"shift"}}
			end
		end

		if options[name .. "_tactical_ai_2"] and options[name .. "_tactical_ai_2"].value ~= nil then
			orderArray[#orderArray + 1] = {CMD_UNIT_AI, {options[name .. "_tactical_ai_2"].value and 1 or 0}, {"shift"}}
		end

		if options[name .. "_fire_at_radar"] and options[name .. "_fire_at_radar"].value ~= nil then
			orderArray[#orderArray + 1] = {CMD_DONT_FIRE_AT_RADAR, {options[name .. "_fire_at_radar"].value and 0 or 1}, {"shift"}}
		end

		if options[name .. "_personal_cloak_0"] and options[name .. "_personal_cloak_0"].value ~= nil then
			orderArray[#orderArray + 1] = {CMD_WANT_CLOAK, {options[name .. "_personal_cloak_0"].value and 1 or 0}, {"shift"}}
		end
	end

	if #orderArray>0 then
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
	if options[name .. "_constructor_buildpriority"] and options[name .. "_constructor_buildpriority"].value then
		if options[name .. "_constructor_buildpriority"].value == -1 then
			local priority = Spring.GetUnitRulesParam(factID,"buildpriority")
			if priority then
				Spring.GiveOrderToUnit(unitID, CMD_PRIORITY, {priority}, {"shift"})
			end
		end
	end
end

function widget:UnitFinished(unitID, unitDefID, unitTeam)
	if not AmITeamLeader (unitTeam) or not unitDefID or not UnitDefs[unitDefID] or (Spring.GetTeamRulesParam(unitTeam, "morphUnitCreating") == 1) then
		return
	end

	local orderArray = {}
	if UnitDefs[unitDefID].customParams.commtype or UnitDefs[unitDefID].customParams.level then
		orderArray[1] = {CMD_PRIORITY, {options.commander_constructor_buildpriority.value}, {"shift"}}
		orderArray[2] = {CMD_MISC_PRIORITY, {options.commander_misc_priority.value}, {"shift"}}
	end

	local name = UnitDefs[unitDefID].name
	if options[name .. "_constructor_buildpriority"] and options[name .. "_constructor_buildpriority"].value then
		if options[name .. "_constructor_buildpriority"].value ~= -1 then
			orderArray[#orderArray + 1] = {CMD_PRIORITY, {options[name .. "_constructor_buildpriority"].value}, {"shift"}}
		end
	end
	if options[name .. "_activateWhenBuilt"] and options[name .. "_activateWhenBuilt"].value ~= nil then
		if options[name .. "_activateWhenBuilt"].value ~= UnitDefs[unitDefID].activateWhenBuilt then
			orderArray[#orderArray + 1] = {CMD.ONOFF, {options[name .. "_activateWhenBuilt"].value and 1 or 0}, {"shift"}}
		end
	end

	if #orderArray>0 then
		Spring.GiveOrderArrayToUnitArray ({unitID,},orderArray) --give out all orders at once
	end
	orderArray = nil
end

function widget:UnitGiven(unitID, unitDefID, newTeamID, teamID)
	widget:UnitCreated(unitID, unitDefID, newTeamID)
	widget:UnitFinished(unitID, unitDefID, newTeamID)
end

function widget:GameFrame(n)
	if n < 10 then
		return
	end
	local team = Spring.GetMyTeamID()
	local units = Spring.GetTeamUnits(team)
	if units then
		for i = 1, #units do
			widget:UnitCreated(units[i], Spring.GetUnitDefID(units[i]), team, nil)
			widget:UnitFinished(units[i], Spring.GetUnitDefID(units[i]), team)
		end
	end
	widgetHandler:RemoveCallIn("GameFrame")
end
