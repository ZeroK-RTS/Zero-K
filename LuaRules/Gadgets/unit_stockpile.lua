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
			resTable = {
				m = stockCost/stockTime,
				e = stockCost/stockTime
			}
		}
	end
end

function gadget:GameFrame(n)
	for i = 1, units.count do
		local unitID = units.data[i]
		local data = unitsByID[unitID]
		local stocked, queued = Spring.GetUnitStockpile(unitID)
		local stunned_or_inbuild, stunned, inbuild = Spring.GetUnitIsStunned(unitID) 
		local disarmed = (Spring.GetUnitRulesParam(unitID, "disarmed") == 1)
		local def = stockpileUnitDefID[data.unitDefID]
		if (not (stunned_or_inbuild or disarmed)) and queued > stocked  then
			if not data.active then
				if def.stockCost > 0 then
					GG.StartMiscPriorityResourcing(unitID,data.teamID,def.stockDrain)
				end
				data.active = true
			end

			if (def.stockCost == 0) or (GG.CheckMiscPriorityBuildStep(unitID, data.teamID, def.resTable.m) and Spring.UseUnitResource(unitID, def.resTable)) then
				data.progress = data.progress - 1
				if data.progress == 0 then
					Spring.SetUnitStockpile(unitID, stocked + 1)
					data.progress = def.stockTime
				end
				Spring.SetUnitRulesParam(unitID, "gadgetStockpile", (def.stockTime-data.progress)/def.stockTime)
			end
		else
			if data.active then
				if def.stockCost > 0 then
					GG.StopMiscPriorityResourcing(unitID,data.teamID)
				end
				data.active = false
			end
		end
	end
end

function gadget:UnitCreated(unitID, unitDefID, teamID)
	if stockpileUnitDefID[unitDefID] then
		local def = stockpileUnitDefID[unitDefID]
		units.count = units.count + 1
		units.data[units.count] = unitID
		unitsByID[unitID] = {
			id = units.count, --the "id" is the index in units.data table
			progress = def.stockTime, 
			unitDefID = unitDefID, 
			teamID = teamID, 
			active = false
		}
		if def.stockCost > 0 then
			GG.AddMiscPriorityUnit(unitID, teamID)
		end
	end
end

function gadget:UnitDestroyed(unitID, unitDefID, teamID)
	if stockpileUnitDefID[unitDefID] then
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
		unitsByID[unitID].active = false
	end
end

function gadget:Initialize()
	
	for _, unitID in ipairs(Spring.GetAllUnits()) do
		local unitDefID = Spring.GetUnitDefID(unitID)
		local teamID = Spring.GetUnitTeam(unitID)
		gadget:UnitCreated(unitID, unitDefID, teamID)
	end
end
