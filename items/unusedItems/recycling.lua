local Factory = ItemBase.new();
Factory.__index = Factory;
Factory.name = "Factory";
Factory.description = "<font=bold>On brick destroyed<font=default>\n<recyclingChance>% chance to create a random turret";
Factory.rarity = "uncommon";
Factory.imageReference = "assets/sprites/UI/ItemIcons/Factory.png";

function Factory.new()
    local instance = setmetatable({}, Factory):init();
    instance.descriptionPointers = {
        doubleChance = hasItem("Four Leafed Clover") and 20 or 10;
    };
    return instance;
end

return Factory;