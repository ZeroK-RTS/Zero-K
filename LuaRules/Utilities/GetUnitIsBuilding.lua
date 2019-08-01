-- $Id:$
-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
--
-- Author: jK @2010
-- License: GPLv2 and later
--
-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------

local CachedBuildDistance = {}

local function IsFeatureInRange(unitID, featureID, range)
	range = range + 100 -- fudge factor
	local x,y,z = Spring.GetFeaturePosition(featureID)
	local ux,uy,uz = Spring.GetUnitPosition(unitID)
	return ((ux - x)^2 + (uz - z)^2) <= range^2
end

local function IsGroundPosInRange(unitID, x, z, range)
	local ux,uy,uz = Spring.GetUnitPosition(unitID)
	return ((ux - x)^2 + (uz - z)^2) <= range^2
end

function Spring.Utilities.GetUnitNanoTarget(unitID)
	local type = ""
	local target
	local isFeature = false
	local inRange

	local buildID = Spring.GetUnitIsBuilding(unitID)
	if (buildID) then
		target = buildID
		type   = "building"
		inRange = true
	else
		local unitDefID = Spring.GetUnitDefID(unitID)
		if not unitDefID then
			return
		end
		if not CachedBuildDistance[unitDefID] then
			local unitDef = UnitDefs[unitDefID] or {}
			CachedBuildDistance[unitDefID] = unitDef.buildDistance or 0
		end
		local buildRange = CachedBuildDistance[unitDefID]
		
		local cmdID, cp_1, cp_2, cp_3, cp_4, cp_5, cp_6
		if Spring.Utilities.COMPAT_GET_ORDER then
			local queue = Spring.GetCommandQueue(unitID, 1)
			if queue and queue[1] then
				local par = queue[1].params
				cmdID, cp_1, cp_2, cp_3, cp_4, cp_5, cp_6 = queue[1].id, par[1], par[2], par[3], par[4], par[5], par[6]
			end
		else
			cmdID, _, _, cp_1, cp_2, cp_3, cp_4, cp_5, cp_6 = Spring.GetUnitCurrentCommand(unitID)
		end
		
		if cmdID then
			if cmdID == CMD.RECLAIM then
				--// anything except "#cmdParams = 1 or 5" is either invalid or discribes an area reclaim
				if (not cp_2) or (cp_5) then
					local id = cp_1
					local unitID_ = id
					local featureID = id - Game.maxUnits

					if (featureID >= 0) then
						if Spring.ValidFeatureID(featureID) then
							target    = featureID
							isFeature = true
							type      = "reclaim"
							inRange	= IsFeatureInRange(unitID, featureID, buildRange)
						end
					else
						if Spring.ValidUnitID(unitID_) then
							target = unitID_
							type   = "reclaim"
							inRange = Spring.GetUnitSeparation(unitID, unitID_, true) <= buildRange
						end
					end
				end

			elseif cmdID == CMD.REPAIR  then
				local repairID = cp_1
				if Spring.ValidUnitID(repairID) then
					target = repairID
					type   = "repair"
					inRange = Spring.GetUnitSeparation(unitID, repairID, true) <= buildRange
				end

			elseif cmdID == CMD.RESTORE then
				local x = cp_1
				local z = cp_3
				type   = "restore"
				target = {x, GetGroundHeight(x,z)+5, z, cp_4}
				inRange = IsGroundPosInRange(unitID, x, z, buildRange)

			elseif cmdID == CMD.CAPTURE then
				if (not cp_2) or (cp_5) then
					local captureID = cp_1
					if Spring.ValidUnitID(captureID) then
						target = captureID
						type   = "capture"
						inRange = Spring.GetUnitSeparation(unitID, captureID, true) <= buildRange
					end
				end

			elseif cmdID == CMD.RESURRECT then
				local rezzID = cp_1 - Game.maxUnits
				if Spring.ValidFeatureID(rezzID) then
					target    = rezzID
					isFeature = true
					type      = "resurrect"
					inRange	= IsFeatureInRange(unitID, rezzID, buildRange)
				end
			end
		end
	end

	if inRange then
		return type, target, isFeature
	else
		return
	end
end
