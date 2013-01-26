-- $Id: unit_jumpjets.lua 4056 2009-03-11 02:59:18Z quantum $
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function gadget:GetInfo()
	return {
		name    = "Jumpjets",
		desc    = "Gives units the jump ability",
		author  = "quantum",
		date    = "May 14, 2008",
		license = "GNU GPL, v2 or later",
		layer   = 0,
		enabled = true -- loaded by default?
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
local MoveCtrl  = Spring.MoveCtrl
local coroutine = coroutine
local Sleep	    = coroutine.yield
local pairs     = pairs
local assert    = assert

local pi2    = math.pi*2
local random = math.random
local abs    = math.abs

local CMD_STOP = CMD.STOP

local spGetHeadingFromVector = Spring.GetHeadingFromVector
local spGetUnitBasePosition  = Spring.GetUnitBasePosition
local spInsertUnitCmdDesc  = Spring.InsertUnitCmdDesc
local spSetUnitRulesParam  = Spring.SetUnitRulesParam
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
local spGetUnitHeading     = Spring.GetUnitHeading
local spSetUnitNoDraw      = Spring.SetUnitNoDraw
local spCallCOBScript      = Spring.CallCOBScript
local spSetUnitNoDraw      = Spring.SetUnitNoDraw
local spGetUnitDefID       = Spring.GetUnitDefID
local spGetUnitTeam        = Spring.GetUnitTeam
local spDestroyUnit        = Spring.DestroyUnit
local spCreateUnit         = Spring.CreateUnit

local mcSetRotationVelocity = MoveCtrl.SetRotationVelocity
local mcSetPosition	        = MoveCtrl.SetPosition
local mcSetRotation         = MoveCtrl.SetRotation
local mcDisable	            = MoveCtrl.Disable
local mcEnable	            = MoveCtrl.Enable

local SetLeaveTracks = Spring.SetUnitLeaveTracks -- or MoveCtrl.SetLeaveTracks --0.82 compatiblity

local emptyTable = {}

local coroutines = {}
local lastJump = {}
local landBoxSize = 60
local jumps = {}
local jumping = {}
local goalSet = {}

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

local function Jump(unitID, goal, cmdTag)
	goal[2]						 = spGetGroundHeight(goal[1],goal[3])
	local start				 = {spGetUnitBasePosition(unitID)}

	local fakeUnitID
	local unitDefID		 = spGetUnitDefID(unitID)
	local jumpDef			 = jumpDefs[unitDefID]
	local speed				 = jumpDef.speed
	local delay				= jumpDef.delay
	local height				= jumpDef.height
	local cannotJumpMidair		= jumpDef.cannotJumpMidair
	local reloadTime		= (jumpDef.reload or 0)*30
	local teamID				= spGetUnitTeam(unitID)
	
	if cannotJumpMidair and abs(spGetGroundHeight(start[1],start[3]) - start[2]) > 1 then
		return false, true
	end
	
	local rotateMidAir	= jumpDef.rotateMidAir
	local cob 	 		= jumpDef.cobscript
	local env

	local vector = {goal[1] - start[1],
					goal[2] - start[2],
					goal[3] - start[3]}
	
	-- vertex of the parabola
	local vertex = {start[1] + vector[1]*0.5,
					start[2] + vector[2]*0.5 + (1-(2*0.5-1)^2)*height,
					start[3] + vector[3]*0.5}
	
	local lineDist = GetDist3(start, goal)
	if lineDist == 0 then lineDist = 0.00001 end
	local flightDist = GetDist3(start, vertex) + GetDist3(vertex, goal)
	
	local speed = speed * lineDist/flightDist
	local step = speed/lineDist
	local duration = math.ceil(1/step)+1
	
	-- check if there is no wall in between
	local x,z = start[1],start[3]
	for i=0, 1, step do
		x = x + vector[1]*step
		z = z + vector[3]*step
		if ( (spGetGroundHeight(x,z) - 30) > (start[2] + vector[2]*i + (1-(2*i-1)^2)*height)) then
			return false, false -- FIXME: should try to use SetMoveGoal instead of jumping!
		end
	end

	-- pick shortest turn direction
	local rotUnit			 = 2^16 / (pi2)
	local startHeading	= spGetUnitHeading(unitID) + 2^15
	local goalHeading	 = spGetHeadingFromVector(vector[1], vector[3]) + 2^15
	if (goalHeading	>= startHeading + 2^15) then
		startHeading = startHeading + 2^16
	elseif (goalHeading	< startHeading - 2^15)	then
		goalHeading	= goalHeading	+ 2^16
	end
	local turn = goalHeading - startHeading
	
	jumping[unitID] = true

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
				Spring.UnitScript.CallAsUnit(unitID,env.beginJump,turn,lineDist,flightDist,duration)
			end
		if rotateMidAir then
			mcSetRotation(unitID, 0, (startHeading - 2^15)/rotUnit, 0) -- keep current heading
			mcSetRotationVelocity(unitID, 0, turn/rotUnit*step, 0)
		end
	else
		if cob then
			spCallCOBScript( unitID, "PreJump", 0)
		else
			Spring.UnitScript.CallAsUnit(unitID,env.preJump,turn,lineDist,flightDist,duration)
		end
	end
	spSetUnitRulesParam(unitID,"jumpReload",0)

	local function JumpLoop()
	
		if delay > 0 then
			if GG.wasMorphedTo[unitID] then
				local oldUnitID = unitID --previous unitID
				unitID = GG.wasMorphedTo[unitID] --new unitID
				local unitDefID = spGetUnitDefID(unitID)
				if (not jumpDefs[unitDefID]) then --check if new unit can jump
					jumping[oldUnitID] = nil
					lastJump[oldUnitID] = nil
					return --exit JumpLoop() if unit can't jump
				end
				cob = jumpDefs[unitDefID].cobscript --script type
				rotateMidAir = jumpDefs[unitDefID].rotateMidAir --unit rotate to face new direction?
				delay = jumpDefs[unitDefID].delay --prejump delay
				speed = jumpDefs[unitDefID].speed  * lineDist/flightDist --speed from A to B
				height = jumpDefs[unitDefID].height --max height
				reloadTime = (jumpDefs[unitDefID].reload or 0)*30 --jump reload time
				if not cob then
					env = Spring.UnitScript.GetScriptEnv(unitID) --get new unit's script
				end
				step = speed/lineDist --resolution of JumpLoop() update
				mcEnable(unitID) --enable MoveCtrl for new unit
				SetLeaveTracks(unitID, false) --set no track
				jumping[unitID] = true --flag unit as jumping
				lastJump[unitID] = lastJump[oldUnitID] --copy last jump timestamp to new unit
				jumping[oldUnitID] = nil --empty old unit's data
				lastJump[oldUnitID] = nil
			end
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
		local i = 0
		while i <= 1 do
			if GG.wasMorphedTo[unitID] then
				local oldUnitID = unitID
				unitID = GG.wasMorphedTo[unitID]
				local unitDefID = spGetUnitDefID(unitID)
				if (not jumpDefs[unitDefID]) then
					jumping[oldUnitID] = nil
					lastJump[oldUnitID] = nil
					return
				end
				cob = jumpDefs[unitDefID].cobscript
				speed = jumpDefs[unitDefID].speed  * lineDist/flightDist --speed from A to B
				reloadTime = (jumpDefs[unitDefID].reload or 0)*30
				if not cob then
					env = Spring.UnitScript.GetScriptEnv(unitID)
				end
				step = speed/lineDist --resolution of JumpLoop() update
				mcEnable(unitID)
				SetLeaveTracks(unitID, false)
				jumping[unitID] = true
				lastJump[unitID] = lastJump[oldUnitID]
				jumping[oldUnitID] = nil
				lastJump[oldUnitID] = nil				
				halfJump = nil --reset halfjump flag. Redo halfjump script for new unit
				if rotateMidAir then 
					mcSetRotationVelocity(unitID, 0, turn/rotUnit*step, 0) --resume unit rotation mid air
				end
			end
			if ((not spGetUnitTeam(unitID)) and fakeUnitID) then
				spDestroyUnit(fakeUnitID, false, true)
				return -- unit died
			end
			local x0, y0, z0 = spGetUnitBasePosition(unitID)
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
		
			if (fakeUnitID) then 
				mcSetPosition(fakeUnitID, x, y, z) 
			end
			if (not halfJump and i > 0.5) then
				if cob then
					spCallCOBScript( unitID, "HalfJump", 0)
				else
					Spring.UnitScript.CallAsUnit(unitID,env.halfJump)
				end
				halfJump = true
			end
			Sleep()
			i = i + step
		end

		if (fakeUnitID) then 
			spDestroyUnit(fakeUnitID, false, true) 
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
		mcDisable(unitID)
	
		--mcSetPosition(unitID, start[1] + vector[1],start[2] + vector[2]-6,start[3] + vector[3])
		local oldQueue = spGetCommandQueue(unitID)
	
		ReloadQueue(unitID, oldQueue, cmdTag)
	
		for j=1, reloadTime do
			if GG.wasMorphedTo[unitID] then
				local oldUnitID = unitID
				unitID = GG.wasMorphedTo[unitID]
				reloadTime = (jumpDefs[unitDefID].reload or 0)*30
				lastJump[unitID] = jumpEndTime --copy last jump timestamp to new unit
				jumping[oldUnitID] = nil --empty old unit's data
			end
			spSetUnitRulesParam(unitID,"jumpReload",j/reloadTime)
			Sleep()
			if j == 1 then
				if Spring.ValidUnitID(unitID) and (not Spring.GetUnitIsDead(unitID)) then
					Spring.SetUnitVelocity(unitID, 0, 0, 0) -- prevent the impulse capacitor
				end
			end
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

function gadget:Initialize()
	Spring.SetCustomCommandDrawData(CMD_JUMP, "Jump", {0, 1, 0, 1})
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


function gadget:UnitDestroyed(unitID, unitDefID)
	if not (jumping[unitID] and GG.wasMorphedTo[unitID]) then --do not clear the "lastJump[]" table if unit is just morphing & not dying.
		lastJump[unitID] = nil
	end
end


function gadget:AllowCommand(unitID, unitDefID, teamID, cmdID, cmdParams, cmdOptions)
	if (cmdID == CMD_JUMP and 
		spTestBuildOrder(
			unitDefID, cmdParams[1], cmdParams[2], cmdParams[3], 1) == 0) then
		return false
	end
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
	if (not jumpDefs[unitDefID]) then
		return false
	end
	
	if (cmdID ~= CMD_JUMP) then
		return false
	end

	if not Spring.ValidUnitID(unitID) then
		return true, true
	end

	if (jumping[unitID]) then
		return true, false -- command was used but don't remove it
	end

	local x, y, z = spGetUnitBasePosition(unitID)
	local distSqr = GetDist2Sqr({x, y, z}, cmdParams)
	local jumpDef = jumpDefs[unitDefID]
	local range   = jumpDef.range
	local reload  = jumpDef.reload or 0
	local t       = spGetGameSeconds()

	if (distSqr < (range*range)) then
		local cmdTag = spGetCommandQueue(unitID,1)[1].tag
		if (lastJump[unitID] and (t - lastJump[unitID]) >= reload) then
			local coords = table.concat(cmdParams)
			if (not jumps[coords]) then
				local didJump, keepCommand = Jump(unitID, cmdParams, cmdTag)
				if not didJump then
					return true, true -- command was used, don't remove it
				end
				jumps[coords] = 1
				return true, keepCommand -- command was used, remove it 
			else
				local r = landBoxSize*jumps[coords]^0.5/2
				local randpos = {
					cmdParams[1] + random(-r, r),
					cmdParams[2],
					cmdParams[3] + random(-r, r)}
				local didJump, keepCommand = Jump(unitID, randpos, cmdTag)
				if not didJump then
					return true, true -- command was used, don't remove it
				end
				jumps[coords] = jumps[coords] + 1
				return true, keepCommand -- command was used, remove it 
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
