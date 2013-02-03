--//Version 0.935
function gadget:GetInfo()
  return {
    name      = "Newton Throw Speed Damage",
    desc      = "Simply give damage to any unit that is thrown by Newton if it reach certain speed.",
    author    = "msafwan",
    date      = "3 Feb 2013",
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
local spAddUnitDamage = Spring.AddUnitDamage
local spGetUnitCollisionVolumeData = Spring.GetUnitCollisionVolumeData
local spGetUnitRadius = Spring.GetUnitRadius
local spGetUnitTransporter  = Spring.GetUnitTransporter 
local spGetUnitIsTransporting = Spring.GetUnitIsTransporting
local spGetUnitDefID =Spring.GetUnitDefID

--------------------------------------------------------------------------------
--Variables
local groundUnit_speedBarrier_squared = 5.09*5.09 -- maximum speed squared before damage is applied to ground unit. Comparison: dart 5.09 elmo-per-frame, glaives 3.8 elmo-per-frame, 
local airplane_speedBarrier_squared = 13*13 --maximum speed squared before damage is applied to airplane unit. Comparison: Avenger 13 elmo-per-frame, precision bomber 8.8 elmo-per-frame,  Vindicator 8 elmo-per-frame, Valkyrie 10.7 elmo-per-frame
local fastGroundUnitsID = {}
local updateRate = 30
--------------------------------------------------------------------------------
--Functions
function gadget:GameFrame(n) --check unit speed, exclude non-related and apply damage to related unit.
	if n%updateRate==0 then
		for unitID,_ in pairs(fastGroundUnitsID) do
			local velX,velY,velZ = spGetUnitVelocity(unitID)
			local netVelocity_squared = (velX*velX+velY*velY +velZ*velZ)
			local isAirplane = fastGroundUnitsID[unitID][2]
			local speedBarrier_squared = (isAirplane and airplane_speedBarrier_squared) or groundUnit_speedBarrier_squared
			if netVelocity_squared > speedBarrier_squared then --if unit is moving faster than the fastest unit: ie: the dart, then mark it as "UNSAFE SPEED".
				local transported = spGetUnitTransporter(unitID)
				if not transported then
					local crossSection = fastGroundUnitsID[unitID][1]
					spAddUnitDamage(unitID, crossSection, 0, nil, -7) --add damage proportional to crosssection every second
				end
			else --unit is not too fast
				fastGroundUnitsID[unitID] = nil
			end
		end
	end
end

function GG.setUnitExcessSpeed(unitID,canFly) --set this as global function so other mod can turn this gadget off by returning False.
	local sclX,sclY,sclZ = spGetUnitCollisionVolumeData(unitID) --get the diameter of the hit volume
	local radX = spGetUnitRadius(unitID) --get the radius of the collision volume
	local crossSection = math.max(sclX,sclY,sclZ,radX*2-8)
	fastGroundUnitsID[unitID]={crossSection,canFly}
	
	local transporting = spGetUnitIsTransporting(unitID)
	if transporting then --reference: weapon_impulse.lua
		for i = 1, #transporting do
			local transportedUnitID = transporting[i]
			local transportedUnitDefID = spGetUnitDefID(transportedUnitID)
			if transportedUnitDefID then
				sclX,sclY,sclZ = spGetUnitCollisionVolumeData(transportedUnitID) --get the diameter of the hit volume
				radX = spGetUnitRadius(transportedUnitID) --get the radius of the collision volume
				crossSection = math.max(sclX,sclY,sclZ,radX*2-8)
				canFly = UnitDefs[transportedUnitDefID].canFly
				fastGroundUnitsID[transportedUnitID]={crossSection,canFly}
			end
		end
	end
end

function gadget:UnitDestroyed(unitID, unitDefID, unitTeam)
	if fastGroundUnitsID[unitID] then
		fastGroundUnitsID[unitID] = nil
	end
end

--We identify any units that might accelerate to extreme speed due to Newton, explosion, or collision with other units. 
function gadget:UnitPreDamaged(unitID, unitDefID, unitTeam, damage, paralyzer, weaponDefID, attackerID, attackerDefID, attackerTeam) -- example: "Fall Damage" & "Weapon Impulse", unit_fall_damage.lua & weapon_impulse.lua, by GoogleFrog 
	if 	not UnitDefs[unitDefID].isBuilding and 
		not UnitDefs[unitDefID].isFactory then --exclude airplane, exclude factory
		local canFly = UnitDefs[unitDefID].canFly
		GG.setUnitExcessSpeed(unitID,canFly)
	end
end

end