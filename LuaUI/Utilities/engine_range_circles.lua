-- emulates engine range circles. By very_bad_soldier and versus666

local max   = math.max
local abs   = math.abs
local cos   = math.cos
local sin   = math.sin
local sqrt  = math.sqrt
local pi    = math.pi

local spGetGroundHeight = Spring.GetGroundHeight

local function GetRange2DWeapon(range, yDiff)
	local root1 = range * range - yDiff * yDiff
	if root1 < 0 then
		return 0
	else
		return sqrt(root1)
	end
end

local GAME_GRAVITY = Game.gravity / (Game.gameSpeed^2)
local function GetRange2DCannon( range, yDiff, projectileSpeed, rangeFactor, myGravity )
	local factor = 0.7071067
	local smoothHeight = 100.0
	local speed2d = projectileSpeed * factor
	local speed2dSq = speed2d * speed2d
	local gravity = myGravity or GAME_GRAVITY
	local heightBoostFactor = (2.0 - rangeFactor) / sqrt(rangeFactor)

	if yDiff < -smoothHeight then
		yDiff = yDiff * heightBoostFactor
	elseif yDiff < 0.0 then
		yDiff = yDiff * (1.0 + (heightBoostFactor - 1.0) * -yDiff / smoothHeight)
	end

	local root1 = speed2dSq + 2 * -gravity * yDiff
	if root1 < 0 then
		return 0
	else
		return rangeFactor * (speed2dSq + speed2d * sqrt(root1)) / gravity
	end
end

local function CalcBallisticCircle( x, y, z, range, weaponDef )
	local rangeLineStrip = {}
	local slope = 0.0

	local rangeFunc = GetRange2DWeapon
	local rangeFactor = 1.0 -- used by range2dCannon
	if weaponDef.type == "Cannon" then
		rangeFunc = GetRange2DCannon
		rangeFactor = range / GetRange2DCannon(range, 0.0, weaponDef.projectilespeed, rangeFactor)
		if rangeFactor > 1.0 or rangeFactor <= 0.0 then
			rangeFactor = 1.0
		end
	end

	local yGround = spGetGroundHeight(x, z)
	for i = 1, 40 do
		local radians = 2.0 * pi * i / 40
		local rAdj = range

		local sinR = sin(radians)
		local cosR = cos(radians)

		local posx = x + sinR * rAdj
		local posz = z + cosR * rAdj
		local posy = spGetGroundHeight(posx, posz)

		local heightDiff = (posy - yGround) / 2.0 -- maybe y has to be getGroundHeight(x,z) cause y is unit center and not aligned to ground

		rAdj = rAdj - heightDiff * slope
		local adjRadius = rangeFunc( range, heightDiff * weaponDef.heightMod, weaponDef.projectilespeed, rangeFactor )
		local adjustment = rAdj / 2.0
		local yDiff = 0.0

		for j = 0, 49 do
			if ( abs( adjRadius - rAdj ) + yDiff <= 0.01 * rAdj ) then
				break
			end

			if ( adjRadius > rAdj ) then
				rAdj = rAdj + adjustment
			else
				rAdj = rAdj - adjustment
				adjustment = adjustment / 2.0
			end
			posx = x + ( sinR * rAdj )
			posz = z + ( cosR * rAdj )
			local newY = spGetGroundHeight( posx, posz )
			yDiff = abs( posy - newY )
			posy = newY
			posy = max( posy, 0.0 )  --hack
			heightDiff = ( posy - yGround )	--maybe y has to be Ground(x,z)
			adjRadius = rangeFunc( range, heightDiff * weaponDef.heightMod, weaponDef.projectilespeed, rangeFactor, weaponDef.myGravity )
		end

		posx = x + ( sinR * adjRadius )
		posz = z + ( cosR * adjRadius )
		posy = spGetGroundHeight( posx, posz ) + 5.0
		posy = max( posy, 0.0 )   --hack

		rangeLineStrip[i] = { posx, posy, posz }
	end
	return rangeLineStrip
end

return CalcBallisticCircle
