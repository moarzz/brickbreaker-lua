local PointerConverter = {};

local arbitraryPreffix = "P_"; -- add this to a key 2 get the real location
local arbitraryPreffixRegex = "^" .. arbitraryPreffix;

local function pointerNewIndex(tbl, key, val)
    assert(type(key) == "string", "tried to create index in pointer using a non string");
    assert(string.match(key, arbitraryPreffixRegex) == nil, "tried to add an invalid value");
    assert(type(val) == "function", "cannot have a function as a value in a pointer");

    key = arbitraryPreffix .. key;

    if rawget(tbl, key) == val then
        return;
    end

    rawset(tbl, key, val);

    if tbl.valueChangeCallback then
        tbl.valueChangeCallback(tbl.valueChangeCallbackObject);
    end
end

local function pointerIndex(tbl, key)
    assert(type(key) == "string", "tried to index pointer using a non string");

    return rawget(tbl, arbitraryPreffix .. key);
end

function PointerConverter.convertToPointer(tbl, valueChangeCallback, obj)
    if tbl.__index or tbl.__newindex then
        assert(tbl.__newindex == pointerNewIndex and tbl.__index == pointerIndex, "tried to convert an object that has __newindex or __index defined into a pointer");

        return tbl; -- it is already a pointer
    end

    tbl.__index = pointerIndex;
    tbl.__newindex = pointerNewIndex;

    for k, v in pairs(tbl) do
        tbl[k] = nil; -- set to nil so that __newindex gets called on next line
        tbl[k] = v;
    end

    -- set after the table has been remade to prevent a shit tonne of calls while its updating
    rawset(tbl, "valueChangeCallback", valueChangeCallback);
    rawset(tbl, "valueChangeCallbackObject", obj);

    return tbl;
end

return PointerConverter;