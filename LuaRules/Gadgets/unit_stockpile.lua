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

local PERIOD = 6

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
			stockUpdates = stockTime/PERIOD,
			stockCost = stockCost,
			stockDrain = TEAM_SLOWUPDATE_RATE*stockCost/stockTime,
			perUpdateCost = PERIOD * stockCost/stockTime,
		}
	end
end

local function GetStockSpeed(unitID)
	return (spGetUnitRulesParam(unitID,"totalBuildPowerChange") or 1)
end

function gadget:GameFrame(n)
	if n%PERIOD ~= 0 then
		return
	end

	for i = 1, units.count do
		local unitID = units.data[i]
		local data = unitsByID[unitID]
		local stocked, queued = spGetUnitStockpile(unitID)
		local stunned_or_inbuild, stunned, inbuild = spGetUnitIsStunned(unitID) 
		local disarmed = (spGetUnitRulesParam(unitID, "disarmed") == 1)
		local def = stockpileUnitDefID[data.unitDefID]
		local cmdID = Spring.Utilities.GetUnitFirstCommand(unitID)
		local isWaiting = cmdID and (cmdID == CMD.WAIT)
		if (not (stunned_or_inbuild or disarmed)) and queued ~= 0 and not (isWaiting and (def.stockCost > 0)) then
			
			local newStockSpeed = GetStockSpeed(unitID)
			if data.stockSpeed ~= newStockSpeed then
				if def.stockCost > 0 then
					GG.StartMiscPriorityResourcing(unitID, def.stockDrain*newStockSpeed)
				end
				data.stockSpeed = newStockSpeed
			end

			if (def.stockCost > 0) then
				local scale = GG.GetMiscPrioritySpendScale(unitID, data.teamID)
				newStockSpeed = newStockSpeed*scale
				data.resTable.m = def.perUpdateCost*newStockSpeed
				data.resTable.e = data.resTable.m
			end
			
			if (def.stockCost == 0) or spUseUnitResource(unitID, data.resTable) then
				data.progress = data.progress - newStockSpeed
				if data.progress <= 0 then
					spSetUnitStockpile(unitID, stocked, 1)
					data.progress = def.stockUpdates
				end
				spSetUnitRulesParam(unitID, "gadgetStockpile", (def.stockUpdates - data.progress)/def.stockUpdates)
			end
		else
			if data.stockSpeed ~= 0 then
				if def.stockCost > 0 then
					GG.StopMiscPriorityResourcing(unitID)
				end
				data.stockSpeed = 0
			end
		end
	end
end


function gadget:StockpileChanged(unitID, unitDefID, unitTeam, weaponNum, oldCount, newCount)
	local scriptFunc = Spring.UnitScript.GetScriptEnv(unitID).StockpileChanged
	if scriptFunc then
		Spring.UnitScript.CallAsUnit(unitID, scriptFunc, newCount)
	end
end

function gadget:UnitCreated(unitID, unitDefID, teamID)
	if stockpileUnitDefID[unitDefID] and not unitsByID[unitID] then
		local def = stockpileUnitDefID[unitDefID]
		if def.stockCost > 0 then
			GG.AddMiscPriorityUnit(unitID)
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
			progress = def.stockUpdates, 
			unitDefID = unitDefID, 
			teamID = teamID, 
			stockSpeed = 0, 
			resTable = {
				m = def.perUpdateCost,
				e = def.perUpdateCost
			}
		}
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
		gadget:UnitCreated(unitID, unitDefID, teamID)
		gadget:UnitFinished(unitID, unitDefID, teamID)
	end
end
