local MagicMag = ItemBase.new();
MagicMag.__index = MagicMag;
MagicMag.name = "Magic Mag";
MagicMag.description = "<font=bold>When ammo is used<font=default>\n35% chance to not consume it";
MagicMag.rarity = "uncommon";
MagicMag.imageReference = "assets/sprites/UI/ItemIcons/MagicMag.png";

function MagicMag.new()
    local instance = setmetatable({}, MagicMag):init();
    instance.stats.ammo = 2
    return instance;
end

return MagicMag;