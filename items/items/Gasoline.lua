local Gasoline = ItemBase.new();
Gasoline.__index = Gasoline;
Gasoline.name = "Gasoline";
Gasoline.description = "<font=bold>Laser or explosion Damage<font=default>\ncauses bricks to burn";
Gasoline.rarity = "common";
-- Gasoline.imageReference = "assets/sprites/UI/ItemIcons/Factory.png";

function Gasoline.new()
    local instance = setmetatable({}, Gasoline):init();
    return instance;
end

return Gasoline;