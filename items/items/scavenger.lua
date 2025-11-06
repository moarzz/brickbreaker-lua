local Scavenger = ItemBase.new();
Scavenger.__index = Scavenger;
Scavenger.name = "Scavenger";
Scavenger.description = "<font=bold>+35%<font=default> chance for bricks to drop money when destroyed";
Scavenger.rarity = "common";
Scavenger.imageReference = "assets/sprites/UI/ItemIcons/Scavenger.png";

function Scavenger.new()
    local instance = setmetatable({}, Scavenger):init();

    return instance;
end

return Scavenger;