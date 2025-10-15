-- script for axis-aligned bounding-boxes (AABB)
-- wrapped as an object for type standardization

local BoundingBox = {};
BoundingBox.__index = BoundingBox;

function BoundingBox.new(x, y, w, h)
    local instance = setmetatable({}, BoundingBox);

    instance.x = x;
    instance.y = y;

    instance.w = w;
    instance.h = h;

    return instance;
end

-- returns true if given point is inside of; or tangential to top or left edge (but not right or bottom edge)
function BoundingBox:isPointInside(x, y)
    if x < self.x or y < self.y then
        return false;
    end

    if x >= self.x + self.w or y >= self.y + self.h then
        return false;
    end

    return true;
end

-- return a point's position in relation to the top left corner of the bounding box
function BoundingBox:getRelativePosition(x, y)
    return x - self.x, y - self.y;
end

function BoundingBox:setPosition(x, y)
    self.x = x;
    self.y = y;
end

function BoundingBox:setDimmensions(w, h)
    self.w = w or self.w;
    self.h = h or self.h;
end

-- moslty used for shaders and stuff, to get the bounding box of the ui element
function BoundingBox:draw()
    love.graphics.rectangle("fill", self.x, self.y, self.w, self.h);
end

return BoundingBox;