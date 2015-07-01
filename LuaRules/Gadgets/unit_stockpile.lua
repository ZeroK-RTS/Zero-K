--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function gadget:GetInfo()
  return {
    name      = "Stockpile",
    desc      = "Partial reimplementation of stockpile system.",
    author    = "Google Frog",
    date      = "26 Feb, 2013",
    license   = "GNU GPL, v2 or later",
    layer     = -1,
    enabled   = true  --  loaded by default?
  }
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

if (not gadgetHandler:IsSyncedCode()) then
  return false  --  no unsynced code
end

include("LuaRules/Configs/constants.lua")

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local spGetUnitStockpile  = Spring.GetUnitStockpile
local spSetUnitStockpile  = Spring.SetUnitStockpile
local spGetUnitIsStunned  = Spring.GetUnitIsStunned
local spUseUnitResource   = Spring.UseUnitResource
local spGetUnitRulesParam = Spring.GetUnitRulesParam
local spSetUnitRulesParam = Spring.SetUnitRulesParam

local stockpileUnitDefID = {}
local units = {data = {}, count = 0}
local unitsByID = {}

for i=1,#UnitDefs do
	local udef = UnitDefs[i]
	if (udef.customParams.stockpiletime) then
		local stockTime = tonumber(udef.customParams.stockpiletime)*TEAM_SLOWUPDATE_RATE
		local stockCost = tonumber(udef.customParams.stockpilecost)
		stockpileUnitDefID[i] = {
			stockTime = stockTime,
			stockCost = stockCost,
			stockDrain = TEAM_SLOWUPDATE_RATE*stockCost/stockTime,
			perFrameCost = stockCost/stockTime,
		}
	end
end

local function GetStockSpeed(unitID)
	return (1 - (spGetUnitRulesParam(unitID,"slowState") or 0))
end

function gadget:GameFrame(n)
	for i = 1, units.count do
		local unitID = units.data[i]
		local data = unitsByID[unitID]
		local stocked, queued = spGetUnitStockpile(unitID)
		local stunned_or_inbuild, stunned, inbuild = spGetUnitIsStunned(unitID) 
		local disarmed = (spGetUnitRulesParam(unitID, "disarmed") == 1)
		local def = stockpileUnitDefID[data.unitDefID]
		if (not (stunned_or_inbuild or disarmed)) and queued > stocked  then
			
			local newStockSpeed = GetStockSpeed(unitID)
			if data.stockSpeed ~= newStockSpeed then
				if def.stockCost > 0 then
					if data.stockSpeed ~= 0 then
						GG.StopMiscPriorityResourcing(unitID,data.teamID)
					end
					GG.StartMiscPriorityResourcing(unitID,data.teamID,def.stockDrain*newStockSpeed)
				end
				data.stockSpeed = newStockSpeed
				data.resTable.m = def.perFrameCost*newStockSpeed
				data.resTable.e = data.resTable.m
			end

			if (def.stockCost == 0) or (GG.CheckMiscPriorityBuildStep(unitID, data.teamID, data.resTable.m) and spUseUnitResource(unitID, data.resTable)) then
				data.progress = data.progress - data.stockSpeed
				if data.progress <= 0 then
					spSetUnitStockpile(unitID, stocked + 1)
					data.progress = def.stockTime
				end
				spSetUnitRulesParam(unitID, "gadgetStockpile", (def.stockTime-data.progress)/def.stockTime)
			end
		else
			if data.stockSpeed ~= 0 then
				if def.stockCost > 0 then
					GG.StopMiscPriorityResourcing(unitID,data.teamID)
				end
				data.stockSpeed = 0
			end
		end
	end
end

function gadget:UnitFinished(unitID, unitDefID, teamID)
	if stockpileUnitDefID[unitDefID] and not unitsByID[unitID] then
		local def = stockpileUnitDefID[unitDefID]
		units.count = units.count + 1
		units.data[units.count] = unitID
		unitsByID[unitID] = {
			id = units.count, --the "id" is the index in units.data table
			progress = def.stockTime, 
			unitDefID = unitDefID, 
			teamID = teamID, 
			stockSpeed = 0, 
			resTable = {
				m = def.perFrameCost,
				e = def.perFrameCost
			}
		}
		if def.stockCost > 0 then
			GG.AddMiscPriorityUnit(unitID, teamID)
		end
	end
end

function gadget:UnitDestroyed(unitID, unitDefID, teamID)
	if unitsByID[unitID] then
		units.data[unitsByID[unitID].id] = units.data[units.count]
		unitsByID[units.data[units.count]].id = unitsByID[unitID].id --shift last entry into empty space
		units.data[units.count]	= nil
		units.count = units.count - 1
		unitsByID[unitID] = nil
	end
end

function gadget:UnitTaken(unitID, unitDefID, oldTeamID, teamID)
	if unitsByID[unitID] then
		unitsByID[unitID].teamID = teamID
		unitsByID[unitID].stockSpeed = 0
	end
end

function gadget:Initialize()
	
	for _, unitID in ipairs(Spring.GetAllUnits()) do
		local unitDefID = Spring.GetUnitDefID(unitID)
		local teamID = Spring.GetUnitTeam(unitID)
		gadget:UnitFinished(unitID, unitDefID, teamID)
	end
end
