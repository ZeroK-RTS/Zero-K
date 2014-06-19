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
	xDist1 = xVel*t1 --distance travelled horizontally in "t" amount of time
	xDist2 = xVel*t2
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

local reverseCompat = (Game.version:find('91.0') == 1)
local function CalculateModdedMaxRange(heightDiff,weaponDef,modType)
	local customMaxRange = weaponDef.range
	local customHeightMod = weaponDef.heightMod
	local customCylinderTargeting  = weaponDef.cylinderTargeting
	local customHeightBoost = weaponDef.heightBoostFactor
	local heightModded = (heightDiff)*customHeightMod
	local effectiveRange = 0
	--equivalent to: GetRange2D():
	if modType == 0 then --Ballistic
		local myGravity = (weaponDef.myGravity > 0 and weaponDef.myGravity*888.888888) or (Game.gravity) or 0
		local deltaV = weaponDef.projectilespeed*30
		local maxFlatRange = CalculateBallisticConstant(deltaV,myGravity,0)
		local scaleDown = customMaxRange/maxFlatRange --Example: UpdateRange() in Spring\rts\Sim\Weapons\Cannon.cpp
		local heightBoostFactor = customHeightBoost
		if heightBoostFactor < 0 and scaleDown > 0 then
			heightBoostFactor = (2 - scaleDown) / math.sqrt(scaleDown) --such that: heightBoostFactor == 1 when scaleDown == 1
		end
		heightModded = heightModded*heightBoostFactor
		local moddedRange = CalculateBallisticConstant(deltaV,myGravity,heightModded)
		effectiveRange = moddedRange*scaleDown --Example: GetRange2D() in Spring\rts\Sim\Weapons\Cannon.cpp
	elseif modType == 1 then 
		--SPHERE
		effectiveRange = math.sqrt(customMaxRange^2 - heightModded^2) --Pythagoras theorem. Example: GetRange2D() in Spring\rts\Sim\Weapons\Weapon.cpp
	elseif modType == 2 then 
		--CYLINDER
		effectiveRange = customMaxRange - heightModded*customHeightMod --Example: GetRange2D() in Spring\rts\Sim\Weapons\StarburstLauncher.cpp
		--Note: for unknown reason we must "Minus the heightMod" instead of adding it. This is the opposite of what shown on the source-code, but ingame test suggest "Minus heightMod" and not adding.
	end
	--equivalent to: TestRange():
	if reverseCompat and modType == 0 then
		customCylinderTargeting = 128
	end
	if customCylinderTargeting >= 0.01 then --See Example: TestRange() in Spring\rts\Sim\Weapons\Weapon.cpp
		--STRICT CYLINDER
		if customCylinderTargeting * customMaxRange > math.abs(heightModded) then
			if modType == 0 then
				effectiveRange = math.min(effectiveRange,customMaxRange) --Ballistic is more complex, physically it have limited range when shooting upward
			else
				effectiveRange = customMaxRange --other weapon have no physic limit and should obey cylinder
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
	local weaponNumber = weaponNumOverride and math.modf(weaponNumOverride) or 1
	heightDiff = heightDiff or 0
	local weaponList = UnitDefs[unitDefID].weapons
	local effectiveMaxRange = 0
	if #weaponList > 0 then
		if weaponNumber > #weaponList then
			Spring.Echo("Warning: No weapon no " .. weaponNumber .. " in unit's weapon list.") 
			weaponNumber = 1
		end
		local weaponDefID = weaponList[weaponNumber].weaponDef
		local weaponDef = WeaponDefs[weaponDefID]
		local modType = GetRangeModType(weaponDef)
		effectiveMaxRange = CalculateModdedMaxRange(heightDiff,weaponDef,modType)
	end
	return effectiveMaxRange
end