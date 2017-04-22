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
local NeedWaitWait = {
	[UnitDefNames["chicken"].id] = true,
}

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
local DEBRIS_SPRING_DAMAGE_MULTIPLIER = 2.5 --tweaked arbitrarily

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
	if ud.speed == 0 then -- buildings are more massive
		attributes[unitDefID].velocityDamageScale = attributes[unitDefID].velocityDamageScale*10
	end
end

local wantedWeaponList = {-1, -2, -3}

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

local function SpringSpeedToDamage(colliderrMass,collideeeMass,relativeSpeed) --Inelastic collision. Reference: Spring/rts/Sim/MoveTypes/GroundMoveType.cpp#875
	local COLLISION_DAMAGE_MULT = 0.02 --Reference: Spring/rts/Sim/MoveTypes/GroundMoveType.cpp#66
	local MAX_UNIT_SPEED = 1000 --Reference: Spring/rts/Sim/Misc/GlobalConstants.h 
	local impactSpeed = relativeSpeed * 0.5; 
	local colliderRelMass = (colliderrMass / (colliderrMass + collideeeMass));
	local colliderRelImpactSpeed = impactSpeed * (1 - colliderRelMass);
	local collideeRelImpactSpeed = impactSpeed * (colliderRelMass);
	local colliderImpactDmgMult = math.min(colliderRelImpactSpeed * colliderrMass * COLLISION_DAMAGE_MULT, MAX_UNIT_SPEED);
	local collideeImpactDmgMult = math.min(collideeRelImpactSpeed * colliderrMass * COLLISION_DAMAGE_MULT, MAX_UNIT_SPEED);
	-- colliderImpactDmgMult = math.modf(colliderImpactDmgMult) --in case fraction need to be removed
	-- collideeImpactDmgMult = math.modf(collideeImpactDmgMult)
	
	return colliderImpactDmgMult, collideeImpactDmgMult
end

local function IsDamageMatch(collideeeData,colliderrData,relativeSpeed)
	local colliderrExpected, collideeeExpected = SpringSpeedToDamage(colliderrData.mass,collideeeData.mass,relativeSpeed)
	for i=1, #colliderrData.givenDamage do
		for j=1, #collideeeData.givenDamage do
			local collideWithBuilding = colliderrData.givenDamage[i] == collideeeData.givenDamage[j]
			local collideWithUnit= colliderrExpected==colliderrData.givenDamage[i] and collideeeExpected==collideeeData.givenDamage[j]
			if collideWithUnit or collideWithBuilding then
				return i, j
			end
		end
	end
	return false,false
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

GG.SetUnitPermanentFallDamageImmunity = SetUnitPermanentFallDamageImmunity
GG.SetUnitFallDamageImmunity = SetUnitFallDamageImmunity
GG.SetUnitFallDamageImmunityFeature = SetUnitFallDamageImmunityFeature
GG.SetNoDamageToAllyCollidee=SetNoDamageToAllyCollidee

-------------------------------------------------------------------
-------------------------------------------------------------------

local unitCollide = {}
local clearTable = false

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
		if unitCollide[unitID] then
			local collisionCount = unitCollide[unitID].collisionCount + 1
			unitCollide[unitID].collisionCount = collisionCount
			unitCollide[unitID].givenDamage[collisionCount] = damage
		else
			local vx,vy,vz = Spring.GetUnitVelocity(unitID)
			local speed = math.sqrt(vx^2 + vy^2 + vz^2)
			unitCollide[unitID] = {
				unitDefID = unitDefID,
				vx = vx, vy = vy, vz = vz,
				certainDamage = speed > UNIT_UNIT_SPEED,
				speed = speed,
				collisionCount = 1,
				givenDamage = {damage},
				mass = attributes[unitDefID].mass,
			}
			clearTable = true
		end
		return 0 -- units bounce but don't damage themselves.
	end
	
	-- ground collision
	if weaponDefID == -2 and attackerID == nil and Spring.ValidUnitID(unitID) and UnitDefs[unitDefID] then
	
		-- Unit AI and script workarounds.
		if NeedWaitWait[unitDefID] then
			Spring.GiveOrderToUnit(unitID,CMD.WAIT, {}, {})
			Spring.GiveOrderToUnit(unitID,CMD.WAIT, {}, {})
		end
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
		local vx,vy,vz = Spring.GetUnitVelocity(unitID)
		local x,y,z = Spring.GetUnitPosition(unitID)
		local nx, ny, nz = Spring.GetGroundNormal(x,z)
		local nMag = math.sqrt(nx^2 + ny^2 + nz^2)
		local nx, ny, nz = nx/nMag, ny/nMag, nz/nMag -- normal to unit vector
		nx, ny, nz = vx*nx, vy*ny, vz*nz -- normal is now a component of velocity
		local tx, ty, tz = vx-nx, vy-ny, vz-nz -- tangent is the other component of velocity
		local nf = att.elasticity
		local tf = att.friction
		vx, vy, vz = tx*tf - nx*nf, ty*tf - ny*nf, tz*tf - nz*nf
		Spring.SetUnitVelocity(unitID,0,0,0)
		Spring.AddUnitImpulse(unitID,vx,vy,vz) --must do impulse because SetUnitVelocity() is not fully functional in Spring 91 (only work with vertical velocity OR when assigned 0)
		local damgeSpeed = math.sqrt((nx + tx*TANGENT_DAMAGE)^2 + (ny + ty*TANGENT_DAMAGE)^2 + (nz + tz*TANGENT_DAMAGE)^2)
		return LocalSpeedToDamage(unitID, unitDefID, damgeSpeed) + outsideMapDamage(unitID, unitDefID)
	end
	
	if weaponDefID == -1 then
		return 20
	end
	
	return damage
