local MoneyBack = ItemBase.new();
MoneyBack.__index = MoneyBack;
MoneyBack.name = "Money Back";
MoneyBack.description = "When you upgrade a weapon, gain <font=big><color=money>1$";
MoneyBack.rarity = "common";
-- MoneyBack.imageReference = "assets/sprites/UI/ItemIcons/Money-Back.png";


function MoneyBack.new()
    local instance = setmetatable({}, MoneyBack):init();

    return instance;
end

return MoneyBack;