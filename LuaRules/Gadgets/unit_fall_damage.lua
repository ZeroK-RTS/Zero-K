
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

local PERIOD = 5
local unitUpdates = {}
local onGround = {}

for i = 0, PERIOD-1 do
	unitUpdates[i] = {
		data = {},
		count = 0,
	}
end

for unitDefID=1,#UnitDefs do
	local ud = UnitDefs[unitDefID]
	attributes[unitDefID] = {
		elasticity = tonumber(ud.customParams.elasticity) or 0.3,
		outOfMapDamagePerElmo = ud.health/800,
		velocityDamageThreshold = 3,
		velocityDamageScale = ud.mass*0.6,
	}
end

function gadget:UnitPreDamaged(unitID, unitDefID, unitTeam, damage, paralyzer, weaponID, attackerID, attackerDefID, attackerTeam)
	--Spring.AddUnitImpulse(unitID,0,3,0)
	if weaponID == WeaponDefNames["corgrav_gravity_pos"].id or weaponID == WeaponDefNames["corgrav_gravity_neg"].id then

		local bx, by, bz = Spring.GetUnitBasePosition(unitID)
		local height = Spring.GetGroundHeight(bx,bz)
		if math.abs(by-height) < 0.01 then
			Spring.AddUnitImpulse(unitID,0,0.16,0)
		end
	end

	-- ground collision
	if weaponID == -1 and attackerID == nil and Spring.ValidUnitID(unitID) and UnitDefs[unitDefID] then
		
		-- check if the damage is really due to fall damage
		local armor = select(2,Spring.GetUnitArmored(unitID)) or 1
		local realDamage = damage/armor
		if realDamage == 0 or realDamage == 3 or realDamage > 48.999 and realDamage < 49.001 then
			return damage
		end		
		
		if onGround[unitID] then
			return 0
		end
		
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

function gadget:GameFrame(f)
	local units = unitUpdates[f%PERIOD]
	local i = 1
	while i < units.count do
		if Spring.ValidUnitID(units.data[i]) then
			local bx, by, bz = Spring.GetUnitBasePosition(units.data[i])
			local height = Spring.GetGroundHeight(bx,bz)
			onGround[units.data[i]] = math.abs(by-height) < 0.1
			i = i + 1
		else
			units.data[i] = units.data[units.count]
			units.data[units.count] = nil
			units.count = units.count - 1
		end
	end
end


function gadget:UnitCreated(unitID,unitDefID)
	local ud = UnitDefs[unitDefID]
	if not ud.canFly and ud.speed > 0 then
		local f = math.floor(math.random()*PERIOD)
		unitUpdates[f].count = unitUpdates[f].count + 1
		unitUpdates[f].data[unitUpdates[f].count] = unitID
	end
end

function gadget:Initialize()
	for _, unitID in ipairs(Spring.GetAllUnits()) do
		gadget:UnitCreated(unitID,Spring.GetUnitDefID(unitID))
	end
end