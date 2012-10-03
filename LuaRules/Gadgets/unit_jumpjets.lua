-- $Id: unit_jumpjets.lua 4056 2009-03-11 02:59:18Z quantum $
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function gadget:GetInfo()
  return {
    name      = "Jumpjets",
    desc      = "Gives units the jump ability",
    author    = "quantum",
    date      = "May 14, 2008, Oct 3 2012",
    license   = "GNU GPL, v2 or later",
    layer     = 0,
    enabled   = true  --  loaded by default?
  }
end

---- CHANGELOG -----
-- msafwan,			v???	(3 October 2012)	: 	fixed case where unit do nothing when jump command queued, replaced all Spring.GetUnitBasePosition with Spring.GetUnitPosition.
--													introduce impulse jump:
--													suggested JumpDef for Impulse-Jump: 
--														height ==> a scale from 0 to infinity: jump height
--														limitHeight ==> true or false: if true, use jump height as the maximum height
--														speed ==> a scale from 0 to 10(default) or to infinity: for adding extra speed to jump. Work by adding artificial gravity which necessitate higher jump speed
--														rotateMidAir ==> true or false:  if true, allow unit to maintain posture in the air & not tumble
--														range ==> a scale from 0 to infinity: maximum horizontal range
--														reload ==> a scale from 0 to infinity: reload time in number of GameFrame

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
--local landBoxSize = 100
local jumps       = {} --remember how many unit jumping to same spot
local jumping     = {} --remember if unit is jumping
local goalSet	  = {}
local isImpulseJump = (Spring.GetModOptions().impulsejump  == "1")
local unitCmdQueue = {} --only used in impulse jump. It remember command queue issued while unit is jumping. A workaround for an issue where unit automatically try to return to the place where they started jumping.
local impulseQueue = {} --used by impulse jump to queue unit impulses outside coroutine. Doing impulses inside coroutine cause Newton to be nonfunctional toward jumping unit.

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
	orderArray, start, storeParams = nil, nil, nil
