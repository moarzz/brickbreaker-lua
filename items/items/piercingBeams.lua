local PiercingBeams = ItemBase.new();
PiercingBeams.__index = PiercingBeams;
PiercingBeams.name = "Piercing Beams";
PiercingBeams.description = "<font=bold>Laser beams<font=default> have a <font=big>10%<font=default> chance to pierce through all bricks in their path";
PiercingBeams.rarity = "rare";
-- PiercingBeams.imageReference = "assets/sprites/UI/ItemIcons/Archeologist's-Hat.png";

function PiercingBeams.new()
    local instance = setmetatable({}, PiercingBeams):init();

    return instance;
end

return PiercingBeams;