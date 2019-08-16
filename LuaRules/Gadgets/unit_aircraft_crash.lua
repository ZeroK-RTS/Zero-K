--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
if (not gadgetHandler:IsSyncedCode()) then
	return
end
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function gadget:GetInfo()
  return {
    name      = "Aircraft Crashing",
    desc      = "Handles crashing planes",
    author    = "KingRaptor",
    date      = "22 Jan 2011",
    license   = "GNU LGPL, v2.1 or later",
    layer     = 0,
    enabled   = true  --  loaded by default?
  }
end
--Revision 4
--------------------------------------------------------------------------------
-- speedups
--------------------------------------------------------------------------------
local spGetUnitIsStunned	= Spring.GetUnitIsStunned
local spGetUnitHealth		= Spring.GetUnitHealth

local aircraftDefIDs = {}

function gadget:Initialize()
	for i=1,#UnitDefs do
		if UnitDefs[i].canFly then
			aircraftDefIDs[i] = UnitDefs[i].health
		end
	end
end

local LOS_ACCESS = {inlos = true}
local DAMAGE_MEMORY = 60	-- gameframes


local recentDamage = {}	-- indexed by unitID
local gameFrame = 0

function gadget:GameFrame(n)
	gameFrame = n
	if n%16 == 0 then
		for unitID, damList in pairs(recentDamage) do
			for frame in pairs(damList) do
				if frame + DAMAGE_MEMORY < n then
					damList[frame] = nil
				end
			end
		end
	end
end

function gadget:UnitDamaged(unitID, unitDefID, unitTeam, damage, paralyzer, weaponID, attackerID, attackerDefID, attackerTeam)
	if not aircraftDefIDs[unitDefID] then
		return
	end
	if (not recentDamage[unitID]) or select(3, spGetUnitIsStunned(unitID)) then
		return
	end
	--Spring.Echo("Plane damaged")
	recentDamage[unitID][gameFrame] = (recentDamage[unitID][gameFrame] or 0) + damage
	
	if spGetUnitHealth(unitID) < 0 then
		--Spring.Echo("Plane shot down")
		local rDam = 0
		for frame, recentDamageInstance in pairs(recentDamage[unitID] or {}) do
			rDam = rDam + recentDamageInstance
		end
		local maxHealth = aircraftDefIDs[unitDefID]
		local severity = rDam/maxHealth
		if severity < 0.5 then
			Spring.SetUnitCrashing(unitID, true)
			Spring.SetUnitNoSelect(unitID, true)
			Spring.SetUnitSensorRadius(unitID, "los", 0)
			Spring.SetUnitSensorRadius(unitID, "airLos", 0)
			Spring.SetUnitRulesParam(unitID, "crashing", 1, LOS_ACCESS)
			GG.UpdateUnitAttributes(unitID)
			-- note that we let the unit keep its airlos
			if GG.AircraftCrashingDown then
				GG.AircraftCrashingDown(unitID) --send event to unit_bomber_command.lua to cancel any airpad reservation hold by this airplane
			end
		end
		recentDamage[unitID] = nil	-- no longer need to track this plane
	end
end

function gadget:UnitDestroyed(unitID, unitDefID, unitTeam)
	recentDamage[unitID] = nil
end

function gadget:UnitFinished(unitID, unitDefID, unitTeam)
	if (not aircraftDefIDs[unitDefID]) or select(3, spGetUnitIsStunned(unitID)) then
		return
	end
	recentDamage[unitID] = {}
end