end
------------------------------------------------------
------------------------------------------------------
local function MoveCtrlJump(unitID,height,lineDist,speed,start,vector,cob,rotateMidAir,flightDist,delay,reloadTime,cmdTag, coords)
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
		
		jumps[coords][#jumps[coords]] = nil --tell CommandFallback that this jump coordinate/queue has finish executing, and other unit can use it
		if #jumps[coords] < 1 then
			jumps[coords] = nil --the last unit using the jumps[coords] will clean the list
		end
	
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
	end
  
	StartScript(JumpLoop)
	return true
end

--Jumpjet by using only impulses. Now Newton can interact with jumping unit. Jump is still at constant height just like MoveCtrl version, but with some other non-critical differences.
local function ImpulseJump(unitID, height,lineDist,speed,start,vector,cob,rotateMidAir,flightDist,delay, reloadTime,cmdTag,coords,myJumpQueue,goal,isInfiniteHeight)
	local artificialGrav = 0.144 * (speed/10) --use speed tag to control artificial gravity. Artificial gravity dictate how much harder unit is pushed downward, hence how fast it fly.
	local unitDefID     = spGetUnitDefID(unitID)
	local mapGravity = (Game.gravity/30/30) + artificialGrav --the game actually use (Game.gravity/30/30)-unit-per-frame-per-frame as the acceleration. Is extremely confusing. -- also will add -0.1 impulse every frame to make jump more dramatic
	local yVel =  nil
	--*notUsed* local flightTimeApex = nil --flight time from beginning to Apex (maximum height).
	local xzTarget = math.sqrt(GetDist2Sqr(vector, {0,0,0})) --we want 2D distance, so can't use "lineDist"
	local xzVel = nil --horizontal speed
	local flightTimeFull =nil --full flight time. From beginning to Destination
	
	local isInfiniteHeight = true -- is jump to have infinite height like in the old MoveCtrl version?

	--Derivation:--
	--Formula for vertical motion with gravity is this: yDist = yVel*t - a*t*t/2 (where a is mapGravity, yVel is initial upward velocity, yDist the height it goes, with t as variable.
	--If we want to find t (timeOfFlight) to that height we must use this formula to find root: --Formula to find root: t = (-b +- (b*b - 4*(a)*(c))^0.5)/(2*a) ..... a & b & c is: 0= c + b*t - a*t*t
	--And it is known that when descriminant for formula for finding root is 0 then there exist only 1 root and it represent the apex of the vertical motion: descriminant = b*b - 4*(a)*(c) ... aka "descriminant = yVel^2 - 4*(-mapGravity/2)*(-yDist)". 
	--So we purposely assign the discriminant to 0 and try to solve for yVel (upward velocity) like here: -- yVel^2 = 4*(-mapGravity/2)*(-yDist)
	--Thus: 
	if isInfiniteHeight then
		yVel = (4*(-mapGravity/2)*(-1*(math.max(height, height+vector[2]))))^0.5 -- calculate vertical launch velocity based on jump height only or jump height+ destination height (to allow infinitely high jump).
	else
		yVel = (4*(-mapGravity/2)*(-height))^0.5
	end
	--And when formula for finding root has 0 as discriminant, then the square-root term dissapear and we got this formula instead:  t = (-b +- (0)/(2*a)
	--Thus:
	--*notUsed* flightTimeApex = -yVel/(2*(-mapGravity/2)) 
	--And we want to find out how fast a unit can travel *horizontally* from origin to destination with this amount of flight time. We use: distance = v*t,  (distance is know, t is known *2 times the apex; going up and going down*, only v is not known)
	--Thus:
	--*notUsed*local xzVel_Approx = xzTarget/(flightTimeApex*2) --approximation of distance over time = speed,
	
	--Then we want to find out the actual flight time when the target location is actually above ground level; supposely higher places take less time to reach since unit don't need to fall down as much.
	--Again we use the same equation for vertical motion: -- yDist = yVel*t - a*t*t/2
	--We rearrange the term involved so it fit the 'Finding root formula': -- 0 = -yDist + yVel*t - a/2*t*t
	--Formula to find root: (-b +- (b*b - 4*(a)*(c))^0.5)/(2*a) ..... a b c is: 0= c + b*t - a*t*t
	--Thus, the execution: (we want to find t (timeOfFlight))
	local smallestDiff =9999
	--*notUsed* local t1 = (-yVel + (yVel^2 - 4*(-mapGravity/2)*(-vector[2]))^0.5)/(2*(-mapGravity/2)) ---formula for finding root for quadratic equation. Ref: http://www.sosmath.com/algebra/quadraticeq/quadraformula/summary/summary.html
	local t2 = (-yVel - (yVel^2 - 4*(-mapGravity/2)*(-vector[2]))^0.5)/(2*(-mapGravity/2)) --root no.2
	flightTimeFull = t2
	--[[ --*the following is not used*:
	local xzDist1 = xzVel_Approx*t1 --test range using approximated horizontal speed
	local xzDist2 = xzVel_Approx*t2
	if abs(xzDist1 - xzTarget) <= smallestDiff and t1>=0 then --select result closer to where we wanted to land, we use math.abs because the xDist1 & root-t1 may go back to negative.
		flightTimeFull= t1
		smallestDiff = abs(xzDist1 - xzTarget)
	end
	if abs(xzDist2 - xzTarget) <= smallestDiff and t2>=0 then
		flightTimeFull = t2
	end
	t1 = nil 
	--]]
	t2, smallestDiff = nil, nil
	if flightTimeFull==nil then --target too high to reach!
		jumping[unitID] = false
		return false, true
	end

	--Again by using "distance = v*t" we find the timeOfFlight, but we use the more accurate "t" we obtain above.
	xzVel = xzTarget/flightTimeFull --more accurate distance over time = speed
	
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
  
	-- pick shortest turn direction (same as in MoveCtrlJump but commented for easy understanding)
	local fullCirle     = 2^16
	local halfCircle    = 2^15
	local rotUnit       = fullCirle / (pi2)
	local startHeading  = spGetUnitHeading(unitID) + halfCircle --convert -2^15 & +2^15 half-circle format into +2^16 full-circle format
	local goalHeading   = spGetHeadingFromVector(vector[1],vector[3]) + halfCircle
	if (startHeading + halfCircle <= goalHeading) then --if goalHeading is greater than half-circle away from startHeading then:
		startHeading = startHeading + fullCirle --put startHeading just infront of goalHeading (shift position +2^16)
	elseif (goalHeading + halfCircle < startHeading)  then --if startHeading is greater than half-circle away from goalHeading then:
		goalHeading  = goalHeading  + fullCirle --put goalHeading just infront of startHeading (shift position +2^16)
	end --else: goalHeading & startHeading is less than half-circle away.
	local turn = goalHeading - startHeading
	
	startHeading = startHeading - halfCircle --return to the old half-circle format
	goalHeading = goalHeading - halfCircle --^
	fullCirle, halfCircle = nil, nil
	--
  
	-- check if there is no wall in between
	local x, z = nil, nil
	for t=0, flightTimeFull*0.75, timeStep do
		x = start[1] + xVel*t
		z = start[3] + zVel*t
		if (spGetGroundHeight(x,z) - 30) > start[2]+(yVel*t - mapGravity*t*t/2) then
			jumping[unitID] = false
			return false, true -- should try to use SetMoveGoal instead of deleting command
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
	else
		if cob then
			spCallCOBScript( unitID, "PreJump", 0)
		else
			Spring.UnitScript.CallAsUnit(unitID,env.preJump,turn,lineDist,flightDist)
		end
	end
	spSetUnitRulesParam(unitID,"jumpReload",0)
	
	unitCmdQueue[unitID] = spGetCommandQueue(unitID)
	local unitRadius = Spring.GetUnitRadius(unitID)
	local unitHeight = Spring.GetUnitHeight(unitID)
	Spring.SetUnitRadiusAndHeight (unitID, unitRadius,1)
	
	local function JumpLoop()
		local wasSleeping = false
		
		if delay > 0 then
			for i=delay, 1, -1 do
				Sleep()
			end
			wasSleeping =true
		end
			
		if myJumpQueue>0 then
			for i=0, 300 do
				if myJumpQueue ==jumps[coords][#jumps[coords]] then --if top of the stack is my queue ID, then skip Sleep()
					break
				end
				Sleep() --sleep until its our turn to jump
			end
			wasSleeping =true
		end
			
		if wasSleeping then
			if cob then
				spCallCOBScript( unitID, "BeginJump", 0)
			else
				Spring.UnitScript.CallAsUnit(unitID,env.beginJump)
			end
		end	
		
		GG.FallDamage.ExcludeFriendlyCollision(unitID)
		
		local halfJump, quarterJump, landed, runOnce, clearedQueue= false,false,false, false, false
		local correctedSpeed = 0
		local reloadTimeInv = 1/reloadTime
		local reloadSoFar = 0
		
		for i=0, flightTimeFull, timeStep do 
			if not Spring.ValidUnitID(unitID) then
				if not clearedQueue then
					jumps[coords][#jumps[coords]] = nil --remove current unit's jump stack, tell CommandFallback that this jump queue has finished a jump and other unit can start using it
					clearedQueue = true
				end
				break --unit died or dissappeared
			end
			
			if (not runOnce) then
				lastJump[unitID] = spGetGameSeconds() --start reloading jumpjet from now :)
				spGiveOrderToUnit(unitID, CMD.INSERT, {0, CMD.MOVE, CMD.OPT_INTERNAL, goal[1], goal[2], goal[3]}, {"alt"} ) --add move command to land position for visual purpose
				runOnce=true
			end	

			if (not halfJump and i > flightTimeFull*0.5) then
				if cob then
					spCallCOBScript( unitID, "HalfJump", 0)
				else
					Spring.UnitScript.CallAsUnit(unitID,env.halfJump)
				end
				halfJump = true
			end
			
			if (not quarterJump and i > flightTimeFull*0.25) then
				jumps[coords][#jumps[coords]] = nil --remove current unit's jump stack, tell CommandFallback that this jump queue has finished a jump and other unit can start using it
				quarterJump = true
				clearedQueue = true
			end			
			
			if rotateMidAir then -- allow unit to maintain posture in the air
				local dx,_,dz  =Spring.GetUnitDirection (unitID)
				local dxdz = math.sqrt(dx*dx + dz*dz) --hypothenus for xz direction
				local currentAngle = (math.atan2(dx/dxdz,dz/dxdz))
				local desiredAngle = currentAngle+(turn/rotUnit)*(1/flightTimeFull)
				local desired_dx = math.sin(desiredAngle)*dxdz
				local desired_dz = math.cos(desiredAngle)*dxdz
				spSetUnitDirection(unitID, desired_dx, 0, desired_dz) --set unit direction (dz & dx) and prevent unit from tumbling during jumploop (dy = 0).
			end
			
			if cob then
				spCallCOBScript(unitID, "Jumping", 1, (i/flightTimeFull) * 100) --similar to one in MoveCtrlJump except "i" is replaced with "i/flightTimeFull".
			else
				Spring.UnitScript.CallAsUnit(unitID,env.jumping)
				--unitScriptQueue[unitID] = {script=2, parameters={nil,nil,nil}}
			end
			
			if reloadSoFar< reloadTime then --update reload information during jump loop
				spSetUnitRulesParam(unitID,"jumpReload",reloadSoFar*reloadTimeInv) 
				reloadSoFar = reloadSoFar +1
			end
			
			if i<(flightTimeFull*0.1) then --for the first 10% of the flight: get to launch velocity
				local vx, vy,vz = Spring.GetUnitVelocity(unitID)
				local dvx = xVel - vx --difference between needed velocity and current velocity
				local dvz = zVel - vz
				local dvy = (yVel- mapGravity*i) - vy -- note: is using "v = v0 + a*t"
				impulseQueue[#impulseQueue+1] = {unitID, dvx, dvy, dvz} --add launch impulse
			end
			
			if i>(flightTimeFull*0.1) and correctedSpeed <2 then --try to compensate for total velocity loss during mid air collision .
				local vx, vy,vz = Spring.GetUnitVelocity(unitID)
				if abs(vx)<abs(xVel*0.5) and abs(vz)<abs(zVel*0.5) or abs(vy)< abs(yVel- mapGravity*i)*0.5 then
					local dvx = xVel - vx --difference between needed velocity and current velocity
					local dvz = zVel - vz
					local dvy = (yVel- mapGravity*i) - vy -- note: is using "v = v0 + a*t"
					impulseQueue[#impulseQueue+1] = {unitID, dvx, dvy, dvz} --add velocity correction
					correctedSpeed = correctedSpeed + 1
					--Spring.Echo("CORRECTION")
				end
			end
			
			impulseQueue[#impulseQueue+1] = {unitID, 0, -artificialGrav-1,0} --add artificial gravity for more aggresive looking jump. Useful in low gravity map
			impulseQueue[#impulseQueue+1] = {unitID, 0, 1,0} --hax; impulse can't be less than 1 or it doesn't work, so we remove 1 and then add 1 impulse.
			
			if i>(flightTimeFull*0.25) then
				local x0, y0, z0 = spGetUnitPosition(unitID)
				if (abs(spGetGroundHeight(x0,z0) - y0) <10) then --find out if unit has landed
					local vx, vy,vz = Spring.GetUnitVelocity(unitID)
					local dvx = 0 - vx --difference between 0 velocity and current velocity
					local dvz = 0 - vz
					local dvy = -0.144 - vy
					if abs(dvy) >= 1 then  --wait until unit fall really fast enough to start a brakes or just wait until "flightTimeFull" has passed. Useful for unit jumping up to a ledge where vertical velocity is already zero at the top.
						impulseQueue[#impulseQueue+1] = {unitID, dvx, dvy, dvz} --send braking impulse.
						ReloadQueue(unitID, unitCmdQueue[unitID], cmdTag) --reload the order given during jump. This override the unit's tendency to return to their jumping position
						landed = true
						SetLeaveTracks(unitID, true)
						Spring.SetUnitRadiusAndHeight (unitID, unitRadius,unitHeight)
						if cob then
							spCallCOBScript( unitID, "EndJump", 0)
						else
							Spring.UnitScript.CallAsUnit(unitID,env.endJump)--ie: stop rocket engine animation for jumping com, start landing explosion for sumo,  
						end					
						break
					end
				end
			end
			
			Sleep() --wait until next gameFrame update
		end --ended stuff that is expected to happen during time-Of-Flight. The rest happen if something unpredicted occur, like being thrown of course while jumping.
		
		jumping[unitID] = false		
		if not clearedQueue then
			jumps[coords][#jumps[coords]] = nil 
		end
		if jumps[coords] then --if jumps[coords] not yet empty
			if #jumps[coords] < 1 then
				jumps[coords] = nil --any first unit that see 0 queue in jumps[coords] will clean the list
			end
		end
		
		for i=reloadSoFar, reloadTime do --continue updating reload information after unit land
			spSetUnitRulesParam(unitID,"jumpReload",i*reloadTimeInv)
			
			if not Spring.ValidUnitID(unitID) then
				break --unit died or dissappeared
			end
			
			if (not landed) then
				local x0, y0, z0 = spGetUnitPosition(unitID)
				if (abs(spGetGroundHeight(x0,z0) - y0) <20) then --check whether unit is not yet landed and whether is it approaching the ground
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
					SetLeaveTracks(unitID, true)
					Spring.SetUnitRadiusAndHeight (unitID, unitRadius,unitHeight)
					if cob then
						spCallCOBScript( unitID, "EndJump", 0)
					else
						Spring.UnitScript.CallAsUnit(unitID,env.endJump)--ie: stop rocket engine animation for jumping com, start landing explosion for sumo, create dramatic land animation for pyro
					end				
				end
			end
			
			Sleep() --continue with reload
		end --ended stuff that would happen if unit thrown off course. The gadget will not break the fall after this point.

		--[[ --extended landing check. let unit fall to death?
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
		unitCmdQueue[unitID] = nil
	end --end the monitoring script
  
	StartScript(JumpLoop)
	return true
end
------------------------------------------------------
------------------------------------------------------

local function Jump(unitID, goal, cmdTag, coords, myJumpQueue)
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
		local isInfiniteJump = not (jumpDef.limitHeight or false)
		return ImpulseJump(unitID, height,lineDist,speed,start,vector,cob,rotateMidAir,flightDist,delay,reloadTime,cmdTag, coords,myJumpQueue,goal, isInfiniteJump)
	else
		return MoveCtrlJump(unitID,height,lineDist,speed,start,vector,cob,rotateMidAir,flightDist,delay,reloadTime,cmdTag, coords)
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
      if (not jumps[coords]) then -- #jumps[coords]<1) then
	    local currentQueue = 0
	    jumps[coords] = {} --initialize queue stack
		jumps[coords][1] = currentQueue --add 0 (the first queue id) at the top of stack
		local didJump, elseRemove = Jump(unitID, cmdParams, cmdTag, coords,currentQueue)
		if didJump then
          return true, true -- command was used, remove it 
        end
        return true, elseRemove -- command was used, remove it 
      else
		local currentQueue = jumps[coords][1] + 1 --new queue id is +1 of the previous queue
		local unitDefID= Spring.GetUnitDefID(unitID)
		local boxSize= (UnitDefs[unitDefID].xsize*8)*3 --unit size multiply by 3
        local r = boxSize*currentQueue^0.5/2
        local randpos = {
          cmdParams[1] + (random()*2*r)-r,--p/s: 'random(-r, r)' will select integer between -r and r, 'random(-1,1)*r' will select integer r or -r or 0, 'random()*r' will select real number between 0 and r, '(random()*2*r)-r' will select real number between -r and r.
          cmdParams[2],
          cmdParams[3] + (random()*2*r)-r}
		  
		distSqr = GetDist2Sqr(randpos, cmdParams)
		if (distSqr > rangeSqr) then --if new jump position is further away than maxRange then walk to there first...
			Spring.GiveOrderToUnit(unitID, CMD.INSERT,
				{0,CMD_JUMP,CMD.OPT_SHIFT,randpos[1],randpos[2],randpos[3]},
				{"alt"}
			);
			Approach(unitID, randpos, range) --set goal
			goalSet[unitID] = true --declare set goal
			return true, true --remove jump command (walk to new location to execute a fresh jump)
		end
		table.insert(jumps[coords], 1, currentQueue) --add current queue id at bottom of stack
		local didJump, elseRemove = Jump(unitID, randpos, cmdTag, coords, currentQueue)
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

--local measureMapGravity ={1, fakeUnitID= nil, gravity=nil}
function gadget:GameFrame(n)
	UpdateCoroutines()
	
	--[[
	if measureMapGravity[1] ==1 and n==1 then
		measureMapGravity.fakeUnitID = spCreateUnit("fakeunit_aatarget", 0, 200, 0, "n", 0)
		spSetUnitNoSelect(measureMapGravity.fakeUnitID, true)
		spSetUnitBlocking(measureMapGravity.fakeUnitID, false)
		spSetUnitNoDraw(measureMapGravity.fakeUnitID, true)
		spSetUnitNoMinimap(measureMapGravity.fakeUnitID, true)
		measureMapGravity[1] = 2
	elseif measureMapGravity[1] == 2 then
		local gravity = select(2,Spring.GetUnitVelocity(measureMapGravity.fakeUnitID))
		spDestroyUnit(measureMapGravity.fakeUnitID, false, true)
		measureMapGravity.gravity= abs(gravity)
		Spring.Echo(gravity .. " unit-per-frame-per-frame, gravity")
		measureMapGravity[1] = 3
	end
	--]]
	
	for i=#impulseQueue, 1, -1 do --we need to apply impulse outside a coroutine thread like this because we don't want impulses in a coroutine to cancel any newton's impulses that is occuring in main thread. We wanted all them to add up.
		spAddUnitImpulse(impulseQueue[i][1],impulseQueue[i][2],impulseQueue[i][3],impulseQueue[i][4])
		impulseQueue[i]=nil
	end
end