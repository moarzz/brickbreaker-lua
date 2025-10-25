local Sommelier = ItemBase.new();
Sommelier.__index = Sommelier;
Sommelier.name = "Sommelier";
Sommelier.description = "<font=big>Consumable Items<font=default> trigger twice";
Sommelier.rarity = "rare";

Sommelier.unique = true; -- does smthn ig

function Sommelier.new()
    local instance = setmetatable({}, Sommelier):init();

    return instance;
end

return Sommelier;