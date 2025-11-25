local GunTurrets = BallBase.new();
GunTurrets.__index = GunTurrets;
GunTurrets.name = "Gun Turrets";
GunTurrets.type = "tech";
GunTurrets.description = "Generates turrets that shoots bricks.\n(max 20)";
GunTurrets.rarity = "uncommon";
GunTurrets.startingPrice = 50;
GunTurrets.size = 1;
GunTurrets.stats = {
    damage = 1;
    ammo = 9;
    cooldown = 12;
};

GunTurrets.trail = Trail.new(10, 50);
GunTurrets.bulletSpeed = 1500;
GunTurrets.noAmount = true;
GunTurrets.ammoMult = 3;

function GunTurrets.new()
    local instance = setmetatable({}, GunTurrets):init();

    instance.currentAmmo = 9 + ((Player.permanentUpgrades.ammo or 0)) * 3;

    return instance;
end

function GunTurrets:onBuy()
    -- fire (?)
end

function GunTurrets:canBuy()
    return Player.currentCore ~= "Damage Core";
end

return GunTurrets;