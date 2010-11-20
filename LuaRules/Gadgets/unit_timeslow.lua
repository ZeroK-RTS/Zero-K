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

--SYNCED
if (not gadgetHandler:IsSyncedCode()) then
   return false
end


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
local spGetUnitDefID        = Spring.GetUnitDefID
local spSetUnitWeaponState  = Spring.SetUnitWeaponState
local spGetUnitWeaponState  = Spring.GetUnitWeaponState
local spGetUnitCOBValue 	= Spring.GetUnitCOBValue
local spAreTeamsAllied		= Spring.AreTeamsAllied
local spValidUnitID 		= Spring.ValidUnitID

local CMD_ATTACK = CMD.ATTACK
local CMD_REMOVE = CMD.REMOVE
local CMD_SET_WANTED_MAX_SPEED = CMD.SET_WANTED_MAX_SPEED

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------


local attritionWeaponDefs = include("LuaRules/Configs/timeslow_defs.lua")
local slowedUnits = {}

if not GG.attUnits then
	GG.attUnits = {}
end

Spring.SetGameRulesParam("slowState",1)

function gadget:Initialize()
end

local function checkTargetRandomTarget(unitID)

end

local function updateSlow(unitID, state)

	local health = Spring.GetUnitHealth(unitID)
	
	if health then
		if state.slowDamage > health*0.66 then
			state.slowDamage = health*0.66
		end
		
		local percentSlow = state.slowDamage/health

		Spring.SetUnitRulesParam(unitID,"slowState",percentSlow, {inlos = true})
	end
end


function gadget:UnitPreDamaged(unitID, unitDefID, unitTeam, damage, paralyzer, weaponID,
                            attackerID, attackerDefID, attackerTeam)
        
	if (not spValidUnitID(unitID)) or (not weaponID) or (not attritionWeaponDefs[weaponID]) or ((not attackerID) and attritionWeaponDefs[weaponID].noDeathBlast)or (attritionWeaponDefs[weaponID].noFF and attackerTeam and spAreTeamsAllied(unitTeam, attackerTeam)) then 
		return damage
	end
	
	-- add stats that the unit requires for this gadget
	if not slowedUnits[unitID] then
		slowedUnits[unitID] = {
			slowDamage = 0, 
			degradeTimer = 1,
		}
		GG.attUnits[unitID] = true -- unit with attribute change to be handled by unit_attributes
	end
	
	-- add slow damage
	local slowdown = attritionWeaponDefs[weaponID].slowDamage
	if attritionWeaponDefs[weaponID].scaleSlow then 
		slowdown = slowdown * (damage/WeaponDefs[weaponID].damages[0]) 
	end	--scale slow damage based on real damage (i.e. take into account armortypes etc.)
	
	slowedUnits[unitID].slowDamage = slowedUnits[unitID].slowDamage + slowdown
	slowedUnits[unitID].degradeTimer = 1

	-- check if a target change is needed
	-- only changes target if the target is fully slowed and next order is an attack order
	if Spring.ValidUnitID(attackerID) and attritionWeaponDefs[weaponID].smartRetarget then
		local health = Spring.GetUnitHealth(unitID)
		if slowedUnits[unitID].slowDamage > health*0.66 then
			
			local cmd = Spring.GetCommandQueue(attackerID)

			-- set order by player
			if #cmd > 1 and (cmd[1].id == CMD_ATTACK and (cmd[2].id == CMD_ATTACK or 
				(#cmd > 2 and cmd[2].id == CMD_SET_WANTED_MAX_SPEED and cmd[3].id == CMD_ATTACK))) then
				
				local re = Spring.GetUnitStates(attackerID)["repeat"]
					
				if cmd[2].id == CMD_SET_WANTED_MAX_SPEED then
					Spring.GiveOrderToUnit(attackerID,CMD_REMOVE,{cmd[1].tag,cmd[2].tag},{})
				else
					Spring.GiveOrderToUnit(attackerID,CMD_REMOVE,{cmd[1].tag},{})
				end
					
				if re then
					Spring.GiveOrderToUnit(attackerID,CMD_ATTACK,cmd[1].params,{"shift"})
				end

			end
			
			-- if attack is a non-player command
			if #cmd == 0 or cmd[1].id ~= CMD_ATTACK or (cmd[1].id == CMD_ATTACK and cmd[1].options.internal) then
				local newTargetID = Spring.GetUnitNearestEnemy(attackerID,UnitDefs[attackerDefID].range, true)
				if newTargetID ~= unitID and spValidUnitID(attackerID) and spValidUnitID(newTargetID) then
					Spring.SetUnitTarget(attackerID,newTargetID)
				end
			end
			
		end
	end
	
	-- write to unit rules param
	updateSlow( unitID, slowedUnits[unitID])
	
	if attritionWeaponDefs[weaponID].onlySlow then 
		return 0
	else 
		return damage 
	end
end

local function removeUnit(unitID)
	slowedUnits[unitID] = nil
end

function gadget:GameFrame(f)
    if (f-1) % 16 == 0 then
        for unitID, state in pairs(slowedUnits) do
        
			if state.degradeTimer <= 0 then
				
				local health = Spring.GetUnitHealth(unitID) or 0
				state.slowDamage = state.slowDamage-health*0.02
				if state.slowDamage < 0 then
					state.slowDamage = 0
					updateSlow(unitID, state)
					removeUnit(unitID)
				else
					updateSlow(unitID, state)
				end
				
			else
				state.degradeTimer = state.degradeTimer-1
			end
			
        end
    end
end


function gadget:UnitDestroyed(unitID)
	removeUnit(unitID)
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
