-- $Id: unit_estall_disable.lua 3291 2008-11-25 00:36:20Z licho $
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
--	file:		unit_estall_disable.lua
--	brief:	 disables units during energy stall
--	author:	
--
--	Copyright (C) 2007.
--	Licensed under the terms of the GNU GPL, v2 or later.
--
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function gadget:GetInfo()
	return {
		name	 = "Unit E-Stall Disable",
		desc	 = "Deactivates units during energy stall",
		author	 = "Licho",
		date	 = "23.7.2007",
		license	 = "GNU GPL, v2 or later",
		layer	 = 0,
		enabled	 = true	--	loaded by default?
	}
end

--------------------------------------------------------------------------------
if (gadgetHandler:IsSyncedCode()) then
--------------------------------------------------------------------------------
--	SYNCED
--------------------------------------------------------------------------------

--Speed-ups

local spGiveOrderToUnit	 = Spring.GiveOrderToUnit
local spGetUnitStates    = Spring.GetUnitStates
local spGetUnitTeam	     = Spring.GetUnitTeam
local spGetUnitResources = Spring.GetUnitResources
local spGetGameSeconds	 = Spring.GetGameSeconds
local spGetUnitIsStunned = Spring.GetUnitIsStunned

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local units = {}
local disabledUnits = {}
local changeStateDelay = 3 -- delay in seconds before state of unit can be changed. Do not set it below 2 seconds, because it takes 2 seconds before enabled unit reaches full energy use
local radarDefs = {
	[ UnitDefNames['armarad'].id ] = true,
	[ UnitDefNames['spherecloaker'].id ] = true,
	[ UnitDefNames['armjamt'].id ] = true,
	[ UnitDefNames['armsonar'].id ] = true,
	[ UnitDefNames['corrad'].id ] = true,
	[ UnitDefNames['corawac'].id ] = true,
	[ UnitDefNames['corvrad'].id ] = true,
}


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function gadget:Initialize()
	for _,unitID in ipairs(Spring.GetAllUnits()) do
		local unitDefID = Spring.GetUnitDefID(unitID)
		AddUnit(unitID, unitDefID)
	end
end


function AddUnit(unitID, unitDefID) 
	if (radarDefs[unitDefID]) then
		units[unitID] = { defID = unitDefID, changeStateTime = spGetGameSeconds() } 
	end
end


function RemoveUnit(unitID) 
	units[unitID] = nil
	disabledUnits[unitID] = nil
end


--[[ Using UnitFinished instead of UnitCreated so that the changeStateDelay
counts from the point in time when the unit is finish built.
This prevents units from being switched off, when they take longer than
changeStateDelay to be built. ]]
function gadget:UnitFinished(unitID, unitDefID, teamID)
	AddUnit(unitID, unitDefID)
end


function gadget:UnitTaken(unitID, unitDefID)
	AddUnit(unitID, unitDefID)
end


function gadget:UnitGiven(unitID, unitDefID, newTeamID)
	if (newTeamID==nil) then RemoveUnit(unitID) end
end


function gadget:UnitDestroyed(unitID)
	RemoveUnit(unitID)
end


function gadget:GameFrame(n)
	if (((n+8) % 64) < 0.1) then
		local teamEnergy = {}
		local gameSeconds = spGetGameSeconds()
		local temp = Spring.GetTeamList() 
		for _,teamID in ipairs(temp) do 
			local eCur, eMax, ePull, eInc, _, _, _, eRec = Spring.GetTeamResources(teamID, "energy")
			teamEnergy[teamID] = eCur - ePull + eInc
		end 

		for unitID,data in pairs(units) do
			if (gameSeconds - data.changeStateTime > changeStateDelay) then
				local disabledUnitEnergyUse = disabledUnits[unitID] 
				if (disabledUnitEnergyUse~=nil) then -- we have disabled unit
					local unitTeamID = spGetUnitTeam(unitID)
					if (disabledUnitEnergyUse < teamEnergy[unitTeamID] and not spGetUnitIsStunned(unitID)) then	-- we still have enough energy to reenable unit
						disabledUnits[unitID]=nil
						spGiveOrderToUnit(unitID, CMD.ONOFF, { 1 }, { })
						data.changeStateTime = gameSeconds
						teamEnergy[unitTeamID] = teamEnergy[unitTeamID] - disabledUnitEnergyUse
					end
				else -- we have non-disabled unit
					local _, _, _, energyUse =	spGetUnitResources(unitID)
					local energyUpkeep = UnitDefs[data.defID].energyUpkeep
					if (energyUse == nil or energyUpkeep == nil) then -- unit probably doesnt exists, get rid of it
						RemoveUnit(unitID)
					-- there is not enough energy to keep unit running (its energy use auto dropped to 0), we will disable it
					elseif (energyUse < energyUpkeep) then
						if (spGetUnitStates(unitID).active) then	-- only disable "active" unit
							spGiveOrderToUnit(unitID, CMD.ONOFF, { 0 }, { })
							data.changeStateTime = gameSeconds
							disabledUnits[unitID] = energyUpkeep
						end
					end
				end
			end
		end
	end
end


function gadget:AllowCommand(unitID, unitDefID, teamID, cmdID, cmdParams, cmdOptions)
	if (cmdID == CMD.ONOFF and disabledUnits[unitID]~=nil) then
		return false
	else 
		return true
	end
end
 
	
--------------------------------------------------------------------------------
--	END SYNCED
--------------------------------------------------------------------------------
end

