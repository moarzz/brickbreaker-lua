local SprayAndPray = ItemBase.new();
SprayAndPray.__index = SprayAndPray;
SprayAndPray.name = "Spray and Pray";
SprayAndPray.description = "fireRate items shoot <font=bold><fireRateMult>%<font=default> faster but are a lot less accurate";
SprayAndPray.rarity = "uncommon";
SprayAndPray.imageReference = "assets/sprites/UI/ItemIcons/Spray-and-Pray.png";

SprayAndPray.unique = true; -- does smthn ig

function SprayAndPray.new()
    local instance = setmetatable({}, SprayAndPray):init();

    instance.descriptionPointers = {
        fireRateMult = hasItem("Four Leafed Clover") and 80 or 40;
    };

    instance.stats.fireRate = 1;

    return instance;
end

-- I dont think this is necessary it should already be in the paddle metadata
function SprayAndPray.events:item_purchase_FourLeafedClover()
    self.descriptionPointers.fireRateMult = 80;
end

function SprayAndPray.events:item_sell_FourLeafedClover()
    self.descriptionPointers.fireRateMult = 40;
end

return SprayAndPray;