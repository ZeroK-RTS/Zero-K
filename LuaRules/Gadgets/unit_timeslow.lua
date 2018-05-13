--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function gadget:GetInfo()
   return {
      name      = "Time slow v2",
      desc      = "Time slow Weapon",
      author    = "Google Frog , (MidKnight made orig)",
      date      = "2010-05-31",
      license   = "GNU GPL, v2 or later",
      layer     = 0,
      enabled   = true
   }
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local SAVE_FILE = "Gadgets/unit_timeslow.lua"

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--SYNCED
if (gadgetHandler:IsSyncedCode()) then
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
local spGetUnitDefID        = Spring.GetUnitDefID
local spGetUnitCOBValue     = Spring.GetUnitCOBValue
local spAreTeamsAllied      = Spring.AreTeamsAllied
local spValidUnitID         = Spring.ValidUnitID
local spGiveOrderToUnit     = Spring.GiveOrderToUnit
local spGetUnitHealth       = Spring.GetUnitHealth
local spSetUnitRulesParam   = Spring.SetUnitRulesParam
local spGetCommandQueue     = Spring.GetCommandQueue
local spGetUnitStates       = Spring.GetUnitStates
local spGetUnitTeam         = Spring.GetUnitTeam
local spSetUnitTarget       = Spring.SetUnitTarget
local spGetUnitNearestEnemy	= Spring.GetUnitNearestEnemy

local CMD_ATTACK = CMD.ATTACK
local CMD_REMOVE = CMD.REMOVE
local CMD_MOVE   = CMD.MOVE
local CMD_FIGHT  = CMD.FIGHT
local CMD_SET_WANTED_MAX_SPEED = CMD.SET_WANTED_MAX_SPEED
local LOS_ACCESS = {inlos = true}

include("LuaRules/Configs/customcmds.h.lua")

local gaiaTeamID = Spring.GetGaiaTeamID()

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local attritionWeaponDefs, MAX_SLOW_FACTOR, DEGRADE_TIMER, DEGRADE_FACTOR, UPDATE_PERIOD = include("LuaRules/Configs/timeslow_defs.lua")
local slowedUnits = {}

_G.slowedUnits = slowedUnits

Spring.SetGameRulesParam("slowState",1)

local function updateSlow(unitID, state)

	local health = spGetUnitHealth(unitID)

	if health then
		local maxSlow = health*(MAX_SLOW_FACTOR + (state.extraSlowBound or 0))
		if state.slowDamage > maxSlow then
			state.slowDamage = maxSlow
		end
		
		local percentSlow = state.slowDamage/health

		spSetUnitRulesParam(unitID,"slowState",percentSlow, LOS_ACCESS)
		GG.UpdateUnitAttributes(unitID)
	end
end

