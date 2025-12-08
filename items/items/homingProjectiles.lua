local HomingProjectiles = ItemBase.new();
HomingProjectiles.__index = HomingProjectiles;
HomingProjectiles.name = "Homing Projectiles";
HomingProjectiles.description = "<font=bold>Projectiles<font=default> will home in on the nearest brick";
HomingProjectiles.rarity = "common";
HomingProjectiles.imageReference = "assets/sprites/UI/ItemIcons/Homing-Bullets.png";

HomingProjectiles.unique = true; -- does smthn ig

function HomingProjectiles.new()
    local instance = setmetatable({}, HomingProjectiles):init();

    -- instance.stats.fireRate = 1;
    instance.stats.ammo = 1;
    instance.stats.cooldown = -1;

    return instance;
end

return HomingProjectiles;