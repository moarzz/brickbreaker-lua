local Factory = ItemBase.new();
Factory.__index = Factory;
Factory.name = "Factory";
Factory.description = "<font=bold>On Turret Generation<font=default>\n<doubleChance>% chance to create an additional turret";
Factory.rarity = "uncommon";
Factory.imageReference = "assets/sprites/UI/ItemIcons/Factory.png";

function Factory.new()
    local instance = setmetatable({}, Factory):init();
    instance.descriptionPointers = {
        doubleChance = hasItem("Four Leafed Clover") and 80 or 40;
    };
    return instance;
end

return Factory;