-- $Id: unit_jumpjets.lua 4056 2009-03-11 02:59:18Z quantum $
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
local isImpulseJump = (Spring.GetModOptions().impulsejump  == "1") --ImpulseJump
function gadget:GetInfo()
	return {
		name    = "Impulse Jumpjets",
		desc    = "Gives units the impulse jump ability",
		author  = "quantum, modified by msafwan (impulsejump)",
		date    = "May 14 2008, December 16 2013",
		license = "GNU GPL, v2 or later",
		layer   = -1, --start before unit_fall_damage.lua (for UnitPreDamage())
    enabled = isImpulseJump,
	}
end

if (not gadgetHandler:IsSyncedCode()) then
	return false -- no unsynced code
end

Spring.SetGameRulesParam("jumpJets",1)

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
--	Proposed Command ID Ranges:
--
--	all negative:	Engine (build commands)
--	     0 - 999:	Engine
--	  1000 - 9999:	Group AI
--	 10000 - 19999:	LuaUI
--	 20000 - 29999:	LuaCob
--	 30000 - 39999:	LuaRules
--

include("LuaRules/Configs/customcmds.h.lua")
-- needed for checks

local Spring    = Spring
local coroutine = coroutine
local Sleep	    = coroutine.yield
local pairs     = pairs
local assert    = assert

local RADperROT = math.pi*2/2^16
local random = math.random
local abs    = math.abs

local CMD_STOP = CMD.STOP
local CMD_WAIT = CMD.WAIT

local spGetHeadingFromVector = Spring.GetHeadingFromVector
local spGetUnitPosition  = Spring.GetUnitPosition
local spInsertUnitCmdDesc  = Spring.InsertUnitCmdDesc
local spSetUnitRulesParam  = Spring.SetUnitRulesParam
local spGetUnitRulesParam  = Spring.GetUnitRulesParam
local spSetUnitNoMinimap   = Spring.SetUnitNoMinimap
local spGetCommandQueue    = Spring.GetCommandQueue
local spGiveOrderToUnit    = Spring.GiveOrderToUnit
local spSetUnitVelocity    = Spring.SetUnitVelocity
local spSetUnitNoSelect    = Spring.SetUnitNoSelect
local spSetUnitBlocking    = Spring.SetUnitBlocking
local spSetUnitMoveGoal    = Spring.SetUnitMoveGoal
local spGetGroundHeight    = Spring.GetGroundHeight
local spTestBuildOrder     = Spring.TestBuildOrder
local spGetGameSeconds     = Spring.GetGameSeconds
local spGetGameFrame       = Spring.GetGameFrame
local spGetUnitHeading     = Spring.GetUnitHeading
local spSetUnitNoDraw      = Spring.SetUnitNoDraw
local spCallCOBScript      = Spring.CallCOBScript
local spSetUnitNoDraw      = Spring.SetUnitNoDraw
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
local landBoxSize = 60
local jumps = {}
local jumping = {}
local goalSet = {}
local impulseQueue = {} --used by impulse jump to queue unit impulses outside coroutine. Note: Doing impulses inside coroutine cause Newton to be nonfunctional toward jumping unit.
local unitCmdQueue = {} --only used in impulse jump. It remember command queue issued while unit is jumping. A workaround for an issue where unit automatically try to return to the place where they started jumping.
local defFallGravity =Game.gravity/30/30

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local jumpDefNames = VFS.Include"LuaRules/Configs/jump_defs.lua"

local jumpDefs = {}
for name, data in pairs(jumpDefNames) do
	jumpDefs[UnitDefNames[name].id] = data
end


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

