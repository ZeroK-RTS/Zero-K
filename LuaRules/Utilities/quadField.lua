--[[
Quadfield class
]]

local markingColor = 0

local quadFieldMethods = {}

local function Clamp(val, minVal, maxVal)
	if val <= minVal then
		return minVal
	end
	if val >= maxVal then
		return maxVal
	end
	return val
end

function quadFieldMethods:GetPos(x, z)
	return Clamp(math.floor(x / self.quadSize), 0, self.sizeX - 1), Clamp(math.floor(z / self.quadSize), 0, self.sizeZ - 1)
end

function quadFieldMethods:GetIndex(x, z)
	return Clamp(math.floor(z / self.quadSize), 0, self.sizeZ - 1) * self.sizeX + Clamp(math.floor(x / self.quadSize), 0, self.sizeX - 1) + 1
end

function quadFieldMethods:GetQuads(x, z, radius)
	if radius <= 0 then
		return nil
	end

	local minx, minz = self:GetPos(x - radius, z - radius)
	local maxx, maxz = self:GetPos(x + radius, z + radius)
	local quads = {1} -- first value is array size (number of quads + 1)

	local maxSqLength = (radius + self.quadSize * 0.72) * (radius + self.quadSize * 0.72)

	for ix = minx, maxx do
		for iz = minz, maxz do
			local dx, dz = (ix + 0.5) * self.quadSize - x, (iz + 0.5) * self.quadSize - z
			if dx * dx + dz * dz < maxSqLength then
				quads[1] = quads[1] + 1
				quads[quads[1]] = iz * self.sizeX + ix + 1
			end
		end
	end
	quads[1] = #quads

	return quads
end


function quadFieldMethods:Remove(objectID)
	local obj = self.objects[objectID]
	if not self.objects[objectID] then
		return
	end
	local quads = obj[4]

	for i = 2, quads[1] do
		local quad = self.field[quads[i]]
		for j = 2, quad[1] do
			if quad[j] == objectID then
				quad[j] = quad[quad[1]]
				quad[1] = quad[1] - 1 -- no need to delete since we keep size
				break
			end
		end
	end
	self.objects[objectID] = nil
end


function quadFieldMethods:Insert(objectID, posx, posz, radius)
	self:Remove(objectID)

	local quads = self:GetQuads(posx, posz, radius)
	for i = 2, quads[1] do
		local quad = self.field[quads[i]]
		quad[quad[1] + 1] = objectID
		quad[1] = quad[1] + 1
	end
	self.objects[objectID] = {posx, posz, radius, quads, 0}
end

function quadFieldMethods:GetNeighbors(objectID)
	local obj = self.objects[objectID]
	if not obj then
		return nil
	end
	local quads = obj[4]
	local neighbors = {1}
	local count = 1

	-- We use colouring to remove duplications
	markingColor = markingColor + 1

	for i = 2, quads[1] do
		local quad = self.field[quads[i]]
		for j = 2, quad[1] do
			local oid = quad[j]
			local obj2 = self.objects[oid]
			if oid ~= objectID and obj2[5] ~= markingColor then
				count = count + 1
				neighbors[count] = oid
				obj2[5] = markingColor
			end
		end
	end
	neighbors[1] = count

	return neighbors
end

function quadFieldMethods:GetIntersections(objectID)
	local obj = self.objects[objectID]
	if not obj then
		return nil
	end
	local posx, posz, radius = obj[1], obj[2], obj[3]
	local intersections = {1}
	local count = 1
	local neighbors = self:GetNeighbors(objectID)

	for i = 2, neighbors[1] do
		local oid = neighbors[i]
		local obj2 = self.objects[oid]
		local posx2, posz2, radius2 = obj2[1], obj2[2], obj2[3]
		local dx, dz = posx - posx2, posz - posz2
		local dist = radius + radius2
		if dx * dx + dz * dz < dist * dist then
			count = count + 1
			intersections[count] = oid
		end
	end

	intersections[1] = count

	return intersections
end

function Spring.Utilities.QuadField(quadSize)
	local qf = {
		sizeX = math.ceil(Game.mapSizeX / quadSize),
		sizeZ = math.ceil(Game.mapSizeZ / quadSize),
		quadSize = quadSize,
		field = {}, -- {{objectID, ...}, ...}
		objects = {}, -- {objectID = {posx, posz, radius}}
	}

	for k, v in pairs(quadFieldMethods) do
		qf[k] = v
	end
	--Spring.Echo("Total: " .. qf.sizeX * qf.sizeZ .. " quads")

	for i = 1, qf.sizeX * qf.sizeZ do
		qf.field[i] = {1} -- first value is array size (number of objects + 1)
	end

	return qf
end
