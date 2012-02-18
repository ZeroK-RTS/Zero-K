
function gadget:GetInfo()
  return {
    name      = "Fall Damage",
    desc      = "Handles fall damage and out of map units",
    author    = "Google Frog",
    date      = "18 Feb 2012",
    license   = "GNU GPL, v2 or later",
    layer     = 0,
    enabled   = true  --  loaded by default?
  }
end

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------

if (not gadgetHandler:IsSyncedCode()) then
    return
end

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------

local MAP_X = Game.mapX*512
local MAP_Z = Game.mapY*512
local GRAVITY = Game.gravity

local attributes = {}

for unitDefID=1,#UnitDefs do
	local ud = UnitDefs[unitDefID]
	attributes[unitDefID] = {
		elasticity = tonumber(ud.customParams.elasticity) or 0.3,
		outOfMapDamagePerElmo = ud.health/800,
		velocityDamageThreashold = 3,
		velocityDamageScale = ud.mass*0.6,
	}
end

function gadget:UnitPreDamaged(unitID, unitDefID, unitTeam, damage, paralyzer, weaponID, attackerID, attackerDefID, attackerTeam)
	-- ground collision
	if weaponDefId == nil and attackerID == nil and Spring.ValidUnitID(unitID) and UnitDefs[unitDefID] then
		local att = attributes[unitDefID]
		local ud = UnitDefs[unitDefID]
		local vx,vy,vz = Spring.GetUnitVelocity(unitID)
		local x,y,z = Spring.GetUnitPosition(unitID)
		--local normal = Spring.GetGroundNormal(x,z)
		local speed = math.sqrt(vx^2 + vy^2 + vz^2)

		local outsideDamage = 0
		if x < 0 or z < 0 or x > MAP_X or z > MAP_Z then
			outsideDamage = math.max(-x,-z,x-MAP_X,z-MAP_Z)*att.outOfMapDamagePerElmo
		end

		local fallDamage = 0
		if speed > att.velocityDamageThreashold then
			fallDamage = (speed-att.velocityDamageThreashold)*att.velocityDamageScale
		end
		
		local elasticity = att.elasticity
		Spring.SetUnitVelocity(unitID,vx*elasticity,vy*elasticity,vz*elasticity)
		
		return fallDamage + outsideDamage
	end
	return damage
end
