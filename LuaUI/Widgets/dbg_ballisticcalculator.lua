function widget:GetInfo()
  return {
    name      = "Ballistic Calculator",
    desc      = "Simulate and plot weapon's ballistic range & calculate Spring's weapon range modification. For weapon setting testing. \n\nInstruction: select any unit, press attack (trajectory will be drawn), follow on-screen helptext, BLUE circle is weapon-range-mod, YELLOW circle is ballistic range.",
    author    = "msafwan", --using component from "gui_jumpjets.lua" by quantum,
    date      = "April 5 2014",
    license   = "GNU GPL, v2 or later",
    layer     = 10000,
    enabled   = false,
  }
end

local customMyGravity = 130
local customWeaponVelocity = 232
local flightTime =0
local highTrajectory = 0
local maximumRange = 0
local apexHeight = 0
local currRange = 0

local customHeightMod = 1
local customCylinderTargeting = 1
local customMaxRange = 620
local customHeightBoost = -1
local moddedMaxRange = 620
local weaponName = "Cannon"

local spGetActiveCommand = Spring.GetActiveCommand
local spGetMouseState = Spring.GetMouseState
local spTraceScreenRay = Spring.TraceScreenRay
local spGetModKeyState = Spring.GetModKeyState
local spGetSelectedUnits = Spring.GetSelectedUnits
local spGetCommandQueue = Spring.GetCommandQueue
function widget:DrawWorld()
	local _, activeCommand = spGetActiveCommand()
	if (activeCommand == CMD.ATTACK) then
		local mouseX, mouseY   = spGetMouseState()
		local category, arg    = spTraceScreenRay(mouseX, mouseY)
		local _, _, _, shift   = spGetModKeyState()
		local units = spGetSelectedUnits()
		for i=1,#units do
			DrawMouseArc(units[i], shift, category == 'ground' and arg)
		end
	end
end

local spGetUnitPosition = Spring.GetUnitPosition
local cachedResult = {nil,nil,nil,nil,nil,nil}
local calculateNow= false
local _2DDist = 0
local hide = false
function DrawMouseArc(unitID, shift, groundPos)
	if (not groundPos) then
		return
	end
	local queue = spGetCommandQueue(unitID, 0)
	local deltaV = customWeaponVelocity
	local customRange = customMaxRange
	if (not queue or queue == 0 or not shift) then
		local unitPos = {spGetUnitPosition(unitID)}
		_2DDist = cachedResult[5] or 0
		local maxRange = cachedResult[6] or 0
		if not hide then
			if calculateNow then
				maxRange,_ = CalculateBallisticConstant(deltaV,customMyGravity,nil,unitPos, groundPos)
				_2DDist = GetDist2D(unitPos, groundPos)
				cachedResult[6]= maxRange
				cachedResult[5]= _2DDist
			end
			DrawArc(unitID, unitPos, groundPos, maxRange,_2DDist, deltaV, customMyGravity)
		end
		moddedMaxRange = DrawModdedRange(unitPos, groundPos,deltaV, customMyGravity,customRange)
		maximumRange = maxRange
		calculateNow= false --wait for GameFrame()
	end
end

function GetDist2D(a, b)
  return ((a[1] - b[1])^2 + (a[3] - b[3])^2)^0.5
end

local spGetGroundHeight = Spring.GetGroundHeight
function CalculateBallisticConstant(deltaV,myGravity,heightDiff,start, finish)
	local angle  = math.pi/4 --use test range of 45 degree for optimal launch
	--determine maximum range & time
	local xVel = math.cos(angle)*deltaV --horizontal portion
	local yVel = math.sin(angle)*deltaV --vertical portion
	local t = nil
	local yDist = heightDiff or start[2] - spGetGroundHeight(finish[1],finish[3]) -- set vertical height of 0 (a round trip from 0 height to 0 height)
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
	--
	--Non-changing value so far: maxRange. This depends on: mapGravity and deltaV.
	--
	return maxRange, t --return maximum range and flight time.
end

