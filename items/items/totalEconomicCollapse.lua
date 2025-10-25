local TotalEconomicCollapse = ItemBase.new();
TotalEconomicCollapse.__index = TotalEconomicCollapse;
TotalEconomicCollapse.name = "Total Economic Collapse";
TotalEconomicCollapse.description = "When you buy this, set the upgrade price of all weapons to 0";
TotalEconomicCollapse.rarity = "legendary";

TotalEconomicCollapse.consumable = true; -- does smthn ig

function TotalEconomicCollapse.new()
    local instance = setmetatable({}, TotalEconomicCollapse):init();

    return instance;
end

function TotalEconomicCollapse:purchase()
    for _, weaponType in pairs(Balls.getUnlockedBallTypes()) do
        weaponType.price = 0;
    end
end

return TotalEconomicCollapse;