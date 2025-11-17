local RichGetRicher = ItemBase.new();
RichGetRicher.__index = RichGetRicher;
RichGetRicher.name = "Rich Get Richer";
RichGetRicher.description = "+1 for every <color=money><font=big>10$<color=white><font=default> you have (min 1)";
RichGetRicher.rarity = "uncommon"; 
RichGetRicher.imageReference = "assets/sprites/UI/ItemIcons/Rich-Get-Richer.png";

function RichGetRicher.new()
    local instance = setmetatable({}, RichGetRicher):init();

    local bonus = math.max(math.floor(Player.realMoney / 10), 1);
    instance.stats.damage = bonus;
    -- instance.stats.fireRate = bonus;

    return instance;
end

function RichGetRicher.events:money() -- update whenever money moves
    local bonus = math.max(math.floor(Player.realMoney / 10), 1);
    self.stats.damage = bonus;
    -- self.stats.fireRate = bonus;
end

return RichGetRicher;