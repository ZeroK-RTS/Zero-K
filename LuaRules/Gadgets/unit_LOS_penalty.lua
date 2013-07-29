--//Version 1.0

function gadget:GetInfo()
  return {
    name      = "Newton Throw Reduce LOS",
    desc      = "Simply reduce LOS to any unit that is thrown by Newton or when a fighter use Speed Boost.",
    author    = "msafwan",
    date      = "29 July 2013",
    license   = "GNU GPL, v2 or later",
    layer     = 0,
    enabled   = false  --  loaded by default?
  }
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
if (gadgetHandler:IsSyncedCode()) then -- SYNCED ---
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--Speedup
local spGetUnitPosition  = Spring.GetUnitPosition
local spGetUnitVelocity = Spring.GetUnitVelocity
local spGetUnitTransporter  = Spring.GetUnitTransporter 
local spGetUnitIsTransporting = Spring.GetUnitIsTransporting
local spGetUnitDefID =Spring.GetUnitDefID
local spValidUnitID = Spring.ValidUnitID
local spSpawnCEG = Spring.SpawnCEG
local spGetUnitHealth = Spring.GetUnitHealth
local spSetUnitSensorRadius = Spring.SetUnitSensorRadius
local spGetUnitSensorRadius = Spring.GetUnitSensorRadius
--------------------------------------------------------------------------------
--Config

local airplane_speedBarrier = UnitDefNames["fighter"].speed/30 + 0.1 --maximum speed before LOS is reduced to airplane unit. Comparison: Avenger 13 elmo-per-frame, precision bomber 8.8 elmo-per-frame,  Vindicator 8 elmo-per-frame, Valkyrie 10.7 elmo-per-frame
local enableForAirplane = true
local factor_landLos_ofAirplane = 10 --% (percent) reduction during high-speed
local factor_airLos_ofAirplane = 75--% (percent)
local airplaneSpeedBoostPeriod = 1 --second

local ground_speedBarrier = UnitDefNames["corfav"].speed/30 + 0.1-- maximum speed before LOS is reduced to ground unit. Comparison: dart 5.09 elmo-per-frame, glaives 3.8 elmo-per-frame, 
local enableForGroundUnits = true
local factor_landLos_ofGroundUnits = 10 --% (percent)
local factor_airLos_ofGroundUnits = 100 --% (percent). Note: 100% is "no change", <100% is "reduce Los"

local updateRate = 2 --this effect VFX rate & responds rate (default is 2)
include "LuaRules/Configs/customcmds.h.lua" --for CMD_ONECLICK_WEAPON
--------------------------------------------------------------------------------
--Variables
local fastGroundUnitsID = {} --content: {[unitID] = {[1] = speedBarrier_squared,[2] =landSensorRadius,[3] =airSensorRadius,[4] =canFly, ["commited"] = bool, ["timeout"]=number}}
local ground_speedBarrier_sq = ground_speedBarrier*ground_speedBarrier
local airplane_speedBarrier_sq = airplane_speedBarrier*airplane_speedBarrier
local _,reallyHigh = Spring.GetGroundExtremes()
reallyHigh = reallyHigh + 40
factor_landLos_ofAirplane = factor_landLos_ofAirplane/100
factor_airLos_ofAirplane = factor_airLos_ofAirplane/100
factor_landLos_ofGroundUnits = factor_landLos_ofGroundUnits/100
factor_airLos_ofGroundUnits = factor_airLos_ofGroundUnits/100
--------------------------------------------------------------------------------
--Functions
function gadget:GameFrame(n) --check unit speed, exclude non-related
	if n%updateRate==0 then
		for unitID,_ in pairs(fastGroundUnitsID) do
			if spValidUnitID(unitID) then
				local velX,velY,velZ = spGetUnitVelocity(unitID)
				local netVelocity_squared = (velX*velX+velY*velY +velZ*velZ)
				local speedBarrier_squared = fastGroundUnitsID[unitID][1]
				if netVelocity_squared > speedBarrier_squared then --if unit is moving faster than speed barrier, then deal damage.
					local transported = spGetUnitTransporter(unitID)
					if not transported then
						if not fastGroundUnitsID[unitID].commited then
							local landSensorRadius = fastGroundUnitsID[unitID][2]
							local airSensorRadius = fastGroundUnitsID[unitID][3]
							local canFly = fastGroundUnitsID[unitID][4]
							local landLos_reduceFactor = (canFly and factor_landLos_ofAirplane) or factor_landLos_ofGroundUnits
							local airLos_reduceFactor = (canFly and factor_airLos_ofAirplane) or factor_airLos_ofGroundUnits
							spSetUnitSensorRadius(unitID, "los", landSensorRadius*landLos_reduceFactor ) --remove surface sensor
							spSetUnitSensorRadius(unitID, "airLos", airSensorRadius*airLos_reduceFactor)
							fastGroundUnitsID[unitID].commited = true
							fastGroundUnitsID[unitID].timeout = 30*airplaneSpeedBoostPeriod
						end
						local x, y, z = spGetUnitPosition(unitID)
						if not canFly and x > reallyHigh then --higher than any hill
							spSpawnCEG("raventrail", x, y , z) -- meteor trail
						end
					end
				else --unit is slowing down/ too slow
					if fastGroundUnitsID[unitID].commited then
						local landSensorRadius = fastGroundUnitsID[unitID][2]
						local airSensorRadius = fastGroundUnitsID[unitID][3]
						spSetUnitSensorRadius(unitID, "los", landSensorRadius) --restore surface sensor
						spSetUnitSensorRadius(unitID, "airLos", airSensorRadius)
						fastGroundUnitsID[unitID].commited = false
					end
					local canFly = fastGroundUnitsID[unitID][4]
					if not canFly then --delete entry for ground unit
						fastGroundUnitsID[unitID] = nil
					elseif fastGroundUnitsID[unitID].timeout >0 then --continue monitoring air unit until timeout (because airplane can bank/turn and this slow them down temporarily)
						fastGroundUnitsID[unitID].timeout = fastGroundUnitsID[unitID].timeout - updateRate
					elseif fastGroundUnitsID[unitID].timeout <= 0 then --delete entry for air unit
						fastGroundUnitsID[unitID] = nil
					end
				end
			else --invalid unit
				fastGroundUnitsID[unitID] = nil
			end
		end
	end
