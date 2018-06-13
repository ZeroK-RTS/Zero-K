--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
if not gadgetHandler:IsSyncedCode() then
	return
end
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function gadget:GetInfo()
  return {
    name      = "Fall Damage",
    desc      = "Handles fall damage and out of map units",
    author    = "Google Frog, msafwan (unit matching by damage)",
    date      = "18 Feb 2012, 2 Jan 2014",
    license   = "GNU GPL, v2 or later",
    layer     = 0,
    enabled   = true  --  loaded by default?
  }
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- CONFIG
local NoDamageToSelf = {
	[UnitDefNames["chicken"].id] = true,
}

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------

local spGetUnitAllyTeam  = Spring.GetUnitAllyTeam
local spAddUnitDamage = Spring.AddUnitDamage

local MAP_X = Game.mapX*512
local MAP_Z = Game.mapY*512
local GRAVITY = Game.gravity

local UNIT_UNIT_SPEED = 5.5
local UNIT_UNIT_DAMAGE_FACTOR = 0.8
local TANGENT_DAMAGE = 0.5
local DEBRIS_SPRING_DAMAGE_MULTIPLIER = 10 --tweaked arbitrarily

local gameframe = Spring.GetGameFrame()
local attributes = {}

for unitDefID=1,#UnitDefs do
	local ud = UnitDefs[unitDefID]
	attributes[unitDefID] = {
		elasticity = tonumber(ud.customParams.elasticity) or 0.3,
		friction = tonumber(ud.customParams.friction) or 0.8,
		outOfMapDamagePerElmo = ud.health/800,
		velocityDamageThreshold = 3,
		velocityDamageScale = ud.mass*0.6,
		mass = ud.mass,
	}
	if ud.isImmobile then -- buildings are more massive
		attributes[unitDefID].velocityDamageScale = attributes[unitDefID].velocityDamageScale*10
	end
end

local wantedWeaponList = {-1, -2, -3}

local collisionDamageMult = {}
local fallDamageImmunityWeaponID = {}

