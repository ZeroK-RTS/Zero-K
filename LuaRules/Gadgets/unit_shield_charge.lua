--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function gadget:GetInfo()
  return {
    name      = "Shield Charge",
    desc      = "Reimplementation of charging for shields. Intended for attributes and priority support.",
    author    = "Google Frog",
    date      = "16 August 2015",
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

local PERIOD = 2

local spGetUnitShieldState  = Spring.GetUnitShieldState
local spSetUnitShieldState  = Spring.SetUnitShieldState

local spGetUnitIsStunned  = Spring.GetUnitIsStunned
local spUseUnitResource   = Spring.UseUnitResource
local spGetUnitRulesParam = Spring.GetUnitRulesParam
local spSetUnitRulesParam = Spring.SetUnitRulesParam
local losTable = {inlos = true}

local unitMap = {}
local unitList = {}
local unitCount = 0

local shieldUnitDefID = {}

for unitDefID = 1, #UnitDefs do
	local ud = UnitDefs[unitDefID]
	if ud.shieldWeaponDef and not ud.customParams.dynamic_comm then
		local shieldWep = WeaponDefs[ud.shieldWeaponDef]
		if shieldWep.customParams then
			if shieldWep.customParams.shield_drain and tonumber(shieldWep.customParams.shield_drain) > 0 then
				shieldUnitDefID[unitDefID] = {
					maxCharge = shieldWep.shieldPower,
					perUpdateCost = PERIOD*tonumber(shieldWep.customParams.shield_drain)/TEAM_SLOWUPDATE_RATE,
					chargePerUpdate = PERIOD*tonumber(shieldWep.customParams.shield_rate)/TEAM_SLOWUPDATE_RATE,
					perSecondCost = tonumber(shieldWep.customParams.shield_drain),
					startPower = shieldWep.customParams.shieldstartingpower and tonumber(shieldWep.customParams.shieldstartingpower),
					rechargeDelay = shieldWep.customParams.shield_recharge_delay and tonumber(shieldWep.customParams.shield_recharge_delay),
				}
			else
				shieldUnitDefID[unitDefID] = {
					startPower = shieldWep.customParams.shieldstartingpower and tonumber(shieldWep.customParams.shieldstartingpower),
				}
			end
		end
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Unit Updating

local function IsShieldEnabled(unitID)
	local enabled, charge = spGetUnitShieldState(unitID)
	if not enabled then
		return false
	end
	local stunned_or_inbuild, stunned, inbuild = spGetUnitIsStunned(unitID)
	if stunned_or_inbuild then
		return false
	end
	local att_enabled = (spGetUnitRulesParam(unitID, "att_abilityDisabled") ~= 1)
	return att_enabled, charge
end

local function GetChargeRate(unitID)
	return (spGetUnitRulesParam(unitID,"totalReloadSpeedChange") or 1)
end

function gadget:GameFrame(n)
	if n%PERIOD ~= 0 then
		return
	end

	local updatePriority = (n % TEAM_SLOWUPDATE_RATE == 0)
	local setParam = ((n % 30) == 8)
	
	for i = 1, unitCount do
		local data = unitList[i]
		local unitID = data.unitID
		
		local enabled, charge = IsShieldEnabled(unitID)
		
		local def = data.def
		local hitTime = Spring.GetUnitRulesParam(unitID, "shieldHitFrame") or -999999
		local currTime = Spring.GetGameFrame()
		local inCooldown = false
		if def.rechargeDelay then
			local remainingTime = hitTime + def.rechargeDelay * 30 - currTime
			inCooldown = (remainingTime >= 0)
			if (setParam or currTime - hitTime < 3) and remainingTime > -70 then
				spSetUnitRulesParam(unitID, "shieldRegenTimer", remainingTime, losTable)
			end
		end
		if enabled and charge < def.maxCharge and not inCooldown and spGetUnitRulesParam(unitID, "shieldChargeDisabled") ~= 1 then
			-- Get changed charge rate based on slow
			local newChargeRate = GetChargeRate(unitID)
			if data.oldChargeRate ~= newChargeRate then
				GG.StartMiscPriorityResourcing(unitID, def.perSecondCost*newChargeRate, true)
				
				data.oldChargeRate = newChargeRate
				data.resTable.e = def.perUpdateCost*newChargeRate
			end
			
			-- Deal with overflow
			local chargeAdd = newChargeRate*def.chargePerUpdate
			if charge + chargeAdd > def.maxCharge then
				local overProportion = 1 - (charge + chargeAdd - def.maxCharge)/chargeAdd
				data.resTable.e = data.resTable.e*overProportion
				chargeAdd = chargeAdd*overProportion
			end

			-- Check if the change can be carried out
			if (GG.AllowMiscPriorityBuildStep(unitID, data.teamID, true, data.resTable) and spUseUnitResource(unitID, data.resTable)) then
				spSetUnitShieldState(unitID, data.shieldNum, charge + chargeAdd)
			end
		else
			if data.oldChargeRate ~= 0 then
				GG.StopMiscPriorityResourcing(unitID)
				data.oldChargeRate = 0
			end
		end
		
		-- Drain shields on paralysis etc..
		if enabled ~= data.enabled then
			if not enabled then
				spSetUnitShieldState(unitID, -1, 0)
			end
			data.enabled = enabled
		end
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Unit Tracking

function gadget:UnitCreated(unitID, unitDefID, teamID)
	if (shieldUnitDefID[unitDefID] or (GG.Upgrades_UnitShieldDef and GG.Upgrades_UnitShieldDef(unitID))) and not unitMap[unitID] then
		GG.AddMiscPriorityUnit(unitID)
	end
end

function gadget:UnitFinished(unitID, unitDefID, teamID)
	local commShieldID = GG.Upgrades_UnitShieldDef and select(1, GG.Upgrades_UnitShieldDef(unitID))
	if ((shieldUnitDefID[unitDefID] and not UnitDefs[unitDefID].customParams.dynamic_comm) or commShieldID) and not unitMap[unitID] then
		local def = shieldUnitDefID[unitDefID]
		if commShieldID then
			def = select(3, GG.Upgrades_UnitShieldDef(unitID))
			if not def then
				return
			end
		end
		local shieldNum = (GG.Upgrades_UnitShieldDef and select(2, GG.Upgrades_UnitShieldDef(unitID))) or -1
		if def.startPower then
			spSetUnitShieldState(unitID, shieldNum, def.startPower)
		end
		
		if def.perUpdateCost then
			unitCount = unitCount + 1
			local data = {
				unitID = unitID,
				index = unitCount,
				unitDefID = unitDefID,
				teamID = teamID,
				resTable = {
					m = 0,
					e = def.perUpdateCost
				},
				shieldNum = shieldNum,
				def = def
			}
			
			unitList[unitCount] = data
			unitMap[unitID] = data
		end
	end
end

function gadget:UnitDestroyed(unitID, unitDefID, teamID)
	if unitMap[unitID] then
		local index = unitMap[unitID].index
		
		unitList[unitCount].index = index
		unitList[index] = unitList[unitCount]
		
		unitList[unitCount] = nil
		unitMap[unitID] = nil
		unitCount = unitCount - 1
	end
end

function gadget:UnitTaken(unitID, unitDefID, oldTeamID, teamID)
	if unitMap[unitID] then
		unitMap[unitID].teamID = teamID
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

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
