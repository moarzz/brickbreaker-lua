local CoverLaser = ItemBase.new();
CoverLaser.__index = CoverLaser;
CoverLaser.name = "Cover Laser";
CoverLaser.description = "After every 30 <font=big>bullets<font=default> fired, summon a laser that lasts for 5 seconds";
CoverLaser.rarity = "uncommon";
CoverLaser.shotCount = 0;
CoverLaser.unique = true
-- CoverLaser.imageReference = "assets/sprites/UI/ItemIcons/Cover-Laser.png";
function CoverLaser.new()
    local instance = setmetatable({}, CoverLaser):init();

    return instance;
end

function CoverLaser:onShoot()
    self.shotCount = self.shotCount + 1
    if self.shotCount >= 30 then
        self.shotCount = 0
        return true
    else
        return false
    end
end

return CoverLaser;