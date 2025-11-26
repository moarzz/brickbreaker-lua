local WeaponBase = {};
WeaponBase.__index = WeaponBase;

local eventMeta = {};

function eventMeta:__index(key)
    return rawget(self, "_" .. key);
end

function eventMeta:__newindex(key, val)
    -- allow the ability to make new events
    if val == true then
        rawset(self, "_" .. key, key);

        return;
    end

    if type(val) ~= "function" then
        assert(val.__call ~= nil, "cannot set event callback to a non function or table with .__call set to a function");
    end

    assert(self[key] ~= nil, "cannot set unknown event: '" .. key .. "'");

    rawset(self, "_" .. key, val); -- successfully set event
end

function WeaponBase:__newindex(key, val)
    assert(type(key) == "string", "cannot use numbered indices variable in item");
    assert(string.find(key, "|") == nil, "cannot make a variable in an item that contains the character '|'");

    rawset(self, key, val);
end

function WeaponBase.new()
    local instance = setmetatable({}, WeaponBase);

    instance.events = setmetatable({}, eventMeta);

    for k, v in pairs(EVENT_POINTERS) do
        instance.events[k] = true;
    end

    return instance;
end

-- seperated from the .new() function to make all variables exist in the highest level of the item
function WeaponBase:init()
    assert(self.name ~= nil, "'name' must be set before creating instance of an ball");
    assert(self.rarity ~= nil, "'rarity' must be set before creating instance of an ball");
    assert(self.type ~= nil, "'type' must be set before creating instance of an ball");
    assert(self.startingPrice ~= nil, "'startingPrice' must be set before creating instance of an ball");
    assert(self.size ~= nil, "'size' must be set before creating instance of an ball");
    assert(self.stats ~= nil, "'stats' must be set before creating instance of an ball");

    self.rarity = self.rarity; -- set the highest table to first available rarity
    self.name = self.name; -- set highest table to first available name
    self.type = self.type;
    self.startingPrice = self.startingPrice;
    self.size = self.size;
    local stats = {};
    for k, v in pairs(self.stats) do
        stats[k] = v;
    end
    self.stats = stats; -- stats

    self.description = self.description or "<highlight=red><colour=white>ERROR<highlight=clear><colour=black> text not set for this ball";

    return self;
end

function WeaponBase:setDescription(description)
    self.description = description;
end
function WeaponBase:setName(name)
    self.name = name;

end
function WeaponBase:getName()
    return self.name;
end

function WeaponBase:getDataAsString()
    local ret = "v0.1\n"; -- version

    local defaultItem = WeaponBase.new();

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

function WeaponBase:loadFromData(str)
    local version, data = string.match(str, "^(v[%d.]*)\n(.*)$");
    assert(version and data, "save data corrupted, error from item");

    if version ~= "v0.1" then
        error("invalid version for item");
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

return WeaponBase;