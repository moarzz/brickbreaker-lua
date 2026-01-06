local BallAttachedLaser = ItemBase.new();
BallAttachedLaser.__index = BallAttachedLaser;
BallAttachedLaser.name = "Ball Attached Laser";
BallAttachedLaser.description = "<font=bold>On wall bounce<font=default>\nBalls shoot a laser in a random direction that deals their <color=damage>damage";
BallAttachedLaser.rarity = "common";
BallAttachedLaser.imageReference = "assets/sprites/UI/ItemIcons/Ball-Laser.png";

function BallAttachedLaser.new()
    local instance = setmetatable({}, BallAttachedLaser):init();

    instance.stats.speed = 1;
    instance.descriptionPointers = {
        laserChance = hasItem("Four Leafed Clover") and 100 or 50;
    };

    return instance;
end

return BallAttachedLaser;