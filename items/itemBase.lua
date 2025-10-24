--! explanation for annoyance:
--? TL;DR. __newindex will only get called the first time a value is set.
--? lua's __newindex metamethod will only be called if rawget(table, key) returns nil
--? if it does not return nil (the value at that key is already set to something) then it will just rawset(table key, value)
--? instead of calling the __newindex metamethod.
--* TL;DR. changing the key that the value is kept at will keep the key nil.
--* to ensure that __newindex gets called every time that the key is set to a new value I have decided
--* to always save the value to a different key by adding the "_" character to the beggining of it
--* this means that setting some key "someKey" will save the value instead to "_someKey" so that
--* if some key "someKey" is set to a different value again, the __newindex metamethod will be called again because
--* the actual key "someKey" is empty.
--* in order to avoid key mismatching; however, the __index metamethod is set to always return the asked for key with
--* the "_" character added to the beggining, so indexing some key "someKey", will instead index "_someKey" which is
--* the 'actual' location of the wanted value

--! this script contains way too many magic numbers

-- local FancyText = require("fancyText/fancyText_");
-- local EasingFuncs = require("easingFuncs");
-- local Box = require("box");

local ItemBase = {};
ItemBase.__index = ItemBase;

-- ItemBase.__drawable = true;
-- ItemBase.__trigger = true;
-- ItemBase.__triggertype = "Modifier";

-- ItemBase.triggerAnimLen = 0.75;
-- ItemBase.isModifier = true;

-- ItemBase.defaultTexture = love.graphics.newImage("textures/modifier_not_found.png");

local eventMeta = {};

function eventMeta:__index(key)
    -- this is annoying (see explanation at top of script)
    return rawget(self, "_" .. key);
end

function eventMeta:__newindex(key, val)
    -- allow the ability to make new events
    if val == true then
        -- this is annoying (see explanation at top of script)
        rawset(self, "_" .. key, key);

        return;
    end

    if type(val) ~= "function" then
        assert(val.__call ~= nil, "cannot set event callback to a non function or table with .__call set to a function");
    end

    assert(self[key] ~= nil, "cannot set unknown event: '" .. key .. "'");

    -- this is annoying (see explanation at top of script)
    rawset(self, "_" .. key, val); -- successfully set event
end

function ItemBase:__newindex(key, val)
    assert(type(key) == "string", "cannot use numbered indices variable in modifier");
    assert(string.find(key, "|") == nil, "cannot make a variable in a modifier that contains the character '|'");

    rawset(self, key, val);
end

function ItemBase.new()
    local instance = setmetatable({}, ItemBase);

    instance.events = setmetatable({}, eventMeta);

    for k, v in pairs(EVENT_POINTERS) do
        instance.events[k] = true;
    end

    return instance;
end

-- seperated from the .new() function to make all variables exist in the highest level of the modifier
function ItemBase:init()
    assert(self.name ~= nil, "name must be set before creating instance of a modifier");
    assert(self.rarity ~= nil, "rarity must be set before creating instance of a modifier");

    self.card = Card.new(0,0, 100,100);
    self.card:setTexture(self.texture or self.defaultTexture);

    self.triggerLen = 0;
    self.triggerType = "hard";

    self.rarity = self.rarity; -- set the highest table to first available rarity
    self.name = self.name; -- set highest table to first available name

    self.text = self.text or "<highlight=red><colour=white>ERROR<highlight=clear><colour=black> text not set for this modifier";
    self.fancyTextTextBox = FancyText.new(self.text, -960,-540, 350, 40, "center", self);
    self.fancyTextNameBox = FancyText.new(self.name, -960,-540, 200000, 40, "left", self); --! really large max width: not good fix later
    self.textBox = Box.new(-972,-552, 374, self.fancyTextTextBox:getHeight() + 24, 18, "filled");
    self.nameBox = Box.new(-960 - self.fancyTextNameBox:getWidth() / 2 + 88,-604, self.fancyTextNameBox:getWidth() + 24, 64, 18, "filled");

    return self;
end

function ItemBase:checkBoundingBox(x, y)
    return self.card:isPointInside(x, y);
end

function ItemBase:grab()
    self.card:grab();
end
function ItemBase:unGrab()
    self.card:unGrab();
end
function ItemBase:getDrawingPosition()
    return self.card:getDrawingPosition();
end

function ItemBase:setText(text)
    self.text = text;

    self.fancyTextTextBox:setText(text);
    self.textBox:setHeight(self.fancyTextTextBox:getHeight() + 24);
end
function ItemBase:setPosition(x, y)
    self.card:setPosition(x, y);

    if x - 350 > -860 then
        self.fancyTextTextBox:setPosition(x - 362, y);
        self.textBox:setPosition(x - 374, y - 12);
    else
        self.fancyTextTextBox:setPosition(x + 112, y);
        self.textBox:setPosition(x + 100, y - 12);
    end

    self.fancyTextNameBox:setPosition(x - self.fancyTextNameBox:getWidth() / 2 + 50, y - 52);
    self.nameBox:setPosition(x - self.fancyTextNameBox:getWidth() / 2 + 38, y - 64);
