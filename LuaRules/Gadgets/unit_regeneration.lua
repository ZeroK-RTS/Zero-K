if not gadgetHandler:IsSyncedCode() then return end

function gadget:GetInfo() return {
	name    = "Regeneration",
	desc    = "Handles idle regeneration for air units",
	author  = "Sprung",
	date    = "2015-05-22",
	license = "PD",
	layer   = 0,
	enabled = true,
} end

local spGetUnitIsStunned  = Spring.GetUnitIsStunned
local spGetUnitHealth     = Spring.GetUnitHealth
local spSetUnitHealth     = Spring.SetUnitHealth

local units = {}
local regenDefs = {}

for id, def in pairs(UnitDefs) do
	if def.customParams.idle_regen then
		regenDefs[id] = { def.idleTime, def.customParams.idle_regen / 2 }
	end
end

local currentFrame
function gadget:Initialize ()
	currentFrame = Spring.GetGameFrame()
end

function gadget:GameFrame (frame)
	currentFrame = frame
	if ((frame % 15) == 7) then
		for unitID, data in pairs(units) do
			if (data[1] < frame) and (not spGetUnitIsStunned(unitID)) then
				local health = spGetUnitHealth(unitID) + data[2]
				spSetUnitHealth(unitID, health)
			end
		end
	end
end

function gadget:UnitCreated(unitID, unitDefID)
	if regenDefs[unitDefID] then
		units[unitID] = {0, regenDefs[unitDefID][2]}
	end
end

function gadget:UnitDamaged(unitID, unitDefID, unitTeam, damage)
	if regenDefs[unitDefID] then
		units[unitID][1] = currentFrame + regenDefs[unitDefID][1]
	end
end

function gadget:UnitDestroyed(unitID)
	units[unitID] = nil
end
