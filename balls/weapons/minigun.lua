local Minigun = BallBase.new();
Minigun.__index = Minigun;
Minigun.name = "Minigun";
Minigun.type = "gun";
Minigun.description = "Fires bullets at an accelerating rate of fire. very long cooldown.";
Minigun.rarity = "uncommon";
Minigun.startingPrice = 50;
Minigun.size = 1;
Minigun.stats = {
    damage = 1;
    cooldown = 15;
    ammo = 100;
    fireRate = 5;
};

Minigun.trail = Trail.new(10, 50);
Minigun.bulletSpeed = 1000;
Minigun.ammoMult = 20;
Minigun.fireRateMult = 1.05;
Minigun.noAmount = true;

function Minigun.new()
    local instance = setmetatable({}, Minigun):init();
    
    instance.currentAmmo = 100 + ((Player.permanentUpgrades.ammo or 0)) * 15;

    return instance;
end

function Minigun:onBuy()
    -- shoot (?)
end

return Minigun;