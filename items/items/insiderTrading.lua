local InsiderTrading = ItemBase.new();
InsiderTrading.__index = InsiderTrading;
InsiderTrading.name = "Insider Trading";
InsiderTrading.description = "+<color=money>3$<color=white> interest per level";
InsiderTrading.rarity = "rare";

InsiderTrading.consumable = true; -- does smthn ig

function InsiderTrading.new()
    local instance = setmetatable({}, InsiderTrading):init();

    return instance;
end

function InsiderTrading:purchase()
    longTermInvestment.value = longTermInvestment.value + 3;
end

return InsiderTrading;