local RichGetRicher = ItemBase.new();
RichGetRicher.__index = RichGetRicher;
RichGetRicher.name = "Rich Get Richer";
RichGetRicher.description = "+1 for every <color=money><font=big>20$<color=white><font=default> you have";
RichGetRicher.rarity = "uncommon";

function RichGetRicher.new()
    local instance = setmetatable({}, RichGetRicher):init();

    local bonus = math.floor(Player.money / 20);
    instance.stats.amount = bonus;
    instance.stats.fireRate = bonus;

    return instance;
end

function RichGetRicher.events:item_purchase() -- update whenever money moves
    local bonus = math.floor(Player.money / 20);
    instance.stats.amount = bonus;
    instance.stats.fireRate = bonus;
end

function RichGetRicher.events:gainMoney() -- update whenever money moves
    local bonus = math.floor(Player.money / 20);
    instance.stats.amount = bonus;
    instance.stats.fireRate = bonus;
end

return RichGetRicher;