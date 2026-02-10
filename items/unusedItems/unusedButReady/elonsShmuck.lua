local ElonsShmuck = ItemBase.new();
ElonsShmuck.__index = ElonsShmuck;
ElonsShmuck.name = "Elon's Shmuck";
ElonsShmuck.description = "Items and rerolls cost 2$";
ElonsShmuck.rarity = "legendary";

ElonsShmuck.unique = true; -- does smthn ig

function ElonsShmuck.new()
    local instance = setmetatable({}, ElonsShmuck):init();

    return instance;
end

return ElonsShmuck;