local BallLaser = ItemBase.new();
BallLaser.__index = BallLaser;
BallLaser.name = "Ball Laser";
BallLaser.description = "<font=bold>On wall bounce<font=default>\nBalls have a <font=big><laserChance>%<font=default> chance to shoot a laser in a random direction that deals their <color=damage>damage";
BallLaser.rarity = "uncommon";
BallLaser.imageReference = "assets/sprites/UI/ItemIcons/Ball-Laser.png";

function BallLaser.new()
    local instance = setmetatable({}, BallLaser):init();

    instance.descriptionPointers = {
        laserChance = hasItem("Four Leafed Clover") and 100 or 50;
    };

    return instance;
end

return BallLaser;