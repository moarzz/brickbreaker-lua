local path = string.match((...), "(.+[./]).-[./]") or "";

local Numberinput = Component.new();
Numberinput.__index = Numberinput;

Numberinput._trigger = "isAltered";

Numberinput.edgeScale = 3;

function Numberinput.new(x, y, w, h, defaultValue, step)
    local instance = setmetatable(Component.new(), Numberinput);

    instance:addBoundingBox(x, y, w, h);
    instance.textinput = instance:addTrigger(Textinput(x, y, w - 40, h), "textAltered");
    instance.increaseButton = instance:addTrigger(Button(x + w - 40, y, 40, h / 2), "valueIncreased");
    instance.decreaseButton = instance:addTrigger(Button(x + w - 40, y + h / 2, 40, h / 2), "valueDecreased");

    instance.defaultValue = defaultValue or 0;
    instance.value = defaultValue or 0;
    instance.step = step or 1;

    instance.textinput:setText(tostring(instance.value));

    instance.altered = 0;

    return instance;
end

function Numberinput:textAltered(textinput)
    local text = textinput:getText();

    -- if string is not exactly a number then try to clean its text until it is
    if not tonumber(text) then
        text = string.gsub(text, "[^0123456789.]", "");

        -- if cleaning did not work the just give up
        if not tonumber(text) then
            self.value = self.defaultValue;

            textinput:setText(tostring(self.defaultValue));

            return;
        end
    end

    local asNum = tonumber(text); -- guarenteed to not be nil

    self.value = asNum;
    textinput:setText(tostring(self.value)); -- just to ensure

    self.altered = 2;
end
function Numberinput:valueIncreased()
    self.value = self.value + self.step;

    self.textinput:setText(tostring(self.value));
    self.altered = 2;
end
function Numberinput:valueDecreased()
    self.value = self.value - self.step;

    self.textinput:setText(tostring(self.value));
    self.altered = 2;
end

function Numberinput:isAltered()
    return self.altered ~= 0;
end

function Numberinput:update()
    if self:isAltered() then
        self.altered = self.altered - 1;
    end
end

function Numberinput:draw()
    self.textinput:draw();
    self.increaseButton:draw();
    self.decreaseButton:draw();
end

return Numberinput;