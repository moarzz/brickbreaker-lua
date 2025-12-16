local Gasoline = ItemBase.new();
Gasoline.__index = Gasoline;
Gasoline.name = "Gasoline";
Gasoline.description = "Damage dealt by lasers or explosions has a 25% chance to burn the brick. dealing their <color=damage>damage<color=white> 5 times";
Gasoline.rarity = "rare";
Gasoline.imageReference = "assets/sprites/UI/ItemIcons/Archeologist's-Hat.png";

function Gasoline.new()
    local instance = setmetatable({}, Gasoline):init();

    return instance;
end

return Gasoline;