local path = string.match((...), "(.+[./]).-[./]") or "";

local Bargraph = Component.new();
Bargraph.__index = Bargraph;

--Bargraph.font = love.graphics.newFont("SpaceMono.ttf", 128);

function Bargraph.new(x, y, w, h, bars)
    local instance = setmetatable(Component.new(), Bargraph);

    instance.bars = {};
    instance.max = 0;

    instance.x = x;
    instance.y = y;
    instance.w = w;
    instance.h = h;

    instance.dispLog = false;

    for i, v in ipairs(bars) do
        instance.bars[i] = {name = v, value = 0};
    end

    return instance;
end

function Bargraph:setDispLog(state)
    self.dispLog = state;
end

function Bargraph:setPlot(name, value)
    if value > self.max then
        self.max = value;
    end

    for i, v in ipairs(self.bars) do
        if v.name == name then
            v.value = value;

            return;
        end
    end
end

function Bargraph:draw()
    local keepMax = self.max;
    local keepBars = {};

    -- display on a log10 scale vertically if wanted
    if self.dispLog then
        for i, v in ipairs(self.bars) do
            keepBars[i] = v.value;
            v.value = math.log(v.value, 10);
        end

        self.max = math.log(self.max, 10);
    end

    local fontHeight = PIXEL_FONT_HEIGHT;
    local markPrintScale = 20 / fontHeight;
    love.graphics.setFont(PIXEL_FONT_128);
    love.graphics.setColor(1,1,1); -- white

    -- draw x and y line at origin
    love.graphics.line(self.x, self.y, self.x, self.y + self.h);
    love.graphics.line(self.x, self.y + self.h, self.x + self.w, self.y + self.h);

    -- get graph scaling values (very nice)
    local minimum = self.max / (self.h / 30);
    local magnitude = 10 ^ math.floor(math.log(minimum, 10));
    local residual = minimum / magnitude;
    local labelMarkScale = magnitude;

    if residual > 5 then
        labelMarkScale = 10 * magnitude;
    elseif residual > 2 then
        labelMarkScale = 5 * magnitude;
    elseif residual > 1 then
        labelMarkScale = 2 * magnitude;
    end

    local markDist = self.h / self.max * labelMarkScale;

    -- draw all marks on y line
    for i = 0, math.floor(self.max / labelMarkScale) do
        love.graphics.line(self.x - 7, self.y + self.h - i * markDist, self.x, self.y + self.h - i * markDist);

        local text = tostring(i * labelMarkScale);
        love.graphics.print(text, self.x - 10 - PIXEL_FONT_128:getWidth(text) * markPrintScale, self.y + self.h - i * markDist - fontHeight * markPrintScale / 2, 0, markPrintScale);
    end

    local barWidth = self.w / (#self.bars * 5/3 + 2/3);
    local gapWidth = (self.w - barWidth * #self.bars) / (#self.bars + 1);

    -- draw all bars
    for i, v in ipairs(self.bars) do
        local x = self.x + i * gapWidth + (i - 1) * barWidth;
        local h = self.h * (v.value / self.max);

        love.graphics.rectangle("fill", x, self.y + self.h - h, barWidth, h);
        love.graphics.print(v.name, x + barWidth / 2 + 10, self.y + self.h + 2, math.pi / 2, markPrintScale);
    end

    -- undo changes to data done from displaying log data
    if self.dispLog then
        love.graphics.print("log10", self.x, self.y - fontHeight * markPrintScale, 0, markPrintScale);

        for i, v in ipairs(self.bars) do
            v.value = keepBars[i];
        end

        self.max = keepMax;
    end
end

return Bargraph;