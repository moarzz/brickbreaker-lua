local RabbitsFoot = ItemBase.new();
RabbitsFoot.__index = RabbitsFoot;
RabbitsFoot.name = "Rabbit's Foot";
RabbitsFoot.description = "<font=bold>+30%<font=default> chance to see rarer items in shop";
RabbitsFoot.rarity = "common";
RabbitsFoot.imageReference = "assets/sprites/UI/ItemIcons/Rabbit-Foot.png";

function RabbitsFoot.new()
    local instance = setmetatable({}, RabbitsFoot):init();

    return instance;
end

return RabbitsFoot;