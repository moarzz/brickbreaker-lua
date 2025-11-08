local PhantomBullets = ItemBase.new();
PhantomBullets.__index = PhantomBullets;
PhantomBullets.name = "Phantom Bullets";
PhantomBullets.description = "<font=bold>Bullets<font=default> have a <font=bold><spawnChance>%<font=default> chance to spawn as <font=bold>Phantom Bullets<font=default>, which pass through bricks without losing damage";
PhantomBullets.rarity = "rare";
PhantomBullets.imageReference = "assets/sprites/UI/ItemIcons/Phantom-Bullets.png";

PhantomBullets.unique = true; -- does smthn ig

function PhantomBullets.new()
    local instance = setmetatable({}, PhantomBullets):init();

    instance.descriptionPointers = {
        spawnChance    = hasItem("Four Leafed Clover") and 20 or 10;
    };

    return instance;
end

return PhantomBullets;