local path = string.match((...), "(.+[./]).-[./]") or "";

local Spreadsheet = Component.new();
Spreadsheet.__index = Spreadsheet;

Spreadsheet._trigger = "isAltered";

Spreadsheet.edgeScale = 3;

function Spreadsheet.new(x, y, w, h, cols, rows)
    local instance = setmetatable(Component.new(), Spreadsheet);

    instance:addBoundingBox(x, y, w, h);

    instance.altered = 0;
    instance.textinputs = {};

    instance.cols = cols;
    instance.rows = rows;

    local wide = w / cols;
    local high = h / rows;

    for row = 1, rows do
        for col = 1, cols do
            local name = "_" .. tostring(row) .. "_" .. tostring(col);
            instance[name] = function(self, textinput)
                self.altered = 2;
            end

            table.insert(instance.textinputs, instance:addTrigger(Textinput(x + (col - 1) * wide, y + (row - 1) * high, wide, high), name));
        end
    end

    return instance;
end

function Spreadsheet:getTextAt(x, y)
    if x <= 0 or x > self.rows then
        return;
    end

    if y <= 0 or y > self.cols then
        return;
    end

    return self.textinputs[(y - 1) * self.rows + x]:getText();
end
function Spreadsheet:setTextAt(x, y, text)
    if x <= 0 or x > self.rows then
        return false;
    end

    if y <= 0 or y > self.cols then
        return false;
    end

    self.textinputs[(y - 1) * self.rows + x]:setText(text);
    return true;
end

function Spreadsheet:isAltered()
    return self.altered ~= 0;
end

function Spreadsheet:update()
    if self:isAltered() then
        self.altered = self.altered - 1;
    end
end

function Spreadsheet:draw()
    for i, v in ipairs(self.textinputs) do
        v:draw();
    end
end

return Spreadsheet;