end

function GG.setUnitExcessSpeed(unitID,unitDefID) --set this as global function so other mod can turn this gadget off by overriding this function and return False.
	local canFly = UnitDefs[unitDefID].canFly
	if (enableForAirplane and canFly) or (enableForGroundUnits and not canFly) then
		local speedBarrier_squared = (canFly and airplane_speedBarrier_sq) or ground_speedBarrier_sq
		local landSensorRadius = spGetUnitSensorRadius(unitID, "los")
		local airSensorRadius = spGetUnitSensorRadius(unitID,  "airLos")
		fastGroundUnitsID[unitID]={speedBarrier_squared,landSensorRadius,airSensorRadius,canFly, commited = false, timeout=2}
	end
	
	local transporting = spGetUnitIsTransporting(unitID)
	if transporting then --reference: weapon_impulse.lua
		for i = 1, #transporting do
			local transportedUnitID = transporting[i]
			local transportedUnitDefID = spGetUnitDefID(transportedUnitID)
			if transportedUnitDefID then
				canFly = UnitDefs[transportedUnitDefID].canFly
				if (enableForAirplane and canFly) or (enableForGroundUnits and not canFly) then
					local speedBarrier_squared = (canFly and airplane_speedBarrier_sq) or ground_speedBarrier_sq
					local landSensorRadius = spGetUnitSensorRadius(unitID, "los")
					local airSensorRadius = spGetUnitSensorRadius(unitID,  "airLos")
					fastGroundUnitsID[transportedUnitID]={speedBarrier_squared,landSensorRadius,airSensorRadius,canFly, commited = false, timeout=2}
				end
			end
		end
	end
end

--Using CommandFallback to detect fighter sprint (reference: oneclick_weapon_defs.lua by KR)
function gadget:CommandFallback(unitID, unitDefID, unitTeam, cmdID, cmdParams, cmdOptions)
	if cmdID == CMD_ONECLICK_WEAPON and not fastGroundUnitsID[unitID] then --exclude duplicate
		GG.setUnitExcessSpeed(unitID,unitDefID)
	end
	return false
end

function gadget:UnitDestroyed(unitID, unitDefID, unitTeam)
	if fastGroundUnitsID[unitID] then
		fastGroundUnitsID[unitID] = nil
	end
end

--We identify any units that might accelerate to extreme speed due to Newton, explosion, or collision with other units. 
function gadget:UnitPreDamaged(unitID, unitDefID, unitTeam, damage, paralyzer, weaponDefID, attackerID, attackerDefID, attackerTeam) -- example: "Fall Damage" & "Weapon Impulse", unit_fall_damage.lua & weapon_impulse.lua, by GoogleFrog 
	if 	not UnitDefs[unitDefID].isBuilding and 
	not UnitDefs[unitDefID].isFactory and 
	not fastGroundUnitsID[unitID] then --exclude airplane, exclude factory, exclude duplicate
		GG.setUnitExcessSpeed(unitID,unitDefID)
	end
end

end