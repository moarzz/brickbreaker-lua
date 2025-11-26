local BuyTheDip = ItemBase.new();
BuyTheDip.__index = BuyTheDip;
BuyTheDip.name = "Buy the Dip";
BuyTheDip.description = "When you buy this, set the upgrade price of a random weapon to 0";
BuyTheDip.rarity = "rare";
BuyTheDip.imageReference = "assets/sprites/UI/ItemIcons/Buy-The-Dip.png";

BuyTheDip.consumable = true; -- does smthn ig

function BuyTheDip.new()
    local instance = setmetatable({}, BuyTheDip):init();

    return instance;
end

function BuyTheDip:purchase()
    local weapons = WeaponHandler.getActiveWeapons();

    local randomId = math.random(1, #weapons);
    local i = 1;

    weapons[randomId].price = 0;
end

return BuyTheDip;