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
local unitWantedVelocity

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

-- function gadget:FeaturePreDamaged() --require Spring 95
-- end

local function DoCollisionDamage(unitID, unitDefID, otherID)
	local myVx, myVy, myVz, mySpeed = Spring.GetUnitVelocity(unitID)
	local oVx, oVy, oVz, otherSpeed = Spring.GetUnitVelocity(otherID)
	local relativeSpeed = math.sqrt((oVx - myVx)^2 + (oVy - myVy)^2 + (oVz - myVz)^2)
	
	local otherUnitDefID = Spring.GetUnitDefID(otherID)
	local noSelfDamage = false
	if NoDamageToSelf[unitDefID] and NoDamageToSelf[otherUnitDefID] then
		noSelfDamage = true
	end
	if (mySpeed > UNIT_UNIT_SPEED or otherSpeed > UNIT_UNIT_SPEED) and not noSelfDamage then
		local otherDamage = LocalSpeedToDamage(unitID, unitDefID, relativeSpeed)
		local myDamage = LocalSpeedToDamage(otherID, otherUnitDefID, relativeSpeed)
		local damageToDeal = math.min(myDamage, otherDamage) * UNIT_UNIT_DAMAGE_FACTOR -- deal the damage of the least massive unit
		local isUnitAllied = (spGetUnitAllyTeam(unitID) == spGetUnitAllyTeam(otherID))
		local colliderImmune = false
		
		local myMass = attributes[unitDefID].mass
		local otherMass = attributes[otherUnitDefID].mass
		local myVelFrac = myMass/(myMass + otherMass)
		
		local aVx = myVx*myVelFrac + oVx*(1 - myVelFrac)
		local aVy = myVy*myVelFrac + oVy*(1 - myVelFrac)
		local aVz = myVz*myVelFrac + oVz*(1 - myVelFrac)
		
		unitWantedVelocity = unitWantedVelocity or {}
		unitWantedVelocity[#unitWantedVelocity + 1] = {unitID, aVx, aVy, aVz}
		unitWantedVelocity[#unitWantedVelocity + 1] = {otherID, aVx, aVy, aVz}
		--GG.AddGadgetImpulseRaw(unitID, aVx - myVx, aVy - myVy, aVz - myVz, true, true)
		--GG.AddGadgetImpulseRaw(otherID, aVx - oVx, aVy - oVy, aVz - oVz, true, true)
		
		if unitImmune[unitID] then
			if unitImmune[unitID] < gameframe then
				unitImmune[unitID] = nil
			else
				colliderImmune = true
			end
		end
		if noDamageToAllyCollidee[otherID] then
			if noDamageToAllyCollidee[otherID] < gameframe then
				noDamageToAllyCollidee[otherID] = nil
			elseif isUnitAllied then
				colliderImmune = true
			end
		end
		if not colliderImmune then
			spAddUnitDamage(unitID, damageToDeal*(collisionDamageMult[unitID] or 1), 0, nil, -7)
		end
		local collideeImmune = false
		if unitImmune[otherID] then
			if unitImmune[otherID] < gameframe then
				unitImmune[otherID] = nil
			else
				collideeImmune = true
			end
		end
		if noDamageToAllyCollidee[unitID] then
			if noDamageToAllyCollidee[unitID] < gameframe then
				noDamageToAllyCollidee[unitID] = nil
			elseif isUnitAllied then
				collideeImmune = true
			end
		end
		if not collideeImmune then
			spAddUnitDamage(otherID, damageToDeal*(collisionDamageMult[otherID] or 1), 0, nil, -7)
		end
	end
end

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
	if (weaponDefID == -3) and not unitPermanentImmune[unitID] then
		if attackerID == nil then
			-- Wreck collision
			local vx,vy,vz = Spring.GetUnitVelocity(unitID)
			if vx then
				local damageTotal = DEBRIS_SPRING_DAMAGE_MULTIPLIER*damage -- Why????
				damageTotal = damageTotal*(collisionDamageMult[unitID] or 1)
				--spAddUnitDamage(unitID, damageTotal, 0, nil, -7)
				
				unitWantedVelocity = unitWantedVelocity or {}
				unitWantedVelocity[#unitWantedVelocity + 1] = {unitID, 0.3}
				--GG.AddGadgetImpulseRaw(unitID, -1*vx, -1*vy, -1*vz, true, true)
				return damageTotal
			end
			return 0
		end
		
		-- Unit on unit collision
		unitAlreadyProcessed = unitAlreadyProcessed or {}
		if unitAlreadyProcessed[unitID] then
			unitAlreadyProcessed[unitID] = false
		else
			unitAlreadyProcessed[attackerID] = true
			DoCollisionDamage(unitID, unitDefID, attackerID)
			return 0
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
		local dot = nx*vx + ny*vy + nz*vz
		nx, ny, nz = dot*nx, dot*ny, dot*nz -- normal is now a component of velocity
		local tx, ty, tz = vx - nx, vy - ny, vz - nz -- tangent is the other component of velocity
		local nf = att.elasticity
		local tf = att.friction
		vx, vy, vz = tx*tf + nx*nf - vx, ty*tf + ny*nf - vy, tz*tf + nz*nf - vz
		GG.AddGadgetImpulseRaw(unitID, vx, vy, vz, true, true)
		
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

function gadget:GameFrame(frame)
	gameframe = frame
	if unitAlreadyProcessed then
		unitAlreadyProcessed = nil
	end
	if unitWantedVelocity then
		local alreadySet = {}
		for i = 1, #unitWantedVelocity do
			local unitID = unitWantedVelocity[i][1]
			if not alreadySet[unitID] then
				alreadySet[unitID] = true
				local vx, vy, vz, speed = Spring.GetUnitVelocity(unitID)
				if vx then
					if unitWantedVelocity[i][4] then
						-- Set mode
						local nx, ny, nz = unitWantedVelocity[i][2], unitWantedVelocity[i][3], unitWantedVelocity[i][4]
						GG.AddGadgetImpulseRaw(unitID, nx - vx, ny - vy, nz - vz, true, true)
					else
						-- Scale mode
						local scale = unitWantedVelocity[i][2] - 1
						GG.AddGadgetImpulseRaw(unitID, scale*vx, scale*vy, scale*vz, true, true)
					end
				end
			end
		end
		unitWantedVelocity = nil
	end
end
