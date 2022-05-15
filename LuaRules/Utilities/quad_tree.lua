local Rect = VFS.Include("LuaRules/Utilities/rect.lua")

local QuadTree = {}
QuadTree.__index = QuadTree

function QuadTree.New(x, y, width, height, capacity, maxDepth, depth)
	local instance = {
		data = {},
		dataCount = 0,
		capacity = capacity,
		depth = depth or 0,
		maxDepth = maxDepth,
		isSubdivided = false,
		rect = Rect.New(x, y, width, height)
	}
	setmetatable(instance, QuadTree)
	return instance
end

function QuadTree:Insert(x, y, data)
	if self.rect:HasPoint(x, y) then
		self:insert(x, y, data)
	end
end

function QuadTree:Remove(x, y, data)
	if self.rect:HasPoint(x, y) then
		self:remove(x, y, data)
	end
end

function QuadTree:Query(x, y, radius)
	local found = {}
	local count = self:query(Rect.New(x - radius, y - radius, radius * 2, radius * 2), found, 0)
	return found, count
end

function QuadTree:insert(x, y, data)
	if self.dataCount < self.capacity or self.depth >= self.maxDepth then
		self.data[data] = {x, y}
		self.dataCount = self.dataCount + 1
	elseif self.isSubdivided then
		self:getPointSubNode(x, y):insert(x, y, data)
	else
		self:subdivide()
		self:getPointSubNode(x, y):insert(x, y, data)
	end
end

function QuadTree:remove(x, y, data)
	if self.data[data] then
		self.data[data] = nil
		self.dataCount = self.dataCount - 1
	elseif self.isSubdivided then
		self:getPointSubNode(x, y):remove(x, y, data)
		if self:areChildrenEmpty() then
			self.topLeft = nil
			self.topRight = nil
			self.bottomLeft = nil
			self.bottomRight = nil
			self.isSubdivided = false
		end
	end
end

function QuadTree:query(rect, found, count)
	for data, point in pairs(self.data) do
		if rect:HasPoint(point[1], point[2]) then
			count = count + 1
			found[count] = data
		end
	end

	if self.isSubdivided and self.rect:Intersects(rect) then
		count = self.topLeft:query(rect, found, count)
		count = self.topRight:query(rect, found, count)
		count = self.bottomLeft:query(rect, found, count)
		count = self.bottomRight:query(rect, found, count)
	end
	return count
end

function QuadTree:areChildrenEmpty()
	return self.topLeft:isEmpty() and self.topRight:isEmpty() and self.bottomLeft:isEmpty() and self.bottomRight:isEmpty()
end

function QuadTree:isEmpty()
	return self.isSubdivided == false and self.dataCount == 0
end

function QuadTree:subdivide()
	local x = self.rect.x
	local y = self.rect.y
	local width = self.rect.width * 0.5
	local height = self.rect.height * 0.5
	self.topLeft = QuadTree.New(x, y, width, height, self.capacity, self.maxDepth, self.depth + 1)
	self.topRight = QuadTree.New(x + width, y, width, height, self.capacity, self.maxDepth,  self.depth + 1)
	self.bottomLeft = QuadTree.New(x, y + height, width, height, self.capacity, self.maxDepth,  self.depth + 1)
	self.bottomRight = QuadTree.New(x + width, y + height, width, height, self.capacity, self.maxDepth,  self.depth + 1)
	self.isSubdivided = true
end

function QuadTree:getPointSubNode(x, y)
	local cX = self.rect.x + self.rect.width * 0.5
	local cY = self.rect.y + self.rect.height * 0.5
	if x < cX then
		if y < cY then
			return self.topLeft
		end
		return self.bottomLeft
	else
		if y < cY then
			return self.topRight
		end
		return self.bottomRight
	end
end

return QuadTree