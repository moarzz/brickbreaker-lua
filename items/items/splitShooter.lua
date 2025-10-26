local SplitShooter = ItemBase.new();
SplitShooter.__index = SplitShooter;
SplitShooter.name = "Split Shooter";
SplitShooter.description = "Bullets have a <font=bold><splitChance>%<font=default> chance to split into 2 after being shot";
SplitShooter.rarity = "uncommon";
SplitShooter.imageReference = "assets/sprites/UI/ItemIcons/Split-Shooter.png";

SplitShooter.unique = true; -- does smthn ig

function SplitShooter.new()
    local instance = setmetatable({}, SplitShooter):init();

    instance.descriptionPointers = {
        splitChance = hasItem("Four Leafed Clover") and 50 or 25;
    };

    instance.stats.ammo = 2;

    return instance;
end

function SplitShooter.events:item_purchase_FourLeafedClover()
    self.descriptionPointers.splitChance = 50;
end

function SplitShooter.events:item_sell_FourLeafedClover()
    self.descriptionPointers.splitChance = 25;
end

return SplitShooter;