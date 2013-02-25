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

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local stockpileUnitDefID = {}
local units = {data = {}, count = 0}
local unitsByID = {}

for i=1,#UnitDefs do
	local udef = UnitDefs[i]
	if (udef.customParams.stockpiletime) then
		local stockTime = tonumber(udef.customParams.stockpiletime)*30
		local stockCost = tonumber(udef.customParams.stockpilecost)
		stockpileUnitDefID[i] = {
			stockTime = stockTime,
			stockCost = stockCost,
			stockDrain = stockCost/stockTime*32,
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
		if queued > stocked then
			local def = stockpileUnitDefID[data.unitDefID]
			if not data.active then
				GG.StartMiscPriorityResourcing(unitID,data.teamID,def.stockDrain)
				data.active = true
			end

			local allow = GG.CheckMiscPriorityBuildStep(unitID, data.teamID, def.resTable.m)
			if allow and (Spring.UseUnitResource(unitID, def.resTable)) then
				data.progress = data.progress - 1
				if data.progress == 0 then
					Spring.SetUnitStockpile(unitID, stocked + 1)
					data.progress = def.stockTime
				end
				Spring.SetUnitRulesParam(unitID, "gadgetStockpile", (def.stockTime-data.progress)/def.stockTime)
			end
		else
			if data.active then
				GG.StopMiscPriorityResourcing(unitID,data.teamID)
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
			id = units.count,
			progress = def.stockTime, 
			unitDefID = unitDefID, 
			teamID = teamID, 
			active = false
		}
		GG.AddMiscPriorityUnit(unitID, teamID)
	end
end

function gadget:UnitDestroyed(unitID, unitDefID, teamID)
	if stockpileUnitDefID[unitDefID] then
		units.data[unitsByID[unitID].id] = units.data[units.count]
		unitsByID[units.data[units.count]].id = unitsByID[unitID].id
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