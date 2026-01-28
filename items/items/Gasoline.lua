local Gasoline = ItemBase.new();
Gasoline.__index = Gasoline;
Gasoline.name = "Gasoline";
Gasoline.description = "<font=bold>Laser or explosion Damage<font=default>\ncauses bricks to burn";
Gasoline.rarity = "uncommon";
Gasoline.imageReference = "assets/sprites/UI/ItemIcons/Gasoline.png";

function Gasoline.new()
    local instance = setmetatable({}, Gasoline):init();
    return instance;
end

return Gasoline;