function gadget:UnitPreDamaged_GetWantedWeaponDef()
	local wantedWeaponList = {}
	for wdid = 1, #WeaponDefs do
		if attritionWeaponDefs[wdid] then
			wantedWeaponList[#wantedWeaponList + 1] = wdid
		end
	end 
	return wantedWeaponList
end

function gadget:UnitPreDamaged(unitID, unitDefID, unitTeam, damage, paralyzer, weaponID,
                            attackerID, attackerDefID, attackerTeam)

	if (not spValidUnitID(unitID)) or (not weaponID) or (not attritionWeaponDefs[weaponID]) or ((not attackerID) and attritionWeaponDefs[weaponID].noDeathBlast)
		or (attritionWeaponDefs[weaponID].scaleSlow and damage == 0) then
		return damage
	end

	-- add stats that the unit requires for this gadget
	if not slowedUnits[unitID] then
		slowedUnits[unitID] = {
			slowDamage = 0,
			degradeTimer = DEGRADE_TIMER,
		}
	end
	local slowDef = attritionWeaponDefs[weaponID]

	-- add slow damage
	local slowdown = slowDef.slowDamage
	if slowDef.scaleSlow then
		slowdown = slowdown * (damage/WeaponDefs[weaponID].customParams.raw_damage)
	end	--scale slow damage based on real damage (i.e. take into account armortypes etc.)

	slowedUnits[unitID].slowDamage = slowedUnits[unitID].slowDamage + slowdown
	slowedUnits[unitID].degradeTimer = DEGRADE_TIMER
	
	if slowDef.overslow then
		slowedUnits[unitID].extraSlowBound = math.max(slowedUnits[unitID].extraSlowBound or 0, slowDef.overslow)
	end

	if GG.Awards and GG.Awards.AddAwardPoints then
		local ud = UnitDefs[unitDefID]
		local cost_slowdown = (slowdown / ud.health) * ud.metalCost
		GG.Awards.AddAwardPoints ('slow', attackerTeam, cost_slowdown)
	end

	-- check if a target change is needed
	-- only changes target if the target is fully slowed and next order is an attack order
	if spValidUnitID(attackerID) and slowDef.smartRetarget then
		local health = spGetUnitHealth(unitID)
		if slowedUnits[unitID].slowDamage > health*slowDef.smartRetarget then

			local cmd = spGetCommandQueue(attackerID, 3)

			-- set order by player
			if #cmd > 1 and (cmd[1].id == CMD_ATTACK and #cmd[1].params == 1 and cmd[1].params[1] == unitID
				and (cmd[2].id == CMD_ATTACK or
				(#cmd > 2 and cmd[2].id == CMD_SET_WANTED_MAX_SPEED and cmd[3].id == CMD_ATTACK))) then

				local re = spGetUnitStates(attackerID)["repeat"]

				if cmd[2].id == CMD_SET_WANTED_MAX_SPEED then
					spGiveOrderToUnit(attackerID,CMD_REMOVE,{cmd[1].tag,cmd[2].tag}, 0)
				else
					spGiveOrderToUnit(attackerID,CMD_REMOVE,{cmd[1].tag},0)
				end

				if re then
					spGiveOrderToUnit(attackerID,CMD_ATTACK,cmd[1].params,CMD.OPT_SHIFT)
				end

			end

			-- if attack is a non-player command
			if #cmd == 0 or cmd[1].id ~= CMD_ATTACK or (cmd[1].id == CMD_ATTACK and cmd[1].options.internal) then
				local newTargetID = spGetUnitNearestEnemy(attackerID,UnitDefs[attackerDefID].range, true)
				if newTargetID ~= unitID and spValidUnitID(attackerID) and spValidUnitID(newTargetID) then
					local team = spGetUnitTeam(newTargetID)
					if (not team) or team ~= gaiaTeamID then
						spSetUnitTarget(attackerID,newTargetID)
						if #cmd > 0 and cmd[1].id == CMD_ATTACK then
							if #cmd > 1 and cmd[2].id == CMD_SET_WANTED_MAX_SPEED then
								spGiveOrderToUnit(attackerID,CMD_REMOVE,{cmd[1].tag,cmd[2].tag}, 0)
							else
								spGiveOrderToUnit(attackerID,CMD_REMOVE,{cmd[1].tag},0)
							end
						elseif #cmd > 1 and (cmd[1].id == CMD_MOVE or cmd[1].id == CMD_RAW_MOVE or cmd[1].id == CMD_RAW_BUILD) and cmd[2].id == CMD_FIGHT and
							cmd[2].options.internal and #cmd[2].params == 1 and cmd[2].params[1] == unitID then
							spGiveOrderToUnit(attackerID,CMD_REMOVE,{cmd[2].tag},0)
						end
					end
				end
			end

		end
	end

	-- write to unit rules param
	updateSlow( unitID, slowedUnits[unitID])

	if slowDef.onlySlow then
		return 0
	else
		return damage
	end
end


local function addSlowDamage(unitID, damage)

	-- add stats that the unit requires for this gadget
	if not slowedUnits[unitID] then
		slowedUnits[unitID] = {
			slowDamage = 0,
			degradeTimer = DEGRADE_TIMER,
		}
	end

	-- add slow damage
	slowedUnits[unitID].slowDamage = slowedUnits[unitID].slowDamage + damage
	slowedUnits[unitID].degradeTimer = DEGRADE_TIMER
	
	updateSlow( unitID, slowedUnits[unitID]) -- without this unit does not fire slower, only moves slower
end

local function getSlowDamage(unitID)
	if slowedUnits[unitID] then
		return slowedUnits[unitID].slowDamage
	end
	return false
end


-- morph uses this
GG.getSlowDamage = getSlowDamage
GG.addSlowDamage = addSlowDamage

local function removeUnit(unitID)
	slowedUnits[unitID] = nil
end

function gadget:GameFrame(f)
    if (f-1) % UPDATE_PERIOD == 0 then
        for unitID, state in pairs(slowedUnits) do
			if state.extraSlowBound then
				state.extraSlowBound = state.extraSlowBound - DEGRADE_FACTOR
				if state.extraSlowBound <= 0 then
					state.extraSlowBound = nil
				end
			end
			if state.degradeTimer <= 0 then
				local health = spGetUnitHealth(unitID) or 0
				state.slowDamage = state.slowDamage - health*DEGRADE_FACTOR
			else
				state.degradeTimer = state.degradeTimer-1
			end
			if state.slowDamage < 0 then
				state.slowDamage = 0
				updateSlow(unitID, state)
				removeUnit(unitID)
			else
				updateSlow(unitID, state)
			end
        end
    end
end


function gadget:UnitDestroyed(unitID)
   removeUnit(unitID)
end

function gadget:Load(zip)
   if not GG.SaveLoad then
		Spring.Log(gadget:GetInfo().name, LOG.ERROR, "Failed to access save/load API")
		return
	end
	
	local loadData = GG.SaveLoad.ReadFile(zip, "Time Slow", SAVE_FILE) or {}
	slowedUnits = {}
	for oldID, entry in pairs(loadData) do
		local newID = GG.SaveLoad.GetNewUnitID(oldID)
		if newID then
			slowedUnits[newID] = entry
			GG.UpdateUnitAttributes(newID)
		end
	end
	_G.slowedUnits = slowedUnits
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
else
-- UNSYNCED
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
function gadget:Save(zip)
	if not GG.SaveLoad then
		Spring.Log(gadget:GetInfo().name, LOG.ERROR, "Failed to access save/load API")
		return
	end
	
	GG.SaveLoad.WriteSaveData(zip, SAVE_FILE, Spring.Utilities.MakeRealTable(SYNCED.slowedUnits, "Time Slow"))
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
end
