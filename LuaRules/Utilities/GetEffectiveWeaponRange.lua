local function GetRangeModType(weaponDef)
	local modType = 0 --weapon targeting mod type
	if (weaponDef.type == "Cannon") or
	(weaponDef.type == "EmgCannon") or
	(weaponDef.type == "DGun" and weaponDef.gravityAffected) or
	(weaponDef.type == "AircraftBomb")
	then
		--Ballistic
		modType = 0
	elseif (weaponDef.type == "LaserCannon" or
	weaponDef.type == "BeamLaser" or
	weaponDef.type == "Melee" or
	weaponDef.type == "Flame" or
	weaponDef.type == "LightningCannon" or
	(weaponDef.type == "DGun" and not weaponDef.gravityAffected))
	then
		--Sphere
		modType = 1
	elseif (weaponDef.type == "MissileLauncher" or
	weaponDef.type == "StarburstLauncher" or
	weaponDef.type == "TorpedoLauncher")
	then
		--Cylinder
		modType = 2
	end
	return modType
end

local weaponAttributes = {}
for i = 1, #WeaponDefs do
	local weaponDef = WeaponDefs[i]
	weaponAttributes[i] = {
		modType = GetRangeModType(weaponDef),
		customMaxRange = weaponDef.range,
		customHeightMod = weaponDef.heightMod,
		customCylinderTargeting  = weaponDef.cylinderTargeting,
		customHeightBoost = weaponDef.heightBoostFactor,
		myGravity = weaponDef.myGravity,
		projectilespeed = (weaponDef.projectilespeed or 30),
	}
end

local unitWeapon = {}
local unitWeaponList = {}
for i = 1, #UnitDefs do
	local weaponList = UnitDefs[i].weapons
	if #weaponList > 0 then
		local maxRange
		for j = 1, #weaponList do
			local wd = WeaponDefs[weaponList[j].weaponDef]
			if wd and ((not maxRange) or wd.range > maxRange) then
				maxRange = wd.range
				unitWeapon[i] = weaponList[j].weaponDef
			end
		end
	end
end

local spGetGroundHeight = Spring.GetGroundHeight
local cos45degree = math.cos(math.pi/4) --use test range of 45 degree for optimal launch
local sin45degree = math.sin(math.pi/4)
local function CalculateBallisticConstant(deltaV,myGravity,heightDiff)
	--determine maximum range & time
	local xVel = cos45degree*deltaV --horizontal portion
	local yVel = sin45degree*deltaV --vertical portion
	local t = nil
	local yDist = heightDiff
	local a = myGravity
	-- 0 = yVel*t - a*t*t/2 --this is the basic equation of motion for vertical motion, we set distance to 0 or yDist (this have 2 meaning: either is launching from ground or is hitting ground) then we find solution for time (t) using a quadratic solver
	-- 0 = (yVel)*t - (a/2)*t*t --^same equation as above rearranged to highlight time (t)
	local discriminant =(yVel^2 - 4*(-a/2)*(yDist))^0.5
	local denominator = 2*(-a/2)
	local t1 = (-yVel + discriminant)/denominator ---formula for finding root for quadratic equation (quadratic solver). Ref: http://www.sosmath.com/algebra/quadraticeq/quadraformula/summary/summary.html
	local t2 = (-yVel - discriminant)/denominator
	local xDist1 = xVel*t1 --distance travelled horizontally in "t" amount of time
	local xDist2 = xVel*t2
	local maxRange = nil
	if xDist1>= xDist2 then
		maxRange=xDist1 --maximum range
		t=t1 --flight time
	else
		maxRange=xDist2
		t=t2
	end
	return maxRange, t --return maximum range and flight time.
end

