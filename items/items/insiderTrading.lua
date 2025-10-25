local InsiderTrading = ItemBase.new();
InsiderTrading.__index = InsiderTrading;
InsiderTrading.name = "Insider Trading";
InsiderTrading.description = "Fill the shop with <font=bold>Long Term Investment<font=default> items";
InsiderTrading.rarity = "rare";

InsiderTrading.consumable = true; -- does smthn ig

function InsiderTrading.new()
    local instance = setmetatable({}, InsiderTrading):init();

    return instance;
end

function InsiderTrading:purchase()
    setItemShop({getItem("Long Term Investment"), getItem("Long Term Investment"), getItem("Long Term Investment")});
end

return InsiderTrading;