end
function ItemBase:setImmediatePosition(x, y)
    self.card:teleport(x, y);

    if x - 350 > -860 then
        self.fancyTextTextBox:setPosition(x - 362, y);
        self.textBox:setPosition(x - 374, y - 12);
    else
        self.fancyTextTextBox:setPosition(x + 112, y);
        self.textBox:setPosition(x + 100, y - 12);
    end

    self.fancyTextNameBox:setPosition(x - self.fancyTextNameBox:getWidth() / 2 + 50, y - 52);
    self.nameBox:setPosition(x - self.fancyTextNameBox:getWidth() / 2 + 38, y - 64);
end
function ItemBase:setName(name)
    self.name = name;

    self.fancyTextNameBox:setText(name);
end
function ItemBase:getName()
    return self.name;
end
-- animation
function ItemBase:trigger(triggerType)
    triggerType = triggerType or "hard";

    if triggerType == "hard" then
        self.triggerType = "hard";
    elseif triggerType == "soft" then
        self.triggerType = "soft";
    else
        error("tried to animate modifier with invalid animation (only 'soft' and 'hard' allowed)");
    end

    self.triggerLen = self.triggerAnimLen;
    --// self.triggerLen = self.triggerAnimLen;
end

function ItemBase:draw(dt)
    dt = dt or love.timer.getDelta();

    love.graphics.setColor(1,1,1); -- white

    local depth = 100;
    local animRot = 0;

    if self.triggerLen > 0 then
        local perun = self.triggerLen / self.triggerAnimLen;

        if self.triggerType == "hard" then
            animRot = EasingFuncs.lerpIn(0, -0.8, EasingFuncs.springer(1 - perun));
        elseif self.triggerType == "soft" then
            animRot = EasingFuncs.lerpIn(0, -0.8, EasingFuncs.spring(1 - perun));
        end

        self.triggerLen = math.max(0, self.triggerLen - dt);
    end

    local mx, my = love.mouse.getPosition();

    -- currently hovering over the modifier. so draw the text aswell
    if Game.modifierRoster.grabbingModifier == nil and not self.card:isGrabbed() and self:checkBoundingBox(mx, my) then
        self.fancyTextTextBox:update();

        -- depth of 0 = draw above everything (can get drawn over if another depth of 0 gets draw afterwards)
        love.graphics.setColor(1,1,1); -- white
        DepthTester.drawCallbackAtDepth(1, self.textBox.draw, self.textBox);
        DepthTester.drawCallbackAtDepth(1, self.nameBox.draw, self.nameBox);
        DepthTester.drawCallbackAtDepth(0, self.fancyTextTextBox.draw, self.fancyTextTextBox);
        DepthTester.drawCallbackAtDepth(0, self.fancyTextNameBox.draw, self.fancyTextNameBox);
        love.graphics.setColor(1,1,1); -- white
    end

    self.card:update(dt);

    if self.card:isGrabbed() then
        depth = 99;
    end

    DepthTester.startDrawingAtDepth();
    self.card:draw(0,0, animRot);
    DepthTester.stopDrawingAtDepth(depth);
end

function ItemBase:getDataAsString()
    local ret = "v0.1\n"; -- version

    local defaultItem = ItemBase.new();

    for k, v in pairs(self) do
        if type(v) ~= "function" and k ~= "events" and not defaultItem[k] then
            if type(v) == "string" then
                ret = ret .. k .. "|string|" .. v .. "|\n";
            elseif type(v) == "number" then
                ret = ret .. k .. "|number|" .. tostring(v) .. "|\n";
            elseif type(v) == "table" then
                ret = ret .. k .. "|table|" .. recurseTableGetDataAsString(v) .. "|\n";
            end
        end
    end

    return ret;
end

function ItemBase:loadFromData(str)
    local version, data = string.match(str, "^(v[%d.]*)\n(.*)$");
    assert(version and data, "save data corrupted, error from modifier");

    if version ~= "v0.1" then
        error("invalid version for modifier");
    end

    while string.len(data) > 3 do -- at least 3 "|"s
        local name, dataType, rem = string.match(data, "^([^|]*)|([^|]*)|(.*)$");

        if dataType == "string" then
            local item, leftover = string.match(rem, "^([^|]*)|\n(.*)$");

            self[name] = item;

            data = leftover;
        elseif dataType == "number" then
            local item, leftover = string.match(rem, "^([^|]*)|\n(.*)$");

            self[name] = tonumber(item);

            data = leftover;
        elseif dataType == "table" then
            local item, leftover = string.match(rem, "^(%b{})|\n(.*)$")

            self[name] = recurseTableLoadDataFromString(item);

            data = leftover;
        else
            error("tried to load data type not supported");
        end
    end
end

return ItemBase;