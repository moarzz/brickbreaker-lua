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

local ItemBase = {};
ItemBase.__index = ItemBase;

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
    assert(type(key) == "string", "cannot use numbered indices variable in item");
    assert(string.find(key, "|") == nil, "cannot make a variable in an item that contains the character '|'");

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

-- seperated from the .new() function to make all variables exist in the highest level of the item
function ItemBase:init()
    assert(self.name ~= nil, "'name' must be set before creating instance of an item");
    assert(self.rarity ~= nil, "'rarity' must be set before creating instance of an item");

    self.rarity = self.rarity; -- set the highest table to first available rarity
    self.name = self.name; -- set highest table to first available name

    self.description = self.description or "<highlight=red><colour=white>ERROR<highlight=clear><colour=black> text not set for this item";

    self.stats = {}; -- stats

    return self;
end

function ItemBase:buy(...)
    print("purchase function not set for this item: " .. tostring(self.name));

    if self.purchase then
        return self:purchase(...);
    end

    -- Resolve the template (the registered item) safely. Instances may mutate .name, so prefer
    -- the template's filteredName if available.
    local template = nil
    if self.filteredName and Items.itemIndices[self.filteredName] then
        template = Items.getItemByName(self.filteredName)
    else
        -- try pcall with self.name (may error if name isn't registered)
        local ok, res = pcall(Items.getItemByName, self.name)
        if ok then template = res end
    end

    -- fallback: scan lists for a template with matching name
    if not template then
        for _, list in pairs(Items.allItems) do
            for _, it in ipairs(list) do
                if it.name == self.name then
                    template = it
                    break
                end
            end
            if template then break end
        end
        if not template then
            for _, list in pairs(Items.allConsumables) do
                for _, it in ipairs(list) do
                    if it.name == self.name then
                        template = it
                        break
                    end
                end
                if template then break end
            end
        end
    end

    -- Decrement instancesLeft on the template (not the instance)
    if template and template.instancesLeft then
        template.instancesLeft = template.instancesLeft - 1
        print("Instances left for item " .. (template.name or tostring(self.name)) .. ": " .. template.instancesLeft)
    end

    if not self.unique then
        if template and template.instancesLeft and template.instancesLeft >= 1 then
            -- use template.filteredName when un-hiding
            Items.removeInvisibleItem(template.filteredName or self.filteredName)
        end
    end

    -- Queue the purchase event using the template's filteredName when possible
    local eventName = (template and template.filteredName) or self.filteredName or self.name
    EventQueue:addEventToQueue(EVENT_POINTERS.item_purchase .. "_" .. eventName);
end

function ItemBase:setDescription(description)
    self.description = description;
end
function ItemBase:setName(name)
    self.name = name;

end
function ItemBase:getName()
    return self.name;
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

return ItemBase;