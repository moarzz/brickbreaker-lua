local HomingBullets = ItemBase.new();
HomingBullets.__index = HomingBullets;
HomingBullets.name = "Homing Bullets";
HomingBullets.description = "<font=bold>Projectiles<font=default> will home in on the nearest brick";
HomingBullets.rarity = "common";
HomingBullets.imageReference = "assets/sprites/UI/ItemIcons/Homing-Bullets.png";

HomingBullets.unique = true; -- does smthn ig

function HomingBullets.new()
    local instance = setmetatable({}, HomingBullets):init();

    instance.stats.fireRate = 1;
    instance.stats.ammo = 1;
    instance.stats.cooldown = -1;

    return instance;
end

return HomingBullets;