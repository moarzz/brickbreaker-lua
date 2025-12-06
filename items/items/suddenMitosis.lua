local SuddenMitosis = ItemBase.new();
SuddenMitosis.__index = SuddenMitosis;
SuddenMitosis.name = "Sudden Mitosis";
SuddenMitosis.description = "<font=bold>On Bullet Shot<font=default>\n5% chance to spawn a small ball that lasts for 6 seconds";
SuddenMitosis.rarity = "uncommon";
SuddenMitosis.shotCount = 0;
SuddenMitosis.unique = true
-- CoverLaser.imageReference = "assets/sprites/UI/ItemIcons/Cover-Laser.png";
function SuddenMitosis.new()
    local instance = setmetatable({}, SuddenMitosis):init();

    return instance;
end

return SuddenMitosis