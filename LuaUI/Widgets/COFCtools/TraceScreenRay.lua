----------------------------------------------------------------------------
-------------------------Interface---------------------------------------
--this function provide an adjusted TraceScreenRay for null-space outside of the map (by msafwan)
--Custom Flags:
-- planeToHit = (integer) intersect a custom ground level. Note: is CPU cheaper than normal, and return intersect with Sphere of radius 2000 if looking away from the level.
-- sphereToHit = (integer) intersect a custom sphere. Note: it override result from planeToHit and is CPU cheaper than planeToHit.
-- returnRayDistance = (boolean) calculate ray-distance.
-- smoothMeshTarget = (boolean) true if caller is using Spring.GetSmoothMeshHeight to find ground heights
TraceCursorToGround = function (viewSizeX,viewSizeY,mousePos ,cs_fov, camPos, camRot,planeToHit,sphereToHit,returnRayDistance,smoothMeshTarget)
	--return gx,gy,gz,rx,ry,rz,rayDist,cancelCache
end
----------------------------------------------------------------------------
----------------------Under the hood------------------------------------
local tan = math.tan
local atan = math.atan
local atan2 = math.atan2
local abs	= math.abs
local min 	= math.min
local max	= math.max
local sqrt	= math.sqrt
local sin	= math.sin
local cos	= math.cos
local PI = math.pi
local HALFPI = math.pi/2
local spGetSmoothMeshHeight	= Spring.GetSmoothMeshHeight
local spGetGroundHeight = Spring.GetGroundHeight
local RADperDEGREE = PI/180

local function _ExtendedGetGroundHeight(x,z,smoothMeshTarget)
	--out of map. Bound coordinate to within map
	if x < 0 then x = 0; end
	if x > Game.mapSizeX then x=Game.mapSizeX; end
	if z < 0 then z = 0; end
	if z >  Game.mapSizeZ then z =  Game.mapSizeZ; end
	if smoothMeshTarget then
		return spGetSmoothMeshHeight(x,z)
	else
		return spGetGroundHeight(x,z)
	end
end

local function _FindGroundWithTrigonometry(outResult,effectiveHeading,camPos,xz_GrndDistRatio,vertGroundDist)
	--//Sphere-to-groundPosition translation (part2)//--
	--[[
	--illustration of conventional coordinate and Spring's coordinate:
	--Convention coordinate:
			 * +Z-axis
			 |
			 |
			 |
			 O - - - - -> +X-axis
	--Spring coordinate: (conventional trigonometry must be tweaked to be consistent with this coordinate system. High chance of bug!)
			 O - - - - -> +X-axis
			 |
			 |
			 |
			 v +Z-axis
	--]]
	local xzDist = xz_GrndDistRatio*(vertGroundDist) --calculate how far does the camera angle look pass the ground beneath
	local xDist = sin(effectiveHeading)*xzDist --break down the ground beneath into x and z component.  Note: using Sin() instead of regular Cos() because coordinate & angle is left handed
	local zDist = cos(effectiveHeading)*xzDist
	outResult.rx,outResult.ry,outResult.rz = xDist,vertGroundDist,zDist --relative 3d coordinate with respect to screen
	outResult.gx, outResult.gz = camPos.px+xDist,camPos.pz+zDist --estimated ground position infront of camera
end

local function _FindGroundWithHitScan(outResult,effectiveHeading,camPos,xz_GrndDistRatio,smoothMeshTarget)
	local currentGrndH, vertGroundDist = 0,-camPos.py
	if abs(xz_GrndDistRatio) == 0 then --is looking directly downward. Easy case, no need to find Ray intersecting with ground
		currentGrndH = _ExtendedGetGroundHeight(camPos.px,camPos.pz,smoothMeshTarget)
		vertGroundDist =  (currentGrndH - camPos.py)
		outResult.px,outResult.py,outResult.pz,outResult.cursorxzDist = camPos.px,currentGrndH,camPos.pz,0
		outResult.rx,outResult.ry,outResult.rz = 0,vertGroundDist,0
		return
	end

	local searchDirection = 1000
	local safetyCounter = 0
	
	local tx,tz,ty,cxzd = 0,0,0,1
	outResult.cursorxzDist = cxzd

	local cursorxDist,cursorzDist;
	while(safetyCounter<500 and cxzd>0 and cxzd<500000) do
		cxzd = cxzd + searchDirection
		safetyCounter = safetyCounter + 1
		cursorxDist = sin(effectiveHeading)*cxzd --break down the ground beneath into x and z component.  Note: using Sin() instead of regular Cos() because coordinate & angle is left handed
		cursorzDist = cos(effectiveHeading)*cxzd
		tx, tz = camPos.px+cursorxDist,camPos.pz+cursorzDist --estimated ground position infront of camera
		currentGrndH = _ExtendedGetGroundHeight(tx,tz,smoothMeshTarget)
		ty = (cxzd/xz_GrndDistRatio) + camPos.py
		if (camPos.py> 0 and currentGrndH >= ty) or (camPos.py< 0 and currentGrndH <= ty) then --condition meet, intersected the ground
			if searchDirection >0.1 then --but search is too coarse
				cxzd = outResult.cursorxzDist --go back
				searchDirection = searchDirection/10 --increase search accuracy
			else
				outResult.gx,outResult.gy,outResult.gz,outResult.cursorxzDist = tx,currentGrndH,tz,cxzd
				break --finish!
			end
		end
		outResult.gx,outResult.gy,outResult.gz,outResult.cursorxzDist = tx,currentGrndH,tz,cxzd --absolute coordinate
	end
	outResult.rx,outResult.ry,outResult.rz = cursorxDist,(outResult.gy - camPos.py),cursorzDist --relative to camera
