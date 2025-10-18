local eventLocatorMeta = {};
function eventLocatorMeta:__index(key)
    if eventLocatorMeta[key] then
        return eventLocatorMeta[key];
    end

    local cur = self;

    for str, _ in string.gmatch(key .. "_", "(.-)_") do
        if cur[str] then
            cur = cur[str];
        else
            error("cannot find event from event pointer: '" .. key .. "'");
        end
    end

    assert(cur ~= self, "cannot find event from event pointer: '" .. key .. "'");

    return cur;
end

function eventLocatorMeta.contains(objToCheck, check)
    local match = string.match(objToCheck, "^" .. check);

    return match ~= nil;
end

_G.EVENTS = setmetatable({
    empty = true; -- 'nil' for events

    block = {
        score = {
            mult  = true;
            bonus = true;
            normal = true;
            gear = true;
        };
        clear = {
            mult  = true;
            bonus = true;
            normal = true;
            gear = true;
        };
        place = {
            mult  = true;
            bonus = true;
            normal = true;
            gear = true;
        };
    };
    piece = {
        place = {
            T = true;
            I = true;
            L = true;
            J = true;
            O = true;
            S = true;
            Z = true;
        };
        hold  = {
            T = true;
            I = true;
            L = true;
            J = true;
            O = true;
            S = true;
            Z = true;
        };
        spin = { -- spin move placements. not rotation
            T = true;
            I = true;
            L = true;
            J = true;
            O = true;
            S = true;
            Z = true;
        };
    };
    line = {
        score = {
            single = true;
            double = true;
            triple = true;
            quadrouple = true;
        };
        clear = {
            single = true;
            double = true;
            triple = true;
            quadrouple = true;
        };
        finished = true;
    };
    modifier = {
        buy     = true;
        sell    = true;
        trigger = true;
    };
}, eventLocatorMeta); -- list of all possible modifier triggers

_G.ANIMATION_EVENTS = setmetatable({
    block = {
        trigger = true;
        clear = true;
        score = {
            points = true;
            mult = true;
        };
    };
    line = {
        trigger = true;
        clear = true;
        score = {
            points = true;
            mult = true;
        };
    };
    modifier = {
        trigger = true;
        score = {
            points = true;
            mult = true;
        };
    };
}, eventLocatorMeta); -- list of all possible animation events

local function recurseFill(tbl, fill, cur)
    fill = fill or {};
    cur = cur or "";

    for k, v in pairs(tbl) do
        assert(string.find(k, "_") == nil, "cannot make an event with subcontents containing the '_' character");

        if type(v) == "table" then
            fill[cur .. k] = cur .. k;

            recurseFill(v, fill, cur .. k .. "_");
        else
            fill[cur .. k] = cur .. k;
        end
    end

    return fill;
end

_G.EVENT_POINTERS = recurseFill(EVENTS);
_G.ANIMATION_EVENT_POINTERS = recurseFill(ANIMATION_EVENTS);
