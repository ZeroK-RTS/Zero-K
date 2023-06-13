function gadget:GetInfo()
	return {
		name    = "Refuel Pad Handler",
		desc    = "Replaces the engine implementation of the refuel pad.",
		author  = "Google Frog",
		date    = "5 Jan 2014", --changes: 22 March 2014
		license = "GNU GPL, v2 or later",
		layer   = 0,
		enabled = true, -- loaded by default?
	}
end

if (not gadgetHandler:IsSyncedCode()) then
	return false -- no unsynced code
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local spGetUnitBasePosition = Spring.GetUnitBasePosition
local spGetUnitHeading      = Spring.GetUnitHeading
local spGetUnitDefID        = Spring.GetUnitDefID
local spSetUnitVelocity     = Spring.SetUnitVelocity
local spSetUnitLeaveTracks  = Spring.SetUnitLeaveTracks
local spGetUnitVelocity     = Spring.GetUnitVelocity
local spGetUnitRotation     = Spring.GetUnitRotation
local spGetUnitHealth       = Spring.GetUnitHealth
local spSetUnitHealth       = Spring.SetUnitHealth
local spGetUnitIsStunned    = Spring.GetUnitIsStunned
local spGetUnitRulesParam   = Spring.GetUnitRulesParam
local spGetUnitIsDead       = Spring.GetUnitIsDead
local spUseUnitResource     = Spring.UseUnitResource

local mcSetVelocity         = Spring.MoveCtrl.SetVelocity
local mcSetRotationVelocity = Spring.MoveCtrl.SetRotationVelocity
local mcSetPosition         = Spring.MoveCtrl.SetPosition
local mcSetRotation         = Spring.MoveCtrl.SetRotation
local mcDisable             = Spring.MoveCtrl.Disable
local mcEnable              = Spring.MoveCtrl.Enable

local coroutine = coroutine
local Sleep     = coroutine.yield
local assert    = assert

-- South is 0 radians and increases counter-clockwise
local HEADING_TO_RAD = (math.pi*2/2^16)
local RAD_TO_HEADING = 1/HEADING_TO_RAD
local PI = math.pi
local cos = math.cos
local sin = math.sin
local acos = math.acos
local floor = math.floor
local sqrt = math.sqrt
local exp = math.exp
local min = math.min

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local mobilePadDefs = {}

for unitDefID, ud in pairs(UnitDefs) do
	if ud.customParams.ispad and (not ud.isImmobile) then
		mobilePadDefs[unitDefID] = true
	end
end

local DEFAULT_REAMMO_DRAIN = 10
local DEFAULT_REPAIR_BP = 2.5

local REPAIR_COST_FACTOR = Game.repairEnergyCostFactor

local padSnapRangeSqr = 80^2
local resTable = {e = 0, m = 0}

local turnRadius = {}
local reammoFrames = {}
local reammoDrain = {}
local padRepairBp = {}
local rotateUnit = {}

for i = 1, #UnitDefs do
	local movetype = Spring.Utilities.getMovetype(UnitDefs[i])
	local ud = UnitDefs[i]
	if movetype == 0 then -- fixedwing
		if ud.customParams and ud.customParams.refuelturnradius then
			turnRadius[i] = tonumber(ud.customParams.refuelturnradius)
		else
			turnRadius[i] = ud.turnRadius
		end
		rotateUnit[i] = true
	elseif movetype == 1 then -- gunship
		turnRadius[i] = 20
		rotateUnit[i] = false
	end
	if ud.customParams.reammoseconds then
		reammoFrames[i] = tonumber(ud.customParams.reammoseconds)*30
		reammoDrain[i] = (tonumber(ud.customParams.reammodrain) or DEFAULT_REAMMO_DRAIN)/30
	end
	
	if ud.customParams.ispad then
		padRepairBp[i] = tonumber(ud.customParams.pad_bp) or DEFAULT_REPAIR_BP
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local landingUnit = {}

local unitNewScript = {}
local unitMovectrled = {}

local coroutines = {}

