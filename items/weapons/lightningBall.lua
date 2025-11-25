local LightningBall = WeaponBase.new();
LightningBall.__index = LightningBall;
LightningBall.name = "Lightning Ball";
LightningBall.type = "ball";
LightningBall.description = "Creates a damaging electric current between bricks on hit.";
LightningBall.rarity = "uncommon";
LightningBall.startingPrice = 50;
LightningBall.size = 1;
LightningBall.stats = {
    speed = 100;
    damage = 1;
    range = 2;
};

LightningBall.trail = Trail.new(10, 50);
LightningBall.speedMult = 1;
LightningBall.ballAmount = 1;

function LightningBall.new()
    local instance = setmetatable({}, LightningBall):init();

    instance.radius = LightningBall.size * 10;

    return instance;
end

return LightningBall;