for wdid = 1, #WeaponDefs do
	local wd = WeaponDefs[wdid]
	if wd.customParams and wd.customParams.falldamageimmunity then
		fallDamageImmunityWeaponID[wd.id] = tonumber(wd.customParams.falldamageimmunity)
		wantedWeaponList[#wantedWeaponList + 1] = wdid
	end
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


local function LocalSpeedToDamage(unitID, unitDefID, speed)
	local armor = select(2,Spring.GetUnitArmored(unitID)) or 1
	local att = attributes[unitDefID]
	if speed > att.velocityDamageThreshold then
		return (speed-att.velocityDamageThreshold)*att.velocityDamageScale
	else
		return 0
	end
end

local function SpringSpeedToDamage(colliderMass,collideeeMass,relativeSpeed) --Inelastic collision. Reference: Spring/rts/Sim/MoveTypes/GroundMoveType.cpp#875
	local COLLISION_DAMAGE_MULT = 0.02 --Reference: Spring/rts/Sim/MoveTypes/GroundMoveType.cpp#66
	local MAX_UNIT_SPEED = 1000 --Reference: Spring/rts/Sim/Misc/GlobalConstants.h 
	local impactSpeed = relativeSpeed * 0.5; 
	local colliderelMass = (colliderMass / (colliderMass + collideeeMass));
	local colliderelImpactSpeed = impactSpeed * (1 - colliderelMass);
	local collideeRelImpactSpeed = impactSpeed * (colliderelMass);
	local colliderImpactDmgMult = math.min(colliderelImpactSpeed * colliderMass * COLLISION_DAMAGE_MULT, MAX_UNIT_SPEED);
	local collideeImpactDmgMult = math.min(collideeRelImpactSpeed * colliderMass * COLLISION_DAMAGE_MULT, MAX_UNIT_SPEED);
	-- colliderImpactDmgMult = math.modf(colliderImpactDmgMult) --in case fraction need to be removed
	-- collideeImpactDmgMult = math.modf(collideeImpactDmgMult)
	
	return colliderImpactDmgMult, collideeImpactDmgMult
end

local unitPermanentImmune = {}

local function SetUnitPermanentFallDamageImmunity(unitID, immunity)
	unitPermanentImmune[unitID] = immunity
end

local unitImmune = {} -- units are immune to collision and fall damage

local function SetUnitFallDamageImmunity(unitID, frame)
	if (not unitImmune[unitID]) or unitImmune[unitID] < frame then
		unitImmune[unitID] = frame
	end
end

local unitImmuneFeature = {} -- units are immune to collision with un-identified feature

local function SetUnitFallDamageImmunityFeature(unitID, frame)
	if (not unitImmuneFeature[unitID]) or unitImmuneFeature[unitID] < frame then
		unitImmuneFeature[unitID] = frame
	end
end

local noDamageToAllyCollidee = {} -- units deal no damage to another unit during collision if its an ally (but can receive damage himself if not immune)

local function SetNoDamageToAllyCollidee(unitID, frame)
	if (not noDamageToAllyCollidee[unitID]) or noDamageToAllyCollidee[unitID] < frame then
		noDamageToAllyCollidee[unitID] = frame
	end
end

local function SetCollisionDamageMult(unitID, mult)
	collisionDamageMult[unitID] = mult
end

GG.SetUnitPermanentFallDamageImmunity = SetUnitPermanentFallDamageImmunity
GG.SetUnitFallDamageImmunity = SetUnitFallDamageImmunity
GG.SetUnitFallDamageImmunityFeature = SetUnitFallDamageImmunityFeature
GG.SetNoDamageToAllyCollidee = SetNoDamageToAllyCollidee
GG.SetCollisionDamageMult = SetCollisionDamageMult

-------------------------------------------------------------------
-------------------------------------------------------------------

local unitCollide = {}
local needGameFrame = false

-- weaponDefID -1 --> debris collision
-- weaponDefID -2 --> ground collision
-- weaponDefID -3 --> object collision
-- weaponDefID -4 --> fire damage
-- weaponDefID -5 --> kill damage

function gadget:UnitPreDamaged_GetWantedWeaponDef()
	return wantedWeaponList
end

function gadget:UnitPreDamaged(unitID, unitDefID, unitTeam, damage, paralyzer, weaponDefID, attackerID, attackerDefID, attackerTeam)
	
	if fallDamageImmunityWeaponID[weaponDefID] then
		SetUnitFallDamageImmunity(unitID, fallDamageImmunityWeaponID[weaponDefID] + gameframe)
		SetUnitFallDamageImmunityFeature(unitID, fallDamageImmunityWeaponID[weaponDefID] + gameframe)
	end
	
	-- unit or wreck collision
	if (weaponDefID == -3) and attackerID == nil and not unitPermanentImmune[unitID] then
		if not unitCollide[unitID] then
			local vx,vy,vz = Spring.GetUnitVelocity(unitID)
			local speed = math.sqrt(vx^2 + vy^2 + vz^2)
			unitCollide[unitID] = {
				unitDefID = unitDefID,
				vx = vx, vy = vy, vz = vz,
				certainDamage = speed > UNIT_UNIT_SPEED,
				speed = speed,
				givenDamage = damage,
				mass = attributes[unitDefID].mass,
			}
			needGameFrame = true
		end
		return 0 -- units bounce but don't damage themselves.
	end
	
	-- ground collision
	if weaponDefID == -2 and attackerID == nil and Spring.ValidUnitID(unitID) and UnitDefs[unitDefID] then
		-- Unit AI and script workarounds.
		GG.WaitWaitMoveUnit(unitID)
			
		local env = Spring.UnitScript.GetScriptEnv(unitID)
		if env and env.script.StartMoving then
			Spring.UnitScript.CallAsUnit(unitID, env.script.StartMoving)
		end
	
		if unitImmune[unitID] then
			if unitImmune[unitID] >= gameframe then
				return 0
			end
			unitImmune[unitID] = nil
		end
		-- modify the unit velocity in two components; normal and tangent
		-- normal is multiplied by elasticity, tangent by friction
		-- unit takes damage based on velocity at normal to terrain + TANGENT_DAMAGE of velocity of tangent
		local att = attributes[unitDefID]
		local vx,vy,vz, speed = Spring.GetUnitVelocity(unitID)
		local x,y,z = Spring.GetUnitPosition(unitID)
		local nx, ny, nz = Spring.GetGroundNormal(x,z)
		local nMag = math.sqrt(nx^2 + ny^2 + nz^2)
		nx, ny, nz = nx/nMag, ny/nMag, nz/nMag -- normal to unit vector
		nx, ny, nz = speed*nx, speed*ny, speed*nz -- normal is now a component of velocity
		local tx, ty, tz = vx - nx, vy - ny, vz - nz -- tangent is the other component of velocity
		local nf = att.elasticity
		local tf = att.friction
		vx, vy, vz = tx*tf + nx*nf - vx, ty*tf + ny*nf - vy, tz*tf + nz*nf - vz
		GG.AddGadgetImpulseRaw(unitID, vx, vy, vz, true, true)
		
		local env = Spring.UnitScript.GetScriptEnv(unitID)
		if env and env.script.StopMoving then
			env.script.StopMoving()
		end
		
		local damgeSpeed = math.sqrt((nx + tx*TANGENT_DAMAGE)^2 + (ny + ty*TANGENT_DAMAGE)^2 + (nz + tz*TANGENT_DAMAGE)^2)
		local damageTotal = LocalSpeedToDamage(unitID, unitDefID, damgeSpeed) + outsideMapDamage(unitID, unitDefID)
		damageTotal = damageTotal*(collisionDamageMult[unitID] or 1)
		return damageTotal
	end
	
	if weaponDefID == -1 then
		return 20
	end
	
	return damage
end

-- function gadget:FeaturePreDamaged() --require Spring 95
-- end

local function DoCollisionDamage(colliderID, colliderData, collidieeID, collidieeData)
	local vx,vy,vz = collidieeData.vx, collidieeData.vy, collidieeData.vz
	local myVx, myVy, myVz = colliderData.vx, colliderData.vy, colliderData.vz
	local relativeSpeed = math.sqrt((vx - myVx)^2 + (vy - myVy)^2 + (vz - myVz)^2)
	
	local unitDefID = collidieeData.unitDefID
	local noSelfDamage = false
	if NoDamageToSelf[colliderData.unitDefID] and NoDamageToSelf[unitDefID] then
		noSelfDamage = true
	end
	if (colliderData.certainDamage or collidieeData.certainDamage) and not noSelfDamage then
		local otherDamage = LocalSpeedToDamage(colliderID, colliderData.unitDefID, relativeSpeed)
		local myDamage = LocalSpeedToDamage(collidieeID, unitDefID, relativeSpeed)
		local damageToDeal = math.min(myDamage, otherDamage) * UNIT_UNIT_DAMAGE_FACTOR -- deal the damage of the least massive unit
		local isUnitAllied = (spGetUnitAllyTeam(colliderID) == spGetUnitAllyTeam(collidieeID))
		local colliderImmune = false
		
		local myMass = attributes[colliderData.unitDefID].mass
		local colMass = attributes[unitDefID].mass
		local myVelFrac = myMass/(myMass + colMass)
		
		local aVx = myVx*myVelFrac + vx*(1-myVelFrac)
		local aVy = myVy*myVelFrac + vy*(1-myVelFrac)
		local aVz = myVz*myVelFrac + vz*(1-myVelFrac)
		
		GG.AddGadgetImpulseRaw(colliderID, aVx - myVx, aVy - myVy, aVz - myVz, true, true)
		GG.AddGadgetImpulseRaw(collidieeID, aVx - vx, aVy - vy, aVz - vz, true, true)
		
		if unitImmune[colliderID] then
			if unitImmune[colliderID] < gameframe then
				unitImmune[colliderID] = nil
			else
				colliderImmune = true
			end
		end
		if noDamageToAllyCollidee[collidieeID] then
			if noDamageToAllyCollidee[collidieeID] < gameframe then
				noDamageToAllyCollidee[collidieeID] = nil
			elseif isUnitAllied then
				colliderImmune = true
			end
		end
		if not colliderImmune then
			spAddUnitDamage(colliderID, damageToDeal*(collisionDamageMult[colliderID] or 1), 0, nil, -7)
		end
		local collideeImmune = false
		if unitImmune[collidieeID] then
			if unitImmune[collidieeID] < gameframe then
				unitImmune[collidieeID] = nil
			else
				collideeImmune = true
			end
		end
		if noDamageToAllyCollidee[colliderID] then
			if noDamageToAllyCollidee[colliderID] < gameframe then
				noDamageToAllyCollidee[colliderID] = nil
			elseif isUnitAllied then
				collideeImmune = true
			end
		end
		if not collideeImmune then
			spAddUnitDamage(collidieeID, damageToDeal*(collisionDamageMult[collidieeID] or 1), 0, nil, -7)
		end
	end
end

function gadget:GameFrame(frame)
	gameframe = frame
	if needGameFrame then
		for colliderID, colliderData in pairs(unitCollide) do
			local smallestDist = nil
			local collidieeID = nil
			for otherID, _ in pairs(unitCollide) do
				if otherID ~= colliderID then
					local dist = Spring.GetUnitSeparation(colliderID, otherID, false, true)
					if dist and dist < (smallestDist or 20) then
						smallestDist = dist
						collidieeID = otherID
					end
				end
			end
			if collidieeID then
				local collidieeData = unitCollide[collidieeID]
				if collidieeData.alreadyCollided ~= colliderID then
					DoCollisionDamage(colliderID, colliderData, collidieeID, collidieeData)
					colliderData.alreadyCollided = collidieeID
				end
			else
				-- Assume feature collision if collidiee is not found.
				local vx,vy,vz = Spring.GetUnitVelocity(colliderID)
				if vx then
					local damageTotal = DEBRIS_SPRING_DAMAGE_MULTIPLIER*colliderData.givenDamage
					damageTotal = damageTotal*(collisionDamageMult[colliderID] or 1)
					spAddUnitDamage(colliderID, damageTotal, 0, nil, -7)
					GG.AddGadgetImpulseRaw(colliderID, -0.8*vx, -0.8*vy, -0.8*vz, true, true)
				end
			end
		end
		
		unitCollide = {}
		needGameFrame = false
	end
end
