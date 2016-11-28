
function widget:GetInfo()
  return {
    name      = "Specific Thing Reclaimer",
    desc      = "Reclaims targeted unit types in an area",
    author    = "Google Frog",
    date      = "May 12, 2008",
    license   = "GNU GPL, v2 or later",
    layer     = 0,
    enabled   = true  --  loaded by default?
  }
end

-- Speedups

local spGiveOrderToUnit = Spring.GiveOrderToUnit
local spGiveOrderToUnitArray = Spring.GiveOrderToUnitArray
local spGetSelectedUnits = Spring.GetSelectedUnits
local spGetUnitsInCylinder = Spring.GetUnitsInCylinder
local spWorldToScreenCoords = Spring.WorldToScreenCoords
local spTraceScreenRay = Spring.TraceScreenRay
local spGetUnitDefID = Spring.GetUnitDefID
local spGetUnitAllyTeam = Spring.GetUnitAllyTeam

local reclaimEnemy = Game.reclaimAllowEnemies

function widget:CommandNotify(cmdID, params, options)

	if not options.ctrl or (cmdID ~= 90) or (#params ~= 4) then
		return
	end

	local cx, cy, cz = params[1], params[2], params[3]
	local mx,my = spWorldToScreenCoords(cx, cy, cz)
	local cType, targetID = spTraceScreenRay(mx,my)

	if (cType == "unit") then

		local selUnits = spGetSelectedUnits()
		if not options.shift then
			for i, sid in ipairs(selUnits) do 
				spGiveOrderToUnit(sid, CMD.STOP, {}, CMD.OPT_RIGHT)
			end
		end

		local cr = params[4]
		local allyTeam = Spring.GetMyAllyTeamID()

		if reclaimEnemy and spGetUnitAllyTeam(targetID) ~= allyTeam then
			local areaUnits = spGetUnitsInCylinder(cx, cz, cr)
			for i, aid in ipairs(areaUnits) do 
				if spGetUnitAllyTeam(aid) ~= allyTeam then
					spGiveOrderToUnitArray(selUnits, CMD.RECLAIM, {aid}, CMD.OPT_SHIFT)
				end
			end
		else
			local team = Spring.GetMyTeamID()
			local areaUnits = spGetUnitsInCylinder(cx, cz, cr, team)
			local unitDefID = spGetUnitDefID(targetID)
			for i, aid in ipairs(areaUnits) do
				if spGetUnitDefID(aid) == unitDefID then
					spGiveOrderToUnitArray(selUnits, CMD.RECLAIM, {aid}, CMD.OPT_SHIFT)
				end
			end
		end
		return true
	elseif (cType == "feature") then
		local featureDefID = Spring.GetFeatureDefID(targetID)
		if FeatureDefs[featureDefID].metal > 0 then
			return
		end

		local selUnits = spGetSelectedUnits()
		if not options.shift then
			for i, sid in ipairs(selUnits) do 
				spGiveOrderToUnit(sid, CMD.STOP, {}, CMD.OPT_RIGHT)
			end
		end

		local cr = params[4]
		local potentialTrees = Spring.GetFeaturesInCylinder(cx, cz, cr)
		local trees = {}
		for i = 1, #potentialTrees do
			local featureID = potentialTrees[i]
			if FeatureDefs[Spring.GetFeatureDefID(featureID)].metal == 0 then
				trees[#trees+1] = featureID
			end
		end
		while #trees > 0 do
			local minDist = cr*cr + 1
			local bestID = 0
			for i = 1, #trees do
				local x, y, z = Spring.GetFeaturePosition(trees[i])
				local dist = (x-cx)*(x-cx) + (z-cz)*(z-cz)
				if dist < minDist then
					minDist = dist
					bestID = i
				end
			end
			local featureID = trees[bestID]
			spGiveOrderToUnitArray(selUnits, CMD.RECLAIM, {featureID + Game.maxUnits}, CMD.OPT_SHIFT)
			cx, cy, cz = Spring.GetFeaturePosition(featureID)
			trees[bestID] = trees[#trees]
			trees[#trees] = nil
		end
		return true
	end
end
