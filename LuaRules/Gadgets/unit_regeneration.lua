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
local spGetUnitRulesParam = Spring.GetUnitRulesParam
local spSetUnitRulesParam = Spring.SetUnitRulesParam

local units = {}
local unitList = {}
local unitCount = 0
local regenDefs = {}
local losTable = {inlos = true}

for id, def in pairs(UnitDefs) do
	regenDefs[id] = {idleTime = def.idleTime, rate = def.customParams.idle_regen / 2 }
end

local currentFrame
function gadget:Initialize()
	currentFrame = Spring.GetGameFrame()
end

function gadget:GameFrame (frame)
	currentFrame = frame
	if ((frame % 15) == 7) then
		local setParam = ((frame % 30) == 7)
		local unitID, data, slowMult, amount, health
		for i = 1, unitCount do
			unitID = unitList[i]
			data = units[unitID]
			if (data.idleFrame < frame) and (not spGetUnitIsStunned(unitID)) and (spGetUnitRulesParam(unitID, "disarmed") ~= 1) then
				slowMult = (1-(spGetUnitRulesParam(unitID,"slowState") or 0))
				amount = data.rate * slowMult
				health = spGetUnitHealth(unitID)
				if health then
					spSetUnitHealth(unitID, health + amount)
				end
			end
			if setParam then
				spSetUnitRulesParam(unitID, "idleRegenTimer", data.idleFrame - frame, losTable)
			end
		end
	end
end

local function SetUnitIdleRegen(unitID, idleTime, idleRate)
	if units[unitID] then
		units[unitID].idleFrame = 0
		units[unitID].idleTime = idleTime
		units[unitID].rate = idleRate
	else
		unitCount = unitCount + 1
		unitList[unitCount] = unitID
		units[unitID] = {
			idleFrame = 0, 
			idleTime = idleTime, 
			rate = idleRate,
			index = unitCount
		}
	end
end

function gadget:UnitCreated(unitID, unitDefID)
	SetUnitIdleRegen(unitID, regenDefs[unitDefID].idleTime, regenDefs[unitDefID].rate)

	local regen = Spring.GetUnitRulesParam(unitID, "comm_autorepair_rate")
	if regen then
		SetUnitIdleRegen(unitID, 0, regen / 2)
	end
end

function gadget:UnitDamaged(unitID, unitDefID, unitTeam, damage)
	if units[unitID] then
		units[unitID].idleFrame = currentFrame + units[unitID].idleTime
		spSetUnitRulesParam(unitID, "idleRegenTimer", units[unitID].idleTime, losTable)
	end
end

function gadget:UnitDestroyed(unitID)
	if units[unitID] then
		local index = units[unitID].index
		unitList[index] = unitList[unitCount]
		units[unitList[index]].index = index
		unitList[unitCount] = nil
		unitCount = unitCount - 1
		units[unitID] = nil
	end
end

function gadget:Initialize()
	GG.SetUnitIdleRegen = SetUnitIdleRegen

	for _, unitID in ipairs(Spring.GetAllUnits()) do
		local unitDefID = Spring.GetUnitDefID(unitID)
		gadget:UnitCreated(unitID, unitDefID)
	end
end