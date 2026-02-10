local ColdHardCash = ItemBase.new();
ColdHardCash.__index = ColdHardCash;
ColdHardCash.name = "Cold Hard Cash";
ColdHardCash.description = "<font=big>Dollar Bills<font=default> give 1$ extra";
ColdHardCash.rarity = "rare";
-- ColdHardCash.imageReference = "assets/sprites/UI/ItemIcons/Cold-Hard-Cash.png";

function ColdHardCash.new()
    local instance = setmetatable({}, ColdHardCash):init();

    return instance;
end

return ColdHardCash;