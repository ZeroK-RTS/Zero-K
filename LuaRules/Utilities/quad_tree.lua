local Rect = VFS.Include("LuaRules/Utilities/rect.lua")

local QuadTree = {}
QuadTree.__index = QuadTree

function QuadTree.new(x, y, width, height)
    local instance = {
        rect = Rect.new(x, y, width, height),
        point = nil,
        data = nil,
        isSubdivided = false;
    }
    setmetatable(instance, QuadTree)
    return instance
end

function QuadTree:Insert(x, y, data)
    if not self.rect:HasPoint(x, y) then
        return false
    end

    if self.isSubdivided then
        return self:_ForceInsert(x, y, data)
    end

    if self.point then
        if self.point[1] == x and self.point[2] == y then
            return false
        end
        self:_Subdivide()
        self:_ForceInsert(x, y, data)
    else
        self.point = {x, y}
        self.data = data
    end

    return true
end

function QuadTree:Remove(x, y, data)
    if not self.rect:HasPoint(x, y) then
        return false
    end

    if (self.isSubdivided) then
        local removed = self:_ForceRemove(x, y)
        if removed and self.topLeft:IsEmpty() and self.topRight:IsEmpty() and self.bottomLeft:IsEmpty() and self.bottomRight:IsEmpty() then
            self.topLeft = nil
            self.topRight = nil
            self.bottomLeft = nil
            self.bottomRight = nil
            self.isSubdivided = false
            return true
        end
    elseif self.point and self.point[1] == x and self.point[2] == y and (data == nil or self.data == data) then
        self.point = nil
        self.data = nil
        return true
    end

    return false
end

function QuadTree:QueryCircle(x, y, radius)
    return self:_Query(Rect.new(x - radius, y - radius, radius * 2, radius * 2))
end

function QuadTree:QueryRect(x, y, width, height)
    return self:_Query(Rect.new(x, y, width, height))
end

function QuadTree:_Query(rect, found)
    if self.rect:Intersects(rect) then
        if not found then
            found = {}
        end
        if self.isSubdivided then
            self.topLeft:_Query(rect, found)
            self.topRight:_Query(rect, found)
            self.bottomLeft:_Query(rect, found)
            self.bottomRight:_Query(rect, found)
        elseif self.data and rect:HasPoint(self.point[1], self.point[2]) then
            found[#found+1] = self.data
        end
    else
        return found
    end

    return found
end

function QuadTree:IsEmpty()
    return self.isSubdivided == false and self.point == nil
end

function QuadTree:Draw(gl)
    if self.isSubdivided then
        self.topLeft:Draw(gl)
        self.topRight:Draw(gl)
        self.bottomLeft:Draw(gl)
        self.bottomRight:Draw(gl)
    elseif self.point then
        self.rect:Draw(gl)
    end
end

function QuadTree:_Subdivide()
    local x = self.rect.x
    local y = self.rect.y
    local width = self.rect.width / 2
    local height = self.rect.height / 2
    self.topLeft =     QuadTree.new(x,         y,          width, height)
    self.topRight =    QuadTree.new(x + width, y,          width, height)
    self.bottomLeft =  QuadTree.new(x + width, y + height, width, height)
    self.bottomRight = QuadTree.new(x,         y + height, width, height)
    self:_ForceInsert(self.point[1], self.point[2], self.data)
    self.point = nil
    self.data = nil
    self.isSubdivided = true
end

function QuadTree:_ForceInsert(x, y, data)
    if self.topLeft:Insert(x, y, data) then
        return true
    end
    if self.topRight:Insert(x, y, data) then
        return true
    end
    if self.bottomLeft:Insert(x, y, data) then
        return true
    end
    if self.bottomRight:Insert(x, y, data) then
        return true
    end
    return false
end

function QuadTree:_ForceRemove(x, y)
    if self.topLeft:Remove(x, y) then
        return true
    end
    if self.topRight:Remove(x, y) then
        return true
    end
    if self.bottomLeft:Remove(x, y) then
        return true
    end
    if self.bottomRight:Remove(x, y) then
        return true
    end
    return false
end

return QuadTree