local function CopyJumpData (unitID, endHeight)
	local oldUnitID = unitID --previous unitID
	unitID = GG.wasMorphedTo[unitID] --new unitID
	local unitDefID = spGetUnitDefID(unitID)
	if (not jumpDefs[unitDefID]) then --check if new unit can jump
		jumping[unitID] = nil
		lastJump[unitID] = nil
		return --exit JumpLoop() if unit can't jump
	end
	local reloadTime = (jumpDefs[unitDefID].reload or 0)*30 --jump reload time
	local cob = jumpDefs[unitDefID].cobscript --script type
	spSetUnitRulesParam(unitID,"jumpReload",0)
	SetLeaveTracks(unitID, false)	
	local env
	if not cob then
		env = Spring.UnitScript.GetScriptEnv(unitID) --get new unit's script
	end
	local speed = jumpDefs[unitDefID].speed --speed from point A to B to C
	local rotateMidAir = jumpDefs[unitDefID].rotateMidAir --unit rotate to face new direction?
	local delay = jumpDefs[unitDefID].delay --prejump delay
	local height = jumpDefs[unitDefID].height --max height
	local limitHeight = jumpDefs[unitDefID].limitHeight --limit height to height?
	if not limitHeight then
		height = math.max(height, endHeight+height) --is always higher than the present or the target location
	end
	
	return unitID,reloadTime,env,cob,speed,rotateMidAir,delay,height,limitHeight
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

	spGiveOrderToUnit(unitID, CMD_STOP, emptyTable, emptyTable)
	for i=start,#queue do
		local cmd = queue[i]
		local cmdOpt = cmd.options
		local opts = {"shift"} -- appending
		if (cmdOpt.alt)	 then opts[#opts+1] = "alt"	 end
		if (cmdOpt.ctrl)	then opts[#opts+1] = "ctrl"	end
		if (cmdOpt.right) then opts[#opts+1] = "right" end
		spGiveOrderToUnit(unitID, cmd.id, cmd.params, opts)
	end
	
	if re and start == 2 then
		spGiveOrderToUnit(unitID, CMD_JUMP, {storeParams[1],Spring.GetGroundHeight(storeParams[1],storeParams[3]),storeParams[3]}, {"shift"} )
	end
	
end

local function FindLaunchSpeedAndAcceleration(flightTime, vectorY, jumpHeight,groundDistance, vectorX, vectorZ)
	--Given value:
	local wantedTime = flightTime
	local diffHeight = vectorY
	local apexHeight = jumpHeight
	local dx = vectorX
	local dz = vectorZ
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
local function Jump(unitID, goal, cmdTag)
	goal[2]						 = spGetGroundHeight(goal[1],goal[3])
	local start				 = {spGetUnitPosition(unitID)}
	start[2] = math.max(0,start[2]) --always use the case for surface launch (no underwater launch)

	local fakeUnitID
	local unitDefID		 = spGetUnitDefID(unitID)
	local jumpDef			 = jumpDefs[unitDefID]
	local speed				 = jumpDef.speed
	local height				= jumpDef.height
	local limitHeight		= jumpDef.limitHeight
	local cannotJumpMidair		= jumpDef.cannotJumpMidair
	local reloadTime		= (jumpDef.reload or 0)*30
	local teamID				= spGetUnitTeam(unitID)
	
	if cannotJumpMidair and abs(spGetGroundHeight(start[1],start[3]) - start[2]) > 1 then
		return false, true
	end
	
	local vector = {goal[1] - start[1],
					goal[2] - start[2],
					goal[3] - start[3]}
					
	if not limitHeight then
		height = math.max(height, vector[2]+height) --is always higher than the present or the target location
	end

	-- vertex of a parabola. This is for flightDist estimate, not need to be too accurate
	local vertex = {start[1] + vector[1]*0.5,
					start[2] + height,
					start[3] + vector[3]*0.5}
					
	local lineDist = GetDist3({start[1],0,start[3]}, {goal[1],0,goal[3]})
	local flightDist = GetDist3(start, vertex) + GetDist3(vertex, goal)
	local duration = flightDist/speed
	
	local verticalLaunchVel, gravity, xVelocity, zVelocity = FindLaunchSpeedAndAcceleration(duration, vector[2],height,lineDist,vector[1],vector[3])

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
	
	local cob			= jumpDef.cobscript
	local delay			= jumpDef.delay
	local env
	local rotateMidAir	= jumpDef.rotateMidAir
	
	if not cob then
		env = Spring.UnitScript.GetScriptEnv(unitID)
	end
	if (delay == 0) then
		if cob then
				spCallCOBScript( unitID, "BeginJump", 0)
			else
				Spring.UnitScript.CallAsUnit(unitID,env.beginJump,turn,lineDist,flightDist,duration)
			end
		if rotateMidAir then
			spSetUnitRotation(unitID, 0, -1*startHeading*RADperROT, 0) -- keep current heading. Note: need to be negative because of bug? not needed for MoveCtrl.SetUnitRotation() apparently
		end
	else
		if cob then
			spCallCOBScript( unitID, "PreJump", 0)
		else
			Spring.UnitScript.CallAsUnit(unitID,env.preJump,turn,lineDist,flightDist,duration)
		end
	end
	
	jumping[unitID] = true
	spSetUnitRulesParam(unitID,"jumpReload",0)

	local function JumpLoop()
		if delay > 0 then
			local countUp = 1
			while (countUp <= delay ) do
				--NOTE: UnitDestroyed() must run first to update jumping & lastJump table for morphed unit.
				if GG.wasMorphedTo[unitID] then
					unitID,reloadTime,env,cob,speed,rotateMidAir,delay,height,limitHeight = CopyJumpData(unitID, vector[2])
					if unitID == nil then 
						return
					end					
					vertex[2] = (start[2] + height)
					flightDist = GetDist3(start, vertex) + GetDist3(vertex, goal)
					local newDuration = flightDist/speed
					if newDuration ~= duration then
						verticalLaunchVel, gravity, xVelocity, zVelocity = FindLaunchSpeedAndAcceleration(duration, vector[2],height,lineDist,vector[1],vector[3])
						duration = newDuration
					end
				end
				Sleep()
				countUp = countUp +1
			end
		
			if cob then
				spCallCOBScript( unitID, "BeginJump", 0)
			else
				Spring.UnitScript.CallAsUnit(unitID,env.beginJump)
			end

			if rotateMidAir then
				spSetUnitRotation(unitID, 0,  -1*startHeading*RADperROT, 0) -- keep current heading.. Note: need to be negative because of bug? not needed for MoveCtrl.SetUnitRotation() apparently
			end
		end
		
		SetLeaveTracks(unitID, false)
		
		local halfJump
		local jumped
		local i = 0
		while i <= duration*1.5 do
			--NOTE: Its really important for UnitDestroyed() to run before GameFrame(). UnitDestroyed() must run first to update jumping & lastJump table for morphed unit.
			if GG.wasMorphedTo[unitID] then
				unitID,reloadTime,env,cob,speed = CopyJumpData(unitID, vector[2])
				if unitID == nil then 
					return
				end
				halfJump = nil --reset halfjump flag. Redo halfjump script for new unit
			end
			if not Spring.ValidUnitID(unitID) or Spring.GetUnitIsDead(unitID) then
				return --unit died
			end
			if (not jumping[unitID] ) or ( jumping[unitID]=="landed" ) then
				break --jump aborted (skip to refreshing reload bar)
			end
			
			local x,y,z =spGetUnitPosition(unitID)
			do
				if not jumped and y>=0 then --not underwater
					local grndh =spGetGroundHeight(x,z)
					if y<=grndh+1 or y<=1 then
						spSetUnitVelocity(unitID,0,0,0)  --thus its speed don't interfere with jumping (prevent range increase while running). Note; ground unit in flying mode wont be effected
					end
					
					impulseQueue[#impulseQueue+1] = {unitID, 0, 1,0} --Spring 91 hax; impulse can't be less than 1 or it doesn't work, so we remove 1 and then add 1 impulse.
					impulseQueue[#impulseQueue+1] = {unitID, xVelocity, verticalLaunchVel-1, zVelocity} --add launch impulse
					-- unitCmdQueue[unitID] = spGetCommandQueue(unitID)
					jumped = true
				end
				local desiredVerticalSpeed = verticalLaunchVel - gravity*(i+1) --maintain original parabola trajectory at all cost. This prevent space-skuttle effect with Newton.
				local currFallSpeed = verticalLaunchVel - defFallGravity*(i) 
				local vx,vy,vz= spGetUnitVelocity(unitID)
				local collide = type(jumping[unitID])== 'number'
				jumping[unitID] = true
				local jumpDiffer =desiredVerticalSpeed - vy --calculate correction
				local nominalDiffer = currFallSpeed - vy
				if collide and halfJump and nominalDiffer < 0 then --collide while going down
					--spSetUnitVelocity(unitID,0,0,0) --stop unit
					impulseQueue[#impulseQueue+1] = {unitID, 0, 4,0}
					impulseQueue[#impulseQueue+1] = {unitID, -vx*0.9, -vy*0.9-4, -vz*0.9} --slowdown to stop
					break --jump aborted (skip to refreshing reload bar)
				end
				local sign = math.abs(jumpDiffer)/jumpDiffer
				jumpDiffer = sign*math.min(math.abs(jumpDiffer),verticalLaunchVel) --cap maximum correction to launch impulse (safety against 'physic glitch': violent tug of war between 2 gigantic impulses that cause 1 side to win and send unit into space)
				impulseQueue[#impulseQueue+1] = {unitID, 0, 4,0} --Impulse capacitor hax; in Spring 91 impulse can't be less than 1, in Spring 93.2.1 impulse can't be less than 4 in y-axis (at least for flying unit)
				impulseQueue[#impulseQueue+1] = {unitID, 0, jumpDiffer-4, 0} --add correction impulse
				----Spring.Echo("----"); speedProfile[#speedProfile+1]=vy; Spring.Echo(jumpDiffer)
			end
		
			if rotateMidAir then -- allow unit to maintain posture in the air
				spSetUnitRotation(unitID, 0, (-1*startHeading-turn*i/duration)*RADperROT, 0) -- step by step rotation. Note: need to be negative because of bug? not needed for MoveCtrl.SetUnitRotation() apparently
			else
				spSetUnitRotation(unitID, 0,  -1*startHeading*RADperROT, 0)-- keep current heading .
			end
			
			if cob then
				spCallCOBScript(unitID, "Jumping", 1, i/duration * 100)
			else
				Spring.UnitScript.CallAsUnit(unitID,env.jumping)
			end
			if (not halfJump and i/duration > 0.5) then
				if cob then
					spCallCOBScript( unitID, "HalfJump", 0)
				else
					Spring.UnitScript.CallAsUnit(unitID,env.halfJump)
				end
				halfJump = true
			end
			Sleep()
			if jumped then
				i = i + 1 --next frame
			end
		end
		
		if cob then
			spCallCOBScript( unitID, "EndJump", 0)
		else
			Spring.UnitScript.CallAsUnit(unitID,env.endJump)
		end
		local jumpEndTime = spGetGameSeconds()
		lastJump[unitID] = jumpEndTime
		jumping[unitID] = false
		SetLeaveTracks(unitID, true)
	
		-- ReloadQueue(unitID, unitCmdQueue[unitID], cmdTag) --reload the order given during jump. This override the unit's tendency to return to their jumping position
		-- unitCmdQueue[unitID] = nil
	
		spSetUnitRulesParam(unitID,"jumpReloadStart",jumpEndTime)
		for j=1, reloadTime do
			if GG.wasMorphedTo[unitID] then
				unitID,reloadTime = CopyJumpData (unitID, vector[2])
				lastJump[unitID] = jumpEndTime
				jumping[unitID] = false
				SetLeaveTracks(unitID, true)
				if unitID == nil then 
					return
				end			
			end
			spSetUnitRulesParam(unitID,"jumpReload",j/reloadTime)
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
function gadget:UnitPreDamaged(unitID, unitDefID, unitTeam, damage, paralyzer, weaponDefID, attackerID, attackerDefID, attackerTeam) --Note:Copied from unit_fall_damage.lua by googlefrog
	-- unit or wreck collision
	if jumping[unitID] and (weaponDefID == -3) and attackerID == nil then
		jumping[unitID] = 1 --signal to jump loop that a collision is occurring (is used to terminate trajectory maintenance when colliding real hard (to escape 'physic glitch'))
		if GG.SetUnitFallDamageImmunity then
			GG.SetUnitFallDamageImmunity(unitID, spGetGameFrame()+30) --this unit immune to unit-to-unit collision damage
		end
		if GG.SetUnitFallDamageImmunityFeature then
			GG.SetUnitFallDamageImmunityFeature(unitID, spGetGameFrame()+30) --this unit immune to unit-to-unit collision damage
		end
		--return math.random() -- no collision damage to collided victim. Using random return to tell "unit_fall_damage.lua" to not use pairs of damage to infer unit-to-unit collision.
	end
	-- ground collision
	if jumping[unitID] and weaponDefID == -2 and attackerID == nil and Spring.ValidUnitID(unitID) and UnitDefs[unitDefID] then
		spSetUnitVelocity(unitID,0,Game.gravity*3/30/30,0) --add some bounce upward to escape 'physic glitch'
		jumping[unitID] = "landed" --abort jump. Note: we do not assign NIL because jump is not yet completed and we do not want a 2nd mid-air jump just because CommandFallback() sees NIL.
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
	
	GG.wasMorphedTo = GG.wasMorphedTo or {}
end

function gadget:UnitCreated(unitID, unitDefID, unitTeam)
	if (not jumpDefs[unitDefID]) then
		return
	end 
	--local t = spGetGameSeconds()
	lastJump[unitID] = -200
	spInsertUnitCmdDesc(unitID, jumpCmdDesc)
end

function gadget:UnitDestroyed(oldUnitID, unitDefID)
	--NOTE: its really important to map old table to new id ASAP to prevent CommandFallback() from executing jump twice for morphed unit. 
	--UnitDestroyed() is called before CommandFallback() when unit is morphed (unit_morph.lua must destroy unit before issuing command) 
	if jumping[oldUnitID] and GG.wasMorphedTo[oldUnitID] then
		local newUnitID = GG.wasMorphedTo[oldUnitID]
		jumping[newUnitID] = jumping[oldUnitID] --copy last jump state to new unit
		lastJump[newUnitID] = lastJump[oldUnitID] --copy last jump timestamp to new unit
		unitCmdQueue[newUnitID] = unitCmdQueue[oldUnitID]
	end
	if lastJump[oldUnitID] then
		lastJump[oldUnitID] = nil
		jumping[oldUnitID] = nil --empty old unit's data
		unitCmdQueue[oldUnitID] = nil
	end
end

function gadget:AllowCommand_GetWantedCommand()	
	return true
end

function gadget:AllowCommand_GetWantedUnitDefID()	
	boolDef = {}
	for udid,_ in pairs(jumpDefs) do
		boolDef[udid] = true
	end
	return boolDef
end

function gadget:AllowCommand(unitID, unitDefID, teamID, cmdID, cmdParams, cmdOptions)
	if unitCmdQueue[unitID] then
		unitCmdQueue[unitID] = spGetCommandQueue(unitID) --save the order given during jump. Which will be reloaded later upon landing.
	end
	-- if (cmdID == CMD_JUMP and 
		-- spTestBuildOrder(
			-- unitDefID, cmdParams[1], cmdParams[2], cmdParams[3], 1) == 0) then
		-- return false --block jumping into blocked position
	-- end
	if goalSet[unitID] then
		goalSet[unitID] = nil
	end	
	-- do no allow morphing while jumping
	if (jumping[unitID] and GG.MorphInfo and cmdID >= CMD_MORPH and cmdID < CMD_MORPH+GG.MorphInfo["MAX_MORPH"]) then
		-- allow to queue
		if cmdOptions.shift then
			return true
		else
			return false
		end
	end
	return true -- allowed
end

function gadget:CommandFallback(unitID, unitDefID, teamID, cmdID, cmdParams, cmdOptions) -- Only calls for custom commands
	if (not jumpDefs[unitDefID]) then --ignore non-jumpable unit
		return false
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

	local t = spGetGameSeconds()

	if lastJump[unitID] and lastJump[unitID]+1 >= t then
		return true, true -- command was used, remove it (unit finished jump)
	end
	
	local x, y, z = spGetUnitPosition(unitID)
	local distSqr = GetDist2Sqr({x, y, z}, cmdParams)
	local jumpDef = jumpDefs[unitDefID]
	local range   = jumpDef.range
	local reload  = jumpDef.reload or 0
	
	if (distSqr < (range*range)) then
		local cmdTag = spGetCommandQueue(unitID,1)[1].tag
		if (lastJump[unitID] and (t - lastJump[unitID]) >= reload) and Spring.GetUnitRulesParam(unitID,"disarmed") ~= 1 then
			local didJump, removeCommand = Jump(unitID, cmdParams, cmdTag)
			if not didJump then
				return true, removeCommand -- command was used
			end
			return true, false -- command was used but don't remove it (unit have not finish jump yet)
			
			--[[ with Jump randomizer:
			local coords = table.concat(cmdParams)
			local currFrame = spGetGameFrame()
			for allCoords, oldStuff in pairs(jumps) do
				if currFrame-oldStuff[2] > 150 then 
					jumps[allCoords] = nil --empty jump table (used for randomization) after 5 second. Use case: If infinite wave of unit has same jump coordinate then jump coordinate won't get infinitely random
				end
			end
			if (not jumps[coords]) then
				local didJump, removeCommand = Jump(unitID, cmdParams, cmdTag)
				if not didJump then
					return true, removeCommand -- command was used
				end
				jumps[coords] = {1,currFrame}
				return true, false -- command was used but don't remove it (unit have not finish jump yet)
			else
				local r = landBoxSize*jumps[coords][1]^0.5/2
				local randpos = {
					cmdParams[1] + random(-r, r),
					cmdParams[2],
					cmdParams[3] + random(-r, r)}
				local didJump, removeCommand = Jump(unitID, randpos, cmdTag)
				if not didJump then
					return true, removeCommand -- command was used
				end
				jumps[coords][1] = jumps[coords][1] + 1
				return true, false -- command was used but don't remove it (unit have not finish jump yet)
			end
			--]]
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
	-- if #speedProfile-1>0 and speedProfile[#speedProfile-1] and speedProfile[#speedProfile] then
		-- Spring.Echo(speedProfile[#speedProfile] - speedProfile[#speedProfile-1])
	-- end
end
