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

return GetRawBoxes, GetTriangulatedBoxes
