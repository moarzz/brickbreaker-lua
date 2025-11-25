local MagneticBall = BallBase.new();
MagneticBall.__index = MagneticBall;
MagneticBall.name = "Magnetic Ball";
MagneticBall.type = "ball";
MagneticBall.description = "A ball that's magnetically attracted to the nearest brick.";
MagneticBall.rarity = "common";
MagneticBall.startingPrice = 25;
MagneticBall.size = 1;
MagneticBall.stats = {
    speed = 150;
    damage = 1;
};

MagneticBall.trail = Trail.new(10, 50);
MagneticBall.speedMult = 1.25;
MagneticBall.ballAmount = 1;
MagneticBall.attractionStrength = 500;

function MagneticBall.new()
    local instance = setmetatable({}, MagneticBall):init();

    instance.radius = MagneticBall.size * 10;

    return instance;
end

return MagneticBall;