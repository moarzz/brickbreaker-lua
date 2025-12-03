local RichGetRicher = ItemBase.new();
RichGetRicher.__index = RichGetRicher;
RichGetRicher.name = "Rich Get Richer";
RichGetRicher.description = "+1 for every <color=money><font=big>12$<color=white><font=default> you have";
RichGetRicher.rarity = "uncommon"; 
RichGetRicher.imageReference = "assets/sprites/UI/ItemIcons/Rich-Get-Richer.png";

function RichGetRicher.new()
    local instance = setmetatable({}, RichGetRicher):init();

    local bonus = math.max(math.floor(Player.realMoney / 12), 0);
    instance.stats.damage = bonus;
    -- instance.stats.fireRate = bonus;

    return instance;
end

function RichGetRicher.events:money() -- update whenever money moves
    local bonus = math.max(math.floor(Player.realMoney / 12), 1);
    self.stats.damage = bonus;
    -- self.stats.fireRate = bonus;
end

return RichGetRicher;