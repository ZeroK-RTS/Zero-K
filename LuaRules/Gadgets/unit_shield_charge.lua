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
local shieldCommWeaponDefID = {}

local function LoadShieldWeaponDef(shieldWep)
	local wcp = shieldWep.customParams
	local def = {
		maxCharge = shieldWep.shieldPower,
		chargePerUpdate = PERIOD*tonumber(wcp.shield_rate)/TEAM_SLOWUPDATE_RATE,
		startPower = wcp.shieldstartingpower and tonumber(wcp.shieldstartingpower),
		slowImmune = wcp.slow_immune and true or false,
		dieOnEmpty = wcp.die_on_empty and true or false,
	}
	if wcp.shield_rate_charge then
		def.chargeRateChange = PERIOD*PERIOD*tonumber(wcp.shield_rate_charge)/(TEAM_SLOWUPDATE_RATE * TEAM_SLOWUPDATE_RATE)
	end
	if wcp.shield_drain and tonumber(wcp.shield_drain) > 0 then
		def.perUpdateCost = PERIOD*tonumber(wcp.shield_drain)/TEAM_SLOWUPDATE_RATE
		def.perSecondCost = tonumber(wcp.shield_drain)
		def.rechargeDelay = wcp.shield_recharge_delay and tonumber(wcp.shield_recharge_delay)
	end
	return def
end

for unitDefID = 1, #UnitDefs do
	local ud = UnitDefs[unitDefID]
	if ud.shieldWeaponDef and not ud.customParams.dynamic_comm then
		local shieldWep = WeaponDefs[ud.shieldWeaponDef]
		if shieldWep.customParams then
			shieldUnitDefID[unitDefID] = LoadShieldWeaponDef(shieldWep)
		end
	end
end

local commShieldDefs = {
	WeaponDefNames["commweapon_areashield"],
	WeaponDefNames["commweapon_personal_shield"],
}

for i = 1, #commShieldDefs do
	local wd = commShieldDefs[i]
	shieldCommWeaponDefID[wd.id] = LoadShieldWeaponDef(wd)
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
	local att_enabled = (spGetUnitRulesParam(unitID, "att_shieldDisabled") ~= 1)
	return att_enabled, charge
end

local function GetChargeRate(unitID)
	return (GG.att_ShieldRegenChange[unitID] or 1)
end

function gadget:GameFrame(n)
	if n%PERIOD ~= 0 then
		return
	end

	local updatePriority = (n % TEAM_SLOWUPDATE_RATE == 0)
	local setParam = ((n % 30) == 8)
	local toDestroy = false
	
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
		
		local chargeRate = def.chargePerUpdate
		if def.chargeRateChange then
			chargeRate = (Spring.GetUnitRulesParam(unitID, "shield_rate_override") or def.chargePerUpdate) + def.chargeRateChange
			Spring.SetUnitRulesParam(unitID, "shield_rate_override", chargeRate, losTable)
		end
		
		local maxCharge = def.maxCharge * (GG.att_ShieldMaxMult[unitID] or 1)
		if enabled and (charge < maxCharge or chargeRate < 0) and not inCooldown and spGetUnitRulesParam(unitID, "shieldChargeDisabled") ~= 1 then
			-- Get changed charge rate based on slow
			local newChargeRate = (def.slowImmune and 1) or GetChargeRate(unitID)
			
			if data.resTable then
				if data.oldChargeRate ~= newChargeRate then
					GG.StartMiscPriorityResourcing(unitID, def.perSecondCost*newChargeRate, true)
					
					data.oldChargeRate = newChargeRate
					data.resTable.e = def.perUpdateCost*newChargeRate
				end
			end
			
			-- Deal with overflow
			local chargeAdd = newChargeRate*chargeRate
			if charge + chargeAdd > maxCharge then
				local overProportion = 1 - (charge + chargeAdd - maxCharge)/chargeAdd
				if data.resTable then
					data.resTable.e = data.resTable.e*overProportion
					data.oldChargeRate = false -- Reset resTable on next full charge
				end
				chargeAdd = chargeAdd*overProportion
			end

			if charge + chargeAdd <= 0 then
				chargeAdd = -charge
				if def.dieOnEmpty then
					toDestroy = toDestroy or {}
					toDestroy[#toDestroy + 1] = unitID
				end
			end
			
			-- Check if the change can be carried out
			if (not data.resTable) or ((GG.AllowMiscPriorityBuildStep(unitID, data.teamID, true, data.resTable) and spUseUnitResource(unitID, data.resTable))) then
				spSetUnitShieldState(unitID, data.shieldNum, charge + chargeAdd)
			end
		end
		
		-- Drain shields on paralysis etc..
		if enabled ~= data.enabled then
			if def.dieOnEmpty and (not enabled) then
				toDestroy = toDestroy or {}
				toDestroy[#toDestroy + 1] = unitID
			end
			if not enabled then
				spSetUnitShieldState(unitID, -1, 0)
			end
			data.enabled = enabled
		end
	end
	
	if toDestroy then
		for i = 1, #toDestroy do
			local unitID = toDestroy[i]
			Spring.DestroyUnit(unitID, true)
		end
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Unit Tracking

function gadget:UnitCreated(unitID, unitDefID, teamID)
	if unitMap[unitID] then
		return
	end
	if shieldUnitDefID[unitDefID] and shieldUnitDefID[unitDefID].perUpdateCost then
		GG.AddMiscPriorityUnit(unitID)
	end
	local commShieldDefID = GG.Upgrades_UnitShieldDef and GG.Upgrades_UnitShieldDef(unitID)
	if commShieldDefID and shieldCommWeaponDefID[commShieldDefID] and shieldCommWeaponDefID[commShieldDefID].perUpdateCost then
		GG.AddMiscPriorityUnit(unitID)
	end
end

function gadget:UnitFinished(unitID, unitDefID, teamID)
	local commShieldDefID = GG.Upgrades_UnitShieldDef and GG.Upgrades_UnitShieldDef(unitID)
	if ((shieldUnitDefID[unitDefID] and not UnitDefs[unitDefID].customParams.dynamic_comm) or commShieldDefID) and not unitMap[unitID] then
		local def = shieldUnitDefID[unitDefID]
		if commShieldDefID then
			def = shieldCommWeaponDefID[commShieldDefID]
			if not def then
				return
			end
		end
		local shieldNum = (GG.Upgrades_UnitShieldDef and select(2, GG.Upgrades_UnitShieldDef(unitID))) or -1
		if def.startPower then
			spSetUnitShieldState(unitID, shieldNum, def.startPower)
		end
		unitCount = unitCount + 1
		local data = {
			unitID = unitID,
			index = unitCount,
			unitDefID = unitDefID,
			teamID = teamID,
			resTable = def.perUpdateCost and {
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
