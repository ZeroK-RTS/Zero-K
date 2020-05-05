if not Script.GetSynced() then return end

function gadget:GetInfo() return {
	name      = "Rezz Hp changer + effect",
	desc      = "Sets rezzed units to full hp",
	author    = "Google Frog, modified by Rafal & Meep",
	date      = "Nov 30, 2008",
	license   = "GNU GPL, v2 or later",
	layer     = 1000001, -- after awards, for GG.Awards to exist by Initialize
	enabled   = true,
} end

local spGetUnitCurrentCommand = Spring.GetUnitCurrentCommand
local spGetUnitHealth         = Spring.GetUnitHealth
local spGetUnitPosition       = Spring.GetUnitPosition
local spSetUnitHealth         = Spring.SetUnitHealth
local spSpawnCEG              = Spring.SpawnCEG

local GG_AddAwardPoints

local CMD_RESURRECT = CMD.RESURRECT

local units = {}
local unitsCount = 0

local costByDefID = {}
local sizeByDefID = {}
do
	local max = math.max
	for i = 1, #UnitDefs do
		local unitDef = UnitDefs[i]
		costByDefID[i] = unitDef.metalCost
		sizeByDefID[i] = max(unitDef.xsize, unitDef.zsize)
	end
end

function gadget:UnitCreated(unitID, unitDefID, teamID, builderID)
	if not builderID then
		return
	end

	if spGetUnitCurrentCommand(builderID) ~= CMD_RESURRECT then
		return
	end

	--[[ cannot do anything immediately, engine multiplies rezzed
	     unit health by 0.05 right *after* UnitCreated so their
	     health has to be changed 1 frame later ]]
	unitsCount = unitsCount + 1
	units[unitsCount] = unitID

	GG_AddAwardPoints("rezz", teamID, costByDefID[unitDefID])

	local ux, uy, uz = spGetUnitPosition(unitID)
	spSpawnCEG("resurrect", ux, uy, uz, 0, 0, 0, sizeByDefID[unitDefID])
end

function gadget:GameFrame(n)
	for i = 1, unitsCount do
		local unitID = units[i]
		local _, maxHealth = spGetUnitHealth(unitID)
		if maxHealth then
			--[[ needs a nil check since the 1 frame delay opens up
			     a window for the unit to have been removed ]]
			spSetUnitHealth(unitID, maxHealth)
		end
	end
	unitsCount = 0
end

function gadget:Initialize()
	GG_AddAwardPoints = GG.Awards.AddAwardPoints -- we're in a later layer so this should be guaranteed to exist
end
