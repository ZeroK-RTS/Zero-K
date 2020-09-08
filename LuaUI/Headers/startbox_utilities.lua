VFS.Include("LuaRules/Utilities/numberfunctions.lua") -- math.triangulate
local GRP = Spring.GetGameRulesParam

local function GetRawBoxes()
	local ret = {}

	local boxCount = GRP("startbox_max_n")
	if not boxCount then
		return ret
	end

	for boxID = 0, boxCount do
		local polies = {}
		local polyCount = GRP("startbox_n_" .. boxID)
		if polyCount then
			for polyID = 1, polyCount do
				local poly = {}
				local vertexCount = GRP("startbox_polygon_" .. boxID .. "_" .. polyID)
				for vertexID = 1, vertexCount do
					local vertex = {}
					vertex[1] = GRP("startbox_polygon_x_" .. boxID .. "_" .. polyID .. "_" .. vertexID)
					vertex[2] = GRP("startbox_polygon_z_" .. boxID .. "_" .. polyID .. "_" .. vertexID)
					poly[vertexID] = vertex
				end
				polies[polyID] = poly
			end
		end

		local startpoints = {}
		local posCount = GRP("startpos_n_" .. boxID)
		if posCount then
			startpoints = {}
			for posID = 1, posCount do
				local pos = {}
				pos[1] = GRP("startpos_x_" .. boxID .. "_" .. posID)
				pos[2] = GRP("startpos_z_" .. boxID .. "_" .. posID)
				startpoints[posID] = pos
			end
		end

		if posCount or polyCount then
			ret[boxID] = {
				boxes = polies,
				startpoints = startpoints
			}
		end
	end

	return ret
end

local function GetTriangulatedBoxes()
	local boxes = GetRawBoxes()
	for boxID, box in pairs(boxes) do
		box.boxes = math.triangulate(box.boxes)
	end
	return boxes
end

local function GetAllyTeamOctant(allyTeamID)
	-- Counterclockwise 1 to 8 starting from North-East-East
	-- Octants are open on their trailing edge and closed on their leading edge.
	-- Eg, the line between 1 and 2 belongs to 1.
	if not allyTeamID then
		return false
	end
	local teamX = Spring.GetGameRulesParam("allyteam_origin_x_" .. allyTeamID)
	local teamZ = Spring.GetGameRulesParam("allyteam_origin_z_" .. allyTeamID)
	if not (teamX and teamZ) then
		return false
	end
	local mapX, mapZ = Game.mapSizeX, Game.mapSizeZ
	local posX, posZ = teamX/mapX, teamZ/mapZ
	
	-- Do some ad hoc nonsense.
	if posX > posZ then
		-- Top right
		if posX < 0.5 then
			return 3
		elseif posZ >= 0.5 then
			return 8
		elseif posX + posZ < 1 then
			return 2
		else
			return 1
		end
	elseif posX == posZ then
		if posX < 0.5 then
			return 3
		else
			return 7
		end
	else
		-- Bottom left
		if posZ <= 0.5 then
			return 4
		elseif posX > 0.5 then
			return 7
		elseif posX + posZ <= 1 then
			return 5
		else
			return 6
		end
	end
end

return GetRawBoxes, GetTriangulatedBoxes, GetAllyTeamOctant
