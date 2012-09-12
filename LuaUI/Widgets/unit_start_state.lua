--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
  return {
    name      = "Unit Start State",
    desc      = "Configurable starting unit states for units",
    author    = "GoogleFrog",
    date      = "13 April 2011",
    license   = "GNU GPL, v2 or later",
	handler   = false,
    layer     = 1,
    enabled   = true  --  loaded by default?
  }
end

VFS.Include("LuaRules/Configs/customcmds.h.lua")


local holdPosException = { 
    ["factoryplane"] = true,
    ["factorygunship"] = true,
    ["armnanotc"] = true,
}

local dontFireAtRadarUnits = {
	[UnitDefNames["armsnipe"].id] = true,
	[UnitDefNames["armmanni"].id] = true,
	[UnitDefNames["armanni"].id] = true,
}

--local rememberToSetHoldPositionPreset = false

local function IsGround(ud)
    return not ud.canFly
end

options_path = 'Game/Unit AI/Initial States'
options_order = { 'presetlabel', 'holdPosition', 'disableTacticalAI', 'enableTacticalAI', 'categorieslabel', 'commander_label', 'commander_firestate', 'commander_movestate1', 'commander_constructor_buildpriority', 'commander_retreat'}
options = {
	presetlabel = {name = "presetlabel", type = 'label', value = "Presets", path = options_path},

    holdPosition = {
		type='button',
		name= "Hold Position",
		desc = "Set all land units to hold position",
		path = "Game/Unit AI/Initial States/Presets",
		OnChange = function ()
			for i = 1, #options_order do
				local opt = options_order[i]
				local find = string.find(opt, "_movestate1")
				local name = find and string.sub(opt,0,find-1)
				local ud = name and UnitDefNames[name]
				if ud and not holdPosException[name] and IsGround(ud) then
					options[opt].value = 0
					--return
				end
			end
			
        end,
	},
	
	categorieslabel = {name = "presetlabel", type = 'label', value = "Categories", path = options_path},
	
	disableTacticalAI = {
		type='button',
		name= "Disable Tactical AI",
		desc = "Disables tactical AI (jinking and skirming) for all units.",
		path = "Game/Unit AI/Initial States/Presets",
		OnChange = function ()
			for i = 1, #options_order do
				local opt = options_order[i]
				local find = string.find(opt, "_tactical_ai")
				local name = find and string.sub(opt,0,find-1)
				local ud = name and UnitDefNames[name]
				if ud then
					options[opt].value = false
				end
			end
			
        end,
	},
	enableTacticalAI = {
		type='button',
		name= "Enable Tactical AI",
		desc = "Enables tactical AI (jinking and skirming) for all units.",
		path = "Game/Unit AI/Initial States/Presets",
		OnChange = function ()
			for i = 1, #options_order do
				local opt = options_order[i]
				local find = string.find(opt, "_tactical_ai")
				local name = find and string.sub(opt,0,find-1)
				local ud = name and UnitDefNames[name]
				if ud then
					options[opt].value = true
				end
			end
			
        end,
	},

    commander_label = {
        name = "label", 
        type = 'label', 
        value = "Commander",
        path = "Game/Unit AI/Initial States/Misc",
    },

    commander_firestate = {
        name = "  Firestate",
        desc = "Values: hold fire, return fire, fire at will",
        type = 'number',
        value = 2, -- commander are fire@will by default
        min = 0, -- most firestates are -1 but no factory/unit build comm (yet)
        max = 2,
        step = 1,
        path = "Game/Unit AI/Initial States/Misc",
    },

    commander_movestate1 = {
        name = "  Movestate",
        desc = "Values: hold position, maneuver, roam",
        type = 'number',
        value = 1,
        min = 0,-- no factory/unit build comm (yet)
        max = 2,
        step = 1,
        path = "Game/Unit AI/Initial States/Misc",
    },
--[[
	commander_buildpriority_0 = {
        name = "  Nanoframe Build Priority",
        desc = "Values: Inherit, Low, Normal, High",
        type = 'number',
        value = -1,
        min = -1,
        max = 2,
        step = 1,
        path = "Game/Unit AI/Initial States/Misc",
    },
--]]	
	commander_constructor_buildpriority = {
		name = "  Constructor Build Priority",
		desc = "Values: Low, Normal, High",
		type = 'number',
		value = 1,
		min = 0,
		max = 2,
		step = 1,
		path = "Game/Unit AI/Initial States/Misc",
	},
	
	commander_retreat = {
		name = "  Retreat at value",
		desc = "Values: no retreat, 30%, 60%, 90% health remaining",
        type = 'number',
        value = 0,
        min = 0,
        max = 3,
        step = 1,
        path = "Game/Unit AI/Initial States/Misc",
    },
}

