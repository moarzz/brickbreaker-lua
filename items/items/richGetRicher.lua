local RichGetRicher = ItemBase.new();
RichGetRicher.__index = RichGetRicher;
RichGetRicher.name = "Rich Get Richer";
RichGetRicher.description = "+1 for every <color=money><font=big>8$<color=white><font=default> you have";
RichGetRicher.rarity = "uncommon"; 
RichGetRicher.imageReference = "assets/sprites/UI/ItemIcons/Rich-Get-Richer.png";

function RichGetRicher.new()
    local instance = setmetatable({}, RichGetRicher):init();

    local bonus = math.floor(Player.getMoney() / 8);
    instance.stats.damage = bonus;
    -- instance.stats.fireRate = bonus;

    return instance;
end

function RichGetRicher.events:money() -- update whenever money moves
    local bonus = math.floor(Player.realMoney / 8);
    self.stats.damage = bonus;
    -- self.stats.fireRate = bonus;
end

return RichGetRicher;