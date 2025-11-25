local TeslaBullets = ItemBase.new();
TeslaBullets.__index = TeslaBullets;
TeslaBullets.name = "Tesla Bullets";
TeslaBullets.description = "<font=bold>On Bullet Hit\n<teslaChance>%<font=default> chance to start an electric current that jumps to 3 nearby bricks. Dealing the bullet's <color=damage>damage";
TeslaBullets.rarity = "uncommon";
TeslaBullets.imageReference = "assets/sprites/UI/ItemIcons/Tesla-Bullets.png";

TeslaBullets.unique = true; -- does smthn ig

function TeslaBullets.new()
    local instance = setmetatable({}, TeslaBullets):init();

    instance.descriptionPointers = {
        teslaChance = hasItem("Four Leafed Clover") and 50 or 25;
    };

    return instance;
end

function TeslaBullets.events:item_purchase_FourLeafedClover()
    self.descriptionPointers.teslaChance = 50;
end

function TeslaBullets.events:item_sell_FourLeafedClover()
    self.descriptionPointers.teslaChance = 25;
end

return TeslaBullets;