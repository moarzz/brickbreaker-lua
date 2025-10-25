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
    gainMoney = true;
    upgradeStat = {
        item1 = {
            amount = true,
            damage = true,
            speed = true,
            fireRate = true,
            range = true,
            ammo = true,
            cooldown = true
        },
        item2 = {
            amount = true,
            damage = true,
            speed = true,
            fireRate = true,
            range = true,
            ammo = true,
            cooldown = true
        },
        item3 = {
            amount = true,
            damage = true,
            speed = true,
            fireRate = true,
            range = true,
            ammo = true,
            cooldown = true
        },
        item4 = {
            amount = true,
            damage = true,
            speed = true,
            fireRate = true,
            range = true,
            ammo = true,
            cooldown = true
        },
        item5 = {
            amount = true,
            damage = true,
            speed = true,
            fireRate = true,
            range = true,
            ammo = true,
            cooldown = true
        },
        item6 = {
            amount = true,
            damage = true,
            speed = true,
            fireRate = true,
            range = true,
            ammo = true,
            cooldown = true
        },
    },
    item = {
        purchase = {
            FourLeafedClover = true;
        };

        sell = {
            FourLeafedClover = true;
        }
    };
    levelUp = true;
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
