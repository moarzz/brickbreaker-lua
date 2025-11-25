local RocketLauncher = BallBase.new();
RocketLauncher.__index = RocketLauncher;
RocketLauncher.name = "Rocket Launcher";
RocketLauncher.type = "tech";
RocketLauncher.description = "Shoots rockets that explode on impact.";
RocketLauncher.rarity = "common";
RocketLauncher.startingPrice = 25;
RocketLauncher.size = 1;
RocketLauncher.stats = {
    damage = 2;
    ammo = 4;
    cooldown = 10;
    fireRate = 2;
    range = 3;
};

RocketLauncher.trail = Trail.new(10, 50);
RocketLauncher.noAmount = true;
RocketLauncher.ammoMult = 2;

function RocketLauncher.new()
    local instance = setmetatable({}, RocketLauncher):init();

    instance.currentAmmo = 2 + ((Player.permanentUpgrades.ammo or 0)) * 2;

    return instance;
end

function RocketLauncher:onBuy()
    -- fire (?)
end

return RocketLauncher;