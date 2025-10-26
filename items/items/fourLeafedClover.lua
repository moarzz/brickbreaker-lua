local FourLeafedClover = ItemBase.new();
FourLeafedClover.__index = FourLeafedClover;
FourLeafedClover.name = "Four Leafed Clover";
FourLeafedClover.description = "every <font=bold>%</font=bold><font=default> on items is doubled";
FourLeafedClover.rarity = "uncommon";
FourLeafedClover.imageReference = "assets/sprites/UI/itemIcons/Four-Leafed-Clover.png";

function FourLeafedClover.new()
    local instance = setmetatable({}, FourLeafedClover):init();

    return instance;
end

return FourLeafedClover;