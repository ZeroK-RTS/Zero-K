local Rect = {}
Rect.__index = Rect

function Rect.new(_x, _y, _width, _height)
    local instance = {
        x = _x,
        y = _y,
        width = _width,
        height = _height
    }
    setmetatable(instance, Rect)
    return instance
end

function Rect:HasPoint(x, y)
    local x2, y2 = self:GetBottomRightPoint()
    return x >= self.x and x <= x2 and y >= self.y and y <= y2
end

function Rect:Intersects(rect)
    return not (
        rect.x - rect.width  > self.x + self.width or
        rect.x + rect.width  < self.x - self.width or
        rect.y - rect.height > self.y + self.height or
        rect.y + rect.height < self.y - self.height
    )
end

function Rect:GetBottomRightPoint()
    return self.x + self.width, self.y + self.height
end

function Rect:Draw(gl)
    gl.DrawGroundQuad(self.x, self.y, self.x + self.width, self.y + self.height)
end

return Rect
