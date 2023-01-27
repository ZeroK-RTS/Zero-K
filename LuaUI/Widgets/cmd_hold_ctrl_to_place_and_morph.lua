function widget:GetInfo()
	return {
		name      = "Hold Ctrl during placement to morph",
		desc      = "Hold the Ctrl key while placing a Cornea, Aegis, Radar Tower or Geothermal Reactor to issue a morph order to the nanoframe when it's created (which will make it start morphing once finished).",
		author    = "dunno", -- the author is known, "dunno" is the nickname
		date      = "2022-05-18",
		license   = "MIT",
		layer     = 0,
		enabled   = true
	}
end

options_path = 'Settings/Unit Behaviour'
options = {
	enable_automorph = {
		name = 'Morph buildings when placed with Ctrl',
		desc = "If queued holding Ctrl, morphable buildings will start morphing when finished.",
		type = 'bool',
		value = false, -- not polished enough, see FIXMEs below
		OnChange = function(self)
			local callins =
				{ "UnitCommand"
				, "UnitCreated"
				, "UnitDestroyed"
				, "UnitIdle"
				, "UnitTaken"
				, "PlayerChanged"
			}
			local func = self.value and widgetHandler.UpdateCallIn or widgetHandler.RemoveCallIn
			for i = 1, #callins do
				func(widgetHandler, callins[i])
			end
		end,
		noHotkey = true,
	},
}

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

function widget:PlayerChanged()
	myTeamID = Spring.GetMyTeamID()
end

function widget:Initialize()
	widget:PlayerChanged()
	options.enable_automorph:OnChange()
end

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

	--[[ FIXME 1: SPACE is captured elsewhere and
	     doesn't work for inserting a morphable.

	     FIXME 2: CTRL conflicts with dragging a
	     rectangle when SHIFT is also held. Ideally
	     the feature would not enable itself if
	     dragging a rectangle, but that is not as
	     simple as disabling SHIFT (would also ruin
	     queuing). ]]
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
