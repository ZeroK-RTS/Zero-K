--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
  return {
    name      = "Unit Start State",
    desc      = "Configurable starting unit states for units",
    author    = "GoogleFrog",
    date      = "13 April 2011",
    license   = "GNU GPL, v2 or later",
	handler   = true,
    layer     = 1,
    enabled   = true  --  loaded by default?
  }
end

local CMD_UNIT_AI = 36214
local CMD_PRIORITY = 34220
local CMD_AP_FLY_STATE = 34569
local CMD_RETREAT = 10000
local CMD_AIR_STRAFE = 39381


local holdPosException = { 
    ["factoryplane"] = true,
    ["factorygunship"] = true,
    ["armnanotc"] = true,
}

local rememberToSetHoldPositionPreset = false

local function IsGround(ud)
    return not ud.canFly
end

options_path = 'Game/Unit AI/Initial States'
options_order = { 'presetlabel', 'holdPosition', 'commander_label', 'commander_firestate', 'commander_movestate', 'commander_buildpriority', 'commander_retreat'}
options = {
	presetlabel = {name = "presetlabel", type = 'label', value = "Presets", path = options_path},

    holdPosition = {
		type='button',
		name= "Hold Position",
		desc = "Set all land units to hold position",
		OnChange = function ()
            rememberToSetHoldPositionPreset = true
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

    commander_movestate = {
        name = "  Movestate",
        desc = "Values: hold position, maneuver, roam",
        type = 'number',
        value = 1,
        min = 0,-- no factory/unit build comm (yet)
        max = 2,
        step = 1,
        path = "Game/Unit AI/Initial States/Misc",
    },

	commander_buildpriority = {
        name = "  Build Priority",
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
        options[defName .. "_movestate"] = {
            name = "  Movestate",
            desc = "Values: inherit from factory, hold position, maneuver, roam",
            type = 'number',
            value = ud.moveState,
            min = -1,
            max = 2,
            step = 1,
            path = path,
        }
        options_order[#options_order+1] = defName .. "_movestate"
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
	end
	
	if ud.customParams and ud.customParams.airstrafecontrol then
		options[defName .. "_airstrafe"] = {
			name = "  Air Strafe",
			desc = "Air Strafe: check box to turn it on",
			type = 'bool',
			value = 0,
			path = path,
		}
		options_order[#options_order+1] = defName .. "_airstrafe"
	end

	options[defName .. "_buildpriority"] = {
        name = "  Build Priority",
        desc = "Values: Low, Normal, High",
        type = 'number',
        value = 1,
        min = 0,
        max = 2,
        step = 1,
        path = path,
    }
	options_order[#options_order+1] = defName .. "_buildpriority"

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

    if tacticalAIUnits[defName] then
		options[defName .. "_tactical_ai"] = {
			name = "  Smart AI",
			desc = "Smart AI: check box to turn it on",
			type = 'bool',
			value = tacticalAIUnits[defName].value,
			path = path,
		}
		options_order[#options_order+1] = defName .. "_tactical_ai"
    end
    
    if ud.canCloak then
        options[defName .. "_personal_cloak"] = {
            name = "  Personal Cloak",
            desc = "Personal Cloak: check box to turn it on",
            type = 'bool',
            value = ud.startCloaked,
            path = path,
        }
        options_order[#options_order+1] = defName .. "_personal_cloak"
    
    end
	
end

local function AddFactoryOfUnits(defName)
	if unitAlreadyAdded[defName] then
        return
    end
	local ud = UnitDefNames[defName]
    local name = ud.humanName
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
        
        if UnitDefs[unitDefID].customParams.commtype or UnitDefs[unitDefID].customParams.level then
            Spring.GiveOrderToUnit(unitID, CMD.FIRE_STATE, {options.commander_firestate.value}, 0)
            Spring.GiveOrderToUnit(unitID, CMD.MOVE_STATE, {options.commander_movestate.value}, 0)
			Spring.GiveOrderToUnit(unitID, CMD_RETREAT, {options.commander_retreat.value}, 0)
			Spring.GiveOrderToUnit(unitID, CMD_PRIORITY, {options.commander_buildpriority.value}, 0)
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
                                Spring.GiveOrderToUnit(unitID, CMD.FIRE_STATE, {firestate}, 0)
                            end
                        end
                    end
                else
                    Spring.GiveOrderToUnit(unitID, CMD.FIRE_STATE, {options[name .. "_firestate"].value}, 0)
                end
            end
            
            if options[name .. "_movestate"] and options[name .. "_movestate"].value then
                if options[name .. "_movestate"].value == -1 then
                    if builderID then
                        local bdid = Spring.GetUnitDefID(builderID)
                        if UnitDefs[bdid] and UnitDefs[bdid].isFactory then
                            local movestate = Spring.GetUnitStates(builderID).movestate
                            if movestate then
                                Spring.GiveOrderToUnit(unitID, CMD.MOVE_STATE, {movestate}, 0)
                            end
                        end
                    end
                else
                    Spring.GiveOrderToUnit(unitID, CMD.MOVE_STATE, {options[name .. "_movestate"].value}, 0)
                end
            end

			if options[name .. "_flylandstate"] and options[name .. "_flylandstate"].value then
				if options[name .. "_flylandstate"].value == -1 then
					-- The unit_air_plants gadget does this bit.
					--[[ if builderID then
						local bdid = Spring.GetUnitDefID(builderID)
                        if UnitDefs[bdid] and UnitDefs[bdid].isFactory then	
							local flyState = Spring.GetUnitStates(builderID, "landFlyFactory")
							if flyState then
                                Spring.GiveOrderToUnit(unitID, CMD.IDLEMODE, {movestate}, 0)
                            end
						end
					end--]]
				else
                    Spring.GiveOrderToUnit(unitID, CMD.IDLEMODE, {options[name .. "_flylandstate"].value}, 0)
                end
			end

			if options[name .. "_airstrafe"] and options[name .. "_airstrafe"].value ~= nil then
				Spring.GiveOrderToUnit(unitID, CMD_AIR_STRAFE, {options[name .. "_airstrafe"].value and 1 or 0}, 0)
			end

			if options[name .. "_retreatpercent"] and options[name .. "_retreatpercent"].value then
				if options[name .. "_retreatpercent"].value == -1 then
					if builderID then
						local bdid = Spring.GetUnitDefID(builderID)
						if UnitDefs[bdid] and UnitDefs[bdid].isFactory then
							local retreat = Spring.GetUnitStates(builderID).retreat
							if retreat then
								Spring.GiveOrderToUnit(unitID, CMD_RETREAT, {_retreatpercent}, 0)
							end
						end
					end
				else
					Spring.GiveOrderToUnit(unitID, CMD_RETREAT, {options[name .. "_retreatpercent"].value}, 0)
					--WG['retreat'].addRetreatCommand(unitID, unitDefID, 2) -> overriden by factory setting @factory exit.
				end
			end

			if options[name .. "_buildpriority"] and options[name .. "_buildpriority"].value then
				Spring.GiveOrderToUnit(unitID, CMD_PRIORITY, {options[name .. "_buildpriority"].value}, 0)
			end
			
            if options[name .. "_tactical_ai"] and options[name .. "_tactical_ai"].value ~= nil then
                Spring.GiveOrderToUnit(unitID, CMD_UNIT_AI, {options[name .. "_tactical_ai"].value and 1 or 0}, 0)
            end
            
            if options[name .. "_personal_cloak"] and options[name .. "_personal_cloak"].value ~= nil then
                Spring.GiveOrderToUnit(unitID, CMD.CLOAK, {options[name .. "_personal_cloak"].value and 1 or 0}, 0)
            end
            
        end
    end
end

function widget:UnitTaken(unitID, unitDefID, newTeamID, teamID)
  widget:UnitCreated(unitID, unitDefID, newTeamID)
end

function widget:GameFrame(n)
	if n == 10 then
		local team = Spring.GetMyTeamID()
		local units = Spring.GetTeamUnits(team)
		if units then
			for i = 1, #units do
				widget:UnitCreated(units[i], Spring.GetUnitDefID(units[i]), team, nil)
			end
		end
	end
end

function widget:Update()
    if rememberToSetHoldPositionPreset then
        for i = 1, #options_order do
            local opt = options_order[i]
            local find = string.find(opt, "_movestate")
            local name = find and string.sub(opt,0,find-1)
            local ud = name and UnitDefNames[name]
            if ud and not holdPosException[name] and IsGround(ud) then
                options[opt].value = 0
            end
        end
        rememberToSetHoldPositionPreset = false
    end
end