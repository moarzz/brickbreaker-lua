--[[local ElectromagneticAlignment = ItemBase.new();
ElectromagneticAlignment.__index = ElectromagneticAlignment;
ElectromagneticAlignment.name = "Electromagnetic Alignment";
ElectromagneticAlignment.description = "Bullets will home in on the nearest brick";
ElectromagneticAlignment.rarity = "common";
ElectromagneticAlignment.imageReference = "assets/sprites/UI/ItemIcons/Homing-Bullets.png";

ElectromagneticAlignment.unique = true; -- does smthn ig

function ElectromagneticAlignment.new()
    local instance = setmetatable({}, ElectromagneticAlignment):init();

    return instance;
end

return ElectromagneticAlignment;]]