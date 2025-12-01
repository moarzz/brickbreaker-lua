local SuddenMitosis = ItemBase.new();
SuddenMitosis.__index = SuddenMitosis;
SuddenMitosis.name = "Sudden Mitosis";
SuddenMitosis.description = "<font=bold>On Bullet Shot<font=default>\n10% chance to spawn a small ball that lasts for 8 seconds";
SuddenMitosis.rarity = "common";
SuddenMitosis.shotCount = 0;
SuddenMitosis.unique = true
-- CoverLaser.imageReference = "assets/sprites/UI/ItemIcons/Cover-Laser.png";
function SuddenMitosis.new()
    local instance = setmetatable({}, SuddenMitosis):init();

    return instance;
end

return SuddenMitosis