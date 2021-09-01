local Rect = {}
Rect.__index = Rect

function Rect.New(x, y, width, height)
    local instance = {
        x = x,
        y = y,
        width = width,
        height = height
    }
    setmetatable(instance, Rect)
    return instance
end

function Rect:HasPoint(x, y)
    local x2, y2 = self.x + self.width, self.y + self.height
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

return Rect
