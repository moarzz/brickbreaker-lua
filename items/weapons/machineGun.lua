local MachineGun = WeaponBase.new();
MachineGun.__index = MachineGun;
MachineGun.name = "Machine Gun";
MachineGun.type = "gun";
MachineGun.description = "Shoots bullets at a very high fire rate.";
MachineGun.rarity = "common";
MachineGun.startingPrice = 5;
MachineGun.size = 2;
MachineGun.ammoMult = 7;
MachineGun.fireRateMult = 0.35;
MachineGun.stats = {
    damage = 1,
    cooldown = 8,
    ammo = 14,
    fireRate = 4,
}

function MachineGun.new()
    local instance = setmetatable({}, MachineGun):init();

    instance.cooldown = 0;
    instance.activeBullets = {}
    instance.currentAmmo = getStat("Machine Gun", "ammo");

    shoot("Machine Gun", instance);
    return instance;
end

function MachineGun:update(dt)

end

function MachineGun:draw()
    for _, bullet in ipairs(self.activeBullets) do
        bullet:draw();
    end
end