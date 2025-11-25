local MachineGun = BallBase.new();
MachineGun.__index = MachineGun;
MachineGun.name = "Machine Gun";
MachineGun.type = "gun";
MachineGun.description = "Fires bullets, fast fireRate.";
MachineGun.rarity = "common";
MachineGun.startingPrice = 10;
MachineGun.size = 1;
MachineGun.stats = {
    damage = 1;
    cooldown = 8;
    ammo = 14;
    fireRate = 4;
};

MachineGun.trail = Trail.new(10, 50);
MachineGun.currentAmmo = 7 + ((Player.permanentUpgrades.ammo or 0)) * 7;
MachineGun.bulletSpeed = 1000;
MachineGun.ammoMult = 7;
MachineGun.fireRateMult = 0.35;
MachineGun.noAmount = true;

function MachineGun.new()
    local instance = setmetatable({}, MachineGun):init();

    return instance;
end

function MachineGun:canBuy()
    return false;
end

function MachineGun:onBuy()
    -- shoot (?)
end

return MachineGun;