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
        splitChance = hasItem("Four Leafed Clover") and 70 or 35;
    };

    instance.stats.cooldown = -2;

    return instance;
end

function SplitShooter.events:item_purchase_FourLeafedClover()
    self.descriptionPointers.splitChance = 60;
end

function SplitShooter.events:item_sell_FourLeafedClover()
    self.descriptionPointers.splitChance = 30;
end

return SplitShooter;