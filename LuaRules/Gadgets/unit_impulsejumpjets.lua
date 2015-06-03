function gadget:GetInfo()
	return {
		name    = "Impulse Jumpjets",
		desc    = "Gives units the impulse jump ability",
		author  = "quantum, modified by xponen (impulsejump)",
		date    = "May 14 2008, January 2 2014", --last update 2 June 2015
		license = "GNU GPL, v2 or later",
		layer   = -1, --start before unit_fall_damage.lua (for UnitPreDamage())
		enabled = (Spring.GetModOptions().impulsejump  == "1"),
} end

if (not gadgetHandler:IsSyncedCode()) then return end -- no unsynced code

local tankDesignMode = false --Echo out the amount of impulse used during jump, this is used to design unit more/less resistant to gravity weapon. Tank defaulted to 52 if not configured.
--commrecon1 vs 3 newton = 50
--commrecon2 vs 3 newton = 56
--commrecon3 vs 3 newton = 51
--commrecon4 vs 3 newton = 48
--commrecon5 vs 3 newton = 52

include("LuaRules/Configs/customcmds.h.lua")
-- needed for checks

local Spring    = Spring
local coroutine = coroutine
local Sleep	    = coroutine.yield
local pairs     = pairs
local assert    = assert

local RADperROT = math.pi*2/2^16
-- local random = math.random
local abs    = math.abs
local min = math.min
local max = math.max

local CMD_STOP = CMD.STOP
local CMD_WAIT = CMD.WAIT

local spGetHeadingFromVector = Spring.GetHeadingFromVector
local spGetUnitPosition  = Spring.GetUnitPosition
local spInsertUnitCmdDesc  = Spring.InsertUnitCmdDesc
local spSetUnitRulesParam  = Spring.SetUnitRulesParam
local spGetUnitRulesParam  = Spring.GetUnitRulesParam
local spSetUnitNoMinimap   = Spring.SetUnitNoMinimap
local spGetUnitIsStunned   = Spring.GetUnitIsStunned
local spGetCommandQueue    = Spring.GetCommandQueue
local spGiveOrderToUnit    = Spring.GiveOrderToUnit
local spSetUnitVelocity    = Spring.SetUnitVelocity
local spSetUnitNoSelect    = Spring.SetUnitNoSelect
local spSetUnitBlocking    = Spring.SetUnitBlocking
local spSetUnitMoveGoal    = Spring.SetUnitMoveGoal
local spGetGroundHeight    = Spring.GetGroundHeight
local spTestBuildOrder     = Spring.TestBuildOrder
local spGetGameSeconds     = Spring.GetGameSeconds
local spGetUnitHeading     = Spring.GetUnitHeading
local spSetUnitNoDraw      = Spring.SetUnitNoDraw
local spSetUnitNoDraw      = Spring.SetUnitNoDraw
local spGetGameFrame       = Spring.GetGameFrame
local spGetUnitDefID       = Spring.GetUnitDefID
local spGetUnitTeam        = Spring.GetUnitTeam
local spDestroyUnit        = Spring.DestroyUnit
local spCreateUnit         = Spring.CreateUnit

local spAddUnitImpulse      = Spring.AddUnitImpulse
local spSetUnitRotation  	= Spring.SetUnitRotation 
local spGetUnitVelocity		= Spring.GetUnitVelocity

local SetLeaveTracks = Spring.SetUnitLeaveTracks -- or MoveCtrl.SetLeaveTracks --0.82 compatiblity

local emptyTable = {}

local coroutines = {}
local lastJump = {}
local lastJumpPosition = {}
local landBoxSize = 60
local jumps = {}
local jumping = {}
local goalSet = {}
local impulseQueue = {} --to queue unit impulses outside coroutine. Note: Doing impulses inside coroutine cause Newton to be nonfunctional toward jumping unit (which defeat the purpose of using impulse in first place).
local defFallGravity =Game.gravity/30/30

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local jumpDefs = VFS.Include ("LuaRules/Configs/jump_defs.lua")

