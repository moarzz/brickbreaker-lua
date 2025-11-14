local ElectromagneticAlignment = ItemBase.new();
ElectromagneticAlignment.__index = ElectromagneticAlignment;
ElectromagneticAlignment.name = "Electromagnetic Alignment";
ElectromagneticAlignment.description = "Balls gain a small homing effect towards the nearest brick";
ElectromagneticAlignment.rarity = "uncommon";
ElectromagneticAlignment.imageReference = "assets/sprites/UI/ItemIcons/Electromagnetic-Alignment.png";

-- ElectromagneticAlignment.unique = true; -- does smthn ig

function ElectromagneticAlignment.new()
    local instance = setmetatable({}, ElectromagneticAlignment):init();
    instance.stats.speed = 1;

    return instance;
end

return ElectromagneticAlignment;