local function StartScript(fn)
	local co = coroutine.create(fn)
	coroutines[#coroutines + 1] = co
end

local function GetBuildRate(unitID)
	local stunned_or_inbuild = spGetUnitIsStunned(unitID)
	if stunned_or_inbuild then
		return 0
	end
	return spGetUnitRulesParam(unitID, "totalBuildPowerChange") or 1
end

local function ForceImmediateAbort(unitID, padID, isLanded)
	if (not spGetUnitIsDead(unitID)) and Spring.ValidUnitID(unitID) then
		spSetUnitLeaveTracks(unitID, true)
		if isLanded then
			spSetUnitVelocity(unitID, 0, 0, 0)
			GG.StopMiscPriorityResourcing(padID, miscPriorityKey)
			-- activate unit and its jets. An attempt at the Vulture-losing-radar bug.
			Spring.SetUnitCOBValue(unitID, COB.ACTIVATION, 1)
		end
		mcDisable(unitID)
		GG.UpdateUnitAttributes(unitID)
	end
	unitMovectrled[unitID] = nil
	landingUnit[unitID] = nil
	return true
end

local function AbortCheck(unitID, padID, isLanded)
	if (not landingUnit[unitID]) or landingUnit[unitID].abort then
		return ForceImmediateAbort(unitID, padID, isLanded)
	end
	
	return spGetUnitIsDead(unitID) or (not Spring.ValidUnitID(unitID))
end

local function SitOnPad(unitID)
	local landData = landingUnit[unitID]
	local heading = spGetUnitHeading(unitID)
	if not heading then
		return
	end
	heading = heading*HEADING_TO_RAD
	
	local ppx, ppy, ppz, pdx, pdy, pdz = Spring.GetUnitPiecePosDir(landData.padID, landData.padPieceID)
	
	local unitDefID        = Spring.GetUnitDefID(unitID)
	local ud               = UnitDefs[unitDefID]
	local cost             = ud.metalCost
	local maxHP            = ud.health
	local healPerFrame     = landData.repairBp*maxHP/(REPAIR_COST_FACTOR*30*cost)
	local repairFrameDrain = landData.repairBp/30
	local reammoMaxTime     = reammoFrames[unitDefID]
	
	if not unitMovectrled[unitID] then
		mcEnable(unitID)
		spSetUnitLeaveTracks(unitID, false)
		unitMovectrled[unitID] = true
	end
	mcSetRotation(unitID,0,-heading,0)
	
	local padHeading = acos(pdz)
	if pdx < 0 then
		padHeading = 2*PI-padHeading
	end
	
	-- Spring.Echo(pdx)
	-- Spring.Echo(pdy)
	-- Spring.Echo(pdz)
	-- Spring.Echo(padHeading*180/PI)
	
	local miscPriorityKey = "p" .. unitID
	local headingDiff = heading - padHeading
	
	spSetUnitVelocity(unitID, 0, 0, 0)
	mcSetVelocity(unitID, 0, 0, 0)
	mcSetPosition(unitID, ppx, ppy, ppz)
	
	-- deactivate unit to cause the lups jets away
	Spring.SetUnitCOBValue(unitID, COB.ACTIVATION, 0)
	
	local function SitLoop()
		-- read unitrulesparam for save/load handling
		local reammoProgress = GG.RequireRefuel(unitID) and reammoMaxTime and (Spring.GetUnitRulesParam(unitID, "reammoProgress") or 0) * reammoMaxTime
		local landDuration = 0
		local oldBuildRate = 0
		local oldUpdateCost = 0
		local updateRate = 1
		
		Sleep() -- Avoid recursion in instantly cancelled commands.
		
		local health, buildRate, updateCost, drainScale, padTeamID
		while true do
			if AbortCheck(unitID, landData.padID, true) then
				return
			end
			padTeamID = Spring.GetUnitTeam(landData.padID)
			if not padTeamID then
				ForceImmediateAbort(unitID, landData.padID, true)
				return
			end
			
			if landData.mobilePad then
				local px, py, pz, dx, dy, dz = Spring.GetUnitPiecePosDir(landData.padID, landData.padPieceID)
				local newPadHeading = acos(dz)
				if dx < 0 then
					newPadHeading = 2*PI-newPadHeading
				end
				mcSetPosition(unitID, px, py, pz)
				mcSetRotation(unitID,0,-(headingDiff+newPadHeading),0)
			end
			
			buildRate = GetBuildRate(landData.padID)
			updateCost = ((reammoProgress and (reammoDrain[unitDefID] or 0)) or repairFrameDrain)
			if updateCost ~= oldUpdateCost or oldBuildRate ~= buildRate then
				oldBuildRate = buildRate
				oldUpdateCost = updateCost
				if updateCost > 0 then
					GG.StartMiscPriorityResourcing(landData.padID, buildRate*updateCost*30, true, miscPriorityKey)
				else
					GG.StopMiscPriorityResourcing(landData.padID, miscPriorityKey)
				end
			end
			
			if (updateCost > 0) then
				updateRate = GG.GetMiscPrioritySpendScale(landData.padID, padTeamID, true)
			else
				updateRate = 1
			end
			updateRate = updateRate*buildRate
			resTable.e = updateCost*updateRate
			
			if reammoProgress then
				if (updateRate > 0) and ((updateCost == 0) or spUseUnitResource(landData.padID, resTable)) then
					reammoProgress = reammoProgress + updateRate
					if reammoProgress > reammoMaxTime then
						reammoProgress = false
						GG.RefuelComplete(unitID)
						Spring.SetUnitRulesParam(unitID, "reammoProgress", nil, LOS_ACCESS)
					else
						Spring.SetUnitRulesParam(unitID, "reammoProgress", reammoProgress/reammoMaxTime, LOS_ACCESS)
					end
				end
			else
				health = spGetUnitHealth(unitID)
				if health < maxHP and (updateRate > 0) and ((updateCost == 0) or spUseUnitResource(landData.padID, resTable)) then
					spSetUnitHealth(unitID, min(maxHP, health + updateRate*healPerFrame))
				else
					GG.StopMiscPriorityResourcing(landData.padID, miscPriorityKey)
					break
				end
			end
			
			landDuration = landDuration + 1
			-- Check crashing every 10s as safety for a rare bug. Otherwise the pad will be oocupied forever.
			if landDuration%300 == 0 then
				if spGetUnitIsDead(unitID) or (not Spring.ValidUnitID(unitID)) or (Spring.GetUnitMoveTypeData(unitID).aircraftState == "crashing") then
					GG.StopMiscPriorityResourcing(landData.padID, miscPriorityKey)
					Spring.DestroyUnit(unitID)
				end
			end
			
			Sleep()
		end
		
		spSetUnitLeaveTracks(unitID, true)
		spSetUnitVelocity(unitID, 0, 0, 0)
		GG.StopMiscPriorityResourcing(landData.padID, miscPriorityKey)
		mcDisable(unitID)
		GG.UpdateUnitAttributes(unitID) --update pending attribute changes in unit_attributes.lua if available
		unitMovectrled[unitID] = nil
		landingUnit[unitID] = nil
		
		-- activate unit and its jets
		Spring.SetUnitCOBValue(unitID, COB.ACTIVATION, 1)
		
		GG.LandComplete(unitID)
	end
	
	StartScript(SitLoop)
end

local function CircleToLand(unitID, goal)
	unitNewScript[unitID] = true
	
	local start = {spGetUnitBasePosition(unitID)}
	
	local unitDefID	= spGetUnitDefID(unitID)
	local ud = unitDefID and UnitDefs[unitDefID]
	
	if not (unitDefID and ud and turnRadius[unitDefID]) then
		return
	end
	
	local turnCircleRadius = turnRadius[unitDefID]
	local turnCircleRadiusSq = turnCircleRadius^2
	
	local disSq = (goal[1] - start[1])^2 + (goal[2] - start[2])^2 + (goal[3] - start[3])^2
	if disSq < padSnapRangeSqr then
		turnCircleRadius = 1
	end
	
	local vx,vy,vz = spGetUnitVelocity(unitID)
	local maxSpeed = sqrt(vx*vx + vy*vy + vz*vz)
	
	local targetSpeed = ud.speed/30
	
	local heading = spGetUnitHeading(unitID)*HEADING_TO_RAD
	
	-- Find position of focus points for left or right turning circles
	local leftFocus = {
		[1] = start[1] + turnCircleRadius*sin(heading + PI/2),
		[3] = start[3] + turnCircleRadius*cos(heading + PI/2)
	}
	
	local rightFocus = {
		[1] = start[1] + turnCircleRadius*sin(heading - PI/2),
		[3] = start[3] + turnCircleRadius*cos(heading - PI/2)
	}
	
	-- Decide upon direction to turn
	local leftDistSq = (goal[1] - leftFocus[1])^2 + (goal[3] - leftFocus[3])^2
	local rightDistSq = (goal[1] - rightFocus[1])^2 + (goal[3] - rightFocus[3])^2
	
	--Spring.MarkerAddPoint(leftFocus[1],0,leftFocus[3],sqrt(leftDistSq))
	--Spring.MarkerAddPoint(rightFocus[1],0,rightFocus[3],sqrt(rightDistSq))
	
	local turnDir -- 1 is left, -1 is right.
	local focus
	if rightDistSq < turnCircleRadiusSq then
		turnDir = 1
		focus = leftFocus
	elseif leftDistSq < turnCircleRadiusSq then
		turnDir = -1
		focus = rightFocus
	elseif leftDistSq < rightDistSq then
		turnDir = 1
		focus = leftFocus
	else
		turnDir = -1
		focus = rightFocus
	end
	
	-- Determine the equations of the two lines tangent to the circle passing through the goal.
	local fx,fz,gx,gz,r = focus[1], focus[3], goal[1], goal[3], turnCircleRadius
	
	local denom = (fx^2 - 2*fx*gx + gx^2 - r^2)
	if denom == 0 then
		denom = 0.0001
	end
	local determinateSqrt = sqrt(fx^2*r^2 + fz^2*r^2 - 2*fx*gx*r^2 + gx^2*r^2 - 2*fz*gz*r^2 + gz^2*r^2 - r^4)
	local otherBit = fx*fz - fz*gx - fx*gz + gx*gz
	
	local grad1 = (otherBit - determinateSqrt)/denom
	local grad2 = (otherBit + determinateSqrt)/denom
	
	-- Choose a line
	local gradToFocus = (fz - gz)/(fx == gx and 0.0001 or fx - gx)
	
	local grad
	if (grad1 < gradToFocus and gradToFocus < grad2) or (grad2 < gradToFocus and gradToFocus < grad1) then
		if grad1*turnDir < grad2*turnDir then
			grad = grad1
		else
			grad = grad2
		end
	else
		if grad1*turnDir < grad2*turnDir then
			grad = grad2
		else
			grad = grad1
		end
	end
	
	-- Find the intersection of the line and circle.
	local ix = (fx + fz*grad - gz*grad + gx*grad^2)/(1 + grad^2)
	local iz = grad*(ix-gx)+gz
	
	-- Find the angle to the intersection and the distance to it along the circle.
	local sAngle = (heading - turnDir*PI/2)
	local iAngle = acos((iz-fz)/turnCircleRadius) or PI/2
	if ix < fx then
		iAngle = -iAngle
	end
	iAngle = iAngle%(2*PI)
	
	local angularDist = turnDir*(iAngle - sAngle)%(2*PI)
	local circleDist = angularDist*turnCircleRadius

	-- Calculate linear distance after turning and vector to follow
	local lineDist = sqrt((gx - ix)^2 + (gz - iz)^2)
	local lineVectorX = (gx - ix)/lineDist
	local lineVectorZ = (gz - iz)/lineDist
	
	local totalDist = circleDist + lineDist
	
	-- Functions which determine position and direction based on distance travelled
	local function DistanceToPosition(distance)
		if distance < circleDist then
			return fx + turnCircleRadius*sin(sAngle + turnDir*distance/turnCircleRadius), fz + turnCircleRadius*cos(sAngle + turnDir*distance/turnCircleRadius)
		else
			return ix + (distance - circleDist)*lineVectorX, iz + (distance - circleDist)*lineVectorZ
		end
	end
	
	local linearDirection = acos(lineVectorZ)
	if lineVectorX < 0 then
		linearDirection = -linearDirection
	end
	
	local function DistanceToDirection(distance)
		if distance < circleDist then
			return heading + turnDir*distance/turnCircleRadius
		else
			return linearDirection
		end
	end
	
	-- Calculate speeds and acceleration
	local currentSpeed = maxSpeed
	local currentTime = 1
	
	local estimatedTime = (2*totalDist)/(maxSpeed+targetSpeed)
	local acceleration = (targetSpeed^2 - maxSpeed^2)/(2*totalDist)
	
	-- Sigmoid Version (have problem with landing on mobile airpad)
	-- local function TimeToVerticalPositon(t)
		-- return start[2] + (goal[2] - start[2])*(1/(1 + exp(6*(-2*t/estimatedTime +1))))
	-- end
	
	-- Straight line Version
	local function TimeToVerticalPositon(t)
		return start[2] + (goal[2] - start[2])*t/estimatedTime
	end
	
	--[[
	for i = 0, totalDist, maxSpeed do
		local px, pz = DistanceToPosition(i)
		Spring.MarkerAddPoint(px,0,pz,"")
	end
		
	Spring.MarkerAddLine(gx,0,gz,ix,0,iz)
	Spring.Echo(sqrt(lineVectorX^2 + lineVectorZ^2))
	--]]
	
	-- Roll Animation
	local roll = 0
	--local _,_,roll = spGetUnitRotation(unitID) -- function not present in 91.0
	roll = -roll
	
	local rollStopFudgeDistance = maxSpeed*25
	local rollSpeed = 0.03
	local maxRoll = 0.8
	
	-- Move control stuff
	if not unitMovectrled[unitID] then
		mcEnable(unitID)
		if rotateUnit[unitDefID] then
			mcSetRotation(unitID,0,-heading,-(roll+currentTime/50))
		end
		spSetUnitLeaveTracks(unitID, false)
		unitMovectrled[unitID] = true
	end
	
	local currentDistance = currentSpeed

	local function LandLoop()
		
		local prevX, prevY, prevZ = start[1], start[2], start[3]
		
		while currentDistance + currentSpeed < totalDist do
			
			if AbortCheck(unitID) then
				return
			end
			if (Spring.GetUnitRulesParam(unitID, "crashing") == 1) then
				ForceImmediateAbort(unitID, padID, isLanded)
				return
			end
			
			local px, pz = DistanceToPosition(currentDistance)
			local py = TimeToVerticalPositon(currentTime)
			local direction = DistanceToDirection(currentDistance)
			
			if rotateUnit[unitDefID] then
				mcSetRotation(unitID,0,-direction,-roll)
			end
			mcSetPosition(unitID, px, py, pz)
			mcSetVelocity(unitID, px - prevX, py - prevY, pz - prevZ)
			spSetUnitVelocity(unitID, px - prevX, 0, pz - prevZ)
			
			currentDistance = currentDistance + currentSpeed
			currentSpeed = currentSpeed + acceleration
			currentTime = currentTime + 1
			
			if currentDistance < circleDist - rollStopFudgeDistance then
				if -roll*turnDir < maxRoll then
					roll = roll - turnDir*rollSpeed
				elseif -roll*turnDir > maxRoll + rollSpeed then
					roll = roll + turnDir*rollSpeed
				end
			else
				if -roll*turnDir > 0 then
					roll = roll + turnDir*rollSpeed
				elseif -roll*turnDir < -rollSpeed then
					roll = roll - turnDir*rollSpeed
				end
			end
			
			prevX, prevY, prevZ = px, py, pz
			Sleep()
			if unitNewScript[unitID] and currentTime ~= 2 then
				return
			else
				unitNewScript[unitID] = nil
			end
		end
		
		if (not AbortCheck(unitID)) and landingUnit[unitID] then
			
			landingUnit[unitID].landed = true
			SitOnPad(unitID)
		end
	end
	
	StartScript(LandLoop)
end

function GG.SendBomberToPad(unitID, padID, padPieceID)
	local padDefID = Spring.GetUnitDefID(padID)
	landingUnit[unitID] = {
		mobilePad = padDefID and mobilePadDefs[padDefID],
		padID = padID,
		padPieceID = padPieceID,
		repairBp = padRepairBp[padDefID],
	}
	
	local px, py, pz = Spring.GetUnitPiecePosDir(padID, padPieceID)
	CircleToLand(unitID, {px,py,pz})
end

function GG.LandAborted(unitID)
	if landingUnit[unitID] then
		landingUnit[unitID].abort = true
	end
end

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

local function UpdatePadLocations(f)
	for unitID, data in pairs(landingUnit) do
		if data.mobilePad and not data.landed then
			local px, py, pz = Spring.GetUnitPiecePosDir(data.padID, data.padPieceID)
			CircleToLand(unitID, {px,py,pz})
		end
	end
end

function gadget:GameFrame(f)
	UpdateCoroutines()
	if f%3 == 1 then
		UpdatePadLocations()
	end
end
