-- $Id: unit_jumpjets.lua 4056 2009-03-11 02:59:18Z quantum $
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function gadget:GetInfo()
  return {
    name      = "Jumpjets",
    desc      = "Gives units the jump ability",
    author    = "quantum",
    date      = "May 14, 2008, 2012",
    license   = "GNU GPL, v2 or later",
    layer     = 0,
    enabled   = true  --  loaded by default?
  }
end

---- CHANGELOG -----
-- msafwan,			v???	(19sept2012)	: 	introduce impulse jump, fixed landbox randomizer (which didn't work before this), add 1 second delay to
--												unit jumping to same coordinate (to avoid damage from impulse jump),
--												fixed case where unit do nothing when jump command queued, replaced all Spring.GetUnitBasePosition with Spring.GetUnitPosition.
--												JumpDef for Impulse-Jump: 
--														height ==> jump height and a maximum height,  0 to infinity
--														speed ==> a scale from 0-10(default) and 0 to infinity (for adding extra speed to jump. Work by adding artificial gravity which necessitate higher jump speed)
--														rotateMidAir ==> *not implemented*
--														range ==> maximum horizontal range, 0 to infinity
--														reload ==> reload time

if (not gadgetHandler:IsSyncedCode()) then
  return false -- no unsynced code
end

Spring.SetGameRulesParam("jumpJets",1)

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
--  Proposed Command ID Ranges:
--
--    all negative:  Engine (build commands)
--       0 -   999:  Engine
--    1000 -  9999:  Group AI
--   10000 - 19999:  LuaUI
--   20000 - 29999:  LuaCob
--   30000 - 39999:  LuaRules
--

include("LuaRules/Configs/customcmds.h.lua")
-- needed for checks

local Spring      = Spring
local MoveCtrl    = Spring.MoveCtrl
local coroutine   = coroutine
local Sleep       = coroutine.yield
local pairs       = pairs
local assert      = assert

local pi2    = math.pi*2
local random = math.random
local abs    = math.abs

local CMD_STOP = CMD.STOP

local spGetHeadingFromVector = Spring.GetHeadingFromVector
local spGetUnitPosition      = Spring.GetUnitPosition
local spInsertUnitCmdDesc  = Spring.InsertUnitCmdDesc
local spSetUnitRulesParam  = Spring.SetUnitRulesParam
local spSetUnitNoMinimap   = Spring.SetUnitNoMinimap
local spGetCommandQueue    = Spring.GetCommandQueue
local spGiveOrderToUnit    = Spring.GiveOrderToUnit
local spSetUnitVelocity	   = Spring.SetUnitVelocity
local spSetUnitNoSelect    = Spring.SetUnitNoSelect
local spSetUnitBlocking    = Spring.SetUnitBlocking
local spSetUnitMoveGoal    = Spring.SetUnitMoveGoal
local spGetGroundHeight    = Spring.GetGroundHeight
local spTestBuildOrder     = Spring.TestBuildOrder
local spGetGameSeconds     = Spring.GetGameSeconds
local spGetUnitHeading     = Spring.GetUnitHeading
local spSetUnitNoDraw      = Spring.SetUnitNoDraw
local spCallCOBScript      = Spring.CallCOBScript
local spSetUnitNoDraw      = Spring.SetUnitNoDraw
local spGetUnitDefID       = Spring.GetUnitDefID
local spGetUnitTeam        = Spring.GetUnitTeam
local spDestroyUnit        = Spring.DestroyUnit
local spCreateUnit         = Spring.CreateUnit

local mcSetRotationVelocity = MoveCtrl.SetRotationVelocity
local mcSetPosition         = MoveCtrl.SetPosition
local mcSetRotation         = MoveCtrl.SetRotation
local mcDisable             = MoveCtrl.Disable
local mcEnable              = MoveCtrl.Enable
local spAddUnitImpulse      = Spring.AddUnitImpulse
local spSetUnitDirection    = Spring.SetUnitDirection

local SetLeaveTracks      = Spring.SetUnitLeaveTracks -- or MoveCtrl.SetLeaveTracks	--0.82 compatiblity

local emptyTable = {}

local coroutines  = {}
local lastJump    = {}
local landBoxSize = 100
local jumps       = {} --remember how many unit jumping to same spot
local jumping     = {} --remember if unit is jumping
local goalSet	  = {}
local isImpulseJump = (Spring.GetModOptions().impulsejump  == "1")
local unitCmdQueue = {} --only used in impulse jump. It remember command queue issued while unit is jumping (a workaround for an issue).

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local jumpDefNames  = VFS.Include"LuaRules/Configs/jump_defs.lua"

local jumpDefs = {}
for name, data in pairs(jumpDefNames) do
  jumpDefs[UnitDefNames[name].id] = data
end


local jumpCmdDesc = {
  id      = CMD_JUMP,
  type    = CMDTYPE.ICON_MAP,
  name    = 'Jump',
  cursor  = 'Jump',  -- add with LuaUI?
  action  = 'jump',
  tooltip = 'Jump to selected position.',
}


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local function GetDist3(a, b)
  local x, y, z = (a[1] - b[1]), (a[2] - b[2]), (a[3] - b[3])
  return (x*x + y*y + z*z)^0.5
end


local function GetDist2Sqr(a, b)
  local x, z = (a[1] - b[1]), (a[3] - b[3])
  return (x*x + z*z)
end


local function Approach(unitID, cmdParams, range)
	spSetUnitMoveGoal(unitID, cmdParams[1],cmdParams[2],cmdParams[3], range)
end


local function StartScript(fn)
  local co = coroutine.create(fn)
  coroutines[#coroutines + 1] = co
end


local function ReloadQueue(unitID, queue, cmdTag)
	if (not queue) then
		return
	end

    local re = Spring.GetUnitStates(unitID)["repeat"]
	local storeParams
	--// remove finished command
	local start = 1
	if (queue[1])and(cmdTag == queue[1].tag) then
		start = 2 
		if re then
			storeParams = queue[1].params
		end
	end

	local orderArray = {}
	--spGiveOrderToUnit(unitID, CMD_STOP, emptyTable, emptyTable)
	orderArray[1]= {CMD_STOP, emptyTable, emptyTable}
	for i=start,#queue do
		local cmd = queue[i]
		local cmdOpt = cmd.options
		local opts = {"shift"} -- appending
		if (cmdOpt.alt)   then opts[#opts+1] = "alt"   end
		if (cmdOpt.ctrl)  then opts[#opts+1] = "ctrl"  end
		if (cmdOpt.right) then opts[#opts+1] = "right" end
		--spGiveOrderToUnit(unitID, cmd.id, cmd.params, opts)
		orderArray[#orderArray+1] = {cmd.id, cmd.params, opts}
	end
  
	if re and start == 2 then
		--spGiveOrderToUnit(unitID, CMD_JUMP, {storeParams[1],Spring.GetGroundHeight(storeParams[1],storeParams[3]),storeParams[3]}, {"shift"} )
		orderArray[#orderArray+1] = {CMD_JUMP, {storeParams[1],Spring.GetGroundHeight(storeParams[1],storeParams[3]),storeParams[3]}, {"shift"}}
	end
	Spring.GiveOrderArrayToUnitArray({unitID}, orderArray)
end
------------------------------------------------------
------------------------------------------------------
local function MoveCtrlJump(unitID,height,cob,delay,rotateMidAir,speed,lineDist,flightDist,reloadTime,start,vector,cmdTag, coords)
	-- pick shortest turn direction
	local rotUnit       = 2^16 / (pi2)
	local startHeading  = spGetUnitHeading(unitID) + 2^15
	local goalHeading   = spGetHeadingFromVector(vector[1], vector[3]) + 2^15
	if (goalHeading  >= startHeading + 2^15) then
		startHeading = startHeading + 2^16
	elseif (goalHeading  < startHeading - 2^15)  then
		goalHeading  = goalHeading  + 2^16
	end
	local turn = goalHeading - startHeading
	--
	
	local speed         = speed * lineDist/flightDist
	local step          = speed/lineDist
  
	-- check if there is no wall in between
	local x,z = start[1],start[3]
	for i=0, 1, step do
		x = x + vector[1]*step
		z = z + vector[3]*step
		if ( (spGetGroundHeight(x,z) - 30) > (start[2] + vector[2]*i + (1-(2*i-1)^2)*height)) then
			jumping[unitID] = false
			return false, true -- FIXME: should try to use SetMoveGoal instead of jumping!
		end
	end
	--
	
	local fakeUnitID
	mcEnable(unitID)
	Spring.SetUnitVelocity(unitID,0,0,0)
	SetLeaveTracks(unitID, false)

	if not cob then
		env = Spring.UnitScript.GetScriptEnv(unitID)
	end
  
	if (delay == 0) then
		if cob then
			spCallCOBScript( unitID, "BeginJump", 0)
		else
			Spring.UnitScript.CallAsUnit(unitID,env.beginJump)
		end
		if rotateMidAir then
			mcSetRotation(unitID, 0, (startHeading - 2^15)/rotUnit, 0) -- keep current heading
			mcSetRotationVelocity(unitID, 0, turn/rotUnit*step, 0)
		end
	else
		if cob then
			spCallCOBScript( unitID, "PreJump", 0)
		else
			Spring.UnitScript.CallAsUnit(unitID,env.preJump,turn,lineDist,flightDist)
		end
	end
	spSetUnitRulesParam(unitID,"jumpReload",0)

	local function JumpLoop()
  
		if delay > 0 then
			for i=delay, 1, -1 do
				Sleep()
			end
	  
			if cob then
				spCallCOBScript( unitID, "BeginJump", 0)
			else
				Spring.UnitScript.CallAsUnit(unitID,env.beginJump)
			end

			if rotateMidAir then
				mcSetRotation(unitID, 0, (startHeading - 2^15)/rotUnit, 0) -- keep current heading
				mcSetRotationVelocity(unitID, 0, turn/rotUnit*step, 0)
			end
	  
			--fakeUnitID = spCreateUnit(
			--"fakeunit_aatarget", start[1], start[2], start[3], "n", teamID)
			--mcEnable(fakeUnitID)
			--spSetUnitNoSelect(fakeUnitID, true)
			--spSetUnitBlocking(fakeUnitID, false)
			--spSetUnitNoDraw(fakeUnitID, true)
			--spSetUnitNoMinimap(fakeUnitID, true)
		end
  
		local halfJump
		for i=0, 1, step do
			if ((not spGetUnitTeam(unitID)) and fakeUnitID) then
				spDestroyUnit(fakeUnitID, false, true)
				return -- unit died
			end
			local x0, y0, z0 = spGetUnitPosition(unitID)
			local x = start[1] + vector[1]*i
			local y = start[2] + vector[2]*i + (1-(2*i-1)^2)*height -- parabola
			local z = start[3] + vector[3]*i
			mcSetPosition(unitID, x, y, z)
			if x0 then
				spSetUnitVelocity(unitID, x - x0, y - y0, z - z0) -- for the benefit of unit AI and possibly target prediction (probably not the latter)
			end
	  
			if cob then
				spCallCOBScript(unitID, "Jumping", 1, i * 100)
			else
				Spring.UnitScript.CallAsUnit(unitID,env.jumping)
			end
	  
			if (fakeUnitID) then mcSetPosition(fakeUnitID, x, y, z) end
			if (not halfJump and i > 0.5) then
				if cob then
					spCallCOBScript( unitID, "HalfJump", 0)
				else
					Spring.UnitScript.CallAsUnit(unitID,env.halfJump)
				end
				halfJump = true
			end
			Sleep()
		end

		if (fakeUnitID) then spDestroyUnit(fakeUnitID, false, true) end
		if cob then
			spCallCOBScript( unitID, "EndJump", 0)
		else
			Spring.UnitScript.CallAsUnit(unitID,env.endJump)
		end
		lastJump[unitID] = spGetGameSeconds()
		jumping[unitID] = false
		SetLeaveTracks(unitID, true)
		mcDisable(unitID)
	
		--mcSetPosition(unitID, start[1] + vector[1],start[2] + vector[2]-6,start[3] + vector[3])
		local oldQueue = spGetCommandQueue(unitID)
	
		ReloadQueue(unitID, oldQueue, cmdTag)
	
		local reloadTimeInv = 1/reloadTime
		for i=1, reloadTime do
			spSetUnitRulesParam(unitID,"jumpReload",i*reloadTimeInv)
			Sleep()
			if i == 1 then
				if Spring.ValidUnitID(unitID) and (not Spring.GetUnitIsDead(unitID)) then
					Spring.SetUnitVelocity(unitID, 0, 0, 0) -- prevent the impulse capacitor
				end
			end
		end
		
		jumps[coords] = jumps[coords] - 1 --tell CommandFallback that this jump coordinate has finish executing, and other unit can use it
	end
  
	StartScript(JumpLoop)
	return true
end

--Jumpjet by using only impulses. Now Newton can interact with jumping unit. Jump is still at constant height just like MoveCtrl version, but with some other non-critical differences.
local function ImpulseJump(unitID, height,lineDist,speed,start,vector,cob,rotateMidAir,flightDist,delay,reloadTime,cmdTag,goal, coords)
	local artificialGrav = 0.144 * (speed/10) --use speed tag to control artificial gravity. Artificial gravity dictate how much harder unit is pushed downward, hence how fast it fly.
	local unitDefID     = spGetUnitDefID(unitID)
	local mapGravity = (Game.gravity/30/30) + artificialGrav --the game actually use (Game.gravity/30/30)-unit-per-frame-per-frame as the acceleration. Is extremely confusing. -- also will add -0.1 impulse every frame to make jump more dramatic
	local yVel =  nil
	local flightTimeApex = nil --half flight time. From beginning to Apex.
	local xzTarget = lineDist
	local xzVel = nil --horizontal speed
	local flightTimeFull =nil --full flight time. From beginning to Destination

	--Derivation:--
	--Formula for vertical motion with gravity is this: yDist = yVel*t - a*t*t/2 (where a is mapGravity, yVel is initial upward velocity, yDist the height it goes, with t as variable.
	--If we want to find t (timeOfFlight) to that height we must use this formula to find root: --Formula to find root: t = (-b +- (b*b - 4*(a)*(c))^0.5)/(2*a) ..... a & b & c is: 0= c + b*t - a*t*t
	--And it is known that when descriminant for formula for finding root is 0 then there exist only 1 root and it represent the apex of the vertical motion: descriminant = b*b - 4*(a)*(c) ... aka "descriminant = yVel^2 - 4*(-mapGravity/2)*(-yDist)". 
	--So we purposely assign the discriminant to 0 and try to solve for yVel (upward velocity) like here: -- yVel^2 = 4*(-mapGravity/2)*(-yDist)
	--Thus: 
	yVel = (4*(-mapGravity/2)*(-height))^0.5
	--And when formula for finding root has 0 as discriminant, then the square-root term dissapear and we got this formula instead:  t = (-b +- (0)/(2*a)
	--Thus:
	flightTimeApex = -yVel/(2*(-mapGravity/2)) 
	--And we want to find out how fast a unit can travel *horizontally* from origin to destination with this amount of flight time. We use: distance = v*t,  (distance is know, t is known *2 times the apex; going up and going down*, only v is not known)
	--Thus:
	local xzVel_Approx = xzTarget/(flightTimeApex*2) --approximation of distance over time = speed,
	
	--Then we want to find out the actual flight time when the target location is actually above ground level; supposely higher places take less time to reach since unit don't need to fall down as much.
	--Again we use the same equation for vertical motion: -- yDist = yVel*t - a*t*t/2
	--We rearrange the term involved so it fit the 'Finding root formula': -- 0 = -yDist + yVel*t - a/2*t*t
	--Formula to find root: (-b +- (b*b - 4*(a)*(c))^0.5)/(2*a) ..... a b c is: 0= c + b*t - a*t*t
	--Thus, the execution: (we want to find t (timeOfFlight))
	local smallestDiff =9999
	local t1 = (-yVel + (yVel^2 - 4*(-mapGravity/2)*(-vector[2]))^0.5)/(2*(-mapGravity/2)) ---formula for finding root for quadratic equation. Ref: http://www.sosmath.com/algebra/quadraticeq/quadraformula/summary/summary.html
	local t2 = (-yVel - (yVel^2 - 4*(-mapGravity/2)*(-vector[2]))^0.5)/(2*(-mapGravity/2))
	local xzDist1 = xzVel_Approx*t1
	local xzDist2 = xzVel_Approx*t2
	if abs(xzDist1 - xzTarget) <= smallestDiff and t1>=0 then --we use math.abs because the xDist1 & root-t1 may go back to negative!
		flightTimeFull= t1
		smallestDiff = abs(xzDist1 - xzTarget)
	end
	if abs(xzDist2 - xzTarget) <= smallestDiff and t2>=0 then
		flightTimeFull = t2
	end
	t1, t2, smallestDiff = nil, nil, nil
	if flightTimeFull==nil then --target too high to reach!
		jumping[unitID] = false
		return false, true
	end
	--Again by using "distance = v*t" we find the timeOfFlight, but we use the more accurate "t" we obtain above.
	xzVel = xzTarget/flightTimeFull --more accurate distance over time = speed
	--Spring.Echo(yVel .. " yVel " .. flightTimeFull .. " flightTimeFull of " .. flightTimeApex .. " flightTimeApex" )
	
	--Then we want to breakdown the obtained horizontal speed (xzVel) into x and z component which is useful for impulse callin.
	--We use math callin math.atan2 to convert a vector of x and z into radian (an angle). There is a table inside the system that convert ratio between x or z and its 'hypothenus' (the composite xz value) into angle. Tri-gonometry framework is explained here: http://www.mathsisfun.com/sine-cosine-tangent.html
	--So we use this callin as defined here: http://lua-users.org/wiki/MathLibraryTutorial
	--Thus:
	local directionxz_radian = math.atan2(vector[3]/xzTarget, vector[1]/xzTarget)
	--Then we use the radian to break our xzVel into x& z component. We use the same trigonometry framework
	--ie: "xVel / xzVel = cos(radian)" .... (where "cos(radian)" is supplied by LUA, and xzVel is known, so we can find the xVel by rearranging the terms)
	--and: "zVel / xzVel = cos(radian)" .... (so we can find the zVel by rearranging the terms)
	--Thus (after rearranging term):
	local xVel = math.cos(directionxz_radian)*xzVel
	local zVel = math.sin(directionxz_radian)*xzVel
	
	--=end physic calculation=-------------------------------------------------------------------
	local timeStep = 1 --set how much time the sim supposely progresses everytime GameFrame updates. We set to 1 because apparently 1-unit-of-time is defined as 1-gameFrame and the calculation is not based on second
  
	-- pick shortest turn direction
	local rotUnit       = 2^16 / (pi2)
	local startHeading  = spGetUnitHeading(unitID) + 2^15
	local goalHeading   = spGetHeadingFromVector(vector[3], vector[1]) + 2^15
	if (goalHeading  >= startHeading + 2^15) then
		startHeading = startHeading + 2^16
	elseif (goalHeading  < startHeading - 2^15)  then
		goalHeading  = goalHeading  + 2^16
	end
	local turn = goalHeading - startHeading
	--
  
	-- check if there is no wall in between
	local x, z = nil, nil
	for t=0, flightTimeFull*0.75, timeStep do
		x = start[1] + xVel*t
		z = start[3] + zVel*t
		if (spGetGroundHeight(x,z) - 30) > start[2]+(yVel*t - mapGravity*t*t/2) then
			jumping[unitID] = false
			return false, true -- should try to use SetMoveGoal instead of jumping!
		end
	end
	x, z = nil, nil
	
	SetLeaveTracks(unitID, false)
	
	if not cob then
		env = Spring.UnitScript.GetScriptEnv(unitID)
	end
	if (delay == 0) then
		if cob then
			spCallCOBScript( unitID, "BeginJump", 0)
		else
			Spring.UnitScript.CallAsUnit(unitID,env.beginJump)
		end
		if rotateMidAir then
			--Spring.SetUnitRotation (unitID, 0, (startHeading - 2^15)/rotUnit, 0)-- keep current heading
		end
	else
		if cob then
			spCallCOBScript( unitID, "PreJump", 0)
		else
			Spring.UnitScript.CallAsUnit(unitID,env.preJump,turn,lineDist,flightDist)
		end
	end
	spSetUnitRulesParam(unitID,"jumpReload",0)
	
	unitCmdQueue[unitID] = spGetCommandQueue(unitID)
	
	local function JumpLoop()
  
		if delay > 0 then
			for i=delay, 1, -1 do
				Sleep()
			end
			
			if cob then
				spCallCOBScript( unitID, "BeginJump", 0)
			else
				Spring.UnitScript.CallAsUnit(unitID,env.beginJump)
			end

			if rotateMidAir then
				--Spring.SetUnitRotation (unitID, 0, (startHeading - 2^15)/rotUnit, 0)-- keep current heading
			end
		end	
		
		GG.FallDamage.ExcludeFriendlyCollision(unitID)
		
		local halfJump
		local landed = false
		local reloadTimeInv = 1/reloadTime
		local reloadSoFar = 0
		local runOnce =true
		for i=0, flightTimeFull, timeStep do 
			--Spring.Echo(i .. " jumpLoop of " .. flightTimeFull)
			if not Spring.ValidUnitID(unitID) then
				break --unit died or dissappeared
			end
			
			if runOnce==true then
				lastJump[unitID] = spGetGameSeconds() --start countdown jump from now :)
				spGiveOrderToUnit(unitID, CMD.INSERT, {0, CMD.MOVE, CMD.OPT_INTERNAL, goal[1], goal[2], goal[3]}, {"alt"} ) --add move command to land position for visual purpose
				runOnce=false
			end			
			
			local dx,dy,dz  =Spring.GetUnitDirection (unitID)
			spSetUnitDirection(unitID, dx, 0, dz) --prevent unit from tumbling during jumploop.
			--Spring.Echo(dy .. " dy")
			
			if rotateMidAir then -- x_x :(
				--Spring.SetUnitRotation (unitID, 0, (startHeading - 2^15)/rotUnit, 0)-- keep current heading
				--Spring.SetUnitRotation (unitID, 0, (startHeading - 2^15)/rotUnit, 0)-- keep current heading
				--Spring.Echo((startHeading - 2^15)/rotUnit .. " (startHeading - 2^15)/rotUnit")
				--Spring.SetUnitRotation (unitID, 0, (turn/rotUnit)*(i/flightTimeFull), 0)-- rotate slowly to current heading after every jumploop
				-- Spring.SetUnitRotation (unitID, 0, goalHeading/rotUnit, 0)-- rotate slowly to current heading after every jumploop
				-- Spring.Echo(startHeading/rotUnit +(turn/rotUnit)*(i/flightTimeFull) .. " angle")
				--Spring.Echo((turn/rotUnit)*(i/flightTimeFull) .. " (turn/rotUnit)*(i/flightTimeFull)")
			end
			
			if i<(flightTimeFull*0.1) then --for the first 10% of the flight try to actively maintain the velocity
				local vx, vy,vz = Spring.GetUnitVelocity(unitID)
				local dvx = xVel - vx --difference between needed velocity and current velocity
				local dvz = zVel - vz
				local dvy = (yVel-mapGravity*i) - vy -- note: is using "v = v0 + a*t"
				spAddUnitImpulse(unitID, dvx, dvy, dvz) --add launch impulse
				-- Spring.Echo(dvx .. " dvx")
				-- Spring.Echo(dvy .. " dvy")
				-- Spring.Echo(dvz .. " dvz")	
			end
			
			spAddUnitImpulse(unitID, 0, -1-artificialGrav,0) --add artificial gravity for more aggresive looking jump. Useful in low gravity map
			spAddUnitImpulse(unitID, 0, 1, 0) --hax; impulse can't be less than 1 or it doesn't work at all. So we add 1 and then remove 1.
			
			if cob then
				spCallCOBScript(unitID, "Jumping", 1, (i/flightTimeFull) * 100) --similar to one in MoveCtrlJump except "i" is replaced with "i/flightTimeFull".
			else
				Spring.UnitScript.CallAsUnit(unitID,env.jumping)
			end
			
			if reloadSoFar< reloadTime then --update reload information during jump loop
				spSetUnitRulesParam(unitID,"jumpReload",reloadSoFar*reloadTimeInv) 
				reloadSoFar = reloadSoFar +1
			end
			
			if (not halfJump and i > flightTimeFull*0.5) then
				if cob then
					spCallCOBScript( unitID, "HalfJump", 0)
				else
					Spring.UnitScript.CallAsUnit(unitID,env.halfJump)
				end
				halfJump = true
			end
			
			local x0, y0, z0 = spGetUnitPosition(unitID)
			if ((abs(spGetGroundHeight(x0,z0) - y0) <10) and i>(flightTimeFull*0.5)) then --find out if unit has landed
				local vx, vy,vz = Spring.GetUnitVelocity(unitID)
				local dvx = 0 - vx --difference between 0 velocity and current velocity
				local dvz = 0 - vz
				local dvy = -0.144 - vy
				if dvy >= 1 then  --wait until unit fall really fast enough to start a brakes or just wait until "flightTimeFull" has passed. Useful for unit jumping up to a ledge where vertical velocity is already zero at the top.
					spAddUnitImpulse(unitID, dvx, dvy, dvz) --send braking impulse.
					
					ReloadQueue(unitID, unitCmdQueue[unitID], cmdTag) --reload the order given during jump. This override the unit's tendency to return to their jumping position
					landed = true
					if cob then
						spCallCOBScript( unitID, "EndJump", 0)
					else
						Spring.UnitScript.CallAsUnit(unitID,env.endJump)--ie: stop rocket engine animation for jumping com, start landing explosion for sumo,  
					end					
					break
				end
			end
			
			Sleep() --wait until next gameFrame update
		end --ended stuff that is expected to happen during time-Of-Flight. The rest happen if something unpredicted occur, like being thrown of course while jumping.
		
		--lastJump[unitID] = spGetGameSeconds()
		jumping[unitID] = false
		SetLeaveTracks(unitID, true)
		
		--local reloadTimeInv = 1/reloadTime
		for i=reloadSoFar, reloadTime do --continue updating reload information after unit land
			spSetUnitRulesParam(unitID,"jumpReload",i*reloadTimeInv)
			
			if not Spring.ValidUnitID(unitID) then
				break --unit died or dissappeared
			end
			
			local x0, y0, z0 = spGetUnitPosition(unitID)
			if not landed and (abs(spGetGroundHeight(x0,z0) - y0) <20) then --check whether unit is not yet landed and whether is it approaching the ground
				local dx,dy,dz  =Spring.GetUnitDirection (unitID)
				local dxdz = math.sqrt(dx*dx + dz*dz) --hypothenus for xz direction
				local dxdzdy = math.sqrt(dxdz*dxdz + dy*dy) --hypothenus for xzy direction
				local angle = (math.atan2(dy/dxdzdy,dxdz/dxdzdy))*180/math.pi --convert ratio to radian then convert to degree
				if (abs(angle)<40) then  --check whether it land on its feet 40 degree leaning forward or backward (+-180 degree is upside down)
					local vx, vy,vz = Spring.GetUnitVelocity(unitID)
					local dvx = 0 - vx --difference between 0 velocity and current velocity
					local dvz = 0  - vz
					local dvy = -0.144 - vy
					dvx = math.min (abs(xVel) ,abs(dvx)) * (abs(dvx)/dvx) -- limit x impulse to as much as the launch's impulse (math.min), and multiply by its sign (abs(x)/x). So that unit is not entirely invulnerable to falling damage and has somekind of limit. 
					dvy = math.min (abs(yVel) ,abs(dvy)) * (abs(dvy)/dvy)
					dvz = math.min (abs(zVel) ,abs(dvy)) * (abs(dvz)/dvz)
					spAddUnitImpulse(unitID, dvx, dvy, dvz) --send braking impulse.
				end
				
				ReloadQueue(unitID, unitCmdQueue[unitID], cmdTag) --refresh unit's order
				landed = true
				if cob then
					spCallCOBScript( unitID, "EndJump", 0)
				else
					Spring.UnitScript.CallAsUnit(unitID,env.endJump)--ie: stop rocket engine animation for jumping com, start landing explosion for sumo, create dramatic land animation for pyro
				end				
			end
			
			Sleep()
		end --ended stuff that would happen if unit thrown off course. The gadget will not break the fall after this point.

		--[[ --let unit fall to death?
		for i=0, 900, 1 do --wait for 30 more second for unit to land
			if not Spring.ValidUnitID(unitID) then
				break --unit died or dissappeared
			end
			
			if landed or jumping[unitID] then
				break --unit are doing another jump midair or has landed
			end
			
			local x0, y0, z0 = spGetUnitPosition(unitID)
			local _,dy,_  =Spring.GetUnitDirection (unitID)
			if not landed and (abs(spGetGroundHeight(x0,z0) - y0) <30) and (abs(dy)<0.125) then --check whether unit has landed & whether it is landing on its feet, 
				local vx, vy,vz = Spring.GetUnitVelocity(unitID)
				local dvx = 0 - vx --difference between 0 velocity and current velocity
				local dvz = 0 - vz
				local dvy = -0.144 - vy
				dvx = math.min (abs(xVel/2) ,abs(dvx)) * (abs(dvx)/dvx) -- limit x impulse to HALF as much as the launch impulse (math.min), and multiply by its sign (abs(x)/x). So that unit is not entirely invulnerable to falling damage and has somekind of limit. 
				dvy = math.min (abs(yVel/2) ,abs(dvy)) * (abs(dvy)/dvy)
				dvz = math.min (abs(zVel/2) ,abs(dvy)) * (abs(dvz)/dvz)
				spAddUnitImpulse(unitID, dvx, dvy, dvz) --send braking impulse.
				ReloadQueue(unitID, unitCmdQueue[unitID], cmdTag) --give order during jump
				landed = true --mark unit as landed
			end
			
			Sleep()
		end
		--]]
		
		GG.FallDamage.IncludeFriendlyCollision(unitID)  
		
		jumps[coords] = jumps[coords] - 1 --tell CommandFallback that this jump coordinate has finish executing, and other unit can use it
		unitCmdQueue[unitID] = nil
	end --end the monitoring script
  
	StartScript(JumpLoop)
	return true
end
------------------------------------------------------
------------------------------------------------------

local function Jump(unitID, goal, cmdTag, coords, duplicateCoordCount)
	goal[2]             = spGetGroundHeight(goal[1],goal[3])
	local start         = {spGetUnitPosition(unitID)}

	local unitDefID     = spGetUnitDefID(unitID)
	local jumpDef       = jumpDefs[unitDefID]
	local speed         = jumpDef.speed
	local delay    	  = jumpDef.delay --the wait animation before jumping
	local height        = jumpDef.height --the desired height
	local cannotJumpMidair    = jumpDef.cannotJumpMidair
	local reloadTime    = (jumpDef.reload or 0)*30
	local teamID        = spGetUnitTeam(unitID)
  
	if cannotJumpMidair and abs(spGetGroundHeight(start[1],start[3]) - start[2]) > 1 then
		return false, false
	end
  
	local rotateMidAir  = jumpDef.rotateMidAir
	local cob 	 	  = jumpDef.cobscript
	local env

	local vector = {goal[1] - start[1],
					goal[2] - start[2],
					goal[3] - start[3]}
  
	-- vertex of the parabola
	local vertex = {start[1] + vector[1]*0.5,
					start[2] + vector[2]*0.5 + (1-(2*0.5-1)^2)*height,
					start[3] + vector[3]*0.5}
  
	local lineDist      = GetDist3(start, goal)
	if lineDist == 0 then lineDist = 0.00001 end
	local flightDist    = GetDist3(start, vertex) + GetDist3(vertex, goal)
  
	jumping[unitID] = true

	
	if isImpulseJump then
		local extraWait = duplicateCoordCount*27 --extra waiting before jumping to avoid mid air collision
		delay = delay + extraWait
		return ImpulseJump(unitID, height,lineDist,speed,start,vector,cob,rotateMidAir,flightDist,delay,reloadTime,cmdTag,goal, coords)
	else
		return MoveCtrlJump(unitID,height,cob,delay,rotateMidAir,speed,lineDist,flightDist,reloadTime,start,vector,cmdTag, coords)
	end
end


-- a bit convoluted for this but might be           
-- useful for lua unit scripts
local function UpdateCoroutines() 
  local newCoroutines = {} 
  for i=1, #coroutines do 
    local co = coroutines[i] 
    if (coroutine.status(co) ~= "dead") then 
      newCoroutines[#newCoroutines + 1] = co 
    end 
  end 
  coroutines = newCoroutines 
  for i=1, #coroutines do 
    assert(coroutine.resume(coroutines[i]))
  end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function gadget:Initialize()
  Spring.SetCustomCommandDrawData(CMD_JUMP, "Jump", {0, 1, 0, 1})
  Spring.AssignMouseCursor("Jump", "cursorJump", true, true)
  gadgetHandler:RegisterCMDID(CMD_JUMP)
  for _, unitID in pairs(Spring.GetAllUnits()) do
    gadget:UnitCreated(unitID, Spring.GetUnitDefID(unitID))
  end
end


function gadget:UnitCreated(unitID, unitDefID, unitTeam)
  if (not jumpDefs[unitDefID]) then
    return
  end 
  --local t = spGetGameSeconds()
  lastJump[unitID] = -200
  spInsertUnitCmdDesc(unitID, jumpCmdDesc)
end


function gadget:UnitDestroyed(unitID, unitDefID)
  lastJump[unitID]  = nil
end


function gadget:AllowCommand(unitID, unitDefID, teamID, cmdID, cmdParams, cmdOptions)
	
	if jumping[unitID] then 
		unitCmdQueue[unitID] = spGetCommandQueue(unitID) --remembers unit's queue --is used as  workaround for impulse jump issues.
		
		-- do no allow morphing while jumping
		if (GG.MorphInfo and cmdID >= CMD_MORPH and cmdID < CMD_MORPH+GG.MorphInfo["MAX_MORPH"]) then
			-- allow to queue
			if cmdOptions.shift then
				return true
			else
				return false --do not allow
			end
		end
	end
	
	if (cmdID == CMD_JUMP) then
		goalSet[unitID] = false --redo the MoveGoal each time player issued a new jump command. As precaution.
	
		if (spTestBuildOrder(unitDefID, cmdParams[1], cmdParams[2], cmdParams[3], 1) == 0) then
			return false --do not allow
		end
	end
	
	return true -- allowed
end


function gadget:CommandFallback(unitID, unitDefID, teamID,    -- keeps getting 
                                cmdID, cmdParams, cmdOptions) -- called until
  if (not jumpDefs[unitDefID]) then
	return false
  end
  
  if (cmdID ~= CMD_JUMP) then      -- you remove the
	goalSet[unitID] = false
	return false  -- command was not used                     -- order
  end
  
  if not Spring.ValidUnitID(unitID) then
    return true, true
  end

  if (jumping[unitID]) then
    return true, false -- command was used but don't remove it
  end

  local x, y, z = spGetUnitPosition(unitID)
  local distSqr = GetDist2Sqr({x, y, z}, cmdParams)
  local jumpDef = jumpDefs[unitDefID]
  local range   = jumpDef.range
    local rangeSqr= range*range
  local reload  = jumpDef.reload or 0
  local t       = spGetGameSeconds()

  if (distSqr < rangeSqr) then
    goalSet[unitID] = false
    local cmdTag = spGetCommandQueue(unitID,1)[1].tag
    if (lastJump[unitID] and (t - lastJump[unitID]) >= reload) then
      local coords = table.concat(cmdParams)
      if (not jumps[coords] or jumps[coords]<1) then
        local didJump, elseRemove = Jump(unitID, cmdParams, cmdTag, coords, 0)
        jumps[coords] = 1
		if didJump then
          return true, true -- command was used, remove it 
        end
        return true, elseRemove -- command was used, remove it 
      else
        local r = landBoxSize*jumps[coords]^0.5/2
		local randomAngle = random()*pi2 --select real number between 0 and pi2
        local randpos = {
          cmdParams[1] + math.cos(randomAngle)*r, --p/s: 'random(-r, r)' will select integer between -r and r, 'random(-1,1)*r' will select integer r or -r or 0, 'random()*r' will select real number between 0 and r
          cmdParams[2],
          cmdParams[3] + math.sin(randomAngle)*r}
		  
		distSqr = GetDist2Sqr(randpos, cmdParams)
		if (distSqr > rangeSqr) then --if new random position is further away than maxRange then walk there...
			Spring.GiveOrderToUnit(unitID,
				CMD.INSERT,
				{0,CMD_JUMP,CMD.OPT_SHIFT,randpos[1],randpos[2],randpos[3]},
				{"alt"}
			);
			Approach(unitID, randpos, range)
			goalSet[unitID] = true
			return true, true --remove command
		end
		
		local didJump, elseRemove = Jump(unitID, randpos, cmdTag, coords, jumps[coords])
		jumps[coords] = jumps[coords] + 1
        if didJump then
          return true, true -- command was used, remove it 
        end
        return true, elseRemove -- command was used, remove it 
      end
    end
  else
	if not goalSet[unitID] then
      Approach(unitID, cmdParams, range)
	  goalSet[unitID] = true
	end
  end
  
  return true, false -- command was used but don't remove it
end

function gadget:GameFrame(n)
  UpdateCoroutines()
end
