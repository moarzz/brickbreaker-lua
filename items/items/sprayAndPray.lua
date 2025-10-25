local SprayAndPray = ItemBase.new();
SprayAndPray.__index = SprayAndPray;
SprayAndPray.name = "Spray and Pray";
SprayAndPray.description = "fireRate items shoot <font=bold><fireRateMult>%<font=default> faster but are a lot less accurate";
SprayAndPray.rarity = "uncommon";

SprayAndPray.unique = true; -- does smthn ig

function SprayAndPray.new()
    local instance = setmetatable({}, SprayAndPray):init();

    instance.descriptionPointers = {
        fireRateMult = hasItem("Four Leafed Clover") and 70 or 35;
    };

    instance.stats.fireRate = 2;

    return instance;
end

function SprayAndPray.events:item_purchase_FourLeafedClover()
    self.descriptionPointers.paddleWidth = 70;
end

function SprayAndPray.events:item_sell_FourLeafedClover()
    self.descriptionPointers.paddleWidth = 35;
end

return SprayAndPray;