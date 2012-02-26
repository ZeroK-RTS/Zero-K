
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
		velocityDamageThreshold = 3,
		velocityDamageScale = ud.mass*0.6,
	}
end

-- weaponDefID -1 --> debris collision
-- weaponDefID -2 --> ground collision
-- weaponDefID -3 --> object collision
-- weaponDefID -4 --> fire damage
-- weaponDefID -5 --> kill damage

function gadget:UnitPreDamaged(unitID, unitDefID, unitTeam, damage, paralyzer, weaponDefID, attackerID, attackerDefID, attackerTeam)
	--Spring.AddUnitImpulse(unitID,0,3,0)
	if weaponDefID == WeaponDefNames["corgrav_gravity_pos"].id or weaponDefID == WeaponDefNames["corgrav_gravity_neg"].id then

		local bx, by, bz = Spring.GetUnitBasePosition(unitID)
		local height = Spring.GetGroundHeight(bx,bz)
		if math.abs(by-height) < 0.01 then
			Spring.AddUnitImpulse(unitID,0,0.16,0)
		end
	end

	-- unit or wreck collision
	if weaponDefID == -3 and attackerID == nil then
		return 0 -- units bounce and damage themselves. This buffs drops though.
	end
	
	-- ground collision
	if weaponDefID == -2 and attackerID == nil and Spring.ValidUnitID(unitID) and UnitDefs[unitDefID] then
		
		local armor = select(2,Spring.GetUnitArmored(unitID)) or 1
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
		if speed > att.velocityDamageThreshold then
			fallDamage = (speed-att.velocityDamageThreshold)*att.velocityDamageScale
		end
		
		local elasticity = att.elasticity
		Spring.SetUnitVelocity(unitID,vx*elasticity,vy*elasticity,vz*elasticity)
		
		return fallDamage*armor + outsideDamage
	end
	return damage
end