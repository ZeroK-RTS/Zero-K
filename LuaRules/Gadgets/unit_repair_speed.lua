--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function gadget:GetInfo()
   return {
      name      = "Repair Speed Changer",
      desc      = "Changes the repair speed for units that are in combat",
      author    = "Google Frog",
      date      = "11 December 2010",
      license   = "GNU GPL, v2 or later",
      layer     = 0,
      enabled   = true
   }
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--SYNCED
if (not gadgetHandler:IsSyncedCode()) then
   return false
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local spAreTeamsAllied = Spring.AreTeamsAllied
local spGetGameFrame = Spring.GetGameFrame
local spGetUnitHealth = Spring.GetUnitHealth
local spSetUnitCosts = Spring.SetUnitCosts
local spValidUnitID = Spring.ValidUnitID

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- CONFIG

local REPAIR_PENALTY = 4 -- effective 4x time to repair
local REPAIR_PENALTY_TIME = 300
local UPDATE_FREQUENCY = 30

local noFFWeaponDefs = {}
for i = 1, #WeaponDefs do
	local wd = WeaponDefs[i]
	if wd.customParams and wd.customParams.nofriendlyfire then
		noFFWeaponDefs[i] = true
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local damagedUnits = {}

function gadget:UnitDamaged(unitID, unitDefID, unitTeam, fullDamage, paralyzer, weaponDefID, attackerID, attackerDefID, attackerTeam)

	if (weaponDefID and noFFWeaponDefs[weaponDefID] and unitTeam and attackerTeam and spAreTeamsAllied(unitTeam, attackerTeam)) then
		return
	end

	if damagedUnits[unitID] then
		damagedUnits[unitID].frames = REPAIR_PENALTY_TIME
	else
		local bt = UnitDefs[unitDefID].buildTime
		damagedUnits[unitID] = {
			bt = bt,
			frames = REPAIR_PENALTY_TIME,
		}
		if select(5,spGetUnitHealth(unitID)) == 1 then
			spSetUnitCosts(unitID, {buildTime = bt*REPAIR_PENALTY})
		end
	end
end

function gadget:UnitFinished(unitID, unitDefID, unitTeam)
	if damagedUnits[unitID] then
		spSetUnitCosts(unitID, {buildTime = damagedUnits[unitID].bt*REPAIR_PENALTY})
	end
end

function gadget:GameFrame(n)
	if n%UPDATE_FREQUENCY == 20 then
		for unitID,data in pairs(damagedUnits) do
			data.frames = data.frames - UPDATE_FREQUENCY
			if data.frames <= 0 then
				if spValidUnitID(unitID) then
					spSetUnitCosts(unitID, {buildTime = data.bt})
				end
				damagedUnits[unitID] = nil
			end
		end
	end
end

function gadget:UnitDestroyed(unitID, unitDefID, unitTeam)
	if damagedUnits[unitID] then
		damagedUnits[unitID] = nil
	end
end

