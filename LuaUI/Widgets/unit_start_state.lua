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
    layer     = 0,
    enabled   = true  --  loaded by default?
  }
end

options_path = 'Settings/Unit AI/Initial States'
options_order = {}
options = {}

local tacticalAIDefs = VFS.Include("LuaRules/Configs/tactical_ai_defs.lua", nil, VFS.ZIP)

local tacticalAIUnits = {}

for unitDefName, behaviourData in pairs(tacticalAIDefs) do
	tacticalAIUnits[unitDefName] = true
end

local unitAlreadyAdded = {}

local function addLabel(text, path) -- doesn't work with order
	path = (path and "Settings/Unit AI/Initial States/" .. path) or "Settings/Unit AI/Initial States"
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
	
	path = "Settings/Unit AI/Initial States/" .. path
	local ud = UnitDefNames[defName]
	
	options[defName .. "_label"] = {
		name = "label", 
		type = 'label', 
		value = ud.humanName,
		path = path,
	}
	options_order[#options_order+1] = defName .. "_label"
	
	if ud.canAttack then
		options[defName .. "_firestate"] = {
			name = "Firestate",
			desc = "Values: inherit from factory, hold fire, return fire, fire at will",
			type = 'number',
			value = ud.fireState, -- no set firestate = -1
			min = -1,
			max = 2,
			step = 1,
			path = path,
		}
		options_order[#options_order+1] = defName .. "_firestate"
	end

	if ud.canMove then
		options[defName .. "_movestate"] = {
			name = "Movestate",
			desc = "Values: inherit from factory, hold positon, manuver, roam",
			type = 'number',
			value = -1, -- ud.movestate is always 2?
			min = -1,
			max = 2,
			step = 1,
			path = path,
		}
		options_order[#options_order+1] = defName .. "_movestate"
	end

	if tacticalAIUnits[defName] then
		options[defName .. "_tactical_ai"] = {
			name = "Smart AI",
			desc = "Values: check box to turn it on",
			type = 'bool',
			value = true,
			path = path,
		}
		options_order[#options_order+1] = defName .. "_tactical_ai"
	end
	
	if ud.canCloak then
		options[defName .. "_personal_cloak"] = {
			name = "Personal Cloak",
			desc = "Values: check box to turn it on",
			type = 'bool',
			value = ud.startCloaked,
			path = path,
		}
		options_order[#options_order+1] = defName .. "_personal_cloak"
	--
	end
	if ud.canBuild then
		options[defName .. "_priority"] = {
			name = "Priority",
			desc = "Values: low, normal, high",
			type = 'number',
			value = 1,
			min = 0,
			max = 2,
			step = 1,
			path = path,
		}
		options_order[#options_order+1] = defName .. "_priority"
	end
	--
end

local function AddFactoryOfUnits(defName)
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

addUnit("armcsa","Mech")
addUnit("armcomdgun","Mech")
addUnit("dante","Mech")
addUnit("armraven","Mech")
addUnit("armbanth","Mech")
addUnit("gorg","Mech")
addUnit("armorco","Mech")

addUnit("screamer","Heavy") --add test about buildings, not built units

--addUnit("comrecon1","Heavy") crash, maybe because unfound


local CMD_UNIT_AI = 36214

function widget:UnitCreated(unitID, unitDefID, unitTeam, builderID) 
	if unitTeam == Spring.GetMyTeamID() and unitDefID and UnitDefs[unitDefID] then
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
			
			if options[name .. "_tactical_ai"] and options[name .. "_tactical_ai"].value ~= nil then
				Spring.GiveOrderToUnit(unitID, CMD_UNIT_AI, {options[name .. "_tactical_ai"].value and 1 or 0}, 0)
			end
			
			if options[name .. "_personal_cloak"] and options[name .. "_personal_cloak"].value ~= nil then
				Spring.GiveOrderToUnit(unitID, CMD.CLOAK, {options[name .. "_personal_cloak"].value and 1 or 0}, 0)
			end
			--
			if options[name .. "_priority"] and options[name .. "_priority"].value then
				if options[name .. "_priority"].value == -1 then --will it fuX ?
					if builderID then
						local bdid = Spring.GetUnitDefID(builderID)
						--if UnitDefs[bdid] and UnitDefs[bdid].isFactory then
							local priority = Spring.GetUnitStates(builderID).priority
							if priority then
								Spring.GiveOrderToUnit(unitID, CMD_PRIORITY, {priority}, 0)
							end
						--end
					end
				else
					Spring.GiveOrderToUnit(unitID, CMD_PRIORITY, {options[name .. "_priority"].value}, 0)
				end
			end
			--
		end
	end
end

function widget:UnitGiven(unitID, unitDefID, newTeamID, teamID)
  widget:UnitCreated(unitID, unitDefID, newTeamID)
end
