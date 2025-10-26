local ArcaneMissiles = ItemBase.new();
ArcaneMissiles.__index = ArcaneMissiles;
ArcaneMissiles.name = "Arcane Missiles";
ArcaneMissiles.description = "<font=bold>On ball bounce with Brick\n<font=default>shoot an arcane missile of that ball's <color=damage>damage";
ArcaneMissiles.rarity = "rare";
ArcaneMissiles.imageReference = "assets/sprites/UI/ItemIcons/Arcane-Missiles.png";

ArcaneMissiles.unique = true; -- does smthn ig

function ArcaneMissiles.new()
    local instance = setmetatable({}, ArcaneMissiles):init();

    return instance;
end

return ArcaneMissiles;