function gadget:GetInfo() return {
		name    = "Jumpjets",
		desc    = "Gives units the jump ability",
		author  = "quantum",
		date    = "May 14, 2008", --last update 2015-05-05
		license = "GNU GPL, v2 or later",
		layer   = 0,
		enabled = not (Spring.GetModOptions().impulsejump  == "1"), -- loaded by default?
} end

if (not gadgetHandler:IsSyncedCode()) then return end

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
local spGetGroundNormal    = Spring.GetGroundNormal
local spTestMoveOrder      = Spring.TestMoveOrder
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

local mcSetRotationVelocity = MoveCtrl.SetRotationVelocity
local mcSetPosition	        = MoveCtrl.SetPosition
local mcSetRotation         = MoveCtrl.SetRotation
local mcDisable	            = MoveCtrl.Disable
local mcEnable	            = MoveCtrl.Enable

local SetLeaveTracks = Spring.SetUnitLeaveTracks -- or MoveCtrl.SetLeaveTracks --0.82 compatiblity

local emptyTable = {}

local coroutines = {}
local lastJumpPosition = {}
local landBoxSize = 60
local jumps = {}
local jumping = {}
local goalSet = {}

local quiteNew = Spring.Utilities.IsCurrentVersionNewerThan(95, 0)

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local jumpDefs = VFS.Include ("LuaRules/Configs/jump_defs.lua")

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

local function spTestMoveOrderX(unitDefID, x, y, z)
	if quiteNew then
		return spTestMoveOrder(unitDefID, x, y, z, 0, 0, 0, true, true, true)
	else
		return spTestBuildOrder(unitDefID, x, y, z, 1)
	end
end


local function GetLandStructureCheckValues(x, z, myRadius)
	-- The largest structure radius is 60 elmos (mahlazer)
	local units = Spring.GetUnitsInCylinder(x,z, 60 + myRadius)
	
	local smallestDistance = 60 + myRadius
	local structureID = false
	local smallestObjectRadius = 0
	
	-- Find the nearby structure which most likely caused the jump
	-- to be a structure jump.
	local spGetUnitRadius = Spring.GetUnitRadius
	
	for i = 1, #units do
		local unitID = units[i]
		local unitDefID = spGetUnitDefID(unitID)
		-- Only check immobile units
		if UnitDefs[unitDefID] and UnitDefs[unitDefID].isImmobile then
			local radius = spGetUnitRadius(unitID)
			local sx, sy, sz = spGetUnitPosition(unitID)
			
			-- If the unit overlaps the center then distance is negative
			local dist = math.sqrt((sx - x)^2 + (sz - z)^2) - radius
			if dist < smallestDistance then
				structureID = unitID
				smallestDistance = dist
				smallestObjectRadius = radius
			end
		end
	end
	
	local featureID = false
	if smallestDistance > myRadius then
		-- No sufficiently close structure was found, 
		-- check whether the blocking was due to a feature.
		local features = Spring.GetFeaturesInCylinder(x,z, 60 + myRadius)
		
		local spGetFeatureBlocking = Spring.GetFeatureBlocking
		local spGetFeatureRadius   = Spring.GetFeatureRadius
		local spGetFeaturePosition = Spring.GetFeaturePosition
		
		local featureDist = 60 + myRadius
		local featureRadius = 0
		
		for i = 1, #features do
			local fid = features[i]
			local blocking = spGetFeatureBlocking(fid)
			if blocking then
				local radius = spGetFeatureRadius(fid)
				local sx, sy, sz = spGetFeaturePosition(fid)
				
				local dist = math.sqrt((sx - x)^2 + (sz - z)^2) - radius
				if dist < featureDist then
					featureID = fid
					featureDist = dist
					featureRadius = radius
				end
			end
		end
		
		-- Replace closest structure with feature if the feature is closer
		if featureID and featureDist < smallestDistance then
			structureID = false
			smallestObjectRadius = featureRadius
		end
	end
	
	if structureID then
		-- Mid position, not base position.
		local _, _, _, sx, sy, sz = spGetUnitPosition(structureID, true)
		return {x = sx, y = sy, z = sz, distSq = (smallestObjectRadius + myRadius)^2}
	elseif featureID then
		local _, _, _, sx, sy, sz = Spring.GetFeaturePosition(featureID, true)
		return {x = sx, y = sy, z = sz, distSq = (smallestObjectRadius + myRadius)^2}
	end
	
	return false
end

local function CheckStructureCollision(data, x, y, z)
	return (data.x - x)^2 + (data.y - y)^2 + (data.z - z)^2 < data.distSq
end

local function GetDist2Sqr(a, b)
	local x, z = (a[1] - b[1]), (a[3] - b[3])
	return (x*x + z*z)
end

local function GetDist3(a, b)
	local x, y, z = (a[1] - b[1]), (a[2] - b[2]), (a[3] - b[3])
	return (x*x + y*y + z*z)^0.5
end


local function Approach(unitID, cmdParams, range)
	spSetUnitMoveGoal(unitID, cmdParams[1],cmdParams[2],cmdParams[3], range)
