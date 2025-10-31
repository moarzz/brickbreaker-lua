local TotalAnihilation = ItemBase.new();
TotalAnihilation.__index = TotalAnihilation;
TotalAnihilation.name = "Total Anihilation";
TotalAnihilation.description = "Explosions cause 4 smaller explosions to happen nearby";
TotalAnihilation.rarity = "rare";

TotalAnihilation.unique = true; -- does smthn ig

function TotalAnihilation.new()
    local instance = setmetatable({}, TotalAnihilation):init();

    instance.stats.damage = 2;
    instance.stats.range  = 2;

    return instance;
end

--! NOT READY YET!!
-- return TotalAnihilation;