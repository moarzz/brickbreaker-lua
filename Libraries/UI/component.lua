-- base component object for components
-- this is used as a parent for a new component to be interfaced with for the component handler

local path = string.match((...), ".+[./]") or "";

local BoundingBox = require(path .. "boundingBox");

local Component = {};
Component.__index = Component;

--Component.labelFont = love.graphics.newFont("SpaceMono.ttf", 10);

function Component.new()
    local instance = setmetatable({}, Component);

    instance.boundingBoxes = {}; -- list of all the bounding boxes
    instance.triggers = {}; -- table of pairs of [callback key] = component to check for trigger
    --* the component given as the pair in the triggers table should be a new component
    --* if it is already in the component handler then bugs can form

    instance.isHovering = false;

    instance.lightVisible = false; -- whether or not to make it dissapear when its a background item

    --//instance.label = "this is a label";
    --//instance.staticHovering = false;
    --//instance.staticHoveringTimer = 0;

    return instance;
end

function Component:setLightVisible(vis)
    self.lightVisible = vis;
end

function Component:setLabel(newLabel)
    self._label = newLabel;
end

function Component:addTrigger(pointer, callbackKey)
    self.triggers[callbackKey] = pointer;

    --//for i, v in ipairs(pointer.boundingBoxes) do
    --//    self:addBoundingBox(v);
    --//end

    return pointer;
end

-- x, y, w, h are optional arguments (thats why they have an underscore and overlap the pointer argument since you acn only have one)
function Component:addBoundingBox(pointer_x, _y, _w, _h)
    -- check if we need to make a new bounding box or are given a pointer
    if type(pointer_x) == "number" then
        local bound = BoundingBox.new(pointer_x, _y, _w, _h);

        table.insert(self.boundingBoxes, bound);

        return bound;
    end

    table.insert(self.boundingBoxes, pointer_x);

    return pointer_x;
end

-- pretty much useless, but it makes setting isHovering more visually dense in other scripts
function Component:setIsHovering(setTo)
    self.isHovering = setTo;
end

function Component:isInAnyBoundingBox(x, y)
    for i, v in ipairs(self.boundingBoxes) do
        if v:isPointInside(x, y) then
            return true;
        end
    end

    return false;
end

function Component:tick(dt)
    if self.update then
        self:update(dt);
    end
end

-- returns a function that when called will draw all of this components bounding boxes with an additional pixel on each side
function Component:getOuterDrawFunc()
    -- love2d expects a callable for the stencil function so one must be created every draw (a little inneficient but worth)
    return function()
        for i, v in ipairs(self.boundingBoxes) do
            love.graphics.rectangle("fill", v.x - 1, v.y - 1, v.w + 2, v.h + 2);
        end
    end
end

-- returns a function that when called will draw all of this components bounding boxes
function Component:getInnerDrawFunc()
    -- love2d expects a callable for the stencil function so one must be created every draw (a little inneficient but worth)
    return function()
        for i, v in ipairs(self.boundingBoxes) do
            love.graphics.rectangle("fill", v.x, v.y, v.w, v.h);
        end
    end
end

function Component:drawOutline()
    love.graphics.setCanvas({stencil = true}); -- make sure you can use the stencils

    love.graphics.setColor(0,0,0,0.4); -- black, slightly transparent

    -- draw all bounding boxes 1 pixel thicker for the stencil buffer
    love.graphics.stencil(self:getOuterDrawFunc(), "replace", 1, false); -- final arg false to set all values in the buffer to 0 first
    love.graphics.stencil(self:getInnerDrawFunc(), "replace", 0, true);  -- final arg true to keep all values set from the previous line
    -- remove all bounding boxes (but not the extra pixel) from the stencil buffer

    love.graphics.setStencilTest("equal", 1);

    -- draw a rectangle over the entire screen, but only the outline of the bounding boxes shows because of the stencil buffer
    love.graphics.rectangle("fill", 0,0, 1920,1080);

    love.graphics.setStencilTest();
    love.graphics.setCanvas();
end

return Component;