end

local function StartScript(fn)
	local co = coroutine.create(fn)
	coroutines[#coroutines + 1] = co
end

local function Jump(unitID, goal, cmdTag, origCmdParams)
	goal[2]                = spGetGroundHeight(goal[1],goal[3])
	local start            = {spGetUnitPosition(unitID)}

	local fakeUnitID
	local unitDefID	       = spGetUnitDefID(unitID)
	local jumpDef          = jumpDefs[unitDefID]
	local speed	           = jumpDef.speed
	local delay	           = jumpDef.delay
	local height           = jumpDef.height
	local cannotJumpMidair = jumpDef.cannotJumpMidair
	local reloadTime       = (jumpDef.reload or 0)*30
	local teamID           = spGetUnitTeam(unitID)
	
	if cannotJumpMidair and abs(spGetGroundHeight(start[1],start[3]) - start[2]) > 1 then
		return false, true
	end
	
	local rotateMidAir	= jumpDef.rotateMidAir
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
	
	jumping[unitID] = {vector[1]*step, vector[2]*step, vector[3]*step}

	mcEnable(unitID)
	Spring.SetUnitRulesParam(unitID, "is_jumping", 1)
	Spring.SetUnitVelocity(unitID,0,0,0)
	SetLeaveTracks(unitID, false)

	env = Spring.UnitScript.GetScriptEnv(unitID)
	
	if (delay == 0) then
		Spring.UnitScript.CallAsUnit(unitID,env.beginJump,turn,lineDist,flightDist,duration)
		if rotateMidAir then
			mcSetRotation(unitID, 0, (startHeading - 2^15)/rotUnit, 0) -- keep current heading
			mcSetRotationVelocity(unitID, 0, turn/rotUnit*step, 0)
		end
	else
		Spring.UnitScript.CallAsUnit(unitID,env.preJump,turn,lineDist,flightDist,duration)
	end
	spSetUnitRulesParam(unitID,"jumpReload",0)

	local function JumpLoop()

		if delay > 0 then
			for i=delay, 1, -1 do
				Sleep()
			end
		
			Spring.UnitScript.CallAsUnit(unitID,env.beginJump)

			if rotateMidAir then
				mcSetRotation(unitID, 0, (startHeading - 2^15)/rotUnit, 0) -- keep current heading
				mcSetRotationVelocity(unitID, 0, turn/rotUnit*step, 0)
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
	
		local hitStructure, structureCollisionData
		local halfJump
		local i = 0
		while i <= 1 do
			if (not Spring.ValidUnitID(unitID) or Spring.GetUnitIsDead(unitID)) then 
				return 
			end

			local x0, y0, z0 = spGetUnitPosition(unitID)
			local x = start[1] + vector[1]*i
			local y = start[2] + vector[2]*i + (1-(2*i-1)^2)*height -- parabola
			local z = start[3] + vector[3]*i
			mcSetPosition(unitID, x, y, z)
			if x0 then
				jumping[unitID] = {x - x0, y - y0, z - z0}
				spSetUnitVelocity(unitID, x - x0, y - y0, z - z0) -- for the benefit of unit AI and possibly target prediction (probably not the latter)
			end

			Spring.UnitScript.CallAsUnit(unitID,env.jumping, 1, i * 100)
		
			if (not halfJump and i > 0.5) then
				Spring.UnitScript.CallAsUnit(unitID,env.halfJump)
				halfJump = true
				
				-- Do structure collision here to prevent early collision (perhaps a rejump onto the same structure?)
				-- If the move order test fails it means the command must have been allowed because the ground
				-- was otherwise high and flat enough for pathing. This means that a structure (or feature) is at the
				-- land location.
				if not spTestMoveOrderX(unitDefID, goal[1], goal[2], goal[3]) then
					local radius = Spring.GetUnitRadius(unitID)
					structureCollisionData = GetLandStructureCheckValues(goal[1], goal[3], radius)
				end
			end
			
			if structureCollisionData and CheckStructureCollision(structureCollisionData, x, y, z) then
				hitStructure = {x, y, z}
				break
			end
			
			Sleep()
			--[[ Slow damage
			local slowMult = 1-(Spring.GetUnitRulesParam(unitID, "slowState") or 0)
			i = i + (step*slowMult)
			]]
			i = i + step
		end

		Spring.UnitScript.CallAsUnit(unitID,env.endJump)
		local jumpEndTime = spGetGameSeconds()
		lastJumpPosition[unitID] = origCmdParams
		jumping[unitID] = nil
		SetLeaveTracks(unitID, true)
		spSetUnitVelocity(unitID, 0, 0, 0)
		Spring.SetUnitRulesParam(unitID, "is_jumping", 0)
		mcDisable(unitID)

		if Spring.ValidUnitID(unitID) and (not Spring.GetUnitIsDead(unitID)) then
			spGiveOrderToUnit(unitID,CMD_WAIT, {}, {})
			spGiveOrderToUnit(unitID,CMD_WAIT, {}, {})
		end
		
		if hitStructure then
			-- Add unstick impulse to make the jumper bound on the structure.
			Spring.AddUnitImpulse(unitID, 3,0,3)
			Spring.AddUnitImpulse(unitID, 0,-0.5,0)
			Spring.AddUnitImpulse(unitID, -3,0,-3)
			-- Set position because the unit may snap to the ground.
			Spring.SetUnitPosition(unitID, hitStructure[1], hitStructure[2], hitStructure[3])
		end

		Sleep()
		
		local morphedTo = Spring.GetUnitRulesParam(unitID, "wasMorphedTo")
		if morphedTo then
			lastJumpPosition[morphedTo] = lastJumpPosition[unitID]
			lastJumpPosition[unitID] = nil
			unitID = morphedTo
		end
		
		if Spring.ValidUnitID(unitID) and (not Spring.GetUnitIsDead(unitID)) then
			Spring.SetUnitVelocity(unitID, 0, 0, 0) -- prevent the impulse capacitor
		end

		local reloadSpeed = 1/reloadTime
		local reloadAmount = reloadSpeed -- Start here because we just did a sleep for impulse capacitor fix
		
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

function gadget:Initialize()
	Spring.SetCustomCommandDrawData(CMD_JUMP, "Jump", {0, 1, 0, 0.7})
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
	Spring.SetUnitRulesParam(unitID, "jumpReload", 1)
	spInsertUnitCmdDesc(unitID, jumpCmdDesc)
end

-- Makes wrecks continue inertially instead of falling straight down
function gadget:UnitDamaged(unitID)
	local jump_dir = jumping[unitID]
	if (Spring.GetUnitHealth(unitID) < 0) and jump_dir then
		mcDisable(unitID)
		Spring.AddUnitImpulse(unitID,jump_dir[1],jump_dir[2],jump_dir[3])
		jumping[unitID] = nil
	end
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
	
	if cmdID == CMD_JUMP then
		if spTestMoveOrderX(unitDefID, cmdParams[1], cmdParams[2], cmdParams[3]) then
			return true
		else
			-- Check whether the terrain is the source of the blockage. If it is not then
			-- conclude that the blockage is a structure.
			local height = spGetGroundHeight(cmdParams[1],cmdParams[3])
			if (not UnitDefs[unitDefID]) or height < -UnitDefs[unitDefID].maxWaterDepth then
				-- Water too deep for the unit to walk on
				return false
			end
			
			local normal = select(2, spGetGroundNormal(cmdParams[1],cmdParams[3]))
			-- Most of the time the normal will be close to 1 because structures are built on
			-- flat ground. This check captures high slope tolerance things such as Windgens and
			-- small turrets.
			if normal < 0.6 then
				 -- Ground is too steep for bots to walk on.
				return false
			end
			
			-- Ground is fine, must contain a blocking structure.
			return true
		end
	end
	if goalSet[unitID] then
		goalSet[unitID] = nil
	end	
	return true -- allowed
end

function gadget:CommandFallback(unitID, unitDefID, teamID, cmdID, cmdParams, cmdOptions) -- Only calls for custom commands
	if (not jumpDefs[unitDefID]) then
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

	if (distSqr < (range*range)) then
		local cmdTag = spGetCommandQueue(unitID,1)[1].tag
		if (Spring.GetUnitRulesParam(unitID, "jumpReload") >= 1) and Spring.GetUnitRulesParam(unitID,"disarmed") ~= 1 then
			local coords = table.concat(cmdParams)
			local currFrame = spGetGameFrame()
			for allCoords, oldStuff in pairs(jumps) do
				if currFrame-oldStuff[2] > 150 then 
					jumps[allCoords] = nil --empty jump table (used for randomization) after 5 second. Use case: If infinite wave of unit has same jump coordinate then jump coordinate won't get infinitely random
				end
			end
			if (not jumps[coords]) or jumpDefs[unitDefID].JumpSpreadException then
				local didJump, removeCommand = Jump(unitID, cmdParams, cmdTag, cmdParams)
				if not didJump then
					return true, removeCommand -- command was used
				end
				jumps[coords] = {1, currFrame} --memorize coordinate so that next unit can choose different landing site
				return true, false -- command was used but don't remove it (unit have not finish jump yet)
			else
				local r = landBoxSize*jumps[coords][1]^0.5/2
				local randpos = {
					cmdParams[1] + random(-r, r),
					cmdParams[2],
					cmdParams[3] + random(-r, r)}
				local didJump, removeCommand = Jump(unitID, randpos, cmdTag, cmdParams)
				if not didJump then
					return true, removeCommand -- command was used
				end
				jumps[coords][1] = jumps[coords][1] + 1
				return true, false -- command was used but don't remove it(unit have not finish jump yet)
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


function gadget:GameFrame(currFrame)
	UpdateCoroutines()
	for coords, queue_n_age in pairs(jumps) do 
		if currFrame-queue_n_age[2] > 300 then
			jumps[coords] = nil
		end
	end
end
