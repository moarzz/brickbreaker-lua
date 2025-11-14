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
    local randomId = math.random(1, tableLength(Balls.getUnlockedBallTypes()));
    local i = 1;

    for _, weapon in pairs(Balls.getUnlockedBallTypes()) do
        if randomId == i then
            weapon.price = 0;
            break;
        end

        i = i + 1;
    end
end

return BuyTheDip;