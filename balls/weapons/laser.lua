local Laser = BallBase.new();
Laser.__index = Laser;
Laser.name = "Laser";
Laser.type = "tech";
Laser.description = "Paddle shoots Laser with that hits every brick in front of it. \nLong Cooldown\n Very long cooldown.";
Laser.rarity = "uncommon";
Laser.startingPrice = 100;
Laser.size = 1;
Laser.stats = {
    damage = 3;
    cooldown = 12;
};

Laser.noAmount = true;

function Laser.new()
    local instance = setmetatable({}, Laser):init();

    instance.charging = true;
    instance.currentChargeTime = 0;

    return instance;
end

return Laser;