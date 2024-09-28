
if not gadgetHandler:IsSyncedCode() then
	return
end
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function gadget:GetInfo()
   return {
      name      = "Attributes",
      desc      = "Handles UnitRulesParam attributes.",
      author    = "CarRepairer & Google Frog",
      date      = "2009-11-27", --last update 2014-2-19
      license   = "GNU GPL, v2 or later",
      layer     = -1,
      enabled   = true,
   }
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local UPDATE_PERIOD = 3

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
local floor = math.floor

local spValidUnitID         = Spring.ValidUnitID
local spGetUnitDefID        = Spring.GetUnitDefID
local spGetUnitRulesParam  	= Spring.GetUnitRulesParam
local spSetUnitRulesParam   = Spring.SetUnitRulesParam


local ALLY_ACCESS = {allied = true}
local INLOS_ACCESS = {inlos = true}

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- UnitRulesParam Handling

function UpdateUnitAttributes(unitID, frame)
	if not spValidUnitID(unitID) then
		return
	end
	
	local unitDefID = spGetUnitDefID(unitID)
	if not unitDefID then
		return
	end
	
	local attributesTable = false -- A table that goes to the unit attributes gadget
	
	-- Increased reload from CAPTURE --
	local selfReloadSpeedChange = spGetUnitRulesParam(unitID, "selfReloadSpeedChange")
	
	local disarmed = spGetUnitRulesParam(unitID, "disarmed") or 0
	local completeDisable = (spGetUnitRulesParam(unitID, "morphDisable") or 0)
	if spGetUnitRulesParam(unitID, "planetwarsDisable") == 1 then
		completeDisable = 1
	end
	local crashing = spGetUnitRulesParam(unitID, "crashing") or 0
	
	-- Unit speed change (like sprint) --
	local upgradesSpeedMult   = spGetUnitRulesParam(unitID, "upgradesSpeedMult")
	local teleportSpeedMult   = spGetUnitRulesParam(unitID, "teleportSpeedMult")
	local selfMoveSpeedChange = spGetUnitRulesParam(unitID, "selfMoveSpeedChange")
	local selfTurnSpeedChange = spGetUnitRulesParam(unitID, "selfTurnSpeedChange")
	local selfIncomeChange = (spGetUnitRulesParam(unitID, "selfIncomeChange") or 1) * (GG.unit_handicap[unitID] or 1)
	local selfEnergyIncChange = 1
	local selfMaxAccelerationChange = spGetUnitRulesParam(unitID, "selfMaxAccelerationChange") --only exist in airplane??
	
	-- SLOW --
	local slowState = spGetUnitRulesParam(unitID, "slowState")
	if slowState and slowState > 0.5 then
		slowState = 0.5 -- Maximum slow
	end
	local zombieSpeedMult = spGetUnitRulesParam(unitID, "zombieSpeedMult")
	local buildpowerMult = spGetUnitRulesParam(unitID, "buildpower_mult")
	
	-- Disable
	local shieldDisabled = (spGetUnitRulesParam(unitID, "shield_disabled") == 1)
	local fullDisable    = (spGetUnitRulesParam(unitID, "fulldisable") == 1)
	
	local baseSpeedMult   = (1 - (slowState or 0))*(zombieSpeedMult or 1)
	local econMult   = (baseSpeedMult)*(1 - disarmed)*(1 - completeDisable)*(selfIncomeChange or 1)
	local buildMult  = (baseSpeedMult)*(1 - disarmed)*(1 - completeDisable)*(selfIncomeChange or 1)*(buildpowerMult or 1)
	local moveMult   = (baseSpeedMult)*(selfMoveSpeedChange or 1)*(1 - completeDisable)*(upgradesSpeedMult or 1)*(teleportSpeedMult or 1)
	local turnMult   = (baseSpeedMult)*(selfMoveSpeedChange or 1)*(selfTurnSpeedChange or 1)*(1 - completeDisable)*(teleportSpeedMult or 1)
	local reloadMult = (baseSpeedMult)*(selfReloadSpeedChange or 1)*(1 - disarmed)*(1 - completeDisable)
	local maxAccMult = (baseSpeedMult)*(selfMaxAccelerationChange or 1)*(upgradesSpeedMult or 1)*(teleportSpeedMult or 1)

	if fullDisable then
		buildMult = 0
		moveMult = 0
		turnMult = 0
		reloadMult = 0
		maxAccMult = 0
	end
	
	-- Let other gadgets and widgets get the total effect without
	-- duplicating the pevious calculations.
	spSetUnitRulesParam(unitID, "baseSpeedMult", baseSpeedMult, INLOS_ACCESS) -- Guaranteed not to be 0 <- This is a pain to generalise
	
	if slowState ~= 0 or turnMult ~= 1 or maxAccMult ~= 1 then
		attributesTable = attributesTable or {}
		attributesTable.healthRegen = (1 - (slowState or 0))
	end
	
	if reloadMult ~= 1 then
		attributesTable = attributesTable or {}
		attributesTable.reload = reloadMult
	end
	
	if moveMult ~= 1 or turnMult ~= 1 or maxAccMult ~= 1 then
		attributesTable = attributesTable or {}
		attributesTable.move = moveMult
		attributesTable.turn = turnMult
		attributesTable.accel = accelMult
	end
	
	if buildMult ~= 1 then
		attributesTable = attributesTable or {}
		attributesTable.build = buildMult
	end
	
	if econMult ~= 1 then
		attributesTable = attributesTable or {}
		attributesTable.econ = econMult
	end
	
	local forcedOff = spGetUnitRulesParam(unitID, "forcedOff")
	local abilityDisabled = (forcedOff == 1 or disarmed == 1 or completeDisable == 1 or crashing == 1)
	if abilityDisabled then
		attributesTable = attributesTable or {}
		attributesTable.abilityDisabled = true
	end
	if (shieldDisabled or abilityDisabled) then
		attributesTable = attributesTable or {}
		attributesTable.shieldDisabled = true
	end
	
	local radarOverride = spGetUnitRulesParam(unitID, "radarRangeOverride")
	local sonarOverride = spGetUnitRulesParam(unitID, "sonarRangeOverride")
	local jammerOverride = spGetUnitRulesParam(unitID, "jammingRangeOverride")
	local sightOverride = spGetUnitRulesParam(unitID, "sightRangeOverride")
	
	if radarOverride or sonarOverride or jammerOverride or sightOverride then
		attributesTable = attributesTable or {}
		attributesTable.setRadar = radarOverride
		attributesTable.setSonar = sonarOverride
		attributesTable.setJammer = jammerOverride
		attributesTable.setSight = sightOverride
	end

	local cloakBlocked = (spGetUnitRulesParam(unitID, "on_fire") == 1) or (disarmed == 1) or (completeDisable == 1)
	if cloakBlocked then
		GG.PokeDecloakUnit(unitID, unitDefID)
	end
	
	if attributesTable then
		GG.Attributes.AddEffect(unitID, "old_att_gadget", attributesTable)
	else
		GG.Attributes.RemoveEffect(unitID, "old_att_gadget")
	end
end

function gadget:Initialize()
	GG.UpdateUnitAttributes = UpdateUnitAttributes
end
