function widget:GetInfo()
	return {
		name      = "Hold Ctrl during placement to morph",
		desc      = "Hold the Ctrl key while placing a Cornea, Aegis, Radar Tower or Geothermal Reactor to issue a morph order to the nanoframe when it's created (which will make it start morphing once finished).",
		author    = "dunno",
		date      = "2022-05-18",
		license   = "MIT",
		layer     = 0,
		enabled   = true
	}
end

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

	--[[ FIXME 1: CTRL gains other meanings when SHIFT is held,
	              this is rare given the current set of morphables
	              but it would be good to solve for modder reasons.

	     FIXME 2: SPACE is captured elsewhere and doesn't work. ]]
	if cmdOpts.ctrl then
		if not buildingsToMorph then
			buildingsToMorph = {}
			buildingsToMorphByBuilder[unitID] = buildingsToMorph
		end
		buildingsToMorph[#buildingsToMorph + 1] = point
	elseif buildingsToMorph then
		-- clear since the list may be stale, see UnitIdle
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
		return
	end

	local ux, uy, uz  = spGetUnitPosition(unitID)
	for i = 1, #buildingsToMorph do
		-- Note: unit_building_starter.lua, which does something similar, uses a location tolerance of 16
		-- here. But this appears to be unnecessary for the morphable buildings considered here(?)
		-- (in fact, it workers with exact equality, but being defensive)

		local point2 = buildingsToMorph[i]
		if abs(point2.x - ux) < 1e-3 and abs(point2.z - uz) < 1e-3 then
			spGiveOrderToUnit(unitID, CMD_MORPH, {}, 0)

			-- don't clear, see UnitIdle
			return
		end
	end
end

function widget:UnitDestroyed(unitID, unitDefID, unitTeam)
	buildingsToMorphByBuilder[unitID] = nil
end

--[[ Morph table isn't cleared when the order is finished,
     this is so that the repeat state works.

     The UnitIdle event may not be needed given it also gets
     cleared on UnitCommand but better be safe I guess. ]]
widget.UnitIdle  = widget.UnitDestroyed
widget.UnitTaken = widget.UnitDestroyed