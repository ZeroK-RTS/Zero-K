-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------

local mapWidth = Game.mapSizeX
local mapHeight = Game.mapSizeZ
local spGiveOrderToUnit = Spring.GiveOrderToUnit
local spGetGroundHeight = Spring.GetGroundHeight
local CMD_INSERT = CMD.INSERT

function Spring.Utilities.IsValidPosition(x, z)
	return x and z and x >= 1 and z >= 1 and x <= mapWidth-1 and z <= mapHeight-1
end

function Spring.Utilities.ClampPosition(x, z)
	if x and z then
		if Spring.Utilities.IsValidPosition(x, z) then
			return x, z
		else
			if x < 1 then
				x = 1
			elseif x > mapWidth-1 then
				x = mapWidth-1
			end
			if z < 1 then
				z = 1
			elseif z > mapHeight-1 then
				z = mapHeight-1
			end
			return x, z
		end
	end
	return 0, 0
end

function Spring.Utilities.GiveClampedOrderToUnit(unitID, cmdID, params, options, doNotGiveOffMap)
	if doNotGiveOffMap and not Spring.Utilities.IsValidPosition(params[1], params[3]) then
		return false
	end
	if cmdID == CMD_INSERT then
		local x, z = Spring.Utilities.ClampPosition(params[4], params[6])
		spGiveOrderToUnit(unitID, cmdID, {params[1], params[2], params[3], x, params[5], z}, options)
		return x, params[5], z
	end
	local x, z = Spring.Utilities.ClampPosition(params[1], params[3])
	spGiveOrderToUnit(unitID, cmdID, {x, params[2], z}, options)
	return x, params[2], z
end

function Spring.Utilities.GiveClampedMoveGoalToUnit(unitID, x, z, speed, raw)
	x, z = Spring.Utilities.ClampPosition(x, z)
	local y = spGetGroundHeight(x,z)
	Spring.SetUnitMoveGoal(unitID, x, y, z, 16, speed, raw) -- The last argument is whether the goal is raw
	return true
end

function Spring.Utilities.GetGroundHeightMinusOffmap(x, z)
	local maxOff = 0
	if x < 0 then
		maxOff = -x
	elseif x > mapWidth then
		maxOff = x - mapWidth
	end
	if z < -maxOff then
		maxOff = -z
	elseif z > mapHeight + maxOff then
		maxOff = z - mapWidth
	end
	return Spring.GetGroundHeight(x, z) - maxOff
end

