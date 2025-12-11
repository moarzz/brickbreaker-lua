local ExplodingBeams = ItemBase.new();
ExplodingBeams.__index = ExplodingBeams;
ExplodingBeams.name = "Exploding Beams";
ExplodingBeams.description = "<font=bold>Laser beams<font=default> have a <font=big><explosionChance>%<font=default> chance to cause an explosion";
ExplodingBeams.rarity = "uncommon";
-- ExplodingBeams.imageReference = "assets/sprites/UI/ItemIcons/Archeologist's-Hat.png";

function ExplodingBeams.new()
    local instance = setmetatable({}, ExplodingBeams):init();

    instance.descriptionPointers = {
        explosionChance = hasItem("Four Leafed Clover") and 20 or 10;
    };
    return instance;
end

return ExplodingBeams;