local TotalAnihilation = ItemBase.new();
TotalAnihilation.__index = TotalAnihilation;
TotalAnihilation.name = "Total Anihilation";
TotalAnihilation.description = "Explosions cause 3 smaller explosions to happen around them with the same <color=damage>damage";
TotalAnihilation.rarity = "uncommon";
TotalAnihilation.imageReference = "assets/sprites/UI/ItemIcons/Total-Anihilation.png";

TotalAnihilation.unique = true; -- does smthn ig

function TotalAnihilation.new()
    local instance = setmetatable({}, TotalAnihilation):init();

    instance.stats.range = 1;

    return instance;
end

--! NOT READY YET!!
return TotalAnihilation;