end

local function _FindCoordinateInWorldSphere(outResult,effectiveHeading,camPos,new_x, new_y,new_z)
	--//Sphere-to-3d-coordinate translation//--
	--(calculate intercept of ray from mouse to sphere edge)
	local xzDist = sqrt(new_x*new_x + new_z*new_z)
	local xDist = sin(effectiveHeading)*xzDist --break down the ground beneath into x and z component.  Note: using Sin() instead of regular Cos() because coordinate & angle is left handed?
	local zDist = cos(effectiveHeading)*xzDist
	outResult.rx,outResult.ry,outResult.rz = xDist,new_y,zDist --relative 3d coordinate with respect to screen (sphere's edge)
	outResult.gx, outResult.gy, outResult.gz = camPos.px+xDist,camPos.py+new_y,camPos.pz+zDist --estimated ground position infront of camera (sphere's edge)
end
----------------------------------------------------------------------------
-------------------TraceCursorToGround------------------------------
TraceCursorToGround = function(viewSizeX,viewSizeY,mousePos ,cs_fov, camPos, camRot,planeToHit,sphereToHit,returnRayDistance,smoothMeshTarget)
	local halfViewSizeY = viewSizeY/2
	local halfViewSizeX = viewSizeX/2
	mousePos.y = mousePos.y- halfViewSizeY --convert screen coordinate to 0,0 at middle
	mousePos.x = mousePos.x- halfViewSizeX
	local currentFov = cs_fov/2 --in Spring: 0 degree is directly ahead and +FOV/2 degree to the left and -FOV/2 degree to the right
	--[[
	--Opengl screen FOV scaling logic:
	                                  >
	                              >    |
	                          >        |
	                      >            |
	                  >  |             |  Notice! : 90 FOV screen size == 2 times 45 FOV screen size
	              >      | <-45 FOV    |
	          >          |   reference |
	      >              |   screen    |
	      > --- FOV=45   |             |
	          >          |             |  <-- 90 FOV
	              >      |             |      new screen size
	                  >  |             |
	                      >            |
	                          >        |
	                              >    |
	                                  > <--ray cone
	--]]
	--//Opengl FOV scaling logic//--
	local referenceScreenSize = halfViewSizeY --because Opengl Glut use vertical screen size for FOV setting
	local referencePlaneDistance = referenceScreenSize -- because Opengl use 45 degree as default FOV, in which case tan(45)=1= referenceScreenSize/referencePlaneDistance
	local currentScreenSize = tan(currentFov*RADperDEGREE)*referencePlaneDistance --calculate screen size for current FOV if the distance to perspective projection plane is the default for 45 degree
	local resizeFactor = referenceScreenSize/currentScreenSize --the ratio of the default screen size to new FOV's screen size
	local perspectivePlaneDistance = resizeFactor*referencePlaneDistance --move perspective projection plane (closer or further away) so that the size appears to be as the default size for 45 degree
	--Note: second method is "perspectivePlaneDistance=halfViewSizeY/math.tan(currentFov*RADperDEGREE)" which yield the same result with 1 line.
	--[[
	--mouse-to-Sphere illustration:
	          ______                            ______
	          \     -----------_______----------      /
	            \    .      .     |     .     .     /
	             \   .     .    ..|.. $<cursor.    /
	              \   .   .   /   |   \   .  .    /
	              | --.---.--.----|----.--.--.----|    <--(bottom of) sphere surface flatten on 2d screen
	              /   .   .   \   |   /   .  .    \       so, cursor distance from center assume role of Inclination
	             /   .     .    ..|..    .    .    \      and, cursor position (left, right, or bottom) assume role of Azimuth
	            /    .      .     |     .     .     \
	          /    ____________-------__________      \
	          -----                             ------
	--]]
	--//mouse-to-Sphere projection//--
	local distanceFromCenter = sqrt(mousePos.x*mousePos.x+mousePos.y*mousePos.y) --mouse cursor distance from center screen. We going to simulate a Sphere dome which we will position the mouse cursor.
	local inclination = atan(distanceFromCenter/perspectivePlaneDistance) --translate distance in 2d plane to angle projected from the Sphere
	inclination = inclination -PI/2 --offset 90 degree because we want to place the south hemisphere (bottom) of the dome on the screen
	local azimuth = atan2(-mousePos.x,mousePos.y) --convert x,y to angle, so that left is +degree and right is -degree. Note: negative x flip left-right or right-left (flip the direction of angle)
	--//Sphere-to-coordinate conversion//--
	--(x,y,z floating in space)
	local virtualSphere = sphereToHit or 2000
	local sphere_x = virtualSphere* sin(azimuth)* cos(inclination) --convert Sphere coordinate back to Cartesian coordinate to prepare for rotation procedure
	local sphere_y = virtualSphere* sin(inclination)
	local sphere_z = virtualSphere* cos(azimuth)* cos(inclination)
	--//coordinate rotation 90+x degree//--
	--(x,y,z rotated in space)
	local rotateToInclination = PI/2+camRot.rx --rotate to +90 degree facing the horizon then rotate to camera's current facing.
	local new_x = sphere_x --rotation on x-axis
	local new_y = sphere_y* cos (rotateToInclination) + sphere_z* sin (rotateToInclination) --move points of Sphere to new location
	local new_z = sphere_z* cos (rotateToInclination) - sphere_y* sin (rotateToInclination)
	--//coordinate-to-Sphere conversion//--
	--(Inclination and Azimuth for x,y,z)
	local cursorTilt = atan2(new_y,sqrt(new_z*new_z+new_x*new_x)) --convert back to Sphere coordinate. See: http://en.wikipedia.org/wiki/Spherical_coordinate_system for conversion formula.
	local cursorHeading = atan2(new_x,new_z) --Sphere's azimuth
	
	local outResult = {gx=-1, gy=-1, gz=-1,rx=-1,ry=-1,rz=-1,cursorxzDist=-1}
	local cancelCache = false
	local rayDist,groundDistSign = -1,-1

	--//Sphere-to-groundPosition translation (part1)//--
	--(calculate intercept of ray from mouse to a flat ground)
	local effectiveHeading = camRot.ry+cursorHeading
	local tiltSign = abs(cursorTilt)/cursorTilt --Sphere's inclination direction (positive upward or negative downward)
	local cursorTiltComplement = (PI/2-abs(cursorTilt))*tiltSign --return complement angle for cursorTilt. Note: we use 0 degree when look down, and 90 degree when facing the horizon. This simplify the problem conceptually. (actual case is 0 degree horizon and +-90 degree up/down)
	cursorTiltComplement = min(HALFPI,abs(cursorTiltComplement))*tiltSign --limit to 89 degree to avoid infinity in math.tan()
	local xz_GrndDistRatio = tan(cursorTiltComplement)
	
	if not sphereToHit then
		if planeToHit then
			local vertGroundDist = planeToHit-camPos.py --distance to ground
			groundDistSign = abs(vertGroundDist)/vertGroundDist --negative when ground is below, positive when ground is above
			_FindGroundWithTrigonometry(outResult,effectiveHeading,camPos,xz_GrndDistRatio,vertGroundDist)
			outResult.gy = planeToHit
		else
				_FindGroundWithHitScan(outResult,effectiveHeading,camPos,xz_GrndDistRatio,smoothMeshTarget)
				local vertGroundDist = outResult.gy-camPos.py --distance to ground
				groundDistSign = abs(vertGroundDist)/vertGroundDist --negative when ground is below, positive when ground is above
		end
	end
	if sphereToHit or (groundDistSign + tiltSign == 0) then ---handle a special case when camera/cursor is facing away from ground (ground & camera sign is different).
		_FindCoordinateInWorldSphere(outResult,effectiveHeading,camPos,new_x, new_y,new_z)
		rayDist = sphereToHit;
		cancelCache = true --force cache update next run (because zooming the sky will end when cam reach the edge of the sphere, so we must always calculate next sphere)
	elseif returnRayDistance then
		rayDist = math.sqrt(outResult.cursorxzDist^2+outResult.ry^2)
	end
	--Finish
	if false then
		-- Spring.MarkerAddPoint(outResult.gx, outResult.gy, outResult.gz, "here")
		-- Spring.Echo(planeToHit)
		-- Spring.Echo(sphereToHit)
		-- Spring.Echo(math.modf(outResult.gx)..",".. math.modf(outResult.gy)..",".. math.modf(outResult.gz))
		-- Spring.Echo(math.modf(outResult.rx)..",".. math.modf(outResult.ry)..",".. math.modf(outResult.rz))
	end
	return outResult.gx,outResult.gy,outResult.gz,outResult.rx,outResult.ry,outResult.rz,rayDist,cancelCache
	--Most important credit to!:
	--0: Google search service
	--1: "Perspective Projection: The Wrong Imaging Model" by Margaret M. Fleck (http://www.cs_illinois.edu/~mfleck/my-papers/stereographic-TR.pdf)
	--2: http://www.scratchapixel.com/lessons/3d-advanced-lessons/perspective-and-orthographic-projection-matrix/perspective-projection-matrix/
	--3: http://stackoverflow.com/questions/5278417/rotating-body-from-spherical-coordinates
	--4: http://en.wikipedia.org/wiki/Spherical_coordinate_system
end