local jumpCmdDesc = {
	id			= CMD_JUMP,
	type		= CMDTYPE.ICON_MAP,
	name		= 'Jump',
	cursor	= 'Jump',	-- add with LuaUI?
	action	= 'jump',
	tooltip = 'Impulse Jump to selected position.',
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

local function Sign(number)
	if number >0 then
		return 1
	else 
		return -1
	end
end

local function FindLaunchSpeedAndAcceleration(flightTime, vector, jumpHeight,groundDistance)
	--Given value:
	local wantedTime = flightTime
	local diffHeight = vector[2]
	local apexHeight = jumpHeight
	local dx = vector[1]
	local dz = vector[3]
	local unitID = unitID
	--Input conversion
	apexHeight = math.max(apexHeight, diffHeight) --safety, if apexHeight too small it cause negative sqrt
	diffHeight = math.min(diffHeight, apexHeight) --safety, if diffHeight too big it cause negative sqrt
	local dxdz = math.sqrt(dx*dx + dz*dz) --hypothenus for xz direction
	local unitDirection = math.atan2(dx/dxdz, dz/dxdz)
	--Formula
	local constant3 = (diffHeight/wantedTime)
	local constant1 = (wantedTime/(4*apexHeight))
	local quadraticSolution = (1 + math.sqrt(1*1 - 4*constant1*constant3))/(2*constant1)
	local horizontalVelocity = groundDistance/wantedTime
	--Result
	local verticalLaunchVel = quadraticSolution
	local gravity = verticalLaunchVel*verticalLaunchVel/(2*apexHeight)
	local xVelocity = math.sin(unitDirection)*horizontalVelocity --x is math.sin (not math.cos) because Spring's coordinate is: positive-x toward the right and positive-z toward the bottom
	local zVelocity = math.cos(unitDirection)*horizontalVelocity
	return verticalLaunchVel, gravity, xVelocity, zVelocity
end

--local speedProfile = {0,}
local function Jump(unitID, goal, cmdTag, origCmdParams)
	goal[2]						 = spGetGroundHeight(goal[1],goal[3])
	local start				 = {spGetUnitPosition(unitID)}

	start[2] = math.max(0,start[2]) --always use the case for surface launch (no underwater launch)
	local fakeUnitID
	local unitDefID		 = spGetUnitDefID(unitID)
	local jumpDef			 = jumpDefs[unitDefID]
	local speed				 = jumpDef.speed --2D speed (point-A-to-B, ignoring height)
	local delay				= jumpDef.delay
	local apexHeight		= jumpDef.height
	local impulseTank		= jumpDef.impulseTank or 52 --capacity to launch high, resist Newton and correct drift mid-air
	local cannotJumpMidair		= jumpDef.cannotJumpMidair
	local reloadTime		= (jumpDef.reload or 0)*30
	local teamID				= spGetUnitTeam(unitID)
	
	if tankDesignMode then
		impulseTank = 1000
	end
	--[[
	if cannotJumpMidair and abs(spGetGroundHeight(start[1],start[3]) - start[2]) > 1 then
		return false, true
	end
	--]]
	
	local rotateMidAir	= jumpDef.rotateMidAir
	local env

	local vector = {goal[1] - start[1],
					goal[2] - start[2],
					goal[3] - start[3]}
	
	apexHeight = math.max(apexHeight, vector[2]+apexHeight) --is always higher than the target location

	-- vertex of a parabola. This is for flightDist estimate, not need to be too accurate
	local vertex = {start[1] + vector[1]*0.5,
					start[2] + apexHeight,
					start[3] + vector[3]*0.5}
	
	local lineDist = GetDist3({start[1],0,start[3]}, {goal[1],0,goal[3]})
	local flightDist = GetDist3(start, vertex) + GetDist3(vertex, goal)
	local duration = flightDist/speed
	
	local verticalLaunchVel, gravity, xVelocity, zVelocity = FindLaunchSpeedAndAcceleration(duration, vector,apexHeight,lineDist)

	-- check if there is no wall in between
	local x,z
	for i=10, duration-10 do
		x = start[1] + xVelocity*i
		z = start[3] + zVelocity*i
		if ( (spGetGroundHeight(x,z) - 30) > (start[2] + verticalLaunchVel*i - gravity*i*i/2)) then
			return false, false -- FIXME: should try to use SetMoveGoal instead of jumping!
		end
	end

	-- pick shortest turn direction
	local startHeading = spGetUnitHeading(unitID)
	local goalHeading = spGetHeadingFromVector(vector[1], vector[3])
	local turn
	do
		local fullCirle     = 2^16
		local halfCircle    = 2^15
		local startHeadingB = startHeading + halfCircle
		local goalHeadingB = goalHeading + halfCircle
		if (startHeadingB + halfCircle <= goalHeadingB) then
			startHeadingB = startHeadingB + fullCirle
		elseif (goalHeadingB + halfCircle < startHeadingB)	then
			goalHeadingB	= goalHeadingB	+ fullCirle
		end
		turn = goalHeadingB - startHeadingB
	end
	
	jumping[unitID] = 'prelaunch'
	Spring.SetUnitRulesParam(unitID, "is_jumping", 1)
	SetLeaveTracks(unitID, false)

	env = Spring.UnitScript.GetScriptEnv(unitID)

	if (delay == 0) then
		Spring.UnitScript.CallAsUnit(unitID,env.beginJump,turn,lineDist,flightDist,duration)
		if rotateMidAir then
			spSetUnitRotation(unitID, 0, -1*startHeading*RADperROT, 0) -- keep current heading. Note: need to be negative because of bug? wasn't the case for MoveCtrl.SetUnitRotation()
		end
	else
		Spring.UnitScript.CallAsUnit(unitID,env.preJump,turn,lineDist,flightDist,duration)
	end
	spSetUnitRulesParam(unitID,"jumpReload",0)

	local function JumpLoop()

		--escape water before launching
		local _,initY = spGetUnitPosition(unitID)
		local i = 0 --time spent on surfacing
		while i < duration and initY<-1 do
			if not Spring.ValidUnitID(unitID) or Spring.GetUnitIsDead(unitID) then return end
			
			impulseQueue[#impulseQueue+1] = {unitID, 0, 1,0} --Spring 91 hax; impulse can't be less than 1 or it doesn't work, so we remove 1 and then add 1 impulse.
			impulseQueue[#impulseQueue+1] = {unitID, 0, 0.4-1, 0} 
			_,initY = spGetUnitPosition(unitID)
			i=i+1
			Sleep()
		end

		if delay > 0 then
			delay = delay - i --deduct from time surfacing
			for i=delay, 1, -1 do
				Sleep()
			end
			if not Spring.ValidUnitID(unitID) or Spring.GetUnitIsDead(unitID) then return end

			Spring.UnitScript.CallAsUnit(unitID,env.beginJump)

			if rotateMidAir then
				spSetUnitRotation(unitID, 0,  -1*startHeading*RADperROT, 0) -- keep current heading..
			end
		end
	
		--detach from transport
		local attachedTransport = Spring.GetUnitTransporter(unitID)
		if (attachedTransport) then
			local envTrans = Spring.UnitScript.GetScriptEnv(attachedTransport)
			if (envTrans.ForceDropUnit) then
				Spring.UnitScript.CallAsUnit(attachedTransport,envTrans.ForceDropUnit)
			end
		end
		
		if not Spring.ValidUnitID(unitID) or Spring.GetUnitIsDead(unitID) then return end
		
		--Launch unit upward
		jumping[unitID]='launch'
		impulseTank = impulseTank - abs(xVelocity) - abs(zVelocity)
		local vertThrust = Sign(verticalLaunchVel)*min(impulseTank,abs(verticalLaunchVel))
		local rightThrust = xVelocity 
		local backThrust = zVelocity
		impulseQueue[#impulseQueue+1] = {unitID, 0, 1,0} --Spring 91 hax; impulse can't be less than 1 or it doesn't work, so we remove 1 and then add 1 impulse.
		impulseQueue[#impulseQueue+1] = {unitID, rightThrust, vertThrust-1, backThrust} --add launch impulse
		impulseTank = impulseTank - abs(vertThrust)
		
		--measure initial drift & formulate corection curve
		local initX,initY,initZ = spGetUnitPosition(unitID)
		local driftX,driftY,driftZ= spGetUnitVelocity(unitID)
		local launchVSpd = driftY + verticalLaunchVel
		local realLaunchVSpd = launchVSpd - defFallGravity
		local initRightSpeed = driftX + xVelocity
		local initBackSpeed = driftZ + zVelocity
		local constVertAcc = -(gravity - defFallGravity) - (driftY*2/duration) 
		local needVAcc = -(gravity - defFallGravity) - (driftY*2/duration) 
		local realVAcc = -(gravity) - (driftY*2/duration) 
		local constVertAcc2 = constVertAcc - defFallGravity
		local constRightAcc = -driftX*2/duration --drift correction curve based on equation: zero-drift = vel*time + (deaccelerate*(time^2))/2n
		local constBackAcc = -driftZ*2/duration 
		
		Sleep()
		jumping[unitID]= 'airborne'
		
		local collideTime = 0
		local halfJump
		local i = 1 --jump steps
		local k = 0 --iteration counter
		while i <= duration*2 do
			k = k + 1
			if not Spring.ValidUnitID(unitID) or Spring.GetUnitIsDead(unitID) then return end
			if (not jumping[unitID] ) or ( jumping[unitID]=='landed' ) then
				if (collideTime <= k) then --haven't smash for a while
					Spring.UnitScript.CallAsUnit(unitID,env.endJump) --sumo smash
				end
				break --jump aborted (skip to refreshing reload bar)
			end
			
			if impulseTank > 0 then
				local j = i-1
				local  jj = j*j
				local ii = i*i
				--check vertical drift
				local expectedVertVel = (realLaunchVSpd + realVAcc*j)  -- from equation of motion #1: currentVelocity = initialVelocity + deacceleration*time
				local expectedVertPos = (launchVSpd*i + realVAcc*(ii)/2 + initY) -- from equation of motion #2: currentPosition = initialPosition + initialVelocity*time + deacceleration*time*time/2

				--check right drift
				local expectedRightVel = (initRightSpeed + constRightAcc*j)
				local expectedRightPos = (initRightSpeed*i + constRightAcc*(ii)/2 + initX)
				
				--check back drift
				local expectedBackVel = (initBackSpeed + constBackAcc*j)
				local expectedBackPos = (initBackSpeed*i + constBackAcc*(ii)/2 + initZ)
				
				--sum all correction thrust
				local x,y,z =spGetUnitPosition(unitID)
				local vx,vy,vz= spGetUnitVelocity(unitID)
				vertThrust = needVAcc +  ( expectedVertVel - vy )  + ( expectedVertPos - y)*0.01
				rightThrust = constRightAcc + (expectedRightVel-vx)  + ( expectedRightPos - x)*0.01
				backThrust = constBackAcc + (expectedBackVel-vz)  +  (expectedBackPos - z)*0.01
				
				--timer for thrust limiting & special fx
				if (jumping[unitID]=='collide' and collideTime < k) then
					Spring.UnitScript.CallAsUnit(unitID,env.endJump) --sumo smash
					collideTime = k+4
				end
				jumping[unitID]= 'airborne'
				
				--limit thrust to avoid glitching out during collision
				local maxThrust =  (collideTime>k  and 0.1) or 0.4
				vertThrust = Sign(vertThrust)*min(impulseTank,abs(vertThrust),maxThrust)
				impulseTank = impulseTank - abs(vertThrust)
				if impulseTank >0 then
					rightThrust = Sign(rightThrust)*min(impulseTank,abs(rightThrust),maxThrust)
					impulseTank = impulseTank - abs(rightThrust)
					if impulseTank > 0 then
						backThrust = Sign(backThrust)*min(impulseTank,abs(backThrust),maxThrust)
						impulseTank = impulseTank - abs(backThrust)
					else
						backThrust = 0
					end
				else
					rightThrust = 0
					backThrust = 0
				end
				impulseQueue[#impulseQueue+1] = {unitID, 0, 1,0} --Spring 91 hax; impulse can't be less than 1 or it doesn't work, so we remove 1 and then add 1 impulse.
				impulseQueue[#impulseQueue+1] = {unitID, rightThrust, vertThrust-1, backThrust} --add launch impulse
				
				--Pause sequence for large correction
				local wait
				if  abs(rightThrust) == maxThrust or abs(backThrust) == maxThrust or abs(vertThrust) ==maxThrust then
					wait = true
				end

				impulseTank = max(0,impulseTank)
			end
		
			if rotateMidAir then -- allow unit to maintain posture in the air
				spSetUnitRotation(unitID, 0, (-1*startHeading-turn*i/duration)*RADperROT, 0) -- step by step rotation. Note: need to be negative because of bug? not needed for MoveCtrl.SetUnitRotation() apparently
			else
				spSetUnitRotation(unitID, 0,  -1*startHeading*RADperROT, 0)-- keep current heading .
			end
			Spring.UnitScript.CallAsUnit(unitID,env.jumping, 1, i/duration * 100)
			if (not halfJump and i/duration > 0.5) then
				Spring.UnitScript.CallAsUnit(unitID,env.halfJump)
				halfJump = true
				if tankDesignMode then
					Spring.Echo(1000-impulseTank)
				end
			end
			
			if not wait then
				--[[ Slow damage
				local slowMult = 1-(Spring.GetUnitRulesParam(unitID, "slowState") or 0)
				i = i + (step*slowMult)
				]]
				i = i + 1 --next frame
			end
			Sleep()
		end
		if tankDesignMode then
			Spring.Echo(1000-impulseTank)
		end
		lastJumpPosition[unitID] = origCmdParams
		jumping[unitID] = nil
		SetLeaveTracks(unitID, true)
		Spring.SetUnitRulesParam(unitID, "is_jumping", 0)

		if Spring.ValidUnitID(unitID) and (not Spring.GetUnitIsDead(unitID)) then
			spGiveOrderToUnit(unitID,CMD_WAIT, {}, {})
			spGiveOrderToUnit(unitID,CMD_WAIT, {}, {})
		end

		Sleep()
		
		local morphedTo = Spring.GetUnitRulesParam(unitID, "wasMorphedTo")
		if morphedTo then
			lastJumpPosition[morphedTo] = lastJumpPosition[unitID]
			lastJumpPosition[unitID] = nil
			unitID = morphedTo
		end
		
		local reloadSpeed = 1/reloadTime
		local reloadAmount = reloadSpeed
		
		while reloadAmount < 1 do
			local morphedTo = Spring.GetUnitRulesParam(unitID, "wasMorphedTo")
			if morphedTo then unitID = morphedTo end

			local stunnedOrInbuild = spGetUnitIsStunned(unitID)
			local reloadFactor = (stunnedOrInbuild and 0) or spGetUnitRulesParam(unitID, "totalReloadSpeedChange") or 1
			reloadAmount = reloadAmount + reloadSpeed*reloadFactor
			spSetUnitRulesParam(unitID,"jumpReload",reloadAmount)
			Sleep()
		end
	end

	StartScript(JumpLoop)
	return true, false
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
-- weaponDefID -1 --> debris collision
-- weaponDefID -2 --> ground collision
-- weaponDefID -3 --> object collision
-- weaponDefID -4 --> fire damage
-- weaponDefID -5 --> kill damage
--Detect ground landing:

function gadget:UnitPreDamaged_GetWantedWeaponDef()
	return {-2, -3}
end

function gadget:UnitPreDamaged(unitID, unitDefID, unitTeam, damage, paralyzer, weaponDefID, attackerID, attackerDefID, attackerTeam) --Note:Copied from unit_fall_damage.lua by googlefrog
	-- unit or wreck collision
	if jumping[unitID] and (weaponDefID == -3) and attackerID == nil then
		jumping[unitID] = 'collide' --signal to jump loop to handle collision (to avoid 'physic glitch')
		if GG.SetUnitFallDamageImmunity then
			local immunityPeriod = spGetGameFrame()+30
			--No collision damage except to enemy to simplify gameplay
			GG.SetUnitFallDamageImmunity(unitID, immunityPeriod) --receive no damage from unit collision
			GG.SetNoDamageToAllyCollidee(unitID, immunityPeriod) --deal no damage to ally
			GG.SetUnitFallDamageImmunityFeature(unitID, immunityPeriod) --receive no damage from feature collision
		end
		--return math.random() -- no collision damage to collided victim. Using random return to tell "unit_fall_damage.lua" to not use pairs of damage to infer unit-to-unit collision.
	end
	-- ground collision
	if jumping[unitID] and weaponDefID == -2 and attackerID == nil and Spring.ValidUnitID(unitID) and UnitDefs[unitDefID] then
		spSetUnitVelocity(unitID,0,defFallGravity*3,0) --add some bounce upward to escape glitch
		jumping[unitID] = 'landed' --abort jump. Note: we don't simply wrote NIL because jump isn't completed yet and we don't want a 2nd mid-air jump just because CommandFallback() saw NIL.
		return 0  -- no collision damage.
	end
	return damage
end

function gadget:Initialize()
	Spring.SetCustomCommandDrawData(CMD_JUMP, "Jump", {0, 1, 0, 0.7})
	Spring.AssignMouseCursor("Jump", "cursorJump", true, true)
	gadgetHandler:RegisterCMDID(CMD_JUMP)
	for _, unitID in pairs(Spring.GetAllUnits()) do
		gadget:UnitCreated(unitID, Spring.GetUnitDefID(unitID))
	end
	if tankDesignMode then
		Spring.Echo("Note: jump unit will have large resistance to Newton due to being in tank design mode")
	end
end

function gadget:UnitCreated(unitID, unitDefID, unitTeam)
	if (not jumpDefs[unitDefID]) then
		return
	end 
	Spring.SetUnitRulesParam(unitID, "jumpReload", 1)
	--local t = spGetGameSeconds()
	lastJump[unitID] = -200
	spInsertUnitCmdDesc(unitID, jumpCmdDesc)
end

function gadget:UnitDestroyed(oldUnitID, unitDefID)
	if jumping[oldUnitID] then
		jumping[oldUnitID] = nil --empty old unit's data
	end
end

function gadget:AllowCommand_GetWantedCommand()	
	return true
end

local boolDef = {}
for udid,_ in pairs(jumpDefs) do
	boolDef[udid] = true
end

function gadget:AllowCommand_GetWantedUnitDefID()
	return boolDef
end

function gadget:AllowCommand(unitID, unitDefID, teamID, cmdID, cmdParams, cmdOptions)
	if (jumpDefs[unitDefID].noJumpHandling) then 
		return true
	end
	
	if goalSet[unitID] then
		goalSet[unitID] = nil
	end	
	return true -- allowed
end

function gadget:CommandFallback(unitID, unitDefID, teamID, cmdID, cmdParams, cmdOptions) -- Only calls for custom commands
	if (not jumpDefs[unitDefID]) then --ignore non-jumpable unit
		return false
	end

	if (jumpDefs[unitDefID].noJumpHandling) then
		return true, false
	end
	
	if (cmdID ~= CMD_JUMP) then
		return false
	end

	if not Spring.ValidUnitID(unitID) then
		return true, true
	end

	if (jumping[unitID]) then
		return true, false -- command was used but don't remove it (unit is still jumping)
	end

	if lastJumpPosition[unitID] then
		if abs(lastJumpPosition[unitID][1] - cmdParams[1]) < 1 and 
				abs(lastJumpPosition[unitID][3] - cmdParams[3]) < 1 then
			return true, true -- command was used, remove it (unit finished jump)
		end
		lastJumpPosition[unitID] = nil
	end
	
	local t = spGetGameSeconds()
	local x, y, z = spGetUnitPosition(unitID)
	local distSqr = GetDist2Sqr({x, y, z}, cmdParams)
	local jumpDef = jumpDefs[unitDefID]
	local range   = jumpDef.range
	local reload  = jumpDef.reload or 0

	if (distSqr < (range*range)) then
		local cmdTag = spGetCommandQueue(unitID,1)[1].tag
		if (Spring.GetUnitRulesParam(unitID, "jumpReload") >= 1) and Spring.GetUnitRulesParam(unitID,"disarmed") ~= 1 then
			local didJump, removeCommand = Jump(unitID, cmdParams, cmdTag, cmdParams)
			if not didJump then
				return true, removeCommand -- command was used
			end
			return true, false -- command was used but don't remove it (unit have not finish jump yet)
		end
	else
		if not goalSet[unitID] then
			Approach(unitID, cmdParams, range)
			goalSet[unitID] = true
		end
	end

	return true, false -- command was used but don't remove it (unit is still moving to get into range)
end


function gadget:GameFrame(currFrame)
	UpdateCoroutines()
	for i=#impulseQueue, 1, -1 do --we need to apply impulse outside a coroutine thread like this because we don't want impulses in a coroutine to cancel any newton's impulses that is occuring in main thread. We wanted all them to add up.
		spAddUnitImpulse(impulseQueue[i][1],impulseQueue[i][2],impulseQueue[i][3],impulseQueue[i][4])
		impulseQueue[i]=nil
	end
end