local function CalculateModdedMaxRange(heightDiff, weapon)
	local effectiveRange = 0
	local heightModded = (heightDiff)*weapon.customHeightMod
	--equivalent to: GetRange2D():
	if weapon.modType == 0 then --Ballistic
		if not weapon.gameMyGravity then
			weapon.gameMyGravity = (weapon.myGravity > 0 and weapon.myGravity*888.888888) or (Game.gravity) or 0
			weapon.deltaV = weapon.projectilespeed*30
			local maxFlatRange = CalculateBallisticConstant(weapon.deltaV,weapon.gameMyGravity,0)
			weapon.scaleDown = weapon.customMaxRange/maxFlatRange --Example: UpdateRange() in Spring\rts\Sim\Weapons\Cannon.cpp
			weapon.heightBoostFactor = weapon.customHeightBoost
			if weapon.heightBoostFactor < 0 and weapon.scaleDown > 0 then
				weapon.heightBoostFactor = (2 - weapon.scaleDown) / math.sqrt(weapon.scaleDown) --such that: heightBoostFactor == 1 when scaleDown == 1
			end
		end
		heightModded = heightModded*weapon.heightBoostFactor
		local moddedRange = CalculateBallisticConstant(weapon.deltaV,weapon.gameMyGravity,heightModded)
		effectiveRange = moddedRange*weapon.scaleDown --Example: GetRange2D() in Spring\rts\Sim\Weapons\Cannon.cpp
	elseif weapon.modType == 1 then
		--SPHERE
		effectiveRange = math.sqrt(weapon.customMaxRange^2 - heightModded^2) --Pythagoras theorem. Example: GetRange2D() in Spring\rts\Sim\Weapons\Weapon.cpp
	elseif weapon.modType == 2 then
		--CYLINDER
		effectiveRange = weapon.customMaxRange - heightModded*weapon.customHeightMod --Example: GetRange2D() in Spring\rts\Sim\Weapons\StarburstLauncher.cpp
		--Note: for unknown reason we must "Minus the heightMod" instead of adding it. This is the opposite of what shown on the source-code, but ingame test suggest "Minus heightMod" and not adding.
	end
	if weapon.customCylinderTargeting >= 0.01 then --See Example: TestRange() in Spring\rts\Sim\Weapons\Weapon.cpp
		--STRICT CYLINDER
		if weapon.customCylinderTargeting * weapon.customMaxRange > math.abs(heightModded) then
			if weapon.modType == 0 then
				effectiveRange = math.min(effectiveRange, weapon.customMaxRange) --Ballistic is more complex, physically it have limited range when shooting upward
			else
				effectiveRange = weapon.customMaxRange --other weapon have no physic limit and should obey cylinder
			end
		else
			effectiveRange = 0 --out of Strict Cylinder bound
		end
	end
	return effectiveRange
end


--This function calculate effective range for unit with different target elevation.
--Note: heightDiff is (unitY - targetY)
--Note2: weaponNumOverride is defaulted to 1 if not specified
function Spring.Utilities.GetEffectiveWeaponRange(unitDefID, heightDiff, weaponNumOverride)
	if not unitDefID or not UnitDefs[unitDefID] then
		return 0
	end
	local weaponNumber = weaponNumOverride and math.modf(weaponNumOverride)
	local weaponDefID
	if weaponNumber then
		if not unitWeaponList[unitDefID] then
			unitWeaponList[unitDefID] = UnitDefs[unitDefID].weapons
			if #(unitWeaponList[unitDefID] or {}) < 1 then
				unitWeaponList[unitDefID] = 0
			end
		end
		if unitWeaponList[unitDefID] ~= 0 then
			weaponDefID = (unitWeaponList[unitDefID][weaponNumber] or {}).weaponDef
		end
	else
		weaponDefID = unitWeapon[unitDefID]
	end
	local effectiveMaxRange = 0
	if weaponDefID then
		heightDiff = heightDiff or 0
		effectiveMaxRange = CalculateModdedMaxRange(heightDiff, weaponAttributes[weaponDefID])
	end
	return effectiveMaxRange
end

--This function a cheap upper bound on Spring.Utilities.GetEffectiveWeaponRange
--Note: heightDiff is (unitY - targetY)
--Note2: weaponNumOverride is defaulted to 1 if not specified
function Spring.Utilities.GetUpperEffectiveWeaponRange(unitDefID, heightDiff, weaponNumOverride)
	if not unitDefID or not UnitDefs[unitDefID] then
		return 0
	end
	local weaponNumber = weaponNumOverride and math.modf(weaponNumOverride)
	local weaponDefID
	if weaponNumber then
		if not unitWeaponList[unitDefID] then
			unitWeaponList[unitDefID] = UnitDefs[unitDefID].weapons
			if #(unitWeaponList[unitDefID] or {}) < 1 then
				unitWeaponList[unitDefID] = 0
			end
		end
		if unitWeaponList[unitDefID] ~= 0 then
			weaponDefID = (unitWeaponList[unitDefID][weaponNumber] or {}).weaponDef
		end
	else
		weaponDefID = unitWeapon[unitDefID]
	end
	local effectiveMaxRange = 0
	if weaponDefID then
		local weapon = weaponAttributes[weaponDefID]
		heightDiff = heightDiff or 0
		if weapon.modType == 0 or heightDiff > 0 then -- Ballistic range gain
			effectiveMaxRange = CalculateModdedMaxRange(heightDiff, weapon)
		else
			effectiveMaxRange = weapon.customMaxRange
		end
	end
	return effectiveMaxRange
end
