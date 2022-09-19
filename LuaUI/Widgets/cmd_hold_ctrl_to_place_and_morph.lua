function widget:GetInfo()
	return {
		name      = "Hold Ctrl during placement to morph",
		version   = '1.0',
		desc      = "Hold the Ctrl key while placing a Cornea, Aegis, Radar Tower or Geothermal Reactor to issue a morph order to the nanoframe when it's created (which will make it start morphing once finished).",
		author    = "dunno",
		date      = "2022-05-18",
		license   = "MIT",
		layer     = 0,
		enabled   = true
	}
end

---@alias UnitInternalName string
---@alias UnitDefId integer
---@alias UnitId integer

---@param names UnitInternalName[]
---@return table<UnitDefId, boolean>
local function CreateUnitDefIdSet(names)
	local result = {}
	for i = 1, #names do
		local name = names[i]
		result[UnitDefNames[name].id] = true
	end
	return result
end

local abs = math.abs
local spGetUnitPosition = Spring.GetUnitPosition
local spGiveOrderToUnit = Spring.GiveOrderToUnit
local CMD_MORPH = Spring.Utilities.CMD.MORPH

local myTeamID

local morphableUnitDefIds = CreateUnitDefIdSet({'staticjammer', 'staticshield', 'staticradar', 'energygeo'})

---@type table<UnitId,{x:number,z:number}[]>
local buildingsToMorphByBuilder = {}

function widget:Initialize()
	myTeamID = Spring.GetMyTeamID()
end
widget.PlayerChanged = widget.Initialize

function widget:UnitCommand(unitID, unitDefID, unitTeam, cmdId, cmdParams, cmdOpts, cmdTag)
	if cmdId > 0 
		or unitTeam ~= myTeamID 
		or not morphableUnitDefIds[-cmdId] 
		or not cmdOpts
		or not cmdParams[1]
		or not cmdParams[3]
	then 
		return 
	end

	local buildingsToMorph = buildingsToMorphByBuilder[unitID]
	local point = { x = cmdParams[1], z = cmdParams[3] }

	if cmdOpts.ctrl then
		if not buildingsToMorph then
			buildingsToMorph = {}
			buildingsToMorphByBuilder[unitID] = buildingsToMorph
		end
		buildingsToMorph[#buildingsToMorph + 1] = point
	elseif buildingsToMorph then
		for i = 1, #buildingsToMorph do
			local point2 = buildingsToMorph[i]
			if point2.x == point.x and point2.z == point.z then
				buildingsToMorph[i] = buildingsToMorph[#buildingsToMorph]
				buildingsToMorph[#buildingsToMorph] = nil
				break
			end
		end
	end
end

function widget:UnitCreated(unitID, unitDefID, unitTeam, builderID)
	if not morphableUnitDefIds[unitDefID] 
		or unitTeam ~= myTeamID 
		or not builderID then
		return
	end

	local buildingsToMorph = buildingsToMorphByBuilder[builderID]

	if not buildingsToMorph then 
		-- Spring.Echo('No buildings to morph!')
		return
	end


	local ux, uy, uz  = spGetUnitPosition(unitID)
	-- Spring.Echo('UnitCreated(unitDef = '..UnitDefs[unitDefID].name..', builderID = '..(builderID or 'nil')..', x = '..ux..', z = '..uz..')')

	for i = 1, #buildingsToMorph do
		-- Note: unit_building_starter.lua, which does something similar, uses a location tolerance of 16
		-- here. But this appears to be unnecessary for the morphable buildings considered here(?)
		-- (in fact, it workers with exact equality, but being defensive)

		local point2 = buildingsToMorph[i]
		if abs(point2.x - ux) < 1e-3 and abs(point2.z - uz) < 1e-3 then
			spGiveOrderToUnit(unitID, CMD_MORPH, {}, 0)
			return
		end
	end

	-- Spring.Echo('This building is not to be morphed!')
end

function widget:UnitDestroyed(unitID, unitDefID, unitTeam)
	buildingsToMorphByBuilder[unitID] = nil
end

widget.UnitIdle  = widget.UnitDestroyed
widget.UnitTaken = widget.UnitDestroyed