end

-- function gadget:FeaturePreDamaged() --require Spring 95
-- end

function gadget:GameFrame(frame)
	gameframe = frame
	if clearTable then
		for colliderrID, colliderrData in pairs(unitCollide) do
			repeat --for "continue" if collisionCount==0
			if colliderrData.collisionCount == 0 then --unit already finish processed
				break;
			end
			local crx,cry,crz = colliderrData.x, colliderrData.y, colliderrData.z
			for collideeeID, collideeeData in pairs(unitCollide) do
				if collideeeID~= colliderrID and collideeeData.collisionCount > 0 then --if collideee not yet processed:
					local vx,vy,vz = collideeeData.vx, collideeeData.vy, collideeeData.vz
					local relativeSpeed = math.sqrt((vx - colliderrData.vx)^2 + (vy - colliderrData.vy)^2 + (vz - colliderrData.vz)^2)
					local dmgMatchColliderr,dmgMatchCollideee = IsDamageMatch(collideeeData,colliderrData,relativeSpeed)
					if dmgMatchColliderr then --unit matched by damage
						local unitDefID = collideeeData.unitDefID
						local noSelfDamage = false
						if NoDamageToSelf[colliderrData.unitDefID] and NoDamageToSelf[unitDefID] then
							noSelfDamage = true
						end
						if (colliderrData.certainDamage or collideeeData.certainDamage) and not noSelfDamage then
							local otherDamage = LocalSpeedToDamage(colliderrID, colliderrData.unitDefID, relativeSpeed)
							local myDamage = LocalSpeedToDamage(collideeeID, unitDefID, relativeSpeed)
							local damageToDeal = math.min(myDamage, otherDamage) * UNIT_UNIT_DAMAGE_FACTOR -- deal the damage of the least massive unit
							local isUnitAllied = (spGetUnitAllyTeam(colliderrID) == spGetUnitAllyTeam(collideeeID))
							local colliderImmune = false
							if unitImmune[colliderrID] then
								if unitImmune[colliderrID] < frame then
									unitImmune[colliderrID] = nil
								else
									colliderImmune = true
								end
							end
							if noDamageToAllyCollidee[collideeeID] then
								if noDamageToAllyCollidee[collideeeID] < frame then
									noDamageToAllyCollidee[collideeeID] = nil
								elseif isUnitAllied then
									colliderImmune = true
								end
							end
							if not colliderImmune then
								spAddUnitDamage(colliderrID, damageToDeal, 0, nil, -7)
							end
							local collideeImmune = false
							if unitImmune[collideeeID] then
								if unitImmune[collideeeID] < frame then
									unitImmune[collideeeID] = nil
								else
									collideeImmune = true
								end
							end
							if noDamageToAllyCollidee[colliderrID] then
								if noDamageToAllyCollidee[colliderrID] < frame then
									noDamageToAllyCollidee[colliderrID] = nil
								elseif isUnitAllied then
									collideeImmune = true
								end
							end
							if not collideeImmune then
								spAddUnitDamage(collideeeID, damageToDeal, 0, nil, -7)
							end
						end
						colliderrData.collisionCount = colliderrData.collisionCount - 1
						collideeeData.collisionCount = collideeeData.collisionCount - 1
						table.remove(colliderrData.givenDamage, dmgMatchColliderr)
						table.remove(collideeeData.givenDamage, dmgMatchCollideee)
						if colliderrData.collisionCount == 0 then
							break;
						end
					end
				end
			end
			if colliderrData.collisionCount >= 1 then --add damage to the rest of the collisionCount that doesn't have contact with any unit
			-- there is no unitID when colliding with feature. Will require gadget:FeaturePreDamaged() in Spring 95 if to get the featureID
				if unitImmuneFeature[colliderrID] then
					if unitImmuneFeature[colliderrID] < frame then
						unitImmuneFeature[colliderrID] = nil
						for i=1, #colliderrData.givenDamage do --use damage given by Spring
							spAddUnitDamage(colliderrID, DEBRIS_SPRING_DAMAGE_MULTIPLIER*colliderrData.givenDamage[i], 0, nil, -7)
						end
					end
				else
					for i=1, #colliderrData.givenDamage do --use damage given by Spring
						spAddUnitDamage(colliderrID, DEBRIS_SPRING_DAMAGE_MULTIPLIER*colliderrData.givenDamage[i], 0, nil, -7)
					end
				end
				colliderrData.collisionCount = 0 --mark this unit as processed
			end
			until (true) --exit repeat
		end
		unitCollide = {}
		clearTable = false
	end
end