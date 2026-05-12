local Recycling = ItemBase.new();
Recycling.__index = Recycling;
Recycling.name = "Recycling";
Recycling.description = "<font=bold>On brick destroyed<font=default>\n<recyclingChance>% chance to create a random turret";
Recycling.rarity = "uncommon";
Recycling.imageReference = "assets/sprites/UI/ItemIcons/Recycling.png";

function Recycling.new()
    local instance = setmetatable({}, Recycling):init();
    instance.descriptionPointers = {
        doubleChance = hasItem("Four Leafed Clover") and 8 or 4;
    };
    return instance;
end

return Recycling;