local tacticalAIDefs, behaviourDefaults = VFS.Include("LuaRules/Configs/tactical_ai_defs.lua", nil, VFS.ZIP)

local tacticalAIUnits = {}

for unitDefName, behaviourData in pairs(tacticalAIDefs) do
    tacticalAIUnits[unitDefName] = {value = (behaviourData.defaultAIState or behaviourDefaults.defaultState) == 1}
end

local unitAlreadyAdded = {}

local function addLabel(text, path) -- doesn't work with order
    path = (path and "Game/Unit AI/Initial States/" .. path) or "Game/Unit AI/Initial States"
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
    
    path = "Game/Unit AI/Initial States/" .. path
    local ud = UnitDefNames[defName]
    if not ud then
		Spring.Echo("Initial States invalid unit " .. defName)
		return
	end
	
    options[defName .. "_label"] = {
        name = "label", 
        type = 'label', 
        value = ud.humanName,
        path = path,
    }
    options_order[#options_order+1] = defName .. "_label"
    
    if ud.canAttack or ud.isFactory then
        options[defName .. "_firestate"] = {
            name = "  Firestate",
            desc = "Values: inherit from factory, hold fire, return fire, fire at will",
            type = 'number',
            value = ud.fireState, -- most firestates are -1
            min = -1,
            max = 2,
            step = 1,
            path = path,
        }
        options_order[#options_order+1] = defName .. "_firestate"
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
		options[defName .. "_flylandstate"] = {
            name = "  Fly/Land State",
            desc = "Values: inherit from factory, fly, land",
            type = 'number',
            value = (ud.customParams and ud.customParams.landflystate and ((ud.customParams.landflystate == "1" and 1) or 0)) or -1,
            min = -1,
            max = 1,
            step = 1,
            path = path,
        }
		options_order[#options_order+1] = defName .. "_flylandstate"
		
		options[defName .. "_autorepairlevel1"] = {
            name = "  Auto Repair to airpad",
            desc = "Values: inherit from factory, no autorepair, 30%, 50%, 80% health remaining",
            type = 'number',
            value = -1,
            min = -1,
            max = 3,
            step = 1,
            path = path,
        }
		options_order[#options_order+1] = defName .. "_autorepairlevel1"
	elseif ud.customParams and ud.customParams.landflystate then
		options[defName .. "_flylandstate_factory"] = {
            name = "  Fly/Land State for factory",
            desc = "Values: fly, land",
            type = 'number',
            value = (ud.customParams and ud.customParams.landflystate and ud.customParams.landflystate == "1" and 1) or 0,
            min = 0,
            max = 1,
            step = 1,
            path = path,
        }
		options_order[#options_order+1] = defName .. "_flylandstate_factory"
		
		options[defName .. "_autorepairlevel_factory"] = {
            name = "  Auto Repair to airpad",
            desc = "Values: no autorepair, 30%, 50%, 80% health remaining",
            type = 'number',
            value = 0, -- auto repair is stupid
            min = 0,
            max = 3,
            step = 1,
            path = path,
        }
		options_order[#options_order+1] = defName .. "_autorepairlevel_factory"
	end
	
	if ud.customParams and ud.customParams.airstrafecontrol then
		options[defName .. "_airstrafe"] = {
			name = "  Air Strafe",
			desc = "Air Strafe: check box to turn it on",
			type = 'bool',
			value = true,
			path = path,
		}
		options_order[#options_order+1] = defName .. "_airstrafe"
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
	
	
	if (ud.canMove or ud.isFactory) then
		options[defName .. "_retreatpercent"] = {
			name = "  Retreat at value",
			desc = "Values: inherit from factory, no retreat, 30%, 60%, 90% health remaining",
			type = 'number',
			value = -1,
			min = -1,
			max = 3,
			step = 1,
			path = path,
		}
		options_order[#options_order+1] = defName .. "_retreatpercent"
	end

    if tacticalAIUnits[defName] or (ud.customParams and ud.customParams.usetacai) then
		options[defName .. "_tactical_ai"] = {
			name = "  Smart AI",
			desc = "Smart AI: check box to turn it on",
			type = 'bool',
			value = (tacticalAIUnits[defName] and tacticalAIUnits[defName].value) or (ud.customParams and ud.customParams.usetacai) or 1,
			path = path,
		}
		options_order[#options_order+1] = defName .. "_tactical_ai"
    end
    
	if dontFireAtRadarUnits[ud.id] then
		options[defName .. "_fire_at_radar"] = {
            name = "  Fire at radar",
            desc = "Check box to make these units fire at radar. All other units fire at radar but these have the option not to.",
            type = 'bool',
            value = true,
            path = path,
        }
        options_order[#options_order+1] = defName .. "_fire_at_radar"
	end
	
    if ud.canCloak then
        options[defName .. "_personal_cloak_0"] = {
            name = "  Personal Cloak",
            desc = "Personal Cloak: check box to turn it on",
            type = 'bool',
            value = ud.startCloaked,
            path = path,
        }
        options_order[#options_order+1] = defName .. "_personal_cloak_0"
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
AddFactoryOfUnits("corsy")

addUnit("striderhub","Mech")
addUnit("armcsa","Mech")
addUnit("armcomdgun","Mech")
addUnit("dante","Mech")
addUnit("armraven","Mech")
addUnit("armbanth","Mech")
addUnit("gorg","Mech")
addUnit("armorco","Mech")

local buildOpts = VFS.Include("gamedata/buildoptions.lua")
local _, _, factory_commands, econ_commands, defense_commands, special_commands, _, _, _ = include("Configs/integral_menu_commands.lua")

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

function widget:UnitCreated(unitID, unitDefID, unitTeam, builderID) 
	if unitTeam == Spring.GetMyTeamID() and unitDefID and UnitDefs[unitDefID] then
		local orderArray={}
        if UnitDefs[unitDefID].customParams.commtype or UnitDefs[unitDefID].customParams.level then
			-- Spring.GiveOrderToUnit(unitID, CMD.FIRE_STATE, {options.commander_firestate.value}, {"shift"})
            -- Spring.GiveOrderToUnit(unitID, CMD.MOVE_STATE, {options.commander_movestate1.value}, {"shift"})
			-- Spring.GiveOrderToUnit(unitID, CMD_RETREAT, {options.commander_retreat.value}, {"shift"})
			orderArray[1] = {CMD.FIRE_STATE, {options.commander_firestate.value}, {"shift"}}
			orderArray[2] = {CMD.MOVE_STATE, {options.commander_movestate1.value}, {"shift"}}
			orderArray[3] = {CMD_RETREAT, {options.commander_retreat.value}, {"shift"}}
        end
        
        local name = UnitDefs[unitDefID].name
        if unitAlreadyAdded[name] then
            
            if options[name .. "_firestate"] and options[name .. "_firestate"].value then
                if options[name .. "_firestate"].value == -1 then
                    if builderID then
                        local bdid = Spring.GetUnitDefID(builderID)
                        if UnitDefs[bdid] and UnitDefs[bdid].isFactory then
                            local firestate = Spring.GetUnitStates(builderID).firestate
                            if firestate then
                                --Spring.GiveOrderToUnit(unitID, CMD.FIRE_STATE, {firestate}, {"shift"})
								orderArray[#orderArray + 1] = {CMD.FIRE_STATE, {firestate}, {"shift"}}
                            end
                        end
                    end
                else
                    --Spring.GiveOrderToUnit(unitID, CMD.FIRE_STATE, {options[name .. "_firestate"].value}, {"shift"})
					orderArray[#orderArray + 1] = {CMD.FIRE_STATE, {options[name .. "_firestate"].value}, {"shift"}}
                end
            end
            
            if options[name .. "_movestate1"] and options[name .. "_movestate1"].value then
                if options[name .. "_movestate1"].value == -1 then
                    if builderID then
                        local bdid = Spring.GetUnitDefID(builderID)
                        if UnitDefs[bdid] and UnitDefs[bdid].isFactory then
                            local movestate = Spring.GetUnitStates(builderID).movestate
                            if movestate then
                                --Spring.GiveOrderToUnit(unitID, CMD.MOVE_STATE, {movestate}, {"shift"})
								orderArray[#orderArray + 1] = {CMD.MOVE_STATE, {movestate}, {"shift"}}
                            end
                        end
                    end
                else
                    --Spring.GiveOrderToUnit(unitID, CMD.MOVE_STATE, {options[name .. "_movestate1"].value}, {"shift"})
					orderArray[#orderArray + 1] = {CMD.MOVE_STATE, {options[name .. "_movestate1"].value}, {"shift"}}
                end
            end

			if options[name .. "_flylandstate"] and options[name .. "_flylandstate"].value then
				if options[name .. "_flylandstate"].value ~= -1 then -- The unit_air_plants gadget deals with inherit
					--Spring.GiveOrderToUnit(unitID, CMD.IDLEMODE, {options[name .. "_flylandstate"].value}, {"shift"})
					orderArray[#orderArray + 1] = {CMD.IDLEMODE, {options[name .. "_flylandstate"].value}, {"shift"}}
                end
			end
			
			if options[name .. "_flylandstate_factory"] and options[name .. "_flylandstate_factory"].value then
				--Spring.GiveOrderToUnit(unitID, CMD_AP_FLY_STATE, {options[name .. "_flylandstate_factory"].value}, {"shift"})
				orderArray[#orderArray + 1] = {CMD_AP_FLY_STATE, {options[name .. "_flylandstate_factory"].value}, {"shift"}}
			end
			
			if options[name .. "_autorepairlevel_factory"] and options[name .. "_autorepairlevel_factory"].value then
				--Spring.GiveOrderToUnit(unitID, CMD_AP_FLY_STATE, {options[name .. "_autorepairlevel_factory"].value}, {"shift"})
				orderArray[#orderArray + 1] = {CMD_AP_FLY_STATE, {options[name .. "_autorepairlevel_factory"].value}, {"shift"}}
			end
			
			if options[name .. "_autorepairlevel1"] and options[name .. "_autorepairlevel1"].value then
				if options[name .. "_autorepairlevel1"].value ~= -1 then  -- The unit_air_plants gadget deals with inherit
					--Spring.GiveOrderToUnit(unitID, CMD.AUTOREPAIRLEVEL, {options[name .. "_autorepairlevel1"].value}, {"shift"})
					orderArray[#orderArray + 1] = {CMD.AUTOREPAIRLEVEL, {options[name .. "_autorepairlevel1"].value}, {"shift"}}
				elseif not builderID then
					-- Spring.GiveOrderToUnit(unitID, CMD.AUTOREPAIRLEVEL, {0}, {"shift"})
					orderArray[#orderArray + 1] = {CMD.AUTOREPAIRLEVEL, {0}, {"shift"}}
				end
			end

			if options[name .. "_airstrafe"] and options[name .. "_airstrafe"].value ~= nil then
				-- Spring.GiveOrderToUnit(unitID, CMD_AIR_STRAFE, {options[name .. "_airstrafe"].value and 1 or 0}, {"shift"})
				orderArray[#orderArray + 1] = {CMD_AIR_STRAFE, {options[name .. "_airstrafe"].value and 1 or 0}, {"shift"}}
			end
			
			if options[name .. "_floattoggle"] and options[name .. "_floattoggle"].value ~= nil then
				-- Spring.GiveOrderToUnit(unitID, CMD_UNIT_FLOAT_STATE, {options[name .. "_floattoggle"].value}, {"shift"})
				orderArray[#orderArray + 1] = {CMD_UNIT_FLOAT_STATE, {options[name .. "_floattoggle"].value}, {"shift"}}
			end

			if options[name .. "_retreatpercent"] and options[name .. "_retreatpercent"].value then
				if options[name .. "_retreatpercent"].value == -1 then
					if builderID then
						local bdid = Spring.GetUnitDefID(builderID)
						if UnitDefs[bdid] and UnitDefs[bdid].isFactory then
							local retreat = Spring.GetUnitStates(builderID).retreat
							if retreat then
								-- Spring.GiveOrderToUnit(unitID, CMD_RETREAT, {_retreatpercent}, {"shift"})
								orderArray[#orderArray + 1] = {CMD_RETREAT, {_retreatpercent}, {"shift"}}
							end
						end
					end
				else
					-- Spring.GiveOrderToUnit(unitID, CMD_RETREAT, {options[name .. "_retreatpercent"].value}, {"shift"})
					orderArray[#orderArray + 1] = {CMD_RETREAT, {options[name .. "_retreatpercent"].value}, {"shift"}}
					--WG['retreat'].addRetreatCommand(unitID, unitDefID, 2) -> overriden by factory setting @factory exit.
				end
			end

			if options[name .. "_buildpriority_0"] and options[name .. "_buildpriority_0"].value then
				if options[name .. "_buildpriority_0"].value == -1 then
					if builderID then
						local priority = Spring.GetUnitRulesParam(builderID,"buildpriority")
						if priority then
							-- Spring.GiveOrderToUnit(unitID, CMD_PRIORITY, {priority}, {"shift"})
							orderArray[#orderArray + 1] = {CMD_PRIORITY, {priority}, {"shift"}}
						end
					else
						-- Spring.GiveOrderToUnit(unitID, CMD_PRIORITY, {1}, {"shift"})
						orderArray[#orderArray + 1] = {CMD_PRIORITY, {1}, {"shift"}}
					end
				else
					-- Spring.GiveOrderToUnit(unitID, CMD_PRIORITY, {options[name .. "_buildpriority_0"].value}, {"shift"})
					orderArray[#orderArray + 1] = {CMD_PRIORITY, {options[name .. "_buildpriority_0"].value}, {"shift"}}
				end
			end
			
            if options[name .. "_tactical_ai"] and options[name .. "_tactical_ai"].value ~= nil then
                -- Spring.GiveOrderToUnit(unitID, CMD_UNIT_AI, {options[name .. "_tactical_ai"].value and 1 or 0}, {"shift"})
				orderArray[#orderArray + 1] = {CMD_UNIT_AI, {options[name .. "_tactical_ai"].value and 1 or 0}, {"shift"}}
            end
			
            if options[name .. "_fire_at_radar"] and options[name .. "_fire_at_radar"].value ~= nil then
                -- Spring.GiveOrderToUnit(unitID, CMD_DONT_FIRE_AT_RADAR, {options[name .. "_fire_at_radar"].value and 0 or 1}, {"shift"})
				orderArray[#orderArray + 1] = {CMD_DONT_FIRE_AT_RADAR, {options[name .. "_fire_at_radar"].value and 0 or 1}, {"shift"}}
            end
        end
		
		Spring.GiveOrderArrayToUnitArray ({unitID,},orderArray) --give out all orders at once
		orderArray = nil
    end
end

--[[
function widget:SelectionChanged(newSelection)
	for i=1,#newSelection do
		local unitID = newSelection[i]
		widget:UnitCreated(unitID, Spring.GetUnitDefID(unitID), Spring.GetMyTeamID()) 
	end
end
--]]

function widget:UnitFromFactory(unitID, unitDefID, unitTeam, factID, factDefID, userOrders)
	if unitTeam == Spring.GetMyTeamID() and unitDefID and UnitDefs[unitDefID] then
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
end

function widget:UnitFinished(unitID, unitDefID, unitTeam)
	if unitTeam == Spring.GetMyTeamID() and unitDefID and UnitDefs[unitDefID] then
        local orderArray = {}
		if UnitDefs[unitDefID].customParams.commtype or UnitDefs[unitDefID].customParams.level then
			-- Spring.GiveOrderToUnit(unitID, CMD_PRIORITY, {options.commander_constructor_buildpriority.value}, {"shift"})
			orderArray[1] = {CMD_PRIORITY, {options.commander_constructor_buildpriority.value}, {"shift"}}
        end
        
        local name = UnitDefs[unitDefID].name
		if options[name .. "_constructor_buildpriority"] and options[name .. "_constructor_buildpriority"].value then
			if options[name .. "_constructor_buildpriority"].value ~= -1 then
				-- Spring.GiveOrderToUnit(unitID, CMD_PRIORITY, {options[name .. "_constructor_buildpriority"].value}, {"shift"})
				orderArray[#orderArray + 1] = {CMD_PRIORITY, {options[name .. "_constructor_buildpriority"].value}, {"shift"}}
			end
		end
		
		if options[name .. "_personal_cloak_0"] and options[name .. "_personal_cloak_0"].value ~= nil then
			-- Spring.GiveOrderToUnit(unitID, CMD.CLOAK, {options[name .. "_personal_cloak_0"].value and 1 or 0}, {"shift"})
			orderArray[#orderArray + 1] = {CMD.CLOAK, {options[name .. "_personal_cloak_0"].value and 1 or 0}, {"shift"}}
		end
		Spring.GiveOrderArrayToUnitArray ({unitID,},orderArray) --give out all orders at once
		orderArray = nil
	end
end

function widget:UnitGiven(unitID, unitDefID, newTeamID, teamID)
	widget:UnitCreated(unitID, unitDefID, newTeamID)
	widget:UnitFinished(unitID, unitDefID, newTeamID)
end

function widget:GameFrame(n)
	if n >= 10 then
		local team = Spring.GetMyTeamID()
		local units = Spring.GetTeamUnits(team)
		if units then
			for i = 1, #units do
				widget:UnitCreated(units[i], Spring.GetUnitDefID(units[i]), team, nil)
			end
		end
		widgetHandler:RemoveCallIn("GameFrame")
	end
end

--[[
function widget:Update()
    if rememberToSetHoldPositionPreset then
        for i = 1, #options_order do
            local opt = options_order[i]
            local find = string.find(opt, "_movestate1")
            local name = find and string.sub(opt,0,find-1)
            local ud = name and UnitDefNames[name]
            if ud and not holdPosException[name] and IsGround(ud) then
                options[opt].value = 0
            end
        end
        rememberToSetHoldPositionPreset = false
    end
end
--]]