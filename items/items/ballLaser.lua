local BallAttachedLaser = ItemBase.new();
BallAttachedLaser.__index = BallAttachedLaser;
BallAttachedLaser.name = "Ball Attached Laser";
BallAttachedLaser.description = "<font=bold>On wall bounce<font=default>\nBalls have a <font=big><laserChance>%<font=default> chance to shoot a laser in a random direction that deals their <color=damage>damage";
BallAttachedLaser.rarity = "uncommon";
BallAttachedLaser.imageReference = "assets/sprites/UI/ItemIcons/Ball-Laser.png";

function BallAttachedLaser.new()
    local instance = setmetatable({}, BallAttachedLaser):init();

    instance.descriptionPointers = {
        laserChance = hasItem("Four Leafed Clover") and 100 or 50;
    };

    return instance;
end

return BallAttachedLaser;