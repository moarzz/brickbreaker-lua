local path = string.match((...), "(.+[./]).-[./]") or "";

local Piechart = Component.new();
Piechart.__index = Piechart;

Piechart.defaultColours = {
    {1,0,0}; -- red
    {0,1,0}; -- green
    {0,0,1}; -- blue
    {0,1,1}; -- cyan
    {1,0,1}; -- magenta
    {1,1,0}; -- yellow
    {1,0.5,0}; -- orange
    {0.5,0,1}; -- purple
    {1,0.5,0.5}; -- light red
    {0.5,1,0.5}; -- light green
    {0.5,0.5,1}; -- light blue
    {0.5,0,0}; -- dark red
    {0,0.5,0}; -- dark green
    {0,0,0.5}; -- dark blue
    {1,1,1}; -- white
    {0,0,0}; -- black
    {0.5,0.5,0.5}; -- gray
};
Piechart.segmentsPerCircle = 256; -- arbitrary number
--Piechart.font = love.graphics.newFont("SpaceMono.ttf", 128);

function Piechart.new(x, y, w, h, peruns)
    local instance = setmetatable(Component.new(), Piechart);

    instance.values = {};
    instance.per = 0;

    instance.x = x;
    instance.y = y;
    instance.w = w;
    instance.h = h;

    local i = 0;
    for k, v in pairs(peruns) do
        i = i + 1;
        instance.values[i] = {name = k, value = v};
        instance.per = instance.per + v;
    end

    return instance;
end

function Piechart:setValue(name, value)
    self.per = 0;

    for i, v in ipairs(self.values) do
        if v.name == name then
            v.value = value;
        end

        self.per = self.per + v.value
    end
end

function Piechart:addValue(name, value)
    self.per = self.per + value;

    table.insert(self.values, {name = name, value = value});
end

function Piechart:draw()
    local centerX = self.x + self.w / 2;
    local centerY = self.y + self.h / 2;

    local minDim = math.min(self.w, self.h) / 2;

    local textScale = 20 / PIXEL_FONT_HEIGHT;
    love.graphics.setFont(PIXEL_FONT_128);

    love.graphics.setCanvas({stencil = true});

    local stencilFunc = function()
        love.graphics.circle("fill", centerX, centerY, minDim);
    end

    love.graphics.stencil(stencilFunc, "replace", 1, false);
    love.graphics.setStencilTest("equal", 1);

    local curRot = -math.pi / 2;
    for i, v in ipairs(self.values) do
        local nextRot = curRot + math.pi * 2 * v.value / self.per;
        love.graphics.setColor(self.defaultColours[(i - 1) % #self.defaultColours + 1]);

        if nextRot - curRot < math.pi then
            local dist = minDim / math.cos((nextRot - curRot) / 2);

            love.graphics.polygon("fill",
                centerX, centerY,
                centerX + math.cos(curRot) * dist, centerY + math.sin(curRot) * dist,
                centerX + math.cos(nextRot) * dist, centerY + math.sin(nextRot) * dist
            );
        elseif nextRot - curRot >= math.pi * 2 then
            love.graphics.rectangle("fill", self.x, self.y, self.w, self.h);
        else
            local dist = minDim / math.cos((nextRot - curRot) / 4);

            love.graphics.polygon("fill",
                centerX, centerY,
                centerX + math.cos(curRot) * dist, centerY + math.sin(curRot) * dist,
                centerX + math.cos(curRot + (nextRot - curRot) / 2) * dist, centerY + math.sin(curRot + (nextRot - curRot) / 2) * dist
            );
            love.graphics.polygon("fill",
                centerX, centerY,
                centerX + math.cos(curRot + (nextRot - curRot) / 2) * dist, centerY + math.sin(curRot + (nextRot - curRot) / 2) * dist,
                centerX + math.cos(nextRot) * dist, centerY + math.sin(nextRot) * dist
            );
        end

        curRot = nextRot;
    end

    love.graphics.setStencilTest();

    local curRot = -math.pi / 2;
    for i, v in ipairs(self.values) do
        local halfAngle = curRot + math.pi * 2 * v.value / self.per / 2;
        local cosHalfAngle = math.cos(halfAngle);
        local sinHalfAngle = math.sin(halfAngle);

        local innerX = centerX + cosHalfAngle * minDim;
        local innerY = centerY + sinHalfAngle * minDim;
        local outerX = centerX + cosHalfAngle * (minDim + 40);
        local outerY = centerY + sinHalfAngle * (minDim + 40);
        local xDir = outerX - innerX;

        if xDir == 0 then
            xDir = 1;
        else
            xDir = xDir / math.abs(xDir);
        end

        local valueDisplay = v.name .. " " .. tostring(math.floor(v.value / self.per * 100)) .. "%";

        love.graphics.setColor(1,1,1); -- white
        love.graphics.line(innerX, innerY, outerX, outerY);
        love.graphics.line(outerX, outerY, outerX + PIXEL_FONT_128:getWidth(valueDisplay) * textScale * xDir, outerY);
        love.graphics.print(valueDisplay, outerX + PIXEL_FONT_128:getWidth(valueDisplay) * textScale * (xDir - 1) / 2, outerY - 20, 0, textScale);

        curRot = curRot + math.pi * 2 * v.value / self.per;
    end
end

return Piechart;