local FlashSale = ItemBase.new();
FlashSale.__index = FlashSale;
FlashSale.name = "Flash Sale";
FlashSale.description = "Reduce the upgrade price of all of your items by 2 (min 0)";
FlashSale.rarity = "uncommon";
FlashSale.imageReference = "assets/sprites/UI/ItemIcons/Flash-Sale.png";

FlashSale.consumable = true; -- does smthn ig

function FlashSale.new()
    local instance = setmetatable({}, FlashSale):init();

    return instance;
end

function FlashSale:purchase()
    for _, weaponType in ipairs(WeaponHandler.getActiveWeapons()) do
        weaponType.price = math.max(weaponType.price - 2, 0);
    end
end

return FlashSale;