local glVertex = gl.Vertex
local glColor = gl.Color
local glDrawGroundCircle = gl.DrawGroundCircle
local glBeginEnd = gl.BeginEnd
local glLineStipple = gl.LineStipple
local GL_LINE_STRIP = GL.LINE_STRIP
local yellow   = {  1,   1, 0.5,   1}
local green    = {0.5,   1, 0.5,   1}
local noSolution = false
function DrawArc(unitID, start, finish, range, dist, deltaV, myGravity)
	--TODO: cache the correct trajectory, don't calculate it every DrawWorld frame. Is CPU intensive.
	
	--x, y, z direction to target
	local vector = {}
	for i=1, 3 do
		vector[i] = finish[i] - start[i]
	end
	--draw max range
	local col = yellow
	glColor(col[1], col[2], col[3], col[4])
	glDrawGroundCircle(start[1], start[2], start[3], range, 100)

	--calculate correct trajectory
	local correctAngle= cachedResult[1] or 0
	local yVelocity = cachedResult[2] or 0
	local horizontalSpeed = cachedResult[3] or 0	
	if calculateNow then --let GameFrame() control when to calculate this rather than letting it to DrawWorld()
		local goodValue = {deviation= 999}
		local searchPattern = {startAngle = -1.571, endAngle = 0.707, stepAngle = 0.005}
		if highTrajectory == 1 then 
			searchPattern= {startAngle = 0.707, endAngle = 1.57, stepAngle = 0.005}
		end
		for i= searchPattern.startAngle ,searchPattern.endAngle, searchPattern.stepAngle do
			local angle  = i
			local xVel = math.cos(angle)*deltaV
			local yVel = math.sin(angle)*deltaV
			local yDist = start[2] - spGetGroundHeight(finish[1],finish[3]) 
			local a = myGravity
			local t1 = nil
			local t2 = nil
			-- yDist = yVel*t - a*t*t/2
			-- 0 = -yDist + (yVel)*t - (a/2)*t*t 
			local discriminant =(yVel^2 - 4*(-a/2)*(yDist))^0.5
			local denominator = 2*(-a/2)
			t1 = (-yVel + discriminant)/denominator
			t2 = (-yVel - discriminant)/denominator
			local xDist1 = xVel*t1
			local xDist2 = xVel*t2
			if math.abs(xDist1 - dist) <= goodValue.deviation and t1>=0 then 
				goodValue[2] = angle
				goodValue[3] = xVel
				goodValue[4] = yVel
				goodValue[5]= t1
				goodValue.deviation = math.abs(xDist1 - dist)
				currRange = xDist1
				--Note:
				--Formula to find root is: t = (-b +- (b*b - 4*(a)*(c))^0.5)/(2*a) ..... a & b & c is: 0= c + b*t - a*t*t
				--but when it have only 1 solution (which only happen at the top-most of the arch/trajectory, the discriminant become 0, simplifying the equation to: t = -b /(2*a)
				local flightTimeApex = -yVel/(2*(-a/2)) --time to apex^
				apexHeight = yVel*flightTimeApex - a*flightTimeApex*flightTimeApex/2 --from: yDist = yVel*t - a*t*t/2 
			elseif math.abs(xDist2 - dist) <= goodValue.deviation and t2>=0 then 
				goodValue[2] = angle
				goodValue[3] = xVel
				goodValue[4] = yVel
				goodValue[5]= t2
				goodValue.deviation = math.abs(xDist2 - dist)
				currRange = xDist2
				
				local flightTimeApex = -yVel/(2*(-a/2)) --time to apex^
				apexHeight = yVel*flightTimeApex - a*flightTimeApex*flightTimeApex/2 --from: yDist = yVel*t - a*t*t/2 
			end
		end
		correctAngle = goodValue[2] or 1.57
		horizontalSpeed = goodValue[3]
		yVelocity = goodValue[4]
		flightTime= goodValue[5] or 0
		cachedResult[1] = correctAngle --update cache
		cachedResult[2] = yVelocity
		cachedResult[3] = horizontalSpeed
	end
	if flightTime == 0 then
		-- Spring.Echo("Ballistic plot error: No solution found")
		noSolution = true
		return
	end
	noSolution = false
	
	--draw real time trajectory
	gl.DepthTest (true)
	glLineStipple('')
	glBeginEnd(GL_LINE_STRIP, DrawLoop, start, vector, green, dist, flightTime, yVelocity, horizontalSpeed, myGravity)
	glLineStipple(false)
	gl.DepthTest(false)
	glColor(1, 1, 1, 1)

end

local blue    = {0.5,   1, 1,   1}
function DrawModdedRange(start, finish, deltaV, myGravity, customRange)
	--draw modded max range
	local moddedRange = cachedResult[4] or 0
	if calculateNow then --30 per second
		moddedRange = CalculateModdedMaxRange(start, finish,deltaV,myGravity,customRange)
		cachedResult[4] = moddedRange
	end
	local col = blue
	glColor(col[1], col[2], col[3], col[4])
	glDrawGroundCircle(start[1], start[2], start[3], moddedRange, 100)
	return moddedRange
end

local modType = 0
function CalculateModdedMaxRange(start,finish,deltaV,myGravity,customRange)
	local heightDiff = start[2] - finish[2] 
	local heightModded = (heightDiff)*customHeightMod
	if modType == 0 then --Ballistic
		-- Spring.Echo(scaleDown)
		local maxFlatRange = CalculateBallisticConstant(deltaV,myGravity,0)
		local scaleDown = customRange/maxFlatRange --Example: UpdateRange() in Spring\rts\Sim\Weapons\Cannon.cpp
		local heightBoostFactor = customHeightBoost
		if heightBoostFactor < 0 and scaleDown > 0 then
			heightBoostFactor = (2 - scaleDown) / math.sqrt(scaleDown) --such that: heightBoostFactor == 1 when scaleDown == 1
		end
		heightModded = heightModded*heightBoostFactor
		local moddedRange = CalculateBallisticConstant(deltaV,myGravity,heightModded)
		return moddedRange*scaleDown --Example: GetRange2D() in Spring\rts\Sim\Weapons\Cannon.cpp
	elseif modType == 1 then --Sphere
		return math.sqrt(customRange^2 - heightModded^2) --Pythagoras theorem. Example: GetRange2D() in Spring\rts\Sim\Weapons\Weapon.cpp
	elseif modType == 2 then --Cylinder
		return customRange - heightModded*customHeightMod --Example: GetRange2D() in Spring\rts\Sim\Weapons\StarburstLauncher.cpp
		--Note: for unknown reason we must "Minus the heightMod" instead of adding it. This is the opposite of what shown on the source-code, but ingame test suggest "Minus heightMod" and not adding.
	elseif modType == 3 then --Pure Cylinder
		if customCylinderTargeting * customRange > math.abs(heightModded) then
			return customRange --Example: TestRange() in Spring\rts\Sim\Weapons\Weapon.cpp
		else
			return 0
		end
	end
	return 0 
end

local lineProgress = 0
function DrawLoop(start, vector, color,dist, flightTime, yVelocity, horizontalSpeed, myGravity)
	glColor(color[1], color[2], color[3], color[4])
	local currentProjectilePosition = lineProgress
	--breakdown horizontal speed into x and z component.
	local directionxz_radian = math.atan2(vector[3]/dist, vector[1]/dist)
	local xVelocity = math.cos(directionxz_radian)*horizontalSpeed
	local zVelocity = math.sin(directionxz_radian)*horizontalSpeed
	local simStep = 0.017 --set resolution of the plot
	for i=0, currentProjectilePosition,simStep do

		local x = start[1] + xVelocity*i
		local y = start[2] + (yVelocity)*i - (myGravity/2)*i*i 
		local z = start[3] + zVelocity*i

		glVertex(x, y, z)
	end
	--lineProgress = lineProgress + 1sec, update at GameFrame()
	if lineProgress >= flightTime then
		lineProgress = 0
	end
end

local lastUpdate=0
function widget:GameFrame(n)
	lineProgress = lineProgress + (1/30)
	calculateNow =true
	-- if n- lastUpdate >= 30 then
		-- Spring.Echo("myGravity: ".. string.format("%.3f", customMyGravity).. " ("..string.format("%.3f", customMyGravity/888.888888) .. " Spring91), weaponVelocity: ".. string.format("%.3f", customWeaponVelocity) .. ", flightTime: " .. string.format("%.3f", flightTime) .." ,apexHeight: " .. string.format("%.3f", apexHeight) .. " , currentRange: " .. string.format("%.3f", currRange) .. " ,maximumRange: ".. string.format("%.3f", maximumRange))
		-- lastUpdate = n
	-- end
end

local modTypeBak = 0
function widget:DrawScreen()
	local currCmd =  Spring.GetActiveCommand() --remember current command
	local activeCmd = Spring.GetActiveCmdDesc(currCmd)
	if activeCmd and activeCmd.id == CMD.ATTACK then
		local mx,my = Spring.GetMouseState()
		local k = -25
		gl.Text("##Range Mod##", mx+40, my+k, 10,"")
		k = k - 10
		gl.Text("\"[\"&\"]\": show different MaxRange", mx+40, my+k, 10,"")
		k = k - 10
		gl.Text("\";\"&\"'\": show different HeightMod", mx+40, my+k, 10,"")
		k = k - 10
		gl.Text("\".\"&\"/\": show different CylinderTargeting", mx+40, my+k, 10,"")
		k = k - 10
		gl.Text("\"\\\": show different TargetingMod", mx+40, my+k, 10,"")
		k = k - 10		
		gl.Text("customMaxRange: " .. string.format("%.3f", customMaxRange), mx+40, my+k, 10,"")
		k = k - 10
		gl.Text("customHeightMod: " .. string.format("%.3f", customHeightMod), mx+40, my+k, 10,"")
		k = k - 10
		gl.Text("customCylinderTargeting: " .. string.format("%.3f", customCylinderTargeting) .. (customCylinderTargeting<=0 and " (base on weapontype)" or "(strict cylinder)"), mx+40, my+k, 10,"")
		k = k - 10
		gl.Text("moddedMaxRange: " .. string.format("%.3f", moddedMaxRange), mx+40, my+k, 10,"")
		if modType== modTypeBak then
			k = k - 10
			gl.Text("weaponName: " .. weaponName .. " (default:" ..(modType==0 and "Ballistic)" or (modType==1 and "Sphere)") or "Cylinder)"), mx+40, my+k, 10,"")
		else
			k = k - 10
			gl.Text("targetMod: " .. (modType==0 and " Ballistic" or (modType==1 and " Sphere") or (modType==2 and " Cylinder") or " Strict Cylinder"), mx+40, my+k, 10,"")
		end
		-- if modType==0 then
			-- k = k - 10
			-- gl.Text("customHeightBoost: " .. string.format("%.3f", customHeightBoost), mx+40, my+k, 10,"")
		-- end
		
		gl.Text("\"M\": load value from unit", mx+40, my-5, 10,"")
		gl.Text("2D distance: " ..  string.format("%.3f", _2DDist), mx+40, my+5, 10,"")
		
		if not noSolution and  not hide then
			local y = 25
			--From gui_lasso_terraform.lua
			gl.Text("myGravity: ".. string.format("%.3f", customMyGravity).. " (tag value:"..string.format("%.3f", customMyGravity/888.888888) .. " Spring91)", mx+40, my+y, 10,"")
			y = y + 10
			gl.Text("weaponVelocity: ".. string.format("%.3f", customWeaponVelocity), mx+40, my+y, 10,"")
			y = y + 10
			gl.Text("flightTime: " .. string.format("%.3f", flightTime), mx+40, my+y, 10,"")
			y = y + 10
			gl.Text("apexHeight: " .. string.format("%.3f", apexHeight), mx+40, my+y, 10,"")
			-- y = y + 10
			-- gl.Text("currentRange: " .. string.format("%.3f", currRange), mx+40, my+y, 10,"")
			y = y + 10
			gl.Text("maximumRange: ".. string.format("%.3f", maximumRange) .. " (45degree)", mx+40, my+y, 10,"")
			y = y + 10
			gl.Text("\",\": toggle trajectory ("..(highTrajectory==1 and "high)" or "low)"), mx+40, my+y, 10,"")
			y = y + 10
			gl.Text("\"K\"&\"L\": show different weapon velocity", mx+40, my+y, 10,"")
			y = y + 10
			gl.Text("\"O\"&\"P\": show different weapon gravity", mx+40, my+y, 10,"")
			y = y + 10
			gl.Text("\"N\": hide/show ballistic plot", mx+40, my+y, 10,"")
			y = y + 10
			gl.Text("##Ballistic##", mx+40, my+y, 10,"")
		else
			local y = 25
			gl.Text("##Cannot plot ballistic trajectory##", mx+40, my+y, 10,"")
			y = y + 10
			gl.Text("weaponVelocity: ".. string.format("%.3f", customWeaponVelocity), mx+40, my+y, 10,"")
			y = y + 10
			gl.Text("myGravity: ".. string.format("%.3f", customMyGravity).. " (tag value:"..string.format("%.3f", customMyGravity/888.888888) .. " Spring91)", mx+40, my+y, 10,"")
			y = y + 10
			gl.Text("\"N\": hide/show ballistic plot", mx+40, my+y, 10,"")
		end
	end
end

---using code from central_build_AI.lua by Troy H. Cheek
local incGravity = string.byte( "p" ) --"i" "o", "k" "l", "m"
local decGravity = string.byte( "o" )
local incVelocity = string.byte( "l" )
local decVelocity = string.byte( "k" )
local trajectory =  string.byte( "," )
local loadUnits =  string.byte( "m" )

local incMaxRange = string.byte( "]" ) --"i" "o", "k" "l", "m"
local decMaxRange = string.byte( "[" )
local incHeightMod = string.byte( "'" )
local decHeightMod = string.byte( ";" )
local incCylinder = string.byte( "/" )
local decCylinder = string.byte( "." )
local targetingMod = string.byte( "\\" )

local hideBallisticPlot = string.byte( "n" )

function widget:KeyPress(key, mods, isRepeat)
	if ( key == incGravity ) then 
		customMyGravity = customMyGravity + ((isRepeat and 1) or 0.1)
		return true
	elseif ( key == decGravity ) then
		customMyGravity = customMyGravity - ((isRepeat and 1) or 0.1)
		return true
	elseif ( key == incVelocity ) then
		customWeaponVelocity = customWeaponVelocity + ((isRepeat and 10) or 1)
		return true
	elseif ( key == decVelocity ) then
		customWeaponVelocity = customWeaponVelocity - ((isRepeat and 10) or 1)
		return true
	elseif ( key == trajectory ) then
		highTrajectory = highTrajectory + 1
		highTrajectory = highTrajectory%2
		return true
	elseif ( key == incMaxRange ) then 
		customMaxRange = customMaxRange + ((isRepeat and 10) or 1)
		return true
	elseif ( key == decMaxRange ) then
		customMaxRange = customMaxRange - ((isRepeat and 10) or 1)
		return true
	elseif ( key == incHeightMod ) then 
		customHeightMod = customHeightMod + ((isRepeat and 0.1) or 0.01)
		return true
	elseif ( key == decHeightMod ) then
		customHeightMod = customHeightMod - ((isRepeat and 0.1) or 0.01)
		return true
	elseif ( key == hideBallisticPlot ) then
		hide = not hide
		return true
	elseif ( key == targetingMod ) then
		modType = modType + 1
		modType = modType % 4
		if modType == 3 then
			customCylinderTargeting = 3
		else
			customCylinderTargeting = 0
		end
		return true
	elseif ( key == incCylinder ) then 
		customCylinderTargeting = customCylinderTargeting + ((isRepeat and 0.1) or 0.01)
		if customCylinderTargeting >= 0.01 then
			modType = 3  --pure cylinder (no heightMod)
		else
			modType = modTypeBak
		end
		return true
	elseif ( key == decCylinder ) then
		customCylinderTargeting = customCylinderTargeting - ((isRepeat and 0.1) or 0.01)
		if customCylinderTargeting < 0.01 then
			modType = modTypeBak
		else
			modType = 3  --pure cylinder (no heightMod)
		end
		return true
	elseif (key == loadUnits ) then
		local selectedUnits = Spring.GetSelectedUnits()
		if  selectedUnits and #selectedUnits> 0 then
			local unitDefID = Spring.GetUnitDefID(selectedUnits[1])
			local weaponList = UnitDefs[unitDefID].weapons
			if #weaponList > 0 then
				local weaponDefID = weaponList[1].weaponDef
				local weaponDef = WeaponDefs[weaponDefID]
				customMyGravity = (weaponDef.myGravity > 0 and weaponDef.myGravity*888.888888) or (Game.gravity) or 0
				customWeaponVelocity = weaponDef.projectilespeed*30
				customMaxRange = weaponDef.range
				customHeightMod = weaponDef.heightMod
				customCylinderTargeting  = weaponDef.cylinderTargeting
				customHeightBoost = weaponDef.heightBoostFactor
				GetRangeModType(weaponDef)
				if customCylinderTargeting >= 0.01 then
					--Strict Cylinder
					modType = 3 --pure cylinder (no heightMod)
				end
			end
		end
		return true
	end
end

function GetRangeModType(weaponDef)
	weaponName = weaponDef.type
	if (weaponDef.type == "Cannon") or
	(weaponDef.type == "EmgCannon") or
	(weaponDef.type == "DGun" and weaponDef.gravityAffected) or
	(weaponDef.type == "AircraftBomb")
	then
		--Ballistic
		modType = 0
		modTypeBak = 0
	elseif (weaponDef.type == "LaserCannon" or
	weaponDef.type == "BeamLaser" or
	weaponDef.type == "Melee" or
	weaponDef.type == "Flame" or
	weaponDef.type == "LightningCannon" or
	(weaponDef.type == "DGun" and not weaponDef.gravityAffected))
	then
		--Sphere
		modType = 1
		modTypeBak = 1
	elseif (weaponDef.type == "MissileLauncher" or
	weaponDef.type == "StarburstLauncher" or
	weaponDef.type == "TorpedoLauncher")
	then
		--Cylinder
		modType = 2
		modTypeBak = 2
	end
end