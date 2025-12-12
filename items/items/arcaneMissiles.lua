local ArcaneMissiles = ItemBase.new();
ArcaneMissiles.__index = ArcaneMissiles;
ArcaneMissiles.name = "Arcane Missiles";
ArcaneMissiles.description = "<font=bold>On damage dealt\n<font=default>20% chance to shoot an arcane missile that deals 25% health damage";
ArcaneMissiles.rarity = "rare";
ArcaneMissiles.imageReference = "assets/sprites/UI/ItemIcons/Arcane-Missiles.png";

ArcaneMissiles.unique = true; -- does smthn ig

function ArcaneMissiles.new()
    local instance = setmetatable({}, ArcaneMissiles):init();

    return instance;
end

return ArcaneMissiles;