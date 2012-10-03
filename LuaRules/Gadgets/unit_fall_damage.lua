
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

local UNIT_UNIT_SPEED = 5.5
local UNIT_UNIT_DAMAGE_FACTOR = 0.8
local TANGENT_DAMAGE = 0.5

local attributes = {}

for unitDefID=1,#UnitDefs do
	local ud = UnitDefs[unitDefID]
	attributes[unitDefID] = {
		elasticity = tonumber(ud.customParams.elasticity) or 0.3,
		friction = tonumber(ud.customParams.friction) or 0.8,
		outOfMapDamagePerElmo = ud.health/800,
		velocityDamageThreshold = 3,
		velocityDamageScale = ud.mass*0.6,
	}
	if ud.speed == 0 then -- buildings are more massive
		attributes[unitDefID].velocityDamageScale = attributes[unitDefID].velocityDamageScale*10
	end
end

local excludedUnitID = {}
GG.FallDamage = {}

function GG.FallDamage.ExcludeFriendlyCollision(unitID)  --ref: http://answers.springlobby.info/questions/5/lua-unit-script-gadget-communication
	excludedUnitID[unitID] = true
end

function GG.FallDamage.IncludeFriendlyCollision(unitID)  
	excludedUnitID[unitID] = nil
end

local function outsideMapDamage(unitID, unitDefID)
	local att = attributes[unitDefID]
	local x,y,z = Spring.GetUnitPosition(unitID)
	if x < 0 or z < 0 or x > MAP_X or z > MAP_Z then
		return math.max(-x,-z,x-MAP_X,z-MAP_Z)*att.outOfMapDamagePerElmo
	else
		return 0
	end
end


local function speedToDamage(unitID, unitDefID, speed)
	local armor = select(2,Spring.GetUnitArmored(unitID)) or 1
	local att = attributes[unitDefID]
	if speed > att.velocityDamageThreshold then
		return (speed-att.velocityDamageThreshold)*att.velocityDamageScale
	else
		return 0
	end
end

local unitCollide = {}
local clearTable = false

-- weaponDefID -1 --> debris collision
-- weaponDefID -2 --> ground collision
-- weaponDefID -3 --> object collision
-- weaponDefID -4 --> fire damage
-- weaponDefID -5 --> kill damage

function gadget:UnitPreDamaged(unitID, unitDefID, unitTeam, damage, paralyzer, weaponDefID, attackerID, attackerDefID, attackerTeam)
	-- unit or wreck collision
	if (weaponDefID == -3 or weaponDefID == -1) and attackerID == nil then
		--Spring.Echo("COLLIDE")
		if unitCollide[damage] then
			local data = unitCollide[damage]
			local amongExcludedUnits = excludedUnitID[unitID] or excludedUnitID[data.unitID]
			local skipDamage = false
			if amongExcludedUnits then 
				local allyID = Spring.GetUnitAllyTeam(unitID)
				if allyID == data.unitAlliance then
					skipDamage = true
				end
			end
			local vx,vy,vz = Spring.GetUnitVelocity(unitID)
			local damageToDeal = 0
			if not skipDamage and (data.certainDamage or math.sqrt(vx^2 + vy^2 + vz^2) > UNIT_UNIT_SPEED) then
				local speed = math.sqrt((vx - data.vx)^2 + (vy - data.vy)^2 + (vz - data.vz)^2)
				local otherDamage = speedToDamage(data.unitID, data.unitDefID, speed)
				local myDamage = speedToDamage(unitID, unitDefID, speed)
				damageToDeal = math.min(myDamage, otherDamage) * UNIT_UNIT_DAMAGE_FACTOR -- deal the damage of the least massive unit
				Spring.AddUnitDamage(data.unitID, damageToDeal, 0, nil, -7)
			end
			return damageToDeal
		else
			local allyID = Spring.GetUnitAllyTeam(unitID)
			local vx,vy,vz = Spring.GetUnitVelocity(unitID)
			local speed = math.sqrt(vx^2 + vy^2 + vz^2)
			local x0, y0, z0 = Spring.GetUnitPosition(unitID)
			unitCollide[damage] = {
				unitID = unitID,
				unitDefID = unitDefID,
				vx = vx, vy = vy, vz = vz,
				x0 = x0, y0= y0, z0=z0,
				certainDamage = speed > UNIT_UNIT_SPEED,
				unitAlliance = allyID
			}
			clearTable = true
		end
		
		return 0 -- units bounce and damage themselves.
	end
	
	-- ground collision
	if weaponDefID == -2 and attackerID == nil and Spring.ValidUnitID(unitID) and UnitDefs[unitDefID] then

		-- modify the unit velocity in two components; normal and tangent
		-- normal is multiplied by elasticity, tangent by friction
		-- unit takes damage based on velocity at normal to terrain + TANGENT_DAMAGE of velocity of tangent
		local att = attributes[unitDefID]
		local vx,vy,vz = Spring.GetUnitVelocity(unitID)
		local x,y,z = Spring.GetUnitPosition(unitID)
		local nx, ny, nz = Spring.GetGroundNormal(x,z)
		local nMag = math.sqrt(nx^2 + ny^2 + nz^2)
		local nx, ny, nz = nx/nMag, ny/nMag, nz/nMag -- normal to unit vector
		nx, ny, nz = vx*nx, vy*ny, vz*nz -- normal is now a component of velocity
		local tx, ty, tz = vx-nx, vy-ny, vz-nz -- tangent is the other component of velocity
		local nf = att.elasticity
		local tf = att.friction
		vx, vy, vz = tx*tf + nx*nf, ty*tf + ny*nf, tz*tf + nz*nf
		Spring.SetUnitVelocity(unitID,vx,vy,vz)
		local damgeSpeed = math.sqrt((nx + tx*TANGENT_DAMAGE)^2 + (ny + ty*TANGENT_DAMAGE)^2 + (nz + tz*TANGENT_DAMAGE)^2)
	
		return speedToDamage(unitID, unitDefID, damgeSpeed) + outsideMapDamage(unitID, unitDefID)
	end
	return damage
end

function gadget:GameFrame(f)
	if clearTable then
		unitCollide = {}
		clearTable = false
	end
end