
-- luacheck: read globals WG
-- provides: read globals UpdateOneWorkerPathing UpdateOneJobPathing CleanPathing

-- Global Build Command/Pathfinding: Responsible keeping track of which units
-- can reach which jobs and vice versa.
-- Gives a lot of false positives: Spring.RequestPath currently seems overly
-- generous, and will often provide a path if it thinks the unit can get
-- closer without necessarily being able to reach the target.
-- XXX: State is currently still tightly coupled with core GBC state.

local Echo               = Spring.Echo
local spGetUnitDefID     = Spring.GetUnitDefID
local spGetUnitPosition  = Spring.GetUnitPosition
local spIsUnitAllied     = Spring.IsUnitAllied
local spValidUnitID      = Spring.ValidUnitID
local spUnitIsDead       = Spring.GetUnitIsDead
local spRequestPath      = Spring.RequestPath

local CMD_REPAIR         = CMD.REPAIR
local CMD_RECLAIM        = CMD.RECLAIM

local abs                = math.abs
local sqrt               = math.sqrt

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Helper Functions ------------------------------------------------------------
--[[
HOW THIS WORKS:
	-- EXTERNAL API --
	UpdateOneWorkerPathing()
		Caches pathing info for one worker for every job in buildQueue. This is called
		whenever a new unit enters our group, and adds the hash of any job that cannot be reached
		and/or performed to 'includedBuilders[unitID].unreachable'. Does not do anything for commands targetting
		units (ie repair, reclaim), since they may move and invalidate cached pathing info.
	UpdateOneJobPathing()
		Caches pathing info for one job for every worker in includedBuilders. This is called whenever a new
		job is added to the queue, and does basically the same thing as UpdateOneWorkerPathing().
	CleanPathing()
		Performs garbage collection for unreachable caches, removing jobs that are no longer on the queue.
	-- INTERNAL FUNCTIONS --
	CanBuildThis()
		Determines whether a given worker can perform a given job or not.
	IsTargetReachable()
		Checks pathing between a unit and destination, to determine if a worker
		can reach a given build site.
--]]

--This function tells us if a unit can perform the job in question.
local function CanBuildThis(cmdID, unitID)
	local unitDefID = spGetUnitDefID(unitID)
	local unitDef = UnitDefs[unitDefID]
	if cmdID < 0 then -- for build jobs
		local bcmd = -cmdID -- invert the command ID to get the unitDefID that it refers to
		local bo = unitDef.buildOptions
		for i = 1, #bo do
			if bo[i] == bcmd then
				return true
			end
		end
		return false
	elseif cmdID == CMD_REPAIR or cmdID == CMD_RECLAIM then -- for repair and reclaim, all builders can do this, return true
		return true
	elseif unitDef.canResurrect then -- for ressurect
		return true
	end
	return false
end

-- This function process result of Spring.PathRequest() to say whether target is reachable or not
local function IsTargetReachable(unitID, tx,ty,tz)
	local ox, oy, oz = spGetUnitPosition(unitID)  -- unit location
	local unitDefID = spGetUnitDefID(unitID)
	local buildDist = UnitDefs[unitDefID].buildDistance -- build range
	local moveID = UnitDefs[unitDefID].moveDef.id -- unit pathing type
	if not moveID then -- air units have no moveID, and we don't need to calculate pathing for them.
		return true --for air units; always reachable
	end

	local path = spRequestPath( moveID,ox,oy,oz,tx,ty,tz, 10)
	if not path then
		return true -- if path is nil for some reason, return true
		-- note: it usually returns nil for very short distances, which is why returning true is a much better default here
	end
	local waypoints = path:GetPathWayPoints()
	local finalCoord = waypoints[#waypoints]
	if not finalCoord then -- unknown why sometimes NIL
		return true -- if finalCoord is nil for some reason, return true
	end
	local dx, dz = finalCoord[1]-tx, finalCoord[3]-tz
	local dist = sqrt(dx*dx + dz*dz)
	if dist < buildDist + 40 then -- is within radius?
		return true -- within reach
	else
		return false -- not within reach
	end
end

-- This function caches pathing when a new worker enters the group.
function UpdateOneWorkerPathing(unitID, includedBuilders, buildQueue)
	for hash, cmd in pairs(buildQueue) do -- check pathing vs each job in the queue, mark any that can't be reached
		local jx, jy, jz = 0
		-- get job position
		if cmd.x or cmd.id == CMD_REPAIR then -- for all jobs not targetting units (ie not repair or unit reclaim)
			local valid = true
			if cmd.x then
				jx, jy, jz = cmd.x, cmd.y, cmd.z --the location of the current job
			elseif spValidUnitID(cmd.target) and spIsUnitAllied(cmd.target) and not spUnitIsDead(cmd.target) then -- for repair jobs, only cache pathing for buildings, since they don't move.
				jx, jy, jz = spGetUnitPosition(cmd.target)
				if not UnitDefs[spGetUnitDefID(cmd.target)].isImmobile then
					valid = false
				end
			else
				valid = false
			end

			if valid and not IsTargetReachable(unitID, jx, jy, jz) or not CanBuildThis(cmd.id, unitID) then -- if the worker can't reach the job, or can't build it, add it to the worker's unreachable list
				includedBuilders[unitID].unreachable[hash] = true
			end
		end
	end
end

-- This function caches pathing when a new job is added to the queue
function UpdateOneJobPathing(hash, includedBuilders, buildQueue)
	local cmd = buildQueue[hash]
	local jx, jy, jz
	-- get job position
	if cmd.x or cmd.id == CMD_REPAIR then -- for build jobs, and non-repair jobs that we cache the coords and pathing for
		local valid = true
		if cmd.x then
			jx, jy, jz = cmd.x, cmd.y, cmd.z --the location of the current job
		else
			jx, jy, jz = spGetUnitPosition(cmd.target)
			if not UnitDefs[spGetUnitDefID(cmd.target)].isImmobile then
				valid = false
			end
		end

		if not valid then return end -- don't check pathing for repair jobs targeting mobiles.

		for unitID, _ in pairs(includedBuilders) do -- check pathing for each unit, mark any that can't be reached.
			if spValidUnitID(unitID) then -- note that this function can be called before validity checks are run, and some of our units may have died.
				if not IsTargetReachable(unitID, jx, jy, jz) or not CanBuildThis(cmd.id, unitID) then -- if the worker can't reach the job, or can't build it, add it to the worker's unreachable list
					includedBuilders[unitID].unreachable[hash] = true
				end
			end
		end
	end
end

-- This function performs garbage collection for cached pathing
function CleanPathing(unitID, includedBuilders, buildQueue)
	for hash,_ in pairs(includedBuilders[unitID].unreachable) do
		if not buildQueue[hash] then -- remove old, invalid jobs from the unreachable list
			includedBuilders[unitID].unreachable[hash] = nil
		end
	end
end
